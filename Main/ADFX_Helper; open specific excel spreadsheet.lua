-- @description ADFX_Helper; open specific excel spreadsheet
-- @version 1.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; open specific excel spreadsheet
 * About: A quick way to open a relevant execl spreadsheet
 * Author: ADFX
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 6.63
 * Extensions: SWS/S&M 2.13.1.0
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2022-07-10)
	+ Initial Release
--]]

function OpenSpecificExcel()
  -- MODIFY THIS PATH to point to your specific Excel file
  local excel_file_path = "C:/users/Mr_Doctor_M1/AppData/Roaming/REAPER/Scripts/ADFXSound/Main/Media/UCS v8.2.1 Full List.xlsx"
  
  -- Open the Excel file with the system's default application
  local command
  
  -- Determine the operating system and construct the appropriate command
  if reaper.GetOS():match("^OSX") then
    -- macOS
    command = 'open "' .. excel_file_path .. '"'
  elseif reaper.GetOS():match("^Win") then
    -- Windows
    command = 'start "" "' .. excel_file_path .. '"'
  else
    -- Linux/Unix
    command = 'xdg-open "' .. excel_file_path .. '"'
  end
  
  -- Execute the command
  local success = os.execute(command)
  
  -- Report results
  if success then
    --reaper.ShowConsoleMsg("Opening Excel file: " .. excel_file_path .. "\n")
  else
    reaper.ShowConsoleMsg("Failed to open Excel file: " .. excel_file_path .. "\n")
    reaper.ShowConsoleMsg("Please check if the file exists and the path is correct.\n")
  end
end

-- Run the function
OpenSpecificExcel()