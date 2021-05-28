; Routine used by focal_plane_match
; FXD May 2018 from Labtools/FXD/N2R12
pro fplane, dlim, gk, ngk, gdall, ngdall, gd, ngd, $
            kida, indich, kp, indch, nch, degree, $
            pp, qq, xg, yg, ida, idb, dd, nostop = nostop
; see Focal_plane.scr
polywarp, /double, kida[indich].nas_x, kida[indich].nas_y, $
          kp[indch].x, kp[indch].y, degree, pp, qq
xg = compute_poly2d( kp.x, kp.y, pp)
yg = compute_poly2d( kp.x, kp.y, qq)
wshet, 16
plot, psym = 8, symsize = 0.6, kida[indich].nas_x, kida[indich].nas_y, $
      /iso, xsty = 2, ysty = 2
oplot, psym = 4, col = 100, xg[indch], yg[indch]
oplot, psym = 8, symsize = 0.4, col = 200, xg[gk], yg[gk]
cont_plot, nostop = nostop
;if not keyword_set( nostop) then stop
match2d, kida.nas_x, kida.nas_y, xg, yg, ida, idb
dd = sqrt((kida[ ida].nas_x-xg)^2 + (kida[ ida].nas_y-yg)^2)
rmsk = sqrt( total( dd[gk]^2) / ngk)
rmsgd = sqrt( total( dd[gd]^2) / ngd)
ddind = sqrt((kida[indich].nas_x-xg[indch])^2 + $
             (kida[indich].nas_y-yg[indch])^2)
rmsind = sqrt( total( ddind^2) / nch)

print, degree, rmsk,  rmsgd, rmsind
gd = where( kp.ninfeed ge 0 and kp.x gt -500 and dd lt dlim, ngd)
print, ngd, ' are found within ', round( dlim), ' arcseconds'
ii = indgen( ngd/5)*5  ; limit the number of used pixels (for machine precision)
indch = gd[ii] &  nch = n_elements( indch) 
indich = ida[ gd[ ii]] 
interm1 = where( kp.ninfeed ge 0 and kp.x gt -500 and dd ge dlim*1. $
                 and dd lt dlim*2., ninterm1) 
interm2 = where( kp.ninfeed ge 0 and kp.x gt -500 and dd ge dlim*2. $
                 and dd lt dlim*4., ninterm2) 
print, ngdall, ngd,  ninterm1,  ninterm2, ngdall -(ngd+ninterm1+ninterm2)

return
end
