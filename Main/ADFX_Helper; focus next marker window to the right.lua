-- Close the "Edit Marker" window if it's open
local edit_marker_window = reaper.JS_Window_Find("Edit Marker", true)
if edit_marker_window then
    reaper.JS_Window_Close(edit_marker_window)
end

-- Get the current cursor position
local cursor_pos = reaper.GetCursorPosition()

-- Initialize variables to find the next marker
local next_marker_pos = math.huge
local found_marker = false

-- Loop through all markers to find the next one to the right of the cursor
local num_markers = reaper.CountProjectMarkers(0)
for i = 0, num_markers - 1 do
    local retval, is_region, pos, _, _, _ = reaper.EnumProjectMarkers(i)
    if not is_region and pos > cursor_pos and pos < next_marker_pos then
        next_marker_pos = pos
        found_marker = true
    end
end

-- If a marker is found, move the cursor to it and open the "Edit Marker" window
if found_marker then
    reaper.SetEditCurPos(next_marker_pos, true, false) -- Move cursor to the next marker
    reaper.Main_OnCommand(40613, 0) -- Open the "Edit Marker" window (Action ID for "Markers: Edit marker near cursor")
else
    reaper.ShowMessageBox("No marker to the right of the cursor found.", "No Marker", 0) -- Notify if no marker is found
end