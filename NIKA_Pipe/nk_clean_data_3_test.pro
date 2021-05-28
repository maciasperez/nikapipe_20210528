;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_clean_data_3_test
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_clean_data_3, param, info, data, kidpar
; 
; PURPOSE: 
;        Decorrelates kids, filters, estimates noise weights
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug. 1st, 2014: creation (Nicolas Ponthieu & Remi Adam)
;        - Apr. 8th, 2016: NP from nk_clean_data_2 to allow multiple or
;          successive decorrelations from various modes
;-

pro nk_clean_data_3_test, param, info, data, kidpar, out_temp_data=out_temp_data, $
                          input_cm_1mm=input_cm_1mm, input_cm_2mm=input_cm_2mm, subtract_maps=subtract_maps

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_clean_data_2, param, info, data, kidpar, out_temp_data=out_temp_data, $"
   print, "               input_cm_1mm=input_cm_1mm, input_cm_2mm=input_cm_2mm"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

nsn = n_elements(data)
if param.do_plot ne 0 then begin
   index = lindgen(nsn)
   my_toi = dblarr(3,nsn)
   my_kid = lonarr(3) -1
   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         ikid = w1[0]           ; default in case the ref det saturates and is discarded
         if !nika.ref_det[iarray-1] ne -1 then begin
            wjunk = where(kidpar.numdet eq !nika.ref_det[iarray-1] and kidpar.type eq 1, nwjunk)
            if nwjunk ne 0 then ikid = wjunk[0]
         endif
         my_kid[iarray-1] = ikid
         my_toi[iarray-1,*] = data.toi[ikid]
      endif
   endfor
endif

;; @ Discards the kids whose stddev is larger than 3 x the median stddev from
;; @^ the common mode estimation
;; update w1 definition
if param.lab eq 0 then begin
   for iarray=1, 3 do begin
      nn = 0
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;      wind, 1, 1, /ylarge
;;      !p.multi=[0,1,2]
;;      make_ct, nw1, ct
;;      plot, data.toi[w1[0]], /xs, /ys, yra=minmax(data.toi[w1]), title='Array '+strtrim(iarray,2)
;;      for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
      if nw1 ne 0 then begin
         sigma = fltarr(nw1)
         for i=0, nw1-1 do begin
            ikid = w1[i]
            woff = where( data.off_source[ikid] eq 1)
            sigma[i] = stddev( data[woff].toi[ikid])
         endfor
         noise_avg = avg( sigma)
         s_sigma = stddev( sigma)
         w = where( sigma ge (noise_avg+3*s_sigma), nw)
         if nw ne 0 then begin
            kidpar[w1[w]].type = 3
            if param.silent eq 0 then message, /info, "found "+strtrim(nw,2)+$
                                               " kids with too high noise in A"+strtrim(iarray,2)+" => not used nor projected"
         endif
      endif
;;       w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;       make_ct, nw1, ct
;;       plot, data.toi[w1[0]], /xs, /ys, yra=minmax(data.toi[w1])
;;       for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
;;       !p.multi=0
;;       stop
   endfor
endif
         

;; @ Performs decorrelation with {\tt nk_decor}.
if strupcase(param.decor_method) eq "MEDIAN_SIMPLE" then begin
   speed = sqrt( deriv(data.ofs_az)^2+deriv(data.ofs_el)^2)*!nika.f_sampling
   med_speed = median(speed)
   
   ;; n_median = round(4*max(!nika.fwhm_nom)/med_speed*!nika.f_sampling)
   n_median = round(param.median_simple_Nwidth*max(!nika.fwhm_nom)/med_speed*!nika.f_sampling)
   for i =0, n_elements(kidpar)-1 do begin
      if kidpar[i].type eq 1 then begin
         data.toi[i] -= median(data.toi[i], n_median)
      endif
   endfor
