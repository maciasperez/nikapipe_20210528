;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_clean_data
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

pro nk_clean_data, param, info, data, kidpar, out_temp_data=out_temp_data, $
                   input_cm_1mm=input_cm_1mm, input_cm_2mm=input_cm_2mm

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_clean_data, param, info, data, kidpar, out_temp_data=out_temp_data, $"
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
   if not param.plot_ps then wind, 1, 1, $
          /free, /xlarge, title = 'nk_clean_data', iconic = param.iconic
   my_multiplot, 2, 1, pp, pp1, /rev
   if param.plot_ps ne 0 then begin
      my_multiplot, 1, 2, pp_new, /rev
      pp[0,0,*] = pp_new[0,0,*]
      pp[1,0,*] = pp_new[0,1,*]
   endif
   outplot, file=param.plot_dir+"/toi_decor_1_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
   for lambda=1, 2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         ikid = w1[0]
         u = where( finite(data.toi[ikid]), nu)
         if nu ne 0 then begin
            plot, index, data.toi[ikid], /xs, position=pp[lambda-1,0,*], /noerase, thick=1, $
                  title=param.scan+" before decorrelation", ytitle='Jy/Beam'
            w = where( data.flag[ikid] eq 0, nw)
            if nw ne 0 then oplot, index[w], data[w].toi[ikid], col=150
            legendastro, ["!7k!3="+strtrim(lambda,2)+"mm", $
                          "Raw data", $
                          "ikid="+strtrim(ikid,2), $
                          "decor_method: "+strtrim(param.decor_method,2), $
                          "projected data"], box=0, textcol=[!p.color, !p.color, !p.color, !p.color, 150]
            power_spec, data.toi[ikid], !nika.f_sampling, pw, freq
            if lambda eq 1 then pw1 = pw
            if lambda eq 2 then pw2 = pw
         endif
      endif
   endfor
   outplot, /close
endif


if strupcase(param.decor_method) eq "MEDIAN_SIMPLE" then begin
;;   t0 = systime(0,/sec)
   speed = sqrt( deriv(data.ofs_az)^2+deriv(data.ofs_el)^2)*!nika.f_sampling
   med_speed = median(speed)
   n_median = round(2*max(!nika.fwhm_nom)/med_speed*!nika.f_sampling)
   for i =0, n_elements(kidpar)-1 do begin
      if kidpar[i].type eq 1 then begin
         data.toi[i] -= median(data.toi[i], n_median)
      endif
   endfor
;;    t1 = systime(0,/sec)
;;    message, /info, "t1-t0 = "+strtrim(t1-t0,2)

;;    ;; Compare speed with Fourier Transform and ~= filter
;;    freqlow = !nika.f_sampling/n_median ; TBC
;;    np_bandpass, data.toi[0], !nika.f_sampling, signal_out, $
;;                 filter=filter, freqlow=freqlow, freqhigh=freqhigh, $
;;                 delta_f=delta_f
;;    ft1 = fft( data.toi, dim=2)
;;    for i =0, n_elements(kidpar)-1 do begin
;;       if kidpar[i].type eq 1 then begin
;;          ft1[i,*] *= filter
;;       endif
;;    endfor
;;    toi2 = double( fft( ft1, /inv, dim=2))
;;    t2 = systime(0,/sec)
;;    message, /info, "t2-t1= "+strtrim(t2-t1,2)
;; 
;;    stop
endif else begin
   if strupcase(strtrim(param.decor_method, 2)) eq "NONE" then begin
      message, /info, "No decorrelation"
   endif else begin

;      message, /info, "fix me:"
;;      save, param, info, data, kidpar, file='data.save'
;;      ;; ;param.decor_per_subscan = 0
;      stop

;;       restore, "data.save"
;;       data_copy = data
;;       nk_init_grid, param, grid
;;       nk_default_mask, param, info, grid, dist=30
;stop
      nk_decor_4, param, info, data, kidpar, out_temp_data=out_temp_data, $
                  input_cm_1mm=input_cm_1mm, input_cm_2mm=input_cm_2mm

