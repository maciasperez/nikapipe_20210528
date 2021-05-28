;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_clean_data_4
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_clean_data_4, param, info, data, kidpar
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
;        - April 16th, 2018: Cleaner version of nk_clean_data_3 and subroutines


pro nk_clean_data_4, param, info, data, kidpar, grid, $
                     out_temp_data=out_temp_data, $
                     input_cm_1mm=input_cm_1mm, input_cm_2mm=input_cm_2mm, $
                     out_coeffs=out_coeffs, snr_toi=snr_toi, Q=Q, U=U, $
                     hfnoise_w8=hfnoise_w8, datasub = datasub
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_clean_data_4'
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)
nsn = n_elements(data)

;; ;; If requested, keep a trace of the Kid to kid correlation matrix
;; ;; before data reduction
;; if param.save_toi_corr_matrix eq 1 then begin
;;    mcorr_init = correlate(data.toi)
;;    delvarx, pk_init
;;    nkids = n_elements(kidpar)
;;    for ikid=0, nkids-1 do begin
;;       if kidpar[ikid].type eq 1 then begin
;;          power_spec, data.toi[ikid]-my_baseline(data.toi[ikid],base=0.05), $
;;                      !nika.f_sampling, pw, freq
;;          if defined(pk_init) eq 0 then begin
;;             pk_init = dblarr(nkids, n_elements(freq))
;;          endif
;;          pk_init[ikid,*] = pw
;;       endif
;;    endfor
;;    save, kidpar, mcorr_init, pk_init, freq, file=param.output_dir+'/toi_corr_matrix_and_pk_init.save'
;; endif

;; Prepare plots
if param.do_plot ne 0 then prepare_clean_data_plots, param, info, data, kidpar, index, my_toi, my_kid

;; @ Discard the noisiest kids from the common mode estimation,
if param.lab eq 0 and param.discard_noisy_kids gt 0 $   ; FXD 23/9/2020 added the option of not using that
   then nk_discard_noisy_kids, param, info, data, kidpar

;; @ Apply a Wiener filter to the TOI's before decorrelation if requested
if param.pre_wiener ne 0 then nk_wiener_filter, param, info, data, kidpar

;; @ Filter TOIs before the decorrelation if requested
if param.prefilter eq 1 then nk_prefilter, param, info, data, kidpar

;; @ Peform the decorrelation according to param.decor_method
out_temp_data = create_struct( "toi", data[0].toi*0.d0)
out_temp_data = replicate( out_temp_data, nsn)

case strupcase(param.decor_method) of
   "NONE": begin
      message, /info, "decorr. method = NONE, so I pass"
   end
   
   "FOURIER": message, /info, "decorr. method = FOURIER, so I pass"
   
   "MEDIAN_SIMPLE": begin
      speed = sqrt( deriv(data.ofs_az)^2+deriv(data.ofs_el)^2)*!nika.f_sampling
      med_speed = median(speed)
      n_median = round(param.median_simple_Nwidth*max(!nika.fwhm_nom)/med_speed*!nika.f_sampling)
      for i =0, n_elements(kidpar)-1 do begin
         if kidpar[i].type eq 1 then begin
            ;; EA and LP: uncomment the line below : data.toi = residuals
            data.toi[i] -= median(data.toi[i], n_median)
            out_temp_data.toi[i] = median( data.toi[i], n_median)
         endif
      endfor
   end
   
   "RAW_MEDIAN":begin
      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            common_mode = median( data.toi[w1], dim=1)
            for i=0, nw1-1 do begin
               ikid = w1[i]
               w = where( data.off_source[ikid] eq 1, nw)
               if nw gt 100 then begin
                  fit = linfit( common_mode[w], data[w].toi[ikid])
               endif else begin
                  fit = linfit( common_mode, data.toi[ikid])
               endelse
               ;; EA and LP: uncomment the line below : data.toi = residuals
               data.toi[ikid] -= (fit[0] + fit[1]*common_mode)
               out_temp_data.toi[ikid] = fit[0] + fit[1]*common_mode
            endfor
         endif
      endfor
   end

   "RING_MEDIAN":begin
