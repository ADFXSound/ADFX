-- @description ADFX_Recorder
-- @version 2.0.0
-- @author ADFXSound

--[[
  ADFX_Recorder.lua  —  shared output recorder strip for the ADFX tools
  ----------------------------------------------------------------------------
  v1.5.2: enlarged the waveform strip and removed the unused idle bottom padding.
  v1.5.1: removed the redundant RECORDER title row and reclaimed its vertical space.

  A self contained ReaImGui footer that records what a script is making, shows
  the result as a waveform, and hands it to the project:

    * left click + drag the waveform into the arrange view to place the take
      (drop on a track, or on empty space to get a fresh track)
    * right click + drag across the waveform to isolate a section; everything
      after that (drag out, insert, preview) uses only that section
    * right click without dragging opens the recorder menu
    * double click plays from that point; hosts that route the space bar
      through Recorder:consume_space() let space stop it
    * double click outside an isolated section clears the isolation

  Slot in at the bottom of a script's ImGui window:

      local sep = package.config:sub(1, 1)
      local Recorder = dofile(reaper.GetResourcePath() .. sep .. 'Scripts' ..
        sep .. 'ADFX' .. sep .. 'Modules' .. sep .. 'ADFX_Recorder.lua')

      local recorder = Recorder.new({ id = 'adfx_s_layer',
                                      name_prefix = 'ADFX_S-Layer' })
      -- ... inside the frame, as the last thing in the window:
      recorder:draw(ctx)
      -- ... when the script closes:
      recorder:shutdown()

  Options for Recorder.new:
    id                  unique string per host script (keeps the hidden
                        capture track and settings separate)
    name_prefix         track / take / file name prefix
    capture             'master' (default) or 'track'
    get_source_track    function returning a MediaTrack, used by 'track' mode
    transport           'timeline' (default) records a pass over the project
                        from the edit cursor; 'isolated' rolls past the end of
                        the project so nothing on the timeline plays and only
                        what the host triggers live is captured
    allow_transport_switch  show the Timeline/Isolated toggle, default true
    height              waveform height in px, default 72
    allow_capture_switch  show the Master/Track toggle, default true
    solo_arm            disarm other tracks while capturing, default true
    cleanup_on_exit     delete the hidden capture track on shutdown, default true
    on_insert           function(rec, section, target) called after a drop
    menu_items          extra right click menu entries, each
                        { label, enabled = bool or function(),
                          action = function(take_position) }; the action may
                        return a string to show in the strip
    imgui               optional ReaImGui table (for hosts using
                        `require 'imgui' '0.9'`); omit to use reaper.ImGui_*
]]

local sep = package.config:sub(1, 1)
local MODULE_DIR = reaper.GetResourcePath() .. sep .. 'Scripts' .. sep ..
  'ADFX' .. sep .. 'Modules' .. sep
local Util = dofile(MODULE_DIR .. 'ADFX_Recorder_Util.lua')
local Engine = dofile(MODULE_DIR .. 'ADFX_Recorder_Engine.lua')

local Recorder = {}
Recorder.__index = Recorder
Recorder.VERSION = '1.5.2'
Recorder.Util = Util
Recorder.Engine = Engine

local COL = {
  panel      = 0x1B1E23FF,
  strip_bg   = 0x121418FF,
  border     = 0x333A44FF,
  border_hot = 0x4C566AFF,
  mid        = 0x2A2F36FF,
  wave       = 0x6FD1FFFF,
  wave_dim   = 0x3C4653FF,
  wave_rec   = 0xE2453CFF,
  iso_fill   = 0x6FD1FF1A,
  iso_edge   = 0x9BE3FFCC,
  shade      = 0x0B0D1099,
  text       = 0xC3CBD6FF,
  text_dim   = 0x7C8695FF,
  text_warn  = 0xE7A33EFF,
  playhead   = 0xFFD166FF,
}

local MIN_DRAG_PX = 4.0

-- How long the live waveform takes to fill the strip before it starts
-- compressing to keep the whole take in view.
local LIVE_FILL_SECONDS = 6.0

