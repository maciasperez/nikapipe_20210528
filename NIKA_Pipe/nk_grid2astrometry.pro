;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_grid2astrometry
;
; CATEGORY: 
;        products
;
; CALLING SEQUENCE:
;        nk_grid2astrometry, param, grid, astrometry
; 
; PURPOSE: 
;        Creates the astrometry structure that will be passed to the output
;fits file
; 
; INPUT: 
;        - grid: the structure containing maps
; 
; OUTPUT: 
;        - astrometry: the output astrometry structure
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Jan 24th, 2015: NP
;        - Feb. 19th, 2019: updated accordinglty to nk_init_grid_2, NP
;-

pro nk_grid2astrometry, grid, astrometry

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_grid2astrometry, grid, astrometry"
   return
endif

astrometry = {naxis:grid.naxis, $
              cd:grid.cd, $
              cdelt:grid.cdelt, $
              crpix:grid.crpix, $
              crval:grid.crval, $
              ctype:grid.ctype,$
              longpole:grid.longpole, $
              latpole:grid.latpole, $
              pv2:grid.pv2}
end
