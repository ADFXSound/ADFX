-- Minimal Send to Pro Tools Script
-- This script exports selected items as WAV files for Pro Tools

-- Default settings
local settings = {
  exportFormat = "WAV",
  sampleRate = 48000,
  bitDepth = 24,
  createFolder = true
}

-- Function to show a dialog for export folder selection
function ChooseExportFolder()
  local defaultPath = reaper.GetProjectPath("")
  local retval, folderPath = reaper.GetUserFileNameForRead(defaultPath, "Choose export folder", "")
  
  if not retval then return nil end
  return folderPath
end

-- Function to export items as WAV files
function ExportSelectedItems(exportFolder)
  local itemCount = reaper.CountSelectedMediaItems(0)
  
  if itemCount == 0 then
    reaper.ShowMessageBox("No items selected. Please select items to export.", "Export Error", 0)
    return false
  end
  
  -- Create export folder
  local timestamp = os.date("%Y%m%d_%H%M%S")
  local exportPath = exportFolder .. "/ProToolsExport_" .. timestamp
  
  if settings.createFolder then
    reaper.RecursiveCreateDirectory(exportPath, 0)
  else
    exportPath = exportFolder
  end
  
  local exportedFiles = {}
  
  -- Remember current time selection
  local timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local isTimeSelEnabled = reaper.GetToggleCommandState(40290) == 1 -- Time selection enabled state
  
  -- Backup current render settings
  local curRenderPath = reaper.GetProjectPath("") .. "/render"
  
  -- Process each selected item
  for i = 0, itemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    
    if take then
      local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local itemEnd = itemPos + itemLen
      local takeName = reaper.GetTakeName(take)
      
      -- Clean up name for file
      local fileName = takeName:gsub("[^%w%s]", "_"):gsub("%s+", "_")
      if fileName == "" then fileName = "Item_" .. i end
      
      -- Create time selection for this item
      reaper.GetSet_LoopTimeRange(true, false, itemPos, itemEnd, false)
      
      -- Set up render for time selection
      reaper.Main_OnCommand(40290, 0) -- Set time selection to items
      reaper.Main_OnCommand(41716, 0) -- Set render bounds to time selection
      
      -- Set render settings
      local renderPath = exportPath .. "/" .. fileName .. ".wav"
      
      -- Use render dialog with pre-filled settings
      reaper.GetSetProjectInfo_String(0, "RENDER_FILE", renderPath, true)
      reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "", true) -- No pattern needed
      
      -- Render with dialog (user needs to click "Render")
      reaper.Main_OnCommand(40015, 0) -- Show render dialog
      
      table.insert(exportedFiles, fileName)
    end
  end
  
  -- Restore original time selection
  reaper.GetSet_LoopTimeRange(true, false, timeSelStart, timeSelEnd, false)
  if not isTimeSelEnabled then
    reaper.Main_OnCommand(40635, 0) -- Remove time selection
  end
  
  -- Show result message
  if #exportedFiles > 0 then
    local msg = string.format("Exported %d items to:\n%s\n\n", #exportedFiles, exportPath)
    msg = msg .. "Files:\n"
    for i, name in ipairs(exportedFiles) do
      msg = msg .. "- " .. name .. ".wav\n"
      if i > 10 then
        msg = msg .. "- ... (and " .. (#exportedFiles - 10) .. " more)\n"
        break
      end
    end
    reaper.ShowConsoleMsg(msg)
    return true
  else
    reaper.ShowMessageBox("No items were exported.", "Export Result", 0)
    return false
  end
end

-- Main function
function Main()
  -- Get export folder
  local exportFolder = ChooseExportFolder()
  if not exportFolder then return end
  
  -- Export items
  reaper.PreventUIRefresh(1)
  local success = ExportSelectedItems(exportFolder)
  reaper.PreventUIRefresh(-1)
  
  if success then
    reaper.ShowMessageBox("Export complete! Files are ready to import into Pro Tools.", "Export Successful", 0)
  end
end

-- Run main function
Main()