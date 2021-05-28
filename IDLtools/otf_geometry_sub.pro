
;; pro otf_geometry_sub, toi, kidpar, param, az, el, ofs_az, ofs_el
;; if not keyword_set(maps_output_dir) then maps_output_dir = !nika.plot_dir+'/Beam_maps/Maps'
pro otf_geometry_sub, i_in, file_list, maps_input_dir, maps_output_dir, kidpars_output_dir, kids_out, nickname, $
                         reso = reso, gamma=gamma, source=source

if not keyword_set(gamma) then gamma = !pi/4.d0
if not keyword_set(source) then source = "Uranus"

restore, maps_input_dir+"/"+file_list[i_in], /verb

;; message, /info, "fix me"
;; ;;el_avg_rad = !pi/4.
;; nk_default_param, param
;; param.source = 'uranus'
;; ;stop


;; Get beam properties in (az,el)
t0 = systime(0,/sec)
kidpar1 = kidpar
beam_guess, map_list_azel, $
            grid_azel.xmap, $
            grid_azel.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_azel, theta_1, const_1, beam_snr_1, rebin=rebin_factor, $
            verbose=verbose, parinfo=parinfo, /noplot, $
            method=beam_fit_method, cpu_time=cpu_time, /silent, nhits=nhits_azel

kidpar.x_peak       =  cos(gamma)*x_peaks_1 + sin(gamma)*y_peaks_1
kidpar.y_peak       = -sin(gamma)*x_peaks_1 + cos(gamma)*y_peaks_1
kidpar.x_peak_azel  =  kidpar.x_peak
kidpar.y_peak_azel  =  kidpar.y_peak
kidpar.a_peak       = a_peaks_1
;kidpar.peak_snr_azel = beam_snr_1

;; Keep track of the azel range used to derive this kidpar for future
;; kid selection
;kidpar.ofs_el_min = min(ofs_el_copy)
;kidpar.ofs_el_max = max(ofs_el_copy)

;; Compute also in Nasmyth to avoid pixelization errors that sometimes finds
;; beams way out of the Focal Plane
t0 = systime(0,/sec)
beam_guess, map_list_nasmyth, $
            grid_nasmyth.xmap, $
            grid_nasmyth.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_nasmyth, theta_1, const_1, beam_snr_1, rebin=rebin_factor, $
            verbose=verbose, parinfo=parinfo, /noplot, $
            method=beam_fit_method, cpu_time=cpu_time, /silent, nhits=nhits_nasmyth
t1 = systime(0,/sec)
kidpar.x_peak_nasmyth = x_peaks_1
kidpar.y_peak_nasmyth = y_peaks_1
kidpar.nas_x          = x_peaks_1
kidpar.nas_y          = y_peaks_1
kidpar.a_peak_nasmyth = a_peaks_1
kidpar.sigma_x        = sigma_x_1
kidpar.sigma_y        = sigma_y_1
kidpar.fwhm_x         = sigma_x_1/!fwhm2sigma
kidpar.fwhm_y         = sigma_y_1/!fwhm2sigma
kidpar.fwhm           = sqrt( sigma_x_1*sigma_y_1)/!fwhm2sigma
kidpar.theta          = theta_1
kidpar.peak_snr_nasmyth = beam_snr_1
ww = where( sigma_y_1 ne 0., nww)
if nww ne 0 then kidpar[ww].ellipt = sigma_x_1[ww]/sigma_y_1[ww]

;; Fit peak amplitude with the fixed nominal FWHM
for iarray=1, 3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin
      sigma_gauss = !nika.fwhm_array[iarray-1]*!fwhm2sigma
      for i=0, nw1-1 do begin
         ikid = w1[i]
         sigma_gauss = !nika.fwhm_array[iarray-1]*!fwhm2sigma
         d        = sqrt( (grid_nasmyth.xmap-kidpar[ikid].x_peak_nasmyth)^2 + (grid_nasmyth.ymap-kidpar[ikid].y_peak_nasmyth)^2)
         gauss_w8 = exp( -d^2/(2.d0*sigma_gauss^2))
         junk     = reform( map_list_nasmyth[ikid,*,*])
         w        = where( finite(junk) eq 1)
         kidpar[ikid].flux = total( junk[w]*gauss_w8[w])/total(gauss_w8[w]^2)
;;         if kidpar[ikid].flux le 0 then kidpar[ikid].type = 7 ; /= 3, easy to find then
         if kidpar[ikid].flux eq 0 then kidpar[ikid].type = 7
      endfor
   endif
endfor

;; Determine "scan" from the input file name
ll = strlen( file_list[i_in])
l_suffix = strlen("_000.save")
l_prefix = strlen('otf_geometry_toi_')
;; scan = strmid( file_list[i_in], l_prefix,  ll-l_suffix-l_prefix)

