-- @description ADFX_Helper; show selected item durations
-- @version 2.0.0
-- @author ADFXSound

-- Show Selected Item Durations
-- Displays the length in seconds of each selected item.
-- Single item → simple message. Multiple items → numbered list.

local item_count = reaper.CountSelectedMediaItems(0)

if item_count == 0 then
  reaper.MB("No items selected.\nPlease select one or more items and run the script again.", "Selected Item Durations", 0)
  return
end

if item_count == 1 then
  -- ── Single item ──────────────────────────────────────────────────────────
  local item     = reaper.GetSelectedMediaItem(0, 0)
  local length   = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local track    = reaper.GetMediaItemTrack(item)
  local _, tname = reaper.GetTrackName(track)

  -- Try to get the active take name for context
  local take     = reaper.GetActiveTake(item)
  local iname    = "(no take)"
  if take then
    iname = reaper.GetTakeName(take)
  end

  local msg = string.format(
    "Item: %s\nTrack: %s\n\nDuration: %.4f seconds",
    iname, tname, length
  )
  reaper.MB(msg, "Selected Item Duration", 0)

else
  -- ── Multiple items ───────────────────────────────────────────────────────
  local total   = 0
  local lines   = {}
  local longest = { idx = 1, val = 0 }
  local shortest= { idx = 1, val = math.huge }

  for i = 0, item_count - 1 do
    local item   = reaper.GetSelectedMediaItem(0, i)
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local take   = reaper.GetActiveTake(item)
    local iname  = "(no take)"
    if take then
      iname = reaper.GetTakeName(take)
    end

    total = total + length

    if length > longest.val  then longest  = { idx = i + 1, val = length } end
    if length < shortest.val then shortest = { idx = i + 1, val = length } end

    -- Truncate long names so the dialog stays readable
    if #iname > 36 then
      iname = iname:sub(1, 33) .. "..."
    end

    lines[#lines + 1] = string.format(
      "%2d.  %-38s  %10.4f s",
      i + 1, iname, length
    )
  end

  local avg = total / item_count

  local header  = string.format("%-4s %-38s  %10s\n%s",
    "#", "Item name", "Duration", string.rep("-", 56))

  local footer  = string.format(
    "%s\n%-42s  %10.4f s\n%-42s  %10.4f s\n%-42s  %10.4f s\n%-42s  %10.4f s",
    string.rep("-", 56),
    "Total:",   total,
    "Average:", avg,
    string.format("Longest  (#%d):", longest.idx),  longest.val,
    string.format("Shortest (#%d):", shortest.idx), shortest.val
  )

  local msg = header .. "\n" .. table.concat(lines, "\n") .. "\n" .. footer
  reaper.MB(msg, string.format("Selected Item Durations  (%d items)", item_count), 0)
end
