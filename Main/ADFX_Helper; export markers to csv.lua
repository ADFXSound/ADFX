--[[
 * ReaScript Name: ADFX_Helper; export markers to csv
 * About: Export session markers to a CSV file with timestamp and name, saved one directory up from the project folder, and named after the session.
 * Author URI: adfxsound.com
 * Repository URI: https://raw.githubusercontent.com/ADearing01/ADFXSound/master/index.xml
 * REAPER: 7.34
 * Extensions: SWS/S&M 2.14.0.3
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2025-03-05)
  + Initial Release
--]]

function main()
    -- Get the number of markers
    local num_markers = reaper.CountProjectMarkers(0)
    
    if num_markers == 0 then
        reaper.ShowMessageBox("No markers found in the project.", "Export Markers", 0)
        return
    end
    
    -- Get the project directory
    local project_path = reaper.GetProjectPath("")
    
    -- Navigate one directory up
    local parent_directory = project_path:match("(.*[\\/])") -- Extract the parent directory path
    
    if not parent_directory then
        reaper.ShowMessageBox("Could not determine the parent directory.", "Error", 0)
        return
    end
    
    -- Get the session name (without extension)
    local session_name = reaper.GetProjectName(0, "")
    session_name = session_name:gsub("%.rpp$", "") -- Remove the .rpp extension if present
    
    if session_name == "" then
        session_name = "Untitled" -- Default name if the session is untitled
    end
    
    -- Define the filename and path
    local csv_filename = parent_directory .. session_name .. "_markers.csv" -- Save in the parent directory
    
    -- Open the file for writing
    local file = io.open(csv_filename, "w")
    
    if not file then
        reaper.ShowMessageBox("Could not create the file.", "Error", 0)
        return
    end
    
    -- Write the header
    file:write("Timestamp,Marker Name\n")
    
    -- Loop through all markers and write them to the file
    for i = 0, num_markers - 1 do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        
        if not isrgn then -- Only process markers, not regions
            -- Convert the position (in seconds) to a timestamp string
            local timestamp = reaper.format_timestr_pos(pos, "", 0)
            
            -- Write the timestamp and marker name to the file
            file:write(string.format("%s,%s\n", timestamp, name))
        end
    end
    
    -- Close the file
    file:close()
    
    reaper.ShowMessageBox("Markers exported successfully to:\n" .. csv_filename, "Export Complete", 0)
end

-- Run the script
main()