;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_scan_preproc_test
;
; CATEGORY:
; low level TOI processing
;
; CALLING SEQUENCE:
;         nk_scan_preproc, param, info, data, kidpar, grid, $
;                     sn_min=sn_min, sn_max=sn_max, $
;                     simpar=simpar, parity=parity,$
;                     prism=prism, force_file=force_file, $
;                     xml = xml, noerror = noerror, nas_center=nas_center, $
;                     list_detector=list_detector, polar=polar, katana=katana, $
;                     preproc_copy=preproc_copy, badkid=badkid, nosubtract_hwp=nosubtract_hwp
; 
; PURPOSE: 
;        low level processing of the data. Everything that goes after the raw
;data extraction in nk_getdata and that is not decorrelation or projection dependent.
; 
; INPUT: 
;        - param, info, data, kidpar, grid
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - NP
;-

pro nk_scan_preproc_test, param, info, data, kidpar, grid, $
                          sn_min=sn_min, sn_max=sn_max, $
                          simpar=simpar, parity=parity,$
                          prism=prism, force_file=force_file, $
                          xml = xml, noerror = noerror, nas_center=nas_center, $
                          list_detector=list_detector, polar=polar, katana=katana, $
                          preproc_copy=preproc_copy, badkid=badkid, nosubtract_hwp=nosubtract_hwp, $
                          astr=astr

if n_params() lt 1 then begin
;; --------- GDL modifications
   ;; message, info, "Calling sequence:"
   message, /info, "Calling sequence: "
   print, "nk_scan_preproc, param, info, data, kidpar, grid, $"
   print, "                 sn_min=sn_min, sn_max=sn_max, $"
   print, "                 simpar=simpar, parity=parity,$"
   print, "                 prism=prism, force_file=force_file, $"
   print, "                 xml = xml, noerror = noerror, nas_center=nas_center, $"
   print, "                 list_detector=list_detector, polar=polar, katana=katana, $"
   print, "                 preproc_copy=preproc_copy, badkid=badkid, nosubtract_hwp=nosubtract_hwp "
   return
endif

process = 1
if keyword_set(preproc_copy) then begin
   preproc_data_file = param.preproc_dir+"/data_"+strtrim(param.scan,2)+".save"
   if file_test(preproc_data_file) then begin
      process = 0
      restore, preproc_data_file
      info   = info_preproc
      kidpar = kidpar_preproc
      ;; param  = param_preproc
      ;; I keep the input param structure because some options may be
      ;; changed (in particular the filtering parameters...)
      ;; If new parameters such as deglitching options must be tested,
      ;; the preprocessing must be redone.
   endif
endif

if process eq 1 then begin
;; @ {\tt nk_getdata} reads the raw data and kid parameters, performs low level processing
   nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max,$
               prism=prism, force_file = force_file, $
               xml = xml, noerror = noerror, param_c=param_c, $
               list_detector=list_detector, katana=katana, polar=polar, $
               badkid=badkid

   if info.status eq 1 then return ; could not read the data

   if param.decimate ne 0 then begin
      index = lindgen(n_elements(data))
      w = where( index mod param.decimate eq 0)
      data = data[w]
   endif

;; In some simulations, we want to alternately add/subtract the data
;; from one scan. This is done via "parity"
   if keyword_set(parity) then data.toi = data.toi*parity

;;-----------------
;; test to debug:
   if keyword_set(nas_center) then begin
      message, /info, "This has been tested in check_geometry_and_offsets_v4 only"
      message, /info, "Make sure you have the right constant terms before going further"
      stop
      kidpar.nas_center_x =   4.d0 + info.nasmyth_offset_x
      kidpar.nas_center_y = -13.d0 + info.nasmyth_offset_y
   endif
;;-----------------

