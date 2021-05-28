
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_keep_only_high_snr
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_keep_only_high_snr, param, info, subtract_maps, subm
; 
; PURPOSE: 
;        Keep only the high SNR regions in the map at 1mm and 2mm
; 
; INPUT: 
;        - param, info, data, kidpar, subtract_maps
; 
; OUTPUT: 
;        - subm (same structure as subtract_maps)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - May 2019, NP
; Routine used in imcm method 120 to keep only the high SNR part of
;the maps. input is not changed. keyword to have the leftover with
;smoothing
; FXD Jan 2021: add the mapin parasite keyword
; FXD May1,2021: add an area (Fhwm/2) around regions strictly above the snr
pro nk_keep_only_high_snr, param, info, subtract_maps, subm, $
                           smooth_residue = smd, $
                           add_mapin = add_mapin, out_res_mapin = out_res_mapin
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_keep_only_high_snr'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

; Init (be careful not to change that)
subm = subtract_maps
smd = subm
out_res_mapin = subm

rmsig = 0.   ; 0 Jan 2021, 1. default, do or do not remove completely a 5 sigma (keep_only_high_snr value) regions
; first smooth the map with a Gaussian
fwhm = !nika.fwhm_nom[0]
; Here just take a smoothed variance
nk_snr_flux_map, subm.map_i_1mm, subm.map_var_i_1mm, subm.nhits_1mm, $
                 fwhm, subm.map_reso, $
                 info, snr_flux_map, sigma = sigma, map_smooth = mapgauss, $
                 method = param.k_snr_method, /noboost
                                ; noboost is to avoid renormalising
                                ; data (here it contains only the high
                                ; snr end

if keyword_set( add_mapin) then begin
   inf = info
   nk_snr_flux_map, add_mapin.map_i_1mm, add_mapin.map_var_i_1mm, $
                    add_mapin.nhits_1mm, $
                    fwhm, add_mapin.map_reso, $
                    inf, snr_flux_mapin, sigma = sigmain, $
                    map_smooth = mapgaussin, $
                    method = param.k_snr_method, /noboost
   out_res_mapin.map_i_1mm = mapgaussin* (add_mapin.nhits_1mm gt 0)
endif

subm.map_i_1mm = 0
smd.map_i_1mm = mapgauss* (subm.nhits_1mm gt 0) ; avoid naughty border pixels
w = where( snr_flux_map gt param.keep_only_high_snr, nw)

;FXD Enlarge the selected regions around the high snr
; Effectively it will enlarge to above 0.5 times the
; keep_only_high_snr parameter
; For snr>4, it means a surrounding region above 2sigma will be
; included in the the selected region
; Init a binary map
mapsel = mapgauss*0.
mapsel[w] = 1
kgauss = get_gaussian_kernel( fwhm, subm.map_reso, /nonorm) ; PSF Gaussian kernel
w = where( convol(mapsel, kgauss) gt 0.5, nw)

; subm contains only the pixels which are of high snr
; smd is the smoothed original map without the tip of snr
if nw ne 0 then begin
   subm.map_i_1mm[w] = subtract_maps.map_i_1mm[w] - $
                       rmsig* param.keep_only_high_snr*sigma[w]
   smd.map_i_1mm[w] = +rmsig* param.keep_only_high_snr*sigma[w]
   if keyword_set( add_mapin) then $
      out_res_mapin.map_i_1mm[w] = +rmsig* param.keep_only_high_snr*sigma[w]
endif

w = where( snr_flux_map lt (-param.keep_only_high_snr), nw)
mapsel = mapgauss*0.
mapsel[w] = 1
kgauss = get_gaussian_kernel( fwhm, subm.map_reso, /nonorm) ; PSF Gaussian kernel
w = where( convol(mapsel, kgauss) gt 0.5, nw)

if nw ne 0 then begin
   subm.map_i_1mm[w] = subtract_maps.map_i_1mm[w] + $
                       rmsig* param.keep_only_high_snr*sigma[w]
   smd.map_i_1mm[w] = -rmsig* param.keep_only_high_snr*sigma[w]
   if keyword_set( add_mapin) then $
      out_res_mapin.map_i_1mm[w] = -rmsig* param.keep_only_high_snr*sigma[w]
endif

;;; 2mm case
fwhm = !nika.fwhm_nom[1]
nk_snr_flux_map, subm.map_i_2mm, subm.map_var_i_2mm, subm.nhits_2mm, $
                 fwhm, subm.map_reso, $
                 info, snr_flux_map, sigma = sigma, map_smooth = mapgauss, $
                 method = param.k_snr_method, /noboost
                                ; noboost is to avoid renormalising
                                ; data (here it contains only the high
                                ; snr end
if keyword_set( add_mapin) then begin
   inf = info
   nk_snr_flux_map, add_mapin.map_i_2mm, add_mapin.map_var_i_2mm, $
                    add_mapin.nhits_2mm, $
                    fwhm, add_mapin.map_reso, $
                    inf, snr_flux_mapin, sigma = sigmain, $
                    map_smooth = mapgaussin, $
                    method = param.k_snr_method, /noboost
   out_res_mapin.map_i_2mm = mapgaussin* (add_mapin.nhits_2mm gt 0)
endif

subm.map_i_2mm = 0
smd.map_i_2mm = mapgauss* (subm.nhits_2mm gt 0)
w = where( snr_flux_map gt param.keep_only_high_snr, nw)

mapsel = mapgauss*0.
mapsel[w] = 1
kgauss = get_gaussian_kernel( fwhm, subm.map_reso, /nonorm) ; PSF Gaussian kernel
w = where( convol(mapsel, kgauss) gt 0.5, nw)

if nw ne 0 then begin
   subm.map_i_2mm[w] = subtract_maps.map_i_2mm[w] - $
                       rmsig* param.keep_only_high_snr*sigma[w]
   smd.map_i_2mm[w] = +rmsig* param.keep_only_high_snr*sigma[w]
   if keyword_set( add_mapin) then $
      out_res_mapin.map_i_2mm[w] = +rmsig* param.keep_only_high_snr*sigma[w]
endif

w = where( snr_flux_map lt (-param.keep_only_high_snr), nw)

mapsel = mapgauss*0.
mapsel[w] = 1
kgauss = get_gaussian_kernel( fwhm, subm.map_reso, /nonorm) ; PSF Gaussian kernel
w = where( convol(mapsel, kgauss) gt 0.5, nw)

if nw ne 0 then begin
   subm.map_i_2mm[w] = subtract_maps.map_i_2mm[w] + $
                       rmsig* param.keep_only_high_snr*sigma[w]
   smd.map_i_2mm[w] = -rmsig* param.keep_only_high_snr*sigma[w]
   if keyword_set( add_mapin) then $
      out_res_mapin.map_i_2mm[w] = -rmsig* param.keep_only_high_snr*sigma[w]
endif

; Deboost signal in the high SNR part only: NO
; The unfiltered signal is a correct representation of the initial toi.
;; if param.method_num eq 120 and keyword_set( param.noiseup) then begin
;;    ; 1mm case first
;;    Np = nk_atmb_count_param( info,  param, 1) ; 1 or 2mm
;;    Nsa = info.subscan_arcsec/!nika.fwhm_nom[0] ; number of beams in a subscan
;;    sigup = (1./(1.-(1.505*Np)/Nsa)) ; see nk_w8
;;    print, 'High SNR decorrection: Sigup = ', sigup, ' for 1mm array'
;;    subm.map_i_1mm = subm.map_i_1mm / sigup
   
;;    Np = nk_atmb_count_param( info,  param, 2) ; 1 or 2mm
;;    Nsa = info.subscan_arcsec/!nika.fwhm_nom[1] ; number of beams in a subscan
;;    sigup = (1./(1.-(1.505*Np)/Nsa)) ; see nk_w8
;;    print, 'High SNR decorrection: Sigup = ', sigup, ' for 2mm array'
;;    subm.map_i_2mm = subm.map_i_2mm / sigup
;; endif

if param.cpu_time then nk_show_cpu_time, param
return
end
