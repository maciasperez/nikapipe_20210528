;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_remove_data_holes
;
; CATEGORY: 1D processing
;
; CALLING SEQUENCE:
;         nk_remove_data, param, info, data, kidpar
; 
; PURPOSE: 
;        During Run9, some holes in the data create large jumps in the data.
;        this codes flags them out and remplaces these data by an interpolation.
; 
; INPUT: 
;        - data_in: data vector
;        - width: Number of samples that defines the window on which we look
;          for jumps
;        - nsigma: number of stddev of the data in the window used to detect a jump
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
;        - Oct. 12th, 2014: NP (from qd_deglitch)
;-
;===========================================================================================================

pro nk_remove_data_holes, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_remove_data_holes, param, info, data, kidpar"
   return
endif

width = round(param.hole_width_sec*!nika.f_sampling)


w1 = where(kidpar.type eq 1,  nw1)
nsn = n_elements(data)
;out_flag = intarr(nw1, nsn)

;; Detect holes on the average of valid kids
width = round(param.hole_width_sec*!nika.f_sampling)
toi_avg = avg( data.toi[w1], 0)
flag    = long(avg( data.flag[w1], 0) ne 0)
nk_remove_data_holes_sub, toi_avg, width, param.hole_nsigma, s_out, g_flag, $
                          fit_deg = fit_deg,  input_flag = flag

;; flag also before and after these jumps to make sure
flag1 = smooth( double(g_flag), width)
w = where(flag1 ne 0, nw)
if nw ne 0 then g_flag[w] = 1

;; Update data.flag with the detected missing data
w = where(g_flag ne 0,  nw, compl = wgood, ncompl = nwgood)
if nwgood eq 0 then begin
   message,  /info, "No valid pixels for interpolation"
   stop
endif else begin
   if nw ne 0 then nk_add_flag, data, 9, w

   index = dindgen(nsn)
   ;;Interpolate missing data
   for i = 0, nw1-1 do begin
      ikid = w1[i]
      s = interpol( data[wgood].toi[ikid], index[wgood], index)
      data.toi[ikid] = s
      ;plot,  data.toi[ikid], title = ikid
      ;oplot,  s,  col = 250
      ;stop
   endfor
endelse
   


end
