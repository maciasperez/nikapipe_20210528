
;;=====================================
;; KATANA: Kid Array Timelines ANAlysis
;;=====================================

pro katana, scan_num, day, source, lambda=lambda, in_param=in_param, png=png, ps=ps, in_retard=in_retard, $
            output_kidpar_fits=output_kidpar_fits, pf=pf, check_sn_range=check_sn_range, $
            all_kids=all_kids, force_file=force_file, lab=lab, corr_el=corr_el, corr_az=corr_az, $
            sn_min=sn_min, sn_max=sn_max, sanity_checks=sanity_checks, absurd=absurd, simul_polar=simul_polar, $
            polar=polar, no_acq_flag=no_acq_flag, input_kidpar_file=input_kidpar_file, $
            imbfits=imbfits, antimb=antimb, undersamp=undersamp, accidents=accidents, $
            switch_sign=switch_sign, xml=xml, holes=holes, fast=fast, list_detector=list_detector, $
            p2cor=p2cor, p7cor=p7cor, keep_all_kids=keep_all_kids, preproc_file=preproc_file, preproc_index=preproc_index

common ktn_common, $
   data, data_copy, kidpar, ks, dispmat, kquick, $
   toi, toi_med, w8, time, x_0, y_0, pw, freq, pw_raw, $
   disp, sys_info, pwc, sky_data, info, grid, $
   operations, param_c, param, units, grid_nasmyth, grid_azel


;; day2run, day, run
;; !nika.run = run
;; 
;; ;; To be sure that !nika.run won't enter any specific case of a run =< 5
;; !nika.run = !nika.run > 11

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+output_dir

if not keyword_set(preproc_file) then begin
;; Init param to be used in pipeline modules
   if keyword_set(in_param) then begin
      param = in_param
   endif else begin
      
      nk_default_param, param
      param.output_dir    = output_dir
      param.scan_num = scan_num
      param.day      = day
      param.scan     = strtrim(day,2)+"s"+strtrim(scan_num,2)

      param.math = "RF"         ; to save time
      param.do_plot=1
      param.flag_uncorr_kid = 0
      param.flag_sat = 0
      param.flag_oor = 0
      param.flag_ovlap = 0
   endelse

   if keyword_set(undersamp) then param.undersamp = undersamp
   if keyword_set(holes) then param.treat_data_holes = 1

   param.source = source
   param.fast_deglitch = 1

; ;; Get data
   if keyword_set(lambda) and long(!nika.run) le 12 then begin
      if lambda eq 1 then begin
         param.one_mm_only = 1
      endif else begin
         param.two_mm_only = 1
      endelse
   endif

   param.math = "RF"            ; to save time and be more robust with flags
   if keyword_set(pf) then param.math = "PF"

   nk_default_info, info
;;nk_update_scan_param, param.scan, param, info, /katana


   if param.lab eq 0 and not keyword_set(force_file) then nk_update_param_info, param.scan, param, info, xml=xml, /katana
   param.file_kidpar = ''       ; erase the default one put by update_scan_param

;   param.cpu_time = 1
   
;; Get the data and KID parameters
   nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max, $
               force_file=force_file, xml=xml, read_type=1, list_detector=list_detector, /katana


;; ;; Foce all kids to the same array to correct for errors in the init parameter
;; ;; files and the potential feedlines exchanges between one scan and another
;;kidpar.array = 1

   if keyword_set(switch_sign) then data.toi = -data.toi

   if keyword_set(accidents) then begin
      ;; correct accidental data, jumps etc...
      w1 = where( kidpar.type eq 1, nw1)
      nsn = n_elements(data)
      index = lindgen(nsn)

      for i=0, nw1-1 do begin
         ikid = w1[i]
         
         w = where( data.flag[ikid] eq 0, nw)
         if nw eq 0 then stop
         med = median( data[w].toi[ikid])
         sigma = stddev( data[w].toi[ikid]-med)
         ww = where( abs( data.toi[ikid]-med) gt 3*sigma, nww)
         if nww ne 0 then begin
            data[ww].flag[ikid] = 1
            wkeep = where( data.flag[ikid] eq 0)
            r = interpol( data[wkeep].toi[ikid], wkeep, index)
            data.toi[ikid] = r
         endif
      endfor
   endif

   sky_data = 1                 ; for ktn_reduce_map
   if param.lab then begin
      sky_data = 0
      data.el  = 0              ; !pi/4.

      ;; subscan boundaries
      w4 = where( data.scan_st eq 4, nw)
      message, /info, "N. scan_st eq 4: "+strtrim(nw,2)
      w5 = where( data.scan_st eq 5, nw)
      message, /info, "N. scan_st et 5: "+strtrim(nw,2)
      
      ;; Make sure previous cuts preserved w4[i]<w5[i] and update w4 and w5 in case
      ;; of cuts.
      data = data[min(w4):max(w5)]
   endif

