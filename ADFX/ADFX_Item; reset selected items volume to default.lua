--[[
 * ReaScript Name: ADFX_Helper; reset selected items volume to default
 * About: This resets the selected items volume to default values
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

function ResetItemVolume()
	if item_vol ~= 0
		then
		reaper.SetMediaItemInfo_Value(item, "D_VOL", 1)
	end

end

function ResetTakeVolume()
	if take_vol ~= 0 then
		reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", 1)
	end
end


function Main()

	count_sel_items = reaper.CountSelectedMediaItems(0)

	for i = 0, count_sel_items -1 do
		item = reaper.GetSelectedMediaItem(0, i)
		item_vol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
		take = reaper.GetMediaItemTake(item, i)
		take_vol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")

		ResetItemVolume()
		ResetTakeVolume()
	end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

Main()

reaper.UpdateArrange()
reaper.Undo_EndBlock("Undo End Block", 0)
reaper.PreventUIRefresh(-1)