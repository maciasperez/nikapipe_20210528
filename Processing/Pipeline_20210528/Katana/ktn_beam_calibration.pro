
;; Merging between beam_guess, ktn_noise_estim, planet_calib...

pro ktn_beam_calibration, noplot=noplot, absurd=absurd, no_bolo_maps=no_bolo_maps

common ktn_common

;; Compute maps in here to allow for iterations in KATANA
nsn = n_elements(data)
x_0 = data.ofs_az
y_0 = data.ofs_el

;;Garde que les aller-simples et vire les pointages abherents
if keyword_set(sky_data) then begin
   t_planet = 1.d0              ; place holder
   w8 = dblarr( nsn) + 1.d0
endif else begin
   t_planet = 4.d0              ; K_RJ
   w8 = dblarr( nsn)

   ;; Allers simples
   w4 = where( data.scan_st eq 4, nw4); & print, nw
   w5 = where( data.scan_st eq 5, nw5); & print, nw
   for i=0, nw4-1 do begin
      w = where( w5 gt w4[i], nw)
      if nw ne 0 then begin     ; maybe the last subscan is cut off, then discard
         imin = min(w)
         w8[ w4[i]:w5[imin]] = 1
      endif
   endfor

   vmax = 1.5 ; 4 ; 1                     ; 4
   v = sqrt( (x_0 - shift(x_0,1))^2 + (y_0-shift(y_0,1))^2)
   index = indgen( nsn)
   wind, 1, 1, /f
   plot, index, v, xtitle='Index', ytitle='Speed'
   oplot, index, v, col=150

   w = where( v gt vmax, nw)
   if nw ne 0 then w8[w]   = 0.
   if nw ne 0 then w8[(w-1)>0] = 0.
   if nw ne 0 then w8[(w+1)<(nsn-1)] = 0.
   if nw ne 0 then oplot, index[w], v[w], psym=1, col=250
endelse

;;w = where( w8 eq 1, nw)

if not keyword_set(no_bolo_maps) then begin
;; Recompute maps in case data.toi has been changed (decorrelated...)
;; get_bolo_maps_2, data.toi, data.ofs_az,   data.ofs_el,   w8, kidpar, grid_azel,    map_list_azel,    nhits_list_azel
;; get_bolo_maps_2, data.toi, data.ofs_nasx, data.ofs_nasy, w8, kidpar, grid_nasmyth, map_list_nasmyth, nhits_list_nasmyth
;   get_bolo_maps_5, data.toi, data.ipix,         w8, kidpar, grid_azel,    map_list_azel
;   get_bolo_maps_5, data.toi, data.ipix_nasmyth, w8, kidpar, grid_nasmyth, map_list_nasmyth
   get_bolo_maps_6, data.toi, data.ipix,         w8, kidpar, grid_azel,    map_list_azel
   get_bolo_maps_6, data.toi, data.ipix_nasmyth, w8, kidpar, grid_nasmyth, map_list_nasmyth

;; Update dist structure
   disp.map_list         = map_list_azel
   disp.map_list_nasmyth = map_list_nasmyth
endif

;; Get beam properties in (az,el)
w1 = where( kidpar.type eq 1, nw1)
;; beam_guess_2, disp.map_list, $
;;               disp.xmap, $
;;               disp.ymap, kidpar, $
;;               x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
;;               beam_list_1, theta_1, rebin=disp.rebin_factor, $
;;               verbose=verbose, parinfo=parinfo, noplot=noplot, $
;;               method=sys_info.beam_fit_method, cpu_time=cpu_time
;; stop
beam_guess, disp.map_list, $
            disp.xmap, $
            disp.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_1, theta_1, rebin=disp.rebin_factor, $
            verbose=verbose, parinfo=parinfo, noplot=noplot, $
            method=sys_info.beam_fit_method, cpu_time=cpu_time

if param.cpu_time eq 1 then print, "beam_guess azel: ", cpu_time
disp.beam_list = beam_list_1

;; Update COMMON variables
kidpar.x_peak       = x_peaks_1
kidpar.y_peak       = y_peaks_1
kidpar.x_peak_azel  = x_peaks_1
kidpar.y_peak_azel  = y_peaks_1

