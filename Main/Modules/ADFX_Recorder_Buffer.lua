-- @description ADFX_Recorder_Buffer
-- @version 1.0.0
-- @author ADFXSound

--[[
  ADFX_Recorder_Buffer.lua
  ----------------------------------------------------------------------------
  Talks to ADFX_Recorder_Capture.jsfx, the continuous capture buffer.

  REAPER will only write a recording while the transport is rolling, so the
  transport based capture path has to roll the project to record anything. A
  JSFX does not: its @sample section runs whenever audio flows through the
  track, stopped or not. The plug-in keeps the last few minutes in a ring
  buffer and, on request, writes a slice of it into the project.

  This module owns the shared memory conversation with that plug-in. It knows
  nothing about the strip or about takes; the engine drives it.
]]

local Buffer = {}
Buffer.__index = Buffer
Buffer.VERSION = '1.2.1'

Buffer.GMEM_NAME = 'ADFX_Recorder'
Buffer.FX_NAME = 'ADFX_Recorder_Capture'

local PROTOCOL = 1
local SLOT_BASE = 64
local SLOT_STRIDE = 32
local SLOT_COUNT = 8

-- Field offsets inside a slot. Mirrors the header of the JSFX.
local F_HEARTBEAT   = 0
local F_SRATE       = 1
local F_CAPACITY    = 2
local F_FRAMES      = 3
local F_PEAK        = 4
local F_PAUSE       = 5
local F_REQUEST     = 6
local F_START       = 7
local F_LENGTH      = 8
local F_TRACK       = 9
local F_RESULT      = 10
local F_SERIAL      = 11
local F_SERIAL_DONE = 12
local F_PROTOCOL    = 13

-- Slider indices in the JSFX, 0 based.
local PARAM_SLOT = 0
local PARAM_SECONDS = 1

-- A slot whose plug-in has not reported in for this long is free to claim.
local HEARTBEAT_TIMEOUT = 2.0

-- Names to try when loading the plug-in. REAPER resolves a path relative to
-- its Effects folder, which works for a JSFX that was only just copied in;
-- the descriptive name needs the FX list to have been rescanned.
local FX_LOOKUPS = {
  'ADFX/ADFX_Recorder_Capture',
  'ADFX_Recorder_Capture',
  'JS: ADFX Recorder Capture',
}

function Buffer.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Buffer)
  self.api = opts.api or reaper
  self.seconds = opts.buffer_seconds or 120
  -- The shared memory space the host script uses for its own plug-ins, if it
  -- has one. See the borrowing note at the foot of this file.
  self.host_gmem = opts.host_gmem
  self.depth = 0
  self.slot = nil
  self.fx = nil
  self.track = nil
  self.serial = 0
  self.attached = false
  return self
end

function Buffer:_has(fn)
  return type(self.api[fn]) == 'function'
end

--[[
  A script has exactly one gmem attachment, and every gmem_read and gmem_write
  it makes goes to whichever space it attached to last. So this module cannot
  simply attach its own space and keep it: doing that redirects the host
  script's own shared memory traffic into the recorder's block. S-Layer talks
  to its trigger plug-ins that way, and silently lost every note.

  Instead the attachment is borrowed for the duration of a call and handed
  back, so the host's space is what is attached at every point the host might
  use it.
]]
function Buffer:_enter()
  self.depth = self.depth + 1
  if self.depth == 1 and self:_has('gmem_attach') then
    self.api.gmem_attach(Buffer.GMEM_NAME)
  end
end

function Buffer:_leave()
  self.depth = self.depth - 1
  if self.depth == 0 and self.host_gmem and self:_has('gmem_attach') then
    self.api.gmem_attach(self.host_gmem)
  end
end

--- True when this REAPER can run the capture plug-in at all.
function Buffer:supported()
  return self:_has('gmem_attach') and self:_has('gmem_read') and self:_has('gmem_write')
    and self:_has('TrackFX_AddByName') and self:_has('TrackFX_SetParam')
end

function Buffer:_read(field)
  if not self.slot then return 0 end
  return self.api.gmem_read(SLOT_BASE + self.slot * SLOT_STRIDE + field) or 0
end

function Buffer:_write(field, value)
  if not self.slot then return end
  self.api.gmem_write(SLOT_BASE + self.slot * SLOT_STRIDE + field, value)
end

function Buffer:_slot_heartbeat(slot)
  return self.api.gmem_read(SLOT_BASE + slot * SLOT_STRIDE + F_HEARTBEAT) or 0
end

--[[
  Picks a slot nobody is using. Several ADFX scripts can capture at the same
  time, so each needs its own corner of the shared memory block; a slot whose
  plug-in has stopped reporting has been closed and can be reused.
]]
function Buffer:_claim_slot()
  local now = self.api.time_precise()
  for slot = 0, SLOT_COUNT - 1 do
    local beat = self:_slot_heartbeat(slot)
    if beat == 0 or now - beat > HEARTBEAT_TIMEOUT then return slot end
  end
  return nil
