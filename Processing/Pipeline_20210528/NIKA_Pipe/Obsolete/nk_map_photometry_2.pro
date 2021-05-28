
;+
;
; SOFTWARE: Real time analysis
;
; NAME:
; nk_map_photometry_2
;
; CATEGORY: general, RTA
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Wrapper to nk_map_photometry, directly from a grid structure
; 
; INPUT: 
;       - grid: a structure containing signal, coordinates and variance maps
; 
; OUTPUT: 
;       - flux: Computed where the gaussian is fit (Jy)
;       - sigma_flux: Error on Flux (Jy)
;       - sigma_bg: noise per beam estimated on the map background far from the
;         fitted gaussian (Jy)
;       - output_fit_par: parameter of the fitted gaussian
;       - output_fit_par_error: errors on output_fit_par
;       - bg_rms: background rms of the map (on a representative subset of the pixels)
;       - flux_center: flux at the center of the map (Jy)
;       - sigma_flux_center: error on the flux at the center (Jy)
;       - integ_time_center: integration time on a disk of XXX diameter at the center of the map
; 
; KEYWORDS:
;       - map_conv: the input map convolved by the input beam (useful to enhance
;                   a weak point source on a display)
;       - input_fit_par: to force gaussian fit parameters (position, widths...)
;                        to estimate fluxes at the desired locations
;       - educated, k_noise : see nk_fitmap.pro
;       - noplot: prevents displays
;       - position: display position
;       - title, xtitle, ytitle: plot keywords
;       - lambda: mandatory to compute the NEFD
;       - NEFD: the noise equivalent flux density
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 16th, 2015: Nicolas Ponthieu
;-
;================================================================================================

pro nk_map_photometry_2, grid, input_fwhm=input_fwhm, $
                         flux, sigma_flux, $
                         sigma_bg, output_fit_par, output_fit_par_error, $
                         bg_rms_source, flux_center, sigma_flux_center, sigma_bg_center, $
                         integ_time_center, sigma_beam_pos, $
                         map_conv=map_conv, dist_fit=dist_fit, $
                         input_fit_par=input_fit_par, educated=educated, $
                         k_noise=k_noise, noplot=noplot, position=position, $
                         title=title, xtitle=xtitle, ytitle=ytitle, param=param, $
                         NEFD_source=NEFD_source, NEFD_center=NEFD_center, imrange=imrange, $
                         ps_file=ps_file, image_only=image_only, total_obs_time=total_obs_time, $
                         sigma_flux_center_toi=sigma_flux_center_toi, map_sn_smooth = map_sn_smooth, $
                         lambda=lambda, toi_nefd=toi_nefd, coltable = coltable,  beam_pos_list = beam_pos_list, info=info, $
                         charsize=charsize, xcharsize=xcharsize, ycharsize=ycharsize, inside_bar=inside_bar, $
                         orientation=orientation, $
                         time_matrix_center=time_matrix_center, time_matrix_source=time_matrix_source, q=q, u=u

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_map_photometry_2, grid, input_fwhm=input_fwhm, $"
   print, "                     flux, sigma_flux, $"
   print, "                     sigma_bg, output_fit_par, output_fit_par_error, $"
   print, "                     bg_rms_source, flux_center, sigma_flux_center, sigma_bg_center, $"
   print, "                     integ_time_center, sigma_beam_pos, $"
   print, "                     map_conv=map_conv, dist_fit=dist_fit, $"
   print, "                     input_fit_par=input_fit_par, educated=educated, $"
   print, "                     k_noise=k_noise, noplot=noplot, position=position, $"
   print, "                     title=title, xtitle=xtitle, ytitle=ytitle, param=param, $"
   print, "                     NEFD_source=NEFD_source, NEFD_center=NEFD_center, imrange=imrange, $"
   print, "                     ps_file=ps_file, image_only=image_only, total_obs_time=total_obs_time, $"
   print, "                     sigma_flux_center_toi=sigma_flux_center_toi, map_sn_smooth = map_sn_smooth, $"
   print, "                     lambda=lambda, toi_nefd=toi_nefd, coltable = coltable,  beam_pos_list = beam_pos_list, info=info, $"
   print, "                     charsize=charsize, xcharsize=xcharsize, ycharsize=ycharsize, inside_bar=inside_bar, $"
   print, "                     orientation=orientation, $"
   print, "                     time_matrix_center=time_matrix_center, time_matrix_source=time_matrix_source, q=q, u=u"
   return
endif

if not keyword_set(lambda) then begin
   message, /info, "Please set lambda to 1 or 2"
   return
endif

if lambda eq 1 then begin
   map     = grid.map_i_1mm
   map_var = grid.map_var_i_1mm
   nhits   = grid.nhits_1mm

   if keyword_set(q) then begin
      map     = grid.map_q_1mm
      map_var = grid.map_var_q_1mm
      nhits   = grid.nhits_1mm
   endif

   if keyword_set(u) then begin
      map     = grid.map_u_1mm
      map_var = grid.map_var_u_1mm
      nhits   = grid.nhits_1mm
   endif

   if not keyword_set(input_fwhm) then input_fwhm=!nika.fwhm_nom[0]
endif else begin
   map     = grid.map_i_2mm
   map_var = grid.map_var_i_2mm
   nhits   = grid.nhits_2mm

   if keyword_set(q) then begin
      map     = grid.map_q_2mm
      map_var = grid.map_var_q_2mm
      nhits   = grid.nhits_2mm
   endif

   if keyword_set(u) then begin
      map     = grid.map_u_2mm
      map_var = grid.map_var_u_2mm
      nhits   = grid.nhits_2mm
   endif

   if not keyword_set(input_fwhm) then input_fwhm=!nika.fwhm_nom[1]
endelse


nk_map_photometry, map, map_var, nhits, grid.xmap, grid.ymap, input_fwhm, $
                   flux, sigma_flux, $
                   sigma_bg, output_fit_par, output_fit_par_error, $
                   bg_rms_source, flux_center, sigma_flux_center, sigma_bg_center, $
                   integ_time_center, sigma_beam_pos, $
                   map_conv=map_conv, dist_fit=dist_fit, $
                   input_fit_par=input_fit_par, educated=educated, $
                   k_noise=k_noise, noplot=noplot, position=position, $
                   title=title, xtitle=xtitle, ytitle=ytitle, param=param, $
                   NEFD_source=NEFD_source, NEFD_center=NEFD_center, imrange=imrange, $
                   ps_file=ps_file, image_only=image_only, total_obs_time=total_obs_time, $
                   sigma_flux_center_toi=sigma_flux_center_toi, map_sn_smooth = map_sn_smooth, $
                   toi_nefd=toi_nefd, coltable = coltable,  beam_pos_list = beam_pos_list, info=info, $
                   charsize=charsize, xcharsize=xcharsize, ycharsize=ycharsize, inside_bar=inside_bar, orientation=orientation, $
                   time_matrix_center=time_matrix_center, time_matrix_source=time_matrix_source


end