;; Check the sample num range now to avoid bad surprises later
   if (not keyword_set(sn_min)) and (not keyword_set(sn_max)) and keyword_set(check_sn_range) then begin
      w1 = where( kidpar.type eq 1, nw1)
      make_ct, nw1, ct
      wind, 1, 1, /free, /large
      !p.multi=[0,1,2]
      plot, data.toi[w1[0]], /xs, yra=minmax( data.toi[w1]), /ys
      for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
      legendastro, ['Check the sample range, then pass sn_min and sn_max to KATANA', '', 'All valid kids'], box=0
      plot, data.toi[w1[0]], /xs, yra=minmax( data.toi[w1]), /ys
      oplot, data.toi[w1[0]], col=250, thick=2
      legendastro, 'Zoom on kid '+strtrim(kidpar[w1[0]].numdet,2), box=0
      !p.multi=0
      goto, ciao
   endif

;; ;; also discard bad subscans
;; w = where( data.subscan ne -1)
;; data = data[w]

;; Deglitch
;; nk_deglitch, param, info, data, kidpar
   nk_deglitch_fast, param, info, data, kidpar

;; Deal with template if polarization is present
   if info.polar ne 0 then begin

      ;; Determine HWP rotation speed
      nk_get_hwp_rot_freq, data, rot_freq_hz

      ;; Subtract template
                                ;param.polar.n_template_harmonics = 5
                                ;ktn_polar_widget
;   data_copy = data
      w1 = where( kidpar.type eq 1,  nw1)
      ikid = w1[0]
      y = data.toi[ikid]
      nsn = n_elements(data)
      nk_hwp_rm, param, kidpar, data

      loadct,  39
      if param.do_plot ne 0 then begin
         power_spec, y, !nika.f_sampling, pw, freq
         power_spec, data.toi[ikid], !nika.f_sampling, pw1, freq
         if param.plot_ps eq 0 then wind,  1,  1, /free, title = 'nk_scan_reduce'
         plot_oo, freq, pw, /xs, xtitle = 'Hz'
         oplot, freq, pw1, col = 250

         for i = 1, 10 do oplot, [i, i]*rot_freq_hz, [1e-10, 1e10], col = 70, line = 2
         legendastro, ["Numdet: "+strtrim(kidpar[ikid].numdet, 2), $
                       "Raw data",  $
                       "HWP rm"], textcol = [0, 0, 250], box = 0, chars = 2
      endif

      ;; Lockin to reduce the number of samples and to build toi, toi_q, and toi_u
      nk_lockin, param, info, data, kidpar
   endif

;;----------------
;;to debug lab tests
   if keyword_set(corr_el) then data.ofs_el = corr_el * data.ofs_el
   if keyword_set(corr_az) then data.ofs_az = corr_az * data.ofs_az
;;----------------

;; Need to center data.ofs_az and data.ofs_el for maps, at least approximately
;; This should not do anything for real observations since beam maps are
;; centered on ofs_az=0 and ofs_el=0
;; Commented out at the telescope, NP, Oct. 9th, 2015.
   if param.lab eq 1 then begin
      data.ofs_az -= avg( data.ofs_az)
      data.ofs_el -= avg( data.ofs_el)
   endif

   if keyword_set(p2cor) then data.ofs_az += p2cor
   if keyword_set(p7cor) then data.ofs_el += p7cor

;; Compute nasmyth coordinates
   azel2nasm, data.el, data.ofs_az, data.ofs_el, x_1, y_1
   data.ofs_nasx = x_1
   data.ofs_nasy = y_1