--------------------------------------------------------------------------------
-- ReaImGui adapter: works with reaper.ImGui_* and with the 0.9+ module table
--------------------------------------------------------------------------------

local function make_imgui(provided)
  if provided then return provided end
  return setmetatable({}, {
    __index = function(t, key)
      local fn = reaper['ImGui_' .. key]
      t[key] = fn
      return fn
    end,
  })
end

--[[
  Looks up an optional ReaImGui function. The versioned module shim
  (`require 'imgui' '0.10'`) raises rather than returning nil for names it does
  not carry, so the lookup itself has to be guarded.
]]
local function has(IM, name)
  local ok, value = pcall(function() return IM[name] end)
  if ok and type(value) == 'function' then return value end
  return nil
end

--- Reads an ImGui constant in either API style.
local function const(IM, name)
  local ok, value = pcall(function() return IM[name] end)
  if not ok then return nil end
  if type(value) == 'function' then return value() end
  return value
end

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function Recorder.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Recorder)
  self.id = opts.id or 'adfx_recorder'
  self.height = opts.height or 90
  self.allow_capture_switch = opts.allow_capture_switch ~= false
  self.allow_transport_switch = opts.allow_transport_switch ~= false
  self.grab_seconds = opts.grab_seconds or 10
  -- Only worth offering to a host that actually calls signal_trigger().
  self.allow_auto_record = opts.allow_auto_record == true or opts.auto_record == true
  self.on_insert = opts.on_insert
  -- Host-supplied menu entries, appended under their own separator. Each is
  -- { label, enabled = bool or function(), action = function(time) }, where
  -- time is the point in the take the menu was opened over.
  self.menu_items = opts.menu_items or {}
  self.IM = make_imgui(opts.imgui)
  self.engine = Engine.new({
    id = self.id,
    name_prefix = opts.name_prefix or 'ADFX_Recorder',
    capture = opts.capture,
    transport = opts.transport,
    backend = opts.backend,
    buffer_seconds = opts.buffer_seconds,
    host_gmem = opts.host_gmem,
    get_source_track = opts.get_source_track,
    solo_arm = opts.solo_arm,
    cleanup_on_exit = opts.cleanup_on_exit,
    rec_mode = opts.rec_mode,
    auto_record = opts.auto_record,
    silence_level = opts.silence_level,
    tail_seconds = opts.tail_seconds,
  })
  self.popup_id = 'adfx_recorder_menu_' .. self.id
  self.message = nil
  self.message_until = 0
  return self
end

--[[
  Space bar, offered to the recorder before the host acts on it.

  Returns true when the recorder used the key, which means the host must not.
  Playback is the only thing it claims: while a take is playing, space stops it
  and goes no further, and the next space is the host's again. That way one key
  does not both stop the playback and fire the instrument.
]]
function Recorder:consume_space()
  if self.engine:previewing() then
    self.engine:stop_preview()
    self:_notify('Playback stopped')
    return true
  end
  return false
end

function Recorder:previewing() return self.engine:previewing() end

--- Wall clock reading for a position in the current take, or nil if unknown.
function Recorder:wall_time_at(position) return self.engine:wall_time_at(position) end

function Recorder:is_recording() return self.engine:is_recording() end
function Recorder:record() return self.engine:start() end
function Recorder:stop() return self.engine:stop() end
function Recorder:toggle() return self.engine:toggle() end
function Recorder:recording() return self.engine.current end

--[[
  Hosts call this the moment they play something. With Auto on it opens a take
  that closes itself once the sound has decayed; with Auto off it does nothing,
  so it is safe to call unconditionally from a trigger path.
]]
function Recorder:signal_trigger() return self.engine:signal_trigger() end

function Recorder:shutdown()
  self.engine:shutdown()
end

