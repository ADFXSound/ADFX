-- @description ADFX_Helper; script launcher
-- @version 1.0.0
-- @author ADFXSound

--[[
 * ReaScript Name: ADFX_Helper; script launcher
 * About: Collects all selected items and places them on a single track while preserving timestamps, and deletes empty source tracks
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2025-03-07)
  + Initial Release
--]]


-- Improved script path detection
local info = debug.getinfo(1,'S')
local script_path

-- Try to extract path from source
if info.source then
  script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
end

-- Fallback if path detection fails
if not script_path then
  script_path = reaper.GetResourcePath() .. "/Scripts/"
  reaper.ShowConsoleMsg("Warning: Could not detect script path, using default Scripts folder\n")
end

-- ===== CONFIGURATION - CUSTOMIZE THESE SETTINGS =====
-- Format for groups: 
-- {name = "Group Name", scripts = {
--   {display_name = "Button Label", file_name = "script_filename.lua", color = 0xRRGGBB} (color is optional)
-- }}
local script_groups = {
  -- Rendering group
  {
    name = "Rendering",
    scripts = {
      
    }
  },
  
  -- Item Management group
 {
    name = "Render",
    scripts = {
      {display_name = "ADFX_Helper; render selected items to new track.lua", file_name = "ADFX_Helper; render selected items to new track.lua"},
      {display_name = "ADFX_Helper; collect selected items to one track.lua", file_name = "ADFX_Helper; collect selected items to one track.lua"},
      {display_name = "ADFX_Helper; render selected items to new single track.lua", file_name = "ADFX_Helper; render selected items to new single track.lua"},
      {display_name = "ADFX_Helper; auto rms loudness matching multiple.lua", file_name = "ADFX_Helper; auto rms loudness matching multiple.lua"},
      {display_name = "ADFX_Helper; auto lufs loudness matching multiple.lua", file_name = "ADFX_Helper; auto lufs loudness matching multiple.lua"},
      
    }
  },
  
  -- Utilities group
  {
    name = "Utilities",
    scripts = {
      {display_name = "ADFX_Helper; copy name script multiple.lua", file_name = "ADFX_Helper; copy name script multiple.lua"},
      {display_name = "ADFX_Helper; copy name script multiple_BottomToTop.lua", file_name = "ADFX_Helper; copy name script multiple_BottomToTop.lua"},
      {display_name = "ADFX_Helper; sort selected items by length.lua", file_name = "ADFX_Helper; sort selected items by length.lua"},
      {display_name = "ADFX_Helper; create marker intervals and align selected items to them.lua", file_name = "ADFX_Helper; create marker intervals and align selected items to them.lua"},
      {display_name = "ADFX_Helper; auto align selected items to grid.lua", file_name = "ADFX_Helper; auto align selected items to grid.lua"},
      {display_name = "ADFX_Helper; auto align selected items to marker.lua", file_name = "ADFX_Helper; auto align selected items to marker.lua"},
      {display_name = "ADFX_Helper; align selected items from bottom track to top track.lua", file_name = "ADFX_Helper; align selected items from bottom track to top track.lua"},
      {display_name = "ADFX_Helper; trigger rate maker.lua", file_name = "ADFX_Helper; trigger rate maker.lua"},  
      {display_name = "ADFX_Helper; run loudness analysis tool.lua", file_name = "ADFX_Helper; run loudness analysis tool.lua"},
      {display_name = "ADFX_Helper; open UCS Reference.lua", file_name = "ADFX_Helper; open specific excel spreadsheet.lua"},
      {display_name = "ADFX_Helper; find all selected items by name and move to new track.lua", file_name = "ADFX_Helper; find all selected items by name and move to new track.lua"},
      {display_name = "ADFX_Helper; align selected items together.lua", file_name = "ADFX_Helper; align selected items together.lua"},
      {display_name = "ADFX_Helper; set item volume for selected items.lua", file_name = "ADFX_Helper; set item volume for selected items.lua"},
      {display_name = "ADFX_Helper; align selected items vertically.lua", file_name = "ADFX_Helper; align selected items vertically.lua"},
      {display_name = "ADFX_Helper; set item playback rate.lua", file_name = "ADFX_Helper; set item playback rate.lua"},
      {display_name = "ADFX_Helper; copy selected item name to clipboard.lua", file_name = "ADFX_Helper; copy selected item name to clipboard.lua"},
      {display_name = "ADFX_Helper; sort selected item by loudness.lua", file_name = "ADFX_Helper; sort selected item by loudness.lua"},
      {display_name = "ADFX_Helper; organize items by similar name.lua", file_name = "ADFX_Helper; organize items by similar name.lua"},
      {display_name = "ADFX_Helper; align item end to edit cursor.lua", file_name = "ADFX_Helper; align item end to edit cursor.lua"},
      {display_name = "ADFX_Helper; set loop points for selected items.lua", file_name = "ADFX_Helper; set loop points for selected items.lua"},
      {display_name = "ADFX_Helper; remove take markers from selected items.lua", file_name = "ADFX_Helper; remove take markers from selected items.lua"},
      {display_name = "ADFX_Helper; explode takes to tracks.lua", file_name = "ADFX_Helper; explode takes to tracks.lua"},
    }
  },
}