;      save, param, info, data, kidpar, grid, file='data.save'
;stop
      if defined(snr_toi) then w8_source = 1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2) else delvarx, w8_source

      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            for i=0, nw1-1 do begin
               ikid = w1[i]
               
               ;; from nk_get_median_common_mode
               d = sqrt( (kidpar[ikid].nas_x-kidpar.nas_x)^2 + (kidpar[ikid].nas_y-kidpar.nas_y)^2)
               wkids = where( d ge param.dist_min_between_kids and d le param.dist_max_between_kids and $
                              kidpar.numdet ne kidpar[ikid].numdet, nwkids)
               if nwkids eq 0 then begin
                  data.flag[ikid] = 2L^7
               endif else begin
                  
                  for isub=min(data.subscan), max(data.subscan) do begin
                     wsub = where( data.subscan eq isub, nwsub)
                     if nwsub ne 0 then begin

                        toi_copy = data[wsub].toi[wkids]
                        w = where( data[wsub].off_source[wkids] eq 0 OR data[wsub].flag[wkids] ne 0, nw)
                        if nw ne 0 then toi_copy[w] = !values.d_nan
                        toi_med = (dblarr(nwsub)+1)##median( toi_copy, dim=2)
                        toi_copy = data[wsub].toi[wkids] - toi_med

                        ;; /!\ No SNR w8 accounted for at this stage... ?! TBC
                        common_mode = median( toi_copy, dim=1)

                        toi        = data[wsub].toi[ikid]
                        flag       = data[wsub].flag[ikid]
                        off_source = data[wsub].off_source[ikid]

                        wsample = where( finite(toi) eq 1 and flag eq 0 and off_source eq 1, nwsample)

                        if defined(w8_source) then begin
                           measure_errors = reform( sqrt( 1.d0/w8_source[ikid,wsub]))
                           measure_errors = measure_errors[wsample]
                        endif else begin
                           delvarx, measure_errors
                        endelse

                        if nwsample ge param.nsample_min_per_subscan then begin
                           coeff = regress( common_mode[wsample], toi[wsample], $
                                            CHISQ= chi, CONST= const, CORRELATION= corr, measure_errors=measure_errors, $
                                            /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)

                           if status eq 0 then begin
                              ;; Subtract the templates everywhere
                              yfit = const + common_mode##coeff
                              ;; EA and LP: add the line below : data.toi = residuals
                              data[wsub].toi[ikid] -= yfit[*]
                              out_temp_data[wsub].toi[ikid] = yfit[*]
                              ;; wind, 1, 1, /free
                              ;; plot, toi, /xs
                              ;; oplot, yfit, col=250
                              ;; stop
                           endif
                        endif else begin
                           data[wsub].flag[ikid] = 2L^7
                        endelse
                     endif
                  endfor
               endelse
            endfor
         endif
      endfor
   end

   "MASK_CONTINUOUS": begin
      ;;-------------------------------------------------------------
      ;; ;; work on continuous sections : does not work yet
      ;; nk_decor_7, param, info, data, kidpar, grid, out_temp_data
      ;;-------------------------------------------------------------

      nk_decor_8, param, info, data, kidpar, grid, out_temp_data
      
   end
   
   else: nk_decor_6, param, info, data, kidpar, grid, out_temp_data, $
                     out_coeffs=out_coeffs, snr_toi=snr_toi, Q=Q, U=U, $
                     hfnoise_w8=hfnoise_w8, datasub = datasub
endcase


if param.do_plot ne 0 then begin
   loadct, 39, /silent

   if !nika.plot_window[1] le 0 then begin
      if (not param.plot_ps) and (not param.plot_z) then begin
         wind, 1, 1, /free, /large, $
               title = 'nk_clean_data_4', iconic = param.iconic
      endif
      my_multiplot, 2, 3, pp, pp1, /rev
   endif else begin
      if info.polar eq 0 then begin
         if (not param.plot_ps) and (not param.plot_z) then begin
            wind, 1, 1, /free, /large
            !nika.plot_window[1] = !d.window
            my_multiplot, 2, 3, pp, pp1, /rev
         endif
      endif else begin
         my_multiplot, 2, 3, pp, pp1, xmargin=0.01, $
                       xmin=0.55, xmax=0.95, gap_x=0.02, gap_y=1d-6, /rev
         ycharsize=0.6
      endelse
   endelse

   outplot, file=param.plot_dir+"/toi_decor_"+strtrim(param.scan), $
            png=param.plot_png, ps=param.plot_ps, zbuffer=param.plot_z

   ;; my_toi = originale TOI subtracted from the map in the source
   ;; mask ( = correlated noise TOI estimate)
   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)     
      if nw1 ne 0 then begin
         ikid = my_kid[iarray-1]
