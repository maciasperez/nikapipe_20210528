
pro nk_project_auxillary_grids, param, info, data, kidpar, grid_out, info_out, $
                                ra_c=ra_c, dec_c=dec_c

info_out = info
info_out.longobj = ra_c
info_out.latobj  = dec_c
;; nk_init_grid, param, info_out, grid_out, astr=astr
nk_init_grid_2, param, info, grid, astr=astr

data2 = data                    ; clumsy but pragmatic for now not to overwrite data.ipix for the standard projection on "grid"
         
;; update (ra,dec) *offsets* as required by nk_get_ipix
w1 = where( kidpar.type eq 1)
;; absolute true coordinates
dec = info.latobj  + data.ddec[w1]/3600.d0
ra  = info.longobj - data.dra[ w1]/3600.d0/cos(astr.crval[1]*!dtor)
;; New pixel coordinates
ad2xy, ra, dec, astr, x, y
ix = floor(x+0.5d0)
iy = floor(y+0.5d0)
ipix = double( ix + iy*grid_out.nx)
w = where( x lt 0 or x gt (grid_out.nx-1) or $
           y lt 0 or y gt (grid_out.ny-1), nw)
if nw ne 0 then ipix[w] = -1
data2.ipix[w1] = ipix

nk_projection_4, param, info_out, data2, kidpar, grid_out

end
