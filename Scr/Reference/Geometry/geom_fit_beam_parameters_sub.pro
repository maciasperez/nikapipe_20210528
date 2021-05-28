
;; pro otf_geometry_sub, toi, kidpar, param, az, el, ofs_az, ofs_el
;; if not keyword_set(maps_output_dir) then maps_output_dir = !nika.plot_dir+'/Beam_maps/Maps'
pro geom_fit_beam_parameters_sub, i_in, file_list, maps_input_dir, maps_output_dir, kidpars_output_dir, kids_out, nickname, $
                                  input_flux_th, $
                                  reso = reso, gamma=gamma, source=source, plateau=plateau, asymfast=asymfast, $
                                  ata_fit_beam_rmax=ata_fit_beam_rmax, $
                                  map_list_nhits_azel=map_list_nhits_azel, map_list_nhits_nasmyth=map_list_nhits_nasmyth, $
                                  aperture_phot=aperture_phot

if not keyword_set(gamma) then gamma = !pi/4.d0
if not keyword_set(source) then source = "Uranus"

restore, maps_input_dir+"/"+file_list[i_in]
;stop
;; Get beam properties in (az,el)
t0 = systime(0,/sec)
kidpar1 = kidpar
;xmap = grid_azel.xmap
;grid_azel.xmap =  cos(gamma)*xmap - sin(gamma)*grid_azel.ymap
;grid_azel.ymap = sin(gamma)*xmap + cos(gamma)*grid_azel.ymap

beam_guess, map_list_azel, $
            grid_azel.xmap, $
            grid_azel.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_azel, theta_1, const_1, rebin=rebin_factor, $
            verbose=verbose, parinfo=parinfo, /noplot, $
            method=beam_fit_method, cpu_time=cpu_time, /silent, $;nhits=nhits_azel, $
            map_list_nhits=map_list_nhits_azel


;; kidpar.x_peak        =  cos(gamma)*x_peaks_1 + sin(gamma)*y_peaks_1
;; kidpar.y_peak        = -sin(gamma)*x_peaks_1 + cos(gamma)*y_peaks_1
;; Gamma back rotation now done in grid_azel.xmap and ymap in
;; geom_prepare_toi, NP. Aug. 19th, 2016, rev > 12213
kidpar.x_peak        = x_peaks_1
kidpar.y_peak        = y_peaks_1
kidpar.x_peak_azel   = kidpar.x_peak
kidpar.y_peak_azel   = kidpar.y_peak
kidpar.a_peak        = a_peaks_1
;kidpar.peak_snr_azel = beam_snr_1

;; Compute also in Nasmyth to avoid pixelization errors that sometimes finds
;; beams way out of the Focal Plane
t0 = systime(0,/sec)
beam_guess, map_list_nasmyth, $
            grid_nasmyth.xmap, $
            grid_nasmyth.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_nasmyth, theta_1, const_1, rebin=rebin_factor, $
            verbose=verbose, parinfo=parinfo, /noplot, $
            method=beam_fit_method, cpu_time=cpu_time, /silent, $;nhits=nhits_nasmyth, $
            map_list_nhits=map_list_nhits_nasmyth


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
;kidpar.peak_snr_nasmyth = beam_snr_1
ww = where( sigma_y_1 ne 0., nww)
;; if nww ne 0 then kidpar[ww].ellipt = sigma_x_1[ww]/sigma_y_1[ww]
if nww ne 0 then begin
   for i=0, nww-1 do begin
      ikid = ww[i]
      kidpar[ikid].ellipt = max( [kidpar[ikid].sigma_x, kidpar[ikid].sigma_y])/min( [kidpar[ikid].sigma_x, kidpar[ikid].sigma_y])
   endfor
endif

;;=============================================
;; Fit peak amplitude with the fixed nominal FWHM, accounting for a
;; background term (makes little difference, less than 1% level, but
;; cleaner)
;; NP, July 30th, 2016
nk_default_info, myinfo

