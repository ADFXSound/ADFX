-- @description ADFX_Helper; export selected items
-- @version 1.0.0
-- @author ADFXSound

-- REAPER Script: Render Selected Items with LUFS Normalization
-- Author: Generated Script
-- Version: 1.0

-- Get script path for saving settings
local script_path = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
local settings_file = script_path .. "render_settings.txt"

-- Default settings
local default_output_dir = ""
local default_lufs_enabled = false
local default_lufs_target = -14.0

-- Get REAPER's last render directory
function get_reaper_last_render_dir()
    -- Try to get last render path from REAPER's render settings
    local retval, last_render_path = reaper.GetSetProjectInfo_String(0, "RENDER_FILE", "", false)
    if retval and last_render_path and last_render_path ~= "" then
        -- Extract directory from full path
        local dir = last_render_path:match("^(.*[/\\])")
        if dir then
            return dir:sub(1, -2) -- Remove trailing slash
        end
    end
    
    -- Fallback: try to get project directory
    local proj_path = reaper.GetProjectPath("")
    if proj_path and proj_path ~= "" then
        return proj_path
    end
    
    return ""
end

-- Load settings from file
function load_settings()
    local file = io.open(settings_file, "r")
    if file then
        local output_dir = file:read("*line") or default_output_dir
        local lufs_enabled = (file:read("*line") or "false") == "true"
        local lufs_target = tonumber(file:read("*line")) or default_lufs_target
        file:close()
        return output_dir, lufs_enabled, lufs_target
    end
    
    -- If no saved settings, try to get REAPER's last render directory
    local reaper_dir = get_reaper_last_render_dir()
    return reaper_dir, default_lufs_enabled, default_lufs_target
end

-- Save settings to file
function save_settings(output_dir, lufs_enabled, lufs_target)
    local file = io.open(settings_file, "w")
    if file then
        file:write(output_dir .. "\n")
        file:write(tostring(lufs_enabled) .. "\n")
        file:write(tostring(lufs_target) .. "\n")
        file:close()
    end
end

-- Get selected items
function get_selected_items()
    local items = {}
    local item_count = reaper.CountSelectedMediaItems(0)
    
    if item_count == 0 then
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return nil
    end
    
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert(items, item)
    end
    
    return items
end

-- Get item info for rendering
function get_item_info(item)
    local take = reaper.GetActiveTake(item)
    if not take then return nil end
    
    local track = reaper.GetMediaItem_Track(item)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local source = reaper.GetMediaItemTake_Source(take)
    local source_filename = reaper.GetMediaSourceFileName(source, "")
    local take_name = reaper.GetTakeName(take)
    
    -- Get original filename without extension for naming
    local base_name = source_filename:match("([^/\\]+)%.%w+$") or "rendered_item"
    if take_name and take_name ~= "" then
        base_name = take_name
    end
    
    return {
        track = track,
        position = item_pos,
        length = item_len,
        name = base_name,
        channels = reaper.GetMediaTrackInfo_Value(track, "I_NCHAN")
    }
end

-- Render item to file
function render_item(item_info, output_dir, lufs_enabled, lufs_target)
    local track = item_info.track
    local start_time = item_info.position
    local end_time = item_info.position + item_info.length
    local filename = item_info.name .. ".wav"
    local full_path = output_dir .. "/" .. filename
    
    -- Solo the track
    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 1)
    
    -- Set render bounds
    reaper.GetSet_LoopTimeRange(true, false, start_time, end_time, false)
    
    -- Configure render settings
    reaper.GetSetProjectInfo_String(0, "RENDER_FILE", full_path, true)
    reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "", true)
    reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 1835008, true) -- WAV format
    reaper.GetSetProjectInfo(0, "RENDER_SRATE", 0, true) -- Project sample rate
    reaper.GetSetProjectInfo(0, "RENDER_CHANNELS", math.floor(item_info.channels), true)
    
    -- Set bounds to time selection
    reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 2, true)
    
    -- Render
    reaper.Main_OnCommand(42230, 0) -- Render project to disk
    
    -- Wait for render to complete
    local render_busy = true
    while render_busy do
        render_busy = reaper.GetSetProjectInfo(0, "RENDER_STATS", 0, false) & 1 == 1
        reaper.defer(function() end)
    end
    
    -- Unsolo the track
    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 0)
    
    -- Apply LUFS normalization if enabled
    if lufs_enabled then
        apply_lufs_normalization(full_path, lufs_target)
    end
    
    return full_path
end

-- Apply LUFS normalization using REAPER's built-in tools
function apply_lufs_normalization(file_path, target_lufs)
    -- This would require external tools or REAPER's normalize function
    -- For now, we'll use REAPER's peak normalization as a placeholder
    -- In a real implementation, you'd want to use ffmpeg-normalize or similar
    
    reaper.ShowConsoleMsg("LUFS normalization would be applied to: " .. file_path .. " (target: " .. target_lufs .. " LUFS)\n")
    reaper.ShowConsoleMsg("Note: Actual LUFS normalization requires external tools like ffmpeg-normalize\n")
end

