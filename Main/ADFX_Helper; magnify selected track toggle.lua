-- @description ADFX_Helper; magnify selected track toggle
-- @version 2.0.0
-- @author ADFXSound

-- Toggle Magnify Selected Track View
-- This script toggles between a magnified view of the selected track (with automation lanes)
-- and the previous view state. It stores/restores track visibility, heights, and scroll position.

local SCRIPT_NAME = "Toggle_Magnify_Selected_Track"
local EXT_SECTION = "MagnifyTrackView"
local STATE_KEY = "is_magnified"
local DATA_KEY = "saved_state"

-- Helper function to serialize a table to string
local function serialize(tbl)
    local result = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            table.insert(result, k .. "={" .. serialize(v) .. "}")
        else
            table.insert(result, k .. "=" .. tostring(v))
        end
    end
    return table.concat(result, ";")
end

-- Helper function to deserialize string to table
local function deserialize(str)
    local tbl = {}
    if not str or str == "" then return tbl end
    
    for pair in string.gmatch(str, "([^;]+)") do
        local key, value = string.match(pair, "([^=]+)=(.+)")
        if key and value then
            if string.sub(value, 1, 1) == "{" then
                value = deserialize(string.sub(value, 2, -2))
            elseif tonumber(value) then
                value = tonumber(value)
            elseif value == "true" then
                value = true
            elseif value == "false" then
                value = false
            end
            tbl[key] = value
        end
    end
    return tbl
end

-- Get the current state of all tracks
local function get_all_tracks_state()
    local state = {
        tracks = {},
        scroll_pos = 0,
        magnified_track_guid = ""
    }
    
    -- Get scroll position
    local arrange = reaper.JS_Window_Find("trackview", true)
    if arrange then
        local _, scroll_pos = reaper.JS_Window_GetScrollInfo(arrange, "v")
        state.scroll_pos = scroll_pos or 0
    end
    
    -- Get all track states
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        if track then
            local guid = reaper.GetTrackGUID(track)
            local height = reaper.GetMediaTrackInfo_Value(track, "I_TCPH") -- Current TCP height
            local visible = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP")
            local env_height = reaper.GetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE")
            
            state.tracks[guid] = {
                height = height,
                visible = visible,
                env_height = env_height
            }
            
            -- Also save envelope lane states
            local env_count = reaper.CountTrackEnvelopes(track)
            local env_states = {}
            for e = 0, env_count - 1 do
                local env = reaper.GetTrackEnvelope(track, e)
                if env then
                    local br_env = reaper.BR_EnvAlloc(env, false)
                    local active, vis, armed, inLane, laneHeight, defShape, minVal, maxVal, centerVal, envType, faderScaling, automationItemsOptions = reaper.BR_EnvGetProperties(br_env)
                    reaper.BR_EnvFree(br_env, false)
                    
                    local _, env_name = reaper.GetEnvelopeName(env)
                    env_states[env_name] = {
                        visible = vis,
                        in_lane = inLane,
                        lane_height = laneHeight
                    }
                end
            end
            state.tracks[guid].envelopes = env_states
        end
    end
    
    return state
end

-- Restore all tracks to saved state
local function restore_tracks_state(state)
    if not state or not state.tracks then return end
    
    reaper.PreventUIRefresh(1)
    
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        if track then
            local guid = reaper.GetTrackGUID(track)
            local track_state = state.tracks[guid]
            
            if track_state then
                -- Restore visibility
                reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", track_state.visible or 1)
                
                -- Restore height
                if track_state.height and track_state.height > 0 then
                    reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", track_state.height)
                end
                
                -- Restore envelope states
                if track_state.envelopes then
                    local env_count = reaper.CountTrackEnvelopes(track)
                    for e = 0, env_count - 1 do
                        local env = reaper.GetTrackEnvelope(track, e)
                        if env then
                            local _, env_name = reaper.GetEnvelopeName(env)
                            local env_state = track_state.envelopes[env_name]
                            
                            if env_state then
                                local br_env = reaper.BR_EnvAlloc(env, false)
                                local active, vis, armed, inLane, laneHeight, defShape, minVal, maxVal, centerVal, envType, faderScaling, automationItemsOptions = reaper.BR_EnvGetProperties(br_env)
                                
                                reaper.BR_EnvSetProperties(br_env, active, env_state.visible or false, armed, env_state.in_lane or false, env_state.lane_height or 0, defShape, faderScaling)
                                reaper.BR_EnvFree(br_env, true)
                            end
                        end
                    end
                end
            end
        end
    end
    
    reaper.TrackList_AdjustWindows(false)
    
    -- Restore scroll position
    local arrange = reaper.JS_Window_Find("trackview", true)
    if arrange and state.scroll_pos then
        reaper.JS_Window_SetScrollPos(arrange, "v", state.scroll_pos)
    end
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

