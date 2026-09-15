--[[
 * ReaScript Name: ADFX_Helper; render selected items to new single track
 * About: -- Processes each selected item one by one with:
          -- 1. Set loop points for each item individually
          -- 2. Render each item to a new track (matching original channel count)
          -- 3. Collect all rendered items to a single track
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
 * v1.1
  + Added channel-matched rendering (mono items render to mono, stereo to stereo)
--]]

-- Function to convert dB to linear volume
function dBToLinear(dB)
    return 10^(dB/20)
end

-- Function to convert linear volume to dB
function linearTodB(linear)
    if linear <= 0 then
        return -150 -- Minimum dB value
    end
    return 20 * math.log(linear) / math.log(10)
end

-- Function to get the channel count of a media item
function GetItemChannelCount(item)
    local take = reaper.GetActiveTake(item)
    if not take then return 2 end -- Default to stereo if no take
    
    local source = reaper.GetMediaItemTake_Source(take)
    if not source then return 2 end -- Default to stereo if no source
    
    local channels = reaper.GetMediaSourceNumChannels(source)
    return channels or 2 -- Default to stereo if can't determine
end

-- Function to render item with matching channel count
function RenderItemWithChannelMatch(item)
    local channels = GetItemChannelCount(item)
    
    local render_cmd_id
    if channels == 1 then
        -- Render to mono
        render_cmd_id = reaper.NamedCommandLookup("_SWS_AWRENDERMONOSMART")
        if render_cmd_id == 0 then
            -- Fallback to regular mono render if smart version not available
            render_cmd_id = reaper.NamedCommandLookup("_SWS_AWRENDERMONO")
        end
    else
        -- Render to stereo (2 or more channels)
        render_cmd_id = reaper.NamedCommandLookup("_SWS_AWRENDERSTEREOSMART")
        if render_cmd_id == 0 then
            -- Fallback to regular stereo render if smart version not available
            render_cmd_id = reaper.NamedCommandLookup("_SWS_AWRENDERSTEREO")
        end
    end
    
    if render_cmd_id ~= 0 then
        reaper.Main_OnCommand(render_cmd_id, 0)
        return true
    else
        reaper.ShowConsoleMsg("Warning: Could not find appropriate SWS render command for " .. channels .. " channels\n")
        return false
    end
end

-- Function to get volume adjustment from user
function GetVolumeAdjustment()
    -- Show input dialog for volume adjustment
    local retval, userInput = reaper.GetUserInputs(
        "Volume Compensation", 
        1, 
        "Pre-render volume boost (dB):", 
        "0.00"
    )
    
    -- Check if user cancelled or input is empty
    if not retval or userInput == "" then
        return nil
    end
    
    -- Convert input to number
    local adjustmentdB = tonumber(userInput)
    
    -- Validate input
    if not adjustmentdB then
        reaper.ShowMessageBox("Invalid input. Please enter a valid number.", "Error", 0)
        return nil
    end
    
    -- Clamp dB value to reasonable range (-150 to +24 dB)
    if adjustmentdB < -150 then
        adjustmentdB = -150
    elseif adjustmentdB > 24 then
        adjustmentdB = 24
        reaper.ShowMessageBox("Volume adjustment clamped to +24 dB for safety.", "Warning", 0)
    end
    
    return adjustmentdB
end

-- Function to apply volume adjustment to items
function ApplyVolumeToItems(items, adjustmentdB)
    local adjustmentLinear = dBToLinear(adjustmentdB)
    
    for i = 1, #items do
        local item = items[i]
        if reaper.ValidatePtr2(0, item, "MediaItem*") then
            local currentVolume = reaper.GetMediaItemInfo_Value(item, "D_VOL")
            local newVolume = currentVolume * adjustmentLinear
            reaper.SetMediaItemInfo_Value(item, "D_VOL", newVolume)
        end
    end
    reaper.UpdateArrange()
end

