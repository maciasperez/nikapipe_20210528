pro nk_keep_one_hwp_position, param, info, data

  if param.keep_one_hwp_position le 0 then return
  nsn = n_elements( data)
  posmin = min( data[0:15].position, imin)

; one wants to flag all hwp positions except one
  flag = data.flag
  kill_flag = bytarr(nsn)+1
  keep = lindgen(nsn/16)*16 + (imin+param.keep_one_hwp_position-1)    ; assumes 16 positions per hwp rotation (Fix me), param goes from 1 to 16, imin+param-1 goes from imin to imin+15, where imin is the smallest HWP position
  kill_flag[ keep] = 0
  wh = where( kill_flag, nwh)
  if nwh ne 0 then data[ wh].flag = 1

  return
end

