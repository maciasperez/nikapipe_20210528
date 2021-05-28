;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_wiener_filter
;
; CATEGORY: 
;        toi processing
;
; CALLING SEQUENCE:
;         nk_wiener_filter, param, info, data, kidpar
; 
; PURPOSE: 
;        Apply an extra filter based on the TOI spectrum
; 
; INPUT: 
;        - param, info, data, kidpar
; 
; OUTPUT: 
;        - data.toi is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 13th, 2018: NP
;-

pro nk_wiener_filter, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_wiener_filter, param, info, data, kidpar"
   return
endif

nt = n_elements(data)
n_mid = nt/2                    ; integer
ffreq = dblarr(nt)
ffreq[0:n_mid]   = dindgen(n_mid+1)
ffreq[n_mid+1:*] = -reverse( dindgen( nt-n_mid-1)+1)
ffreq = ffreq/(nt/!nika.f_sampling)

base_frac = round(!nika.f_sampling/n_elements(data))

if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 1, 1, /free, /large
my_multiplot, 2, 2, pp, pp1, /rev

for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      make_ct, nw1, ct

      nk_get_cm_sub_2, param, info, data.toi[w1], data.flag[w1], $
                       data.off_source[w1], kidpar[w1], atm_cm, $
                       w8_source=atm_w8_source

      signal = atm_cm - my_baseline(atm_cm, base_frac=0.05)
      power_spec, signal, !nika.f_sampling, pw, freq
      pw = reform(pw, n_elements(pw))
      w0 = where(freq gt param.wiener_freq_min)
      wh = where( freq gt param.wiener_white_noise_freq)
      ;; guess
      a = [avg(pw[wh]),1,1.5]
      r = curvefit( freq[w0], pw[w0], freq*0. + 1.d0, a, function_name="oneoverf", status=status)

      plot_oo, freq, pw, /xs, position=pp1[iarray-1,*], /noerase
      oplot, freq, r, col=250
      oplot, freq[w0], pw[w0], psym=1, col=200
      oplot, freq[wh], pw[wh], psym=1, col=200

      w0 = where( freq gt 0. and freq lt param.wiener_freq_min)
      fit = linfit( alog( freq[w0]), alog( pw[w0]))
      oplot, freq, exp(fit[0])*freq^fit[1], col=150



stop




      for i=0, nw1-1 do begin
         ikid = w1[i]

         signal = data.toi[ikid]-my_baseline(data.toi[ikid], base_frac=base_frac)
         power_spec, signal, !nika.f_sampling, pw, freq
         pw = reform(pw, n_elements(pw))
         w0 = where(freq gt param.wiener_freq_min)
         wh = where( freq gt 5)
         ;; guess
         a = [avg(pw[wh]),0.3, 2]
         r = curvefit( freq[w0], pw[w0], freq*0. + 1.d0, a, function_name="oneoverf", status=status)

         if i eq 0 then plot_oo, freq, pw, /xs, position=pp1[iarray-1,*], /noerase
         oplot, freq, pw, col=ct[i]

         if i eq (nw1-1) then oplot, freq, r, col=0, thick=2

         if status ne 0 then begin
            kidpar[ikid].type = 3
         endif else begin
            ;; Define the 1/f filter
            oneoverf, abs(ffreq), a, filter
            filter = 1./filter
            filter /= max(filter)
            ftsig = fft( signal, /double)
            ftsig = ftsig * filter
            signal_out = double( fft( ftsig, /inverse, /double))
            data.toi[ikid] = signal_out
         endelse

      endfor
   endif
endfor

stop

end
