;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_clean_data_2
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_clean_data, param, info, data, kidpar
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
;        - Aug. 1st, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_clean_data_2, param, info, data, kidpar, out_temp_data=out_temp_data, $
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

if param.do_plot ne 0 then begin
   index = lindgen(n_elements(data))
   if not param.plot_ps then $
      wind, 1, 1, /free, /xlarge, title = 'nk_clean_data', iconic = param.iconic
;;    my_multiplot, 3, 1, pp, pp1, /rev
    my_multiplot, 1, 3, pp, pp1, /rev
   if param.plot_ps ne 0 then begin
      my_multiplot, 1, 2, pp_new, /rev
      pp[0,0,*] = pp_new[0,0,*]
      pp[0,1,*] = pp_new[0,1,*]
   endif
   outplot, file=param.plot_dir+"/toi_decor_1_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         ikid = w1[0]
         plot, index, data.toi[ikid]-data[0].toi[ikid], /xs, position=pp[0,iarray-1,*], /noerase, thick=1, $
               title=param.scan+" before decorrelation", ytitle='Jy/Beam'
         w = where( data.flag[ikid] eq 0, nw)
         if nw gt 1 then $
            oplot, index[w], data[w].toi[ikid]-data[0].toi[ikid], col=150
         legendastro, ["Array "+strtrim(iarray,2), $
                       "Raw data", $
                       "ikid="+strtrim(ikid,2), $
                       "decor_method: "+strtrim(param.decor_method,2), $
                       "projected data"], box=0, textcol=[!p.color, !p.color, !p.color, !p.color, 150]
         ;; Do not take the power spectrum of drops at the end of
         ;; scans when RF_DIDQ is not well computed and it has escaped
         ;; scan_valid (quick fix)
         w7 = nk_where_flag( data.flag[ikid], 7, compl=w)
         power_spec, data[w].toi[ikid], !nika.f_sampling, pw, freq
         if iarray eq 1 then pw1 = pw & freq1 = freq
         if iarray eq 2 then pw2 = pw & freq2 = freq
         if iarray eq 3 then pw3 = pw & freq3 = freq
      endif
   endfor
   outplot, /close
endif

;; Decorrelation
if strupcase(param.decor_method) eq "MEDIAN_SIMPLE" then begin
   speed = sqrt( deriv(data.ofs_az)^2+deriv(data.ofs_el)^2)*!nika.f_sampling
   med_speed = median(speed)
;;Debug at the telescope by Alessia and Florian
;n_median = round(2*max(!nika.fwhm_nom)/med_speed*!nika.f_sampling)
   n_median = round(4*max(!nika.fwhm_nom)/med_speed*!nika.f_sampling)
   for i =0, n_elements(kidpar)-1 do begin
      if kidpar[i].type eq 1 then begin
         data.toi[i] -= median(data.toi[i], n_median)
      endif
   endfor
endif else begin
   if strupcase(strtrim(param.decor_method, 2)) eq "NONE" then begin
      message, /info, "No decorrelation"
   endif else begin
      nk_decor_5, param, info, data, kidpar, out_temp_data=out_temp_data
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

;; Notch filter noise lines if any
if param.line_filter ne 0 then nk_line_filter, param, info, data, kidpar

;; Bandpass
if param.bandpass ne 0 then nk_bandpass_filter, param, info, data, kidpar

;; Polynomial subtraction per subscan for now
if param.polynomial ne 0 then nk_polynomial_subtraction, param, info, data, kidpar

if param.discard_outlying_samples eq 1 then begin
   for iarray=1, 3 do begin
      ;; nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      w1 = where( kidpar.array eq 1 and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         med   = median( data.toi[w1])
         sigma = stddev( data.toi[w1])
         w = where( abs( data.toi[w1]-med) gt 3*sigma, nw, compl=wkeep)

         ;; iterate on the determination of sigma
         med   = median( (data.toi[w1])[wkeep])
         sigma = stddev( (data.toi[w1])[wkeep])

         w = where( abs( data.toi[w1]-med) gt 6*sigma, nw)
         if nw ne 0 then begin
            junk = data.flag[w1]
            junk[w] = 1
            data.flag[w1] = junk
            junk=0
         endif
      endif
   endfor
endif

if param.do_plot ne 0 then begin
   loadct, 39, /silent

   if not param.plot_ps then wind, 1, 1, /free, /large, $
                                   title = 'nk_clean_data', iconic = param.iconic

   outplot, file=param.plot_dir+"/toi_decor_2_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps

   !P.multi =  [0, 1, 3]
   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)     
      if nw1 ne 0 then begin
         ikid = w1[0]
                                ;yra = minmax( data.toi[w1]*long(data.flag[w1] eq 0))

         ;;We still have some very noisy KIDs. So the yrange is too big
         ;;if we consider all the KIDs --> we can't see if the
         ;;decorrelation is good
         yra = minmax( data.toi[ikid]*long(data.flag[ikid] eq 0))
         
                                ;plot, index, data.toi[ikid], /xs, position=pp[iarray-1,0,*], /noerase, thick=2, $
                                ;      title=param.scan, ytitle='Jy/Beam', yra=yra, /ys
         
         plot, index, data.toi[ikid], /xs, thick=2, $
               title=param.scan, ytitle='Jy/Beam', yra=yra, /ys
         
         w = where( data.flag[ikid] eq 0, nw)
         if nw ne 0 then oplot, [index[w]], [data[w].toi[ikid]], col=150
         legendastro, ["Array "+strtrim(iarray,2), $
                       "Clean data", $
                       "ikid="+strtrim(ikid,2), $
                       "decor_method: "+strtrim(param.decor_method,2), $
                       "projected data"], box=0, textcol=[!p.color, !p.color, !p.color, !p.color, 150]
      endif      
   endfor
   !P.multi =  0
   outplot, /close

   if not param.plot_ps then wind, 2, 2, /free, /large, $
                                   title = 'nk_clean_data_2', iconic = param.iconic
   outplot, file=param.plot_dir+"/power_spec_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
   loadct, 39, /silent
   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         ikid = w1[0]
         ;; Do not take the power spectrum of drops at the end of
         ;; scans when RF_DIDQ is not well computed and it has espaced
         ;; scan_valid (quick fix)
         w7 = nk_where_flag( data.flag[ikid], 7, compl=w)
         power_spec, data[w].toi[ikid], !nika.f_sampling, pw11, freq
         if iarray eq 1 then $
            plot_oo, freq1, pw1, /xs, xtitle='Hx', ytitle='(Jy/Beam).Hz!u-1/2!n', position=pp[0,iarray-1,*], /noerase
         if iarray eq 2 then $
            plot_oo, freq2, pw2, /xs, xtitle='Hx', ytitle='(Jy/Beam).Hz!u-1/2!n', position=pp[0,iarray-1,*], /noerase
         if iarray eq 3 then $
            plot_oo, freq3, pw3, /xs, xtitle='Hx', ytitle='(Jy/Beam).Hz!u-1/2!n', position=pp[0,iarray-1,*], /noerase

         oplot,   freq, pw11, col=250
         legendastro, ['Raw', 'Decorrelated'], line=0, col=[!p.color, 250], box=0, /right
         legendastro, ['Array '+strtrim(iarray,2)], /bottom
      endif
   endfor
   outplot, /close
endif

if param.lf_sin_fit_n_harmonics ne 0 then nk_lf_sin_fit, param, info, data, kidpar


if param.cpu_time then nk_show_cpu_time, param, "nk_clean_data_2"

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
