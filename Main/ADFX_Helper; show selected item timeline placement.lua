-- @description ADFX_Helper; show selected item timeline placement
-- @version 2.0.0
-- @author ADFXSound

-- Show Selected Item Start Times
-- Displays the timeline start position (in seconds) of each selected item.
-- Single item → simple message. Multiple items → numbered list.

local item_count = reaper.CountSelectedMediaItems(0)

-- ── Helper: format seconds as HH:MM:SS.mmm for readability ────────────────
local function fmt_time(s)
  local sign = s < 0 and "-" or ""
  s = math.abs(s)
  local h   = math.floor(s / 3600)
  local m   = math.floor((s % 3600) / 60)
  local sec = s % 60
  return string.format("%s%02d:%02d:%06.3f", sign, h, m, sec)
end

-- ── No selection ──────────────────────────────────────────────────────────
if item_count == 0 then
  reaper.MB(
    "No items selected.\nPlease select one or more items and run the script again.",
    "Selected Item Start Times", 0
  )
  return
end

-- ── Single item ───────────────────────────────────────────────────────────
if item_count == 1 then
  local item      = reaper.GetSelectedMediaItem(0, 0)
  local start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local track     = reaper.GetMediaItemTrack(item)
  local _, tname  = reaper.GetTrackName(track)

  local take  = reaper.GetActiveTake(item)
  local iname = take and reaper.GetTakeName(take) or "(no take)"

  local msg = string.format(
    "Item:   %s\nTrack:  %s\n\nStart:  %s\n        (%.4f s)",
    iname, tname, fmt_time(start_pos), start_pos
  )
  reaper.MB(msg, "Selected Item Start Time", 0)
  return
end

-- ── Multiple items ────────────────────────────────────────────────────────
-- Collect data first so we can compute summary stats
local items = {}
for i = 0, item_count - 1 do
  local item      = reaper.GetSelectedMediaItem(0, i)
  local start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local take      = reaper.GetActiveTake(item)
  local iname     = take and reaper.GetTakeName(take) or "(no take)"
  local track     = reaper.GetMediaItemTrack(item)
  local _, tname  = reaper.GetTrackName(track)

  -- Truncate long names
  if #iname > 32 then iname = iname:sub(1, 29) .. "..." end
  if #tname > 18 then tname = tname:sub(1, 15) .. "..." end

  items[#items + 1] = {
    idx   = i + 1,
    iname = iname,
    tname = tname,
    pos   = start_pos,
  }
end

-- Sort a copy by position for the earliest/latest summary
local sorted = {}
for _, v in ipairs(items) do sorted[#sorted + 1] = v end
table.sort(sorted, function(a, b) return a.pos < b.pos end)

local earliest = sorted[1]
local latest   = sorted[#sorted]

-- Build the table
local SEP    = string.rep("-", 72)
local header = string.format(
  " %-4s %-32s %-18s  %-15s  %s",
  "#", "Item name", "Track", "Start (HH:MM:SS)", "Seconds"
)

local lines = { header, SEP }
for _, v in ipairs(items) do
  lines[#lines + 1] = string.format(
    " %-4d %-32s %-18s  %-15s  %.4f s",
    v.idx, v.iname, v.tname, fmt_time(v.pos), v.pos
  )
end

-- Summary footer
lines[#lines + 1] = SEP
lines[#lines + 1] = string.format(
  " %-55s  %-15s  %.4f s",
  string.format("Earliest (#%d  %s):", earliest.idx, earliest.iname),
  fmt_time(earliest.pos), earliest.pos
)
lines[#lines + 1] = string.format(
  " %-55s  %-15s  %.4f s",
  string.format("Latest   (#%d  %s):", latest.idx, latest.iname),
  fmt_time(latest.pos), latest.pos
)
lines[#lines + 1] = string.format(
  " %-55s  %-15s  %.4f s",
  "Span (latest start − earliest start):",
  fmt_time(latest.pos - earliest.pos), latest.pos - earliest.pos
)

local msg = table.concat(lines, "\n")
reaper.MB(
  msg,
  string.format("Selected Item Start Times  (%d items)", item_count),
  0
)