;; Compute also in Nasmyth to avoid pixelization errors that sometimes finds
;; beams way out of the Focal Plane
beam_guess, disp.map_list_nasmyth, $
            disp.xmap_nasmyth, $
            disp.ymap_nasmyth, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_1, theta_1, rebin=disp.rebin_factor, $
            verbose=verbose, parinfo=parinfo, noplot=noplot, $
            method=sys_info.beam_fit_method, cpu_time=cpu_time
if param.cpu_time eq 1 then print, "beam_guess Nasmyth: ", cpu_time

;; Update COMMON variables
kidpar.a_peak_nasmyth = a_peaks_1
kidpar.x_peak_nasmyth = x_peaks_1
kidpar.y_peak_nasmyth = y_peaks_1
kidpar.nas_x          = x_peaks_1
kidpar.nas_y          = y_peaks_1
kidpar.a_peak         = a_peaks_1
kidpar.sigma_x        = sigma_x_1
kidpar.sigma_y        = sigma_y_1
kidpar.fwhm_x         = sigma_x_1/!fwhm2sigma
kidpar.fwhm_y         = sigma_y_1/!fwhm2sigma
kidpar.fwhm           = sqrt( sigma_x_1*sigma_y_1)/!fwhm2sigma
kidpar.theta          = theta_1
ww = where( sigma_y_1 ne 0., nww)
if nww ne 0 then kidpar[ww].ellipt = sigma_x_1[ww]/sigma_y_1[ww]

;; Fit peak amplitude with the fixed nominal FWHM
for ikid=0, n_elements(kidpar)-1 do begin
   if kidpar[ikid].type eq 1 then begin
      if kidpar[ikid].array eq 1 then sigma_gauss = !nika.fwhm_nom[0]*!fwhm2sigma else sigma_gauss = !nika.fwhm_nom[1]*!fwhm2sigma

      d        = sqrt( (disp.xmap_nasmyth-kidpar[ikid].x_peak_nasmyth)^2 + (disp.ymap_nasmyth-kidpar[ikid].y_peak_nasmyth)^2)
      gauss_w8 = exp( -d^2/(2.d0*sigma_gauss^2))
      junk     = reform( disp.map_list_nasmyth[ikid,*,*])
      w        = where( finite(junk) eq 1)
      kidpar[ikid].flux = total( junk[w]*gauss_w8[w])/total(gauss_w8[w]^2)
   endif
endfor

;; Flag kids with problems if requested
if keyword_set(absurd) then begin
   message, /info, "keyword 'absurd' replaced by keyword 'sys_info.outlyers'"
   sys_info.outlyers = 1
endif

;;------------------------------------------------------
if sys_info.outlyers eq 1 then ktn_discard_outlyers

;; if sys_info.outlyers eq 1 then begin
;; 
;;    tags = tag_names(kidpar)
;;    fields_to_check = ['fwhm', 'a_peak', 'x_peak_nasmyth', 'y_peak_nasmyth', 'x_peak_azel', 'y_peak_azel']
;;    for i=0, n_elements(fields_to_check)-1 do begin
;;       ifield = where( strupcase(tags) eq strupcase(fields_to_check[i]), nw)
;;       if nw eq 0 then begin
;;          message, /info, "Can't find the current tag"
;;          stop
;;       endif
;;       
;;       w = where( finite(kidpar.(ifield)) eq 1, nw)
;;       if nw eq 0 then begin
;;          message, /info, "All "+tags[ifield]+"'s are infinite."
;;          return
;;       endif else begin
;;          med   = median( kidpar[w].(ifield))
;;          sigma = stddev( kidpar[w].(ifield))
;;          w = where( finite(kidpar.(ifield)) ne 1 or abs(kidpar.(ifield)-med) gt 5*sigma, nw)
;;          if nw ne 0 then kidpar[w].plot_flag = 1
;;       endelse
;;    endfor
;; 
;; endif
;;--------------------------------------------------------------

;; Absolute Calibration
;; nika_pipe_planet_calib, param, data, kidpar
nk_planet_calib, param, data, kidpar

;; Noise and sensitivity estimation
ktn_noise_estim

;; Checklist status
operations.beam_guess_done = 1

end
