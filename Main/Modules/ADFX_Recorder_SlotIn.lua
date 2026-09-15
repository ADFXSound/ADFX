-- @description ADFX_Recorder_SlotIn
-- @version 1.0.0
-- @author ADFXSound

--[[
  ADFX_Recorder_SlotIn.lua
  ----------------------------------------------------------------------------
  Not a script you run. This is the copy/paste reference for wiring the shared
  recorder into an ADFX tool. There are three pieces; nothing else changes in
  the host script.
]]

--==============================================================================
-- 1. Near the top of the host script, next to the other requires
--==============================================================================

local sep = package.config:sub(1, 1)
local Recorder = dofile(reaper.GetResourcePath() .. sep .. 'Scripts' .. sep ..
  'ADFX' .. sep .. 'Modules' .. sep .. 'ADFX_Recorder.lua')

-- Sound Design Pad: capture everything the pad plays through the master bus,
-- and roll the timeline so the pass lines up with the arrangement.
local recorder = Recorder.new({
  id          = 'adfx_sound_design_pad',
  name_prefix = 'ADFX_SDPad',
  capture     = 'master',
  transport   = 'timeline',
})

-- S-Layer: capture the layer bus only. `get_source_track` is asked for the
-- track every time recording starts, so it can follow the script's selection.
--
-- `backend = 'buffer'` records through the capture JSFX, which holds a rolling
-- buffer of whatever it hears and needs no transport at all -- the sound comes
-- from the plugin, not the timeline. `transport` is the fallback for a REAPER
-- that cannot load the plug-in.
--
-- A script that uses gmem for its own plug-ins must name its space in
-- `host_gmem`; a script has only one attachment, and the recorder has to know
-- what to hand back after talking to the capture plug-in.
--
-- `auto_record` lets the recorder follow the script instead of the user: see
-- piece 4 below.
--
-- local recorder = Recorder.new({
--   id               = 'adfx_s_layer',
--   name_prefix      = 'ADFX_S-Layer',
--   capture          = 'track',
--   get_source_track = function() return my_layer_track end,
--   backend          = 'buffer',
--   host_gmem        = GMEM_NAME,
--   auto_record      = true,
--   transport        = 'isolated',
-- })

--==============================================================================
-- 2. At the bottom of the host window, as the last thing before ImGui_End
--==============================================================================

-- if visible then
--   ... the script's existing UI ...
--   recorder:draw(ctx)          -- optionally recorder:draw(ctx, { height = 90 })
--   reaper.ImGui_End(ctx)
-- end

--==============================================================================
-- 3. Wherever the host script tears down
--==============================================================================

-- reaper.atexit(function() recorder:shutdown() end)
--
-- ... and in the defer loop's close branch:
--
-- if open then reaper.defer(loop) else recorder:shutdown() end

--==============================================================================
-- 4. Optional: on the frame the host actually plays a sound
--==============================================================================

-- With `auto_record = true` this opens a take and closes it a second after the
-- sound decays. It does nothing while Auto is off, so no guard is needed.
-- Pass `allow_auto_record = true` to show the Auto button while leaving it off.
--
-- recorder:signal_trigger()

--==============================================================================
-- 5. Optional: where the host handles the space bar
--==============================================================================

-- Double clicking the waveform plays from that point. Space belongs to the
-- recorder while that is playing, and to the host at all other times.
--
-- if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Space(), false) then
--   if not recorder:consume_space() then my_host_audition() end
-- end

--==============================================================================
-- 6. Optional: answer "what was I doing when this sound happened"
--==============================================================================

-- A menu entry is handed the point in the take that was right clicked, and
-- wall_time_at turns that into the time_precise() reading it was captured at.
-- Log what the host plays against that clock and a sound can be traced back to
-- the settings that made it.
--
-- menu_items = {
--   { label = 'Restore settings from here',
--     action = function(at)
--       local entry = my_log_at(recorder:wall_time_at(at))
--       if not entry then return 'Nothing was played at that point' end
--       my_restore(entry)
--       return 'Restored'
--     end },
-- },

return Recorder
