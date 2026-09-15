--[[
 * ReaScript Name: ADFX_Helper; create markers intervals and align selected items to them
 * About: Automatically aligns selected items with equal spacing and creates markers at each item position
 * Author: ADFX 
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2025-03-05)
  + Initial Release
--]]

function main()
  -- Store the initial edit cursor position to restore later
  local initial_cursor_pos = reaper.GetCursorPosition()
  
  -- Check if any items are selected
  local num_selected_items = reaper.CountSelectedMediaItems(0)
  if num_selected_items == 0 then
    reaper.ShowMessageBox("No items selected. Please select some items.", "Error", 0)
    return
  end
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Get all selected items and their properties
  local items = {}
  for i = 0, num_selected_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    
    -- Get item name if available
    local item_name = ""
    if take then
      item_name = reaper.GetTakeName(take)
    end
    
    -- Add item to our list
    table.insert(items, {
      item = item,
      position = item_pos,
      length = item_length,
      name = item_name
    })
  end
  
  -- Sort items by their original positions
  table.sort(items, function(a, b) return a.position < b.position end)
  
  -- Fixed settings
  local spacing = 1 -- 1 second spacing between items
  local start_position = items[1].position -- Use first item's position
  
  -- Position for the first item
  local current_pos = start_position
  
  -- Reposition each item and create markers
  for i, item_data in ipairs(items) do
    -- Set the new position for this item
    reaper.SetMediaItemInfo_Value(item_data.item, "D_POSITION", current_pos)
    
    -- Create a marker at this item position
    local marker_name = "Item " .. i
    if item_data.name ~= "" then
      marker_name = item_data.name -- Use item/take name if available
    end
    reaper.AddProjectMarker(0, false, current_pos, 0, marker_name, -1)
    
    -- Calculate the position for the next item (current position + this item's length + spacing)
    current_pos = current_pos + item_data.length + spacing
  end
  
  -- Update the display
  reaper.UpdateArrange()
  
  -- Restore cursor position
  reaper.SetEditCurPos(initial_cursor_pos, false, false)
  
  -- End undo block
  reaper.Undo_EndBlock("Align Items and Create Markers", -1)
end

-- Execute the script
main()