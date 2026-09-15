-- @description ADFXHelper; return play cursor
-- @version 2.0.0
-- @author ADFXSound

-- ADFXHelper; return play cursor.lua
-- Starts playback while remembering the edit cursor position.
-- Run the same action again to stop; playback returns to the saved position.

local SECTION = "ADFX_ReturnPlayCursor"
local KEY = "start_pos"

local play_state = reaper.GetPlayState()
local playing = (play_state & 1) == 1 or (play_state & 4) == 4

if not playing then
    -- Save where the edit cursor was before playback.
    local start_pos = reaper.GetCursorPosition()
    reaper.SetExtState(SECTION, KEY, string.format("%.17g", start_pos), false)

    -- Start playback.
    reaper.OnPlayButton()
else
    -- Stop playback.
    reaper.OnStopButton()

    -- Restore the edit cursor to where playback began.
    local saved = tonumber(reaper.GetExtState(SECTION, KEY))
    if saved then
        reaper.SetEditCurPos(saved, true, false)
    end

    reaper.DeleteExtState(SECTION, KEY, false)
end
