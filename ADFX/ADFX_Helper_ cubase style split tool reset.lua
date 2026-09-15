--[[
 * ReaScript Name: ADFX_Helper; cubase style split tool
 * About: This replicates the Cubase/Nuendo style split tool functionality. There is a Counter part script (cubase style split tool reset) which nulls this defer loop are returns the mouse to normal behaviors. Likewise can also re-run this using the terminate instance option to kill the process.
 * Author: ADFX
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.1
--]]

--[[
 * Changelog:
 * v1.1 (2025-02-18)
  + Fix to prevent Spam clicks with 250 ms cooldown
--]]

--[[
 * Changelog:
 * v1.0 (2022-07-10)
  + Initial Release
--]]

--[[
*NOTE: This script will interact with script "ADFX_Helper; cubase style split tool reset" - which will stop this script from running. As to replicate the default Cubase / Nuendo keyboard shortcuts 1 and 3, respectively.
 --]]


-- DEPENDENCY
dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

if not ultraschall and not ultraschall.IsReaperRendering then
  reaper.MB("Please install Ultrashall API, available via Reapack. Check online doc of the script for more infos.", "Error", 0)
  return
end

function Main()
  ultraschall.StopDeferCycle("mydeferscript")
 
end

Main()