
;+
;
; SOFTWARE: Real time analysis
;
; NAME:
; nk_ata_fit_beam2
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;        nk_ata_fit_beam2, map, map_var, gauss_w8, info,
;        flux, sigma_flux
; PURPOSE: 
;        Fits a constant background and a gaussian of known FWHM for Point
;        Source photometry. nk_ata_fit_beam2 is to compute
;        the flux everywhere on a map.
;        Output is a map of flux and a map of noise
; 
; INPUT:
;        map: 2D array
;        map_var: 2D array of variance
;        gauss_w8: kernel for the point-source
;        info: usual info structure
; 
; OUTPUT:
;        flux: a 2D array containing the flux of the source
;        if it were at the position of each pixel of the input map
;        sigma_flux: a 2D 1 sigma uncertainty
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY:
;        - April 20th, 2017 FXD: start from nk_ata_fit_beam
;        - June 4th, 2014: Nicolas Ponthieu
;================================================================================================

pro nk_ata_fit_beam2, map, map_var, gauss_w8, info, flux, sigma_flux

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_ata_fit_beam2'
   return
endif
;-

flux = map*0.D0
sigma_flux = flux-1.D0

hit = where( map_var gt 0, nhit)
if nhit eq 0 then begin
   nk_error, info, 'No valid pixel to do Point Source photometry'
   return
endif

; Need to prepare by convolution
inv_var = map_var*0.
inv_var[ hit] = 1/map_var[hit]
m1 = convol( inv_var, gauss_w8*0+1D0)
m2 = convol( inv_var, gauss_w8)
m3 = convol( inv_var, gauss_w8^2)
m4 = convol( map*inv_var, gauss_w8*0+1D0)
m5 = convol( map*inv_var, gauss_w8)

; Need to form a matrix of 2 by 2 : call them a, b, c, d
aa = m1
bb = m2
cc = m2
dd = m3
determ = aa*dd - bb*cc
; Test if we can invert
gdpx = where( determ ne 0, ngdpx)
invdet = map*0.

if ngdpx ne 0 then invdet[ gdpx] = 1.D0/determ[ gdpx]

flux = invdet * (-cc * m4 + aa * m5)

sigma_flux = sqrt( invdet * aa)

return

end
