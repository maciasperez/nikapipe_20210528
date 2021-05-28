;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_clean_data_3
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

pro nk_clean_data_3, param, info, data, kidpar, out_temp_data=out_temp_data, $
                     input_cm_1mm=input_cm_1mm, input_cm_2mm=input_cm_2mm

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
;      print, iarray, nw1
      if nw1 ne 0 then begin
         if !nika.ref_det[iarray-1] ne -1 then ikid = (where(kidpar.numdet eq !nika.ref_det[iarray-1]))[0] else ikid = w1[0]
         if ikid ne -1 then begin
            my_kid[iarray-1] = ikid
            my_toi[iarray-1,*] = data.toi[ikid]
         endif
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

;; @ Filter TOIs before the decorrelation if requested
if param.prefilter eq 1 then nk_prefilter, param, info, data, kidpar

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
;; print, "valid kids: ", n_elements(where(kidpar.type eq 1))
;; print, "total flag: ", total( data.flag)
;; print, "total off_source: ", total( data.off_source)
;; stop

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
if param.polynomial ne 0 then nk_polynomial_subtraction, param, info, data, kidpar

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
               ytitle='Jy/Beam', yra=yra, /ys, position=pp[0,iarray-1,*], /noerase, $
               charsize=0.8;, title=param.scan
         nika_title, info, /ut, /az, /el, /scan
         
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
         ;; Modif JUAN to avoid wrong reference pixel
         if ikid ge 0 then begin
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
         if param.do_plot ne 0 then nika_title, info, /all
      endif
   endfor
   outplot, /close
endif
my_multiplot, /reset

;; if param.lf_sin_fit_n_harmonics ne 0 then nk_lf_sin_fit, param, info, data, kidpar
if param.lf_sin_fit_n_harmonics ne 0 then begin
   for isubscan=min(data.subscan), max(data.subscan) do begin
      wsubscan = where( data.subscan eq isubscan, nwsubscan)
      if nwsubscan ne 0 then begin
         data1 = data[wsubscan]
         nk_lf_sin_fit, param, info, data1, kidpar
         data[wsubscan].toi = data1.toi
      endif
   endfor
endif


if param.cpu_time then nk_show_cpu_time, param

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
