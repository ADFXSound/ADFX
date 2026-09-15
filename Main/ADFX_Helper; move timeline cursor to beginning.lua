-- Set Cursor to Start (Keep Zoom)
-- Moves the edit/playback cursor to 00:00:00 while preserving the current horizontal zoom level

function main()
    -- Check if SWS extension is available (recommended for reliable view control)
    local has_sws = reaper.APIExists("BR_GetArrangeView")
    
    if has_sws then
        -- SWS method (more reliable)
        local start_time, end_time = reaper.BR_GetArrangeView(0)
        local view_duration = end_time - start_time
        
        -- Move cursor to 0
        reaper.SetEditCurPos(0, false, true)
        
        -- Set arrange view from 0 to duration (preserves zoom)
        reaper.BR_SetArrangeView(0, 0, view_duration)
    else
        -- Native fallback method
        -- Get arrange window and calculate pixels per second
        local arrange = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000)
        
        if arrange and reaper.JS_Window_GetClientSize then
            -- js_ReaScriptAPI method
            local _, width, _ = reaper.JS_Window_GetClientSize(arrange)
            local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
            local view_duration = end_time - start_time
            
            reaper.SetEditCurPos(0, false, true)
            reaper.GetSet_ArrangeView2(0, true, 0, 0, 0, view_duration)
        else
            -- Basic native method
            local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
            local view_duration = end_time - start_time
            
            reaper.SetEditCurPos(0, false, true)
            
            -- Use action to scroll, then manually adjust
            reaper.Main_OnCommand(40150, 0) -- View: Scroll view to edit cursor
            
            -- Re-get bounds and adjust to maintain duration
            local new_start, new_end = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
            local new_duration = new_end - new_start
            
            -- If duration changed, try to correct it using zoom
            if math.abs(new_duration - view_duration) > 0.001 then
                local zoom_factor = view_duration / new_duration
                local current_zoom = reaper.GetHZoomLevel()
                reaper.adjustZoom(current_zoom / zoom_factor, 1, true, 0)
                reaper.GetSet_ArrangeView2(0, true, 0, 0, 0, view_duration)
            end
        end
    end
    
    reaper.UpdateArrange()
end

reaper.defer(main)
