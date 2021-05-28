;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: qd_deglitch
;
; CATEGORY: 1D processing
;
; CALLING SEQUENCE:
;         qd_deglitch_median, 
; 
; PURPOSE: 
;        Detect, flags and interpolate cosmic ray induced glitches
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data_out: the deglitched timeline
;        - output_flag: intarray of the same size as data_out. 1 means a glitch
;          was found at the corresponding sample, 0 means ok.
; 
; KEYWORDS:
;        - fit_deg: the degree of the baseline polynomial (default 1)
;        - input_flag: array of the same size as data_in. 0 means OK, anything
;          else discards the corresponding sample.
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - NP. Jan 23rd, 2021: run a smooth median rather than fit a
;          baseline like qd_deglitch_baseline. Designed to be used on
;          common modes to remove faint glitches.
;===========================================================================================================

pro qd_deglitch_median, data_in, width, nsigma, data_out, output_flag, $
                        fit_deg=fit_deg, input_flag=input_flag, $
                        deglitch_nsamples_margin=deglitch_nsamples_margin, debug=debug
;-

if n_params() lt 1 then begin
   dl_unix, 'qd_deglitch'
   return
endif

nsn  = n_elements( data_in)
index  = lindgen( nsn)

if not keyword_set(fit_deg)                  then fit_deg = 1
if not keyword_set(deglitch_nsamples_margin) then deglitch_nsamples_margin=0
if keyword_set(input_flag) then flag = (input_flag < 1) else flag = intarr( nsn)
output_flag = intarr(nsn)

;; init
toi_copy = data_in
nglitch = 1
iter_glitch = -1
nsmooth = 10
while nglitch ne 0 do begin
   iter_glitch++
   ;; Iterate until no more glitches are found
   nglitch          = 0
   x1               = 0
   x2               = nsn-1
   x                = dindgen( x2-x1+1)
   y                = toi_copy[   x1:x2] ; data_in[    x1:x2]
   flag_temp        = flag[       x1:x2]
   output_flag_temp = output_flag[x1:x2]
      
;;      w = where( flag_temp eq 0, nw)
;;      if nw ge 3 then begin
;         fit = poly_fit( x[w], y[w], fit_deg, yfit=baseline)

   
   ;; 1/2 No keyword to leave the latest samples untouched and NOT bias
   ;; the baseline by some mirroring of the samples (in case of
   ;; significant drop, as happens on common modes)
   baseline = smooth( y, nsmooth) ; , /edge_mirr)

   ;; 2/2 Then use interpol to extrapolate baseline to the few nsmooth
   ;; points at the beginning and end of the timeline
   baseline = interpol( baseline[nsmooth:nsn-nsmooth], index[nsmooth:nsn-nsmooth], index)
   
   ;; A glitch is defined as an outlyer at nsigma from the baseline estimated
   ;; on the valid data of the current chunk
   ;; The ABS value allows also to get rid of negative glitches
   y_diff = y-baseline

   s      = stddev(y_diff)
   ww     = where( abs( y_diff) gt nsigma*s, nww, compl=wgood, ncompl=nwgood)
   
   if keyword_set(debug) then begin ; and x1 ge 7000 then begin
      wind, 1, 1, /free, /large
      my_multiplot, 1, 2, pp, pp1, /rev
;         xra = [7800,8200]
;         xra = [-100,400]
;         xra = [0,2000]
;      xra = [5000,7000]
      plot, y, /xs, position=pp1[0,*], xra=xra
      oplot, baseline, col=70
      if nww ne 0 then oplot, ww, y[ww], psym=1, col=250
      legendastro, ['TOI', 'Baseline', 'Glitch'], textcol=[0,150,70,250], /bottom
      legendastro, ['x1: '+strtrim(x1,2), $
                    'x2: '+strtrim(x2,2), $
                    'nglitches: '+strtrim(nww,2)]

      plot, y-baseline, /xs, /ys, position=pp1[1,*], /noerase, xra=xra
      oplot, [-1,1]*1d10, [0,0], col=70
      for i=-5, 5 do oplot, [-1,1]*1d10, [1,1]*i*s, line=2, col=70
      if nww ne 0 then oplot, ww, (y-baseline)[ww], psym=1, col=250, thick=2
      legendastro, ['TOI-Baseline', $
                    'Glitch', 'glitch iteration '+strtrim(iter_glitch,2)], textcol=[0,150,70,250]
      stop
   endif
   
   if nww ne 0 then begin
      toi_copy[        ww] = baseline[ww]
      flag_temp[       ww] = 1
      output_flag_temp[ww] = 1
      ;; take a few samples margin on each side to make sure
      for ii=-deglitch_nsamples_margin, deglitch_nsamples_margin do begin
         flag_temp[(ww+ii)>0]              = 1
         output_flag_temp[(ww+ii)>0]       = 1
         flag_temp[(ww+ii)<(nsn-1)]        = 1
         output_flag_temp[(ww+ii)<(nsn-1)] = 1
      endfor
   endif
   
   flag[       x1:x2] = flag_temp
   output_flag[x1:x2] = output_flag_temp
   
   nglitch += nww
endwhile

wflag = where( output_flag ne 0, nwflag)
if nwflag ne 0 then begin

;;    if nwflag gt 1 then begin
;;       ;; Keep only glitches that have no immediate neighbour to preserve planets
;;       for i=1, nwflag-1 do begin ; small loop
;;          if (wflag[i]-wflag[i-1]) eq 1 then begin
;;             output_flag[wflag[i  ]] = 0
;;             output_flag[wflag[i-1]] = 0
;;          endif
;;       endfor
;;    endif

   ;; Interpolate only glitches, not all flagged values
   ;; Rely on non-flagged values for the interpolation (flag contains glitch flags too)
   wgood = where( flag eq 0, nwgood)
   if nwgood ne 0 then begin
      ;; data_out = interpol( data_in[wgood], index[wgood], index)
      data_out = toi_copy ; interpolated by "baseline" (smooth)
   endif else begin
      message, /info, "No good samples for interpolation ?!"
      stop
   endelse
endif else begin
   data_out = data_in
endelse


end
