-- @description ADFX_Helper; set item playback rate
-- @version 1.0.0
-- @author ADFXSound

-- Set Playback Rate and Stretch Selected Items with Auto-Spacing
-- This script prompts for a playback rate, applies it to all selected items,
-- and automatically spaces them out to prevent overlapping when stretched

function main()
    -- Get the number of selected items
    local num_items = reaper.CountSelectedMediaItems(0)
    
    if num_items == 0 then
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return
    end
    
    -- Prompt user for playback rate
    local retval, user_input = reaper.GetUserInputs("Set Playback Rate", 1, "Playback Rate (0.1 to 4.0):", "1.0")
    
    if not retval then
        return -- User cancelled
    end
    
    -- Convert input to number and validate
    local playback_rate = tonumber(user_input)
    
    if not playback_rate or playback_rate <= 0 or playback_rate > 4.0 then
        reaper.ShowMessageBox("Invalid playback rate! Please enter a value between 0.1 and 4.0", "Error", 0)
        return
    end
    
    -- Begin undo block
    reaper.Undo_BeginBlock()
    
    -- First pass: collect item information and calculate new lengths
    local items_info = {}
    
    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        
        if item then
            local take = reaper.GetActiveTake(item)
            
            if take then
                local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                local track = reaper.GetMediaItem_Track(item)
                
                -- Calculate new length based on playback rate
                local new_length = item_length / playback_rate
                
                table.insert(items_info, {
                    item = item,
                    take = take,
                    track = track,
                    original_start = item_start,
                    original_length = item_length,
                    new_length = new_length,
                    length_increase = new_length - item_length
                })
            end
        end
    end
    
    -- Sort items by track and then by start position
    table.sort(items_info, function(a, b)
        local track_a = reaper.GetMediaTrackInfo_Value(a.track, "IP_TRACKNUMBER")
        local track_b = reaper.GetMediaTrackInfo_Value(b.track, "IP_TRACKNUMBER")
        
        if track_a == track_b then
            return a.original_start < b.original_start
        else
            return track_a < track_b
        end
    end)
    
    -- Second pass: apply playback rate and adjust positions to prevent overlap
    local current_track = nil
    local track_end_position = 0
    
    for i, info in ipairs(items_info) do
        local item = info.item
        local take = info.take
        local track = info.track
        
        -- Check if we're on a new track
        local track_number = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        if current_track ~= track_number then
            current_track = track_number
            track_end_position = 0
        end
        
        -- Set the playback rate
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", playback_rate)
        
        -- Set the new item length
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", info.new_length)
        
        -- Calculate new position to prevent overlap
        local new_start_position = math.max(info.original_start, track_end_position)
        
        -- Set the new position
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_start_position)
        
        -- Update the track end position for the next item
        track_end_position = new_start_position + info.new_length
        
        -- Update the item in the arrange view
        reaper.UpdateItemInProject(item)
    end
    
    -- End undo block
    reaper.Undo_EndBlock("Set Playback Rate and Stretch Items with Auto-Spacing", -1)
    
    -- Update the arrange view
    reaper.UpdateArrange()
    
    -- Show confirmation message
    --reaper.ShowMessageBox(string.format("Applied playback rate %.2f to %d item(s) with auto-spacing", playback_rate, num_items), "Success", 0)
end

-- Run the main function
main()