end

function Buffer:_find_fx(track)
  local R = self.api
  for _, name in ipairs(FX_LOOKUPS) do
    local idx = R.TrackFX_AddByName(track, name, false, 0)
    if idx and idx >= 0 then return idx end
  end
  return nil
end

function Buffer:_add_fx(track)
  local R = self.api
  for _, name in ipairs(FX_LOOKUPS) do
    local idx = R.TrackFX_AddByName(track, name, false, 1)
    if idx and idx >= 0 then return idx end
  end
  return nil
end

--[[
  Puts the capture plug-in on the track and claims a slot for it. Returns
  false plus a reason the caller can show if anything is missing, so the
  engine can fall back to transport recording rather than failing outright.
]]
function Buffer:attach(track)
  local R = self.api
  if not self:supported() then
    return false, 'this REAPER has no JSFX shared memory support'
  end

  local existing = self:_find_fx(track)
  local fx = existing or self:_add_fx(track)
  if not fx then
    return false, 'ADFX_Recorder_Capture.jsfx is not installed'
  end

  -- Never let the plug-in window pop up in the user's face.
  if self:_has('TrackFX_Show') then R.TrackFX_Show(track, fx, 2) end

  if existing then
    -- Reclaim whatever slot the plug-in left behind on the previous run.
    self.slot = math.floor((R.TrackFX_GetParam(track, fx, PARAM_SLOT) or 0) + 0.5)
  else
    self.slot = self:_claim_slot()
    if not self.slot then
      return false, 'all capture slots are in use'
    end
    R.TrackFX_SetParam(track, fx, PARAM_SLOT, self.slot)
  end
  R.TrackFX_SetParam(track, fx, PARAM_SECONDS, self.seconds)

  self.track = track
  self.fx = fx
  self.attached = true
  return true
end

function Buffer:detach()
  if self.track and self.fx and self:_has('TrackFX_Delete')
    and self.api.ValidatePtr2(0, self.track, 'MediaTrack*') then
    self.api.TrackFX_Delete(self.track, self.fx)
  end
  self.attached = false
  self.track, self.fx, self.slot = nil, nil, nil
end

--- True while the plug-in is loaded and processing audio.
function Buffer:alive()
  if not self.attached or not self.slot then return false end
  if self:_read(F_PROTOCOL) ~= PROTOCOL then return false end
  return self.api.time_precise() - self:_read(F_HEARTBEAT) <= HEARTBEAT_TIMEOUT
end

function Buffer:srate()
  local rate = self:_read(F_SRATE)
  return rate > 0 and rate or nil
end

--- Frames captured since the plug-in loaded. Never resets, so it can be used
--- as a clock that has nothing to do with the transport.
function Buffer:frames()
  return self:_read(F_FRAMES)
end

function Buffer:capacity_frames()
  return self:_read(F_CAPACITY)
end

function Buffer:capacity_seconds()
  local rate = self:srate()
  if not rate then return 0 end
  return self:capacity_frames() / rate
end

--- Loudest sample since the last call, which is what the strip meters.
function Buffer:read_peak()
  if not self:alive() then return nil end
  local peak = self:_read(F_PEAK)
  self:_write(F_PEAK, 0)
  return peak
end

function Buffer:set_paused(paused)
  self:_write(F_PAUSE, paused and 1 or 0)
end

--[[
  Asks the plug-in to write frames [start, start + length) onto a track.
  The copy and the export happen in the plug-in's @gfx thread, so this
  returns a ticket to poll rather than a result.
]]
function Buffer:request_export(start_frame, length_frames, track_index)
  if not self:alive() then return nil end
  self.serial = self.serial + 1
  self:_write(F_RESULT, 0)
  self:_write(F_START, start_frame)
  self:_write(F_LENGTH, length_frames)
  self:_write(F_TRACK, track_index)
  self:_write(F_SERIAL, self.serial)
  self:_write(F_REQUEST, 1)
  return self.serial
end

--- nil while the export is still running, true when it wrote an item,
--- false when the plug-in refused (nothing left in the buffer to write).
function Buffer:export_done(serial)
  if not serial then return false end
  if self:_read(F_SERIAL_DONE) < serial then return nil end
  return self:_read(F_RESULT) == 1
end

--[[
  Everything that touches shared memory goes through the borrow, including
  attach, which claims a slot. Wrapping here rather than inside each method
  keeps the bodies readable and makes it impossible to add a method that
  forgets to hand the attachment back.
]]
for _, name in ipairs({
  'attach', 'alive', 'srate', 'frames', 'capacity_frames', 'capacity_seconds',
  'read_peak', 'set_paused', 'request_export', 'export_done',
}) do
  local inner = Buffer[name]
  Buffer[name] = function(self, ...)
    self:_enter()
    local out = table.pack(inner(self, ...))
    self:_leave()
    return table.unpack(out, 1, out.n)
  end
end

return Buffer
