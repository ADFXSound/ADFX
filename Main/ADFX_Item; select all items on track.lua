--[[
 * ReaScript Name: ADFX_Helper; select all items on track.lua
 * About: This selects all items on track
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

function Main()

	local track_count = reaper.CountSelectedTracks(0)
	for i = 0, track_count -1 do
		sel_item = reaper.GetSelectedTrack(0, i)
		reaper.Main_OnCommand(40421, 0, 0)
		--This selects all of the media items on the track
	end
end

Main()

