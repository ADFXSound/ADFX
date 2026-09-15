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

Main()

reaper.UpdateArrange()