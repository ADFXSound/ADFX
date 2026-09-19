-- @description ADFX_Recorder_Engine
-- @version 2.0.0
-- @author ADFXSound

--[[
  ADFX_Recorder_Engine.lua
  All REAPER-side behaviour for the ADFX recorder: capture routing, transport,
  peak extraction, preview playback and dropping the result into the project.

  The engine keeps no ImGui state, so it can be driven from a UI, from a
  keyboard shortcut, or from a test harness with a mocked `reaper` table.
]]

local sep = package.config:sub(1, 1)
local MODULE_DIR = reaper.GetResourcePath() .. sep .. 'Scripts' .. sep ..
  'ADFX' .. sep .. 'Modules' .. sep
local Util = dofile(MODULE_DIR .. 'ADFX_Recorder_Util.lua')
local Buffer = dofile(MODULE_DIR .. 'ADFX_Recorder_Buffer.lua')

local Engine = {}
Engine.__index = Engine
Engine.VERSION = '1.7.9'

local EXT_KEY = 'P_EXT:ADFX_RECORDER'
local PEAK_BUCKETS = 1400
local PEAK_TIMEOUT = 4.0

-- Live metering while recording. A bucket is a fixed slice of *time*, not one
-- per UI frame, so the live shape sits on the same axis as the waveform of the
-- finished file. Uneven frame rates would otherwise stretch and squash the
-- live view, and the host UIs do not run at a steady frame rate. The slice
-- doubles whenever the buffer fills, so a long take still fits the strip.
local LIVE_MAX_BUCKETS = 900
local LIVE_BUCKET_SECONDS = 1 / 60
local LIVE_MIN_CEILING = 0.25

-- Sample scan budget for waveform extraction.
local SCAN_TARGET_SAMPLES = 300000
local SCAN_MIN_RATE = 2000
local SCAN_MAX_RATE = 48000
local SCAN_CHUNK = 16384

-- I_RECMODE 3 = "record output (stereo, latency compensated)".
local REC_MODE_OUTPUT_STEREO_LATCOMP = 3
local ACTION_RECORD = 1013
local ACTION_STOP = 1016
local ACTION_STOP_SAVE_MEDIA = 40667
local ACTION_TOGGLE_SNAP = 1157
local ACTION_GLUE_ITEMS = 41588
-- Glue that ignores an unrelated arrange time selection. 41588 will silently
-- produce nothing (or a sliver) when a time selection does not cover the
-- hidden scratch items, which is how a take longer than one export chunk
-- never became playable.
local ACTION_GLUE_ITEMS_IGNORE_TIME = 40362
-- Peaks: Build any missing peaks. Glue (40362) also rebuilds them, which is
-- why a glued drop suddenly shows a waveform; this starts the same cache
-- without rewriting the file.
local ACTION_BUILD_MISSING_PEAKS = 40047

-- Isolated capture parks the transport this far past the end of the project,
-- so nothing on the timeline plays into the recording.
local ISOLATED_GAP = 2.0

-- How long REAPER is given to actually start writing before a transport that
-- is not recording is taken to mean the pass ended.
local RECORD_START_GRACE = 1.5

-- A recording shorter than the pass by more than this is worth explaining.
local SHORT_TAKE_SLACK = 0.75

-- The capture plug-in writes its file from REAPER's UI thread, which can be
-- serviced at a reduced rate, so it gets far longer than a normal finalize.
local EXPORT_TIMEOUT = 15.0
-- Keep every JSFX export comfortably below the contiguous scratch-memory limit.
local EXPORT_CHUNK_SECONDS = 20.0
local EXPORT_CHUNK_MAX_FRAMES = 1048576

-- How long the capture plug-in is given to report that it is seeing audio
-- before the engine gives up on it and records the transport instead.
local CAPTURE_START_GRACE = 5.0

-- Auto record follows the sound instead of the user watching the strip: a take
-- opens when the host plays something and closes once it has gone quiet.
-- Roughly -56 dBFS. Low enough to sit under a decaying tail, high enough not to
-- be held open by a noise floor.
local AUTO_SILENCE_LEVEL = 0.0016
-- Silence has to last this long before the take is closed, and the tail is
-- kept: it is part of the sound.
local AUTO_TAIL_SECONDS = 1.0
-- A trigger that never makes a sound must not leave the recorder running.
local AUTO_SIGNAL_TIMEOUT = 3.0

-- Playing from a point needs something left to hear. Below this a double click
-- at the very end of a take would start a preview that is over on arrival.
local MIN_PREVIEW_SECONDS = 0.02

function Engine.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Engine)
  self.api = opts.api or reaper
  self.id = opts.id or 'adfx'
  self.name_prefix = opts.name_prefix or 'ADFX_Recorder'
  self.capture = opts.capture or 'master'
  -- 'timeline' records a pass over the project from the edit cursor.
  -- 'isolated' records past the end of the project, so only what the host
  -- script plays live is captured.
  self.transport = opts.transport or 'timeline'
  -- 'transport' records the way REAPER does, by rolling and arming a track.
  -- 'buffer' reads from the capture JSFX, which is always holding the last few
  -- minutes of audio and needs no transport at all. The buffer backend falls
  -- back to the transport one if the plug-in cannot be loaded.
  self.backend = opts.backend or 'transport'
  self.buffer_seconds = opts.buffer_seconds or 120
  -- The gmem space the host script uses for its own plug-ins. The capture
  -- buffer needs a space of its own, and a script can only be attached to one
  -- at a time, so it has to know what to hand back.
  self.host_gmem = opts.host_gmem
  self.get_source_track = opts.get_source_track
  self.rec_mode = opts.rec_mode or REC_MODE_OUTPUT_STEREO_LATCOMP
  self.solo_arm = opts.solo_arm ~= false
  self.cleanup_on_exit = opts.cleanup_on_exit ~= false
  -- Auto record: the host says when it played something and the take closes
  -- itself once the sound has decayed.
  self.auto_record = opts.auto_record == true
  -- Signal Session is a manually armed, silence-compacted recording. The JSFX
  -- ring buffer is paused between sounds, so minutes of wall-clock silence do
  -- not consume frames; all audible regions export as one contiguous WAV.
  self.signal_record = opts.signal_record == true
  self.signal_active = false
  self.signal_heard = false
  self.signal_quiet_since = nil
  -- Maps compact Signal Session file time back to the wall-clock time at which
  -- each audible region was actually triggered/captured. Required by hosts such
  -- as S-Layer whose Restore Settings journal is keyed to wall time.
  self.signal_segments = {}
  self.signal_segment = nil
  self.silence_level = opts.silence_level or AUTO_SILENCE_LEVEL
  self.tail_seconds = opts.tail_seconds or AUTO_TAIL_SECONDS
  self.state = 'idle' -- idle | recording | finalizing | ready
  self.takes = {}
  self.take_count = 0
  self.error = nil
  self.sends = {}
  self.saved_arm = {}
  self:_reset_live()
  -- Snapshot of the waveform the user actually saw while recording.  This is
  -- retained across Stop/finalization and is a safe display fallback if REAPER's
  -- freshly-created media source is not peak-readable yet.
  self.final_live_peaks = nil
  self.final_live_ceiling = nil
  return self
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

function Engine:_has(fn)
  return type(self.api[fn]) == 'function'
end

--[[
  The recorder strip draws its own peaks. The arrange view does not: it needs
  a .reapeaks cache. AddMediaItemToTrack + PCM_Source_CreateFromFile never
  starts that builder, so a dropped take is audible but drawn as a blank
  block until REAPER's background rebuild (or Glue) fills the cache.

  This runs on its own reaper.defer chain — not Engine:tick() — so a peak
  error cannot stop recording or live metering.
]]
function Engine:_request_arrange_peaks(path, item)
  local R = self.api
  if type(path) ~= 'string' or path == '' then return end
  if not self:_has('PCM_Source_BuildPeaks') then return end

  local source
  local owned = false
  if item and self:_has('GetMediaItemTake_Source') then
    local take = R.GetActiveTake(item)
    source = take and R.GetMediaItemTake_Source(take)
  end
  if not source and self:_has('PCM_Source_CreateFromFile') then
    source = R.PCM_Source_CreateFromFile(path)
    owned = source ~= nil
  end
  if not source then return end

  local defer = R.defer or reaper.defer
  if type(defer) ~= 'function' then
    if owned and R.PCM_Source_Destroy then pcall(R.PCM_Source_Destroy, source) end
    return
  end

  local function finish()
    pcall(R.PCM_Source_BuildPeaks, source, 2)
    if item and R.ValidatePtr2 and R.ValidatePtr2(0, item, 'MediaItem*')
        and R.UpdateItemInProject then
      pcall(R.UpdateItemInProject, item)
    end
    if R.UpdateArrange then pcall(R.UpdateArrange) end
    if owned and R.PCM_Source_Destroy then pcall(R.PCM_Source_Destroy, source) end
  end

  local ok, remaining = pcall(R.PCM_Source_BuildPeaks, source, 0)
  if not ok then
    if owned and R.PCM_Source_Destroy then pcall(R.PCM_Source_Destroy, source) end
    return
  end
  if not remaining or remaining == 0 then
    finish()
    return
  end

  local tries = 0
  local function continue_peaks()
    tries = tries + 1
    local ok2, left = pcall(R.PCM_Source_BuildPeaks, source, 1)
    if not ok2 or tries > 2000 then
      finish()
      return
    end
    if (left or 0) == 0 then
      finish()
      return
    end
    defer(continue_peaks)
  end
  defer(continue_peaks)