;; Compute individual kid pointing once for all
;; Needed here for simulations
   ;; @ {\tt nk_get_kid_pointing} computes the pointing of each kid
   ;; @^ based on data.ofs_az, data.ofs_el etc... and the Nasmyth
   ;; @^ offsets provided in the kidpar.
   if param.zigzag_correction eq 1 then begin
      nsn = n_elements(data)
      time = dindgen(nsn)/!nika.f_sampling

      ;; ;; The delay between NIKA2 and the telescope must be applied
      ;; ;; only to the a_t_uc which is the reference time and because,
      ;; ;; even if there's a time difference in utc between the
      ;; ;; different boxes, the *measurements* are all taken
      ;; ;; simultaneouly
      ;; ;; NP, Aug. 11th, 2016
      ;; w1 = where( kidpar.type eq 1, nw1)

      ;; Not so sure anymore... trying a zigzag per array util we
      ;; understand why (NP, Sept. 19, 2016)
      ofs_az = data.ofs_az
      ofs_el = data.ofs_el
      az     = data.az
      el     = data.el
      paral  = data.paral
      ;; avoid the loop to save time with interpol and
      ;; nk_get_kid_pointing
      if (!nika.zigzag[1] eq !nika.zigzag[0]) and $
         (!nika.zigzag[2] eq !nika.zigzag[0]) then begin
         w1 = where( kidpar.type eq 1, nw1)
         if nw1 ne 0 then begin
            time1 = time + !nika.zigzag[0]
            data.ofs_az = interpol( ofs_az, time, time1)
            data.ofs_el = interpol( ofs_el, time, time1)
            data.az     = interpol( az,     time, time1)
            data.el     = interpol( el,     time, time1)
            data.paral  = interpol( paral,  time, time1)
            nk_get_kid_pointing, param, info, data, kidpar
            
            data.dra[ w1] = data.dra[ w1]
            data.ddec[w1] = data.ddec[w1]
            nsnflag = round( !nika.zigzag[0]*!nika.f_sampling) > 1
            data[0:nsnflag-1].flag[w1]       += 1
            data[nsn-nsnflag:nsn-1].flag[w1] += 1
         endif
      endif else begin
         for iarray=1, 3 do begin
            w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
            if nw1 ne 0 then begin
               time1 = time + !nika.zigzag[iarray-1]
               data.ofs_az = interpol( ofs_az, time, time1)
               data.ofs_el = interpol( ofs_el, time, time1)
               data.az     = interpol( az,     time, time1)
               data.el     = interpol( el,     time, time1)
               data.paral  = interpol( paral,  time, time1)
               nk_get_kid_pointing, param, info, data, kidpar
               
               data.dra[ w1] = data.dra[ w1]
               data.ddec[w1] = data.ddec[w1]

               nsnflag = round( !nika.zigzag[iarray-1]*!nika.f_sampling) > 1
               data[0:nsnflag-1].flag[w1]       += 1
               data[nsn-nsnflag:nsn-1].flag[w1] += 1
            endif
         endfor
      endelse

   endif else begin
      nk_get_kid_pointing, param, info, data, kidpar
   endelse

;; Calibrate
   ;; @ {\tt nk_calibration} derives opacity correction and applies
   ;; @^ point source absolute calibration to the timelines. They will
   ;; @^ therefore be in Jy for the rest of the processing.
   nk_calibration, param, info, data, kidpar, simpar=simpar

;; At this stage, if the scan is polarized, toi_q and toi_u exist but
;; are all zero. There's no need to deglitch them and waste a
;; significant amount of time => force a temporary info to polar=0
   info1 = info
   info1.polar = 0
   ;; @ {\tt nk_deglitch} suppresses and interpolates cosmic rays
   if param.fast_deglitch eq 1 then begin
      nk_deglitch_fast, param, info1, data, kidpar
   endif else begin
      nk_deglitch, param, info1, data, kidpar
   endelse

   if param.jump_remove eq 1 then nk_remove_jumps, param, info, data, kidpar

   ;; @ If {\tt param.preproc_copy}==1, save data, kidpar etc... on
   ;; @^ disk to bypass this low level processing if this scan is reprocessed
   if keyword_set(preproc_copy) then begin
      param_preproc      = param
      kidpar_preproc     = kidpar
      info_preproc       = info
      save, param_preproc, info_preproc, data, kidpar_preproc, $
            file=param.preproc_dir+"/data_"+strtrim(param.scan,2)+".save"
      print, "saved "+param.preproc_dir+"/data_"+strtrim(param.scan,2)+".save"
   endif

endif                            ; process = 1

if info.polar ne 0 then nk_add_qu_to_grid, param, grid

;;---------------------------------------------------
;;------------------- Simulations -------------------
;;---------------------------------------------------
;;@ If keyword_set(simpar), data is modified according to simpar.
if keyword_set(simpar) then begin

   if simpar.quick_noise_sim eq 1 then begin
      nsn      = n_elements(data)
      nkids    = n_elements(kidpar)
      data.toi = reform( randomn( seed, nkids*nsn), nkids, nsn)
   endif else begin
      ;; Scientific data
      ;; @ {\tt nks_data} first simulates (or adds) scientific data timelines
      if keyword_set(prism) then begin
         nks_data_2beams, param, simpar, info, data, kidpar, grid
      endif else begin
         nks_data, param, simpar, info, data, kidpar
      endelse

      w1 = where( kidpar.type eq 1, nw1)
      
      ;; Instrumental noise
      ;;@ {\tt nks_add_uncorr_noise} adds noise that is uncorrelated
      ;;between detectors
      nks_add_uncorr_noise, param, simpar, info, data, kidpar

;;       ;;-----------------------------
;;       message, /info, "fix me:"
;;       ;; ensure correct random white noise, uniform over all detectors
;;       ;; to check how the noise averages down
;;       nsn = n_elements(data)
;;       w1 = where( kidpar.type eq 1, nw1)
;;       noise = randomn( seed, nw1*nsn)
;;       for i=0, nw1-1 do begin
;;          ikid = w1[i]
;;          data.toi[ikid] = noise[i*nsn:(i+1)*nsn-1]
;;       endfor
;;       ;;-----------------------------
   endelse
   
   ;; Simulate the effect a wrong offset in Nasmyth coordinates
   if simpar.nas_x_offset ne 0 then kidpar.nas_x += simpar.nas_x_offset
   if simpar.nas_y_offset ne 0 then kidpar.nas_y += simpar.nas_y_offset

   if simpar.nsample_ptg_shift ne 0 then begin
      ;; Simulate the effect of fixed time delay between the telescope
      ;; and NIKA
      nsn = n_elements(data)
      tags = ["ofs_az", "ofs_el", "el", "paral", "lst", "mjd"]
      for i=0, n_elements(tags)-1 do begin
         w = where( strupcase(tag_names(data)) eq strupcase(tags[i]), nw)
         if nw eq 0 then begin
            message, /info, "There's no "+tags[i]+" tag in the data structure"
            info.status = 1
            return
         endif else begin
            data.(w) = shift( data.(w), simpar.nsample_ptg_shift)
         endelse
      endfor
      nk_add_flag, data, 8, wsample=[lindgen(simpar.nsample_ptg_shift+1), $
                                     lindgen(simpar.nsample_ptg_shift+1)-simpar.nsample_ptg_shift-1+nsn]
   endif   