--[[
  Total height the strip occupies, including its buttons, waveform and hint line.
  Hosts that pin the recorder to the bottom of a window subtract this from the
  space they give their own content, e.g.

      local footer = recorder:reserved_height(ctx)
      ImGui.BeginChild(ctx, '##body', 0, -footer, 0, 0)
]]
function Recorder:reserved_height(ctx, opts)
  local IM = self.IM
  local strip = (opts and opts.height) or self.height
  local text_line = has(IM, 'GetTextLineHeightWithSpacing')
  local frame_line = has(IM, 'GetFrameHeightWithSpacing')
  local text_h = text_line and text_line(ctx) or 18
  local frame_h = frame_line and frame_line(ctx) or 26

  -- Only reserve the status/hint row when Recorder will actually draw one.
  -- At idle there is no text below the waveform, so giving that row space just
  -- looked like dead bottom padding. The reclaimed space goes into the taller
  -- waveform instead.
  local engine = self.engine
  local has_status =
    (self.message and reaper.time_precise() < self.message_until) or
    engine:previewing() or
    (engine.current ~= nil)

  return strip + frame_h + 12 + (has_status and text_h or 0)
end

function Recorder:_notify(text)
  self.message = text
  self.message_until = reaper.time_precise() + 4
end

--------------------------------------------------------------------------------
-- Waveform rendering
--------------------------------------------------------------------------------

--[[
  Paints one vertical line per pixel column from folded min/max buckets.
  `colour` is either a colour or a function of the 0..1 position across the
  span, which is how the isolated range is tinted differently.
]]
local function paint_columns(IM, dl, x, y, w, h, peaks, ceiling, colour)
  local mid = y + h * 0.5
  local half = math.max(h * 0.5 - 3, 2)
  local columns = math.max(math.floor(w), 1)
  for i = 0, columns - 1 do
    local position = columns > 1 and i / (columns - 1) or 0
    local p = Util.peak_at(peaks, position)
    if p then
      local top = mid - (p.max / ceiling) * half
      local bottom = mid - (p.min / ceiling) * half
      if bottom - top < 1 then bottom = top + 1 end
      IM.DrawList_AddLine(dl, x + i + 0.5, top, x + i + 0.5, bottom,
        type(colour) == 'function' and colour(position) or colour, 1.0)
    end
  end
end

function Recorder:_draw_placeholder(dl, x, y, w, h)
  local IM = self.IM
  IM.DrawList_AddRectFilled(dl, x, y, x + w, y + h, COL.strip_bg, 4)
  IM.DrawList_AddRect(dl, x, y, x + w, y + h, COL.border, 4)
  local mid = y + h * 0.5
  local engine = self.engine

  if engine:is_recording() or engine.state == 'finalizing' then
    local live = engine:live_peaks()
    if #live > 0 then
      -- Grow left to right at a fixed rate, then fit the whole take to the
      -- strip once it is full, so the shape matches the finished waveform.
      local elapsed = engine:elapsed()
      local filled = math.min(elapsed / LIVE_FILL_SECONDS, 1)
      local live_w = math.max(w * filled, 2)
      paint_columns(IM, dl, x, y, live_w, h, live, engine:live_ceiling(), COL.wave_rec)
      local head = x + live_w
      IM.DrawList_AddLine(dl, head, y + 1, head, y + h - 1, COL.playhead, 1.5)
    else
      IM.DrawList_AddLine(dl, x, mid, x + w, mid, COL.wave_rec, 1.0)
    end
    local peak_db = engine:live_peak_db()
    local caption = string.format('Recording  %s   %s', Util.format_time(engine:elapsed()),
      peak_db and string.format('peak %.1f dB', peak_db) or 'waiting for signal')
    IM.DrawList_AddText(dl, x + 8, y + 6, COL.text, caption)
    return
  end

  IM.DrawList_AddLine(dl, x, mid, x + w, mid, COL.mid, 1.0)
  -- Idle instructional text intentionally hidden.
end