end

function Engine:_track_tag(track)
  local ok, value = self.api.GetSetMediaTrackInfo_String(track, EXT_KEY, '', false)
  if ok then return value end
  return ''
end

--- Finds a recorder track left behind by a previous run of the same script.
function Engine:_find_existing_track()
  local R = self.api
  for i = 0, R.CountTracks(0) - 1 do
    local track = R.GetTrack(0, i)
    if self:_track_tag(track) == self.id then return track end
  end
  return nil
end

function Engine:_ensure_track()
  local R = self.api
  if self.track and R.ValidatePtr2(0, self.track, 'MediaTrack*') then return self.track end

  local track = self:_find_existing_track()
  if not track then
    local idx = R.CountTracks(0)
    R.InsertTrackAtIndex(idx, false)
    R.TrackList_AdjustWindows(false)
    track = R.GetTrack(0, idx)
    R.GetSetMediaTrackInfo_String(track, EXT_KEY, self.id, true)
  end

  R.GetSetMediaTrackInfo_String(track, 'P_NAME', self.name_prefix, true)
  R.SetMediaTrackInfo_Value(track, 'B_MAINSEND', 0)
  R.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 0)
  R.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', 0)
  R.SetMediaTrackInfo_Value(track, 'I_RECMODE', self.rec_mode)
  R.SetMediaTrackInfo_Value(track, 'I_RECMON', 0)
  self.track = track
  return track
end