endif
;;---------------------------------------------------
;;---------------------------------------------------
;;---------------------------------------------------

;;----------------------------------------------------------------------------------------
;; Moved the remaining section of this code from nk_scan_reduce here because it
;; still is kid by kid processing, that the old /preproc option is no longer
;; used anymore and because we now process bunches of kids in a parallel mode on
;; nika2-a when reading the input files on several threads.
;; NP, Feb. 5th, 2016
;; @ Compute data.ipix to save time
;; nk_get_ipix, data, info, grid, astr=astr
nk_get_ipix, param, info, data, kidpar, grid, astr=astr

;; @ Define which parts of the maps must be masked for common mode estimation
;; info.mask_source must be 1 outside the source, 0 on source
nk_mask_source, param, info, data, kidpar, grid

;; Build fake lissajous subscans if requested
if strupcase(info.obs_type) eq "LISSAJOUS" and param.fake_lissajous_subscans eq 1 then begin
   nk_fake_lissajous_subscans, param, info, data, kidpar
endif

nsn = n_elements(data)

;;------------------------------------------------------------------------------
;; Comment out this section to try nk_iterative_offsets: NP & FXD, May 4th, 2016
;; ;; In principle, the input maps should be subtracted from the timelines before
;; ;; the HWP template removal, to improve on this too...
;; ;; This will be improved in the future. For now, I put it here, otherwise
;; ;; data_copy is not cleaned from the template or we have to do it twice.
;; ;; data_copy = data
;; if keyword_set(subtract_maps) then begin
;;    ;; toi's have already been calibrated in nk_scan_preproc, so we can
;;    ;; read directly the map and subtract it.
;;    ;;nk_subtract_maps, param, info, data, kidpar, subtract_maps
;;    nk_maps2data_toi, param, info, data, kidpar, subtract_maps, toi_input_maps
;;    data.toi -= toi_input_maps
;;    ;toi_input_maps = 0           ; save memory
;; endif
;;------------------------------------------------------------------------------

if keyword_set(nosubtract_hwp) then return

if info.polar ne 0 then begin

   ;; @ {\tt nk_deal_with_hwp_template} If this is a polarized scan, subtract HWPSS
   nk_deal_with_hwp_template, param, info, data, kidpar, y, y1

   ;; @ {\tt nk_lockin} If this is a polarized scan, perform Lockin to
   ;; reduce the number of samples and to build toi, toi_q, and toi_u
;   message, /info, "fix me: uncomment nk_lockin"
   nk_lockin, param, info, data, kidpar
;   stop
   
   if param.do_plot ne 0 and n_elements( y) gt 10 then begin
      power_spec, y-my_baseline(y), !nika.f_sampling, pw1, freq
      power_spec, y1-my_baseline(y1), !nika.f_sampling, pw,  freq
      w1 = where(kidpar.type eq 1)
      ikid = w1[0]
      power_spec, data.toi_q[ikid]-my_baseline(data.toi_q[ikid]), !nika.f_sampling, pw_q
      
      outplot, file=param.plot_dir+'/nika_polar_pw', ps=param.plot_ps, png=param.plot_png
      plot_oo, freq, pw1, /xs, xtitle='Hz', ytitle='Jy/Beam.Hz!u-1/2!n',thick=2
      oplot, freq, pw_q, col=70
      oplot, freq, pw, col = 250
      legendastro, ['Raw data', 'Raw data - HWP systematics', 'Q timeline'], col=[!p.color, 250, 70], box=0, /bottom, line=0
      outplot,/close
   endif
endif

;; if param.n_decor_freq_bands then begin
;;    message, /info, "n_decor_freq_bands ?!"
;;    stop
;;    for i=0, param.n_decor_freq_bands-1 do begin
;;       junk = execute( "freqmin  = param.decor_freq_low"+strtrim(i,2))
;;       junk = execute( "freqhigh = param.decor_freq_high"+strtrim(i,2))
;;       nk_band_freq_decor, param, info, data, kidpar, freqmin, freqhigh
;;    endfor
;; endif

;; if keyword_set(preproc_copy) then begin
;;    preproc_data_file = param.preproc_dir+"/data_"+strtrim(param.scan,2)+".save"
;;    save, param, info, data, kidpar, file=preproc_data_file
;; endif



end
