--[[
 * ReaScript Name: ADFX_Helper; align selected items to grid
 * About: Automatically aligns selected items to consecutive downbeats (1, 2, 3, etc.) when possible, or skips to next available downbeat if item length requires it
 * Author: ADFX
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 6.63
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2022-07-10)
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
  
  -- Function to find the next available downbeat
  local function nextAvailableDownbeat(current_pos)
    -- Find the nearest downbeat position at or after current_pos
    local beat = math.ceil(current_pos)
    -- If we're already exactly on a downbeat, return the current position
    if beat == current_pos then
      return beat
    end
    -- Otherwise return the next downbeat
    return beat
  end
  
  -- Start position for the first item (moved to the next downbeat)
  local current_pos = nextAvailableDownbeat(items[1].position)
  
  -- Reposition each item
  for i, item_data in ipairs(items) do
    -- Set the new position for this item
    reaper.SetMediaItemInfo_Value(item_data.item, "D_POSITION", current_pos)
    
    -- Calculate the next position (current position + this item's length)
    current_pos = current_pos + item_data.length
    
    -- Find the next available downbeat
    current_pos = nextAvailableDownbeat(current_pos)
  end
  
  -- Update the display
  reaper.UpdateArrange()
  
  -- Restore cursor position
  reaper.SetEditCurPos(initial_cursor_pos, false, false)
  
  -- End undo block
  reaper.Undo_EndBlock("Align Selected Items to Consecutive Downbeats", -1)
end

-- Execute the script
main()