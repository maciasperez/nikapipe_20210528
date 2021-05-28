
pro nika_nasmyth2draddec, ofs_az, ofs_el, elevation_rad, parangle_rad, nas_x, nas_y, fpc_x, fpc_y, $
                          dra, ddec, $
                          nas_x_ref=nas_x_ref, nas_y_ref=nas_y_ref

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_nasmyth2draddec, ofs_az, elevation_rad, parangle_deg, nas_x, nas_y, fpc_x, fpc_y, $"
   print, "                      nas_x_ref=nas_x_ref, nas_y_ref=nas_y_ref"
   return
endif
;print, nas_x, nas_y
nika_nasmyth2azel, nas_x, nas_y, fpc_x, fpc_y, elevation_rad*!radeg, dx, dy, $
                   nas_x_ref=nas_x_ref, nas_y_ref=nas_y_ref

dx   = -dx + ofs_az
dy   = -dy + ofs_el
dra  =  cos(parangle_rad)*dx + sin(parangle_rad)*dy
ddec = -sin(parangle_rad)*dx + cos(parangle_rad)*dy

end
