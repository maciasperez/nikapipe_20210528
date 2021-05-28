pro find_tilt2, tabs, tabw, xd, yd, pc, px, py, epx, epy, nan = k_nan
; Find the best instantaneous tilted plane going through the data
; Change the method: use regress
; inputs: tabs and tabw : Signal and weight = fltarr (ndet, nsample)
; and xd and yd focal plane positions
; Outputs: piston term pc (units of the signal), and 
; px, py : vector orthogonal to the tilted plane (units of signal/(units xd)
; Hence data=px.xd+py.yd+pc
dx = (double( xd)^2 # double( tabw))
dy = (double( yd)^2 # double( tabw))
good = where( dx gt 0 and dy gt 0, ngood)
nsample = n_elements( tabs[0, * ])
defv = 0.
if keyword_set( k_nan) then defv = !values.f_nan

px = fltarr( nsample)+defv
py = px
pc = px
epx = px
epy = py

if ngood ne 0 then begin
   for ig = 0, ngood -1 do begin
      u = where(tabw[*, good[ig]] gt 0)
      res = regress( transpose([[xd[u]], [yd[u]]]), $
                     reform(tabs[ u, good[ig]]), $
                     const = const, /double, $
                     sigma = sigma, $
                     status = status)
      if status eq 0 then begin
         pc[good[ ig]] = const
         px[good[ ig]] = res[0]
         py[good[ ig]] = res[1]
         epx[good[ig]] = sigma[0]
         epy[good[ig]] = sigma[1]
      endif

   endfor
endif

return

end