endif else begin

   if strupcase(strtrim(param.decor_method, 2)) eq "NONE" then begin
      message, /info, "No decorrelation"
   endif else begin
      case strupcase(param.decor_method) of

         "ITERATIVE_SN":begin
            nsn = n_elements(data)
            if info.polar ne 0 then begin
               out_temp_data = create_struct( "toi", data[0].toi, "toi_q", data[0].toi_q, "toi_u", data[0].toi_u)
            endif else begin
               out_temp_data = create_struct( "toi", data[0].toi)
            endelse
            out_temp_data = replicate( out_temp_data, nsn)

            ;; Discard kids that are too uncorrelated to the other ones
            if param.flag_uncorr_kid ne 0 then begin
               for i = 1, param.iterate_uncorr_kid do nk_flag_uncorr_kids, param, info, data, kidpar
            endif

            nk_maps2data_toi, param, info, data, kidpar, subtract_maps, toi_input_maps, $
                              output_toi_var_i=output_toi_var_i

            ;; decorrelate on the entire scan
            ;; nk_decor_sub_5, param, info, data, kidpar, out_temp_data=out_temp_data
            data.off_source  = 1.d0
            templates = dblarr(2,nsn)
            templates[0,*] = data.el
            for iarray=1, 3 do begin
               w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
               if nw1 ne 0 then begin
                  common_mode = dblarr(nsn)
                  cm_w8       = dblarr(nsn)
                  for i=0, nw1-1 do begin
                     ikid = w1[i]
                     w = where( output_toi_var_i[ikid,*] ne 0, nw)
                     w8 = dblarr(nsn)
                     w8map = dblarr(nsn)

                     sigma_toi = kidpar[ikid].noise*kidpar[ikid].calib_fix_fwhm*sqrt(!nika.f_sampling/2.)
                     w8map[w] = (toi_input_maps[ikid,w]/sqrt( output_toi_var_i[ikid,w]))^2
                     w8 = 1.d0/( sigma_toi*(1.d0 + param.iterative_offsets_k*w8map))

                     ;; common_mode += w8*data.toi[ikid]
                     common_mode += w8*(data.toi[ikid]-toi_input_maps[ikid,*])
                     cm_w8       += w8
                  endfor
                  common_mode /= cm_w8

                  templates[1,*] = common_mode
                  ;; Perform decorrelation
                  toi = data.toi[w1]-toi_input_maps[w1,*]
                  nk_subtract_templates_3, param, info, toi, data.flag[w1], data.off_source[w1], kidpar[w1], templates, out_temp
                  data.toi[w1] -= out_temp
               endif
            endfor
         end

         "SUCCESSIVE": begin
            ;; regress on all templates one at a time
            ;; subtract a common mode per array
            param1 = param
            param1.decor_method = "common_mode_kids_out"
            param1.decor_elevation = 1
            nk_decor_sub_5, param1, info, data, kidpar

            ;; subtract a common mode per acqbox (on the entire
            ;; scan, it's not subscan dependent)
            for ibox=min(kidpar.acqbox), max(kidpar.acqbox) do begin
               w1 = where( kidpar.acqbox eq ibox and kidpar.type eq 1, nw1)
               ;; nk_get_cm_sub_2, param, info, data.toi[w1], data.flag[w1], data.off_source[w1], kidpar[w1], common_mode
               off_source = data.off_source[w1]*0. + 1.d0 ; ignore mask for the moment
               nk_get_cm_sub_2, param, info, data.toi[w1], data.flag[w1], off_source, kidpar[w1], common_mode
               for i=0, nw1-1 do begin
                  ikid = w1[i]
                  ww = where( data.flag[ikid,*] eq 0, nww)
                  fit = linfit( common_mode[ww], data[ww].toi[ikid])
                  data.toi[ikid] -= (fit[0] + fit[1]*common_mode)
               endfor
            endfor

            ;; subtract a common mode per subband (on the
            ;; entire scan, it's not subscan dependent)
            subband = kidpar.numdet/80 ; int division on purpose
            nsubbands = max(subband)-min(subband)+1
            for iband=min(subband), max(subband)-1 do begin
               w1 = where( kidpar.numdet/80 eq iband and kidpar.type eq 1, nw1)
               ;;nk_get_cm_sub_2, param, info, data.toi[w1], data.flag[w1], data.off_source[w1], kidpar[w1], common_mode
               off_source = data.off_source[w1]*0. + 1.d0 ; ignore mask for the moment
               nk_get_cm_sub_2, param, info, data.toi[w1], data.flag[w1], off_source, kidpar[w1], common_mode
               for i=0, nw1-1 do begin
                  ikid = w1[i]
                  ww = where( data.flag[ikid] eq 0, nww)
                  fit = linfit( common_mode[ww], data[ww].toi[ikid])
                  data.toi[ikid] -= (fit[0] + fit[1]*common_mode)
               endfor
            endfor
         end

         "TRIPLE": begin
            ;; Regress on all templates at the same time
            ;; nk_decor_6, param, info, data, kidpar, out_temp_data=out_temp_data
            subband = kidpar.numdet/80 ; int division on purpose
            nsn = n_elements(data)
            templates = dblarr(4,nsn)
            templates[0,*] = data.el
            for iarray=1, 3 do begin
               w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)

               ;; Common mode per array and per scan
               nk_get_cm_sub_2, param, info, data.toi[w1], data.flag[w1], data.off_source[w1], kidpar[w1], common_mode_array
               templates[1,*] = common_mode_array

               ;; Common mode per acq box
               for ibox=min(kidpar[w1].acqbox), max(kidpar[w1].acqbox) do begin
                  w1box = where( kidpar.acqbox eq ibox and kidpar.type eq 1, nw1box)
                  if nw1box lt 2 then begin
                     txt = "less than 2 kids in acqbox "+strtrim(ibox,2)
                     nk_error, info, txt, status=2
                     data.flag[w1box] = 1 ; do not project this kid
                  endif else begin
                     off_source = data.off_source[w1box]*0. + 1.d0 ; ignore mask for the moment
                     nk_get_cm_sub_2, param, info, data.toi[w1box], data.flag[w1box], off_source, kidpar[w1box], common_mode_box
                     templates[2,*] = common_mode_box
                     
                     ;; Common mode per subband (on the entire
                     ;; scan, it's not subscan dependent)
                     for iband=min(subband[w1box]), max(subband[w1box]) do begin
                        w1band = where( kidpar.type eq 1 and subband eq iband, nw1band)
                        if nw1band lt 2 then begin
                           txt = "less than 2 kids in subband "+strtrim(iband,2)
                           nk_error, info, txt, status=2
                           data.flag[w1band] = 1 ; do not project this kid
                        endif else begin
                           off_source = data.off_source[w1band]*0. + 1.d0 ; ignore mask for the moment
                           nk_get_cm_sub_2, param, info, data.toi[w1band], data.flag[w1band], off_source, kidpar[w1band], common_mode_subband
                           templates[3,*] = common_mode_subband
                           
                           ;; Regress on all templates at the same time, off
                           ;; source.
                           toi = data.toi[w1band]
                           nk_subtract_templates_3, param, info, toi, data.flag[w1band], $
                                                    data.off_source[w1band], kidpar[w1band], templates
                           data.toi[w1band] = toi
                        endelse
                     endfor
                  endelse
               endfor
            endfor
         end
         
         "SUBBAND":begin
            subband = kidpar.numdet/80 ; int division on purpose
            nsn = n_elements(data)
            templates = dblarr(2,nsn)
            templates[0,*] = data.el
            for iband=min(subband), max(subband) do begin
               w1 = where( kidpar.type eq 1 and subband eq iband, nw1)
               if nw1 ne 0 then begin
                  nk_get_cm_sub_2, param, info, data.toi[w1], data.flag[w1], data.off_source[w1], kidpar[w1], common_mode
                  templates[1,*] = common_mode
                  
                  ;; Regress on all templates at the same time, off source.
                  toi = data.toi[w1]
                  nk_subtract_templates_3, param, info, toi, data.flag[w1], $
                                           data.off_source[w1], kidpar[w1], templates
                  data.toi[w1] = toi
               endif
            endfor
         end

         
         "CORR_MIN_1":begin
            ;; Use only kids that are correlated to more than param.corr_corr_min
            data.off_source = 1
            mcorr = correlate( data.toi)
            nk_decor_7, param, info, data, kidpar, out_temp_data=out_temp_data, mcorr=mcorr
         end
         
         "CORR_MIN_2":begin
            ;; Use only kids that are correlated to more than
            ;; param.corr_corr_min after a first global decorrelation
            ;; of a (Atmosphere dominated ?) common mode
            data.off_source = 1
            param1 = param
            param1.decor_method = 'common_mode'
            nk_decor_5, param1, info, data, kidpar, out_temp_data=out_temp_data

            mcorr = correlate( data.toi)
            nk_decor_7, param, info, data, kidpar, out_temp_data=out_temp_data, mcorr=mcorr
         end
         "COMMON_MODE_FOCUS": begin
;restore, file = '$SAVE/temp.save',/verb
            ;; param1 = param
            ;; param1.decor_method = 'common_mode'
            ;; param1.interpol_common_mode = 1
            ;; data1 = data
            ;; nk_decor_5, param1, info, data1, kidpar, out_temp_data=out_temp_data

            ;; mcorr = correlate( data1.toi)
;            stop
            nk_decor_8, param, info, data, kidpar, $
                        out_temp_data=out_temp_data
            
         end
         
         "RAW_MEDIAN":begin
            out_temp_data = create_struct( "toi", data[0].toi)
            out_temp_data = replicate( out_temp_data, nsn)
            for iarray=1, 3 do begin
               w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
               if nw1 ne 0 then begin
                  common_mode = median( data.toi[w1], dim=1)
                  ;; make_ct, nw1, ct
                  ;; wind, 1, 1, /free, /xlarge
                  ;; plot, data.toi[w1[0]], /xs, yra=minmax(data.toi[w1]), /ys
                  ;; for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
                  ;; oplot, common_mode

                  for i=0, nw1-1 do begin
                     ikid = w1[i]
                     fit = linfit( common_mode, data.toi[ikid])
                     data.toi[ikid] -= (fit[0] + fit[1]*common_mode)
                     out_temp_data.toi[ikid] = fit[0] + fit[1]*common_mode
                  endfor

               endif
            endfor
         end

         else:begin
            ;; decor_method has been defined in the old way
            nk_decor_5, param, info, data, kidpar, out_temp_data=out_temp_data, /keep_all
         end
      endcase
   endelse
endelse


;; Re-deglitch, this time, toi by toi and before filtering
if param.second_deglitch eq 1 then begin
   if param.fast_deglitch eq 1 then begin
      nk_deglitch_fast, param, info, data, kidpar
   endif else begin
      nk_deglitch, param, info, data, kidpar
   endelse
endif

if strupcase(param.decor_2_method) ne "NONE" then begin
   param1 = param
   param1.decor_method      = param.decor_2_method
   param1.decor_per_subscan = param.decor_2_per_subscan
   ;; out_temp_data is not ported here. To be done.
   nk_decor_5, param1, info, data, kidpar
endif

;; @ nk_line_filter notches filter noise lines if requested
if param.line_filter ne 0 then nk_line_filter, param, info, data, kidpar

;; @ nk_bandpass_filter fourier filters the data if requested
if param.bandpass ne 0 then nk_bandpass_filter, param, info, data, kidpar

;; @ nk_bandkill : excludes a band (inverse operation of bandpass) if requested
if param.bandkill ne 0 then nk_bandkill_filter, param, info, data, kidpar

;; @ {\tt nk_polynomial_subtraction} fits and subtracts a polynomial outside the source and per
;; @^ subscan if requested
;; @ NP, Dec. 6th, 2016: param.poynomial is now used in nk_decor_sub_5.
;; @ comment it out here to avoid redoing it
;; if param.polynomial ne 0 then nk_polynomial_subtraction, param, info, data, kidpar

;; if param.discard_outlying_samples eq 1 then begin
;;    for iarray=1, 3 do begin
;;       ;; nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
;;       w1 = where( kidpar.array eq 1 and kidpar.type eq 1, nw1)
;;       if nw1 ne 0 then begin
;;          med   = median( data.toi[w1])
;;          sigma = stddev( data.toi[w1])
;;          w = where( abs( data.toi[w1]-med) gt 3*sigma, nw, compl=wkeep)
;; 
;;          ;; iterate on the determination of sigma
;;          med   = median( (data.toi[w1])[wkeep])
;;          sigma = stddev( (data.toi[w1])[wkeep])
;; 
;;          w = where( abs( data.toi[w1]-med) gt 6*sigma, nw)
;;          if nw ne 0 then begin
;;             junk = data.flag[w1]
;;             junk[w] = 1
;;             data.flag[w1] = junk
;;             junk=0
;;          endif
;;       endif
;;    endfor
;; endif


if param.do_plot ne 0 then begin
   loadct, 39, /silent
   if not param.plot_ps then wind, 1, 1, /free, /large, $
                                   title = 'nk_clean_data_3', iconic = param.iconic

   outplot, file=param.plot_dir+"/toi_decor_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
   my_multiplot, 2, 3, pp, pp1, /rev
   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)     
      if nw1 ne 0 then begin
         ikid = my_kid[iarray-1]
         yra = minmax( my_toi[iarray-1,*] - my_toi[iarray-1,0])
         plot, index, my_toi[iarray-1,*]- my_toi[iarray-1,0], /xs, $
               title=param.scan, ytitle='Jy/Beam', yra=yra, /ys, position=pp[0,iarray-1,*], /noerase, $
               charsize=0.8
         oplot, index, data.toi[ikid]-data[0].toi[ikid], col=70
         w = where( data.flag[ikid] eq 0, nw)
         if nw ne 0 then oplot, [index[w]], [data[w].toi[ikid]-data[w[0]].toi[ikid]], col=150
         legendastro, ["Array "+strtrim(iarray,2)+", Numdet "+strtrim(kidpar[ikid].numdet,2), $
                       "raw data", $
                       "Clean data", $
                       "projected data", $
                       "decor_method: "+strtrim(param.decor_method,2)], $
                      box=0, textcol=[!p.color, !p.color, 70, 150, !p.color]
      endif      
   endfor

   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         ikid = my_kid[iarray-1]
         ;; Do not take the power spectrum of drops at the end of
         ;; scans when RF_DIDQ is not well computed and it has espaced
         ;; scan_valid (quick fix)
         w7 = nk_where_flag( data.flag[ikid], 7, compl=w)
         power_spec, my_toi[iarray-1,w], !nika.f_sampling, pw_raw, freq
         power_spec, data[w].toi[ikid],  !nika.f_sampling, pw
         yra = [min(pw)/10., max(pw_raw)*10.]
         plot_oo, freq, pw_raw, /xs, /ys, yra=yra, xtitle='Hz', $
                  ytitle='(Jy/Beam).Hz!u-1/2!n', position=pp[1,iarray-1,*], /noerase, $
                  charsize=0.8, ytickformat='exponent_noone'
         oplot, freq, pw, col=70
         legendastro, ['Raw', 'Decorrelated'], line=0, col=[!p.color, 70], box=0, /right
         legendastro, ['Array '+strtrim(iarray,2)], /bottom, box=0
      endif
   endfor
   outplot, /close
endif
my_multiplot, /reset

;; ;; if param.lf_sin_fit_n_harmonics ne 0 then nk_lf_sin_fit, param, info, data, kidpar
;; if param.lf_sin_fit_n_harmonics ne 0 then begin
;;    for isubscan=min(data.subscan), max(data.subscan) do begin
;;       wsubscan = where( data.subscan eq isubscan, nwsubscan)
;;       if nwsubscan ne 0 then begin
;;          data1 = data[wsubscan]
;;          nk_lf_sin_fit, param, info, data1, kidpar
;;          data[wsubscan].toi = data1.toi
;;       endif
;;    endfor
;; endif

if param.cpu_time then nk_show_cpu_time, param, "nk_clean_data_3"

;;----------------------------------------------------------------------
;; Display all individual timelines (this plot takes time to appear, so
;; it's commented out by default)

;; if param.do_plot ne 0 and param.plot_ps eq 1 then begin
;;    loadct, 39, /silent
;;    for iarray=1,3 do begin
;;       w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;       if nw1 ne 0 then begin
;;          outplot, file=param.plot_dir+"/all_tois_A"+strtrim(iarray,2)+"_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
;;          my_multiplot, 1, 1, pp, pp1, /rev, ntot=nw1, /full
;;          for i=0, nw1-1 do begin
;;             ikid = w1[i]
;;             !p.charsize = 1e-10
;;             !x.charsize = 1e-10
;;             !y.charsize = 1e-10
;;             plot, data.toi[ikid], /xs, yra=minmax(data.toi[w1]), /ys, position=pp1[i,*], /noerase
;;             legendastro, strtrim(ikid,2), textcol=250, box=0, charsize=1
;;          endfor
;;          outplot, /close
;;       endif
;;    endfor
;; endif

end
