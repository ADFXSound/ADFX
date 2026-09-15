-- @description ADFX_Helper; strip silence
-- @version 2.0.0
-- @author ADFXSound

--[[
ADFX_Helper; strip silence.lua
v1.3.0

LIVE PREVIEW UNDO MODEL
-----------------------
The live preview NEVER uses SplitMediaItem/DeleteTrackMediaItem.

Instead, this script snapshots each affected track's state chunk and builds a
temporary preview by writing modified track chunks with:
    reaper.SetTrackStateChunk(track, chunk, false)

The final "false" explicitly tells REAPER not to create an undo state.

Therefore:
- Open, tweak settings any number of times, then close/cancel:
      ZERO undo entries.
- Open, tweak settings any number of times, then press Strip:
      exactly ONE undo entry.
- The next undo after Strip is whatever existed before Strip Silence opened.

At commit, the preview chunk is first restored without undo, then the final
Strip is performed once with normal REAPER item editing inside one undo block.

Requirements:
- ReaImGui

Current defaults:
- Strip Threshold:    -12 dB
- Min Strip Duration:   0 ms
- Clip Start Pad:       0 ms
- Clip End Pad:       650 ms
]]

local SCRIPT_NAME = "ADFX_Helper; strip silence"
local VERSION = "1.4"

if not reaper.ImGui_CreateContext then
  reaper.ShowMessageBox("This script requires ReaImGui.", SCRIPT_NAME, 0)
  return
end

local ctx = reaper.ImGui_CreateContext(SCRIPT_NAME)
local font = reaper.ImGui_CreateFont("sans-serif", 14)
reaper.ImGui_Attach(ctx, font)

-- ADFX logo: keep the PNG beside this Lua script.
-- Drawn directly into the window draw list so it does NOT participate in
-- ImGui layout and therefore does not change any existing spacing/grid.
local logo_image = nil
do
  local script_path = ({reaper.get_action_context()})[2] or ""
  local script_dir = script_path:match("^(.*[\\/])") or ""
  local logo_candidates = {
    script_dir .. "ADFX_O_LOGO.png",
    script_dir .. "ADFX_O_LOGO(1).png"
  }

  if reaper.ImGui_CreateImage then
    for _, logo_path in ipairs(logo_candidates) do
      local ok, img = pcall(reaper.ImGui_CreateImage, logo_path)
      if ok and img then
        logo_image = img
        pcall(reaper.ImGui_Attach, ctx, logo_image)
        break
      end
    end
  end
end

-- A second transparent ReaImGui window is used ONLY for visual preview.
-- It draws over the arrange view and never edits the project, so it cannot
-- generate undo states.
local overlay_ctx = reaper.ImGui_CreateContext(SCRIPT_NAME .. " Preview")

-- Always start from these defaults when the tool opens.
local threshold_db = -12.0
local min_strip_ms = 0.0
local start_pad_ms = 0.0
local end_pad_ms = 650.0

local analysis_step = 0.005
local preview_interval = 0.035

local snapshots = {}
local tracks = {}
local regions_cache = {}
local preview_replacements_applied = 0

local running = true
local committed = false
local preview_dirty = false
local last_preview_time = 0.0

local function valid_item(item)
  return item and reaper.ValidatePtr2(0, item, "MediaItem*")
end

local function valid_track(track)
  return track and reaper.ValidatePtr2(0, track, "MediaTrack*")
end

local function db_to_amp(db)
  return 10 ^ (db / 20)
end

