;+
pro nk_snr_flux_map, map, map_var, nhits, fwhm, reso, info, snr_flux_map, $
                     sigma = sigma_flux_kgauss, map_smooth = flux_kgauss, $
                     method = k_method, noiseup = noiseup, $
                     keep_only_high_snr = k_keep_only_high_snr, $
                     k_snr = k_snr, truncate_map = truncate_map, $
                     noboost = noboost, found_boost = found_boost, $
                     gridx = gridx, gridy = gridy, $
                     bg_zero_level_radius = bgzl_radius, $
                     bg_zero_level_mask = bgzl_mask
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_snr_flux_map'
   return
endif
if keyword_set(noiseup) then nup = noiseup else nup = 1.

kgauss = get_gaussian_kernel( fwhm, reso, /nonorm) ; PSF Gaussian kernel

;; @ Use ata_fit to derive the flux and the local background

if keyword_set( k_method) then meth = k_method else meth = 2 ; default
;   message, /info, string(meth)
if meth eq 3 then begin
   nk_ata_fit_beam3, map, map_var, kgauss, info, $
                     flux_kgauss, sigma_flux_kgauss, $ ; maps of flux and error,
                                ; corrected by nup
                     noiseup = nup ; nup does not affect map and map_var 
endif else begin                                    ; all other cases
   nk_ata_fit_beam2, map, map_var, kgauss, info, $
                     flux_kgauss, sigma_flux_kgauss ; map of flux and error
endelse

;; renormalize the error
;; Note: nhits_smooth is a smoothed version of nhits, not a
;; convolution of nhits at the beam scale.
nhits_smooth = convol( nhits, kgauss)/total(kgauss)
if not keyword_set( truncate_map) then $
   trunc = nhits_smooth*0+1. else trunc = truncate_map
if meth eq 3 then begin
   if keyword_set( bgzl_mask) then begin
      whkgauss     = where( bgzl_mask gt 0.9 and $
                            trunc gt 0.99 and nhits_smooth ne 0 and $
                            sigma_flux_kgauss ne 0. and $
                            finite( flux_kgauss) and $
                            finite( sigma_flux_kgauss), nwhkgauss)
      whkgauss2     = where( nhits_smooth ne 0 and sigma_flux_kgauss ne 0. and $
                             flux_kgauss ne 0. and $
                             finite( flux_kgauss) and $
                             finite( sigma_flux_kgauss), nwhkgauss2)
   endif else begin
      if keyword_set( bgzl_radius) then begin
         whkgauss     = where( sqrt( gridx^2 + gridy^2) ge  bgzl_radius and $
                               trunc gt 0.99 and nhits_smooth ne 0 and $
                               sigma_flux_kgauss ne 0. and $
                               finite( flux_kgauss) and $
                               finite( sigma_flux_kgauss), nwhkgauss)
         whkgauss2     = where( nhits_smooth ne 0 and sigma_flux_kgauss ne 0. and $
                                flux_kgauss ne 0. and $
                                finite( flux_kgauss) and $
                                finite( sigma_flux_kgauss), nwhkgauss2)
      endif else begin
         whkgauss     = where( trunc gt 0.99 and nhits_smooth ne 0 and $
                               sigma_flux_kgauss ne 0. and $
                               finite( flux_kgauss) and $
                               finite( sigma_flux_kgauss), nwhkgauss)
         whkgauss2     = where( nhits_smooth ne 0 and sigma_flux_kgauss ne 0. and $
                                flux_kgauss ne 0. and $
                                finite( flux_kgauss) and $
                                finite( sigma_flux_kgauss), nwhkgauss2)
      endelse
   endelse 
endif else begin
   whkgauss     = where( nhits_smooth ne 0 and sigma_flux_kgauss ne 0. and $
                         finite( flux_kgauss) and $
                         finite( sigma_flux_kgauss), nwhkgauss)
   whkgauss2 = whkgauss
   nwhkgauss2 = nwhkgauss
endelse
whk     = where( nhits ne 0 and map_var ne 0. and $
                 map ne 0. and $
                 finite( map) and $
                 finite( map_var), nwhk)
whkall     = where( map_var ne 0. and $
                 map ne 0. and $
                 finite( map) and $
                 finite( map_var), nwhkall)


;; @ Compare the current SNR distribution to a normalized gaussian to
;; @^ derive sigma_boost
histo_make, flux_kgauss[ whkgauss]/sigma_flux_kgauss[ whkgauss], $
            /gauss, n_bin = 301, minval = -10, maxval = +10, $
            xarr, yarr, stat_res, gauss_res
sigma_boost = gauss_res[1]
if not keyword_set( noboost) then $
   sigma_flux_kgauss = sigma_flux_kgauss * sigma_boost