function Engine:_source_tracks()
  local R = self.api
  local out = {}

  if self.capture == 'track' then
    local track = self.get_source_track and self.get_source_track()
    if track and R.ValidatePtr2(0, track, 'MediaTrack*') and track ~= self.track then
      out[#out + 1] = track
      return out
    end
    -- The host could not name its output track (its engine may not be built
    -- yet), so capture the master rather than recording silence.
    self.master_fallback = true
    self:_notify('source track not found — captured the master bus instead')
  end

  -- Master capture: receive every top level track that feeds the master bus.
  -- The recorder's own master send is off, so this cannot form a loop.
  for i = 0, R.CountTracks(0) - 1 do
    local track = R.GetTrack(0, i)
    if track ~= self.track
      and R.GetTrackDepth(track) == 0
      and R.GetMediaTrackInfo_Value(track, 'B_MAINSEND') == 1 then
      out[#out + 1] = track
    end
  end
  return out
end

--- True when track capture had to fall back to the master bus.
function Engine:metering_master()
  return self.capture ~= 'track' or self.master_fallback == true
end

--[[
  Notices explain something the user did not ask for but needs to know, such
  as REAPER ending a pass early. They are queued rather than stored so the UI
  can show each one once, whenever it happens, instead of only at the moment
  Record is pressed.
]]
function Engine:_notify(text)
  self.notice = text
  self.pending_notice = text
end

--- Returns the next unseen notice, or nil. Clears it.
function Engine:take_notice()
  local text = self.pending_notice
  self.pending_notice = nil
  return text
end

function Engine:_open_routing()
  local R = self.api
  self.sends = {}
  for _, src in ipairs(self:_source_tracks()) do
    R.CreateTrackSend(src, self.track)
    self.sends[#self.sends + 1] = src
  end
end

function Engine:_close_routing()
  local R = self.api
  for _, src in ipairs(self.sends) do
    if R.ValidatePtr2(0, src, 'MediaTrack*') then
      for i = R.GetTrackNumSends(src, 0) - 1, 0, -1 do
        local dest = R.GetTrackSendInfo_Value(src, 0, i, 'P_DESTTRACK')
        if dest == self.track then R.RemoveTrackSend(src, 0, i) end
      end
    end
  end
  self.sends = {}
end

--------------------------------------------------------------------------------
-- Buffer backend: the capture JSFX, which needs no transport
--------------------------------------------------------------------------------

--[[
  Brings up the capture plug-in and leaves the routing open for as long as the
  strip is on screen. Unlike transport recording there is no pass to open and
  close: the plug-in is always holding the last few minutes, and Record only
  marks where in that buffer the take should begin.

  Anything missing here — an old REAPER, an uninstalled plug-in — drops the
  engine back to transport recording rather than leaving it unable to record.
]]
function Engine:_ensure_capture()
  if self.backend ~= 'buffer' then return false end
  if self.buffer and self.buffer.attached then return true end

  self:_ensure_track()
  self.buffer = self.buffer or Buffer.new({
    api = self.api,
    buffer_seconds = self.buffer_seconds,
    host_gmem = self.host_gmem,
  })
  local ok, why = self.buffer:attach(self.track)
  if not ok then
    self.backend = 'transport'
    self.buffer = nil
    self:_notify((why or 'capture plug-in unavailable') .. ' — recording the transport instead')
    return false
  end

  -- The buffer is only worth anything if it is being fed, so the sends stay up
  -- from now until shutdown instead of being opened per pass.
  if #self.sends == 0 then self:_open_routing() end
  self.buffer_attached_at = self.api.time_precise()
  return true
end

--[[
  A plug-in that loaded but never reports in is not capturing anything, so the
  strip would look ready and then produce nothing. Give it a moment, then go
  back to transport recording, which always works.
]]
function Engine:_watch_capture()
  if self.backend ~= 'buffer' or not self.buffer or not self.buffer.attached then return end
  local now = self.api.time_precise()
  if self.buffer:alive() then
    if self.capture_lost then self:_notify('Recorder Recovered') end
    self.capture_lost = false
    self.capture_lost_at = nil
    self.capture_recover_at = nil
    self.buffer_confirmed = true
    return
  end

  if self.buffer_confirmed then
    if not self.capture_lost then
      self.capture_lost = true
      self.capture_lost_at = now
      self:_notify('Recorder Lost — attempting capture recovery')
    end
    -- Preserve the existing JSFX/ring buffer first. Re-enabling it is safe even
    -- during an active take; deleting it would destroy frames already captured.
    if not self.capture_recover_at or now - self.capture_recover_at >= 1.0 then
      self.capture_recover_at = now
      pcall(self.buffer.recover, self.buffer)
    end
    -- Only recreate a dead plug-in when no take/session depends on its ring
    -- buffer. During recording AND finalizing we keep retrying and make the
    -- loss visible: detaching here would destroy the frames a multi-chunk
    -- export is still reading.
    if self.state ~= 'recording' and self.state ~= 'finalizing'
      and now - (self.capture_lost_at or now) >= CAPTURE_START_GRACE then
      self.buffer:detach()
      self.buffer = nil
      self.buffer_confirmed = false
      self.capture_lost = false
      if self:_ensure_capture() then self:_notify('Recorder capture recreated') end
    end
    return
  end

  if now - (self.buffer_attached_at or 0) < CAPTURE_START_GRACE then return end
  self.buffer:detach()
  self.buffer = nil
  self.backend = 'transport'
  self:_notify('Recorder Lost — capture plug-in did not start; transport fallback enabled')
end

function Engine:_track_index()
  local R = self.api
  if not (self.track and R.ValidatePtr2(0, self.track, 'MediaTrack*')) then return 0 end
  return math.floor((R.GetMediaTrackInfo_Value(self.track, 'IP_TRACKNUMBER') or 1) - 1)
end

--[[
  Exporting inserts an item, and REAPER selects what it inserts. The item is
  deleted a moment later, but the user's own selection would be gone with it.
]]
function Engine:_save_item_selection()
  local R = self.api
  if not self:_has('CountSelectedMediaItems') then return nil end
  local saved = {}
  for i = 0, R.CountSelectedMediaItems(0) - 1 do
    saved[#saved + 1] = R.GetSelectedMediaItem(0, i)
  end
  return saved
end

function Engine:_restore_item_selection()
  local R = self.api
  local saved = self.saved_selection
  self.saved_selection = nil
  if not (saved and self:_has('SetMediaItemSelected')) then return end
  for _, item in ipairs(saved) do
    if R.ValidatePtr2(0, item, 'MediaItem*') then R.SetMediaItemSelected(item, true) end
  end
end

function Engine:_save_time_selection()
  local R = self.api
  if not self:_has('GetSet_LoopTimeRange2') and not self:_has('GetSet_LoopTimeRange') then
    return nil
  end
  local start_t, end_t
  if self:_has('GetSet_LoopTimeRange2') then
    start_t, end_t = R.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  else
    start_t, end_t = R.GetSet_LoopTimeRange(false, false, 0, 0, false)
  end
  return { start = start_t or 0, finish = end_t or 0 }
end

function Engine:_restore_time_selection(saved)
  if not saved then return end
  local R = self.api
  if self:_has('GetSet_LoopTimeRange2') then
    R.GetSet_LoopTimeRange2(0, true, false, saved.start or 0, saved.finish or 0, false)
  elseif self:_has('GetSet_LoopTimeRange') then
    R.GetSet_LoopTimeRange(true, false, saved.start or 0, saved.finish or 0, false)
  end
end

--- First media item on the capture track that is not already in `known`.
function Engine:_untracked_item(known)
  local R = self.api
  known = known or {}
  local count = R.CountTrackMediaItems(self.track)
  for i = 0, count - 1 do
    local candidate = R.GetTrackMediaItem(self.track, i)
    if candidate and not known[candidate] then return candidate end
  end
  return nil
end

function Engine:_item_source_path(item)
  local R = self.api
  if not item then return '' end
  local take = R.GetActiveTake(item)
  if not take then return '' end
  local source = R.GetMediaItemTake_Source(take)
  if not source then return '' end
  return Util.source_filename(R, source)
end

--[[
  Turns the exported scratch pieces into one file the rest of the recorder
  already knows how to preview and drag.

  File-level WAV concatenation is preferred: it does not care that the capture
  track is hidden, and it cannot be clipped by an arrange time selection.
  Glue is the fallback for non-WAV project recording formats.
]]
function Engine:_merge_export_chunks(plan)
  local R = self.api
  if not plan or #plan.items <= 1 then return true end

  local dest
  local first_path = plan.paths and plan.paths[1]
  if first_path and first_path ~= '' then
    dest = Util.dirname(first_path) .. string.format('%s_merged_%03d.wav',
      self.name_prefix, self.take_count + 1)
  end

  if dest and plan.paths and #plan.paths == #plan.items then
    local ok, why = Util.concat_wav_files(plan.paths, dest)
    if ok then
      self:_clear_items()
      local item = R.AddMediaItemToTrack(self.track)
      local take = R.AddTakeToMediaItem(item)
      local source = R.PCM_Source_CreateFromFile(dest)
      if source then R.SetMediaItemTake_Source(take, source) end
      R.SetMediaItemPosition(item, 0, false)
      R.SetMediaItemLength(item, plan.total_frames / plan.rate, false)
      return true
    end
    self:_notify(string.format('WAV merge skipped (%s) — gluing chunks instead', why or 'unknown'))
  end

  local saved_time = self:_save_time_selection()
  local shown = false
  if self:_has('SetMediaTrackInfo_Value') then
    -- Glue can ignore items on a track that is hidden from the TCP.
    R.SetMediaTrackInfo_Value(self.track, 'B_SHOWINTCP', 1)
    shown = true
  end
  if self:_has('SelectAllMediaItems') then R.SelectAllMediaItems(0, false) end
  for _, it in ipairs(plan.items) do
    if R.ValidatePtr2(0, it, 'MediaItem*') then R.SetMediaItemSelected(it, true) end
  end
  if self:_has('Main_OnCommand') then
    R.Main_OnCommand(ACTION_GLUE_ITEMS_IGNORE_TIME, 0)
    -- Older REAPERs may only have the time-selection-aware glue.
    if R.CountTrackMediaItems(self.track) ~= 1 then
      R.Main_OnCommand(ACTION_GLUE_ITEMS, 0)
    end
  end
  if shown then R.SetMediaTrackInfo_Value(self.track, 'B_SHOWINTCP', 0) end
  self:_restore_time_selection(saved_time)
  return R.CountTrackMediaItems(self.track) > 0
end

--- True when the JSFX backend is loaded and processing.
function Engine:buffer_ready()
  return self.backend == 'buffer' and self.buffer ~= nil and self.buffer:alive()
end

--- Seconds of audio the capture buffer holds, or nil when not on that backend.
function Engine:buffer_seconds_held()
  if not self:buffer_ready() then return nil end
  return self.buffer:capacity_seconds()
end

--- Disarms every other track so only our capture lands on disk.
function Engine:_take_over_arm()
  local R = self.api
  self.saved_arm = {}
  if self.solo_arm then
    for i = 0, R.CountTracks(0) - 1 do
      local track = R.GetTrack(0, i)
      if track ~= self.track then
        local armed = R.GetMediaTrackInfo_Value(track, 'I_RECARM')
        if armed == 1 then
          self.saved_arm[#self.saved_arm + 1] = track
          R.SetMediaTrackInfo_Value(track, 'I_RECARM', 0)
        end
      end
    end
  end
  R.SetMediaTrackInfo_Value(self.track, 'I_RECARM', 1)
end

function Engine:_restore_arm()
  local R = self.api
  for _, track in ipairs(self.saved_arm) do
    if R.ValidatePtr2(0, track, 'MediaTrack*') then
      R.SetMediaTrackInfo_Value(track, 'I_RECARM', 1)
    end
  end
  self.saved_arm = {}
  if self.track and R.ValidatePtr2(0, self.track, 'MediaTrack*') then
    R.SetMediaTrackInfo_Value(self.track, 'I_RECARM', 0)
  end
end

function Engine:_clear_items()
  local R = self.api
  if not (self.track and R.ValidatePtr2(0, self.track, 'MediaTrack*')) then return end
  for i = R.CountTrackMediaItems(self.track) - 1, 0, -1 do
    R.DeleteTrackMediaItem(self.track, R.GetTrackMediaItem(self.track, i))
  end
end

--------------------------------------------------------------------------------
-- Transport
--------------------------------------------------------------------------------

function Engine:is_recording()
  return self.state == 'recording'
end

--------------------------------------------------------------------------------
-- Live metering: the waveform drawn while the take is still being written
--------------------------------------------------------------------------------

function Engine:_reset_live()
  self.live = { peaks = {}, span = LIVE_BUCKET_SECONDS, filled = 0, level = 0, ceiling = 0 }
end

-- Freeze an independent copy of the red live waveform.  The live table is
-- mutable and is reset on the next Record, so current.peaks must never alias it.
function Engine:_snapshot_live_waveform()
  local src = self.live and self.live.peaks or {}
  local out = {}
  for i = 1, #src do
    local p = src[i]
    out[i] = { max = p.max or 0, min = p.min or 0 }
  end

  -- A very short take can stop before the first time bucket closes. Preserve
  -- the pending meter value too, otherwise a clearly visible short transient
  -- can become an empty finalized waveform.
  if self.live and (self.live.level or 0) > 0 then
    out[#out + 1] = { max = self.live.level, min = -self.live.level }
  end

  self.final_live_peaks = out
  self.final_live_ceiling = self.live and self.live.ceiling or nil
end

--[[
  The tracks to read levels from while recording.

  Deliberately not just the capture track: it is hidden from both the TCP and
  the mixer, and REAPER does not keep meter state for a track it never draws,
  so metering it alone reports silence. The master bus (or, in track mode, the
  source track) carries the same signal and is always metered. The capture
  track is still included in case a future REAPER does meter it.
]]
function Engine:_meter_tracks()
  local R = self.api
  local tracks = {}

  if not self:metering_master() then
    for _, source in ipairs(self.sends) do
      if R.ValidatePtr2(0, source, 'MediaTrack*') then tracks[#tracks + 1] = source end
    end
  elseif self:_has('GetMasterTrack') then
    tracks[#tracks + 1] = R.GetMasterTrack(0)
  end

  if self.track and R.ValidatePtr2(0, self.track, 'MediaTrack*') then
    tracks[#tracks + 1] = self.track
  end
  return tracks
end

--[[
  Loudest peak seen since the last call.

  Both meter APIs are read and the larger kept: Track_GetPeakHoldDB with
  clear = true reports the true peak between two UI frames, which catches
  transients that fall between frames, while Track_GetPeakInfo reports the
  current meter value and works on builds where the hold state is not
  maintained.
]]
function Engine:_read_meter()
  local R = self.api
  -- The capture plug-in sees the samples themselves, so on that backend the
  -- live waveform is drawn from the audio rather than from a track meter.
  if self.backend == 'buffer' and self.buffer then return self.buffer:read_peak() end

  local hold = self:_has('Track_GetPeakHoldDB')
  local instant = self:_has('Track_GetPeakInfo')
  if not (hold or instant) then return nil end

  local tracks = self:_meter_tracks()
  if #tracks == 0 then return nil end

  local level = 0
  for _, track in ipairs(tracks) do
    for channel = 0, 1 do
      if hold then
        local amp = Util.hold_db_to_amplitude(R.Track_GetPeakHoldDB(track, channel, true))
        if amp > level then level = amp end
      end
      if instant then
        local amp = math.abs(R.Track_GetPeakInfo(track, channel) or 0)
        if amp > level then level = amp end
      end
    end
  end
  return level
end

--[[
  Closes off however many time slices have elapsed since the last frame, each
  carrying the loudest level measured across the frame. Driving this from the
  clock rather than the frame counter is what keeps the live shape on the same
  time axis as the finished waveform: a slow frame widens one bucket instead of
  compressing everything after it.
]]
function Engine:_poll_live_meter()
  local level = self:_read_meter()
  if not level then return end

  -- In Signal Session the capture JSFX is paused while WAITING. Its peak meter
  -- can still see the source track, but those samples are deliberately NOT part
  -- of the compact WAV. Do not let waiting-time peaks leak into the live strip;
  -- the red live waveform must describe the same compact timeline as the final
  -- blue waveform. Reading above still clears the JSFX peak accumulator.
  if self.signal_record and self.state == 'recording' and not self.signal_active then
    self:_note_level(level)
    return
  end

  local live = self.live
  if level > live.level then live.level = level end
  if level > live.ceiling then live.ceiling = level end

  local elapsed = self:elapsed()
  local closed = false
  while live.filled < math.floor(elapsed / live.span) do
    live.peaks[#live.peaks + 1] = { max = live.level, min = -live.level }
    live.filled = live.filled + 1
    closed = true
    if #live.peaks >= LIVE_MAX_BUCKETS then
      live.peaks = Util.halve_peaks(live.peaks)
      live.span = live.span * 2
      live.filled = #live.peaks
    end
  end
  -- Only forget the reading once it has been drawn somewhere. Frames can be
  -- shorter than a bucket, and a transient measured in one of those must not
  -- be dropped on the floor.
  if closed then live.level = 0 end
  self:_note_level(level)
end

--------------------------------------------------------------------------------
-- Auto record: the take follows the sound
--------------------------------------------------------------------------------

--[[
  Called by the host the moment it plays something. With auto record on this
  opens a take, and a second trigger while one is already open extends it
  rather than starting a new one, so a roll of hits lands in one recording.

  Returns true if a take is open because of this call.
]]
function Engine:signal_trigger()
  -- Signal Session is explicitly armed with Record. A host trigger wakes the
  -- paused capture immediately, so the first transient is not dependent on a
  -- level detector noticing it after the fact.
  if self.signal_record and self.state == 'recording' then
    local now = self.api.time_precise()
    -- A new trigger begins a new wall-clock mapping segment at the exact compact
    -- file position where capture resumes. Signal Session removes real-world
    -- gaps, so a single anchor + file position is not sufficient.
    if self.signal_segment then
      self.signal_segment.file_end = self:elapsed()
      self.signal_segment.wall_end = now
      self.signal_segment = nil
    end
    local seg = { file_start = self:elapsed(), wall_start = now }
    self.signal_segments[#self.signal_segments + 1] = seg
    self.signal_segment = seg
    self.signal_active = true
    self.signal_heard = false
    self.signal_quiet_since = nil
    self.auto_deadline = now + AUTO_SIGNAL_TIMEOUT
    if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(false) end
    return true
  end

  if not self.auto_record then return false end
  if self.state == 'finalizing' then return false end
  if self.state ~= 'recording' then
    if not self:start() then return false end
    self.auto_heard = false
  end
  self.auto_active = true
  self.auto_quiet_since = nil
  self.auto_deadline = self.api.time_precise() + AUTO_SIGNAL_TIMEOUT
  return true
end

--- Feeds each metered level into Auto or Signal Session silence tracking.
function Engine:_note_level(level)
  if self.signal_record and self.state == 'recording' and self.signal_active then
    if level >= self.silence_level then
      self.signal_heard = true
      self.signal_quiet_since = nil
    elseif self.signal_heard and not self.signal_quiet_since then
      self.signal_quiet_since = self.api.time_precise()
    end
    return
  end
  if not self.auto_active then return end
  if level >= self.silence_level then
    self.auto_heard = true
    self.auto_quiet_since = nil
  elseif self.auto_heard and not self.auto_quiet_since then
    self.auto_quiet_since = self.api.time_precise()
  end
end

function Engine:_poll_auto_stop()
  if self.state ~= 'recording' then return end
  local now = self.api.time_precise()

  if self.signal_record then
    if not self.signal_active then return end
    if self.signal_heard then
      if self.signal_quiet_since and now - self.signal_quiet_since >= self.tail_seconds then
        -- Do not finalize. Freeze the capture clock here. The next trigger
        -- unpauses it and therefore appends directly after this tail.
        if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(true) end
        if self.signal_segment then
          self.signal_segment.file_end = self:elapsed()
          self.signal_segment.wall_end = now
          self.signal_segment = nil
        end
        self.signal_active = false
        self.signal_heard = false
        self.signal_quiet_since = nil
      end
    elseif now >= (self.auto_deadline or 0) then
      -- Trigger made no sound: return to waiting rather than closing the whole
      -- session. This is important for muted/empty S-Layer iterations.
      if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(true) end
      if self.signal_segment then
        self.signal_segment.file_end = self:elapsed()
        self.signal_segment.wall_end = now
        self.signal_segment = nil
      end
      self.signal_active = false
    end
    return
  end

  if not self.auto_active then return end
  if self.auto_heard then
    if self.auto_quiet_since and now - self.auto_quiet_since >= self.tail_seconds then self:stop() end
    return
  end
  if now >= (self.auto_deadline or 0) then
    self:_notify('nothing was heard after the trigger, so the take was closed')
    self:stop()
  end
end

--[[
  Keep the current follow session from swallowing a diagnostic replay.
  Signal Session stays armed but paused. An Auto take is closed so the
  replay is not appended to the previous trigger.
]]
function Engine:skip_follow()
  if self.state ~= 'recording' then return false end
  if self.signal_record then
    if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(true) end
    local now = self.api.time_precise()
    if self.signal_segment then
      self.signal_segment.file_end = self:elapsed()
      self.signal_segment.wall_end = now
      self.signal_segment = nil
    end
    self.signal_active = false
    self.signal_heard = false
    self.signal_quiet_since = nil
    return true
  end
  if self.auto_active then
    self:stop()
    return true
  end
  return false
end

function Engine:set_auto_record(on)
  self.auto_record = on and true or false
  if self.auto_record then self.signal_record = false end
  if not self.auto_record then self.auto_active = false end
end

function Engine:set_signal_record(on)
  on = on and true or false
  if self.state == 'recording' then return false end
  self.signal_record = on
  if on then self:set_auto_record(false); self.signal_record = true end
  return true
end

function Engine:auto_recording() return self.auto_active == true and self.state == 'recording' end
function Engine:signal_recording() return self.signal_record == true and self.state == 'recording' end
function Engine:capture_status()
  if self.backend ~= 'buffer' then return 'transport' end
  if self.capture_lost then return 'lost' end
  if self.buffer_confirmed then return 'ready' end
  return 'connecting'
end

--- Buckets captured so far. Empty unless a take is being written.
function Engine:live_peaks()
  if self.state ~= 'recording' and self.state ~= 'finalizing' then return {} end
  return self.live.peaks
end

function Engine:live_ceiling()
  return math.max((self.live and self.live.ceiling) or 0, LIVE_MIN_CEILING)
end

--- Loudest level seen so far this take, in dB, or nil if nothing has arrived.
function Engine:live_peak_db()
  return Util.amplitude_to_db(self.live and self.live.ceiling)
end

--[[
  Isolated capture: park the transport past the end of the project so no items
  play into the take, and remember where the user was so stopping puts the edit
  cursor back. REAPER only records while the transport rolls, so this is how a
  live-triggered instrument gets captured on its own.
]]
function Engine:_park_transport()
  local R = self.api
  if self.transport ~= 'isolated' then return end
  if not self:_has('SetEditCurPos') then return end

  local play_state = math.floor(R.GetPlayState() or 0)
  if play_state % 2 == 1 then R.Main_OnCommand(ACTION_STOP, 0) end

  self.saved_cursor = R.GetCursorPosition()
  local project_end = (self:_has('GetProjectLength') and R.GetProjectLength(0)) or 0
  R.SetEditCurPos(project_end + ISOLATED_GAP, false, false)
end

function Engine:_restore_transport()
  local R = self.api
  if not self.saved_cursor then return end
  if self:_has('SetEditCurPos') then R.SetEditCurPos(self.saved_cursor, true, false) end
  self.saved_cursor = nil
end

--[[
  Repeat has to be off for the pass. With it on REAPER loop-records: the
  transport jumps back at the loop point and every iteration becomes its own
  item and its own file, so the strip would meter the whole performance while
  the take only held the final lap. The user's setting is put back on stop.
]]
function Engine:_suspend_repeat()
  local R = self.api
  self.saved_repeat = nil
  if not self:_has('GetSetRepeat') then return end
  if R.GetSetRepeat(-1) == 1 then
    self.saved_repeat = true
    R.GetSetRepeat(0)
  end
end

function Engine:_restore_repeat()
  if not self.saved_repeat then return end
  if self:_has('GetSetRepeat') then self.api.GetSetRepeat(1) end
  self.saved_repeat = nil
end

--- True while REAPER reports that it is actually writing a recording.
function Engine:_reaper_is_recording()
  local R = self.api
  if not self:_has('GetPlayState') then return nil end
  local state = math.floor(R.GetPlayState() or 0)
  return math.floor(state / 4) % 2 == 1
end

--[[
  How much has been recorded, measured off the transport rather than the wall
  clock, so the number on the strip is the length of the file being written.
  Falls back to the wall clock on builds with no play position.
]]
function Engine:_recorded_so_far()
  local R = self.api

  -- The capture buffer counts frames whether or not anything is rolling, so
  -- it is its own clock and needs none of the transport handling below.
  if self.backend == 'buffer' and self.buffer then
    local rate = self.buffer:srate()
    if rate and self.start_frame then
      return math.max((self.buffer:frames() - self.start_frame) / rate, 0)
    end
    return 0
  end

  local recording = self:_reaper_is_recording()

  if recording and self.record_start_pos and self:_has('GetPlayPosition') then
    local pos = R.GetPlayPosition()
    if type(pos) == 'number' then
      local dt = pos - self.record_start_pos
      if dt >= 0 then
        self.transport_elapsed = dt
        return dt
      end
    end
  end

  -- REAPER has stopped writing. The take is as long as the transport got, not
  -- as long as the strip has been on screen.
  if recording == false and self.transport_elapsed then return self.transport_elapsed end
  return R.time_precise() - (self.started_at or 0)
end

function Engine:start()
  if self.state == 'recording' then return false end
  local R = self.api
  self.error = nil
  self.notice = nil
  self.master_fallback = false
  self.final_live_peaks = nil
  self.final_live_ceiling = nil

  if self.state == 'finalizing' then
    self.error = 'still writing the last take'
    return false
  end

  local play_state = math.floor(R.GetPlayState() or 0)
  if math.floor(play_state / 4) % 2 == 1 then
    self.error = 'REAPER is already recording'
    return false
  end

  R.PreventUIRefresh(1)
  self:_reset_live()
  -- A take started from the button is the user's to end. signal_trigger sets
  -- these again straight after calling in here.
  self.auto_active = false
  self.auto_heard = false
  self.auto_quiet_since = nil
  self.signal_active = false
  self.signal_heard = false
  self.signal_quiet_since = nil
  self.signal_segments = {}
  self.signal_segment = nil
  self:stop_preview()
  -- The previous take gives way to the live strip; its file stays on disk.
  self.current = nil
  self.section = nil
  self:_ensure_capture()
  self:_ensure_track()
  self:_clear_items()

  if self.backend == 'buffer' then
    -- Nothing to arm and nothing to roll. The plug-in is already capturing;
    -- all a take needs is the point in its buffer where it should begin.
    self.start_frame = self.buffer:frames()
    R.PreventUIRefresh(-1)
    self.state = 'recording'
    self.started_at = R.time_precise()
    self.seen_recording = true
    self.transport_elapsed = nil
    self.pass_length = 0
    if self.signal_record and self.buffer then self.buffer:set_paused(true) end
    return true
  end

  self:_open_routing()
  self:_take_over_arm()
  self:_suspend_repeat()
  self:_park_transport()
  self.record_start_pos = R.GetCursorPosition()
  R.PreventUIRefresh(-1)

  R.Main_OnCommand(ACTION_RECORD, 0)
  self.state = 'recording'
  self.started_at = R.time_precise()
  self.seen_recording = false
  self.transport_elapsed = nil
  self.pass_length = 0
  return true
end

--- Seconds captured so far, frozen at the pass length once recording ends.
function Engine:elapsed()
  if self.state == 'recording' then
    self.pass_length = math.max(self:_recorded_so_far(), 0)
    return self.pass_length
  end
  if self.state == 'finalizing' then return self.pass_length or 0 end
  return 0
end

function Engine:stop()
  if self.state ~= 'recording' then return false end
  local R = self.api

  -- What was visible during recording is valuable state in its own right.
  -- Capture it BEFORE any buffer/export/finalize transition. This makes Stop
  -- incapable of visually erasing a valid recording merely because REAPER's
  -- new WAV/peak cache is momentarily unavailable.
  self:_snapshot_live_waveform()

  self.pass_length = self:elapsed()
  self.auto_active = false
  if self.signal_record and self.signal_segment then
    self.signal_segment.file_end = self.pass_length
    self.signal_segment.wall_end = R.time_precise()
    self.signal_segment = nil
  end
  self.signal_active = false

  if self.backend == 'buffer' then
    -- Stop means the marked take must become immutable immediately.  Previously
    -- Signal Session only cleared signal_active here; if Stop was pressed while
    -- CAPTURING, the JSFX ring continued writing throughout finalization.  A
    -- multi-chunk export could therefore be reading a moving/overwriting ring.
    -- Freeze first, then snapshot the absolute end frame exactly once.
    if self.buffer then self.buffer:set_paused(true) end
    local stop_frame = self.buffer:frames()
    local frames = stop_frame - (self.start_frame or 0)
    local capacity = self.buffer:capacity_frames()
    if frames > capacity then
      frames = capacity
      self:_notify(string.format('take was longer than the %.0fs capture buffer — kept the end',
        self.buffer:capacity_seconds()))
    end
    if frames <= 0 then
      if self.buffer then self.buffer:set_paused(false) end
      self.state = 'idle'
      self.error = 'nothing was captured'
      return true
    end
    -- Where the first exported frame sits on the wall clock. Counting back from
    -- now over the frames actually kept is right for a normal pass and for
    -- grab_last, which reaches backwards into buffer the plug-in already held.
    if self.signal_record and self.signal_segments[1] then
      self.pending_anchor = self.signal_segments[1].wall_start
    else
      self.pending_anchor = R.time_precise() - frames / math.max(self.buffer:srate(), 1)
    end
    -- The exported item lands on the hidden track, where finalizing reads its
    -- file and throws the item away, exactly as it does for a recorded pass.
    self.saved_selection = self:_save_item_selection()
    -- Long buffer takes are exported in bounded pieces.  The old monolithic
    -- export could create a correctly-sized item whose samples stopped after
    -- the JSFX contiguous memory window.  Each piece is small, then REAPER
    -- glues the pieces into one ordinary WAV before the recorder exposes it.
    local rate = math.max(self.buffer:srate() or 0, 1)
    local chunk_frames = math.min(math.floor(rate * EXPORT_CHUNK_SECONDS), EXPORT_CHUNK_MAX_FRAMES)
    chunk_frames = math.max(chunk_frames, 16384)
    self.export_plan = {
      -- Both ends are based on the frozen stop-frame snapshot.  Never ask
      -- frames() again while this export is in flight.
      start_frame = stop_frame - frames,
      stop_frame = stop_frame,
      total_frames = frames,
      done_frames = 0,
      chunk_frames = chunk_frames,
      rate = rate,
      items = {},
      paths = {},
      awaiting_item = false,
      before_count = R.CountTrackMediaItems(self.track),
      current_request_frames = 0,
    }
    local first_len = math.min(chunk_frames, frames)
    self.export_plan.current_request_frames = first_len
    -- Do not let a one-frame buffer availability race destroy the take.  The
    -- finalizer owns export requests and will retry this exact chunk until the
    -- capture plug-in is alive again or EXPORT_TIMEOUT genuinely expires.
    self.export_serial = nil
    self.export_wait_started = R.time_precise()
    self.export_last_recover = 0
    self.state = 'finalizing'
    self.finalize_started = self.export_wait_started
    return true
  end

  -- Rolling the transport takes a moment REAPER does not report, so this is the
  -- moment the take was asked for rather than the moment its first sample
  -- landed. Close enough to line a take up against events seconds apart.
  self.pending_anchor = self.started_at
  R.Main_OnCommand(ACTION_STOP_SAVE_MEDIA, 0)
  self:_close_routing()
  self:_restore_arm()
  self:_restore_repeat()
  self:_restore_transport()

  self.state = 'finalizing'
  self.finalize_started = R.time_precise()
  return true
end

function Engine:toggle()
  if self:is_recording() then return self:stop() end
  return self:start()
end

--[[
  Takes the last few seconds straight out of the capture buffer. The plug-in
  has been holding them all along, so this works for a phrase that was already
  played before anyone thought to press Record.
]]
function Engine:grab_last(seconds)
  if not self:buffer_ready() then
    self.error = 'the capture buffer is not running'
    return false
  end
  if self.state == 'recording' or self.state == 'finalizing' then
    self.error = 'already capturing'
    return false
  end

  local rate = self.buffer:srate()
  local frames = self.buffer:frames()
  local want = math.min(math.floor(seconds * rate), self.buffer:capacity_frames(), frames)
  if want <= 0 then
    self.error = 'nothing has been captured yet'
    return false
  end

  self.error = nil
  self:_reset_live()
  self:stop_preview()
  self.current = nil
  self.section = nil
  self:_clear_items()
  self.start_frame = frames - want
  self.state = 'recording'
  self.started_at = self.api.time_precise()
  return self:stop()
end

--------------------------------------------------------------------------------
-- Finalizing: grab the file, build peaks, then drop the temp item
--------------------------------------------------------------------------------

--[[
  Reads the take's samples through an audio accessor and folds them into
  min/max buckets. This is the primary path: unlike GetMediaItemTake_Peaks it
  does not depend on REAPER's peak cache, which does not exist yet for a file
  that was recorded seconds ago.
]]
function Engine:_peaks_from_samples(take, length)
  local R = self.api
  if not (self:_has('CreateTakeAudioAccessor') and self:_has('GetAudioAccessorSamples')
    and self:_has('new_array')) then return nil end

  local accessor = R.CreateTakeAudioAccessor(take)
  if not accessor then return nil end

  local start = R.GetAudioAccessorStartTime(accessor) or 0
  local finish = R.GetAudioAccessorEndTime(accessor) or 0
  local total = finish - start
  if total <= 0 then total = length or 0 end
  if length and length > 0 then total = math.min(total, length) end
  if total <= 0 then
    R.DestroyAudioAccessor(accessor)
    return nil
  end

  -- Read at a rate that keeps the whole scan around a few hundred thousand
  -- samples, so a long take costs the same as a short one.
  local rate = math.floor(Util.clamp(SCAN_TARGET_SAMPLES / total, SCAN_MIN_RATE, SCAN_MAX_RATE))
  local channels = 2
  local total_samples = math.floor(total * rate)
  if total_samples < 2 then
    R.DestroyAudioAccessor(accessor)
    return nil
  end

  local buckets = math.min(PEAK_BUCKETS, total_samples)
  local per_bucket = total_samples / buckets
  local peaks = {}
  for i = 1, buckets do peaks[i] = { min = 0, max = 0 } end

  local buf = R.new_array(SCAN_CHUNK * channels)
  local read = 0
  local failed = false
  while read < total_samples do
    local count = math.min(SCAN_CHUNK, total_samples - read)
    -- Clear before every read. REAPER does not promise to write anything for a
    -- block it reports as silent, so stale samples from the previous block
    -- would otherwise be folded in and fill the gaps with a copy of the last
    -- loud passage.
    if buf.clear then buf.clear() end
    local ok, rv = pcall(R.GetAudioAccessorSamples, accessor, rate, channels,
      start + read / rate, count, buf)
    if not ok or (type(rv) == 'number' and rv < 0) then
      failed = true
      break
    end

    -- rv == 0 means silence: leave those buckets at zero and move on.
    if rv ~= 0 then
      local data = buf.table(1, count * channels)
      for s = 0, count - 1 do
        local bucket = math.min(math.floor((read + s) / per_bucket) + 1, buckets)
        local p = peaks[bucket]
        for c = 1, channels do
          local v = data[s * channels + c] or 0
          if v > p.max then p.max = v end
          if v < p.min then p.min = v end
        end
      end
    end
    read = read + count
  end

  R.DestroyAudioAccessor(accessor)
  if failed or Util.peak_ceiling(peaks) <= 0 then return nil end
  return peaks
end

--- Fallback for hosts without accessors: REAPER's cached peaks, if any exist.
function Engine:_peaks_from_cache(take, length)
  local R = self.api
  if not (self:_has('GetMediaItemTake_Peaks') and self:_has('new_array')) then return nil end
  local channels = 2
  local buckets = PEAK_BUCKETS
  local peak_rate = buckets / math.max(length, 0.001)
  local buf = R.new_array(buckets * channels * 3)
  local ok, rv = pcall(R.GetMediaItemTake_Peaks, take, peak_rate, 0, channels, buckets, 0, buf)
  if not ok or type(rv) ~= 'number' then return nil end
  local returned = math.floor(rv % 0x100000)
  if returned <= 0 then return nil end
  local flat = buf.table(1, returned * channels * 2)
  local peaks = Util.fold_peaks(flat, returned, channels)
  if Util.peak_ceiling(peaks) <= 0 then return nil end
  return peaks
end

function Engine:_compute_peaks(take, length)
  local peaks = self:_peaks_from_samples(take, length)
  if peaks then
    self.peak_source = 'samples'
    return peaks
  end
  peaks = self:_peaks_from_cache(take, length)
  if peaks then
    self.peak_source = 'cache'
    return peaks
  end
  self.peak_source = nil
  return nil
end

--[[
  Rebuilds the waveform for the take that is already loaded. Only possible
  while the source file is still on disk, which it always is.
]]
function Engine:rebuild_peaks()
  local R = self.api
  if not self.current then return false end
  if not (self:_has('PCM_Source_CreateFromFile') and self:_has('AddMediaItemToTrack')) then
    return false
  end
  self:_ensure_track()
  local item = R.AddMediaItemToTrack(self.track)
  local take = R.AddTakeToMediaItem(item)
  R.SetMediaItemTake_Source(take, R.PCM_Source_CreateFromFile(self.current.path))
  R.SetMediaItemLength(item, self.current.length, false)
  local peaks = self:_compute_peaks(take, self.current.length)
  R.DeleteTrackMediaItem(self.track, item)
  R.UpdateArrange()
  if peaks then
    self.current.peaks = peaks
    return true
  end
  return false
end

--[[
  The pass does not always leave exactly one item behind. Loop recording ends
  an item at every loop point and auto-punch ends one at each edge of the time
  selection, and each piece is a separate file. Taking whichever item happened
  to be last then showed only the tail of the performance. Take the longest,
  and let the caller say that the pass was split.
]]
function Engine:_pass_item()
  local R = self.api
  local count = R.CountTrackMediaItems(self.track)
  local best, best_length = nil, -1
  for i = 0, count - 1 do
    local item = R.GetTrackMediaItem(self.track, i)
    local length = R.GetMediaItemInfo_Value(item, 'D_LENGTH') or 0
    if length > best_length then best, best_length = item, length end
  end
  return best, count
end

--- Explains a take that does not hold everything the strip metered.
function Engine:_report_short_take(length, item_count)
  if item_count > 1 then
    self:_notify(string.format(
      'REAPER split this pass into %d recordings (loop recording or auto-punch) — kept the longest',
      item_count))
    return
  end
  local pass = self.pass_length or 0
  if pass > 0 and length < pass - SHORT_TAKE_SLACK then
    self:_notify(string.format(
      'REAPER stopped writing after %.1fs of a %.1fs pass — check auto-punch and the project end',
      length, pass))
  end
end

--[[
  Called every frame while finalizing. The file REAPER just wrote is not always
  readable on the first frame, so we retry until the waveform can be built,
  then give up and hand over a peakless take that can still be dragged.
]]
function Engine:_poll_finalize()
  local R = self.api
  if not (self.track and R.ValidatePtr2(0, self.track, 'MediaTrack*')) then
    self.state = 'idle'
    self.error = 'recorder track disappeared'
    return
  end

  -- A finished export whose item has not appeared yet must not fire another
  -- request. Re-exporting the same frames created duplicates or timed out
  -- before Play/drag were enabled, which is the >1-chunk (often >10 s at
  -- 96 kHz) failure.
  if self.export_plan and self.export_plan.awaiting_item and not self.export_serial then
    local plan = self.export_plan
    local now = R.time_precise()
    local known = {}
    for _, old_item in ipairs(plan.items) do known[old_item] = true end
    local item = self:_untracked_item(known)
    if item then
      local chunk_len = R.GetMediaItemInfo_Value(item, 'D_LENGTH') or 0
      if self:_has('SetMediaItemInfo_Value') then
        R.SetMediaItemInfo_Value(item, 'D_POSITION', plan.done_frames / plan.rate)
      end
      plan.items[#plan.items + 1] = item
      local path = self:_item_source_path(item)
      if path ~= '' then plan.paths[#plan.paths + 1] = path end
      local chunk_frames = plan.current_request_frames or math.floor(chunk_len * plan.rate + 0.5)
      plan.done_frames = math.min(plan.total_frames, plan.done_frames + chunk_frames)
      plan.awaiting_item = false
      self.export_wait_started = now
      self.finalize_started = now

      if plan.done_frames < plan.total_frames then
        local left = plan.total_frames - plan.done_frames
        plan.current_request_frames = math.min(plan.chunk_frames, left)
      else
        if not self:_merge_export_chunks(plan) then
          self.export_plan = nil
          self:_restore_item_selection()
          self.state = 'idle'
          self.error = 'could not join the exported recording chunks'
          if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(false) end
          return
        end
        self.export_plan = nil
        self.finalize_started = now
      end
    elseif now - (self.export_wait_started or now) > EXPORT_TIMEOUT then
      self.export_plan = nil
      self:_restore_item_selection()
      self.state = 'idle'
      self.error = 'the capture plug-in exported audio but REAPER never created an item'
      if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(false) end
    end
    return
  end

  -- A buffer export request can legitimately fail to acquire the capture JSFX
  -- for a single UI frame.  Never interpret that transient nil as an empty take.
  -- Keep the export plan intact and retry the SAME chunk.  This applies both to
  -- the first chunk after Stop and to every later chunk of a long recording.
  if self.export_plan and not self.export_serial then
    local plan = self.export_plan
    local now = R.time_precise()
    self.export_wait_started = self.export_wait_started or now

    -- Best-effort recovery is intentionally non-destructive: it re-enables the
    -- existing capture instance and therefore preserves its ring buffer.
    if now - (self.export_last_recover or 0) >= 0.25 then
      if self.buffer and self.buffer.recover then pcall(self.buffer.recover, self.buffer) end
      self.export_last_recover = now
    end

    local left = math.max(plan.total_frames - plan.done_frames, 0)
    if left > 0 then
      local n = plan.current_request_frames
      if not n or n <= 0 then
        n = math.min(plan.chunk_frames, left)
        plan.current_request_frames = n
      end
      local ok, serial = pcall(self.buffer.request_export, self.buffer,
        plan.start_frame + plan.done_frames, n, self:_track_index())
      if ok and serial then
        self.export_serial = serial
        self.export_wait_started = nil
        self.finalize_started = now
        return
      end
    end

    if now - self.export_wait_started > EXPORT_TIMEOUT then
      self.export_plan = nil
      self:_restore_item_selection()
      self.state = 'idle'
      self.error = 'the capture plug-in did not answer while exporting; recording was kept in the live buffer'
      if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(false) end
    end
    return
  end

  -- The plug-in writes the file from its own thread, which REAPER services at
  -- its own pace, so wait to be told the export finished before going looking
  -- for an item.
  if self.export_serial then
    local done = self.buffer:export_done(self.export_serial)
    if done == nil then
      if R.time_precise() - (self.finalize_started or 0) > EXPORT_TIMEOUT then
        self.export_serial = nil
        self:_restore_item_selection()
        self.state = 'idle'
        self.error = 'the capture plug-in did not answer'
        if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(false) end
      end
      return
    end
    self.export_serial = nil
    if done == false then
      self.export_plan = nil
      self:_restore_item_selection()
      self.state = 'idle'
      self.error = 'nothing left in the capture buffer to export'
      if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(false) end
      return
    end

    -- Remember that this serial succeeded. The next tick looks for the new
    -- item; it must not issue another export for the same frames.
    if self.export_plan then
      self.export_plan.awaiting_item = true
      self.export_wait_started = R.time_precise()
      self.finalize_started = self.export_wait_started
      return
    end

    -- Peak extraction gets its own budget now the complete/glued export exists.
    self.finalize_started = R.time_precise()
  end

  if R.CountTrackMediaItems(self.track) == 0 then
    if R.time_precise() - (self.finalize_started or 0) > PEAK_TIMEOUT then
      self.state = 'idle'
      self.error = 'nothing was recorded'
      if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(false) end
    end
    return
  end

  local item, item_count = self:_pass_item()
  local take = item and R.GetActiveTake(item)
  if not take then return end
  local source = R.GetMediaItemTake_Source(take)
  if not source then return end

  local length = R.GetMediaSourceLength(source)
  if type(length) ~= 'number' or length <= 0 then
    length = R.GetMediaItemInfo_Value(item, 'D_LENGTH')
  end
  local path = Util.source_filename(R, source)
  if path == '' then
    if R.time_precise() - (self.finalize_started or 0) > PEAK_TIMEOUT then
      self.state = 'idle'
      self.error = 'the exported take has no file path'
      if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(false) end
    end
    return
  end
  local peaks = self:_compute_peaks(take, length)
  local timed_out = R.time_precise() - (self.finalize_started or 0) > PEAK_TIMEOUT
  if not peaks and not timed_out then return end

  -- Do not replace a waveform the user just recorded with an empty strip.
  -- Normally the blue waveform comes from the finalized WAV. If REAPER cannot
  -- expose fresh-file peaks within the timeout, present the exact live waveform
  -- snapshot until/if the user chooses Rebuild waveform.
  local display_peaks = peaks
  local peaks_from_live = false
  if not display_peaks or #display_peaks == 0 then
    display_peaks = self.final_live_peaks or {}
    peaks_from_live = #display_peaks > 0
  end

  self.take_count = self.take_count + 1
  self.current = {
    index = self.take_count,
    path = path,
    length = length,
    peaks = display_peaks,
    peaks_from_live = peaks_from_live,
    name = Util.take_name(self.name_prefix, self.take_count),
    anchor = self.pending_anchor,
    timeline_map = (function()
      if not self.signal_record or #self.signal_segments == 0 then return nil end
      local out = {}
      for i,seg in ipairs(self.signal_segments) do
        out[i] = {
          file_start = seg.file_start or 0, file_end = seg.file_end or length,
          wall_start = seg.wall_start, wall_end = seg.wall_end
        }
      end
      return out
    end)(),
  }
  self.pending_anchor = nil
  self.section = nil
  if self.backend ~= 'buffer' then self:_report_short_take(length, item_count) end
  self:_clear_items()
  self:_restore_item_selection()
  self.state = 'ready'
  self.export_wait_started = nil
  self.export_last_recover = nil
  if self.backend == 'buffer' and self.buffer then self.buffer:set_paused(false) end
  -- Start the arrange .reapeaks file now, while the take is already on disk
  -- and recording is over. A later drag then has a cache to draw.
  self:_request_arrange_peaks(path)
  R.UpdateArrange()
end

--[[
  REAPER can end a pass without being asked: punched out at the end of a time
  selection, stopped from the transport, or stopped by a script. Noticing that
  keeps the strip from metering a recording that is no longer being written,
  which is what made the live view and the finished take disagree.
]]
function Engine:_poll_transport()
  -- The take may already have been closed earlier in this same frame, by auto
  -- record deciding the sound was over. Nothing left to watch.
  if self.state ~= 'recording' then return end
  -- Nothing to watch on the buffer backend: it does not use the transport, so
  -- the user is free to play, stop and scrub while a take is being marked.
  -- A stale heartbeat is not a dead plug-in: after pause, @block often stops
  -- while @gfx (gfx_idle) is still able to export. Only give up if the FX is
  -- no longer on the track.
  if self.backend == 'buffer' then
    if not (self.buffer and (self.buffer.loaded and self.buffer:loaded() or self.buffer.attached)) then
      self:stop()
      self:_notify('the capture plug-in stopped responding')
    end
    return
  end

  local recording = self:_reaper_is_recording()
  if recording == nil then return end
  if recording then
    self.seen_recording = true
    return
  end
  -- Recording takes a frame or two to spin up, so an idle transport only
  -- counts once it has been seen rolling or the grace period has passed.
  if not self.seen_recording
    and self.api.time_precise() - (self.started_at or 0) < RECORD_START_GRACE then
    return
  end
  self:stop()
  self:_notify('REAPER ended the recording — the take holds what was written')
end

--- Drives async work. Call once per UI frame.
function Engine:tick()
  -- The capture buffer is only useful if it has been filling before Record is
  -- pressed, so it is brought up as soon as the strip is on screen.
  if self.backend == 'buffer' then
    if not (self.buffer and self.buffer.attached) then
      if self.state ~= 'recording' then self:_ensure_capture() end
    else
      self:_watch_capture()
    end
  end
  if self.state == 'recording' then
    self:_poll_live_meter()
    self:_poll_auto_stop()
    self:_poll_transport()
  end
  if self.state == 'finalizing' then self:_poll_finalize() end
  self:_poll_preview()
end

--------------------------------------------------------------------------------
-- Sections
--------------------------------------------------------------------------------

function Engine:set_section(anchor_a, anchor_b)
  if not self.current then return end
  self.section = Util.make_section(anchor_a, anchor_b, self.current.length)
end

function Engine:clear_section()
  self.section = nil
end

function Engine:effective_section()
  if not self.current then return nil end
  return Util.effective_section(self.section, self.current.length)
end

--[[
  Turns a position inside the current take back into the wall clock reading it
  was captured at, so a host can look up what it was doing at that moment.
  Returns nil when the take was made before anchors existed or the backend
  could not work one out.
]]
function Engine:wall_time_at(position)
  if not self.current then return nil end
  local length = self.current.length or 0
  local pos = Util.clamp(position or 0, 0, length)

  -- Signal Session removes wall-clock silence from the file. Use the segment
  -- map captured as the session ran so a click at (say) 31 s in the compact WAV
  -- resolves to the shot that really produced that audio, even if minutes passed
  -- between earlier iterations.
  local map = self.current.timeline_map
  if map and #map > 0 then
    local chosen = map[#map]
    for _,seg in ipairs(map) do
      local a = seg.file_start or 0
      local b = seg.file_end or a
      if pos >= a and pos <= b + 0.000001 then chosen = seg; break end
      if pos < a then chosen = seg; break end
    end
    if chosen and chosen.wall_start then
      local a = chosen.file_start or 0
      local b = chosen.file_end or a
      local local_pos = Util.clamp(pos - a, 0, math.max(b - a, 0))
      return chosen.wall_start + local_pos
    end
  end

  if not self.current.anchor then return nil end
  return self.current.anchor + pos
end

function Engine:discard()
  self:stop_preview()
  self.current = nil
  self.section = nil
  self.state = 'idle'
end

--------------------------------------------------------------------------------
-- Dropping into the project
--------------------------------------------------------------------------------

--[[
  Resolves what sits under a native screen coordinate.
  Returns a table { track, position, kind } or nil when the point is not a
  usable drop location (over the recorder window, the mixer, a menu, ...).
]]
function Engine:drop_target(native_x, native_y)
  local R = self.api
  local track, info = R.GetThingFromPoint(native_x, native_y)
  info = info or ''

  if info:find('arrange', 1, true) then
    local view_start = R.GetSet_ArrangeView2(0, false, native_x, native_x + 1)
    local position = view_start or 0
    if R.GetToggleCommandStateEx(0, ACTION_TOGGLE_SNAP) == 1 then
      position = R.SnapToGrid(0, position)
    end
    return { track = track, position = math.max(0, position), kind = track and 'arrange' or 'empty' }
  end

  if info:find('tcp', 1, true) and track then
    return { track = track, position = R.GetCursorPosition(), kind = 'tcp' }
  end

  return nil
end

--[[
  Inserts the active section as a new item. `target.track` may be nil, in which
  case a new track is appended so a drop on empty arrange space still works.
]]
function Engine:insert(target)
  local R = self.api
  if not self.current then return nil end
  if type(self.current.path) ~= 'string' or self.current.path == '' then return nil end
  local section = self:effective_section()
  if not section or section.len <= 0 then return nil end

  local track = target and target.track
  local position = (target and target.position) or R.GetCursorPosition()

  R.Undo_BeginBlock()
  R.PreventUIRefresh(1)

  if not (track and R.ValidatePtr2(0, track, 'MediaTrack*')) then
    local idx = R.CountTracks(0)
    R.InsertTrackAtIndex(idx, true)
    track = R.GetTrack(0, idx)
    R.GetSetMediaTrackInfo_String(track, 'P_NAME', self.name_prefix, true)
  end

  local item = R.AddMediaItemToTrack(track)
  local take = R.AddTakeToMediaItem(item)
  local source = R.PCM_Source_CreateFromFile(self.current.path)
  R.SetMediaItemTake_Source(take, source)
  R.SetMediaItemPosition(item, position, false)
  R.SetMediaItemLength(item, section.len, false)
  R.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', section.start)
  R.GetSetMediaItemTakeInfo_String(take, 'P_NAME',
    Util.take_name(self.name_prefix, self.current.index, self.section), true)

  R.PreventUIRefresh(-1)
  if R.UpdateItemInProject then R.UpdateItemInProject(item) end
  -- Ask REAPER to fill missing arrange peaks for this file. Glue (40362)
  -- does the same thing by writing a new file; this only builds the cache.
  if R.Main_OnCommand then R.Main_OnCommand(ACTION_BUILD_MISSING_PEAKS, 0) end
  self:_request_arrange_peaks(self.current.path, item)
  R.UpdateArrange()
  R.Undo_EndBlock('ADFX Recorder: insert recording', -1)
  return item
end

--------------------------------------------------------------------------------
-- Preview (SWS/js_ReaScriptAPI "CF_" preview functions, optional)
--------------------------------------------------------------------------------

function Engine:can_preview()
  return self:_has('CF_CreatePreview') and self:_has('CF_Preview_Play')
end

function Engine:previewing()
  return self.preview ~= nil
end

function Engine:stop_preview()
  if self.preview then
    pcall(self.api.CF_Preview_Stop, self.preview)
    self.preview = nil
  end
  self.preview_pos = nil
end

function Engine:_start_preview(from, stop_at)
  local R = self.api
  if type(self.current.path) ~= 'string' or self.current.path == '' then return false end
  local source = R.PCM_Source_CreateFromFile(self.current.path)
  if not source then return false end
  local preview = R.CF_CreatePreview(source)
  if not preview then return false end
  R.CF_Preview_SetValue(preview, 'D_POSITION', from)
  R.CF_Preview_SetValue(preview, 'B_LOOP', 0)
  R.CF_Preview_Play(preview)
  self.preview = preview
  self.preview_stop_at = stop_at
  self.preview_pos = from
  return true
end

function Engine:toggle_preview()
  if self.preview then
    self:stop_preview()
    return false
  end
  if not (self.current and self:can_preview()) then return false end
  local section = self:effective_section()
  return self:_start_preview(section.start, section.start + section.len)
end

--[[
  Play from one point in the recording, which is what a double click on the
  waveform asks for. Playback runs to the end of the isolated section when the
  point is inside it, and to the end of the take otherwise, so a click outside
  an isolation is not silently dragged into it.
]]
function Engine:play_from(position)
  if not (self.current and self:can_preview()) then return false end
  local length = self.current.length or 0
  local from = Util.clamp(position or 0, 0, length)
  local section = self:effective_section()
  local section_end = section.start + section.len
  local stop_at = length
  if from >= section.start and from < section_end then stop_at = section_end end
  if stop_at - from < MIN_PREVIEW_SECONDS then return false end
  self:stop_preview()
  return self:_start_preview(from, stop_at)
end

function Engine:_poll_preview()
  if not self.preview then return end
  local ok, pos = pcall(self.api.CF_Preview_GetValue, self.preview, 'D_POSITION')
  if not ok then
    self:stop_preview()
    return
  end
  -- CF_Preview_GetValue returns (retval, value) in some builds.
  if type(pos) == 'boolean' then pos = select(2, self.api.CF_Preview_GetValue(self.preview, 'D_POSITION')) end
  self.preview_pos = pos
  if not pos or pos >= (self.preview_stop_at or 0) then self:stop_preview() end
end

--------------------------------------------------------------------------------
-- Teardown
--------------------------------------------------------------------------------

function Engine:shutdown()
  local R = self.api
  if self.state == 'recording' then self:stop() end
  self:stop_preview()
  self:_restore_item_selection()
  if self.buffer then
    self.buffer:detach()
    self.buffer = nil
  end
  self:_close_routing()
  self:_restore_arm()
  self:_restore_repeat()
  self:_restore_transport()
  if self.cleanup_on_exit and self.track and R.ValidatePtr2(0, self.track, 'MediaTrack*') then
    self:_clear_items()
    R.DeleteTrack(self.track)
    self.track = nil
    R.TrackList_AdjustWindows(false)
    R.UpdateArrange()
  end
end

return Engine