;;      nk_w8, param, info, data, kidpar
;;      nk_projection_3, param, info, data, kidpar, grid
;;      nk_display_maps, grid

   endelse
endelse

;message, /info, "fix me:"
;stop

;; Redeglitch, this time, toi by toi and before filtering
if param.fast_deglitch eq 1 then begin
   nk_deglitch_fast, param, info, data, kidpar
endif else begin
   nk_deglitch, param, info, data, kidpar
endelse

if param.line_filter ne 0 then nk_line_filter, param, info, data, kidpar

if param.bandpass ne 0 or param.polynomial ne 0 then begin
   if param.decor_per_subscan eq 1 then begin
      for i = min(data.subscan), max(data.subscan) do begin
         w = where(data.subscan eq i, nw)
         if nw eq 0 then begin
            nk_error, info, "No data for subscan "+strtrim(i,2)
            return
         endif else begin
            data1 = data[w]
            nk_filter, param, info, data1, kidpar
            data[w].toi = data1.toi
         endelse
      endfor
   endif else begin
      nk_filter, param, info, data, kidpar
   endelse
endif

if param.discard_outlying_samples eq 1 then begin
   for lambda=1, 2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         med   = median( data.toi[w1])
         sigma = stddev( data.toi[w1])
         w = where( abs( data.toi[w1]-med) gt 3*sigma, nw, compl=wkeep)

         ;; iterate on the determination of sigma
         med   = median( (data.toi[w1])[wkeep])
         sigma = stddev( (data.toi[w1])[wkeep])

;;          wind, 1, 1, /free
;;          plot,  data.toi[w1], psym=1, /ys
;;          oplot, data.toi[w1]*0. + med, col=70
;;          oplot, data.toi[w1]*0. + med + 6*sigma, col=150
;;          oplot, data.toi[w1]*0. + med - 6*sigma, col=150

         w = where( abs( data.toi[w1]-med) gt 6*sigma, nw)
         if nw ne 0 then begin
            junk = data.flag[w1]
            junk[w] = 1
            data.flag[w1] = junk
            junk=0
         endif

;;             ;; kill the entire subscan for a kid that shows outlyers
;;             for j=0, nw1-1 do begin
;;                ikid = w1[j]
;;                w = where( abs(data[wsubscan].toi[ikid]-med) gt 6*sigma, nw)
;;                if nw ne 0 then data[wsubscan].flag[ikid] = 1
;;             endfor

;;         endfor
      endif
   endfor
endif

if param.do_plot ne 0 then begin
loadct, 39, /silent

if not param.plot_ps then $
   wind, 1, 1, /free, /xlarge, title = 'nk_clean_data', iconic = param.iconic
   outplot, file=param.plot_dir+"/toi_decor_2_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
   for lambda=1, 2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         ikid = w1[0]
         ;;yra = minmax(data.toi[w1])
         yra = minmax( data.toi[w1]*long(data.flag[w1] eq 0))
         plot, index, data.toi[ikid], /xs, position=pp[lambda-1,0,*], /noerase, thick=2, $
               title=param.scan, ytitle='Jy/Beam', yra=yra, /ys
         w = where( data.flag[ikid] eq 0, nw)
         if nw ne 0 then oplot, [index[w]], [data[w].toi[ikid]], col=150
         legendastro, ["!7k!3="+strtrim(lambda,2)+"mm", $
                       "Clean data", $
                       "ikid="+strtrim(ikid,2), $
                       "decor_method: "+strtrim(param.decor_method,2), $
                       "projected data"], box=0, textcol=[!p.color, !p.color, !p.color, !p.color, 150]
         power_spec, data.toi[ikid], !nika.f_sampling, pw11, freq
      endif
   endfor
   outplot, /close

   if not param.plot_ps then $
      wind, 2, 2, /free, /xlarge, title = 'nk_clean_data', iconic = param.iconic
   outplot, file=param.plot_dir+"/power_spec_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
   loadct, 39, /silent
   for lambda=1,2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         ikid = w1[0]
         u = where( finite(data.toi[ikid]), nu)
         if nu ne 0 then begin
            power_spec, data.toi[ikid], !nika.f_sampling, pw11, freq
            if lambda eq 1 then begin
               plot_oo, freq, pw1, /xs, xtitle='Hx', ytitle='(Jy/Beam).Hz!u-1/2!n', position=pp[lambda-1,0,*], /noerase
            endif else begin
               plot_oo, freq, pw2, /xs, xtitle='Hx', ytitle='(Jy/Beam).Hz!u-1/2!n', position=pp[lambda-1,0,*], /noerase
            endelse
            oplot,   freq, pw11, col=250
            legendastro, ['Raw', 'Decorrelated'], line=0, col=[!p.color, 250], box=0, /right
            legendastro, [strtrim(lambda,2)+'mm'], /bottom
         endif
      endif
   endfor
   outplot, /close