-- Magnify the selected track
local function magnify_selected_track()
    local selected_track = reaper.GetSelectedTrack(0, 0)
    if not selected_track then
        reaper.ShowMessageBox("Please select a track first.", SCRIPT_NAME, 0)
        return false
    end
    
    reaper.PreventUIRefresh(1)
    
    local selected_guid = reaper.GetTrackGUID(selected_track)
    
    -- Get arrange window height for sizing
    local arrange = reaper.JS_Window_Find("trackview", true)
    local arrange_height = 600 -- default
    if arrange then
        local _, _, _, h = reaper.JS_Window_GetClientRect(arrange)
        arrange_height = h or 600
    end
    
    -- Count envelopes to calculate sizes
    local env_count = reaper.CountTrackEnvelopes(selected_track)
    local env_visible_count = 0
    
    -- First pass: count how many envelopes we'll show
    for e = 0, env_count - 1 do
        local env = reaper.GetTrackEnvelope(selected_track, e)
        if env then
            env_visible_count = env_visible_count + 1
        end
    end
    
    -- Get the track's current height and double it
    local current_track_height = reaper.GetMediaTrackInfo_Value(selected_track, "I_TCPH")
    local track_height = math.floor(current_track_height * 2)
    local env_height = track_height
    
    -- Apply minimum heights
    track_height = math.max(track_height, 50)
    env_height = math.max(env_height, 50)
    
    -- Hide all tracks and set selected track
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        if track then
            local guid = reaper.GetTrackGUID(track)
            if guid == selected_guid then
                -- Show and magnify selected track
                reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
                reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", track_height)
                
                -- Show all automation lanes
                for e = 0, env_count - 1 do
                    local env = reaper.GetTrackEnvelope(track, e)
                    if env then
                        local br_env = reaper.BR_EnvAlloc(env, false)
                        local active, vis, armed, inLane, laneHeight, defShape, minVal, maxVal, centerVal, envType, faderScaling, automationItemsOptions = reaper.BR_EnvGetProperties(br_env)
                        
                        -- Make envelope visible in its own lane with good height
                        reaper.BR_EnvSetProperties(br_env, active, true, armed, true, env_height, defShape, faderScaling)
                        reaper.BR_EnvFree(br_env, true)
                    end
                end
            else
                -- Hide other tracks
                reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
            end
        end
    end
    
    reaper.TrackList_AdjustWindows(false)
    
    -- Scroll to top to show the selected track
    if arrange then
        reaper.JS_Window_SetScrollPos(arrange, "v", 0)
    end
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    
    return true, selected_guid
end

-- Check if SWS extension is available
local function check_sws()
    if not reaper.BR_EnvAlloc then
        reaper.ShowMessageBox(
            "This script requires the SWS Extension.\n\nPlease install it from: https://www.sws-extension.org/",
            SCRIPT_NAME,
            0
        )
        return false
    end
    return true
end

-- Check if JS extension is available
local function check_js()
    if not reaper.JS_Window_Find then
        reaper.ShowMessageBox(
            "This script requires the JS ReaScript API extension.\n\nPlease install it from ReaPack:\nExtensions > ReaPack > Browse packages > js_ReaScriptAPI",
            SCRIPT_NAME,
            0
        )
        return false
    end
    return true
end

