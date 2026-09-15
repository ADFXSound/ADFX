-- @description ADFX_Helper; run loudness analysis tool
-- @version 1.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; run loudness analysis tool
 * About: This script opens the SWS/BR loudness analysis dialog
 * Author: ADFX
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.13.1.0
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2025-03-05)
  + Initial Release
--]]

-- Main script execution
function main()
  -- Get command ID for _BR_ANALAYZE_LOUDNESS_DLG
  local command_id = reaper.NamedCommandLookup("_BR_ANALAYZE_LOUDNESS_DLG")
  
  -- Check if the command exists
  if command_id == 0 then
    reaper.ShowMessageBox("Command _BR_ANALAYZE_LOUDNESS_DLG not found. Make sure you have SWS Extensions installed.", "Error", 0)
    return
  end
  
  -- Execute the command
  reaper.Main_OnCommand(command_id, 0) -- The second parameter 0 means to execute in the main section
end

-- Run the script
main()