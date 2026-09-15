-- @description ADFX_Helper; quick check
-- @version 2.0.0
-- @author ADFXSound

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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CycleAmt = 6 -- Define desired amount of variations
EmptySpaceAmt = CycleAmt * 3 --Creates empty space in timeline relative to initial CycleAmt value

commandID = reaper.NamedCommandLookup("_RSca00b007868200550ca8e04476399c75889680f2") --nvk duplicate items SMART
commandID2 = reaper.NamedCommandLookup("_SWS_SELPREVITEM2") --select previous items

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function Main2()
	reaper.Main_OnCommand(40297, 0) --unselect all tracks

	sel_items = reaper.CountSelectedMediaItems(0)
	for i=0, sel_items -1 do
		sel = reaper.GetSelectedMediaItem(0, i)
		track = reaper.GetMediaItem_Track(sel)
		reaper.SetTrackSelected(track, true)
	end

reaper.Main_OnCommand(40290,0) --Set time selection to items

reaper.Main_OnCommand(41173,0) --Item Navigation: Move cursor to start of items

reaper.Main_OnCommand(40059,0) --Edit Cut items/tracks/envelope points (depending on focus) Ignoring time selection

local i = 1
	repeat
		reaper.Main_OnCommand(40200, 0) -- Timeselection: Insert empty space at time selection (moving later items)
		i = i + 1
	until i >= num

	position = reaper.GetCursorPosition()

	reaper.Main_OnCommand(40058, 0) --paste items/tracks

	reaper.SetEditCurPos(position, true, false)
end

function nvk_duplicate(num)
	local i = 1
	repeat
		reaper.Main_OnCommand(commandID, 0)
		i = i + 1
	until i >= num
end
 
function SelectPrevItems(num)
	local i = 1
	repeat 
		reaper.Main_OnCommand(commandID2, 0)
		i = i + 1
	until i >= num
end

function Main3()
	reaper.Main_OnCommand(40286, 0) --Goto previous Track

	for i =1, reaper.CountSelectedTracks(0) do
    trk = reaper.GetSelectedTrack(0,i-1)
    local start, et = reaper.GetSet_LoopTimeRange2( 0, 0, 0, 0, 0, 0 )
    reaper.CreateNewMIDIItemInProj( trk, start, et, 0)
  end

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ FLOW ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

Main2()
nvk_duplicate(CycleAmt)
SelectPrevItems(EmptySpaceAmt)
Main3()

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Undo End Block", -1)

