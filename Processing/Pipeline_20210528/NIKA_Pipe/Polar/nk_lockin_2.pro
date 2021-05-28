;+
;
; SOFTWARE: NIKA pipeline (polarization specific)
;
; NAME:
; nk_lockin_2
;
; CATEGORY:
;
; CALLING SEQUENCE:
;       nk_lockin_2, param, info, data, kidpar
; 
; PURPOSE: 
;        Updates toi_i, toi_q and toi_u, together with pointing and flag info
;        and reduces the number of samples.
; 
; INPUT: 
;        - param: the reduction parameters array of structures (one per scan)
;        - info: the array of information structure to be filled (one
;          per scan)
;        - data
;        - kidpar
; 
; OUTPUT: 
;        - data is resamples, data.toi now contains I timeline, data.toi_q and
;          data.toi_u are built
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct. 2017, NP: use array multiplications, faster than nk_lockin.pro
;=========================================================================================================

pro nk_lockin_2, param, info, data, kidpar
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_lockin_2'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements(data)

;; Change default def of lockin_freqhigh to minimize the
;; overlap between the I and Q bands. NP, Nov. 23rd, 2017
;;            if param.polar_lockin_freqhigh eq 0 then param.polar_lockin_freqhigh = info.hwp_rot_freq - 0.1

;; back to 2 x hwp_rot_freq to try, NP. Feb. 25th, 2020
;; 1.9 rather than 2 to avoid residuals at 2xomega sharp
if param.polar_lockin_freqhigh eq 0 then param.polar_lockin_freqhigh = 1.9d0*info.hwp_rot_freq

;; init filter
np_bandpass, dblarr(nsn), !nika.f_sampling, junk, $
             freqlow=param.polar_lockin_freqlow, $
             freqhigh=param.polar_lockin_freqhigh, $
             delta_f=param.polar_lockin_delta_f, filter=filter

;; check fft calling sequence
w1 = where( kidpar.type eq 1, nw1)

;; Expand filter
my_filter = filter##(dblarr(nw1)+1.d0)

;; Take care of A1 and A3 relative orientations
nkids = n_elements(kidpar)
pol_sign = dblarr(nkids) + 1.d0
w3 = where( kidpar.array eq 3, nw3)
if nw3 ne 0 then pol_sign[w3] = -1.d0

;; Subtract baseline
nsn_base = round( !nika.f_sampling)
y0 = median( data[0:nsn_base-1].toi[w1], dim=2)
y1 = median( data[nsn-nsn_base:*].toi[w1], dim=2)
x0 = double( median( indgen(nsn_base)))
x1 = double( median( indgen(nsn_base)+nsn-nsn_base))
slope = (y1-y0)/(x1-x0)
baseline = (dblarr(nsn)+1.d0)##y0 + ((dblarr(nsn)+1.d0)##slope) * (dindgen(nsn)##(dblarr(nw1)+1.d0))

if param.improve_lockin eq 1 then begin

   w1 = where( kidpar.type eq 1, nw1)
   nsn = n_elements(data)

   ;; Lowpass intensity to get rid of polarization and residuals of HWPSS
   freqhigh = 6.
   np_bandpass, dblarr(nsn), !nika.f_sampling, junk, $
                freqlow=0.d0, $
                freqhigh=freqhigh, $
                delta_f=0.2, filter=I_filter

   freqhigh = 6.
   np_bandpass, dblarr(nsn), !nika.f_sampling, junk, $
                freqlow = 0.d0, $
                freqhigh=freqhigh, $
                delta_f=0.2, filter=Pol_filter

   for i=0, nw1-1 do begin
      ikid = w1[i]
      baseline_i = baseline[i,*]
      np_bandpass, data.toi[ikid] - baseline_i, !nika.f_sampling, I_out, filter=I_filter
      Q_out = 2.d0*double( fft( fft( pol_sign[ikid]*(data.toi[ikid]-baseline_i-I_out)*data.cospolar,/double)*Pol_filter, /double, /inv))
      U_out = 2.d0*double( fft( fft( pol_sign[ikid]*(data.toi[ikid]-baseline_i-I_out)*data.sinpolar,/double)*Pol_filter, /double, /inv))

      
      data.toi[  ikid] = I_out
      data.toi_q[ikid] = Q_out
      data.toi_u[ikid] = U_out
   endfor

endif else begin

   if param.boxcar_smooth gt 0 then begin
