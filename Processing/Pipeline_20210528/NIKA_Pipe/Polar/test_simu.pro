
;; Uranus
scan_list_in = '20140124s200'

;; CasA shifted 2 arcminutes /check sensivity
;; scan_list_in = ['20140126s216' , '20140126s217' , '20140126s218','20140126s219',$
;;                 '20140126s220', '20140126s221', '20140126s222']



;; CasA
;; scan_list_in = ['20140126s225' , '20140126s226' , '20140126s227','20140126s228', $
;;                 '20140126s229', '20140126s230', '20140126s231',
;;                 '20140126s232', '20140126s233']

;; Crab
;; scan_list_in = ['20140126s247' , '20140126s248' , '20140126s249','20140126s250', $
;;                 '20140126s251', '20140126s252']

;; Create mask_source
nk_default_param, param
nk_init_info, param, info, /polar
param.decor_method  = "COMMON_MODE_KIDS_OUT"
param.decor_cm_dmin = 1.5*!nika.fwhm_nom[1]
dist = sqrt( info.xmap^2 + info.ymap^2)
w = where( dist lt param.decor_cm_dmin, nw)
if nw ne 0 then info.mask_source[w] = 0.d0

;; Simulation prism tentative
;; simu
;; *****************************


nk_polar, scan_list_in, output_maps, kidpar, param=param, info=info, /polar
stop
;; nk_average_scans_polar, scan_list_in, param, info, output_maps, /plot
;; sim_pixel n°2
;; nk_polar, scan_list_in, maps_out1, kidpar, param=param, info=info, /polar
;; nk_average_scans_polar, scan_list_in, param, info, output_maps1, /plot

;; plot two polarizations states in the prism configuration

stop
;; check sensivity
;; **********************1mm********************************
input_fwhm  = !nika.fwhm_nom[0]
lambda = 1
nk_map_photometry, output_maps.map_q_1mm, output_maps.map_var_1mm,$
                   output_maps.nhits_1mm, output_maps.xmap, $
                   output_maps.ymap,input_fwhm, $
                   flux, sigma_flux, sigma_bg, output_fit_par,$
                   output_fit_par_error, bg_rms, $
                   flux_center, sigma_flux_center, $
                   lambda=lambda, kidpar=kidpar, /NEFD

nk_map_photometry, output_maps.map_u_1mm, output_maps.map_var_1mm,$
                   output_maps.nhits_1mm, output_maps.xmap, $
                   output_maps.ymap,input_fwhm, $
                   flux, sigma_flux, sigma_bg, output_fit_par,$
                   output_fit_par_error, bg_rms, $
                   flux_center, sigma_flux_center, $
                   lambda=lambda, kidpar=kidpar, /NEFD

;************************2mm*********************************
lambda = 2
input_fwhm  = !nika.fwhm_nom[1]
nk_map_photometry, output_maps.map_q_2mm, output_maps.map_var_2mm,$
                   output_maps.nhits_2mm, output_maps.xmap, $
                   output_maps.ymap,input_fwhm, $
                   flux, sigma_flux, sigma_bg, output_fit_par,$
                   output_fit_par_error, bg_rms, $
                   flux_center, sigma_flux_center,$
                   lambda=lambda, kidpar=kidpar, /NEFD

nk_map_photometry, output_maps.map_u_2mm, output_maps.map_var_2mm,$
                   output_maps.nhits_2mm, output_maps.xmap,$
                   output_maps.ymap, input_fwhm, $
                   flux, sigma_flux, sigma_bg, output_fit_par,$
                   output_fit_par_error, bg_rms, $
                   flux_center, sigma_flux_center, $
                   lambda=lambda, kidpar=kidpar, /NEFD

;; ***********************************************************
end 