for iarray=1, 3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin
      sigma_gauss = !nika.fwhm_array[iarray-1]*!fwhm2sigma

      case 1 of
         keyword_set(asymfast): begin
            ;;********************************************************
            ;; Il faut fitter en azel car le beam est modelise en azel
            ;;********************************************************
            bg_mask = grid_azel.xmap*0.d0
            for i=0, nw1-1 do begin
               ikid   = w1[i]
               nhits_azel = reform( map_list_nhits_azel[ikid,*,*], grid_azel.nx, grid_azel.ny)
               kidmap = reform( map_list_azel[ikid,*,*])
               d      = sqrt( (grid_azel.xmap-kidpar[ikid].x_peak_azel)^2 + (grid_azel.ymap-kidpar[ikid].y_peak_azel)^2)
               bg_mask = grid_azel.xmap*0.d0
               ;; Compute the background either on a ring around the
               ;; source or on the whole map far from
               ;; the source.
               if keyword_set(ata_fit_beam_rmax) then begin
                  ;; for tests, we may try very small ata_fit_beam_rmax
                  ;; and then no pixel could be at 2*fwhm and less then ata_fit_beam_rmax
                  if ata_fit_beam_rmax le 2*!nika.fwhm_array[iarray-1] then begin
                     wbg = where( d ge 2*!nika.fwhm_array[iarray-1] and $
                                  nhits_azel ne 0, nwbg)
                  endif else begin
                     wbg = where( d ge 2*!nika.fwhm_array[iarray-1] and $
                                  nhits_azel ne 0 and $
                                  d le ata_fit_beam_rmax, nwbg)
                  endelse
                  wfit = where( d le ata_fit_beam_rmax and $
                                nhits_azel ne 0, nwfit, compl=wnofit)
               endif else begin
                  wbg  = where( d ge 4*!nika.fwhm_array[iarray-1] and nhits_azel ne 0, nwbg)
                  wfit = where( nhits_azel ne 0, nwfit, compl=wnofit)
               endelse
               bg_mask[wbg] = 1
               nk_bg_var_map, kidmap, nhits_azel, bg_mask, map_var
               map_var[wnofit] = 0.d0
               message, /info, "fix me:"
               stop
               p_guess = [0.d0, max(kidmap), kidpar[ikid].x_peak_azel, kidpar[ikid].y_peak_azel]
               my_fit_nika2_beam, kidmap, map_var, $
                                  grid_azel.xmap, $
                                  grid_azel.ymap, params, covar, perror, fit=fit, p_guess=p_guess

;;             wind, 1, 1, /free, /large
;;              my_multiplot, 2, 3, pp, pp1, /rev, gap_y=0.05
;;              imview, kidmap, xmap=grid_azel.xmap, ymap=grid_azel.ymap, position=pp1[0,*], title='Raw', $
;;                      legend_text = ['x_peak: '+strtrim(kidpar[ikid].x_peak_azel,2), $
;;                                     'y_peak: '+strtrim(kidpar[ikid].y_peak_azel,2)], leg_col=250
;;              oplot, [1,1]*kidpar[ikid].x_peak_azel, [1,1]*kidpar[ikid].y_peak_azel, psym=1, col=250, syms=2
;;              imview, long(map_var ne 0), xmap=grid_azel.xmap, ymap=grid_azel.ymap, position=pp1[1,*], title='map_var for fit', /noerase
;;              oplot, [1,1]*kidpar[ikid].x_peak_azel, [1,1]*kidpar[ikid].y_peak_azel, psym=1, col=250, syms=2
;;              imview, fit, xmap=grid_azel.xmap, ymap=grid_azel.ymap, position=pp1[2,*], /noerase, title='fit';, $
;; ;                     legend_text=strtrim(params,2), leg_color=255
;;              oplot, [1,1]*kidpar[ikid].x_peak_azel, [1,1]*kidpar[ikid].y_peak_azel, psym=1, col=250, syms=2
;; ;             imview, myfit, xmap=grid_azel.xmap, ymap=grid_azel.ymap, position=pp1[3,*], /noerase, title='myfit'
;; ;             oplot, [1,1]*kidpar[ikid].x_peak_azel, [1,1]*kidpar[ikid].y_peak_azel, psym=1, col=250, syms=2
;;              ;; imview, kidmap-myfit, xmap=grid_azel.xmap, ymap=grid_azel.ymap, position=pp1[4,*], /noerase, title='myfit', $
;;              ;;         xra=kidpar[ikid].x_peak_azel+[-1,1]*50, yra=kidpar[ikid].y_peak_azel+[-1,1]*50
;;              ;; oplot, [1,1]*kidpar[ikid].x_peak_azel, [1,1]*kidpar[ikid].y_peak_azel, psym=1, col=250, syms=2
;;              my_multiplot, /reset
;;  
;;  
;;              stop
               kidpar[ikid].flux = params[1]
               ;; kidpar[ikid].corr2cm = params[1]
            endfor
         end
      
         keyword_set(aperture_phot):begin
            for i=0, nw1-1 do begin
               ikid   = w1[i]
               input_fwhm = !nika.fwhm_array[kidpar[ikid].array-1]
               map = reform( map_list_azel[ikid,*,*])
               nhits = reform( map_list_nhits_azel[ikid,*,*])
               d = sqrt( (grid_azel.xmap-kidpar[ikid].x_peak_azel)^2 + $
                         (grid_azel.ymap-kidpar[ikid].y_peak_azel)^2)
               bg_mask = long( d gt 3*input_fwhm)
               nk_bg_var_map, map, nhits, bg_mask, map_var
               bin_width = 10.
               noplot = 1
               
               radius_meas   = 150.d0 ; 5*input_fwhm
               radius_bg_min = 150.d0 ; 5*input_fwhm
               radius_bg_max = 300.d0 ; 10*input_fwhm
               ;message, /info, "fix me: set noplot back to 1"
               ;noplot=0
               ;erase
               aphot, map, map_var, grid_azel.xmap, grid_azel.ymap, grid_azel.map_reso, $
                      kidpar[ikid].x_peak_azel, kidpar[ikid].y_peak_azel, $
                      radius_meas, radius_bg_min, radius_bg_max, bin_width, input_fwhm, $
                      flux, err_flux, noplot=noplot
               ;stop
               ;wait, 0.2
               kidpar[ikid].flux = flux
               kidpar[ikid].peak_snr_nasmyth = flux/err_flux
            endfor
         end

         else:begin             ; standard gaussian fit with fixed fwhm photometry
            for i=0, nw1-1 do begin
               ikid = w1[i]
               d        = sqrt( (grid_nasmyth.xmap-kidpar[ikid].x_peak_nasmyth)^2 + (grid_nasmyth.ymap-kidpar[ikid].y_peak_nasmyth)^2)
               gauss_w8 = exp( -d^2/(2.d0*sigma_gauss^2))
               bg_mask = grid_nasmyth.xmap*0.d0
               nhits_nasmyth = reform( map_list_nhits_nasmyth[ikid,*,*], grid_nasmyth.nx, grid_nasmyth.ny)
               
               ;; Compute the background either on a ring around the
               ;; source or on the whole map far from
               ;; the source.
               if keyword_set(ata_fit_beam_rmax) then begin
                  wbg = where( d ge 4*!nika.fwhm_array[iarray-1] and $
                               nhits_nasmyth ne 0 and $
                               d le ata_fit_beam_rmax, nwbg)
                  wfit = where( d le ata_fit_beam_rmax and $
                                nhits_nasmyth ne 0, nwfit, compl=wnofit)
               endif else begin
                  wbg  = where( d ge 4*!nika.fwhm_array[iarray-1] and nhits_nasmyth ne 0, nwbg)
                  wfit = where( nhits_nasmyth ne 0, nwfit, compl=wnofit)
               endelse
               if nwbg eq 0 then begin
                  message, /info, "No valid pix to compute bg for ikid "+strtrim(ikid,2)
               endif else begin
                  bg_mask[wbg] = 1
                  kidmap     = reform( map_list_nasmyth[ikid,*,*])
                  nk_bg_var_map, kidmap, nhits_nasmyth, bg_mask, map_var
                  map_var[wnofit] = 0.d0
                  nk_ata_fit_beam, kidmap, map_var, gauss_w8, myinfo, flux, sigma_flux
                  kidpar[ikid].flux = flux
                  kidpar[ikid].peak_snr_nasmyth = flux/sigma_flux
                  if kidpar[ikid].flux le 0 then kidpar[ikid].type = 7
                  
                  ;; to try and see by how much fluxes differ
                  if keyword_set(plateau) then begin
                     error = sqrt(map_var)
                     np_fitplateau, reso, kidmap, error, coeff=coeff, best_fit=best_fit, $
                                    xmap=grid_nasmyth.xmap-kidpar[ikid].x_peak_nasmyth, $
                                    ymap=grid_nasmyth.ymap-kidpar[ikid].y_peak_nasmyth
                     kidpar[ikid].flux = coeff[1]
                  endif
               endelse
            endfor
         end
      endcase
   endif
   
