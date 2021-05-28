;+
; SOFTWARE: NIKA pipeline
;
; NAME:
;       nk_grid2grad
;
; CATEGORY: useful for polar leakage
;
; CALLING SEQUENCE:
;    nk_grid2grad, grid, grad
; 
; PURPOSE: 
;        Compute first and second derivative of a map to infer polar leakage
; 
; INPUT: 
;        - grid
; 
; OUTPUT: 
;        - grad,hessian in a structure (times the 5 outputs I1, I2,
;          I3, I_1mm, I_2mm)
; 
; KEYWORDS:
;        - norm : normalise everything to max(mapI) (useful for
;          calibration)
;        - maptag= list : gives the list of 5 (see above) tag names which are used
;          in the routine.
; SIDE EFFECT:
;       
; METHOD; See this ref. for ex.: 
; https://www.mathematik.uni-dortmund.de/~kuzmin/cfdintro/lecture4.pdf
;
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 4/2/2021 : FXD, derived and adapted from SCR/FXD/N2Rall/Polar/measure_leakage

pro nk_grid2grad, grid, grad, norm = norm, maptag = maptagname
;-
  if n_params() lt 1 then begin
     dl_unix, 'nk_grid2grad'
     return
  endif

  tagn = tag_names( grid)
  maptag = where( tagn eq 'MAP_I1' or tagn eq 'MAP_I2' or tagn eq 'MAP_I3' or $
                 tagn eq 'MAP_I_1MM' or tagn eq 'MAP_I_2MM', nmaptag)
  maptag = maptag[ sort( tagn[maptag])] ; make sure of the order I1, I2, I3
  maptagname = tagn[ maptag]
  nmap = n_elements(grid.(maptag[0])[*, 0])
  reso = grid.map_reso
  initmap = grid.(maptag[0])*0.D0
  grad = replicate({ mapi: initmap, mapx: initmap, mapy: initmap, $
                     mapxx: initmap, mapxy: initmap, mapyy: initmap}, nmaptag)
  for narr = 0, nmaptag-1 do begin ; loop on maps
     mapi = grid.(maptag[ narr])
     maxm = max( mapi)
     if keyword_set( norm) and maxm ne 0. then mapi = mapi / maxm
     grad[narr].mapi = mapi
     grad[narr].mapx =  0.5*( shift(mapi, 1, 0) - shift(mapi, -1,  0))/ reso ; derivative is in arcsec^-1 units
     grad[narr].mapy =  0.5*( shift(mapi, 0, 1) - shift(mapi,  0, -1))/ reso
     grad[narr].mapxx = (shift(mapi, 1, 0) - 2*mapi + shift(mapi, -1, 0)) / reso^2 ; 2nd derivative is in arcsec^-2 units
     grad[narr].mapxy = 0.25*(  shift(mapi,  1, 1) - shift(mapi,  1, -1) $
                               -shift(mapi, -1, 1) + shift(mapi, -1, -1)) / reso^2
     grad[narr].mapyy = (shift(mapi, 0, 1) - 2*mapi + shift(mapi, 0, -1)) / reso^2
  endfor                        ; end loop on array

  return

end