;; Save a copy of data for further restore
;; data_copy = data
   toi_ori = data.toi

;; Data cleaning (old median filter to get a first estimation of beam parameters
   speed = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling
   median_speed = median( speed)
   decor_median_width = long(10*20.*!fwhm2sigma/median_speed*!nika.f_sampling) ; 5 sigma on each side at about 35 arcsec/s
   w1 = where( kidpar.type eq 1, nw1)
   t0 = systime(0,/sec)
   print, "median filter..."
   for i=0, nw1-1 do begin
      ikid = w1[i]
      data.toi[ikid] -= median( data.toi[ikid], decor_median_width)
   endfor
   print, "... done."
   t1 = systime(0,/sec)
   print, "median filter cpu time: ", t1-t0

;; retrieve file and directory information
   file     = file_basename( param.data_file)
   dat_dir  = file_dirname(  param.data_file)

   l = strlen(file)
   if strmid( file, l-5) eq ".fits" then begin
      nickname = strmid( file, 0, l-5)
   endif else begin
      nickname = file
   endelse

;; Create or open comments file
   comments_file = param.output_dir+"/"+nickname+".txt"

;; Launch the map analysis and pixel selection
   ktn_prepare, file, dat_dir, comments_file, param.output_dir, $
                out_png=png, out_ps=ps, reso_map=param.map_reso, absurd=absurd, $
                input_kidpar_file=input_kidpar_file, fast=fast

;; Convenient output (see define_kidpar.pro)
   if not keyword_set(output_kidpar_fits) then output_kidpar_fits = "kidpar_"+sys_info.nickname+"_temp.fits"
   sys_info.output_kidpar_fits = output_kidpar_fits

   ktn_widget, no_block = no_block ;, /check_list

endif else begin
ktn_prepare_light, preproc_file, preproc_index
ktn_widget_light, preproc_index
endelse



;; if keyword_set(fast) then begin
;; 
;;    sys_info.png = 1
;; 
;; ;;    ;; 1st pass
;; ;;    ;; Force circular beam fit to get rid of the string
;; ;;    ;; only display purpose to check that all feedlines are ok
;; ;;    message, /info, '1st pass, circular beams...'
;; ;;    sys_info.plot_dir = sys_info.output_dir+"/fast_plots"
;; ;;    spawn, "mkdir -p "+sys_info.plot_dir
;; ;;    sys_info.beam_fit_method = 'MPFIT'
;; ;;    ktn_beam_calibration, /no_bolo_maps
;; ;;    ktn_plot_fp
;; 
;;    ;; 2nd pass, keep all kids, allow for ellipticity
;;    message, /info, '2nd pass, general beams...'
;;    sys_info.beam_fit_method = 'nika'
;;    sys_info.plot_dir = sys_info.output_dir+"/slow_plots"
;;    spawn, "mkdir -p "+sys_info.plot_dir
;; ;; ktn_beam_calibration alreay run in ktn_prepare
;; ;;   ktn_beam_calibration, /no_bolo_maps ; do not reproject maps to save time, just redo the beam fit
;; ;   ktn_noise_estim
;;    ktn_plot_fp
;;    ktn_beam_stats
;; 
;;    ;; 3rd pass, discard outlyers in fwhm, peak amplitude...
;;    message, /info, 'Discard outlyers'
;;    sys_info.plot_dir = sys_info.output_dir+"/slow_plots_noOutlyers"
;;    spawn, "mkdir -p "+sys_info.plot_dir
;;   if not keyword_set(keep_all_kids) then  ktn_discard_outlyers
;;    ktn_beam_stats
;;    ktn_plot_fp
;; ;   ktn_show_matrix
;;    
;; ;;   ;; save temporary kidpar
;; ;;   ktn_save_kidpar
;; 
;; ;;    ;; Kid maps and noise stats (decorr...)
;; ;;    ktn_otf_map_noise_2, toi_ori, /show_map
;;    
;;    ;; save kidtype and .txt summary files
;;    ktn_save_kidpar
;; 
;; endif else begin
;   ktn_plot_fp
;   ktn_widget, no_block = no_block ;, /check_list
;;endelse

message, /info, ""
message, /info, "KATANA finished."

ciao:
end
