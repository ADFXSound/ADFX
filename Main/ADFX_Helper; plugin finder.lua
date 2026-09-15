-- @description ADFX_Helper; plugin finder
-- @version 1.0.0
-- @author ADFXSound

-- Try Common Pro-Q4 Plugin Names
-- This script tries various common naming patterns for Pro-Q4
-- Save this as "try_proq4_names.lua" in your REAPER Scripts folder

function main()
  -- Check if a track is selected
  local track = reaper.GetSelectedTrack(0, 0)
  if not track then
    reaper.ShowMessageBox("Please select a track first!", "No Track Selected", 0)
    return
  end
  
  -- Common naming patterns for plugins
  local possible_names = {
    "VST3: Pro-Q 4 (FabFilter)",
    "VST3: FabFilter Pro-Q 4",
    "VST3: Pro-Q4 (FabFilter)",
    "VST3: FabFilter Pro-Q4",
    "VST: Pro-Q 4 (FabFilter)",
    "VST: FabFilter Pro-Q 4",
    "VST: Pro-Q4 (FabFilter)",
    "VST: FabFilter Pro-Q4",
    "AU: Pro-Q 4 (FabFilter)",
    "AU: FabFilter Pro-Q 4",
    "AU: Pro-Q4 (FabFilter)",
    "AU: FabFilter Pro-Q4",
    "Pro-Q 4",
    "Pro-Q4",
    "FabFilter Pro-Q 4",
    "FabFilter Pro-Q4"
  }
  
  -- Try each name
  local success = false
  local used_name = ""
  
  reaper.ShowConsoleMsg("Trying to add Pro-Q4 using common naming patterns...\n")
  
  for _, name in ipairs(possible_names) do
    reaper.ShowConsoleMsg("Trying: " .. name .. "\n")
    
    local fx_index = reaper.TrackFX_AddByName(track, name, false, -1)
    
    if fx_index ~= -1 then
      success = true
      used_name = name
      
      -- Make the plugin window visible
      reaper.TrackFX_Show(track, fx_index, 3)
      
      reaper.ShowConsoleMsg("SUCCESS! Added using name: " .. name .. "\n")
      break
    end
  end
  
  -- Report results
  if success then
    local msg = "Successfully added Pro-Q4 using name:\n\n" .. used_name .. 
                "\n\nYou can use this name in your shortcut script."
    reaper.ShowMessageBox(msg, "Success", 0)
  else
    local msg = "Could not add Pro-Q4 using common naming patterns.\n\n" ..
                "Please use the manual method:\n" ..
                "1. Right-click on the track's FX button\n" ..
                "2. Locate Pro-Q4 in the menu\n" ..
                "3. Take note of the exact name as shown"
    reaper.ShowMessageBox(msg, "Plugin Not Found", 0)
  end
end

main()