-- @description ADFX_Helper; insert track respect folders_New
-- @version 1.0.0
-- @author ADFXSound

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local script_name = "ADFX_Helper; insert track respect folders_New"


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Empty string = use theme/global default TCP layout
function setTrackLayout(track)
reaper.GetSetMediaTrackInfo_String(track, "P_TCP_LAYOUT", "", true)
end

function main()
if reaper.CountSelectedTracks(0) > 0 then
local sel_track = reaper.GetSelectedTrack(0, 0)
local sel_track_idx = reaper.GetMediaTrackInfo_Value(sel_track, "IP_TRACKNUMBER")

local folder_depth = reaper.GetMediaTrackInfo_Value(sel_track, "I_FOLDERDEPTH")
local folder_depth_prev_track = 0

if sel_track_idx > 1 then
  folder_depth_prev_track = reaper.GetMediaTrackInfo_Value(
    reaper.GetTrack(0, sel_track_idx - 2),
    "I_FOLDERDEPTH"
  )
end

-- Normal track right after the last track in a nested folder
if folder_depth == 0 and folder_depth_prev_track < 0 then
  reaper.InsertTrackAtIndex(sel_track_idx, true)

  local new_track = reaper.GetTrack(0, sel_track_idx)
  setTrackLayout(new_track)
  reaper.SetOnlyTrackSelected(new_track)

-- Last track in a folder right after the last track in a nested folder
elseif folder_depth < 0 and folder_depth_prev_track < 0 then
  reaper.InsertTrackAtIndex(sel_track_idx, true)

  local new_track = reaper.GetTrack(0, sel_track_idx)
  setTrackLayout(new_track)

  reaper.SetOnlyTrackSelected(new_track)
  reaper.ReorderSelectedTracks(sel_track_idx, 2)

-- Folder parent
elseif folder_depth == 1 then
  reaper.InsertTrackAtIndex(sel_track_idx, true)

  local new_track = reaper.GetTrack(0, sel_track_idx)
  setTrackLayout(new_track)
  reaper.SetOnlyTrackSelected(new_track)

-- Normal track, or last track in folder/nested folder
elseif folder_depth <= 0 then
  reaper.InsertTrackAtIndex(sel_track_idx - 1, true)

  local new_track = reaper.GetTrack(0, sel_track_idx - 1)
  setTrackLayout(new_track)

  reaper.SetOnlyTrackSelected(sel_track)
  reaper.ReorderSelectedTracks(sel_track_idx - 1, 2)
  reaper.SetOnlyTrackSelected(new_track)
end

else
-- Insert track at end of project if none selected
local track_count = reaper.CountTracks(0)
reaper.InsertTrackAtIndex(track_count, true)

local new_track = reaper.GetTrack(0, track_count)
setTrackLayout(new_track)
reaper.SetOnlyTrackSelected(new_track)

end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function dbg(dbg)
reaper.ShowConsoleMsg(dbg .. "\n")
end

function msg(msg)
reaper.MB(msg, script_name, 0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
