;+
; SOFTWARE: NIKA pipeline
;
; NAME:
;       nk_grid2grad2
;
; CATEGORY: useful for polar leakage
;
; CALLING SEQUENCE:
;    nk_grid2grad2, grid, sigarr, grad
; 
; PURPOSE: 
;        Compute first and second derivatives of a map by convolution to infer polar leakage
; 
; INPUT: 
;        - grid
;        - fwhmarr: array of 2 float: fwhm_beam_1mm, fwhm_beam_2mm
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
; METHOD: Kernel smoothing
; 
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 5/2/2021 : FXD

pro nk_grid2grad2, grid, fwhmarr, grad, norm = norm, maptag = maptagname
;-
  if n_params() lt 1 then begin
     dl_unix, 'nk_grid2grad2'
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
  fwhm = fwhmarr[ [0, 1, 0, 0, 1]]
  for narr = 0, nmaptag-1 do begin ; loop on maps
     kgauss = get_gaussian_kernel( fwhm[ narr], reso, k1d2d, /nonorm)
; PSF Gaussian kernel (peak at 1) and its 1st and 2nd derivative
     mapi = grid.(maptag[ narr])
     maxm = max( mapi)
     if keyword_set( norm) and maxm ne 0. then mapi = mapi / maxm
     grad[narr].mapi  = convol( mapi, kgauss)
     grad[narr].mapx  = convol( mapi, k1d2d[*, *, 0])
     grad[narr].mapy  = convol( mapi, k1d2d[*, *, 1])
     grad[narr].mapxx = convol( mapi, k1d2d[*, *, 2])
     grad[narr].mapxy = convol( mapi, k1d2d[*, *, 3])
     grad[narr].mapyy = convol( mapi, k1d2d[*, *, 4])
  endfor                        ; end loop on array

  return

end
