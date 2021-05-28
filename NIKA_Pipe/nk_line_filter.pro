
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_line_filter
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_line_filter, param, info, data, kidpar
; 
; PURPOSE: 
;        Detects strong noise lines and notch filter them out
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
;        - Nov. 25th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_line_filter, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_line_filter, param, info, data, kidpar"
   return
endif

;; sanity checks
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kids"
   return
endif

;; Define the frequency vector
ndata      = n_elements(data)        ;Number of points in the TOI
n2         = n_elements(data)/2
fr         = dindgen(n2+1)/double(n2) * !nika.f_sampling/2.0 ;Frequency
filter_pos = dblarr(n2) + 1
if ((ndata mod 2) eq 0) then begin
   fr=[fr, -1*reverse(fr[1:n2-1])]
   filter_neg = dblarr(n2-1) + 1
endif else begin
   fr=[fr, -1*reverse(fr[1:*])]
   filter_neg = dblarr(n2) + 1
endelse

df         = fr[1]-fr[0]
freq_width = round(param.line_filter_width/df)

;; Main loop
indice = lindgen(n2)                                            ;index des points
for i=0, nw1-1 do begin
   ikid = w1[i]

   ;;------- Compute the power spectrum
   power_spec, data.toi[ikid], !nika.f_sampling, spectre, f_spec

   ;; init
   if i eq 0 then ind_cut = long(param.line_filter_freq_start/max(f_spec)*n2) - 1
  
   ;;------- Flag the lines
   nflag        = 0                    ;nombre de points flagged
   x1           = ind_cut                 ;we start to check out at param.line_filter_freq_start
   spectre_loop = spectre
   while x1 le (n2-1) do begin
      x2 = (x1 + freq_width) < (n2-1)
      
      x = dindgen(x2-x1+1)
      y = spectre[x1:x2]
      
      loc_no_line = where(x eq x, nloc_no_line) ;first consider no line
      if nloc_no_line ge 4 then begin
         nitt = 5
         for iit=1, nitt do begin
            if nloc_no_line ge 2 then begin
               ;;------- Remove baseline
               error = dblarr(n_elements(x)) + 1e6
               error[loc_no_line] = 1
               fit = poly_fit(x, y, 2, yfit=baseline, measure_errors=error)
               ps_bl = y - baseline
               
               ;;------- Iterate away from potential lines
               sig_spec = stddev(ps_bl[loc_no_line])
               sig_spec = stddev(ps_bl[where(ps_bl le param.line_filter_nsigma * sig_spec)])
               loc_no_line = [where(ps_bl le 2*float(nitt)/float(iit) * sig_spec), nloc_no_line]
            endif
         endfor
         
         ;;------- Flag
         spectre_loop[x1:x2] = spectre_loop[x1:x2] - baseline
         flag_loop = where(spectre_loop gt param.line_filter_nsigma*sig_spec and indice ge x1 and indice le x2, nflag_loop)
         
         if (nflag_loop ne 0) then begin
            if nflag eq 0 then flag = flag_loop else flag = [flag, flag_loop]
         endif
         
         nflag = nflag + nflag_loop
      endif
      x1 = x2 +1
   endwhile
   
   ;; reset filter
   filter_pos = filter_pos*0.d0 + 1.d0
   filter_neg = filter_neg*0.d0 + 1.d0
   if nflag ne 0 then begin 
      filter_pos[flag] = 0 
      filter_neg[flag] = 0 
   endif
   
   filter_neg = reverse(filter_neg)  
   filter     = [1,filter_pos,filter_neg]
   
;;    ;;------- Low frequency filter
;;    if fc[0] ne 0 or fc[1] ne 0 then begin  
;;       z1 = where(abs(fr) lt fc[0])             ;low freq zone
;;       z2 = where(fr gt fc[0] and fr lt fc[1])  ;transition at positive low freq
;;       z3 = where(fr gt -fc[1] and fr lt -fc[0]) ;transition at negative low freq
;;       
;;       cosfilt = dblarr(ndata) + 1.0
;;       cosfilt[z1] = 0                                                ;cut low freq
;;       cosfilt[z2] = (sin((!pi/2.0) * (fr[z2]-fc[0])/(fc[1]-fc[0])))^2 ;cos^2 transition at positive low freq
;;       cosfilt[z3] = (cos((!pi/2.0) * (fr[z3]+fc[1])/(fc[1]-fc[0])))^2 ;cos^2 transition at negative low freq
;;    endif else begin
;;       cosfilt = 1
;;    endelse

   ;;------- Apply the filter and get filtered data
   ;;df_filt = fft(data,/double) * filter * cosfilt
   df_filt = fft(data.toi[ikid],/double) * filter
   dataclean = double(fft(df_filt,/double,/inv))

   ;;------- Case we want to check
   ;power_spec,dataclean,!nika.f_sampling,spectre_clean,f_spec
   ;plot_oo, f_spec,spectre, title="Numdet "+strtrim(kidpar[ikid].numdet,2)
   ;oplot, f_spec,spectre_clean,col=250
   ;stop
   
   data.toi[ikid] = dataclean
endfor


end
