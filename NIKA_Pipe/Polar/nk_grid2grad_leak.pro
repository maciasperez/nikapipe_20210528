;+
; SOFTWARE: NIKA pipeline
;
; NAME:
;       nk_grid2grad_leak
;
; CATEGORY: polar leakage
;
; CALLING SEQUENCE:
;    nk_grid2grad_leak, grid, leak
; 
; PURPOSE: 
;        Compute the polar leakage from coefficients and derivatives
;        of the I map.
; 
; INPUT: 
;        - grid
;        - leakcoeff (see nk_measure_leak) obtained with a calibrator
;          (e.g. Uranus)
; 
; OUTPUT: 
;        - leak: same structure as grid. I is useless, Q and U are the
;          sought leakages.
; 
; KEYWORDS:
;        - maptag= list : gives the list of 5 (see above) tag names which are used
;          in the routine.
; SIDE EFFECT:
;        at the border of the map, gradients may be wrong. Make sure
;        the map has zeros on the edge to avoid this.
;       
; METHOD:  Take the gradient and Hessian and compute the expected
;         leakage with the coefficients found in the calibration
;
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 4/2/2021 : FXD, derived and adapted from SCR/FXD/N2Rall/Polar/measure_leakage

pro nk_grid2grad_leak, grid, leakcoeff, leak, maptag = maptagname
;-
  if n_params() lt 1 then begin
     dl_unix, 'nk_grid2grad_leak'
     return
  endif

  tagn = tag_names( grid)
  maptag = where( tagn eq 'MAP_I1' or tagn eq 'MAP_I2' or tagn eq 'MAP_I3' or $
                 tagn eq 'MAP_I_1MM' or tagn eq 'MAP_I_2MM', nmaptag)
  maptag = maptag[ sort( tagn[maptag])] ; make sure of the order I1, I2, I3
  maptagname = tagn[ maptag]

  qutag = [where( tagn eq 'MAP_Q1'), $
           where( tagn eq 'MAP_U1'), $
           where( tagn eq 'MAP_Q2'), $
           where( tagn eq 'MAP_U2'), $
           where( tagn eq 'MAP_Q3'), $
           where( tagn eq 'MAP_U3'), $
           where( tagn eq 'MAP_Q_1MM'), $
           where( tagn eq 'MAP_U_1MM'), $
           where( tagn eq 'MAP_Q_2MM'), $
           where( tagn eq 'MAP_U_2MM')]
  nqutag = n_elements( qutag)
  

  nmap = n_elements(grid.(maptag[0])[*, 0])
  reso = grid.map_reso
  leak = grid                   ; to init the output

  nk_grid2grad, grid, grad      ; no normalisation
  
  for narr = 0, nmaptag-1 do begin ; loop on maps
     leak.(maptag[ narr]) = 0.
     for iqu = 0, 1 do begin    ; loop on Q and U leakage
        leak.(qutag[iqu+narr*2]) = leakcoeff[narr].coeff[iqu, 0]* grad[narr].mapi+ $
                                   leakcoeff[narr].coeff[iqu, 1]* grad[narr].mapx+ $
                                   leakcoeff[narr].coeff[iqu, 2]* grad[narr].mapy+ $
                                   leakcoeff[narr].coeff[iqu, 3]* grad[narr].mapxx+ $
                                   leakcoeff[narr].coeff[iqu, 4]* grad[narr].mapxy+ $
                                   leakcoeff[narr].coeff[iqu, 5]* grad[narr].mapyy
                                   
     endfor  ; end loop on Q and U
     
     
  endfor                        ; end loop on array

  return

end