endfor


;; w1 = where( kidpar.type eq 1)
;; yra = [0,1e4]
;; wind, 1, 1, /free, /large
;; !p.multi=[0,1,2]
;; plot, kidpar[w1].a_peak_nasmyth, yra=yra, /ys, /xs
;; oplot, kidpar[w1].flux, col=250
;; !p.multi=0
;; stop

;; Absolute calibration.
;; Extracted from $PIPE/nk_planet_calib.pro
kidpar.calib = 0.d0
kidpar.calib_fix_fwhm = 0.d0
for iarray=1, 3 do begin
   flux = input_flux_th[iarray-1]
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
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

;; Derive sensitivity
;; kidpar.sensitivity_decorr  = kidpar.calib * kidpar.noise * 1000 ; Jy/Hz x Hz/sqrt(Hz) x 1000 = mJy/sqrt(Hz) x 1
kidpar.sensitivity_decorr  = kidpar.calib_fix_fwhm * kidpar.noise * 1000
kidpar.sensitivity_decorr /= sqrt(2.d0) ; /Hz^1/2 to s^1/2

;; Get ready for katana_light and ktn_widget_light
save, file = maps_output_dir+'/map_lists_'+nickname+"_sub_"+strtrim(i_in,2)+".save", $
      map_list_azel, map_list_nasmyth, kidpar, $
      beam_list_azel, beam_list_nasmyth, grid_nasmyth, grid_azel, $
      map_list_nhits_azel, map_list_nhits_nasmyth
;      nhits_azel, nhits_nasmyth

;; Output kidpars in case it's the second iteration and we do
;; not need to go through Katana again
;; nk_write_kidpar, kidpar, kidpars_output_dir+"/kidpar_"+scan+"_raw_"+strtrim(i_in, 2)+".fits"
;; nk_write_kidpar, kidpar, kidpars_output_dir+"/kidpar_raw_"+strtrim(i_in, 2)+".fits"
nk_write_kidpar, kidpar, kidpars_output_dir+"/kidpar_"+nickname+"_"+strtrim(i_in, 2)+".fits"

end