function Recorder:_draw_wave(dl, x, y, w, h, rec, section)
  local IM = self.IM
  IM.DrawList_AddRectFilled(dl, x, y, x + w, y + h, COL.strip_bg, 4)
  local mid = y + h * 0.5
  local half = math.max(h * 0.5 - 3, 2)
  local peaks = rec.peaks or {}

  if #peaks == 0 then
    -- No waveform could be read: show the take as a solid block so it is still
    -- obvious what there is to drag and isolate.
    IM.DrawList_AddRectFilled(dl, x + 1, mid - half * 0.6, x + w - 1, mid + half * 0.6,
      COL.wave_dim, 2)
    IM.DrawList_AddText(dl, x + 8, y + 6, COL.text_warn,
      'No waveform — right-click and choose Rebuild waveform')
  else
    local ceiling = math.max(Util.peak_ceiling(peaks), 0.05)
    paint_columns(IM, dl, x, y, w, h, peaks, ceiling, function(position)
      local t = position * rec.length
      local inside = t >= section.start and t <= section.start + section.len
      return inside and COL.wave or COL.wave_dim
    end)
  end

  -- Isolation overlay
  if self.engine.section then
    local sx = Util.time_to_x(section.start, 0, rec.length, x, x + w)
    local ex = Util.time_to_x(section.start + section.len, 0, rec.length, x, x + w)
    IM.DrawList_AddRectFilled(dl, x, y, sx, y + h, COL.shade)
    IM.DrawList_AddRectFilled(dl, ex, y, x + w, y + h, COL.shade)
    IM.DrawList_AddRectFilled(dl, sx, y, ex, y + h, COL.iso_fill)
    IM.DrawList_AddLine(dl, sx, y, sx, y + h, COL.iso_edge, 1.5)
    IM.DrawList_AddLine(dl, ex, y, ex, y + h, COL.iso_edge, 1.5)
    local label = string.format('%s  ·  %s', Util.format_duration(section.len),
      Util.format_time(section.start))
    IM.DrawList_AddText(dl, math.min(sx + 5, x + w - 120), y + 5, COL.iso_edge, label)
  end

  if self.engine.preview_pos then
    local px = Util.time_to_x(self.engine.preview_pos, 0, rec.length, x, x + w)
    IM.DrawList_AddLine(dl, px, y, px, y + h, COL.playhead, 1.5)
  end

  IM.DrawList_AddRect(dl, x, y, x + w, y + h,
    self.drag and COL.border_hot or COL.border, 4)
end

--------------------------------------------------------------------------------
-- Interaction
--------------------------------------------------------------------------------

function Recorder:_handle_drag_out(ctx, x, y, w, h)
  local IM = self.IM
  if IM.IsItemActive(ctx) and IM.IsMouseDragging(ctx, 0, MIN_DRAG_PX) then
    self.drag = true
  end
  if not self.drag then return end

  local mx, my = IM.GetMousePos(ctx)
  local over_strip = mx >= x and mx <= x + w and my >= y and my <= y + h
  local section = self.engine:effective_section()

  IM.SetTooltip(ctx, over_strip
    and 'Drag onto a track in the arrange view'
    or string.format('Drop to insert  (%s)', Util.format_duration(section.len)))

  if not IM.IsMouseDown(ctx, 0) then
    self.drag = false
    if not over_strip then
      local nx, ny = mx, my
      local convert = has(IM, 'PointConvertNative')
      if convert then nx, ny = convert(ctx, mx, my, true) end
      local target = self.engine:drop_target(nx, ny)
      if target then
        local item = self.engine:insert(target)
        if item then
          self:_notify(string.format('Inserted %s at %s',
            Util.format_duration(section.len), Util.format_time(target.position)))
          if self.on_insert then self.on_insert(self.engine.current, section, target) end
        else
          self:_notify('Could not insert the recording')
        end
      else
        self:_notify('Drop on the arrange view to insert')
      end
    end
  end
end

