-- @description ADFX_Helper; Explode takes of items across tracks
-- @author ADFXSound
-- @version 1.2
-- @about
--   Explodes multi-take items so each take gets its own dedicated track.
--   Works on all selected items. For each selected item with N takes:
--     - The active take goes on the original track (track renamed to take name)
--     - All other takes get new tracks inserted below, also named after the take
--     - The original multi-take item is deleted after all single-take items are created
--   Undo point is created automatically.

-- ============================================================
--  Helpers
-- ============================================================

--- Return the track index (0-based) of a given track in the project.
local function track_index(track)
  return reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
end

--- Get a human-readable take name, falling back to source filename.
local function get_take_name(take, fallback)
  if not take then return fallback or "" end
  local name = reaper.GetTakeName(take)
  if name and name ~= "" then return name end
  local src = reaper.GetMediaItemTake_Source(take)
  if src then
    local filename = reaper.GetMediaSourceFileName(src, "")
    if filename and filename ~= "" then
      return filename:match("([^/\\]+)%.[^%.]+$")
          or filename:match("([^/\\]+)$")
          or filename
    end
  end
  return fallback or "Take"
end

--- Copy item-level geometry and properties to a freshly created item.
local function apply_item_props(src_item, dest_item)
  local props = {
    "D_POSITION", "D_LENGTH", "D_SNAPOFFSET",
    "D_FADEINLEN", "D_FADEOUTLEN",
    "D_FADEINLEN_AUTO", "D_FADEOUTLEN_AUTO",
    "C_FADEINSHAPE", "C_FADEOUTSHAPE",
    "D_VOL", "B_MUTE", "B_LOOPSRC",
    "I_CUSTOMCOLOR",
  }
  for _, p in ipairs(props) do
    reaper.SetMediaItemInfo_Value(dest_item, p,
      reaper.GetMediaItemInfo_Value(src_item, p))
  end
end

--- Add one take to dest_item, copying all properties from src_take.
local function add_single_take(dest_item, src_take, label)
  local new_take = reaper.AddTakeToMediaItem(dest_item)

  -- Source (audio/MIDI file reference)
  local src = reaper.GetMediaItemTake_Source(src_take)
  reaper.SetMediaItemTake_Source(new_take, src)

  -- Numeric take properties
  local num_props = {
    "D_STARTOFFS", "D_VOL", "D_PAN", "D_PANLAW",
    "D_PLAYRATE", "D_PITCH", "B_PPITCH",
    "I_CHANMODE", "I_PITCHMODE", "I_CUSTOMCOLOR",
  }
  for _, p in ipairs(num_props) do
    reaper.SetMediaItemTakeInfo_Value(new_take, p,
      reaper.GetMediaItemTakeInfo_Value(src_take, p))
  end

  -- Take name
  local tname = get_take_name(src_take, label)
  reaper.GetSetMediaItemTakeInfo_String(new_take, "P_NAME", tname, true)

  return new_take
end

--- Insert a new track at position idx (0-based) and name it.
local function insert_named_track(idx, name)
  reaper.InsertTrackAtIndex(idx, true)
  local t = reaper.GetTrack(0, idx)
  reaper.GetSetMediaTrackInfo_String(t, "P_NAME", name, true)
  return t
end

-- ============================================================
--  Main
-- ============================================================

local function explode_takes()
  local n_sel = reaper.CountSelectedMediaItems(0)
  if n_sel == 0 then
    reaper.ShowMessageBox("No items selected.", "Explode Takes", 0)
    return
  end

  -- Snapshot selected items (selection may change as we work)
  local entries = {}
  for i = 0, n_sel - 1 do
    local item  = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    entries[#entries + 1] = { item = item, track = track }
  end

  -- Check at least one item qualifies
  local any_multi = false
  for _, e in ipairs(entries) do
    if reaper.CountTakes(e.item) > 1 then any_multi = true; break end
  end
  if not any_multi then
    reaper.ShowMessageBox(
      "None of the selected items have more than one take.",
      "Explode Takes", 0)
    return
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- Process from the bottom track upward so inserting tracks below doesn't
  -- shift the indices of items we haven't touched yet.
  table.sort(entries, function(a, b)
    local ta = track_index(a.track)
    local tb = track_index(b.track)
    if ta ~= tb then return ta > tb end
    return reaper.GetMediaItemInfo_Value(a.item, "D_POSITION")
         > reaper.GetMediaItemInfo_Value(b.item, "D_POSITION")
  end)

  local total_exploded = 0

  for _, entry in ipairs(entries) do
    local item    = entry.item
    local track   = entry.track
    local n_takes = reaper.CountTakes(item)

    if n_takes > 1 then
      total_exploded = total_exploded + 1

      -- ---- Collect takes, active take first ----
      local takes = {}
      for ti = 0, n_takes - 1 do
        takes[ti + 1] = reaper.GetTake(item, ti)
      end

      local active = reaper.GetActiveTake(item)
      local active_idx = 1
      for ti, t in ipairs(takes) do
        if t == active then active_idx = ti; break end
      end

      if active_idx ~= 1 then
        local reordered = { takes[active_idx] }
        for ti, t in ipairs(takes) do
          if ti ~= active_idx then reordered[#reordered + 1] = t end
        end
        takes = reordered
      end

      -- ---- Insert destination tracks ----
      -- takes[1]  -> original track (renamed)
      -- takes[2+] -> new tracks inserted right below, in order
      local src_idx = track_index(track)

      -- Insert n_takes-1 new tracks below the source track.
      -- Insert in reverse order so they end up in the correct sequence.
      for ti = n_takes, 2, -1 do
        local tname = get_take_name(takes[ti], "Take " .. ti)
        insert_named_track(src_idx + 1, tname)
      end

      -- Rename original track to take 1's name
      local t1name = get_take_name(takes[1], "Take 1")
      reaper.GetSetMediaTrackInfo_String(track, "P_NAME", t1name, true)

      -- Build destination track list: original + the newly inserted ones
      -- After insertion, they sit at src_idx, src_idx+1, ..., src_idx+n_takes-1
      local dest_tracks = {}
      for ti = 1, n_takes do
        dest_tracks[ti] = reaper.GetTrack(0, src_idx + ti - 1)
      end

      -- ---- Create one new single-take item per take ----
      for ti = 1, n_takes do
        local new_item = reaper.AddMediaItemToTrack(dest_tracks[ti])
        apply_item_props(item, new_item)
        local new_take = add_single_take(new_item, takes[ti], "Take " .. ti)
        reaper.SetActiveTake(new_take)
      end

      -- ---- Delete the original multi-take item ----
      reaper.DeleteTrackMediaItem(track, item)
    end
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.TrackList_AdjustWindows(false)

  reaper.Undo_EndBlock(
    ("Takes: Explode takes across tracks (%d item%s)")
      :format(total_exploded, total_exploded == 1 and "" or "s"),
    -1
  )
end

explode_takes()