; Change the zero level as well
zerolev = median( gauss_res[0]*sigma_flux_kgauss[ whkgauss])
if keyword_set( bgzl_radius) or keyword_set( bgzl_mask) then begin
   if keyword_set( bgzl_mask) then begin
      wbck = where( bgzl_mask gt 0.9 and $
                    trunc gt 0.99 and nhits_smooth ne 0 and $
                    sigma_flux_kgauss ne 0. and $
                    finite( flux_kgauss) and $
                    finite( sigma_flux_kgauss) and $
                    abs(flux_kgauss/sigma_flux_kgauss) lt 3, nwbck)
                                ; nail down the background on pixels
                                ; with low signal outside the central
                                ; zone (e.g. SZ cluster)
   endif else begin
      wbck = where( sqrt( gridx^2 + gridy^2) ge  bgzl_radius and $
                    trunc gt 0.99 and nhits_smooth ne 0 and $
                    sigma_flux_kgauss ne 0. and $
                    finite( flux_kgauss) and $
                    finite( sigma_flux_kgauss) and $
                    abs(flux_kgauss/sigma_flux_kgauss) lt 3, nwbck)
                                ; nail down the background on pixels
                                ; with low signal outside the central
                                ; zone (e.g. SZ cluster)
   endelse 
   if nwbck ne 0 then zerolev = $
      total( flux_kgauss[ wbck] / sigma_flux_kgauss[ wbck]^2, /double) / $
      total( 1./ sigma_flux_kgauss[ wbck]^2, /double) $
   else zerolev = 0.
;;; Old, gives bias in SZ maps
;;; if nwbck ne 0 then zerolev = median( flux_kgauss[ wbck]) else zerolev = 0.
   print, sigma_boost, zerolev
endif
found_boost = sigma_boost

if not keyword_set( noboost) then begin
   flux_kgauss[ whkgauss2] = flux_kgauss[ whkgauss2] - zerolev*trunc

; Change inputs  FXD Multiply by nup here (4 nov 2020)
   map[ whkall] = (map[ whkall]  - zerolev*trunc) * nup   ; change the zero level only where it has been measured
   map_var = (map_var * sigma_boost^2) * nup^2  ; assume the boost is valid everywhere
endif

; Change inputs  FXD Multiply by nup here (2Oct2020): wrong to use whk
; (must applied everywhere)
;; if nwhk ne 0 and ( not keyword_set( noboost)) then begin
;;    map[ whk] = (map[ whk]  - zerolev) * nup
;;    map_var[ whk] = (map_var[ whk] * sigma_boost^2) * nup^2
;; ;help, zerolev, sigma_boost, nup
;; endif

;; @ Update the flux SNR map
snr_flux_map            = map_var*0.d0
snr_flux_map[ whkgauss2] = $
   flux_kgauss[ whkgauss2] / sigma_flux_kgauss[ whkgauss2]

; The map (not the variance)
; High flux end may have been altered by noiseup: put it down to keep
; photometry of strong sources intact. An empirical formula that goes
; smoothly from 1/noiseup at high snr to 1. at low snr.

if keyword_set( k_keep_only_high_snr) then begin
   wp = where( snr_flux_map gt k_keep_only_high_snr, nwp)
   if nwp ne 0 then begin
      flux_kgauss[ wp] = flux_kgauss[ wp]  / nup
      map[ wp] = map[ wp] / nup
   endif
   wn = where( snr_flux_map lt -k_keep_only_high_snr, nwn)
   if nwn ne 0 then begin
      flux_kgauss[ wn] = flux_kgauss[ wn] / nup
      map[ wn] = map[ wn] / nup
   endif
   wc = where( abs(snr_flux_map) lt k_keep_only_high_snr, nwc) ; complementary pixel for later
   snr_flux_map[ whkgauss2] = $
      flux_kgauss[ whkgauss2] / sigma_flux_kgauss[ whkgauss2]
endif
;  expo changed to 1.5, a pure empirical exponent)
if keyword_set( k_snr) then begin
   if keyword_set( k_keep_only_high_snr) then $
      kk = k_keep_only_high_snr else kk = 1D20
   if not keyword_set( k_keep_only_high_snr) then $
      wc = where( abs(snr_flux_map) lt kk, nwc) ;all pixels in fact
   if nwc ne 0 then begin
      flux_kgauss[ wc] = flux_kgauss[ wc] * $
                         (nup+k_snr*abs(snr_flux_map[ wc])^1.5)/ $
                         (1D0 + k_snr*abs(snr_flux_map[ wc])^1.5) / nup
      map[ wc]         = map[ wc]         * $
                         (nup+k_snr*abs(snr_flux_map[ wc])^1.5)/ $
                         (1D0 + k_snr*abs(snr_flux_map[ wc])^1.5) / nup
   endif
   snr_flux_map[ whkgauss2] = flux_kgauss[ whkgauss2] / $
                              sigma_flux_kgauss[ whkgauss2]
endif

return
end

