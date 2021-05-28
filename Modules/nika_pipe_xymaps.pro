
;; Quicklook over all kids and min/max azimuth to determine maximum coverage
;;==========================================================================

pro nika_pipe_xymaps, param, data, kidpar, xmap, ymap, nx, ny, xmin, ymin

nsn   = n_elements(data)
nkids = n_elements(kidpar)

dra_min  =  1e10
dra_max  = -1e10
ddec_min =  1e10
ddec_max = -1e10
el       = data[nsn/2].el       ; approx is enough
paral    = data[nsn/2].paral    ; approx is enough

;; Main loop
el_test = minmax(data.ofs_el)
az_test = minmax(data.ofs_az)
for i=0, 1 do begin
   for j=0, 1 do begin
      for ikid=0, nkids-1 do begin
         if kidpar[ikid].type eq 1 then begin
            nika_nasmyth2draddec, az_test[i], el_test[j], el, paral, $
                                  kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                                  0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                                  nas_y_ref=kidpar[ikid].nas_center_Y
            if dra  lt dra_min  then dra_min = dra
            if ddec lt ddec_min then ddec_min = ddec
            if dra  gt dra_max  then dra_max = dra
            if ddec gt ddec_max then ddec_max = ddec
         endif
      endfor
   endfor
endfor

;; Init coordinates maps
xsize = (dra_max  -  dra_min)
ysize = (ddec_max - ddec_min)
xra   = [dra_min, dra_max]   + [-1,1]*0.1*xsize ; add 10% margin
yra   = [ddec_min, ddec_max] + [-1,1]*0.1*ysize ; add 10% margin
xyra2xymaps, xra, yra, param.map.reso, xmap, ymap, nx, ny, xmin, ymin

end
