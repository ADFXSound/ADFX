-- @description ADFX_Helper; open specific website
-- @version 2.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; open specific website
 * About: Opens a specified website URL in the default browser
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


-- Change this URL to whatever website you want to open
local url = "https://www.dropbox.com/scl/fo/lw1i20cgsm4edsvj3awn1/AP_ZhzG3LlpfFLbX309FbOU?e=1&preview=UCS+v8.2.1+Full+List.xlsx&rlkey=wa2onzo0difpew1nze6odztlp&dl=0"

-- Function to determine OS and open URL with appropriate command
function openURL(url)
  local osName = reaper.GetOS()
  
  if osName:match("^OSX") then
    -- macOS
    os.execute('open "' .. url .. '"')
  elseif osName:match("^Win") then
    -- Windows
    os.execute('start "" "' .. url .. '"')
  else
    -- Linux and other Unix-like systems
    os.execute('xdg-open "' .. url .. '"')
  end
end

-- Main function
function main()
  openURL(url)
end

-- Run the script
main()