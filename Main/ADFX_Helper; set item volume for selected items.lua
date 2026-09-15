-- @description ADFX_Helper; set item volume for selected items
-- @version 2.0.0
-- @author ADFXSound

-- Set Item Volume with Dialog Window
-- This script opens a dialog to input dB value and applies it to selected items

-- Function to convert dB to linear volume
function dBToLinear(dB)
    return 10^(dB/20)
end

-- Function to convert linear volume to dB
function linearTodB(linear)
    if linear <= 0 then
        return -150 -- Minimum dB value
    end
    return 20 * math.log(linear) / math.log(10)
end

-- Main function
function main()
    -- Check if there are selected items
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    
    if numSelectedItems == 0 then
        reaper.ShowMessageBox("No items selected. Please select one or more items.", "Error", 0)
        return
    end
    
    -- Get current volume of first selected item for default value
    local firstItem = reaper.GetSelectedMediaItem(0, 0)
    local currentVolume = reaper.GetMediaItemInfo_Value(firstItem, "D_VOL")
    local currentdB = linearTodB(currentVolume)
    
    -- Show input dialog
    local retval, userInput = reaper.GetUserInputs(
        "Set Item Volume", 
        1, 
        "Volume (dB):", 
        string.format("%.2f", currentdB)
    )
    
    -- Check if user cancelled or input is empty
    if not retval or userInput == "" then
        return
    end
    
    -- Convert input to number
    local targetdB = tonumber(userInput)
    
    -- Validate input
    if not targetdB then
        reaper.ShowMessageBox("Invalid input. Please enter a valid number.", "Error", 0)
        return
    end
    
    -- Clamp dB value to reasonable range (-150 to +12 dB)
    if targetdB < -150 then
        targetdB = -150
    elseif targetdB > 12 then
        targetdB = 12
        reaper.ShowMessageBox("Volume clamped to +12 dB for safety.", "Warning", 0)
    end
    
    -- Convert dB to linear volume
    local targetVolume = dBToLinear(targetdB)
    
    -- Begin undo block
    reaper.Undo_BeginBlock()
    
    -- Apply volume to all selected items
    for i = 0, numSelectedItems - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemInfo_Value(item, "D_VOL", targetVolume)
    end
    
    -- Update arrangement and end undo block
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Set item volume to " .. string.format("%.2f", targetdB) .. " dB", -1)
    

end

-- Run the main function
main()