-- Button layout configuration
local config = {
  button_width = 400,     -- Width of buttons
  button_height = 30,     -- Height of buttons
  spacing = 8,            -- Spacing between buttons
  group_spacing = 2,     -- Extra spacing between groups
  columns = 1,            -- Number of columns for buttons
  window_title = "ADFXSound Script Launcher", -- Window title
  allow_external_paths = false, -- Set to true to allow absolute paths for scripts in other directories
  show_group_headers = true, -- Show group headers
}
-- ===================================================

-- Function to verify scripts exist
function VerifyScripts()
  local verified_groups = {}
  
  for g, group in ipairs(script_groups) do
    local verified_scripts = {}
    
    for i, script in ipairs(group.scripts) do
      local script_file
      
      if config.allow_external_paths and script.file_name:match("[\\/]") then
        -- This is an absolute path
        script_file = script.file_name
      else
        -- Path relative to this script
        -- Make sure script_path ends with a separator
        local path = script_path
        if path and not path:match("[\\/]$") then
          path = path .. "/"
        end
        script_file = path .. script.file_name
      end
      
      local file = io.open(script_file, "r")
      if file then
        file:close()
        script.path = script_file
        table.insert(verified_scripts, script)
      else
        reaper.ShowConsoleMsg("Warning: Script not found - " .. script.file_name .. "\n")
      end
    end
    
    if #verified_scripts > 0 then
      table.insert(verified_groups, {name = group.name, scripts = verified_scripts})
    end
  end
  
  return verified_groups
end

-- Function to run a script
function RunScript(script_path)
  dofile(script_path)
end

-- Function to check if ImGui context is valid
function IsContextValid(ctx)
  -- Check if the context pointer is still valid
  return ctx and reaper.ImGui_ValidatePtr and reaper.ImGui_ValidatePtr(ctx, 'ImGui_Context*')
end

-- Calculate total number of scripts and rows needed
local total_scripts = 0
local total_rows = 0

for g, group in ipairs(script_groups) do
  total_scripts = total_scripts + #group.scripts
  -- Each group needs rows for its scripts
  total_rows = total_rows + math.ceil(#group.scripts / config.columns)
  
  -- Add row for group header if enabled
  if config.show_group_headers then
    total_rows = total_rows + 1
  end
  
  -- Add row for group separator (except for the last group)
  if g < #script_groups then
    total_rows = total_rows + 1 -- Account for separator and spacing
  end
end

-- Calculate window size based on configuration and actual content
local window_width = config.button_width + (config.spacing * 2)
if config.columns > 1 then
  window_width = (config.button_width * config.columns) + (config.spacing * (config.columns + 1))
end

-- Improved height calculation that accounts for all elements
local window_height = (config.button_height * total_rows) + -- Button heights
                      (config.spacing * (total_rows + 1)) + -- Regular spacing between buttons
                      (config.group_spacing * (#script_groups - 1)) -- Extra spacing for group separators

-- Check for required extensions
local gfx = reaper.ImGui_CreateContext and reaper.ImGui_CreateContext('Script Launcher') or reaper.JS_GFX

if not gfx then
  reaper.ShowMessageBox("This script requires either ReaImGui or js_ReaScriptAPI extension. Please install via ReaPack.", "Error", 0)
  return
end

local using_imgui = reaper.ImGui_CreateContext ~= nil

if using_imgui then
  -- ImGui implementation
  local ctx = gfx
  local WINDOW_FLAGS = reaper.ImGui_WindowFlags_NoCollapse()
  
  local verified_groups = VerifyScripts()
  
  function loop()
    -- Check if context is still valid before using it
    if not IsContextValid(ctx) then
      return -- Exit the loop if context is no longer valid
    end
    
    local visible, open = reaper.ImGui_Begin(ctx, config.window_title, true, WINDOW_FLAGS)
    if visible then
      
      -- Set window size
      reaper.ImGui_SetWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_FirstUseEver())
      
      if #verified_groups == 0 then
        reaper.ImGui_Text(ctx, "No scripts found. Please check your configuration.")
      else
        -- Display each group of scripts
        for g, group in ipairs(verified_groups) do
          -- Group header
          if config.show_group_headers then
            -- Use text color to make headers stand out
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFFFF)
            reaper.ImGui_Text(ctx, "--- " .. group.name .. " ---")
            reaper.ImGui_PopStyleColor(ctx)
            reaper.ImGui_Spacing(ctx)
          end
          
          -- Display scripts as buttons in columns
          if reaper.ImGui_BeginTable(ctx, "ScriptTable_" .. g, config.columns) then
            local index = 0
            
            for i, script in ipairs(group.scripts) do
              if index % config.columns == 0 then
                reaper.ImGui_TableNextRow(ctx)
              end
              
              reaper.ImGui_TableNextColumn(ctx)
              
              -- Set button color if specified
              if script.color then
                local r = (script.color >> 16) & 0xFF
                local g = (script.color >> 8) & 0xFF
                local b = script.color & 0xFF
                -- Convert RGB to packed color format for ImGui
                local packed_color = reaper.ImGui_ColorConvertDouble4ToU32(r/255, g/255, b/255, 1.0)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), packed_color)
              end
              
              if reaper.ImGui_Button(ctx, script.display_name, config.button_width, config.button_height) then
                reaper.defer(function() RunScript(script.path) end)
              end
              
              if script.color then
                reaper.ImGui_PopStyleColor(ctx)
              end
              
              index = index + 1
            end
            
            reaper.ImGui_EndTable(ctx)
          end
          
          -- Add space between groups (except for the last group)
          if g < #verified_groups then
            reaper.ImGui_Dummy(ctx, 0, config.group_spacing)
            reaper.ImGui_Separator(ctx)
            reaper.ImGui_Spacing(ctx)
            reaper.ImGui_Dummy(ctx, 0, config.group_spacing / 2)
          end
        end
      end
      
      reaper.ImGui_End(ctx)
    end
    
    if open and IsContextValid(ctx) then
      reaper.defer(loop)
    else
      -- Safely check if the context and function exist before destroying
      if IsContextValid(ctx) and reaper.ImGui_DestroyContext then
        reaper.ImGui_DestroyContext(ctx)
      end
    end
  end
  
  -- Add a cleanup function to handle script termination
  function cleanup()
    if IsContextValid(ctx) and reaper.ImGui_DestroyContext then
      reaper.ImGui_DestroyContext(ctx)
    end
  end
  
  reaper.atexit(cleanup)
  reaper.defer(loop)
