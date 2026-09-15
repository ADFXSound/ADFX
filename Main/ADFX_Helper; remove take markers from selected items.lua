-- @description ADFX_Helper; remove take markers from selected items
-- @version 1.0.0
-- @author ADFXSound

-- Remove Take Markers From Selected Items
-- Targets numbered downward-triangle take markers visible on items

reaper.Undo_BeginBlock()

local selected_count = reaper.CountSelectedMediaItems(0)

if selected_count == 0 then
  reaper.ShowMessageBox("No items selected.", "Remove Take Markers", 0)
  return
end

local total_removed = 0

for i = 0, selected_count - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local take_count = reaper.CountTakes(item)

  for t = 0, take_count - 1 do
    local take = reaper.GetTake(item, t)
    if take ~= nil then
      local marker_count = reaper.GetNumTakeMarkers(take)
      -- Delete in reverse to avoid index shifting
      for m = marker_count - 1, 0, -1 do
        reaper.DeleteTakeMarker(take, m)
        total_removed = total_removed + 1
      end
    end
  end

  reaper.UpdateItemInProject(item)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Remove Take Markers From Selected Items", -1)
