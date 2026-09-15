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

function ShowImGuiMessageBox(message, title)
  -- Create ImGui context for error message
  local ctx = reaper.ImGui_CreateContext and reaper.ImGui_CreateContext('ADFX Message')
  
  if not ctx then
    -- Fallback to standard message box if ImGui not available
    reaper.ShowMessageBox(message, title, 0)
    return
  end
  
  -- Attach fonts
  local font = reaper.ImGui_CreateFont('sans-serif', 18)
  reaper.ImGui_Attach(ctx, font)
  
  local window_open = true
  
  function error_loop()
    -- Use fixed position and size for simplicity
    local window_width, window_height = 200, 120
    
    -- Set window position to center of screen (approximate)
    -- Use a fixed position that should work on most screens
    reaper.ImGui_SetNextWindowPos(ctx, 400, 300, reaper.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Always())
    
    local WINDOW_FLAGS = reaper.ImGui_WindowFlags_NoCollapse() | 
                         reaper.ImGui_WindowFlags_NoResize() |
                         reaper.ImGui_WindowFlags_AlwaysAutoResize()
    
    local visible, open = reaper.ImGui_Begin(ctx, title, true, WINDOW_FLAGS)
    
    if visible then
      reaper.ImGui_PushFont(ctx, font)
      
      -- Add spacing to center content vertically
      reaper.ImGui_Spacing(ctx)
      reaper.ImGui_Spacing(ctx)
      
      -- Display the message
      reaper.ImGui_Text(ctx, message)
      
      reaper.ImGui_Spacing(ctx)
      reaper.ImGui_Spacing(ctx)
      
      -- OK button
      if reaper.ImGui_Button(ctx, "OK", 100, 30) then
        window_open = false
      end
      
      -- Also close on Enter or Escape
      if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) or 
         reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
        window_open = false
      end
      
      reaper.ImGui_PopFont(ctx)
      reaper.ImGui_End(ctx)
    end
    
    if open and window_open then
      reaper.defer(error_loop)
    else
      if reaper.ImGui_DestroyContext then
        reaper.ImGui_DestroyContext(ctx)
      end
    end
  end
  
  reaper.defer(error_loop)
end

function main()
  -- Prompt for number of markers to add
  local retval, num_markers = reaper.GetUserInputs("Add Markers on Downbeats", 1, "Number of markers to add:,extrawidth=100", "8")
  
  -- Exit if user canceled
  if not retval then return end
  
  -- Convert input to number
  num_markers = tonumber(num_markers)
  
  -- Validate input
  if not num_markers or num_markers <= 0 then
    ShowImGuiMessageBox("Please enter a valid positive number.", "Error")
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
      ShowImGuiMessageBox("Failed to add marker #" .. (i + 1), "Error")
    end
  end
  
  -- End undo block
  reaper.Undo_EndBlock("Add Markers on Downbeats", -1)
  
  -- Update the arrange view
  reaper.UpdateArrange()
end

-- Execute the script
main()