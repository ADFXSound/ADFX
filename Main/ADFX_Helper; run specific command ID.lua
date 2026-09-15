-- @description ADFX_Helper; run specific command ID
-- @version 1.0.0
-- @author ADFXSound

-- Run Command by ID Script for REAPER
-- This script allows you to execute a REAPER command using its command ID

-- Function to run a command by its ID
function RunCommandByID(command_id)
  if command_id then
    -- Convert string to number if necessary
    if type(command_id) == "string" then
      command_id = tonumber(command_id)
    end
    
    -- Check if the conversion was successful or if a valid number was provided
    if command_id then
      -- Main function to execute the command
      reaper.Main_OnCommand(command_id, 0) -- The second parameter 0 means to execute in the main section
      return true
    else
      reaper.ShowMessageBox("Invalid command ID. Please enter a valid number.", "Error", 0)
      return false
    end
  else
    reaper.ShowMessageBox("No command ID provided.", "Error", 0)
    return false
  end
end

-- Get command ID from user input or use a predefined value
function GetCommandID()
  -- Uncomment and modify the line below if you want to use a predefined command ID
  -- return 40044 -- Example: 40044 is "Track: Select all tracks"
  
  -- Or get command ID from user input
  local retval, user_input = reaper.GetUserInputs("Run Command by ID", 1, "Enter Command ID:", "")
  
  if retval then
    return user_input
  else
    return nil -- User canceled
  end
end

-- Main script execution
function main()
  -- Get command ID
  local command_id = GetCommandID()
  
  -- Run the command
  if command_id then
    local success = RunCommandByID(command_id)
    
    -- Optional: Show success message
    if success then
      -- Uncomment the line below if you want a confirmation message
      -- reaper.ShowMessageBox("Command " .. command_id .. " executed successfully.", "Success", 0)
    end
  end
  
  -- Clean up (usually not needed in REAPER scripts)
end

-- Run the script
main()