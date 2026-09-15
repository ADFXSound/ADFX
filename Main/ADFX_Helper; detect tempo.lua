--[[
ADFX_Helper; Detect Tempo.lua
v1.1

Workflow:
1. Select the recorded item (or multiple items defining the range).
2. Run this script.
3. Enter the number of beats contained in the selected item range.
4. The script calculates BPM and optionally applies it to the project.

Selection behavior:
- One selected item: uses the item's start and end.
- Multiple selected items: uses the earliest selected-item start and latest selected-item end.
- No timeline/time selection is required.

Designed for sound-design workflows:
- Calculation does not alter anything.
- Applying BPM sets the project tempo while forcing project item timebase to TIME,
  helping prevent existing audio from changing playback rate/length.
- One clean Undo step when applying tempo.

Formula:
BPM = beats / seconds * 60
]]

local SCRIPT_NAME = "ADFX Detect Tempo"
local DEFAULT_BEATS = 8

local function msg(text, title, typ)
  return reaper.ShowMessageBox(text, title or SCRIPT_NAME, typ or 0)
end

local function get_selected_item_range()
  local count = reaper.CountSelectedMediaItems(0)
  if count == 0 then
    return nil, nil, nil, 0
  end

  local range_start = math.huge
  local range_end = -math.huge

  for i = 0, count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local item_end = pos + len

      if pos < range_start then range_start = pos end
      if item_end > range_end then range_end = item_end end
    end
  end

  if range_start == math.huge or range_end == -math.huge then
    return nil, nil, nil, count
  end

  return range_start, range_end, range_end - range_start, count
end

local function format_bpm(bpm)
  return string.format("%.2f", bpm)
end

local function calc_bpm(beats, duration)
  if not beats or beats <= 0 or not duration or duration <= 0 then
    return nil
  end
  return (beats / duration) * 60.0
end

local function get_project_timebase()
  -- PROJECT_TIMEBASE:
  -- 0 = Time
  -- 1 = Beats (position, length, rate)
  -- 2 = Beats (position only)
  return reaper.GetSetProjectInfo(0, "PROJECT_TIMEBASE", 0, false)
end

local function set_project_timebase(value)
  reaper.GetSetProjectInfo(0, "PROJECT_TIMEBASE", value, true)
end

local function apply_project_bpm(bpm)
  reaper.Undo_BeginBlock()

  -- Force TIME before changing tempo so existing audio does not follow
  -- the project tempo by changing length/rate.
  set_project_timebase(0)

  reaper.SetCurrentBPM(0, bpm, true)

  -- Intentionally leave the project in TIME mode for sound-design work.
  set_project_timebase(0)

  reaper.UpdateTimeline()
  reaper.UpdateArrange()

  reaper.Undo_EndBlock(
    string.format("ADFX Detect Tempo: Set project BPM to %.2f", bpm),
    -1
  )
end

local function main()
  local range_start, range_end, duration, item_count = get_selected_item_range()

  if not duration or duration <= 0 then
    msg(
      "Select the recorded audio item first.\n\n" ..
      "The selected item's start and end will automatically define the tempo measurement range.\n\n" ..
      "For best results, trim the item so it begins and ends exactly on known beats.",
      SCRIPT_NAME,
      0
    )
    return
  end

  local caption
  if item_count == 1 then
    caption = "Beats in selected item:"
  else
    caption = "Beats across selected items:"
  end

  local ok, input = reaper.GetUserInputs(
    SCRIPT_NAME,
    1,
    caption,
    tostring(DEFAULT_BEATS)
  )

  if not ok then return end

  local beats = tonumber(input)

  if not beats or beats <= 0 then
    msg("Please enter a valid beat count greater than 0.", SCRIPT_NAME, 0)
    return
  end

  local bpm = calc_bpm(beats, duration)

  if not bpm then
    msg("Could not calculate tempo from the selected item range.", SCRIPT_NAME, 0)
    return
  end

  local range_label = item_count == 1
    and "Selected item"
    or (tostring(item_count) .. " selected items")

  local answer = msg(
    "Detected tempo: " .. format_bpm(bpm) .. " BPM\n\n" ..
    range_label .. "\n" ..
    "Range length: " .. string.format("%.3f", duration) .. " sec\n" ..
    "Beat count: " .. tostring(beats) .. "\n\n" ..
    "Set the project BPM to " .. format_bpm(bpm) .. "?\n\n" ..
    "YES = Set project BPM\n" ..
    "NO = Just show the result\n" ..
    "CANCEL = Close",
    SCRIPT_NAME,
    3
  )

  -- Windows message box type 3:
  -- 6 = Yes, 7 = No, 2 = Cancel
  if answer == 6 then
    apply_project_bpm(bpm)
  end
end

main()
