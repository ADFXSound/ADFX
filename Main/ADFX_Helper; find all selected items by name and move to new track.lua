-- Script: Move Selected Items with Specific Name to New Track
-- Description: Locates all selected items containing a specific search term
--              and moves them to a newly created track named after that term.

function Main()
  -- Get project info
  local proj = reaper.EnumProjects(-1)
  
  -- Get search term from user
  local retval, search_term = reaper.GetUserInputs("Move Items by Name", 1, "Enter search term:", "")
  if not retval or search_term == "" then return end
  
  -- Check if we have any selected items first
  local selected_items_count = reaper.CountSelectedMediaItems(proj)
  if selected_items_count == 0 then
    reaper.ShowMessageBox("No items are selected. Please select some items first.", "Error", 0)
    return
  end
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Store items that match the search term
  local matching_items = {}
  local item_count = 0
  
  -- Find items with matching name
  for i = 0, selected_items_count - 1 do
    local item = reaper.GetSelectedMediaItem(proj, i)
    local take = reaper.GetActiveTake(item)
    
    if take then
      local take_name = reaper.GetTakeName(take)
      
      if string.find(string.lower(take_name), string.lower(search_term)) then
        item_count = item_count + 1
        matching_items[item_count] = item
      end
    end
  end
  
  -- Check if any matching items were found
  if item_count == 0 then
    reaper.ShowMessageBox("No items with '" .. search_term .. "' in their name found.", "No Matches", 0)
    reaper.Undo_EndBlock("Find Items by Name (No matches)", -1)
    return
  end
  
  -- Determine where to insert the new track
  -- We'll place it directly after the track of the first matching item
  local track_index = -1
  if item_count > 0 then
    local parent_track = reaper.GetMediaItemTrack(matching_items[1])
    local parent_track_idx = reaper.GetMediaTrackInfo_Value(parent_track, "IP_TRACKNUMBER") - 1
    track_index = parent_track_idx + 1
  else
    track_index = reaper.CountTracks(proj)
  end
  
  -- Create new track and name it
  reaper.InsertTrackAtIndex(track_index, true)
  local new_track = reaper.GetTrack(proj, track_index)
  reaper.GetSetMediaTrackInfo_String(new_track, "P_NAME", search_term, true)
  
  -- Move matching items to the new track
  for i = 1, item_count do
    reaper.MoveMediaItemToTrack(matching_items[i], new_track)
  end
  
  -- End undo block
  reaper.Undo_EndBlock("Move items containing '" .. search_term .. "' to new track", -1)
  
  -- Provide feedback to user
  reaper.ShowMessageBox("Moved " .. item_count .. " items to new track '" .. search_term .. "'", "Operation Complete", 0)
end

-- Run the script
Main()