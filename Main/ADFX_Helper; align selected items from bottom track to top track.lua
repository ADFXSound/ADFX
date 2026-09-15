-- @description ADFX_Helper; align selected items from bottom track to top track
-- @version 2.0.0
-- @author ADFXSound

-- Script Name: Align Selected Items from Bottom Track to Top Track
-- Description: This script aligns all selected media items from the bottom track to match
--              the positions of items on the top track in the selection.
-- Author: Claude
-- Version: 1.0

function main()
  -- Get count of selected items
  local item_count = reaper.CountSelectedMediaItems(0)
  
  if item_count < 2 then
    reaper.ShowMessageBox("Please select at least two items on different tracks.", "Error", 0)
    return
  end
  
  -- Find the top and bottom tracks in the selection
  local top_track = nil
  local bottom_track = nil
  local top_track_idx = math.huge
  local bottom_track_idx = -1
  
  -- First pass: find the top and bottom tracks
  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    
    if track_idx < top_track_idx then
      top_track_idx = track_idx
      top_track = track
    end
    
    if track_idx > bottom_track_idx then
      bottom_track_idx = track_idx
      bottom_track = track
    end
  end
  
  if top_track == bottom_track then
    reaper.ShowMessageBox("Selected items must be on different tracks.", "Error", 0)
    return
  end
  
  -- Collect all items on the top track and bottom track
  local top_items = {}
  local bottom_items = {}
  
  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    
    if track == top_track then
      table.insert(top_items, item)
    elseif track == bottom_track then
      table.insert(bottom_items, item)
    end
  end
  
  if #top_items == 0 or #bottom_items == 0 then
    reaper.ShowMessageBox("Need selected items on both the top and bottom tracks.", "Error", 0)
    return
  end
  
  -- Sort items by position
  table.sort(top_items, function(a, b)
    return reaper.GetMediaItemInfo_Value(a, "D_POSITION") < reaper.GetMediaItemInfo_Value(b, "D_POSITION")
  end)
  
  table.sort(bottom_items, function(a, b)
    return reaper.GetMediaItemInfo_Value(a, "D_POSITION") < reaper.GetMediaItemInfo_Value(b, "D_POSITION")
  end)
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Align items from bottom track to top track
  local min_count = math.min(#top_items, #bottom_items)
  
  for i = 1, min_count do
    local top_pos = reaper.GetMediaItemInfo_Value(top_items[i], "D_POSITION")
    local bottom_item = bottom_items[i]
    
    -- Set the position of the bottom item to match the top item
    reaper.SetMediaItemInfo_Value(bottom_item, "D_POSITION", top_pos)
  end
  
  -- End undo block
  reaper.UpdateTimeline()
  reaper.Undo_EndBlock("Align Items from Bottom Track to Top Track", -1)
end

-- Run the script
main()