function Main()
    -- Check if the project has ever been saved (has a filename)
    local proj_name = reaper.GetProjectName(0, "")
    if proj_name == "" then
        reaper.MB("Please save the session before running this script.\n\nThis script processes multiple items and it's recommended to save your project first for safety.", "Save Required", 0)
        return
    end
    
    -- Store all selected items in a table
    local count = reaper.CountSelectedMediaItems(0)
    if count == 0 then return end
    
    -- Get volume adjustment from user
    local volumeAdjustmentdB = GetVolumeAdjustment()
    if volumeAdjustmentdB == nil then
        return -- User cancelled
    end
    
    -- Add confirmation dialog for large selections
    local THRESHOLD = 10 -- Adjust this threshold as needed
    if count > THRESHOLD then
        local confirm = reaper.MB("You're about to process " .. count .. " items with " .. string.format("%.2f", volumeAdjustmentdB) .. " dB volume compensation. This could take some time.\n\nContinue?", "ADFX_Helper Confirmation", 1)
        if confirm ~= 1 then
            reaper.ShowConsoleMsg("\nOperation cancelled by user.\n")
            return
        end
    end
    
    local items = {}
    local original_item_names = {}
    local original_volumes = {} -- Store original volumes for restoration
    local item_channel_counts = {} -- Store channel counts for logging
    
    for i = 0, count-1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        items[i+1] = item
        
        -- Store original item name
        local take = reaper.GetActiveTake(item)
        if take then
            local retval, item_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
            original_item_names[i+1] = item_name
        else
            original_item_names[i+1] = ""
        end
        
        -- Store original volume
        original_volumes[i+1] = reaper.GetMediaItemInfo_Value(item, "D_VOL")
        
        -- Store channel count for logging
        item_channel_counts[i+1] = GetItemChannelCount(item)
    end
    
    -- Apply volume adjustment to all items before processing
    if volumeAdjustmentdB ~= 0 then
        reaper.ShowConsoleMsg("Applying " .. string.format("%.2f", volumeAdjustmentdB) .. " dB volume boost to " .. count .. " items...\n")
        ApplyVolumeToItems(items, volumeAdjustmentdB)
    end
    
    -- Table to store original track information
    local original_tracks = {}
    
    -- Table to store newly rendered items with their original names
    local rendered_items = {}
    local rendered_item_names = {}
    
    -- Remember original selection and time selection
    local orig_start_time, orig_end_time = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
    local orig_repeat_state = reaper.GetToggleCommandState(1068) -- Get repeat state
    
    -- Add a cancel flag
    local cancelled = false
    
    -- Create a progress dialog
    local title = "ADFX_Helper Progress"
    local msg = "Processing item 1 of " .. count
    reaper.ClearConsole()
    
    -- Capture all existing tracks before processing
    local existing_tracks = {}
    local track_count_before = reaper.CountTracks(0)
    for i = 0, track_count_before - 1 do
        existing_tracks[reaper.GetTrackGUID(reaper.GetTrack(0, i))] = true
    end
    
    -- Process each item one by one
    for i = 1, #items do
        -- Update progress message
        local channels_text = item_channel_counts[i] == 1 and "mono" or "stereo"
        msg = "Processing item " .. i .. " of " .. count .. " (" .. channels_text .. ")\n\nPress Escape to cancel"
        reaper.ShowConsoleMsg("\n" .. msg)
        
        -- Check for ESC key press (user cancellation)
        if reaper.HasExtState("ADFX_Helper", "cancel") == "1" or reaper.JS_Window_FromPoint(0, 0) == nil then
            cancelled = true
            reaper.ShowConsoleMsg("\n\nOperation cancelled by user.\n")
            break
        end
        
        -- Set an ExtState that script is running
        reaper.SetExtState("ADFX_Helper", "running", "1", false)
        
        local item = items[i]
        local track = reaper.GetMediaItemTrack(item)
        
        -- Store the original track for this item
        original_tracks[i] = track
        
        -- Deselect all items and tracks
        reaper.Main_OnCommand(40289, 0) -- Unselect all items
        reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
        
        -- Select only current item
        reaper.SetMediaItemSelected(item, true)
        
        -- Also select its parent track to ensure rendering from the correct source
        reaper.SetTrackSelected(track, true)
        reaper.UpdateArrange()
        
        -- Get position and length of the current item
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local end_pos = pos + len
        
        -- Clear any existing time selection
        reaper.Main_OnCommand(40635, 0) -- Remove time selection
        
        -- Set time selection and loop points to only this item
        reaper.GetSet_LoopTimeRange(1, 0, pos, end_pos, 0)
        reaper.GetSet_LoopTimeRange(1, 1, pos, end_pos, 0)
        
        -- Make sure we're at the start of the item
        reaper.SetEditCurPos(pos, false, false)
        
        -- Make sure repeat is enabled
        if reaper.GetToggleCommandState(1068) == 0 then
            reaper.Main_OnCommand(1068, 0) -- Enable repeat
        end
        
        -- Run ADFX_Helper script for the current item
        -- Try running by exact script name
        if reaper.APIExists("ReaScript_GetFunctionByName") then
            local func = reaper.ReaScript_GetFunctionByName("ADFX_Helper; Set loops points for selected item.lua")
            if func then reaper.JS_Callback_Execute(func) end
        else
            -- Fallback to command ID if available
            local cmd_id = reaper.NamedCommandLookup("_ADFX_Helper; Set loops points for selected item")
            if cmd_id ~= 0 then
                reaper.Main_OnCommand(cmd_id, 0)
            end
        end
        
        -- Ensure time selection is still correct
        reaper.GetSet_LoopTimeRange(1, 0, pos, end_pos, 0)
        
        -- Sleep briefly to ensure settings are applied
        reaper.defer(function() end)
        
        -- Now render with channel-matched rendering
        local render_success = RenderItemWithChannelMatch(item)
        if render_success then
            -- Sleep to allow render to complete
            local start_time = reaper.time_precise()
            local function wait_for_completion()
                if reaper.time_precise() - start_time < 1.0 then -- Increased to 1 second delay
                    reaper.defer(wait_for_completion)
                end
            end
            reaper.defer(wait_for_completion)
            
            -- After rendering, find all new tracks and their items
            local track_count_after = reaper.CountTracks(0)
            for j = 0, track_count_after - 1 do
                local new_track = reaper.GetTrack(0, j)
                local track_guid = reaper.GetTrackGUID(new_track)
                
                -- If this track didn't exist before, it's a new rendered track
                if not existing_tracks[track_guid] then
                    -- Get track name to verify it's a stem track
                    local retval, track_name = reaper.GetTrackName(new_track)
                    if track_name:find("stem") then
                        -- Add all items from this new track to our rendered items list
                        local item_count_on_track = reaper.CountTrackMediaItems(new_track)
                        for k = 0, item_count_on_track - 1 do
                            local rendered_item = reaper.GetTrackMediaItem(new_track, k)
                            table.insert(rendered_items, rendered_item)
                            -- Store the original name for this rendered item
                            table.insert(rendered_item_names, original_item_names[i])
                            
                            -- Immediately restore the original name to the rendered item
                            local take = reaper.GetActiveTake(rendered_item)
                            if take and original_item_names[i] then
                                reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", original_item_names[i], true)
                            end
                            
                            -- Apply inverse volume compensation to rendered item
                            if volumeAdjustmentdB ~= 0 then
                                local currentVolume = reaper.GetMediaItemInfo_Value(rendered_item, "D_VOL")
                                local inverseAdjustment = dBToLinear(-volumeAdjustmentdB)
                                local newVolume = currentVolume * inverseAdjustment
                                reaper.SetMediaItemInfo_Value(rendered_item, "D_VOL", newVolume)
                            end
                        end
                    end
                    -- Mark this track as existing for next iteration
                    existing_tracks[track_guid] = true
                end
            end
        else
            reaper.ShowConsoleMsg("Failed to render item " .. i .. ", skipping...\n")
        end
        
        -- Important: Deselect any tracks that might have been selected during rendering
        reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
        reaper.Main_OnCommand(40289, 0) -- Unselect all items
        
        -- Check for cancellation again after processing this item
        if reaper.HasExtState("ADFX_Helper", "cancel") == "1" then
            cancelled = true
            reaper.ShowConsoleMsg("\n\nOperation cancelled after processing item " .. i .. ".\n")
            break
        end
    end
    
    -- Restore original volumes to source items
    if volumeAdjustmentdB ~= 0 then
        reaper.ShowConsoleMsg("\nRestoring original volumes to source items...\n")
        for i = 1, #items do
            local item = items[i]
            if reaper.ValidatePtr2(0, item, "MediaItem*") then
                reaper.SetMediaItemInfo_Value(item, "D_VOL", original_volumes[i])
            end
        end
        reaper.UpdateArrange()
    end
    
    -- Clear the running state
    reaper.DeleteExtState("ADFX_Helper", "running", false)
    reaper.DeleteExtState("ADFX_Helper", "cancel", false)
    
    -- If processing completed successfully (not cancelled), consolidate the rendered items
    if not cancelled and #rendered_items > 0 then
        reaper.ShowConsoleMsg("\nProcessing complete. Consolidating " .. #rendered_items .. " rendered items...\n")
        ConsolidateRenderedItems(rendered_items, rendered_item_names)
    elseif not cancelled then
        reaper.ShowConsoleMsg("\nProcessing complete, but no rendered items were found to consolidate.\n")
    end
    
    -- Restore original time selection and repeat state
    reaper.GetSet_LoopTimeRange(1, 0, orig_start_time, orig_end_time, 0)
    reaper.GetSet_LoopTimeRange(1, 1, orig_start_time, orig_end_time, 0)
    
    -- Restore original repeat state
    if orig_repeat_state == 0 and reaper.GetToggleCommandState(1068) == 1 then
        reaper.Main_OnCommand(1068, 0) -- Toggle repeat off
    elseif orig_repeat_state == 1 and reaper.GetToggleCommandState(1068) == 0 then
        reaper.Main_OnCommand(1068, 0) -- Toggle repeat on
    end
    
    if cancelled then
        -- Reselect all original items if cancelled
        reaper.Main_OnCommand(40289, 0) -- Unselect all items
        reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
        
        for j = 1, #items do
            local item = items[j]
            if reaper.ValidatePtr2(0, item, "MediaItem*") then
                reaper.SetMediaItemSelected(item, true)
            end
        end
        
        reaper.ShowConsoleMsg("\nProcessing was cancelled. Items processed: " .. (i-1) .. " of " .. count .. "\n")
    else
        -- Select all items on the consolidated track if consolidation happened
        if #rendered_items > 0 then
            reaper.ShowConsoleMsg("\nAll operations complete. " .. count .. " items processed and " .. #rendered_items .. " rendered items consolidated with " .. string.format("%.2f", volumeAdjustmentdB) .. " dB compensation applied.\n")
        else
            -- If no consolidation, reselect original items
            reaper.Main_OnCommand(40289, 0) -- Unselect all items
            for j = 1, #items do
                local item = items[j]
                if reaper.ValidatePtr2(0, item, "MediaItem*") then
                    reaper.SetMediaItemSelected(item, true)
                end
            end
            reaper.ShowConsoleMsg("\nProcessing complete. " .. count .. " items processed.\n")
        end
    end
    
    reaper.UpdateArrange()
end

function ConsolidateRenderedItems(rendered_items, rendered_item_names)
    if #rendered_items == 0 then
        reaper.ShowConsoleMsg("No rendered items to consolidate.\n")
        return
    end
    
    -- First, select all the rendered items (names should already be restored)
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    for i = 1, #rendered_items do
        if reaper.ValidatePtr2(0, rendered_items[i], "MediaItem*") then
            reaper.SetMediaItemSelected(rendered_items[i], true)
        end
    end
    
    -- Find the highest track index that contains a rendered item
    local highest_track_idx = -1
    
    -- Store source tracks of rendered items (the -stem tracks)
    local source_tracks = {}
    
    for i = 1, #rendered_items do
        local item = rendered_items[i]
        if reaper.ValidatePtr2(0, item, "MediaItem*") then
            local track = reaper.GetMediaItem_Track(item)
            local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1 -- Convert to zero-based
            
            -- Add to source tracks table if not already there
            local track_guid = reaper.GetTrackGUID(track)
            source_tracks[track_guid] = track
            
            if track_idx > highest_track_idx then
                highest_track_idx = track_idx
            end
        end
    end
    
    -- Insert new track after the highest track with rendered items
    local insert_idx = highest_track_idx + 1
    reaper.InsertTrackAtIndex(insert_idx, true)
    local target_track = reaper.GetTrack(0, insert_idx)
    reaper.GetSetMediaTrackInfo_String(target_track, "P_NAME", "Collected Items", true)
    
    -- Move each rendered item to the target track
    for i = 1, #rendered_items do
        local item = rendered_items[i]
        if reaper.ValidatePtr2(0, item, "MediaItem*") then
            -- Move the item to the target track
            reaper.MoveMediaItemToTrack(item, target_track)
        end
    end
    
    -- Check source tracks and delete if empty (these should be the -stem tracks)
    local tracks_to_delete = {}
    
    for _, track in pairs(source_tracks) do
        -- Skip if this is the target track
        local track_guid = reaper.GetTrackGUID(track)
        local target_guid = reaper.GetTrackGUID(target_track)
        
        if track_guid ~= target_guid then
            -- Count items on the track
            local track_item_count = reaper.CountTrackMediaItems(track)
            
            if track_item_count == 0 then
                -- Store for deletion (can't delete now as it messes with indices)
                table.insert(tracks_to_delete, track)
            end
        end
    end
    
    -- Delete empty source tracks (in reverse order by track index to avoid index issues)
    table.sort(tracks_to_delete, function(a, b)
        local idx_a = reaper.GetMediaTrackInfo_Value(a, "IP_TRACKNUMBER")
        local idx_b = reaper.GetMediaTrackInfo_Value(b, "IP_TRACKNUMBER")
        return idx_a > idx_b -- Sort in descending order for deletion
    end)
    
    for i = 1, #tracks_to_delete do
        local track = tracks_to_delete[i]
        reaper.DeleteTrack(track)
    end
    
    -- Select all items on the target track
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    for i = 1, #rendered_items do
        if reaper.ValidatePtr2(0, rendered_items[i], "MediaItem*") then
            reaper.SetMediaItemSelected(rendered_items[i], true)
        end
    end
    
    reaper.ShowConsoleMsg("Rendered items consolidated to 'Collected Items' track and empty stem tracks deleted.\n")
end

-- Add key listener function to detect ESC key
function listenForEscKey()
    local function checkKeys()
        local hwnd = reaper.GetMainHwnd()
        if reaper.JS_Window_GetForeground() == hwnd then
            if reaper.JS_Window_GetTitle(hwnd):find("REAPER") then
                if reaper.HasExtState("ADFX_Helper", "running") == "1" then
                    -- Check for ESC key
                    local is_esc = reaper.JS_VKeys_GetState(0) 
                    if is_esc:byte(0x1B) ~= 0 then
                        reaper.SetExtState("ADFX_Helper", "cancel", "1", false)
                        return
                    end
                else
                    return
                end
            end
        end
        reaper.defer(checkKeys)
    end
    
    if reaper.APIExists("JS_VKeys_GetState") then
        checkKeys()
    end
end

-- Execute the script
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

-- Start ESC key listener if JS API is available
if reaper.APIExists("JS_Window_FromPoint") and reaper.APIExists("JS_VKeys_GetState") then
    listenForEscKey()
end

Main()

reaper.Undo_EndBlock("Process Multiple Selected Items with Volume Compensation & Consolidate", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()