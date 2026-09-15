-- @description ADFX_Item; select all items on track
-- @version 1.0.0
-- @author ADFXSound

function Main()

	local track_count = reaper.CountSelectedTracks(0)
	for i = 0, track_count -1 do
		sel_item = reaper.GetSelectedTrack(0, i)
		reaper.Main_OnCommand(40421, 0, 0)
		--This selects all of the media items on the track
	end
end

Main()

