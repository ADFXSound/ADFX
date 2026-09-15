-- @description ADFX_Helper; pro tools style pre roll
-- @version 1.0.0
-- @author ADFXSound

-- Pro Tools Style Pre-Roll Record
-- Sets a punch-in point at cursor, plays from X bars/beats/seconds before, and auto-records at cursor
--
-- CONFIGURATION: Edit these values to set your preferred pre-roll amount
-- ============================================================================

local PREROLL_AMOUNT = 1          -- How much pre-roll (number of units)
local PREROLL_UNIT = "bars"       -- "bars", "beats", or "seconds"

-- ============================================================================
-- END CONFIGURATION
-- ============================================================================

function GetProjectTempo()
    return reaper.Master_GetTempo()
end

function GetTimeSignature(position)
    local _, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, position)
    return cml, cdenom  -- beats per measure, beat note value
end

function BarsToSeconds(bars, position)
    local bpm = GetProjectTempo()
    local beats_per_bar, _ = GetTimeSignature(position)
    local beats = bars * beats_per_bar
    return (beats / bpm) * 60
end

function BeatsToSeconds(beats)
    local bpm = GetProjectTempo()
    return (beats / bpm) * 60
end

function GetPrerollSeconds(position)
    if PREROLL_UNIT == "seconds" then
        return PREROLL_AMOUNT
    elseif PREROLL_UNIT == "beats" then
        return BeatsToSeconds(PREROLL_AMOUNT)
    elseif PREROLL_UNIT == "bars" then
        return BarsToSeconds(PREROLL_AMOUNT, position)
    else
        reaper.ShowMessageBox("Invalid PREROLL_UNIT. Use 'bars', 'beats', or 'seconds'.", "Error", 0)
        return nil
    end
end

function Main()
    -- Get current edit cursor position (this will be our punch-in point)
    local punch_in_pos = reaper.GetCursorPosition()
    
    -- Calculate pre-roll in seconds
    local preroll_seconds = GetPrerollSeconds(punch_in_pos)
    if not preroll_seconds then return end
    
    -- Calculate the playback start position
    local play_start_pos = punch_in_pos - preroll_seconds
    if play_start_pos < 0 then play_start_pos = 0 end
    
    -- Set up time selection for auto-punch (from punch-in to end of project or a reasonable length)
    local project_length = reaper.GetProjectLength(0)
    local punch_out_pos = project_length
    if punch_out_pos <= punch_in_pos then
        punch_out_pos = punch_in_pos + 3600  -- Default 1 hour if project is empty
    end
    
    -- Set time selection (defines the auto-punch region)
    reaper.GetSet_LoopTimeRange(true, false, punch_in_pos, punch_out_pos, false)
    
    -- Enable auto-punch record mode
    -- Action 40076: Record Mode: Auto-punch selected area
    local punch_mode = reaper.GetToggleCommandState(40076)
    if punch_mode ~= 1 then
        reaper.Main_OnCommand(40076, 0)
    end
    
    -- Move edit cursor to pre-roll start position
    reaper.SetEditCurPos(play_start_pos, true, false)
    
    -- Start recording (will play until punch-in point, then record)
    reaper.Main_OnCommand(1013, 0)  -- Transport: Record
    
    reaper.UpdateArrange()
end

-- Run with undo block
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Pro Tools Style Pre-Roll Record", -1)
