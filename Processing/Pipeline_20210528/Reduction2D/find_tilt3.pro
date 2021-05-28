pro find_tilt3, tabs, tabw, xd, yd, pc, px, py, epx, epy, cst, nan = k_nan
; Find the best instantaneous tilted plane going through the data
; Change the method: use regress
; inputs: tabs and tabw : Signal and weight = fltarr (ndet, nsample)
; and xd and yd focal plane positions in x and y coordinate: fltarr(ndet)
; Outputs: piston term pc (units of the signal), and 
; px, py : vector orthogonal to the tilted plane (units of signal/(units xd)
; Hence data[kid i]=px.xd+py.yd+pc+cst[i]
  ; Here the constant is added wrt to find_tilt2
dx = (double( xd)^2 # double( tabw))
dy = (double( yd)^2 # double( tabw))
good = where( dx gt 0 and dy gt 0, ngood)
nsample = n_elements( tabs[0, * ])
ndet = n_elements( tabs[*, 0])
defv = 0.
if keyword_set( k_nan) then defv = !values.f_nan

px = fltarr( nsample)+defv
py = px
pc = px
epx = px
epy = py
cst = fltarr( ndet)+defv ; constant per kid

; Fit all parameters except the constant
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

; Fit the constant (so that the average of pc, and px and py is 0)
   cst = ( total( (tabw[*, good] gt 0) * tabs[ *, good], 2) - $
           (tabw[*, good] gt 0) # (pc[ good]-mean(pc[ good])) - $
           (tabw[*, good] gt 0) # (px[ good]-mean(px[ good])) * xd - $
           (tabw[*, good] gt 0) # (py[ good]-mean(py[ good])) * yd)  / $
         total( (tabw[*, good] gt 0), 2)
   ;; cst = ( total( (tabw[*, good] gt 0) * tabs[ *, good], 2) - $
   ;;         (tabw[*, good] gt 0) # pc[ good] )  / $
   ;;       total( (tabw[*, good] gt 0), 2)

; iterate
   px = fltarr( nsample)+defv
   py = px
   pc = px
   epx = px
   epy = py
   for ig = 0, ngood -1 do begin
      u = where(tabw[*, good[ig]] gt 0)
      res = regress( transpose([[xd[u]], [yd[u]]]), $
                     ; remove the constant gradient across the array
                     reform(tabs[ u, good[ig]] -cst[u]), $
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

