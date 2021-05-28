
;+
;
; SOFTWARE:
;
; NAME:
; nk_get_source_flux
;
; CATEGORY:
;
; CALLING SEQUENCE:
;  nk_get_source_flux, map, map_var, nhits, xmap, ymap, fwhm, xsource, ysource,
;flux, sigma_flux
;
; PURPOSE: 
;        Computes the flux integrated in a gaussian beam of a user supplied FWHM
;        around the location (xsource, ysource)
;
; INPUT: 
;       - map: the signal map, in Jy
;       - map_var: the variance map per pix in Jy^2
;       - nhits: number of hits per pixel
;       - xmap: map of coordinates in the x direction (arcsec)
;       - ymap: map of coordinates in the y direction (arcsec)
;       - fwhm: fwhm of the convolution kernel used to estimate
;                     quantities per beam (arcsec) 
;       - xsource and ysource: coordinates of the source
; 
; OUTPUT: 
;       - flux: Computed where the gaussian is fit (Jy)
;       - sigma_flux: Error on Flux (Jy)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aprils 28th, 2015: NP
;-
;================================================================================================

pro nk_get_source_flux, map, map_var, nhits, xmap, ymap, fwhm, xsource, ysource, $
                        flux, sigma_flux, dist_fit=dist_fit

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_source_flux, map, map_var, nhits, xmap, ymap, fwhm, xsource, ysource, $"
   print, "                    flux, sigma_flux"
   return
endif

reso       = xmap[1] - xmap[0]
flux       = 0.d0
sigma_flux = 0.d0

if not keyword_set(dist_fit) then dist_fit = 30. ; arcsec

;; Make sure the kernel is centered
input_sigma_beam = fwhm*!fwhm2sigma

;; Determine weights for aperture photometry at the center of the map
;; and around the source
dist_source     = sqrt( (xmap-xsource)^2 + (ymap-ysource)^2)
gauss_w8_source = exp( -dist_source^2/(2.d0*input_sigma_beam^2))

;; Restrict to defined pixels
valid_pix = where( map_var gt 0, compl=wout, nvalid_pix, ncompl=nwout)
if nwout ne 0 then gauss_w8_source[wout] = 0.d0

;; Estimate noise from the background of the map (pixels far from the source
;; and well covered).
ww           = where( map_var gt 0 and dist_source gt 5*input_sigma_beam, nww)
if nww eq 0 then stop
;;    if keyword_set(info) then begin
;;       stop
;; ;      nk_error, info, "Only undef pixels further than dist_source"
;; ;      return
;;    endif else begin
;;       stop
;; ;      message,/info, $
;; ;              "Only undef pixels further than dist_source"
;; ;      return
;;    endelse      
;; endif

wpix_source  = where( map_var gt 0 and dist_source gt 5*input_sigma_beam and nhits ge median( nhits[ww]), nwpix_source)
if nwpix_source eq 0 then message, "No pixel with var > 0 and further from the source than 5*sigma ?!"
if nwpix_source le 2 then message, "Not more than 2 valid pixels to estimate the noise (far from source)?!"
hh                              = sqrt(nhits[wpix_source])*map[wpix_source]
sigma_h_source                  = stddev(hh) ; Jy   
bg_rms_source                   = stddev( map[wpix_source])
noise_var_map_source            = xmap*0.d0
noise_var_map_source[valid_pix] = sigma_h_source^2/nhits[valid_pix]

;; Fit a background a gaussian of known FWHM to determine the flux
;; Need a test on nw because if it does not find any source, the centroid can be
;; found outside map boundaries and crash the estimation.
w        = where( map_var gt 0 and dist_source le dist_fit, nw)
if nw ne 0 then begin
   ata      = dblarr(2,2)
   atd      = dblarr(2)
   ata[0,0] = total( 1.d0/noise_var_map_source[w])
   ata[1,0] = total( gauss_w8_source[w]/noise_var_map_source[w])
   ata[0,1] = ata[1,0]
   ata[1,1] = total( gauss_w8_source[w]^2/noise_var_map_source[w])
   atd[0]   = total( map[w]/noise_var_map_source[w])
   atd[1]   = total( gauss_w8_source[w]*map[w]/noise_var_map_source[w])
   atam1    = invert(ata)
   s        = atam1##atd

   flux       = s[1]
   sigma_flux = sqrt(atam1[1,1])
endif else begin
   flux = 0.d0
   sigma_flux = 0.d0
endelse

end
