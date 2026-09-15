-- @description ADFX_Recorder_Demo
-- @version 1.0.0
-- @author ADFXSound

--[[
  ADFX_Recorder_Demo.lua
  Standalone host for the shared recorder strip. Run this to check the recorder
  on its own before slotting it into the Sound Design Pad or S-Layer.
]]

local sep = package.config:sub(1, 1)
local module_path = reaper.GetResourcePath() .. sep .. 'Scripts' .. sep .. 'ADFX' ..
  sep .. 'Modules' .. sep .. 'ADFX_Recorder.lua'

if not reaper.ImGui_CreateContext then
  reaper.ShowMessageBox('This script needs ReaImGui (ReaPack > Browse packages > ReaImGui).',
    'ADFX Recorder demo', 0)
  return
end

local Recorder = dofile(module_path)
if not Recorder then
  reaper.ShowMessageBox('Could not load:\n' .. module_path, 'ADFX Recorder demo', 0)
  return
end

local recorder = Recorder.new({
  id = 'adfx_recorder_demo',
  name_prefix = 'ADFX_Demo',
  label = 'Recorder',
})

local ctx = reaper.ImGui_CreateContext('ADFX Recorder demo')

reaper.atexit(function()
  recorder:shutdown()
end)

local function frame()
  reaper.ImGui_Text(ctx, 'Play or trigger anything in the project, then record it here.')
  reaper.ImGui_Spacing(ctx)
  recorder:draw(ctx, { height = 90 })
end

local function loop()
  reaper.ImGui_SetNextWindowSize(ctx, 560, 260, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'ADFX Recorder demo', true)
  if visible then
    frame()
    reaper.ImGui_End(ctx)
  end
  if open then
    reaper.defer(loop)
  else
    recorder:shutdown()
  end
end

reaper.defer(loop)