;;       ;; NO baseline subtraction here, leave it for the decorrelation
;;       y  = data.toi[w1]
;;       yq = (y-baseline)*( data.cospolar##pol_sign[w1])
;;       yu = (y-baseline)*( data.sinpolar##pol_sign[w1])
;; 
;;       ;; Then take a single point per period => need to deal with flags
;;       ;; as well
;;       nsn = n_elements(data)
;;       for i=0, nw1-1 do begin
;;          ikid = w1[i]
;;          data.toi[  ikid] = reform( smooth( y[ i,*], param.boxcar_smooth), nsn)
;; ;      data.toi_q[ikid] = reform( smooth( yq[i,*], param.boxcar_smooth), nsn)
;; ;      data.toi_u[ikid] = reform( smooth( yu[i,*], param.boxcar_smooth), nsn)
;; 
;; ;;       yq = reform( y[i,*]-smooth(y[i,*], param.boxcar_smooth*2), nsn)*data.cospolar*pol_sign[w1[i]]
;; ;;       yu = reform( y[i,*]-smooth(y[i,*], param.boxcar_smooth*2), nsn)*data.sinpolar*pol_sign[w1[i]]
;; ;; ;;      data.toi_q[ikid] = reform( smooth( yq, param.boxcar_smooth), nsn)
;; ;; ;;      data.toi_u[ikid] = reform( smooth( yu, param.boxcar_smooth), nsn)
;; 
;; ;;       ftsig = fft( yq, /double)
;; ;;       data.toi_q[ikid] = 2.d0 * double( fft( ftsig*my_filter, /double, /inv))
;; ;;       ftsig = fft( yu, /double)
;; ;;       data.toi_u[ikid] = 2.d0 * double( fft( ftsig*my_filter, /double, /inv))
;;          ftsig = fft( yq[ikid,*], /double)
;;          data.toi_q[ikid] = reform( 2.d0 * double( fft( ftsig*my_filter[ikid,*], /double, /inv)))
;;          ftsig = fft( yu[ikid,*], /double)
;;          data.toi_u[ikid] = reform( 2.d0 * double( fft( ftsig*my_filter[ikid,*], /double, /inv)))
;; 
;; ;;       wind, 1, 1, /free
;; ;;       power_spec, data.toi_q[ikid], !nika.f_sampling, pw, freq
;; ;;       plot_oo, freq, pw, /xs
;; ;;       stop
;;          
;; ;;      ;; kills the distinction between the different types of flags
;; ;;      ;; for now... to improved later, but should make little difference
;; ;;      data.flag[ikid] = long( smooth( data.flag[ikid], param.boxcar_smooth) ne 0)
;;       endfor
;; 
;; ;;   ;; Keep only one sample per period
;; ;;   n_index = floor(nsn/double(param.boxcar_smooth))
;; ;;   ;; remove the last point...
;; ;;   n_index--
;; ;;   index = lindgen(n_index)
;; ;;   data = data[index*param.boxcar_smooth + param.boxcar_smooth/2]
;; ;;   !nika.f_sampling /= param.boxcar_smooth
;; 
;; ;   wind, 1, 1, /free
;; ;   plot, data.toi_q[w1[0]]
;; ;   stop

      
   endif else begin ; no boxcar

      y = data.toi[w1] - baseline
      ;; Lockin and lowpass
      if param.keep_one_hwp_position ge 1 then begin
;         if i eq 0 then print, 'Special TOI processing with hwp = ', param.keep_one_hwp_position
         ; special experimental treatment, not standard pipeline FXD
         data.toi[w1] = y
; don't touch I, but just demodulate to have Q and U
         data.toi_q[w1] = 2.d0*double( y*( data.cospolar##pol_sign[w1]))
         data.toi_u[w1] = 2.d0*double( y*( data.sinpolar##pol_sign[w1]))
      endif else begin  ; standard case
         ;; I
         ftsig = fft( y, /double, dimension=2)
         data.toi[w1] = double( fft( ftsig*my_filter, /double, /inv, dim=2))
         ;; Q
         ftsig = fft( y*( data.cospolar##pol_sign[w1]), /double, dim=2)
         data.toi_q[w1] = 2.d0 * double( fft( ftsig*my_filter, /double, /inv, dim=2))
         ;; U
         ftsig = fft( y*( data.sinpolar##pol_sign[w1]), /double, dim=2)
         data.toi_u[w1] = 2.d0 * double( fft( ftsig*my_filter, /double, /inv, dim=2))
      endelse
      
   endelse  ; end case of noboxcar
   
endelse ; end case of no improve lockin


if param.cpu_time then nk_show_cpu_time, param

end