;; Absolute calibration.
;; Extracted from $PIPE/nk_planet_calib.pro
kidpar.calib = 0.d0
kidpar.calib_fix_fwhm = 0.d0

;nsn = n_elements(el)
;el_avg_rad = median(el)

for lambda=1, 2 do begin
   il = (where( round(!nika.lambda) eq lambda))[0]

   ;; Look for planet flux
   case strupcase(source) of
      "URANUS":  flux = !nika.flux_uranus[il]
      "MARS":    flux = !nika.flux_mars[il]
      "NEPTUNE": flux = !nika.flux_neptune[il]
      "SATURN":  flux = !nika.flux_saturn[il]
      "CERES":   flux = !nika.flux_ceres[il]
      "PALLAS":  flux = !nika.flux_pallas[il]
      "VESTA":   flux = !nika.flux_vesta[il]
      "LUTETIA": flux = !nika.flux_lutetia[il]
      '3C84':    flux = !nika.flux_3c84[il]
      else: flux = 1.d0 ; to allow cross-calibration at least
   endcase

   nk_list_kids, kidpar, lambda=lambda, on=w1, non=nw1
   if nw1 ne 0 then begin
      if el_avg_rad ne 0 then begin
         kidpar[w1].calib          = flux * exp(-kidpar[w1].tau_skydip/sin(el_avg_rad))/kidpar[w1].a_peak ; Jy/Hz
         kidpar[w1].calib_fix_fwhm = flux * exp(-kidpar[w1].tau_skydip/sin(el_avg_rad))/kidpar[w1].flux
      endif else begin
         ;; Lab measurements
         kidpar[w1].calib          = flux/kidpar[w1].a_peak ; Jy/Hz
         kidpar[w1].calib_fix_fwhm = flux/kidpar[w1].flux
      endelse
   endif
endfor

;; the following estimation of noise is now in nk_otf_geometry_bcast_data
;; ;; Take the power spectrum on the 2 most quiet minutes
;; n_2mn = 2*60.*!nika.f_sampling
;; nsn_noise = 2L^round( alog(n_2mn)/alog(2))
;; wk = where( kidpar.type eq 1, nwk)
;; for i=0, nwk-1 do begin
;;    ikid = wk[i]
;;    rms  = 1e10
;;    ixp  = 0
;;    while (ixp+nsn_noise-1) lt nsn do begin
;;       d = reform( toi[ikid,ixp:ixp+nsn_noise-1])
;;       if stddev(d) lt rms then ix1 = ixp
;;       ixp += nsn_noise
;;    endwhile
;; 
;;    y = reform( toi[ikid,ix1:ix1+nsn_noise-1])
;;    power_spec, y - my_baseline( y), !nika.f_sampling, pw, freq
;;    wf = where( freq gt 4.d0)
;;    if finite(avg(pw[wf])) eq 0 then stop
;;    kidpar[ikid].noise = avg(pw[wf]) ; Hz/sqrt(Hz) since data is in Hz
;;    
;;    wf = where( abs(freq-1.d0) lt 0.2, nwf)
;;    if nwf ne 0 then kidpar[ikid].noise_1hz = avg(pw[wf])
;;    wf = where( abs(freq-2.d0) lt 0.2, nwf)
;;    if nwf ne 0 then kidpar[ikid].noise_2hz = avg(pw[wf])
;;    wf = where( abs(freq-10.d0) lt 1, nwf)
;;    if nwf ne 0 then kidpar[ikid].noise_10hz = avg(pw[wf])
;; endfor

;; Derive sensitivity
kidpar.sensitivity_decorr  = kidpar.calib * kidpar.noise * 1000 ; Jy/Hz x Hz/sqrt(Hz) x 1000 = mJy/sqrt(Hz) x 1
kidpar.sensitivity_decorr /= sqrt(2.d0) ; /Hz^1/2 to s^1/2

;; Get ready for katana_light and ktn_widget_light
save, file = maps_output_dir+'/map_lists_'+nickname+"_sub_"+strtrim(i_in,2)+".save", $
      map_list_azel, map_list_nasmyth, kidpar, $
      beam_list_azel, beam_list_nasmyth, grid_nasmyth, grid_azel, $ ;param, 
      nhits_azel, nhits_nasmyth

;; Output kidpars in case it's the second iteration and we do
;; not need to go through Katana again
;; nk_write_kidpar, kidpar, kidpars_output_dir+"/kidpar_"+scan+"_raw_"+strtrim(i_in, 2)+".fits"
;; nk_write_kidpar, kidpar, kidpars_output_dir+"/kidpar_raw_"+strtrim(i_in, 2)+".fits"
nk_write_kidpar, kidpar, kidpars_output_dir+"/kidpar_"+nickname+"_"+strtrim(i_in, 2)+".fits"

end