else
  -- JS_ReaScriptAPI implementation
  local window = reaper.JS_Window_Create(
    config.window_title, 
    window_width, 
    window_height, 
    false
  )
  
  if not window then
    reaper.ShowMessageBox("Could not create window.", "Error", 0)
    return
  end
  
  -- Verify scripts exist
  local verified_groups = VerifyScripts()
  
  -- Set up layout
  local x_pos, y_pos = config.spacing, config.spacing
  
  -- Create a label
  reaper.JS_Window_AddLabel(window, x_pos, y_pos, window_width - config.spacing*2, 20, config.window_title)
  y_pos = y_pos + 30
  
  -- Create buttons for each group
  for g, group in ipairs(verified_groups) do
    -- Group header
    if config.show_group_headers then
      reaper.JS_Window_AddLabel(window, x_pos, y_pos, window_width - config.spacing*2, 20, group.name)
      y_pos = y_pos + 25
    end
    
    -- Create buttons for scripts in this group
    for i, script in ipairs(group.scripts) do
      local col = (i-1) % config.columns
      local row = math.floor((i-1) / config.columns)
      
      x_pos = config.spacing + col * (config.button_width + config.spacing)
      local button_y = y_pos + row * (config.button_height + config.spacing)
      
      local button = reaper.JS_Window_AddButton(window, x_pos, button_y, config.button_width, config.button_height, script.display_name)
      
      -- Set up button callback
      local function buttonCallback()
        RunScript(script.path)
      end
      
      reaper.JS_WindowMessage_Send(window, "WM_COMMAND", reaper.JS_WindowMessage_Post(window, "WM_COMMAND", button, 0), 0)
      reaper.JS_Window_OnCommand(window, button, buttonCallback)
    end
    
    -- Update y_pos for the next group
    local rows_in_group = math.ceil(#group.scripts / config.columns)
    y_pos = y_pos + rows_in_group * (config.button_height + config.spacing)
    
    -- Add space between groups
    if g < #verified_groups then
      y_pos = y_pos + config.group_spacing
      
      -- Add a separator line
      local separator = reaper.JS_GDI_CreatePen(1, 1, 0x808080)
      local gdi = reaper.JS_GDI_GetWindowDC(window)
      reaper.JS_GDI_Line(gdi, config.spacing, y_pos - config.group_spacing/2, window_width - config.spacing, y_pos - config.group_spacing/2, separator)
      reaper.JS_GDI_ReleaseDC(window, gdi)
      reaper.JS_GDI_DeleteObject(separator)
    end
  end
  
  -- Show window
  reaper.JS_Window_Show(window, "SHOW")
  
  -- Clean up when REAPER closes
  function exit()
    reaper.JS_Window_Destroy(window)
  end
  
  reaper.atexit(exit)
end