-- Main function
local function main()
    -- Check for required extensions
    if not check_sws() then return end
    if not check_js() then return end
    
    -- Check current state
    local is_magnified = reaper.GetExtState(EXT_SECTION, STATE_KEY)
    
    if is_magnified == "1" then
        -- Currently magnified - restore previous state
        local saved_data = reaper.GetExtState(EXT_SECTION, DATA_KEY)
        
        if saved_data and saved_data ~= "" then
            -- Simple restoration approach - use stored track data
            local state = {}
            
            -- Parse the saved data (simplified format)
            for line in string.gmatch(saved_data, "([^\n]+)") do
                local guid, height, visible, env_data = string.match(line, "([^|]+)|([^|]+)|([^|]+)|?(.*)")
                if guid then
                    state[guid] = {
                        height = tonumber(height) or 0,
                        visible = tonumber(visible) or 1,
                        envelopes = {}
                    }
                    
                    -- Parse envelope data
                    if env_data and env_data ~= "" then
                        for env_info in string.gmatch(env_data, "([^,]+)") do
                            local env_name, vis, lane, lane_h = string.match(env_info, "([^:]+):([^:]+):([^:]+):([^:]+)")
                            if env_name then
                                state[guid].envelopes[env_name] = {
                                    visible = vis == "1",
                                    in_lane = lane == "1",
                                    lane_height = tonumber(lane_h) or 0
                                }
                            end
                        end
                    end
                end
            end
            
            -- Restore all tracks
            reaper.PreventUIRefresh(1)
            
            local track_count = reaper.CountTracks(0)
            for i = 0, track_count - 1 do
                local track = reaper.GetTrack(0, i)
                if track then
                    local guid = reaper.GetTrackGUID(track)
                    local track_state = state[guid]
                    
                    if track_state then
                        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", track_state.visible)
                        if track_state.height > 0 then
                            reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", track_state.height)
                        end
                        
                        -- Restore envelopes
                        local env_count = reaper.CountTrackEnvelopes(track)
                        for e = 0, env_count - 1 do
                            local env = reaper.GetTrackEnvelope(track, e)
                            if env then
                                local _, env_name = reaper.GetEnvelopeName(env)
                                local env_state = track_state.envelopes[env_name]
                                
                                if env_state then
                                    local br_env = reaper.BR_EnvAlloc(env, false)
                                    local active, vis, armed, inLane, laneHeight, defShape, minVal, maxVal, centerVal, envType, faderScaling = reaper.BR_EnvGetProperties(br_env)
                                    reaper.BR_EnvSetProperties(br_env, active, env_state.visible, armed, env_state.in_lane, env_state.lane_height, defShape, faderScaling)
                                    reaper.BR_EnvFree(br_env, true)
                                end
                            end
                        end
                    else
                        -- Track wasn't in saved state, make it visible
                        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
                    end
                end
            end
            
            reaper.TrackList_AdjustWindows(false)
            reaper.PreventUIRefresh(-1)
            reaper.UpdateArrange()
        end
        
        -- Clear magnified state
        reaper.SetExtState(EXT_SECTION, STATE_KEY, "0", false)
        reaper.SetExtState(EXT_SECTION, DATA_KEY, "", false)
        
    else
        -- Not magnified - save current state and magnify
        local selected_track = reaper.GetSelectedTrack(0, 0)
        if not selected_track then
            reaper.ShowMessageBox("Please select a track first.", SCRIPT_NAME, 0)
            return
        end
        
        -- Save current state in simple format
        local save_data = {}
        local track_count = reaper.CountTracks(0)
        
        for i = 0, track_count - 1 do
            local track = reaper.GetTrack(0, i)
            if track then
                local guid = reaper.GetTrackGUID(track)
                local height = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
                local visible = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP")
                
                -- Get envelope states
                local env_parts = {}
                local env_count = reaper.CountTrackEnvelopes(track)
                for e = 0, env_count - 1 do
                    local env = reaper.GetTrackEnvelope(track, e)
                    if env then
                        local _, env_name = reaper.GetEnvelopeName(env)
                        local br_env = reaper.BR_EnvAlloc(env, false)
                        local active, vis, armed, inLane, laneHeight = reaper.BR_EnvGetProperties(br_env)
                        reaper.BR_EnvFree(br_env, false)
                        
                        -- Escape colons in envelope name
                        env_name = string.gsub(env_name, ":", "_")
                        table.insert(env_parts, string.format("%s:%d:%d:%d", 
                            env_name, 
                            vis and 1 or 0, 
                            inLane and 1 or 0, 
                            laneHeight or 0))
                    end
                end
                
                local env_str = table.concat(env_parts, ",")
                table.insert(save_data, string.format("%s|%d|%d|%s", guid, height, visible, env_str))
            end
        end
        
        -- Store the state
        reaper.SetExtState(EXT_SECTION, DATA_KEY, table.concat(save_data, "\n"), false)
        
        -- Now magnify
        local success = magnify_selected_track()
        
        if success then
            reaper.SetExtState(EXT_SECTION, STATE_KEY, "1", false)
        end
    end
    
    reaper.Undo_OnStateChange(SCRIPT_NAME)
end

-- Run the script
main()
