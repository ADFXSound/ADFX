-- @description ADFX_Helper; sort selected items by length
-- @version 2.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; auto lufs loudness matching multiple
 * About: This script matches the LUFS volume of the second selected item to the first one for multiple pairs
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2025-03-07)
  + Initial Release
--]]

function main()
  -- Check if any items are selected
  local item_count = reaper.CountSelectedMediaItems(0)
  if item_count == 0 then
    reaper.ShowMessageBox("No items selected. Please select items to sort.", "Error", 0)
    return
  end
  
  -- Get the track of the first selected item
  local first_item = reaper.GetSelectedMediaItem(0, 0)
  local first_track = reaper.GetMediaItemTrack(first_item)
  
  -- Check if all selected items are on the same track
  for i = 1, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItemTrack(item)
    
    if track ~= first_track then
      reaper.ShowMessageBox("Selected items must be on the same track.", "Error", 0)
      return
    end
  end
  
  -- Create a table to store items and their lengths
  local items = {}
  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    
    items[i+1] = {
      item = item,
      length = length,
      position = position
    }
  end
  
  -- Sort items by length (longest to shortest)
  table.sort(items, function(a, b) return a.length > b.length end)
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Get the position of the first item (leftmost)
  local start_position = math.huge
  for i = 1, #items do
    start_position = math.min(start_position, items[i].position)
  end
  
  -- Reposition items in order
  local current_position = start_position
  for i = 1, #items do
    reaper.SetMediaItemPosition(items[i].item, current_position, true)
    current_position = current_position + items[i].length
  end
  
  -- End undo block
  reaper.Undo_EndBlock("Sort Selected Items by Length (Longest to Shortest)", -1)
  
  -- Update the arrange view
  reaper.UpdateArrange()
end

main()