function Recorder:_handle_isolate(ctx, x, w, rec)
  local IM = self.IM
  local function time_at_mouse()
    local mx = IM.GetMousePos(ctx)
    return Util.clamp(Util.x_to_time(mx, x, x + w, 0, rec.length), 0, rec.length)
  end

  if IM.IsItemClicked(ctx, 1) then
    self.iso_anchor = time_at_mouse()
    -- Kept for the menu, which opens on release and needs to know where the
    -- gesture started rather than where the pointer has drifted to.
    self.menu_at = self.iso_anchor
    self.iso_moved = false
    return
  end

  if not self.iso_anchor then return end

  if IM.IsMouseDown(ctx, 1) then
    local t = time_at_mouse()
    if math.abs(t - self.iso_anchor) > rec.length * 0.002 then
      self.iso_moved = true
      self.engine:set_section(self.iso_anchor, t)
    end
  else
    if not self.iso_moved then IM.OpenPopup(ctx, self.popup_id) end
    self.iso_anchor = nil
  end
end

--[[
  Whatever the host added, at the bottom of the menu. A host entry is given the
  take position the menu was opened over, and may return a string to say what it
  did. It runs inside a pcall so a broken entry cannot take the strip down mid
  frame, leaving ImGui's popup stack unbalanced.
]]
function Recorder:_host_menu_items(ctx)
  local items = self.menu_items
  if not (items and #items > 0) then return end
  local IM = self.IM
  IM.Separator(ctx)
  for _, entry in ipairs(items) do
    local enabled = entry.enabled
    if type(enabled) == 'function' then enabled = enabled() end
    if enabled == nil then enabled = true end
    if IM.MenuItem(ctx, entry.label or '(unnamed)', nil, false, enabled and true or false) then
      local ok, result = pcall(entry.action, self.menu_at or 0)
      if not ok then
        self:_notify('That menu item failed')
      elseif type(result) == 'string' then
        self:_notify(result)
      end
    end
  end
end

function Recorder:_menu(ctx)
  local IM = self.IM
  if not IM.BeginPopup(ctx, self.popup_id) then return end
  local engine = self.engine
  local section = engine:effective_section()

  IM.Text(ctx, Util.short_name(engine.current and engine.current.path, 40))
  -- Which build is loaded, so a stale copy in REAPER's Scripts folder can be
  -- spotted without reading the file.
  IM.TextColored(ctx, COL.text_dim, string.format('ADFX Recorder %s  ·  %s', Recorder.VERSION,
    engine:buffer_ready()
      and string.format('capture buffer, %s', Util.format_duration(engine:buffer_seconds_held() or 0))
      or (engine.transport .. ' roll')))
  IM.Separator(ctx)

  if IM.MenuItem(ctx, 'Insert section at edit cursor') then
    local track = reaper.GetSelectedTrack(0, 0)
    local item = engine:insert({ track = track, position = reaper.GetCursorPosition() })
    if item then
      self:_notify('Inserted at edit cursor')
      if self.on_insert then self.on_insert(engine.current, section, { track = track }) end
    end
  end

  if engine:can_preview() then
    local playing = engine.preview ~= nil
    if IM.MenuItem(ctx, playing and 'Stop preview' or 'Preview section') then
      engine:toggle_preview()
    end
  end

  IM.Separator(ctx)
  if IM.MenuItem(ctx, 'Clear isolation', nil, false, engine.section ~= nil) then
    engine:clear_section()
  end
  if IM.MenuItem(ctx, 'Rebuild waveform') then
    self:_notify(engine:rebuild_peaks() and 'Waveform rebuilt' or 'Could not read the file for a waveform')
  end
  if IM.MenuItem(ctx, 'Copy file path') then
    local set_clipboard = has(IM, 'SetClipboardText')
    if set_clipboard then set_clipboard(ctx, engine.current and engine.current.path or '') end
  end
  if reaper.CF_LocateInExplorer and IM.MenuItem(ctx, 'Show file in explorer') then
    if engine.current then reaper.CF_LocateInExplorer(engine.current.path) end
  end

  IM.Separator(ctx)
  if IM.MenuItem(ctx, 'Discard recording') then
    engine:discard()
    self:_notify('Recording discarded (file kept on disk)')
  end

  self:_host_menu_items(ctx)
  IM.EndPopup(ctx)
end

--------------------------------------------------------------------------------
-- Header controls
--------------------------------------------------------------------------------

function Recorder:_draw_header(ctx)
  local IM = self.IM
  local engine = self.engine
  local recording = engine:is_recording()

  local col_button = const(IM, 'Col_Button')
  local col_hovered = const(IM, 'Col_ButtonHovered')
  local pushed = false
  if recording then
    IM.PushStyleColor(ctx, col_button, 0xC03A31FF)
    IM.PushStyleColor(ctx, col_hovered, 0xE2453CFF)
    pushed = true
  end
  if IM.Button(ctx, recording and 'Stop' or 'Record', 74, 0) then
    engine:toggle()
    if engine.error then self:_notify(engine.error) end
  end
  if pushed then IM.PopStyleColor(ctx, 2) end

  if self.allow_auto_record then
    IM.SameLine(ctx)
    local on = engine.auto_record
    if on then
      IM.PushStyleColor(ctx, col_button, 0x2F6F4EFF)
      IM.PushStyleColor(ctx, col_hovered, 0x3C8A62FF)
    end
    if IM.SmallButton(ctx, on and 'Auto: On' or 'Auto: Off') then
      engine:set_auto_record(not on)
    end
    if on then IM.PopStyleColor(ctx, 2) end
    if IM.IsItemHovered(ctx) then
      IM.SetTooltip(ctx, 'Auto records every sound this script plays.\n\n' ..
        'A take opens the moment something is triggered and closes\n' ..
        'itself once the sound has been silent for a second, so the\n' ..
        'recorder does not have to be watched.')
    end
  end

  IM.SameLine(ctx)
  if recording then
    IM.TextColored(ctx, COL.wave_rec, Util.format_time(engine:elapsed()))
  elseif engine.state == 'finalizing' then
    IM.TextColored(ctx, COL.text_dim, 'Rendering peaks…')
  elseif engine.current then
    IM.TextColored(ctx, COL.text, string.format('%s  %s',
      Util.format_duration(engine.current.length),
      Util.short_name(engine.current.path, 28)))
    -- The strip only has room for the file name, but where the file went is
    -- the first thing anyone asks. REAPER chooses the folder, not this script.
    if IM.IsItemHovered(ctx) then
      IM.SetTooltip(ctx, engine.current.path ..
        '\n\nREAPER writes takes to the project media folder, or to the\n' ..
        'default recording path when the project has not been saved.')
    end
  else
    IM.TextColored(ctx, COL.text_dim, 'No take yet')
  end

  if self.allow_capture_switch then
    IM.SameLine(ctx)
    local label = engine.capture == 'track' and 'Source: Track' or 'Source: Master'
    if IM.SmallButton(ctx, label) then
      engine.capture = engine.capture == 'track' and 'master' or 'track'
    end
    if IM.IsItemHovered(ctx) then
      IM.SetTooltip(ctx, 'Master captures everything feeding the master bus.\n' ..
        'Track captures only the source track this script plays through.')
    end
  end

  if engine:buffer_ready() then
    -- The buffer has been filling since the strip opened, so the last few
    -- seconds can be lifted out of it without having pressed Record first.
    IM.SameLine(ctx)
    if IM.SmallButton(ctx, string.format('Last %ds', self.grab_seconds)) then
      if not engine:grab_last(self.grab_seconds) and engine.error then
        self:_notify(engine.error)
      end
    end
    if IM.IsItemHovered(ctx) then
      IM.SetTooltip(ctx, string.format(
        'Take the last %d seconds straight out of the capture buffer.\n\n' ..
        'The plug-in holds the most recent %s at all times, so this works\n' ..
        'for something you already played without pressing Record.',
        self.grab_seconds, Util.format_duration(engine:buffer_seconds_held() or 0)))
    end
  elseif self.allow_transport_switch then
    IM.SameLine(ctx)
    local isolated = engine.transport == 'isolated'
    if IM.SmallButton(ctx, isolated and 'Roll: Isolated' or 'Roll: Timeline') then
      engine.transport = isolated and 'timeline' or 'isolated'
    end
    if IM.IsItemHovered(ctx) then
      IM.SetTooltip(ctx, 'Timeline rolls the project from the edit cursor, so a\n' ..
        'pass over your arrangement is recorded.\n\n' ..
        'Isolated rolls past the end of the project instead, so nothing\n' ..
        'on the timeline plays and only what you trigger live is captured.\n' ..
        'The edit cursor goes back where it was when you stop.')
    end
  end

  if engine.current and engine:can_preview() then
    IM.SameLine(ctx)
    if IM.SmallButton(ctx, engine.preview and 'Stop' or 'Play') then
      engine:toggle_preview()
    end
  end

  if engine.current then
    IM.SameLine(ctx)
    if IM.SmallButton(ctx, 'Clear') then
      engine:discard()
    end
  end
end

--------------------------------------------------------------------------------
-- Public draw
--------------------------------------------------------------------------------

--- Draws the recorder strip. Call once per frame, inside the host's window.
function Recorder:draw(ctx, opts)
  local IM = self.IM
  if not IM.Button then
    if not self.warned then
      reaper.ShowMessageBox('ADFX Recorder needs ReaImGui.\n' ..
        'Install it from ReaPack: Extensions > ReaPack > Browse packages > ReaImGui.',
        'ADFX Recorder', 0)
      self.warned = true
    end
    return
  end

  opts = opts or {}
  local height = opts.height or self.height
  self.engine:tick()

  -- Something the engine needs to explain, such as REAPER ending a pass on its
  -- own. Drained every frame, because these happen long after Record was hit.
  local notice = self.engine:take_notice()
  if notice then self:_notify(notice) end

  IM.Separator(ctx)
  self:_draw_header(ctx)

  local avail = IM.GetContentRegionAvail(ctx)
  local width = math.max(opts.width or avail or 240, 80)
  local x, y = IM.GetCursorScreenPos(ctx)
  local dl = IM.GetWindowDrawList(ctx)

  IM.InvisibleButton(ctx, '##adfx_recorder_strip_' .. self.id, width, height)
  local writing = self.engine:is_recording() or self.engine.state == 'finalizing'
  local rec = not writing and self.engine.current or nil
  local section = self.engine:effective_section()

  if rec then
    self:_draw_wave(dl, x, y, width, height, rec, section)
    self:_handle_isolate(ctx, x, width, rec)
    self:_handle_drag_out(ctx, x, y, width, height)
    if IM.IsItemHovered(ctx) and IM.IsMouseDoubleClicked(ctx, 0) then
      local mx = IM.GetMousePos(ctx)
      local at = Util.clamp(Util.x_to_time(mx, x, x + width, 0, rec.length), 0, rec.length)
      local iso = self.engine.section
      if iso and (at < iso.start or at > iso.start + iso.len) then
        -- Outside the isolation the double click undoes it. Playing from there
        -- would be playing from outside the very range everything else uses.
        self.engine:clear_section()
        self:_notify('Isolation cleared')
      else
        -- Play from where the pointer is, the way double clicking a waveform
        -- anywhere else in REAPER behaves.
        if self.engine:play_from(at) then
          self:_notify(string.format('Playing from %s  ·  Space stops',
            Util.format_time(at)))
        elseif not self.engine:can_preview() then
          self:_notify('Playing from a point needs the SWS extension')
        end
      end
    end
    self:_menu(ctx)
  else
    self:_draw_placeholder(dl, x, y, width, height)
  end

  local playing = self.engine:previewing()
  if self.message and reaper.time_precise() < self.message_until then
    IM.TextColored(ctx, playing and COL.playhead or COL.text_dim, self.message)
  elseif playing then
    IM.TextColored(ctx, COL.playhead, 'Playing  ·  Space stops  ·  double-click to play from elsewhere')
  elseif rec and self.engine.section then
    IM.TextColored(ctx, COL.text_dim,
      'Double-click inside the selection to play it  ·  outside to clear it  ·  left-drag to place it')
  elseif rec then
    IM.TextColored(ctx, COL.text_dim,
      'Double-click to play from there  ·  left-drag into the arrange view  ·  right-drag to isolate')
  else
  end
end

return Recorder
