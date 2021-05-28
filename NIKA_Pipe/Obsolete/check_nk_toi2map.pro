
;; Testing the current pipeline, with real data and/or simulations
;;=======================================================================

nks_init, simpar

;; Add a point source at the center
simpar.ps_flux1mm[0] = 1.d0
simpar.ps_flux2mm[0] = 1.d0

;; Add uncorrelated white noise
simpar.white_noise     = 1
simpar.kid_NET         = 5e-3
simpar.kid_fknee       = 0.1
simpar.kid_alpha_noise = 2

;; Same fwhm for all kids
simpar.uniform_fwhm = 1

;; Init param
scan_list = '20140219s205'
nk_init, scan_list, param, info

;; ;; Init the mask
;; d = sqrt( info.xmap^2 + info.ymap^2)
;; w = where( d le 30)
;; info.mask_source = info.xmap*0.d0 + 1
;; info.mask_source[w] = 0

;; ;; Iteration on the source mask
;; info.mask_source = 1 ; no prior on source position at the first iteration
param.niter = 2

param.decor_meth = "COMMON_MODE_KIDS_OUT" ; "NONE"
nk_toi2map, param, info, simpar=simpar

wind, 1, 1, /free, /large
my_multiplot, 2, 2, pp, pp1, /rev
imview, info.map_1mm,     xmap=info.xmap, ymap=info.ymap, position=pp1[0,*], /noerase, title='1mm'
imview, info.map_2mm,     xmap=info.xmap, ymap=info.ymap, position=pp1[1,*], /noerase, title='2mm'
imview, info.map_var_1mm, xmap=info.xmap, ymap=info.ymap, position=pp1[2,*], /noerase, title='Variance 1mm'
imview, info.map_var_2mm, xmap=info.xmap, ymap=info.ymap, position=pp1[3,*], /noerase, title='Variance 2mm'

;; Check photometry
fwhm_1mm = simpar.fwhm_1mm
nk_map_photometry, info.map_1mm, info.nhits_1mm/!nika.f_sampling, info.map_var_1mm, $
                   info.xmap, info.ymap, fwhm_1mm, flux_1mm, sigma_flux_1mm, $
                   flux_center_1mm, sigma_flux_center_1mm, fit_par_1mm, fit_par_error_1mm
print, "flux_1mm, sigma_flux_1mm: ", flux_1mm, sigma_flux_1mm
print, "flux_center_1mm, sigma_flux_center_1mm: ", flux_center_1mm, sigma_flux_center_1mm

fwhm_2mm = simpar.fwhm_2mm
nk_map_photometry, info.map_2mm, info.nhits_2mm/!nika.f_sampling, info.map_var_2mm, $
                   info.xmap, info.ymap, fwhm_2mm, flux_2mm, sigma_flux_2mm, $
                   flux_center_2mm, sigma_flux_center_2mm, fit_par_2mm, fit_par_error_2mm
print, "flux_2mm, sigma_flux_2mm: ", flux_2mm, sigma_flux_2mm
print, "flux_center_2mm, sigma_flux_center_2mm: ", flux_center_2mm, sigma_flux_center_2mm

end
