
-- Add FabFilter Pro-Q4 to Selected Track in REAPER
-- This script adds the FabFilter Pro-Q4 plugin to the currently selected track in REAPER
-- 1. Save this file as "add_proq4.lua" in your REAPER Scripts folder
-- 2. Open REAPER and assign this script to a keyboard shortcut or toolbar button

-- Main function
function main()
  -- Check if a track is selected
  local track = reaper.GetSelectedTrack(0, 0)
  if not track then
    reaper.ShowMessageBox("Please select a track first!", "No Track Selected", 0)
    return
  end
  
  -- Set specific plugin
  local plugin = "VST3: Pro-Q 4 (FabFilter)" 
  
  -- Add plugin to track
  local fx_index = reaper.TrackFX_AddByName(track, plugin, false, -1)
  
  if fx_index == -1 then
    reaper.ShowMessageBox("Plugin '" .. plugin .. "' not found!\n\nMake sure FabFilter Pro-Q4 is installed and properly scanned by REAPER.", "Error", 0)
    return
  end
  
  -- Make the plugin window visible
  reaper.TrackFX_Show(track, fx_index, 3)
  
  -- Update the track control panel
  reaper.UpdateArrange()
  
end

-- Execute the script
main()