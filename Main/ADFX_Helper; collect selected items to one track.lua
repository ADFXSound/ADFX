-- @description ADFX_Helper; collect selected items to one track
-- @version 1.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; collect selected items to one track
 * About: Collects all selected items and places them on a single track while preserving timestamps, and deletes empty source tracks
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2025-03-07)
  + Initial Release
--]]

function main()
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Count selected items
  local item_count = reaper.CountSelectedMediaItems(0)
  
  if item_count == 0 then
    reaper.ShowMessageBox("No items selected. Please select items first.", "Error", 0)
    return
  end
  
  -- Find the highest track index that contains a selected item
  local highest_track_idx = -1
  
  -- Store source tracks of selected items
  local source_tracks = {}
  
  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1 -- Convert to zero-based
    
    -- Add to source tracks table if not already there
    local track_guid = reaper.GetTrackGUID(track)
    source_tracks[track_guid] = track
    
    if track_idx > highest_track_idx then
      highest_track_idx = track_idx
    end
  end
  
  -- Insert new track after the highest track with selected items
  local insert_idx = highest_track_idx + 1
  reaper.InsertTrackAtIndex(insert_idx, true)
  local target_track = reaper.GetTrack(0, insert_idx)
  reaper.GetSetMediaTrackInfo_String(target_track, "P_NAME", "Collected Items", true)
  
  -- Store items in a table (because moving items changes the selection)
  local items = {}
  for i = 0, item_count - 1 do
    items[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
  
  -- Move each item to the target track
  for i = 1, #items do
    local item = items[i]
    
    -- Move the item to the target track
    reaper.MoveMediaItemToTrack(item, target_track)
  end
  
  -- Check source tracks and delete if empty
  local tracks_to_delete = {}
  
  for _, track in pairs(source_tracks) do
    -- Skip if this is the target track
    local track_guid = reaper.GetTrackGUID(track)
    local target_guid = reaper.GetTrackGUID(target_track)
    
    if track_guid ~= target_guid then
      -- Count items on the track
      local item_count = reaper.CountTrackMediaItems(track)
      
      if item_count == 0 then
        -- Store for deletion (can't delete now as it messes with indices)
        table.insert(tracks_to_delete, track)
      end
    end
  end
  
  -- Delete empty source tracks (in reverse to avoid index issues)
  for i = #tracks_to_delete, 1, -1 do
    local track = tracks_to_delete[i]
    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
    reaper.DeleteTrack(track)
  end
  
  -- Update the arrange view
  reaper.UpdateArrange()
  
  -- End undo block
  reaper.Undo_EndBlock("Move Items & Delete Empty Source Tracks", -1)
end

main()