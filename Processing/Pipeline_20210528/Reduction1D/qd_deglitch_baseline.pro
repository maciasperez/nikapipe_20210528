;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: qd_deglitch_baseline
;
; CATEGORY: 1D processing
;
; CALLING SEQUENCE:
;         qd_deglitch, 
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
;        - NP: Jan 23rd, 2021: explicitely renamed old qd_deglitch.pro
;                              to distinguish with qd_deglitch_median.
;===========================================================================================================

pro qd_deglitch_baseline, data_in, width, nsigma, data_out, output_flag, $
                          fit_deg=fit_deg, input_flag=input_flag, deglitch_nsamples_margin=deglitch_nsamples_margin
;-

if n_params() lt 1 then begin
   dl_unix, 'qd_deglitch'
   return
endif

if not keyword_set(fit_deg) then fit_deg = 1
if not keyword_set(deglitch_nsamples_margin) then deglitch_nsamples_margin=0

nsn  = n_elements( data_in)
ind  = lindgen( nsn)
if keyword_set(input_flag) then flag = (input_flag < 1) else flag = intarr( nsn)
output_flag = intarr(nsn)

;; init
nglitch = 1
while nglitch ne 0 do begin
   ;; Iterate until no more glitches are found
   nglitch = 0
   x1      = 0

   ;; Look at chunks of data
   while x1 le (nsn-1) do begin
      x2 = (x1 + width-1) < (nsn-1)
      if x2 eq (nsn-1) then x1 = (x2-width+1)>0

      x                = dindgen( x2-x1+1)
      y                = data_in[    x1:x2]
      flag_temp        = flag[       x1:x2]
      output_flag_temp = output_flag[x1:x2]
      
      w = where( flag_temp eq 0, nw)
      if nw ge 3 then begin
         fit = poly_fit( x[w], y[w], fit_deg, yfit=baseline)
         
         ;; A glitch is defined as an outlyer at nsigma from the baseline estimated
         ;; on the valid data of the current chunk
         y_diff = y[w]-baseline
         s      = stddev(y_diff)
         ww      = where( abs( y_diff) gt nsigma*s and flag_temp eq 0, nww)
         if nww ne 0 then begin
            flag_temp[ww]        = 1
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
      endif else begin
         ;; not enough valid samples to do anything, leave it as is...
      endelse
      x1       = x2 + 1
   endwhile
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
      data_out = interpol( data_in[wgood], ind[wgood], ind)
   endif else begin
      message, /info, "No good samples for interpolation ?!"
      stop
   endelse
endif else begin
   data_out = data_in
endelse


end
