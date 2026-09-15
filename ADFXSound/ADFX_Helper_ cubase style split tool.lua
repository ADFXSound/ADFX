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


--[[
 * ReaScript Name: ADFX_Helper; cubase style split tool
 * About: This replicates the Cubase/Nuendo style split tool functionality.
 * Author: ADFX
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 6.63
 * Extensions: SWS/S&M 2.13.1.0
 * Version: 1.1
--]]

-- DEPENDENCY
dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
if not ultraschall and not ultraschall.IsReaperRendering then
  reaper.MB("Please install Ultrashall API, available via Reapack. Check online doc of the script for more infos.", "Error", 0)
  return
end

local isDelaying = false
local lastTime = 0

function Main()
  local mouseState = reaper.JS_Mouse_GetState(0x00000001)
  reaper.BR_GetMouseCursorContext()
  local pos = reaper.BR_GetMouseCursorContext_Position()
  if pos > -1 then
    reaper.SetEditCurPos2(0, pos, false, false)
  end
  
  local currentTime = reaper.time_precise()
  if mouseState == 1 and currentTime - lastTime >= 0.25 then  -- 250ms in seconds
    reaper.Main_OnCommand(2021, 0) -- Action: Toggle arm of next
    reaper.Main_OnCommand(40012, 0) -- Items: Split items at edit or play cursor
    lastTime = currentTime
  else
  end
  ultraschall.Defer((Main), "mydeferscript")
end

function Exit()
  local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
  reaper.SetToggleCommandState(sectionID, cmdID, 0)
  reaper.RefreshToolbar2(sectionID, cmdID)
end

local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)
reaper.atexit(Exit)
Main()
