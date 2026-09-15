-- @description ADFX_Helper; copy name script multiple_BottomToTop
-- @version 2.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; copy name from bottom to top
 * About: -- Copies the name from the bottom track item to top track item -- 
 * -- Based on the vertical grouping pattern of the reference script
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.1
--]]
--[[
 * Changelog:
 * v1.1 (2025-03-18)
  + Modified to copy name from bottom track to top track
 * v1.0 (2025-03-07)
  + Initial Release
--]]

-- Group items by position/time
function group_items_by_position()
  local item_count = reaper.CountSelectedMediaItems(0)
  local position_groups = {}
  
  -- Tolerance for considering items to be at the same position (in seconds)
  local time_tolerance = 0.001
  
  -- Group items by position
  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    
    -- Find a matching group or create a new one
    local found_group = false
    
    for group_pos, group in pairs(position_groups) do
      if math.abs(group_pos - position) < time_tolerance then
        table.insert(group.items, item)
        found_group = true
        break
      end
    end
    
    if not found_group then
      position_groups[position] = {
        items = {item}
      }
    end
  end
  
  return position_groups
end

-- Copy name from reference item to target item
function copy_item_name(reference_item, target_item)
  -- Get takes from items
  local reference_take = reaper.GetActiveTake(reference_item)
  local target_take = reaper.GetActiveTake(target_item)
  
  if not reference_take or not target_take then
    return false, "Both items must have valid takes."
  end
  
  -- Get reference name
  local retval, reference_name = reaper.GetSetMediaItemTakeInfo_String(reference_take, "P_NAME", "", false)
  
  -- Copy the name
  reaper.GetSetMediaItemTakeInfo_String(target_take, "P_NAME", reference_name, true)
  reaper.UpdateItemInProject(target_item)
  
  return true
end

-- Process items grouped by vertical position
function process_vertical_groups()
  -- Group selected items by position
  local position_groups = group_items_by_position()
  
  -- Count groups
  local group_count = 0
  for _, _ in pairs(position_groups) do
    group_count = group_count + 1
  end
  
  if group_count == 0 then
    return
  end
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Process each position group
  for position, group in pairs(position_groups) do
    local items = group.items
    
    -- Skip groups with only one item
    if #items < 2 then
      goto continue
    end
    
    -- Sort items by track index (top to bottom)
    table.sort(items, function(a, b)
      local track_a = reaper.GetMediaItemTrack(a)
      local track_b = reaper.GetMediaItemTrack(b)
      local idx_a = reaper.GetMediaTrackInfo_Value(track_a, "IP_TRACKNUMBER")
      local idx_b = reaper.GetMediaTrackInfo_Value(track_b, "IP_TRACKNUMBER")
      return idx_a < idx_b
    end)
    
    -- Use the last item (bottom track) as reference instead of the first
    local reference_item = items[#items]
    
    -- Process all other items in the group except the reference item
    for i = 1, #items - 1 do
      local target_item = items[i]
      copy_item_name(reference_item, target_item)
    end
    
    ::continue::
  end
  
  -- End undo block
  reaper.Undo_EndBlock("Copy Names from Bottom to Top Track Items", -1)
end

-- Main function
function main()
  -- Get count of selected items
  local item_count = reaper.CountSelectedMediaItems(0)
  
  -- No items selected
  if item_count == 0 then
    reaper.ShowMessageBox("Please select at least two items to copy names.", "Error", 0)
    return
  end
  
  -- For exactly two items, use simple pair mode
  if item_count == 2 then
    -- Get both selected items
    local item1 = reaper.GetSelectedMediaItem(0, 0)
    local item2 = reaper.GetSelectedMediaItem(0, 1)
    
    -- Get tracks for both items
    local track1 = reaper.GetMediaItemTrack(item1)
    local track2 = reaper.GetMediaItemTrack(item2)
    
    -- Get track indices
    local idx1 = reaper.GetMediaTrackInfo_Value(track1, "IP_TRACKNUMBER")
    local idx2 = reaper.GetMediaTrackInfo_Value(track2, "IP_TRACKNUMBER")
    
    -- Determine which is top and which is bottom
    local top_item, bottom_item
    if idx1 < idx2 then
      top_item = item1
      bottom_item = item2
    else
      top_item = item2
      bottom_item = item1
    end
    
    -- Begin undo block
    reaper.Undo_BeginBlock()
    
    -- Copy from bottom to top
    copy_item_name(bottom_item, top_item)
    
    -- End undo block
    reaper.Undo_EndBlock("Copy name from bottom to top item", -1)
  else
    -- More than two items, use vertical processing mode for stacked items
    process_vertical_groups()
  end
end

-- Execute script
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()