;;         yra = minmax( my_toi[iarray-1,*] - my_toi[iarray-1,0])
         yra = array2range(my_toi[iarray-1,*] - avg(my_toi[iarray-1,*]))
         if iarray eq 3 then xcharsize=0.6 else xcharsize=1d-10
         plot, index, my_toi[iarray-1,*]- avg(my_toi[iarray-1,*]), /xs, $
               ytitle='Jy/Beam', yra=yra, /ys, position=pp[0,iarray-1,*], /noerase, $
               xcharsize=xcharsize, ycharsize=ycharsize
         oplot, index, my_toi[iarray-1,*]- avg(my_toi[iarray-1,*]), col=70
         if iarray eq 1 then nika_title, info, /all

         ;; oplot, index, data.toi[ikid]-data[0].toi[ikid], col=200
         ;; EA and LP: modify the line below : data.toi = residuals
         ;;oplot, index, data.toi[ikid]-out_temp_data.toi[ikid], col=200
         oplot, index, data.toi[ikid], col=200
         w = where( data.flag[ikid] eq 0, nw)
;         if nw ne 0 then oplot, [index[w]],
;         [data[w].toi[ikid]-data[w[0]].toi[ikid]], col=150
         ;; EA and LP: modify the line below : data.toi = residuals
         ;;if nw ne 0 then oplot, [index[w]], [data[w].toi[ikid]-out_temp_data[w].toi[ikid]], col=150
         if nw ne 0 then oplot, [index[w]], [data[w].toi[ikid]], col=150
         legendastro, ["Array "+strtrim(iarray,2)+", Numdet "+strtrim(kidpar[ikid].numdet,2), $
                       "raw data", $
                       "Clean data", $
                       "projected data", $
                       "decor_method: "+strtrim(param.decor_method,2)], $
                      box=0, textcol=[!p.color, 70, 200, 150, !p.color]
      endif      
   endfor

   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         ikid = my_kid[iarray-1]
         ;; Do not take the power spectrum of drops at the end of
         ;; scans when RF_DIDQ is not well computed and it has espaced
         ;; scan_valid (quick fix)
         ;; Modif JUAN to avoid wrong reference pixel
         if ikid ge 0 then begin
         w7 = nk_where_flag( data.flag[ikid], 7, compl=w)
         power_spec, my_toi[iarray-1,w]-my_baseline(my_toi[iarray-1,w],b=0.05), !nika.f_sampling, pw_raw, freq
         ;; EA and LP: modify the line below : data.toi = residuals
         ;;power_spec, data[w].toi[ikid]-out_temp_data[w].toi[ikid], !nika.f_sampling, pw
         power_spec, data[w].toi[ikid],  !nika.f_sampling, pw
         yra = [min(pw)/10., max(pw_raw)*10.]

         if iarray eq 3 then xcharsize=0.6 else xcharsize=1d-10
         plot_oo, freq, pw_raw, /xs, /ys, yra=yra, xtitle='Hz', $
                  position=pp[1,iarray-1,*], /noerase, $
                  xcharsize=xcharsize, ytickformat='exponent_noone'
         oplot, freq, pw_raw, col=70

         beam_tf_ampl = 100*avg(pw_raw[where(freq ge 4)])
         f = dindgen(1000)/999*(max(freq)-min(freq)) + min(freq)
         sigma_t = !nika.fwhm_array[iarray-1]*!fwhm2sigma/info.median_scan_speed
         sigma_f = 1.0d0/(2.0d0*!dpi*sigma_t)
         oplot, f, beam_tf_ampl*exp(-f^2/(2.0d0*sigma_f^2)), line=2
         
         if iarray eq 1 then nika_title, info, /all
         oplot, freq, pw, col=150
         legendastro, ['A'+strtrim(iarray,2), 'Raw', 'Decorr (I) Projected'], $
                      col=[!p.color, 70, 150], box=0, /right
         xy0 = convert_coord( min(freq), yra[0], /data, /to_device)
         xy1 = convert_coord( max(freq), yra[1], /data, /to_device)
         xt  = xy0[0] + 0.05*(xy1[0]-xy0[0])
         yt  = xy0[1] + 0.10*(xy1[1]-xy0[1])
         xyouts, xt, yt, '(Jy/beam).Hz!u-1/2!n', orient=90, chars=charsize, /device
         endif

      endif
   endfor
   outplot, /close, /verb
endif
my_multiplot, /reset

if param.cpu_time then nk_show_cpu_time, param

;;----------------------------------------------------------------------
;; Display all individual timelines (this plot takes time to show up, so
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
