--[[
 * ReaScript Name: ADFX_Helper; create markers at grid intervals
 * About: Create markers on the downbeat of 1 at grid intervals
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

function main()
  -- Prompt for number of markers to add
  local retval, num_markers = reaper.GetUserInputs("Add Markers on Downbeats", 1, "Number of markers to add:,extrawidth=100", "8")
  
  -- Exit if user canceled
  if not retval then return end
  
  -- Convert input to number
  num_markers = tonumber(num_markers)
  
  -- Validate input
  if not num_markers or num_markers <= 0 then
    reaper.ShowMessageBox("Please enter a valid positive number.", "Error", 0)
    return
  end
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Get current edit cursor position
  local cursor_pos = reaper.GetCursorPosition()
  
  -- Get time signature at cursor position
  local retval, numerator, denominator = reaper.TimeMap_GetTimeSigAtTime(0, cursor_pos)
  
  -- Get tempo
  local tempo = reaper.Master_GetTempo()
  
  -- First, get the current measure and beat at cursor position
  local _, _, currentMeasure, currentBeat = reaper.TimeMap2_timeToBeats(0, cursor_pos)
  
  -- Go to next measure if we're not on the first beat
  local targetMeasure = currentMeasure
  if currentBeat > 0.01 then -- small threshold to account for floating point errors
    targetMeasure = currentMeasure + 1
  end
  
  -- Add markers at each measure start
  for i = 0, num_markers - 1 do
    -- Convert measure to time
    local markerMeasure = targetMeasure + i
    local markerPos = reaper.TimeMap2_beatsToTime(0, 0, markerMeasure)
    
    -- Add the marker
    local markerName = "Marker " .. (i + 1)
    local markerIndex = reaper.AddProjectMarker(0, false, markerPos, 0, markerName, -1)
    
    if markerIndex == -1 then
      reaper.ShowMessageBox("Failed to add marker #" .. (i + 1), "Error", 0)
    end
  end
  
  -- End undo block
  reaper.Undo_EndBlock("Add Markers on Downbeats", -1)
  
  -- Update the arrange view
  reaper.UpdateArrange()
end

-- Execute the script
main()