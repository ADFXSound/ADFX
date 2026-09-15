--[[
 * ReaScript Name: ADFX_Helper; align selected items to markers
 * About: Automatically aligns selected items to markers while preventing overlap
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
  
  -- Get all markers in the project
  local markers = {}
  local num_markers = reaper.CountProjectMarkers(0)
  
  if num_markers == 0 then
    reaper.ShowMessageBox("No markers found in project. Please add markers first.", "Error", 0)
    return
  end
  
  -- Collect all marker positions
  for i = 0, num_markers - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
    if retval and not isrgn then -- only use markers, not regions
      table.insert(markers, {
        position = pos,
        name = name,
        index = markrgnindexnumber
      })
    end
  end
  
  -- Sort markers by position
  table.sort(markers, function(a, b) return a.position < b.position end)
  
  if #markers == 0 then
    reaper.ShowMessageBox("No markers found in project (only regions). Please add markers.", "Error", 0)
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
  
  -- Function to find the next available marker position
  local function nextAvailableMarker(pos)
    for i, marker in ipairs(markers) do
      if marker.position >= pos then
        return marker.position
      end
    end
    -- If no marker is found after pos, return the last marker position + 1
    return markers[#markers].position + 1
  end
  
  -- Start position for the first item (moved to the nearest marker)
  local current_pos = nextAvailableMarker(items[1].position)
  local marker_index = 1
  
  -- Reposition each item
  for i, item_data in ipairs(items) do
    -- Set the new position for this item
    reaper.SetMediaItemInfo_Value(item_data.item, "D_POSITION", current_pos)
    
    -- Calculate the end position of this item
    local item_end = current_pos + item_data.length
    
    -- Find the next available marker position that comes after this item
    current_pos = nextAvailableMarker(item_end)
  end
  
  -- Update the display
  reaper.UpdateArrange()
  
  -- Restore cursor position
  reaper.SetEditCurPos(initial_cursor_pos, false, false)
  
  -- End undo block
  reaper.Undo_EndBlock("Align Selected Items to Markers", -1)
end

-- Execute the script
main()