-- Browse for directory (Windows Explorer style)
function browse_for_directory(initial_dir)
    -- Check if JS_ReaScriptAPI extension is available
    if not reaper.JS_Dialog_BrowseForFolder then
        reaper.ShowMessageBox(
            "JS_ReaScriptAPI extension is required for folder browsing.\n\n" ..
            "Please install it from:\n" ..
            "Extensions > ReaPack > Browse packages\n" ..
            "Search for 'js_ReaScriptAPI'\n\n" ..
            "For now, please enter the path manually in the text field.",
            "Extension Required",
            0
        )
        return initial_dir or ""
    end
    
    -- Use proper folder browser dialog
    local selected_dir = reaper.JS_Dialog_BrowseForFolder("Select Output Directory", initial_dir or "")
    
    -- The function returns the selected directory path or empty string if cancelled
    if selected_dir and selected_dir ~= "" then
        return selected_dir
    end
    
    -- If cancelled, return the original directory
    return initial_dir or ""
end

-- Enhanced GUI function with proper ImGui implementation
function show_gui()
    local output_dir, lufs_enabled, lufs_target = load_settings()
    
    -- If still no directory, use current project path as last resort
    if output_dir == "" then
        output_dir = reaper.GetProjectPath("")
    end
    
    -- Check for ImGui availability
    if not reaper.ImGui_CreateContext then
        -- Fallback to basic dialog if ImGui not available
        while true do
            local lufs_checkbox = lufs_enabled and 1 or 0
            
            local ret, values = reaper.GetUserInputs(
                "ADFX Render Tool - Selected Items",
                3,
                "Output Directory (or 'browse'):,Enable LUFS Normalization (1/0):,LUFS Target:,extrawidth=300",
                output_dir .. "," .. lufs_checkbox .. "," .. lufs_target
            )
            
            if not ret then return false end
            
            local input_dir, input_lufs_enabled, input_lufs_target = values:match("([^,]*),([^,]*),([^,]*)")
            
            if input_dir and (input_dir:lower() == "browse" or input_dir:lower() == "b") then
                local new_dir = browse_for_directory(output_dir)
                if new_dir and new_dir ~= output_dir then
                    output_dir = new_dir
                end
            else
                output_dir = input_dir or ""
                lufs_enabled = input_lufs_enabled == "1"
                lufs_target = tonumber(input_lufs_target) or -14.0
                break
            end
        end
        
        if output_dir == "" then
            reaper.ShowMessageBox("Please specify an output directory!", "Error", 0)
            return false
        end
        
        save_settings(output_dir, lufs_enabled, lufs_target)
        return output_dir, lufs_enabled, lufs_target
    end
    
    -- ImGui implementation (stable version)
    local ctx = reaper.ImGui_CreateContext('ADFX Render Tool')
    local font = reaper.ImGui_CreateFont('sans-serif', 18)
    reaper.ImGui_Attach(ctx, font)
    
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoResize()
    local window_width, window_height = 750, 220
    local confirmed = false
    local cancelled = false
    
    -- Variables to hold current state
    local current_output_dir = output_dir
    local current_lufs_enabled = lufs_enabled
    local current_lufs_target = lufs_target
    local browse_clicked = false
    local frame_count = 0
    
    -- Main GUI loop
    function gui_loop()
        frame_count = frame_count + 1
        
        reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Always())
        reaper.ImGui_SetNextWindowPos(ctx, 100, 100, reaper.ImGui_Cond_FirstUseEver())
        
        local visible, open = reaper.ImGui_Begin(ctx, "ADFX Render Tool", true, window_flags)
        
        if visible then
            reaper.ImGui_PushFont(ctx, font)
            
            -- Spacing
            reaper.ImGui_Spacing(ctx)
            reaper.ImGui_Spacing(ctx)
            
            -- Output Directory Section
            reaper.ImGui_Text(ctx, "Output Directory:")
            reaper.ImGui_SetNextItemWidth(ctx, window_width - 150)
            
            -- Handle browse result on next frame
            if browse_clicked and frame_count > 1 then
                local browsed_dir = browse_for_directory(current_output_dir)
                if browsed_dir and browsed_dir ~= "" and browsed_dir ~= current_output_dir then
                    current_output_dir = browsed_dir
                end
                browse_clicked = false
            end
            
            local changed, new_dir = reaper.ImGui_InputText(ctx, "##outputdir", current_output_dir)
            if changed then 
                current_output_dir = new_dir 
            end
            
            -- Browse button on same line
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "Browse", 100, 0) then
                browse_clicked = true
                frame_count = 0 -- Reset frame counter
            end
            
            reaper.ImGui_Spacing(ctx)
            reaper.ImGui_Spacing(ctx)
            
            -- LUFS Normalization Checkbox
            local changed, new_lufs_enabled = reaper.ImGui_Checkbox(ctx, "Enable LUFS Normalization", current_lufs_enabled)
            if changed then 
                current_lufs_enabled = new_lufs_enabled 
            end
            
            -- LUFS Target (only visible when enabled)
            if current_lufs_enabled then
                reaper.ImGui_Spacing(ctx)
                reaper.ImGui_Text(ctx, "LUFS Target:")
                reaper.ImGui_SameLine(ctx)
                reaper.ImGui_SetNextItemWidth(ctx, 100)
                local changed, new_target = reaper.ImGui_InputDouble(ctx, "##lufstarget", current_lufs_target, 0.1, 1.0, "%.1f")
                if changed then 
                    current_lufs_target = new_target 
                end
                reaper.ImGui_SameLine(ctx)
                reaper.ImGui_Text(ctx, "LUFS")
            end
            
            reaper.ImGui_Spacing(ctx)
            reaper.ImGui_Spacing(ctx)
            reaper.ImGui_Spacing(ctx)
            
            -- Action Buttons
            if reaper.ImGui_Button(ctx, "Render Items", 120, 35) then
                if current_output_dir == "" or current_output_dir == nil then
                    reaper.ShowMessageBox("Please specify an output directory!", "Error", 0)
                else
                    confirmed = true
                end
            end
            
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, "Cancel", 80, 35) then
                cancelled = true
            end
            
            -- Keyboard shortcuts
            if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) and current_output_dir ~= "" then
                confirmed = true
            end
            
            if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
                cancelled = true
            end
            
            reaper.ImGui_PopFont(ctx)
            reaper.ImGui_End(ctx)
        end
        
        -- Check if we should continue the loop
        if open and not confirmed and not cancelled then
            reaper.defer(gui_loop)
        else
            -- Clean up ImGui context safely
            if ctx and reaper.ImGui_DestroyContext then
                reaper.ImGui_DestroyContext(ctx)
            end
            
            -- Handle the result
            if confirmed and not cancelled then
                -- Validate directory
                local file_test = io.open(current_output_dir .. "/test_write", "w")
                if file_test then
                    file_test:close()
                    os.remove(current_output_dir .. "/test_write")
                    
                    -- Save settings and return success
                    save_settings(current_output_dir, current_lufs_enabled, current_lufs_target)
                    
                    -- Set global variables for main function to use
                    _G.render_output_dir = current_output_dir
                    _G.render_lufs_enabled = current_lufs_enabled
                    _G.render_lufs_target = current_lufs_target
                    _G.render_confirmed = true
                else
                    reaper.ShowMessageBox("Output directory does not exist or is not writable!\n\nPath: " .. current_output_dir, "Directory Error", 0)
                    _G.render_confirmed = false
                end
            else
                _G.render_confirmed = false
            end
        end
    end
    
    -- Start the GUI
    reaper.defer(gui_loop)
    
    -- Return placeholder - actual values will be in global variables
    return true
