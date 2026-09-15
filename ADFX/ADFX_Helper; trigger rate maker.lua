--[[
 * ReaScript Name: ADFX_Helper; trigger rate maker
 * About: Create a 6 second loop at desired trigger rate, randomizing selected items, on a new track
 * Author: ADFX
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2025-03-05)
  + Initial Release
--]]


-- Random Short Segments Script
-- Configuration
local LOOP_LENGTH = 6.0  -- Total loop length in seconds

function Main()
  -- Prompt for segment length
  local retval, user_input = reaper.GetUserInputs("Segment Length", 1,
    "Segment length (seconds):",
    "0.12")
  
  if not retval then return end  -- User canceled
  
  -- Validate and convert input
  local SEGMENT_LENGTH = tonumber(user_input)
  if not SEGMENT_LENGTH or SEGMENT_LENGTH <= 0 or SEGMENT_LENGTH >= LOOP_LENGTH then
    reaper.ShowMessageBox("Please enter a valid segment length between 0 and " .. LOOP_LENGTH .. " seconds", "Error", 0)
    return
  end
  
  local NUM_SEGMENTS = math.floor(LOOP_LENGTH / SEGMENT_LENGTH)
  
  -- Get selected items
  local num_items = reaper.CountSelectedMediaItems(0)
  if num_items == 0 then
    reaper.ShowMessageBox("Please select some items", "Error", 0)
    return
  end
  
  if num_items == 1 then
    reaper.ShowMessageBox("Please select at least 2 items to prevent repetition", "Error", 0)
    return
  end
  
  -- Find lowest selected track
  local lowest_track_index = 0
  for i = 0, num_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
    lowest_track_index = math.max(lowest_track_index, track_idx)
  end
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Create new track below the lowest selected track
  reaper.InsertTrackAtIndex(lowest_track_index + 1, true)
  local new_track = reaper.GetTrack(0, lowest_track_index + 1)
  
  -- Store selected items with their names
  local source_items = {}
  for i = 0, num_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    local name = take and reaper.GetTakeName(take) or "Unnamed"
    table.insert(source_items, {
      item = item,
      name = name
    })
  end
  
  -- Function to get random item excluding last used
  local function getRandomItem(last_used_index)
    local available_indices = {}
    for i = 1, #source_items do
      if i ~= last_used_index then
        table.insert(available_indices, i)
      end
    end
    local random_idx = math.random(#available_indices)
    return available_indices[random_idx], source_items[available_indices[random_idx]]
  end
  
  -- Create segments
  local last_used_index = nil
  for i = 1, NUM_SEGMENTS do
    -- Pick random source item (excluding last used)
    local chosen_index, source_data = getRandomItem(last_used_index)
    last_used_index = chosen_index
    
    local source_item = source_data.item
    local source_take = reaper.GetActiveTake(source_item)
    
    -- Calculate position
    local position = (i - 1) * SEGMENT_LENGTH
    
    -- Create new item
    local new_item = reaper.AddMediaItemToTrack(new_track)
    reaper.SetMediaItemPosition(new_item, position, false)
    reaper.SetMediaItemLength(new_item, SEGMENT_LENGTH, false)
    
    -- Copy and adjust take
    local new_take = reaper.AddTakeToMediaItem(new_item)
    reaper.SetMediaItemTake_Source(new_take, reaper.GetMediaItemTake_Source(source_take))
    reaper.SetMediaItemTakeInfo_Value(new_take, "D_STARTOFFS", 
      reaper.GetMediaItemTakeInfo_Value(source_take, "D_STARTOFFS"))
    reaper.SetMediaItemTakeInfo_Value(new_take, "D_PLAYRATE", 
      reaper.GetMediaItemTakeInfo_Value(source_take, "D_PLAYRATE"))
    
    -- Set the new take name to include the source name
    reaper.GetSetMediaItemTakeInfo_String(new_take, "P_NAME", source_data.name, true)
  end
  
  -- Set loop points
  reaper.GetSet_LoopTimeRange(true, false, 0, LOOP_LENGTH, false)
  reaper.Main_OnCommand(40632, 0) -- Toggle repeat (loop) on
  
  -- End undo block
  reaper.Undo_EndBlock("Create Random Segments", -1)
  
  -- Update arrange view
  reaper.UpdateArrange()
end

-- Add script to REAPER's action list
if not preset_file_init then
  local _, _, sectionID = reaper.get_action_context()
  reaper.SetToggleCommandState(sectionID, 0, 0)
  reaper.RefreshToolbar2(sectionID, 0)
end

Main()