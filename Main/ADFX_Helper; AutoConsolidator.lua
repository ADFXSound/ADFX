function Msg(param)
	reaper.ShowConsoleMsg(tostring(param).."\n")
end

function SetCursorPosition()

	reaper.SetEditCurPos(item_pos, true, false)
	reaper.Main_OnCommandEx(40142, 0, 0)

end


function Main()
	
	count_sel_items = reaper.CountSelectedMediaItems(0)

	for i = 0, count_sel_items -1 do

		item = reaper.GetSelectedMediaItem(0, 0)

       	item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

		SetCursorPosition()

	end
end

Main()

 --playpos = reaper.GetPlayPosition()
  --reaper.SetEditCurPos(playpos, true, false)
  --reaper.GetSet_LoopTimeRange(true, true, playpos, playpos, false)
