pro find_tilt4, tabs, tabw, xd, yd, pc, px, py, epc, epx, epy, cst, nan = k_nan
; Find the best instantaneous tilted plane going through the data
; Change the method: use regress
; inputs: tabs and tabw : Signal and weight = fltarr (ndet, nsample)
; and xd and yd focal plane positions in x and y coordinate: fltarr(ndet)
; Outputs: piston term pc (units of the signal), and 
; px, py : vector orthogonal to the tilted plane (units of signal/(units xd)
; Hence data[kid i]=px.xd+py.yd+pc+cst[i]
                                ; Here the constant is added wrt to find_tilt2
; find_tilt4 works around the iteration procedure of find_tilt3
  ; thanks to NP and the ATN-1 procedure
nsample = n_elements( tabs[0, * ])
ndet = n_elements( tabs[*, 0])
defv = 0.
if keyword_set( k_nan) then defv = !values.f_nan

px = fltarr( nsample)+defv
py = px
pc = px
epc = pc
epx = px
epy = py
cst = fltarr( ndet)+defv ; constant per kid

; Fit all parameters except the constant
;if ngood ne 0 then begin
; Overall constants

mat33=dblarr(3,3)
tata = tabw*tabs
totmeas  = total( tata/nsample)
totxmeas = total( double( xd) # (tata/nsample))
totymeas = total( double( yd) # (tata/nsample))
for isample = 0, nsample-1 do begin
; Compute a matrix of 3x3 elements
   ;; for i = 0, 2 do for j = i, 2 do $
   ;;    mat33[i, j] = total( tabw[*, isample]* xd^i*yd^j)
      mat33[0, 0] = total( tabw[*, isample])
      mat33[0, 1] = total( tabw[*, isample]* xd)
      mat33[0, 2] = total( tabw[*, isample]* yd)
      mat33[1, 1] = total( tabw[*, isample]* xd^2)
      mat33[1, 2] = total( tabw[*, isample]* xd*yd)
      mat33[2, 2] = total( tabw[*, isample]* yd^2)
      mat33[1, 0] = mat33[0, 1]
      mat33[2, 0] = mat33[0, 2]
      mat33[2, 1] = mat33[1, 2]
   ; invert it
   imat = invert( mat33, /double, status)
   if status lt 1 then begin ; inversion was ok
      outvec = imat #[total(      tata[*, isample])- totmeas, $
                      total( xd * tata[*, isample])-totxmeas, $
                      total( yd * tata[*, isample])-totymeas]
      pc[ isample] = outvec[0]
      px[ isample] = outvec[1]
      py[ isample] = outvec[2]
      epc[ isample] = imat[0, 0]
      epx[ isample] = imat[1, 1]
      epy[ isample] = imat[2, 2]
   endif
endfor
epc = sqrt(epc)
epx = sqrt(epx)
epy = sqrt(epy)
  
; Fit the constant (so that the average over time of pc, and px and py is 0)
for idet = 0, ndet-1 do $
   cst[ idet] = -xd[ idet]* total( tabw[ idet, *] * px) - $
                 yd[ idet]* total( tabw[ idet, *] * py) + $
           total( tata[idet, *])- total( tabw[ idet, *]* pc)

return

end

