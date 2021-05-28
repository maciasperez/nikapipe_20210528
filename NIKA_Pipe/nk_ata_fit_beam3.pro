
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
;        nk_ata_fit_beam3, map, map_var, gauss_w8, info, flux, sigma_flux
; PURPOSE: 
;        Fits a gaussian of known FWHM for Point
;        Source photometry. nk_ata_fit_beam3 is to compute
;        the flux everywhere on a map.
;        Output is a map of flux and a map of noise.
; 
; INPUT:
;        map: 2D array (not changed on output)
;        map_var: 2D array of variance (not changed on output)
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
;        - July, 2020 FXD: start from nk_ata_fit_beam2, Here a zero
;          background is assumed
;================================================================================================

pro nk_ata_fit_beam3, map, map_var, gauss_w8, info, flux, sigma_flux, $
                      noiseup = noiseup
; Same as beam2 but no background is fitted, assumed 0.
                                ; Add the possibility of increasing
                                ; the noise due to the number of modes and
                                ; parameters used in the decorrelation
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_ata_fit_beam3'
   return
endif
;-
if keyword_set(noiseup) then nup = noiseup else nup = 1.
; This is a boosting factor for flux and noise to account for degrees
; of freedom in decorrelation fits.

flux = map*0.D0
sigma_flux = flux-1.D0

hit = where( map_var gt 0 and finite( map_var), nhit)
if nhit eq 0 then begin
   nk_error, info, 'No valid pixel to do Point Source photometry'
   return
endif

; Need to prepare by convolution
inv_var = map_var*0.
inv_var[ hit] = 1/map_var[hit]
m3 = convol( inv_var, gauss_w8^2)
m5 = convol( map*inv_var, gauss_w8)

; Test if we can invert
gdpx = where( m3 ne 0, ngdpx)
invdet = map*0.
if ngdpx ne 0 then invdet[ gdpx] = 1.D0/m3[ gdpx]
flux = invdet * m5 * nup
sigma_flux = sqrt( invdet) * nup
bad = where( sigma_flux eq 0., nbad) ; borders
if nbad ne 0 then begin
   flux[ bad] = !values.d_nan
   sigma_flux[ bad] = !values.d_nan
endif


return

end
