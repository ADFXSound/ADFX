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
 * v1.1 (2022-07-13)
  + Adding additional notes, Lokasenna, and various OCD related things
--]]

--[[
*NOTE: This script was designed for usaged with nvk_create, and nvk_workflow, it's otherwise untested and less effective. The nvk stuff is purchaseable from nvk @ https://nvktools.gumroad.com/
*NOTE: This script also requires Lokasenna: Track Selection Follows Item Selection, which needs to run at all times. https://github.com/ReaTeam/ReaScripts/raw/master/index.xml
 --]]

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CycleAmt = 8 -- Define desired amount of variations
EmptySpaceAmt = CycleAmt * 3 --Creates empty space in timeline relative to initial CycleAmt value

commandID = reaper.NamedCommandLookup("_RSca00b007868200550ca8e04476399c75889680f2") --nvk duplicate items SMART
commandID2 = reaper.NamedCommandLookup("_SWS_SELPREVITEM2") --select previous items

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function SetTimeSelectionToItems()
  reaper.Main_OnCommand(40290,0) --Set time selection to items
end

function CutItems()
  reaper.Main_OnCommand(41173,0) --Item Navigation: Move cursor to start of items

  reaper.Main_OnCommand(40059,0) --Edit Cut items/tracks/envelope points (depending on focus) Ignoring time selection
end

function InsertTime(num)
  local i = 1
  repeat
    reaper.Main_OnCommand(40200, 0) -- Timeselection: Insert empty space at time selection (moving later items)
    i = i + 1
  until i >= num
end

function PasteItems()
  position = reaper.GetCursorPosition()

  reaper.Main_OnCommand(40058, 0) --paste items/tracks

  reaper.SetEditCurPos(position, true, false)
end

function nvk_duplicate(num)
  local i = 1
  repeat
    reaper.Main_OnCommand(commandID, 0) --nvk duplicate items SMART
    i = i + 1
  until i >= num
end
 
function SelectPrevItems(num)
  local i = 1
  repeat 
    reaper.Main_OnCommand(commandID2, 0) --select previous items
    i = i + 1
  until i >= num
end

function GoToPrevTrack()
  reaper.Main_OnCommand(40286, 0) --Goto previous Track

end

function InsertEmptyItemAtSelection()
  for i =1, reaper.CountSelectedTracks(0) do
    trk = reaper.GetSelectedTrack(0,i-1)
    local start, et = reaper.GetSet_LoopTimeRange2( 0, 0, 0, 0, 0, 0 )
    reaper.CreateNewMIDIItemInProj( trk, start, et, 0) --Create the Folder track parent empty Item at the length of all variations
    end

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ FLOW ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function Main()
  SetTimeSelectionToItems()
  CutItems()
  InsertTime(EmptySpaceAmt)
  PasteItems()
  nvk_duplicate(CycleAmt)
  SetTimeSelectionToItems()
  SelectPrevItems(CycleAmt)
  SetTimeSelectionToItems()
  GoToPrevTrack()
  InsertEmptyItemAtSelection()
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

Main()

reaper.UpdateArrange()
reaper.Undo_EndBlock("Undo End Block", -1)
reaper.PreventUIRefresh(-1)

