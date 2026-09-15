-- @description ADFX_Helper; lufs loudness analysis
-- @version 2.0.0
-- @author ADFXSound

function Main()
  local item_count = reaper.CountSelectedMediaItems(0)
  
  if item_count == 0 then
    reaper.ShowMessageBox("Please select at least one item to analyze.", "LUFS Analyzer", 0)
    return
  end
  
  -- Check for SWS Extensions
  local has_sws = reaper.APIExists("CF_GetSWSVersion")
  if not has_sws then
    reaper.ShowMessageBox("This script works best with SWS Extensions.\nSome features may not work correctly without it.", "LUFS Analyzer", 0)
  end
  
  -- Check for various analyze commands that might exist in different SWS versions
  local analyze_cmd_id = 0
  local possible_commands = {
    "_SWS_ANALYZELONG0",
    "_SWS_ANALYZEITEM1",
    "_SWS_ANALYZELOUD",
    "_SWS_ANALYZEITEMS",
    "_RS1c8b02e4f2c275d6ad19b83a8cb8131801c053f1", -- Some installations use cryptic IDs
    "_RSba23046f21aebaf3b67a44d56797469390f82cbe",
    "_XENAKIOS_ANALYZEITEMS"  -- Older SWS versions
  }
  
  -- Try to find an available loudness analysis command
  for _, cmd_name in ipairs(possible_commands) do
    local cmd = reaper.NamedCommandLookup(cmd_name)
    if cmd ~= 0 then
      analyze_cmd_id = cmd
      break
    end
  end
  
  -- If none found, try to use direct menu command IDs
  if analyze_cmd_id == 0 then
    -- Try native REAPER loudness analysis if available (4.6+ feature)
    analyze_cmd_id = reaper.NamedCommandLookup("_RS7d3c_RENDER_LOUDNESSSTATISTICS")
    if analyze_cmd_id == 0 then
      -- Try direct ID - "Item properties: Loudness analysis" action
      analyze_cmd_id = 40855
    end
  end
  
  -- Check if we found any valid command
  if analyze_cmd_id == 0 then
    -- Manual instructions if no command found
    reaper.ShowMessageBox(
      "Could not find any loudness analysis command.\n\n" ..
      "To analyze loudness manually:\n" ..
      "1. Right-click on the item\n" ..
      "2. Select 'Item properties' or 'Analyze'\n" ..
      "3. Choose 'Loudness analysis'", 
      "LUFS Analyzer", 0)
    return
  end
  
  -- Create result string
  local result_str = "LUFS Loudness Analysis Results:\n\n"
  
  -- Store initial selection
  local initial_items = {}
  for i = 0, item_count - 1 do
    initial_items[i] = reaper.GetSelectedMediaItem(0, i)
  end
  
  -- Analyze each selected item individually
  for i = 0, item_count - 1 do
    local item = initial_items[i]
    local take = reaper.GetActiveTake(item)
    local take_name = take and reaper.GetTakeName(take) or "Unnamed Take"
    
    -- Get item position
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local pos_str = reaper.format_timestr(item_pos, "")
    
    -- Add item header to result
    result_str = result_str .. "Item " .. (i+1) .. ": " .. take_name .. " (at " .. pos_str .. ")\n"
    
    -- Clear all selections and select just this item
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.SetMediaItemSelected(item, true)
    
    -- Run the analyze command
    reaper.Main_OnCommand(analyze_cmd_id, 0)
    
    -- Give time for analysis to complete
    local time_start = reaper.time_precise()
    local timeout = 3 -- 3 seconds timeout
    local result_found = false
    
    -- Wait for results with timeout
    while not result_found and (reaper.time_precise() - time_start < timeout) do
      -- Check potential project state keys where the results might be stored
      local possible_keys = {
        {"ANALYZE_LOUDNESS", "LAST_RESULTS"},
        {"ANALAYZE_LOUDNESS", "LAST_RESULTS"}, -- Typo in some versions
        {"SWS", "AnalyzeLoudness"},
        {"LOUDNESS_ANALYZER", "LAST_RESULT"}
      }
      
      for _, key_pair in ipairs(possible_keys) do
        local section, key = key_pair[1], key_pair[2]
        local retval, str = reaper.GetProjExtState(0, section, key)
        
        if retval == 1 and str ~= "" then
          -- Add the raw result string to our output
          result_str = result_str .. "  " .. str .. "\n"
          result_found = true
          break
        end
      end
      
      -- Small pause to prevent CPU usage spike
      reaper.defer(function() end)
    end
    
    if not result_found then
      result_str = result_str .. "  Analysis completed, but couldn't retrieve results automatically.\n"
      result_str = result_str .. "  Please check the analysis window or console for results.\n"
    end
    
    result_str = result_str .. "\n"
  end
  
  -- Restore original selection
  reaper.Main_OnCommand(40289, 0) -- Unselect all items
  for i = 0, item_count - 1 do
    reaper.SetMediaItemSelected(initial_items[i], true)
  end
  
  -- Show results in a prompt
  local title = "LUFS Loudness Analysis"
  local ret_val, user_input = reaper.GetUserInputs(title, 1, "Results (read-only),extrawidth=600", result_str)
end

-- Execute the main function
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("LUFS Loudness Analysis", -1)