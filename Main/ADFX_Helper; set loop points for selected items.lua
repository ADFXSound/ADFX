-- @description ADFX_Helper; set loop points for selected items
-- @version 1.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; set loops points for selected items
 * About: Sets loop points based on selected item(s). For a single item, sets loop to that item's boundaries.
 *      For multiple items, sets loop from the start of the first item to the end of the last item.
 * Author: ADFX 
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.3
--]]
--[[
 * Changelog:
 * v1.3 (2025-03-07)
  + Added moving playback cursor to loop start
 * v1.2 (2025-03-07)
  + Fixed focus issue preventing playback after script execution
 * v1.1 (2025-03-07)
  + Added check to enable repeat only if not already active
 * v1.0 (2025-03-07)
  + Initial Release
--]]

count = reaper.CountSelectedMediaItems(0)
if count > 0 then
  -- Find earliest start and latest end
  local start_pos = nil
  local end_pos = nil
  
  for i = 0, count-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    
    if start_pos == nil or pos < start_pos then start_pos = pos end
    if end_pos == nil or pos+len > end_pos then end_pos = pos+len end
  end
  
  -- Set time selection and loop points in one go
  reaper.Main_OnCommand(40635, 0) -- Remove time selection
  reaper.GetSet_LoopTimeRange(1, 0, start_pos, end_pos, 0)
  reaper.GetSet_LoopTimeRange(1, 1, start_pos, end_pos, 0)
  
  -- Enable repeat only if not already active
  if reaper.GetSetRepeat(-1) == 0 then
    reaper.GetSetRepeat(1)
  end
  
  -- Move playback cursor to loop start
  reaper.SetEditCurPos(start_pos, false, false)
  
  -- Return focus to arrange view/main window
  reaper.SetCursorContext(1, nil)
  reaper.Main_OnCommand(40914, 0) -- Set focus to main window
end
