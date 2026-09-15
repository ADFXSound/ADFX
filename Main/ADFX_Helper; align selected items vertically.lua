-- Align Selected Items Vertically to Different Tracks
-- This script moves selected items to sequential tracks while preserving their timeline positions

function main()
    -- Check if we have selected items
    local num_items = reaper.CountSelectedMediaItems(0)
    if num_items == 0 then
        reaper.ShowMessageBox("No items selected. Please select some items first.", "Error", 0)
        return
    end
    
    -- Begin undo block
    reaper.Undo_BeginBlock()
    
    -- Store selected items and find the earliest position
    local items = {}
    local earliest_position = math.huge
    
    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        table.insert(items, {item = item, position = position})
        
        -- Track the earliest position
        if position < earliest_position then
            earliest_position = position
        end
    end
    
    -- Sort items by their original position (for consistent track assignment)
    table.sort(items, function(a, b) return a.position < b.position end)
    
    -- Get the track of the first selected item as starting point
    local first_track = reaper.GetMediaItem_Track(items[1].item)
    local first_track_idx = reaper.GetMediaTrackInfo_Value(first_track, "IP_TRACKNUMBER") - 1
    
    -- Create tracks if needed and move items
    for i, item_data in ipairs(items) do
        local target_track_idx = first_track_idx + (i - 1)
        
        -- Ensure we have enough tracks
        local track_count = reaper.CountTracks(0)
        while target_track_idx >= track_count do
            reaper.InsertTrackAtIndex(track_count, false)
            track_count = track_count + 1
        end
        
        -- Get target track
        local target_track = reaper.GetTrack(0, target_track_idx)
        
        -- Move item to target track
        reaper.MoveMediaItemToTrack(item_data.item, target_track)
        
        -- Set item position to the earliest position
        reaper.SetMediaItemInfo_Value(item_data.item, "D_POSITION", earliest_position)
    end
    
    -- End undo block
    reaper.Undo_EndBlock("Align selected items vertically to different tracks", -1)
    
    -- Update display
    reaper.UpdateArrange()

end

-- Run the script
main()