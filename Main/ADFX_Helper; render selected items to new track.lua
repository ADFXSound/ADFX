-- @description ADFX_Helper; render selected items to new track
-- @version 2.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; render selected items to new track
 * About: -- Processes each selected item one by one with:
          -- 1. Set loop points for each item individually
          -- 2. Render each item to a new track
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.1
--]]

--[[
 * Changelog:
 * v1.1 (2025-03-18)
  + Added confirmation dialog for large selections
  + Added ability to cancel processing
 * v1.0 (2025-03-07)
  + Initial Release
--]]

function Main()
  -- Check if the project has ever been saved (has a filename)
  local proj_name = reaper.GetProjectName(0, "")
  if proj_name == "" then
    reaper.MB("Please save the session before running this script.\n\nThis script processes multiple items and it's required to save your project first.", "Save Required", 0)
    return
  end
  
  -- Store all selected items in a table
  local count = reaper.CountSelectedMediaItems(0)
  if count == 0 then return end
  
  -- Add confirmation dialog for large selections
  local THRESHOLD = 10 -- Adjust this threshold as needed
  if count > THRESHOLD then
    local confirm = reaper.MB("You're about to process " .. count .. " items. This could take some time.\n\nContinue?", "ADFX_Helper Confirmation", 1)
    if confirm ~= 1 then
      reaper.ShowConsoleMsg("\nOperation cancelled by user.\n")
      return
    end
  end
  
  local items = {}
  for i = 0, count-1 do
    items[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
  
  -- Table to store original track information
  local original_tracks = {}
  
  -- Remember original selection and time selection
  local orig_start_time, orig_end_time = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  local orig_repeat_state = reaper.GetToggleCommandState(1068) -- Get repeat state
  
  -- Add a cancel flag
  local cancelled = false
  
  -- Create a progress dialog
  local title = "ADFX_Helper Progress"
  local msg = "Processing item 1 of " .. count
  reaper.ClearConsole()
  
  -- Process each item one by one
  for i = 1, #items do
    -- Update progress message
    msg = "Processing item " .. i .. " of " .. count .. "\n\nPress Escape to cancel"
    reaper.ShowConsoleMsg("\n" .. msg)
    
    -- Check for ESC key press (user cancellation)
    if reaper.HasExtState("ADFX_Helper", "cancel") == "1" or reaper.JS_Window_FromPoint(0, 0) == nil then
      cancelled = true
      reaper.ShowConsoleMsg("\n\nOperation cancelled by user.\n")
      break
    end
    
    -- Set an ExtState that script is running
    reaper.SetExtState("ADFX_Helper", "running", "1", false)
    
    local item = items[i]
    local track = reaper.GetMediaItemTrack(item)
    
    -- Store the original track for this item
    original_tracks[i] = track
    
    -- Deselect all items and tracks
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    
    -- Select only current item
    reaper.SetMediaItemSelected(item, true)
    
    -- Also select its parent track to ensure rendering from the correct source
    reaper.SetTrackSelected(track, true)
    reaper.UpdateArrange()
    
    -- Get position and length of the current item
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local end_pos = pos + len
    
    -- Clear any existing time selection
    reaper.Main_OnCommand(40635, 0) -- Remove time selection
    
    -- Set time selection and loop points to only this item
    reaper.GetSet_LoopTimeRange(1, 0, pos, end_pos, 0)
    reaper.GetSet_LoopTimeRange(1, 1, pos, end_pos, 0)
    
    -- Make sure we're at the start of the item
    reaper.SetEditCurPos(pos, false, false)
    
    -- Make sure repeat is enabled
    if reaper.GetToggleCommandState(1068) == 0 then
      reaper.Main_OnCommand(1068, 0) -- Enable repeat
    end
    
    -- Run ADFX_Helper script for the current item
    -- Try running by exact script name
    if reaper.APIExists("ReaScript_GetFunctionByName") then
      local func = reaper.ReaScript_GetFunctionByName("ADFX_Helper; Set loops points for selected item.lua")
      if func then reaper.JS_Callback_Execute(func) end
    else
      -- Fallback to command ID if available
      local cmd_id = reaper.NamedCommandLookup("_ADFX_Helper; Set loops points for selected item")
      if cmd_id ~= 0 then
        reaper.Main_OnCommand(cmd_id, 0)
      end
    end
    
    -- Ensure time selection is still correct
    reaper.GetSet_LoopTimeRange(1, 0, pos, end_pos, 0)
    
    -- Sleep briefly to ensure settings are applied
    reaper.defer(function() end)
    
    -- Now render with SWS
    local render_cmd_id = reaper.NamedCommandLookup("_SWS_AWRENDERSTEREOSMART")
    if render_cmd_id ~= 0 then
      reaper.Main_OnCommand(render_cmd_id, 0)
    end
    
    -- Sleep to allow render to complete
    local start_time = reaper.time_precise()
    local function wait_for_completion()
      if reaper.time_precise() - start_time < 0.1 then -- 100ms delay
        reaper.defer(wait_for_completion)
      end
    end
    reaper.defer(wait_for_completion)
    
    -- Important: Deselect any tracks that might have been selected during rendering
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    
    -- Re-select the item to ensure we're working with the right item for the next iteration
    reaper.SetMediaItemSelected(item, true)
    reaper.UpdateArrange()
    
    -- Check for cancellation again after processing this item
    if reaper.HasExtState("ADFX_Helper", "cancel") == "1" then
      cancelled = true
      reaper.ShowConsoleMsg("\n\nOperation cancelled after processing item " .. i .. ".\n")
      break
    end
  end
  
  -- Clear the running state
  reaper.DeleteExtState("ADFX_Helper", "running", false)
  reaper.DeleteExtState("ADFX_Helper", "cancel", false)
  
  -- Restore original time selection and repeat state
  reaper.GetSet_LoopTimeRange(1, 0, orig_start_time, orig_end_time, 0)
  reaper.GetSet_LoopTimeRange(1, 1, orig_start_time, orig_end_time, 0)
  
  -- Restore original repeat state
  if orig_repeat_state == 0 and reaper.GetToggleCommandState(1068) == 1 then
    reaper.Main_OnCommand(1068, 0) -- Toggle repeat off
  elseif orig_repeat_state == 1 and reaper.GetToggleCommandState(1068) == 0 then
    reaper.Main_OnCommand(1068, 0) -- Toggle repeat on
  end
  
  -- Reselect all original items and their original tracks
  reaper.Main_OnCommand(40289, 0) -- Unselect all items
  reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
  
  for i = 1, #items do
    local item = items[i]
    reaper.SetMediaItemSelected(item, true)
  end
  
  reaper.UpdateArrange()
  
  if cancelled then
    reaper.ShowConsoleMsg("\nProcessing was cancelled. Items processed: " .. (i-1) .. " of " .. count .. "\n")
  else
    reaper.ShowConsoleMsg("\nProcessing complete. All " .. count .. " items processed.\n")
  end
end

-- Add key listener function to detect ESC key
function listenForEscKey()
  local function checkKeys()
    local hwnd = reaper.GetMainHwnd()
    if reaper.JS_Window_GetForeground() == hwnd then
      if reaper.JS_Window_GetTitle(hwnd):find("REAPER") then
        if reaper.HasExtState("ADFX_Helper", "running") == "1" then
          -- Check for ESC key
          local is_esc = reaper.JS_VKeys_GetState(0) 
          if is_esc:byte(0x1B) ~= 0 then
            reaper.SetExtState("ADFX_Helper", "cancel", "1", false)
            return
          end
        else
          return
        end
      end
    end
    reaper.defer(checkKeys)
  end
  
  if reaper.APIExists("JS_VKeys_GetState") then
    checkKeys()
  end
end

-- Execute the script
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

-- Start ESC key listener if JS API is available
if reaper.APIExists("JS_Window_FromPoint") and reaper.APIExists("JS_VKeys_GetState") then
  listenForEscKey()
end

Main()

reaper.Undo_EndBlock("Process Multiple Selected Items", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()