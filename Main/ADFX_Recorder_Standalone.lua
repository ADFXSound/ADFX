-- @description ADFX_Recorder_Standalone
-- @version 2.1.0
-- @author ADFXSound

--[[
  ADFX_Recorder_Standalone.lua
  Standalone host for the current shared recorder tool set. Run this to test the
  recorder independently before slotting it into Sound Design Pad or S-Layer.

  The demo deliberately uses the buffer backend and exposes the host-driven
  controls used by the production tools:
    * Signal Session is available and starts enabled.
    * Auto is available but starts disabled.
    * Trigger Signal simulates the host calling recorder:signal_trigger().

  Trigger Signal does not generate audio by itself. Play audio through the
  selected capture source while using it to test Signal/Auto wake behaviour.
]]

local sep = package.config:sub(1, 1)
local module_path = reaper.GetResourcePath() .. sep .. 'Scripts' .. sep .. 'ADFX' ..
  sep .. 'Modules' .. sep .. 'ADFX_Recorder.lua'

if not reaper.ImGui_CreateContext then
  reaper.ShowMessageBox('This script needs ReaImGui (ReaPack > Browse packages > ReaImGui).',
    'ADFX Recorder Standalone', 0)
  return
end

local ok, Recorder = pcall(dofile, module_path)
if not ok or not Recorder then
  reaper.ShowMessageBox(
    'Could not load ADFX_Recorder.lua.\n\nInstall the current ADFX Recorder modules in:\n' ..
    reaper.GetResourcePath() .. sep .. 'Scripts' .. sep .. 'ADFX' .. sep .. 'Modules' ..
    (ok and '' or '\n\n' .. tostring(Recorder)),
    'ADFX Recorder Standalone', 0)
  return
end

local recorder = Recorder.new({
  id                  = 'adfx_recorder_demo',
  name_prefix         = 'ADFX_Demo',
  capture             = 'master',
  backend             = 'buffer',
  buffer_seconds      = 120,
  transport           = 'timeline',
  allow_capture_switch   = true,
  allow_transport_switch = true,
  allow_auto_record      = true,
  auto_record            = false,
  allow_signal_record    = true,
  signal_record          = true,
})

local ctx = reaper.ImGui_CreateContext('ADFX Recorder Standalone')
local shut_down = false

local function shutdown()
  if shut_down then return end
  shut_down = true
  recorder:shutdown()
end

reaper.atexit(shutdown)

local function frame()
  reaper.ImGui_TextWrapped(ctx,
    'Standalone test host for the shared ADFX Recorder. Signal Session is enabled by default.')
  reaper.ImGui_TextWrapped(ctx,
    'Press Record to arm a Signal Session, then use Trigger Signal when the host would normally trigger a sound.')
  reaper.ImGui_Spacing(ctx)

  if reaper.ImGui_Button(ctx, 'Trigger Signal', 110, 0) then
    recorder:signal_trigger()
  end
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_SetTooltip(ctx,
      'Simulates a host trigger by calling recorder:signal_trigger().\n' ..
      'This wakes Signal Session / Auto capture but does not generate audio itself.')
  end

  reaper.ImGui_SameLine(ctx)
  local status = recorder:capture_status()
  if status and status ~= '' then
    reaper.ImGui_TextDisabled(ctx, tostring(status))
  else
    reaper.ImGui_TextDisabled(ctx, 'Recorder test host')
  end

  reaper.ImGui_Spacing(ctx)
  recorder:draw(ctx, { height = 110 })
end

local function loop()
  reaper.ImGui_SetNextWindowSize(ctx, 640, 330, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'ADFX Recorder Standalone', true)

  if visible then
    frame()
    reaper.ImGui_End(ctx)
  else
    -- draw() drives the recorder while visible. Keep asynchronous capture,
    -- finalization and preview work alive while the demo window is collapsed.
    recorder:tick()
  end

  if open then
    reaper.defer(loop)
  else
    shutdown()
  end
end

reaper.defer(loop)
