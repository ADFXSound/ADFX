function Main()

  count_sel_items =  reaper.CountSelectedMediaItems( 0 )

  for i = 0, count_sel_items -1 do
  
    item = reaper.GetSelectedMediaItem(0, i)
  
    item_mute = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
  
    ToggleMute()

  end


end

function ToggleMute()
  if item_mute == 0
  then
  reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
  elseif item_mute == 1
  then
  reaper.SetMediaItemInfo_Value(item, "B_MUTE", 0)
  end

end


Main()
reaper.UpdateArrange()