;;    ;; Show all kids to check for outlyers
;;    if not param.plot_ps then wind, 1, 1, /free, /xlarge, title = 'nk_clean_data'
;;    outplot, file=param.plot_dir+"/toi_decor_3_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
;;    for lambda=1, 2 do begin
;;       nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
;;       if nw1 ne 0 then begin
;;          ikid = w1[0]
;;          ;;yra = minmax(data.toi[w1])
;;          yra = minmax( data.toi[w1]*long(data.flag[w1] eq 0))
;;          plot, index, data.toi[ikid], /xs, position=pp[lambda-1,0,*], /noerase, thick=2, $
;;                title=param.scan, /ys, psym=3, /nodata, yra = yra
;;          make_ct, nw1, ct
;;          for i = 0, nw1-1 do begin
;;             w = where( data.flag[w1[i]] eq 0, nw)
;;             if nw ne 0 then oplot, w, data[w].toi[w1[i]], psym=3, col=ct[i]
;; 
;;          endfor
;;          legendastro, ["!7k!3="+strtrim(lambda,2)+"mm", $
;;                        "Clean data: after decorrelation", $
;;                        "decor_method: "+strtrim(param.decor_method,2)], box = 0
;;       endif
;;    endfor
;;    outplot, /close
endif

if param.lf_sin_fit_n_harmonics ne 0 then nk_lf_sin_fit, param, info, data, kidpar

if param.cpu_time then nk_show_cpu_time, param, "nk_clean_data"

;;----------------------------------------------------------------------
;; Display all individual timelines (this plot takes time to appear, so
;; it's commented out by default)

if param.do_plot ne 0 and param.plot_ps eq 1 then begin
;   if param.plot_ps eq 0 then begin
   loadct, 39, /silent
;      wind, 1, 1, /free, /large, iconic = param.iconic
   nk_list_kids, kidpar, lambda=1, valid=w1, nval=nw1
   if nw1 ne 0 then begin
      outplot, file=param.plot_dir+"/all_tois_1mm_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
      my_multiplot, 1, 1, pp, pp1, /rev, ntot=nw1, /full
      for i=0, nw1-1 do begin
         ikid = w1[i]
         !p.charsize = 1e-10
         !x.charsize = 1e-10
         !y.charsize = 1e-10
         plot, data.toi[ikid], /xs, yra=minmax(data.toi[w1]), /ys, position=pp1[i,*], /noerase
         legendastro, strtrim(ikid,2), textcol=250, box=0, charsize=1
      endfor
      outplot, /close
   endif
   ;wind, 2, 2, /free, /large, iconic = param.iconic
   nk_list_kids, kidpar, lambda=2, valid=w1, nval=nw1
   if nw1 ne 0 then begin
      outplot, file=param.plot_dir+"/all_tois_2mm_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
      my_multiplot, 1, 1, pp, pp1, /rev, ntot=nw1, /full
      for i=0, nw1-1 do begin
         ikid = w1[i]
         !p.charsize = 1e-10
         !x.charsize = 1e-10
         !y.charsize = 1e-10
         plot, data.toi[ikid], /xs, yra=minmax(data.toi[w1]), /ys, position=pp1[i,*], /noerase
         legendastro, strtrim(ikid,2), textcol=250, box=0, charsize=1
      endfor
      outplot, /close
   endif
endif

end