local function analyze_item(item)
  local take = reaper.GetActiveTake(item)
  if not take or reaper.TakeIsMIDI(take) then return nil end

  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  if len <= 0 then return nil end

  local accessor = reaper.CreateTakeAudioAccessor(take)
  if not accessor then return nil end

  local source = reaper.GetMediaItemTake_Source(take)
  local channels = 2
  if source and reaper.GetMediaSourceNumChannels then
    channels = math.max(1, reaper.GetMediaSourceNumChannels(source))
  end
  channels = math.min(channels, 16)

  local accessor_start = 0.0
  if reaper.GetAudioAccessorStartTime then
    accessor_start = reaper.GetAudioAccessorStartTime(accessor) or 0.0
  end

  local samplerate = 48000
  local points = {}
  local t = 0.0

  while t < len do
    local dur = math.min(analysis_step, len - t)
    local frames = math.max(1, math.floor(samplerate * dur))
    local buf = reaper.new_array(frames * channels)
    buf.clear()

    local got = reaper.GetAudioAccessorSamples(
      accessor, samplerate, channels, accessor_start + t, frames, buf
    )

    local peak = 0.0
    if got and got > 0 then
      local vals = buf.table(1, frames * channels)
      for i = 1, #vals do
        local a = math.abs(vals[i] or 0)
        if a > peak then peak = a end
      end
    end

    points[#points + 1] = { t = t, peak = peak }
    t = t + dur
  end

  reaper.DestroyAudioAccessor(accessor)

  return {
    pos = pos,
    len = len,
    points = points
  }
end

local function merge_ranges(ranges)
  if #ranges <= 1 then return ranges end
  table.sort(ranges, function(a, b) return a[1] < b[1] end)

  local out = { {ranges[1][1], ranges[1][2]} }
  for i = 2, #ranges do
    local cur = ranges[i]
    local last = out[#out]
    if cur[1] <= last[2] then
      last[2] = math.max(last[2], cur[2])
    else
      out[#out + 1] = {cur[1], cur[2]}
    end
  end
  return out
end

local function compute_regions_for(a)
  local amp = db_to_amp(threshold_db)
  local min_sil = math.max(0, min_strip_ms / 1000.0)
  local start_pad = math.max(0, start_pad_ms / 1000.0)
  local end_pad = math.max(0, end_pad_ms / 1000.0)

  local keep = {}
  local in_sound = false
  local sound_start = 0.0

  for _, p in ipairs(a.points) do
    local above = p.peak >= amp

    if above and not in_sound then
      in_sound = true
      sound_start = p.t
    elseif (not above) and in_sound then
      in_sound = false
      keep[#keep + 1] = {sound_start, p.t}
    end
  end

  if in_sound then
    keep[#keep + 1] = {sound_start, a.len}
  end

  for _, r in ipairs(keep) do
    r[1] = math.max(0, r[1] - start_pad)
    r[2] = math.min(a.len, r[2] + end_pad)
  end
  keep = merge_ranges(keep)

  -- Retain short below-threshold gaps.
  if #keep > 1 and min_sil > 0 then
    local merged = { {keep[1][1], keep[1][2]} }
    for i = 2, #keep do
      local last = merged[#merged]
      local gap = keep[i][1] - last[2]
      if gap < min_sil then
        last[2] = math.max(last[2], keep[i][2])
      else
        merged[#merged + 1] = {keep[i][1], keep[i][2]}
      end
    end
    keep = merged
  end

  local strip = {}
  local cursor = 0.0

  for _, r in ipairs(keep) do
    local gap = r[1] - cursor
    if gap > 0 and gap >= min_sil then
      strip[#strip + 1] = {cursor, r[1]}
    end
    cursor = math.max(cursor, r[2])
  end

  local tail = a.len - cursor
  if tail > 0 and tail >= min_sil then
    strip[#strip + 1] = {cursor, a.len}
  end

  return keep, strip
end

local function rebuild_regions()
  regions_cache = {}
  for i, snap in ipairs(snapshots) do
    local keep, strip = compute_regions_for(snap.analysis)
    regions_cache[i] = {keep = keep, strip = strip}
  end
end

-- ---------- Chunk preview helpers ----------

local function get_item_guid(item)
  local _, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
  return guid
end

local function get_item_chunk(item)
  local ok, chunk = reaper.GetItemStateChunk(item, "", false)
  if ok then return chunk end
  return nil
end

local function get_track_chunk(track)
  local ok, chunk = reaper.GetTrackStateChunk(track, "", false)
  if ok then return chunk end
  return nil
end

local function guid_from_item_chunk(chunk)
  -- REAPER stores the MEDIA ITEM GUID as IGUID in the ITEM chunk.
  -- TAKE GUIDs use GUID. v1.3.0 incorrectly searched only for GUID here,
  -- so none of the selected item blocks matched the replacement map and the
  -- live preview appeared completely static.
  local before_take = chunk:match("^(.-)\n%s*<TAKE") or chunk

  return before_take:match("\n%s*IGUID%s+([^\r\n]+)")
      or before_take:match("^%s*IGUID%s+([^\r\n]+)")
      or before_take:match("\n%s*GUID%s+([^\r\n]+)")
      or before_take:match("^%s*GUID%s+([^\r\n]+)")
end

local function set_numeric_line(chunk, key, value)
  local pattern = "(\n%s*" .. key .. "%s+)[^%s\r\n]+"
  local replaced, n = chunk:gsub(pattern, "%1" .. string.format("%.14f", value), 1)
  if n == 0 then
    pattern = "^(%s*" .. key .. "%s+)[^%s\r\n]+"
    replaced, n = chunk:gsub(pattern, "%1" .. string.format("%.14f", value), 1)
  end
  return replaced
end

local function get_numeric_line(chunk, key)
  local s = chunk:match("\n%s*" .. key .. "%s+([^%s\r\n]+)")
  if not s then s = chunk:match("^%s*" .. key .. "%s+([^%s\r\n]+)") end
  return tonumber(s)
end

local function fresh_guid()
  if reaper.genGuid then
    return reaper.genGuid("")
  end
  -- Fallback is only for preview identity.
  return string.format("{ADFX-%08X-%08X}", math.random(0, 0x7fffffff), math.random(0, 0x7fffffff))
end

local function regenerate_guids(chunk)
  -- Regenerate item/take GUIDs so multiple preview segments don't share identity.
  chunk = chunk:gsub("(\n%s*GUID%s+)[^\r\n]+", function(prefix)
    return prefix .. fresh_guid()
  end)
  chunk = chunk:gsub("(\n%s*IGUID%s+)[^\r\n]+", function(prefix)
    return prefix .. fresh_guid()
  end)
  return chunk
end

local function offset_all_take_soffs(chunk, delta_seconds)
  if delta_seconds == 0 then return chunk end

  -- Each take can have its own PLAYRATE. Walk line-by-line and adjust SOFFS
  -- using the most recently encountered PLAYRATE within the current TAKE.
  local lines = {}
  local current_rate = 1.0
  local in_take = false

  for line in (chunk .. "\n"):gmatch("(.-)\n") do
    if line:match("^%s*<TAKE") then
      in_take = true
      current_rate = 1.0
    elseif in_take then
      local rate = line:match("^%s*PLAYRATE%s+([^%s]+)")
      if rate then
        current_rate = tonumber(rate) or 1.0
      end

      local soff = line:match("^(%s*SOFFS%s+)([^%s]+)(.*)$")
      if soff then
        local prefix, num, suffix = line:match("^(%s*SOFFS%s+)([^%s]+)(.*)$")
        local old = tonumber(num) or 0.0
        line = prefix .. string.format("%.14f", old + delta_seconds * current_rate) .. suffix
      end
    end
    lines[#lines + 1] = line
  end

  return table.concat(lines, "\n")
end

local function make_segment_chunk(original_chunk, original_pos, start_off, end_off)
  local seg_len = end_off - start_off
  if seg_len <= 0.0000001 then return nil end

  local chunk = original_chunk
  chunk = set_numeric_line(chunk, "POSITION", original_pos + start_off)
  chunk = set_numeric_line(chunk, "LENGTH", seg_len)

  -- Split semantics: advance source offset by the amount trimmed from the left.
  chunk = offset_all_take_soffs(chunk, start_off)

  -- Snap offset should stay relative to the visible segment.
  local snapoffs = get_numeric_line(chunk, "SNAPOFFS")
  if snapoffs then
    chunk = set_numeric_line(chunk, "SNAPOFFS", math.max(0, snapoffs - start_off))
  end

  chunk = regenerate_guids(chunk)
  return chunk
end

local function split_top_level_item_blocks(track_chunk)
  local out = {}
  local i = 1
  local n = #track_chunk

  -- Keep text scanning line-oriented, but track nested <...> depth.
  local block_start = nil
  local depth = 0
  local pos = 1

  while pos <= n do
    local nl = track_chunk:find("\n", pos, true)
    local line_end = nl and (nl - 1) or n
    local line = track_chunk:sub(pos, line_end)
    local stripped = line:match("^%s*(.-)%s*$")

    if not block_start then
      if stripped:match("^<ITEM[%s>]") then
        if pos > i then
          out[#out + 1] = {kind="text", text=track_chunk:sub(i, pos - 1)}
        end
        block_start = pos
        depth = 1
      end
    else
      if stripped:sub(1,1) == "<" then
        depth = depth + 1
      elseif stripped == ">" then
        depth = depth - 1
        if depth == 0 then
          local block_end = nl and nl or n
          out[#out + 1] = {
            kind="item",
            text=track_chunk:sub(block_start, block_end)
          }
          i = block_end + 1
          block_start = nil
        end
      end
    end

    if not nl then break end
    pos = nl + 1
  end

  if i <= n then
    out[#out + 1] = {kind="text", text=track_chunk:sub(i)}
  end

  return out
end

local function build_preview_track_chunk(track_info, replacement_map)
  local parts = split_top_level_item_blocks(track_info.original_chunk)
  local out = {}

  for _, part in ipairs(parts) do
    if part.kind == "item" then
      local guid = guid_from_item_chunk(part.text)

      -- Must distinguish "no replacement entry" from an intentionally empty
      -- replacement (the whole item is stripped).
      if guid and replacement_map[guid] ~= nil then
        out[#out + 1] = replacement_map[guid]
        preview_replacements_applied = preview_replacements_applied + 1
      else
        out[#out + 1] = part.text
      end
    else
      out[#out + 1] = part.text
    end
  end

  return table.concat(out)
end

local function restore_track_chunks_no_undo()
  -- Live preview no longer changes project state, so there is nothing to
  -- restore here. Keeping this function makes the commit path explicit.
end

local function build_chunk_preview()
  -- v1.3.5: live preview is VISUAL ONLY.
  --
  -- Earlier v1.3.x builds attempted to rewrite track state chunks with
  -- isundo=false. That kept undo history clean, but REAPER does not reliably
  -- rebuild the arrange-view item display for newly-added/removed ITEM blocks.
  --
  -- We therefore leave the project completely untouched while dialing in
  -- settings and draw the strip regions in a transparent overlay instead.
  -- The actual destructive edit happens exactly once when Strip is committed.
  rebuild_regions()
  preview_replacements_applied = #snapshots
end

local function capture()
  local count = reaper.CountSelectedMediaItems(0)
  if count == 0 then
    return false, "Select at least one audio item."
  end

  local track_map = {}

  for i = 0, count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)

    if take and not reaper.TakeIsMIDI(take) then
      local track = reaper.GetMediaItem_Track(item)
      local item_chunk = get_item_chunk(item)
      local analysis = analyze_item(item)
      local guid = get_item_guid(item)

      if valid_track(track) and item_chunk and analysis and guid then
        snapshots[#snapshots + 1] = {
          track = track,
          guid = guid,
          item_chunk = item_chunk,
          analysis = analysis
        }

        if not track_map[track] then
          local tr_chunk = get_track_chunk(track)
          if not tr_chunk then
            return false, "Could not read the state chunk for an affected track."
          end
          local info = {track=track, original_chunk=tr_chunk}
          track_map[track] = info
          tracks[#tracks + 1] = info
        end
      end
    end
  end

  if #snapshots == 0 then
    return false, "No selected audio items could be analyzed."
  end

  return true
end

-- ---------- Arrange-view live preview overlay ----------

local function flag_value(name)
  local fn = reaper[name]
  if type(fn) == "function" then
    local ok, v = pcall(fn)
    if ok then return v or 0 end
  end
  return 0
end

local OVERLAY_FLAGS =
    flag_value("ImGui_WindowFlags_NoDecoration")
  | flag_value("ImGui_WindowFlags_NoInputs")
  | flag_value("ImGui_WindowFlags_NoSavedSettings")
  | flag_value("ImGui_WindowFlags_NoNav")
  | flag_value("ImGui_WindowFlags_NoFocusOnAppearing")
  | flag_value("ImGui_WindowFlags_NoBringToFrontOnFocus")

local function draw_live_overlay()
  if not reaper.JS_Window_FindChildByID
      or not reaper.JS_Window_GetRect then
    return
  end

  local main = reaper.GetMainHwnd()
  local arrange = reaper.JS_Window_FindChildByID(main, 1000)
  if not arrange then return end

  local ok, left, top, right, bottom = reaper.JS_Window_GetRect(arrange)
  if not ok then return end

  local w = math.max(1, right - left)
  local h = math.max(1, bottom - top)
  if w <= 2 or h <= 2 then return end

  reaper.ImGui_SetNextWindowPos(overlay_ctx, left, top)
  reaper.ImGui_SetNextWindowSize(overlay_ctx, w, h)
  if reaper.ImGui_SetNextWindowBgAlpha then
    reaper.ImGui_SetNextWindowBgAlpha(overlay_ctx, 0.0)
  end

  local visible = reaper.ImGui_Begin(
    overlay_ctx,
    "##ADFXStripSilenceArrangePreview",
    true,
    OVERLAY_FLAGS
  )

  if visible then
    local draw_list = reaper.ImGui_GetWindowDrawList(overlay_ctx)
    local view_start, view_end = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local view_len = math.max(0.000001, view_end - view_start)

    -- Dark translucent fill makes portions that WILL BE REMOVED visually
    -- recede without touching the actual media item.
    local strip_fill = 0x080A0BCC
    local strip_edge = 0xE6E6E6AA

    for i, snap in ipairs(snapshots) do
      local tr = snap.track
      local rc = regions_cache[i]

      if valid_track(tr) and rc then
        local tr_y = reaper.GetMediaTrackInfo_Value(tr, "I_TCPY")
        local tr_h = reaper.GetMediaTrackInfo_Value(tr, "I_WNDH")

        -- IMPORTANT:
        -- ImGui draw-list coordinates are absolute SCREEN coordinates.
        -- I_TCPY and the time->pixel calculation below are ARRANGE-CLIENT
        -- coordinates. v1.3.5 forgot to add the arrange window's screen-space
        -- left/top offsets, which is why the preview floated near the upper
        -- left of the screen instead of sitting on the selected item.
        --
        -- Convert the track lane into absolute screen coordinates here.
        local local_y1 = math.max(0, tr_y + 2)
        local local_y2 = math.min(h, tr_y + tr_h - 2)
        local y1 = top + local_y1
        local y2 = top + local_y2

        if y2 > y1 then
          for _, r in ipairs(rc.strip or {}) do
            local t1 = snap.analysis.pos + r[1]
            local t2 = snap.analysis.pos + r[2]

            if t2 >= view_start and t1 <= view_end then
              local c1 = math.max(t1, view_start)
              local c2 = math.min(t2, view_end)

              local local_x1 = ((c1 - view_start) / view_len) * w
              local local_x2 = ((c2 - view_start) / view_len) * w
              local x1 = left + local_x1
              local x2 = left + local_x2

              if x2 > x1 then
                reaper.ImGui_DrawList_AddRectFilled(
                  draw_list, x1, y1, x2, y2, strip_fill
                )
                reaper.ImGui_DrawList_AddLine(
                  draw_list, x1, y1, x1, y2, strip_edge, 1.0
                )
                reaper.ImGui_DrawList_AddLine(
                  draw_list, x2, y1, x2, y2, strip_edge, 1.0
                )
              end
            end
          end
        end
      end
    end

    reaper.ImGui_End(overlay_ctx)
  end
end

-- ---------- Final commit helpers ----------

local function find_item_by_guid(guid)
  local count = reaper.CountMediaItems(0)
  for i = 0, count - 1 do
    local item = reaper.GetMediaItem(0, i)
    local _, g = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
    if g == guid then return item end
  end
  return nil
end

local function split_item_at_boundaries(item, origin, ranges)
  local boundaries = {}

  for _, r in ipairs(ranges) do
    if r[1] > 0 then boundaries[#boundaries + 1] = origin + r[1] end
    if r[2] < reaper.GetMediaItemInfo_Value(item, "D_LENGTH") then
      boundaries[#boundaries + 1] = origin + r[2]
    end
  end

  table.sort(boundaries)
  local segments = {item}

  for _, split_time in ipairs(boundaries) do
    for i = #segments, 1, -1 do
      local seg = segments[i]
      if valid_item(seg) then
        local p = reaper.GetMediaItemInfo_Value(seg, "D_POSITION")
        local l = reaper.GetMediaItemInfo_Value(seg, "D_LENGTH")
        if split_time > p + 0.0000001 and split_time < p + l - 0.0000001 then
          local right = reaper.SplitMediaItem(seg, split_time)
          if right then table.insert(segments, i + 1, right) end
          break
        end
      end
    end
  end

  return segments
end

local function local_in_ranges(t, ranges)
  for _, r in ipairs(ranges) do
    if t >= r[1] and t <= r[2] then return true end
  end
  return false
end

local function apply_final_strip()
  rebuild_regions()

  -- Preview is first removed with isundo=false, leaving the project exactly
  -- as it was before the tool opened.
  restore_track_chunks_no_undo()

  reaper.Undo_BeginBlock2(0)
  reaper.PreventUIRefresh(1)

  for i, snap in ipairs(snapshots) do
    local item = find_item_by_guid(snap.guid)
    if valid_item(item) then
      local origin = snap.analysis.pos
      local strip = regions_cache[i].strip
      local segments = split_item_at_boundaries(item, origin, strip)

      for j = #segments, 1, -1 do
        local seg = segments[j]
        if valid_item(seg) then
          local p = reaper.GetMediaItemInfo_Value(seg, "D_POSITION")
          local l = reaper.GetMediaItemInfo_Value(seg, "D_LENGTH")
          local center = (p + l * 0.5) - origin

          if local_in_ranges(center, strip) then
            local tr = reaper.GetMediaItem_Track(seg)
            if valid_track(tr) then
              reaper.DeleteTrackMediaItem(tr, seg)
            end
          end
        end
      end
    end
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock2(0, SCRIPT_NAME .. " - Strip", -1)
end

local function apply_final_extract()
  rebuild_regions()
  restore_track_chunks_no_undo()

  reaper.Undo_BeginBlock2(0)
  reaper.PreventUIRefresh(1)

  for i, snap in ipairs(snapshots) do
    local item = find_item_by_guid(snap.guid)
    if valid_item(item) then
      local origin = snap.analysis.pos
      -- Extract is the inverse of Strip: remove the detected/selected audio
      -- regions and leave the unselected (below-threshold) areas behind.
      local remove = regions_cache[i].keep
      local segments = split_item_at_boundaries(item, origin, remove)

      for j = #segments, 1, -1 do
        local seg = segments[j]
        if valid_item(seg) then
          local p = reaper.GetMediaItemInfo_Value(seg, "D_POSITION")
          local l = reaper.GetMediaItemInfo_Value(seg, "D_LENGTH")
          local center = (p + l * 0.5) - origin

          if local_in_ranges(center, remove) then
            local tr = reaper.GetMediaItem_Track(seg)
            if valid_track(tr) then
              reaper.DeleteTrackMediaItem(tr, seg)
            end
          end
        end
      end
    end
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock2(0, SCRIPT_NAME .. " - Extract", -1)
end

local function apply_final_separate()
  rebuild_regions()
  restore_track_chunks_no_undo()

  reaper.Undo_BeginBlock2(0)
  reaper.PreventUIRefresh(1)

  for i, snap in ipairs(snapshots) do
    local item = find_item_by_guid(snap.guid)
    if valid_item(item) then
      split_item_at_boundaries(item, snap.analysis.pos, regions_cache[i].keep)
    end
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock2(0, SCRIPT_NAME .. " - Separate", -1)
end

local function commit_strip()
  if preview_dirty then
    build_chunk_preview()
    preview_dirty = false
  end

  apply_final_strip()
  committed = true
  running = false
end

local function commit_extract()
  if preview_dirty then
    build_chunk_preview()
    preview_dirty = false
  end

  apply_final_extract()
  committed = true
  running = false
end

local function commit_separate()
  apply_final_separate()
  committed = true
  running = false
end

local ok, err = capture()
if not ok then
  reaper.ShowMessageBox(err or "Unable to initialize Strip Silence.", SCRIPT_NAME, 0)
  return
end

rebuild_regions()
build_chunk_preview()
last_preview_time = reaper.time_precise()

local function imgui_key(name)
  local fn = reaper[name]
  if type(fn) == "function" then
    local ok, value = pcall(fn)
    if ok then return value end
  end
  return nil
end

local ENTER_KEY = imgui_key("ImGui_Key_Enter")
local KEYPAD_ENTER_KEY = imgui_key("ImGui_Key_KeypadEnter")
local ESCAPE_KEY = imgui_key("ImGui_Key_Escape")

local function enter_pressed()
  if not reaper.ImGui_IsKeyPressed then return false end

  if ENTER_KEY then
    local ok, pressed = pcall(reaper.ImGui_IsKeyPressed, ctx, ENTER_KEY)
    if ok and pressed then return true end
  end

  if KEYPAD_ENTER_KEY then
    local ok, pressed = pcall(reaper.ImGui_IsKeyPressed, ctx, KEYPAD_ENTER_KEY)
    if ok and pressed then return true end
  end

  return false
end

local function escape_pressed()
  if not reaper.ImGui_IsKeyPressed or not ESCAPE_KEY then return false end
  local ok, pressed = pcall(reaper.ImGui_IsKeyPressed, ctx, ESCAPE_KEY)
  return ok and pressed or false
end

local function loop()
  if not running then return end

  if preview_dirty then
    local now = reaper.time_precise()
    if now - last_preview_time >= preview_interval then
      build_chunk_preview()
      preview_dirty = false
      last_preview_time = now
    end
  end

  -- Always redraw so zooming, scrolling and track-height changes stay aligned.
  draw_live_overlay()

  reaper.ImGui_SetNextWindowSize(ctx, 500, 220, reaper.ImGui_Cond_FirstUseEver())

  local visible, open = reaper.ImGui_Begin(
    ctx,
    SCRIPT_NAME .. " v" .. VERSION,
    true,
    reaper.ImGui_WindowFlags_NoCollapse()
  )

  if visible then
    reaper.ImGui_PushFont(ctx, font, 14)

    local changed

    changed, threshold_db = reaper.ImGui_SliderDouble(
      ctx, "Strip Threshold", threshold_db, -96.0, 0.0, "%.1f dB"
    )
    if changed then preview_dirty = true end

    changed, min_strip_ms = reaper.ImGui_SliderDouble(
      ctx, "Min Strip Duration", min_strip_ms, 0.0, 5000.0, "%.0f ms"
    )
    if changed then preview_dirty = true end

    changed, start_pad_ms = reaper.ImGui_SliderDouble(
      ctx, "Clip Start Pad", start_pad_ms, 0.0, 5000.0, "%.0f ms"
    )
    if changed then preview_dirty = true end

    changed, end_pad_ms = reaper.ImGui_SliderDouble(
      ctx, "Clip End Pad", end_pad_ms, 0.0, 5000.0, "%.0f ms"
    )
    if changed then preview_dirty = true end

    reaper.ImGui_Separator(ctx)

    local avail = reaper.ImGui_GetContentRegionAvail(ctx)
    local bw = (avail - 16) / 3

    if reaper.ImGui_Button(ctx, "Extract", bw, 32) then
      commit_extract()
    end

    reaper.ImGui_SameLine(ctx)

    if reaper.ImGui_Button(ctx, "Separate", bw, 32) then
      commit_separate()
    end

    reaper.ImGui_SameLine(ctx)

    if reaper.ImGui_Button(ctx, "Strip", bw, 32) then
      commit_strip()
    end

    -- Escape cancels immediately: close without committing any changes.
    if running and escape_pressed() then
      running = false
    end

    -- Enter / numpad Enter commits the current Strip preview and closes.
    if running and enter_pressed() then
      commit_strip()
    end

    rebuild_regions()

    local keeps, strips = 0, 0
    for _, rc in ipairs(regions_cache) do
      keeps = keeps + #(rc.keep or {})
      strips = strips + #(rc.strip or {})
    end

    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_TextDisabled(
      ctx,
      string.format(
        "%d source item(s) | %d kept | %d stripped | LIVE VISUAL PREVIEW | 0 undo",
        #snapshots, keeps, strips
      )
    )

    -- Bottom-right ADFX logo. Absolute draw-list placement keeps it independent
    -- from all sliders, buttons, separators, and status-text layout.
    if logo_image and reaper.ImGui_DrawList_AddImage then
      local wx, wy = reaper.ImGui_GetWindowPos(ctx)
      local ww, wh = reaper.ImGui_GetWindowSize(ctx)
      local logo_size = 32
      local margin_right = 8
      local margin_bottom = 7
      local x2 = wx + ww - margin_right
      local y2 = wy + wh - margin_bottom
      local x1 = x2 - logo_size
      local y1 = y2 - logo_size

      pcall(
        reaper.ImGui_DrawList_AddImage,
        reaper.ImGui_GetWindowDrawList(ctx),
        logo_image,
        x1, y1, x2, y2
      )
    end

    reaper.ImGui_PopFont(ctx)
    reaper.ImGui_End(ctx)
  end

  if not open then
    running = false
  end

  if running then
    reaper.defer(loop)
  end
end

reaper.atexit(function()
  -- Live preview is visual-only, so closing/canceling leaves the project and
  -- undo history completely untouched.
end)

loop()