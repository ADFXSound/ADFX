--[[
 * ReaScript Name: ADFX_Helper; align selected items together
 * About: Aligns selected items consecutively without spaces between them
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

function Main()
  -- Get number of selected items
  local itemCount = reaper.CountSelectedMediaItems(0)
  
  -- Check if any items are selected
  if itemCount < 2 then
    reaper.ShowMessageBox("Please select at least 2 items.", "Error", 0)
    return
  end
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Get all selected items and store them
  local items = {}
  for i = 0, itemCount - 1 do
    items[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
  
  -- Sort items by position
  table.sort(items, function(a, b)
    return reaper.GetMediaItemInfo_Value(a, "D_POSITION") < reaper.GetMediaItemInfo_Value(b, "D_POSITION")
  end)
  
  -- Get the starting position (position of the first item)
  local startPos = reaper.GetMediaItemInfo_Value(items[1], "D_POSITION")
  local currentPos = startPos
  
  -- Loop through each item and position it after the previous one
  for i = 1, itemCount do
    local item = items[i]
    local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    
    -- Set item position
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", currentPos)
    
    -- Update current position for next item
    currentPos = currentPos + itemLength
  end
  
  -- Update arrange view
  reaper.UpdateArrange()
  
  -- End undo block
  reaper.Undo_EndBlock("Align items back-to-back", -1)
end

-- Execute the function
Main()