function insert_empty_item_to_time_selection()
	for i =1, reaper.CountSelectedTracks(0) do
		trk = reaper.GetSelectedTrack(0,i-1)
		local start, et = reaper.GetSet_LoopTimeRange2(0, 0, 0, 0, 0, 0)
		reaper.CreateNewMIDIItemInProj( trk, start, et, 0)
	end
end
insert_empty_item_to_time_selection()