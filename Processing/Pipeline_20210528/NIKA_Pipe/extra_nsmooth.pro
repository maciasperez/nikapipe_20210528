
;; remove input map from the current TOIs not to bias the smooth
if keyword_set(subtract_maps) and param.subtract_i_map eq 1 then begin &$
   nk_subtract_maps_from_toi, param, info, data, kidpar, grid, subtract_maps &$
endif
w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin &$
   ikid = w1[i] &$
   y = smooth( data.toi[ikid], param.extra_nsmooth, /edge_mirror) &$
   data.toi[ikid] = reform(toi_copy[ikid,*])  - out_temp_data.toi[ikid] - y &$
endfor
