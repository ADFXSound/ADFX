-- @description ADFX_Tab to Transient
-- @version 2.0.0
-- @author ADFXSound

--[[
  ADFX: Tab to Transient
  Select and move to the next item, set loop points to that selection,
  and snap the playhead if REAPER is playing.

  Load this file in the Action List to use it on its own.
  The Sound Design Pad dofiles this same script for Tab / Shift+Tab.
]]

local CMD_NEXT_ITEM = 40417
local CMD_PREV_ITEM = 40416
local CMD_REMOVE_TIME_SELECTION = 40635

local M = {}

function M.selection_bounds(api)
  api = api or reaper
  local count = api.CountSelectedMediaItems(0)
  if count == 0 then return nil, nil, 0 end

  local start_pos, end_pos
  for i = 0, count - 1 do
    local item = api.GetSelectedMediaItem(0, i)
    if item then
      local pos = api.GetMediaItemInfo_Value(item, "D_POSITION")
      local len = api.GetMediaItemInfo_Value(item, "D_LENGTH")
      if start_pos == nil or pos < start_pos then start_pos = pos end
      if end_pos == nil or pos + len > end_pos then end_pos = pos + len end
    end
  end

  return start_pos, end_pos, count
end

function M.set_loop_from_selection(api, opts)
  api = api or reaper
  opts = opts or {}
  local start_pos, end_pos, count = M.selection_bounds(api)
  if not start_pos or end_pos <= start_pos then return nil, nil, count end

  if api.Main_OnCommand then
    api.Main_OnCommand(CMD_REMOVE_TIME_SELECTION, 0)
  end
  api.GetSet_LoopTimeRange(true, false, start_pos, end_pos, false)
  api.GetSet_LoopTimeRange(true, true, start_pos, end_pos, false)

  if opts.enable_repeat and api.GetSetRepeat and api.GetSetRepeat(-1) == 0 then
    api.GetSetRepeat(1)
  end

  return start_pos, end_pos, count
end

function M.is_playing(api)
  api = api or reaper
  local state = api.GetPlayState and api.GetPlayState() or 0
  return (state % 2) == 1
end

function M.snap_playhead_if_playing(api)
  api = api or reaper
  if M.is_playing(api) and api.OnPlayButton then
    api.OnPlayButton()
  end
end

function M.go(api, direction, opts)
  api = api or reaper
  opts = opts or {}
  local cmd = direction < 0 and CMD_PREV_ITEM or CMD_NEXT_ITEM
  if api.Main_OnCommandEx then
    api.Main_OnCommandEx(cmd, 0, 0)
  elseif api.Main_OnCommand then
    api.Main_OnCommand(cmd, 0)
  end

  local start_pos, end_pos, count
  if opts.set_loop ~= false then
    start_pos, end_pos, count = M.set_loop_from_selection(api, opts)
  else
    local _
    _, _, count = M.selection_bounds(api)
  end

  M.snap_playhead_if_playing(api)
  return start_pos, end_pos, count
end

function M.next(api, opts)
  return M.go(api, 1, opts)
end

function M.prev(api, opts)
  return M.go(api, -1, opts)
end

-- Run only when this file is the action REAPER launched. The pad dofiles
-- this script for its functions and must not jump on load.
local function launched_as_action()
  if type(reaper) ~= "table" or not reaper.get_action_context then return false end
  local ok, _, filename = pcall(reaper.get_action_context)
  if not ok or type(filename) ~= "string" then return false end
  local leaf = filename:match("([^/\\]+)$") or filename
  return leaf:lower() == "adfx_tab to transient.lua"
end

if launched_as_action() then
  M.next(reaper, { set_loop = true, enable_repeat = true })
end

return M