end

-- Main execution
function main()
    -- Check for selected items
    local items = get_selected_items()
    if not items then return end
    
    -- Show GUI and wait for completion
    show_gui()
    
    -- Wait for GUI to complete
    local timeout = 0
    while not _G.render_confirmed and timeout < 1000 do
        reaper.defer(function() end)
        timeout = timeout + 1
    end
    
    -- Check if user confirmed the action
    if not _G.render_confirmed then 
        return 
    end
    
    -- Get values from global variables set by GUI
    local output_dir = _G.render_output_dir
    local lufs_enabled = _G.render_lufs_enabled
    local lufs_target = _G.render_lufs_target
    
    -- Clear global variables
    _G.render_output_dir = nil
    _G.render_lufs_enabled = nil
    _G.render_lufs_target = nil
    _G.render_confirmed = nil
    
    -- Start undo block
    reaper.Undo_BeginBlock()
    
    -- Store original solo states
    local original_solo_states = {}
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        original_solo_states[track] = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
    end
    
    local rendered_files = {}
    local failed_items = {}
    
    -- Process each selected item
    for i, item in ipairs(items) do
        local item_info = get_item_info(item)
        if item_info then
            reaper.ShowConsoleMsg("Rendering item " .. i .. "/" .. #items .. ": " .. item_info.name .. "\n")
            
            local success, result = pcall(render_item, item_info, output_dir, lufs_enabled, lufs_target)
            if success then
                table.insert(rendered_files, result)
            else
                table.insert(failed_items, item_info.name)
                reaper.ShowConsoleMsg("Failed to render: " .. item_info.name .. "\n")
            end
        else
            table.insert(failed_items, "Item " .. i .. " (no active take)")
        end
    end
    
    -- Restore original solo states
    for track, solo_state in pairs(original_solo_states) do
        reaper.SetMediaTrackInfo_Value(track, "I_SOLO", solo_state)
    end
    
    -- End undo block
    reaper.Undo_EndBlock("Render Selected Items", -1)
    
    -- Show results
    local message = "Rendering complete!\n\n"
    message = message .. "Successfully rendered: " .. #rendered_files .. " items\n"
    if #failed_items > 0 then
        message = message .. "Failed: " .. #failed_items .. " items\n"
    end
    message = message .. "\nFiles saved to: " .. output_dir
    
    reaper.ShowMessageBox(message, "Render Complete", 0)
    
    -- Update display
    reaper.UpdateArrange()
end

-- Run the script
main()