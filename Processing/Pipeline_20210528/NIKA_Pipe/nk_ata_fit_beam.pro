
;+
;
; SOFTWARE: Real time analysis
;
; NAME:
; nk_ata_fit_beam
;
; CATEGORY: general
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Fits a constant background and a gaussian of known FWHM for Point
;        Source photometry.
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 4th, 2014: Nicolas Ponthieu
;-
;================================================================================================

pro nk_ata_fit_beam, map, map_var, gauss_w8, info, flux, sigma_flux

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

flux = 0.D0
sigma_flux = -1.D0

w = where( map_var gt 0 and gauss_w8 ne 0.d0, nw)
if nw eq 0 then begin
   nk_error, info, "No valid pixel to do Point Source photometry"
   return
endif

ata      = dblarr(2,2)
atd      = dblarr(2)
ata[0,0] = total( 1.d0/map_var[w])
ata[1,0] = total( gauss_w8[w]/map_var[w])
ata[0,1] = ata[1,0]
ata[1,1] = total( gauss_w8[w]^2/map_var[w])
atd[0]   = total( map[w]/map_var[w])
atd[1]   = total( gauss_w8[w]*map[w]/map_var[w])
atam1    = invert(ata)
s        = atam1##atd

flux       = s[1]
sigma_flux = sqrt(atam1[1,1])

end
