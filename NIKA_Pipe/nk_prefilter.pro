;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_pre_filter
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_pre_filter, param, info, data, kidpar
; 
; PURPOSE: 
;        Subtracts a baseline and applies a fourier filter.
;        Can be used on raw data before the decorreation.
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
;-

pro nk_prefilter, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_prefilter, param, info, data, kidpar"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

;;-------------------------------
;; ;; Init filter
;; np_bandpass, data.toi[0], !nika.f_sampling, s_out, $
;;              freqlow =param.prefilter_freqlow, $
;;              freqhigh=param.prefilter_freqhigh, $
;;              filter=filter, delta_f=param.bandpass_delta_f
;; 
;; ;; take 1 sec on each edge to estimate the baseline
;; base_fraction = !nika.f_sampling/n_elements(data)
;; 
;; ;; Filter all kids
;; for ikid=0, n_elements(kidpar)-1 do begin
;;    if kidpar[ikid].type ne 2 then begin
;;       np_bandpass, data.toi[ikid] - $
;;                    my_baseline(data.toi[ikid], base_fraction=base_fraction), $
;;                    !nika.f_sampling, s_out, filter=filter
;;       data.toi[ikid] = s_out
;;       
;;       if info.polar ne 0 then begin
;;          np_bandpass, data.toi_q[ikid] - $
;;                       my_baseline(data.toi_q[ikid], base_fraction=base_fraction), $
;;                       !nika.f_sampling, s_out, filter=filter
;;          data.toi_q[ikid] = s_out
;;          np_bandpass, data.toi_u[ikid] - $
;;                       my_baseline(data.toi_u[ikid], base_fraction=base_fraction), $
;;                       !nika.f_sampling, s_out, filter=filter
;;          data.toi_u[ikid] = s_out
;;       endif
;;    endif
;; endfor
;;-------------------------------



base_frac = round(!nika.f_sampling/n_elements(data))
nsn = n_elements(data)
n_mid = nsn/2                    ; insneger
ffreq = dblarr(nsn)
ffreq[0:n_mid]   = dindgen(n_mid+1)
ffreq[n_mid+1:*] = -reverse( dindgen( nsn-n_mid-1)+1)
ffreq = ffreq/(nsn/!nika.f_sampling)

;; Compute the beam transfer function
scan_speed = median( sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2))*!nika.f_sampling

;; Fit the power spectrum of the common mode (all kids to be dominated
;; by the atmosphere)
for iarray=1, 3 do begin

   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      common_mode_1 = median( data.toi[w1], dim=1)
      common_mode   = dblarr(nsn)
      rms = dblarr(nw1)

      ;;1st subtraction to have a cleaner estimate of each KID's rms
      for i=0, nw1-1 do begin
         ikid = w1[i]
         fit = linfit( common_mode_1, data.toi[ikid])
         rms[i] = stddev(data.toi[ikid] - (fit[0]+fit[1]*common_mode_1))
      endfor

      ;; Improve on the common mode
      w8 = 0.d0
      for i=0, nw1-1 do begin
         ikid = w1[i]
         fit = linfit( data.toi[ikid], common_mode_1)
         common_mode += (fit[0] + fit[1]*data.toi[ikid])/rms[i]^2
         w8          += 1./rms[i]^2
      endfor
      common_mode /= w8

      ;; Determine the power spectrum of the (atm dominated) common mode
      power_spec, common_mode-my_baseline(common_mode,base_frac=base_frac), !nika.f_sampling, pw, freq
      pw = reform(pw, n_elements(pw))
;;      w0 = where(freq ne 0.)
;;      wh = where( freq gt 5)
;;      ;; guess
;;      a = [avg(pw[wh]),0.3, 2]
;;      r = curvefit( freq[w0], pw[w0], freq*0. + 1.d0, a, function_name="oneoverf")
;;      oneoverf, abs(ffreq), a, noise_fit
;;      filter = 1./noise_fit
;;      ;; normalize to 1 at high freq
;;      filter /= max(filter)

      ;; restrict to low frequency
      nu_k = 0.1
      wlf = where( freq le nu_k and freq gt 0.)
      whf = where( freq ge 5.d0)
      fit = linfit( alog(freq[wlf]), alog(pw[wlf]))
      lf_noise_fit = exp(fit[0])*abs(ffreq)^fit[1]

      ;; Beam filter
      if iarray eq 2 then fwhm = !nika.fwhm_nom[1] else fwhm = !nika.fwhm_nom[0]
      sigma_t = fwhm*!fwhm2sigma/scan_speed
      sigma_k = 1.0d0/(2.0d0*!dpi*sigma_t)
      beam_filter = exp(-ffreq^2/(2.*sigma_k^2))
    
;;      ;; Apply to the data
;;      for i=0, nw1-1 do begin
;;         ikid = w1[i]
;;         ftsig = fft( data.toi[ikid], /double)
;;         data.toi[ikid] = double( fft( filter*ftsig, /double, /inv))
;;      endfor

      ;; Apply to the data
;;      if iarray eq 2 then stop
      for i=0, nw1-1 do begin
         ikid = w1[i]
         ;; Adjust spectra to a kid
         power_spec, data.toi[ikid]-my_baseline(data.toi[ikid], base=base_frac), !nika.f_sampling, pwkid
 
         lf_model = abs(freq)^fit[1]
         lf_ampl = avg( pwkid[wlf])/avg( lf_model[wlf])
         noise_model = lf_ampl*abs(ffreq)^fit[1] + avg( pwkid[whf])

         ;; kid filter
         noise_filter = 1./noise_model
         noise_filter /= max(noise_filter)
         filter = beam_filter*noise_filter
 
;;         wind, 1, 1, /free, /xlarge
;;         plot_oo, freq, pw, /xs
;;         legendastro, ['data', 'common mode', 'beam_filter', 'Low freq fit on C. M.', $
;;                       'KID noise model', 'KID filter'], $
;;                      col=[100, 0, 150, 70, 40], line=0, /bottom
;;         oplot, abs(ffreq), lf_noise_fit, col=70, line=2
;;         oplot, abs(ffreq), beam_filter, col=150
;;         oplot, freq, pwkid, col=100
;;         oplot, freq, noise_model, col=40, thick=2
;;         oplot, freq, filter, col=250
;;         stop
         
         ftsig = fft( data.toi[ikid], /double)
         data.toi[ikid] = double( fft( filter*ftsig, /double, /inv))
      endfor
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param

end
