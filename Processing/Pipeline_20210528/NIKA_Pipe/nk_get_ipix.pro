
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_ipix
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_get_ipix, data, info, grid
; 
; PURPOSE: 
;        Computes map pixel addresses for all samples
; 
; INPUT: 
;        - data, info, grid
; 
; OUTPUT: 
;        - data.ipix
; 
; KEYWORDS:
;
; DE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug 13th, 2014: NP
;        - Aug. 13th, 2015: NP. now takes grid in input instead of xmin, ymin, nx, ny...
;-
;===============================================================================================

;; pro nk_get_ipix, data, info, xmin, ymin, nx, ny, map_reso
;; pro nk_get_ipix, data, info, grid, header=header
pro nk_get_ipix, param, info, data, kidpar, grid, astr=astr
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence"
   print, "nk_get_ipix, param, info, data, kidpar, grid, astr=astr"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if strupcase(param.map_proj) eq "RADEC" or $
   strupcase(param.map_proj) eq "GALACTIC" then begin

   w1 = where( kidpar.type eq 1, nw1)

   ;; 1/ data.dra has been corrected for the cos(dec) to have orthonormal
   ;; xmap and ymap by default. But adx2y requires true ra and dec, so
   ;; I need to back correct.
   ;;
   ;; 2/ The sign convention of dra is opposite to the
   ;; R. A. convention as spotted by Helene Roussel as well, so we
   ;; need a "-" sign here
   ;;
   ;; 3/ For the moment, all the focal plane is rotated by the same
   ;; elevation angle as the center of the FOV, so here I rotate by
   ;; the central Dec.
   dec = info.latobj  + data.ddec[w1]/3600.d0
   
   ;;ra  = info.longobj + data.dra[ w1]/3600.d0/cos(astr.crval[1]*!dtor)
   ;; change sign of dra to be standard, NP+Ph.A, Dec. 2018
   ra  = info.longobj + data.dra[ w1]/3600.d0/cos(astr.crval[1]*!dtor)
   
   ad2xy, ra, dec, astr, x, y
   ;; correct bug in ad2xy convention, A. Beelen + NP, April 4th, 2018
   ;; ix = floor(x)
   ;; iy = floor(y)
   ix = floor(x+0.5d0)
   iy = floor(y+0.5d0)

   ipix = double( ix + iy*grid.nx)
   w = where( x lt 0 or x gt (grid.nx-1) or $
              y lt 0 or y gt (grid.ny-1), nw)
   if nw ne 0 then ipix[w] = -1
   data.ipix[w1] = ipix

endif else begin

   wkill = where( finite(data.dra) eq 0 or finite(data.ddec) eq 0, nwkill)
   ix    = (data.dra  - grid.xmin)/grid.map_reso
   iy    = (data.ddec - grid.ymin)/grid.map_reso
   if nwkill ne 0 then begin
      ix[wkill] = -1
      iy[wkill] = -1
   endif

   ipix = double( floor(ix) + floor(iy)*grid.nx)
   w = where( floor(ix) lt 0 or floor(ix) gt (grid.nx-1) or $
              floor(iy) lt 0 or floor(iy) gt (grid.ny-1), nw)
   if nw ne 0 then ipix[w] = -1
   data.ipix = ipix

endelse

if param.cpu_time then nk_show_cpu_time, param
end
