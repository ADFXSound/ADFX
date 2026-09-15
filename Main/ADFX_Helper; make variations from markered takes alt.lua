--[[
 * ReaScript Name: ADFX_Helper; make variations from markered takes
 * About: A quick way to duplicate items, and consolidate items for export
 * Author: ADFX
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 6.63
 * Extensions: SWS/S&M 2.13.1.0
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2022-07-10)
	+ Initial Release
--]]

--[[
 * NOTE: This script was designed for usaged with nvk_create, and nvk_workflow, its otherwise untested and less effective. The nvk stuff is purchaseable from nvk @ https://nvktools.gumroad.com/
 --]]


-- Get the time selection start and end
local t_start, t_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

-- Check if a time selection is active
if t_start ~= t_end then
  -- Loop through all selected items
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    -- Check if the item overlaps with the time selection
    if item_start < t_end and item_end > t_start then
      -- Load and execute another script
      dofile("C:/Users/Mr_Doctor_M1/AppData/Roaming/REAPER/Scripts/nvk-ReaScripts/FOLDER_ITEMS/nvk_FOLDER_ITEMS - Add new items to existing folder.lua")
    end
  end
else
  reaper.ShowMessageBox("Please make a time selection.", "Error", 0)
end