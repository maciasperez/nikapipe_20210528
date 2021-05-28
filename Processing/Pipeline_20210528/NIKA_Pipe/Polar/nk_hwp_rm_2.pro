
;+
;
; SOFTWARE:
;; NIKA pipeline / Polarization
;
; NAME: 
; nk_hwp_rm_2
;
; CATEGORY:
;
; CALLING SEQUENCE:
;     nk_hwp_rm_2, param, kidpar, data, amplitudes
; 
; PURPOSE: 
;        Estimate the HWP parasitic signal as a sum of harmonics of the
;rotation frequency and subtract it from data.toi
; 
; INPUT: 
;    - param, kidpar, data
; 
; OUTPUT: 
;    - amplitudes
;    - data.toi is modified
; 
; KEYWORDS:
;    - fit : the last fit
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - NP
;        - changed the matrix multiplication to improve speed, Feb. 2016 (NP)
;-

pro nk_hwp_rm_2, param, info, data, kidpar, amplitudes, fit=fit, df_tone=df_tone

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_hwp_rm_2, param, kidpar, data, amplitudes, fit=fit, df_tone=df_tone"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements( kidpar)
nsn   = n_elements( data)

ncoeff = 2 + 4*param.polar_n_template_harmonics

t = dindgen(nsn)/!nika.f_sampling

w1     = where(kidpar.type eq 1, nw1)

;; Changed the definition of womeag to start from the first sample
;; womega = where( data.position eq min(data.position), nwomega)
womega = where( data.position eq data[0].position, nwomega)

;; wall   = where( avg( data.flag[w1], 0) eq 0 and $
;;                 data.sample ge data[womega[0]].sample and $
;;                 data.sample le data[womega[nwomega-1]].sample, nwall)

;; Kill the end of the scan after the last data[0].position, otherwise
;; the interpolation below will leave the toi untouched and create a
;; huge jump
data = temporary(data[0:womega[nwomega-1]])
nsn = n_elements(data)

wall = where( avg( data.flag[w1], 0) eq 0, nwall)

if nwall eq 0 then begin
   message, /info, "No sample with all kid flags = 0 to determine the hwp template"
   amplitudes = dblarr( nkids, ncoeff)
   return
endif

if param.hwp_harmonics_only eq 0 then begin
   amplitudes = dblarr( nkids, ncoeff)

   ;; Fitting template, only on good positions
   temp = dblarr( ncoeff, nwall)
   temp[0,*] = 1.0d0
   temp[1,*] = t[wall]
   for i=0, param.polar_n_template_harmonics-1 do begin
      temp[ 2 + i*4,     *] =         cos( (i+1)*data[wall].position)
      temp[ 2 + i*4 + 1, *] = t[wall]*cos( (i+1)*data[wall].position)
      temp[ 2 + i*4 + 2, *] =         sin( (i+1)*data[wall].position)
      temp[ 2 + i*4 + 3, *] = t[wall]*sin( (i+1)*data[wall].position)
   endfor

   ;; Global template for the reconstruction
   outtemp = dblarr( ncoeff, nsn)
   outtemp[0,*] = 1.0d0
   outtemp[1,*] = t
   for i=0, param.polar_n_template_harmonics-1 do begin
      outtemp[ 2 + i*4,     *] =   cos( (i+1)*data.position)
      outtemp[ 2 + i*4 + 1, *] = t*cos( (i+1)*data.position)
      outtemp[ 2 + i*4 + 2, *] =   sin( (i+1)*data.position)
      outtemp[ 2 + i*4 + 3, *] = t*sin( (i+1)*data.position)
   endfor
endif else begin

   amplitudes = dblarr( nkids, ncoeff-2)

   ;; Fitting template, only on good positions
   temp = dblarr( ncoeff-2, nwall)
   for i=0, param.polar_n_template_harmonics-1 do begin
      temp[ i*4,     *] =         cos( (i+1)*data[wall].position)
      temp[ i*4 + 1, *] = t[wall]*cos( (i+1)*data[wall].position)
      temp[ i*4 + 2, *] =         sin( (i+1)*data[wall].position)
      temp[ i*4 + 3, *] = t[wall]*sin( (i+1)*data[wall].position)
   endfor

   ;; Global template for the reconstruction
   outtemp = dblarr( ncoeff-2, nsn)
   for i=0, param.polar_n_template_harmonics-1 do begin
      outtemp[ i*4,     *] =   cos( (i+1)*data.position)
      outtemp[ i*4 + 1, *] = t*cos( (i+1)*data.position)
      outtemp[ i*4 + 2, *] =   sin( (i+1)*data.position)
      outtemp[ i*4 + 3, *] = t*sin( (i+1)*data.position)
   endfor
endelse

ata   = matrix_multiply( temp, temp, /btranspose)
atam1 = invert(ata)

;; const    = data.toi[w1]*0.d0
;; baseline = data.toi[w1]*0.d0
if keyword_set(df_tone) then begin

   my_interpol = dblarr(nw1, nsn)
   for i=0, nwomega-2 do begin
      dx    = double(womega[i+1] - womega[i])
      dy    = data[womega[i+1]].df_tone[w1] - data[womega[i]].df_tone[w1]
      n     = womega[i+1]-womega[i]+1
      slope = (dblarr(n)+1) ## (dy/dx)
      c     = (dblarr(n)+1) ## data[womega[i]].df_tone[w1]
      xx    = dindgen(n)
      
      my_interpol[*,womega[i]:womega[i+1]] = c + slope*(xx##(dblarr(nw1)+1))
   endfor

   ;; before womega[0] and after womega[nwomega-1], my_interpol is
   ;; zero anyway, so we can subtract it here everywhere for convenience
   data.df_tone[w1] -= my_interpol
   
   ;; Ditto here, the constant is computed on the correct range but
   ;; can be subtracted everywhere
   a = avg( data[womega[0]:womega[nwomega-1]].df_tone[w1], 1)
   data.df_tone[w1] -= (dblarr(nsn)+1)##a
   
   atd        = transpose(temp) ## data[wall].df_tone[w1]
   amplitudes = atam1##atd
   new_fit    = outtemp##amplitudes
   
   ;; apply the fit to the entire DF_TONE, even the first and last
   ;; fractions of HWP rotation that were not used in the fit
   data.df_tone[w1] -= new_fit

   ;; Restore the subtracted baseline
   data.df_tone[w1] += my_interpol + (dblarr(nsn)+1)##a

endif else begin

;;      ;;------------------------------
;;      data1 = data
;;      ikid=6
;;      base = interpol( data1[womega].toi[ikid], womega, dindgen(nsn))
;;      data1.toi[ikid] -= base
;;      a = avg( data1.toi[ikid])
;;      data1.toi[ikid] -= a
;;      atd = matrix_multiply( data1[wall].toi[ikid], temp, /btranspose)
;;      ampl = atam1##atd
;;      amplitudes[ikid,*] = ampl
;;      fit  = reform( outtemp##ampl)
;;      data1.toi[ikid] -= fit
;;      data1.toi[ikid] += a + base
;;      ;;------------------------------

   my_interpol = dblarr(nw1, nsn)
   for i=0, nwomega-2 do begin
      dx    = double(womega[i+1] - womega[i])
      dy    = data[womega[i+1]].toi[w1] - data[womega[i]].toi[w1]
      n     = womega[i+1]-womega[i]+1
      slope = (dblarr(n)+1) ## (dy/dx)
      c     = (dblarr(n)+1) ## data[womega[i]].toi[w1]
      xx    = dindgen(n)
      
      my_interpol[*,womega[i]:womega[i+1]] = c + slope*(xx##(dblarr(nw1)+1))
   endfor
   
   ;; before womega[0] and after womega[nwomega-1], my_interpol is
   ;; zero anyway, so we can subtract it here everywhere for convenience
   data.toi[w1] -= my_interpol
   
   ;; Ditto here, the constant is computed on the correct range but
   ;; can be subtracted everywhere
   a = avg( data[womega[0]:womega[nwomega-1]].toi[w1], 1)
   data.toi[w1] -= (dblarr(nsn)+1)##a
   
   atd        = transpose(temp) ## data[wall].toi[w1]
   amplitudes = atam1##atd
   new_fit    = outtemp##amplitudes

   if param.output_hwpss_residuals eq 1 then begin
      openw, u, "hwpss_residuals_"+param.scan+".dat", /get_lun
      openw, u1, "hwpss_harmonics_raw_peak_"+param.scan+".dat", /get_lun
      openw, u2, "hwpss_harmonics_res_peak_"+param.scan+".dat", /get_lun
      for i=0, nw1-1 do begin
         power_spec, data.toi[w1[i]], !nika.f_sampling, pw, freq
         data.toi[w1[i]] -= new_fit[i,*]
         power_spec, data.toi[w1[i]], !nika.f_sampling, pw1
         peak_ratio = dblarr(8)
         w_white_noise = where( freq gt ((5*info.hwp_rot_freq)<(0.8*max(freq))))
         pw_white_noise = avg( pw[w_white_noise])
         peak_ampl     = dblarr(8)
         raw_peak_ampl = dblarr(8)
         for ifreq=1, 8 do begin
            ;; wfreq = where( abs( freq-ifreq*info.hwp_rot_freq) le 1., nwfreq)
            wfreq = where( abs( freq-ifreq*info.hwp_rot_freq) le 1. and $
                           (ifreq*info.hwp_rot_freq+1.) lt max(freq), nwfreq)
            w = where( pw[wfreq] eq max( pw[wfreq]))
            raw_peak = pw[wfreq[w[0]]]
            raw_peak_ampl[ifreq-1] = raw_peak
            w = where( pw1[wfreq] eq max( pw1[wfreq]))
            peak = pw1[wfreq[w[0]]]
            peak_ampl[ifreq-1] = peak
            peak_ratio[ifreq-1] = (peak-pw_white_noise)/(raw_peak-pw_white_noise)
         endfor
         printf, u, strtrim(!nika.f_sampling, 2)+", "+$
                 strtrim(info.hwp_rot_freq,2)+", "+$
                 strtrim(kidpar[w1[i]].numdet, 2)+", "+$
                 strtrim(peak_ratio[0],2)+", "+$
                 strtrim(peak_ratio[1],2)+", "+$
                 strtrim(peak_ratio[2],2)+", "+$
                 strtrim(peak_ratio[3],2)

         strexc = strtrim(!nika.f_sampling, 2)+", "+$
                  strtrim(info.hwp_rot_freq,2)+", "+$
                  strtrim(kidpar[w1[i]].numdet, 2)
         for ifreq=1, 8 do strexc += ", "+strtrim(raw_peak_ampl[ifreq-1],2)
         printf, u1, strexc

         strexc = strtrim(!nika.f_sampling, 2)+", "+$
                  strtrim(info.hwp_rot_freq,2)+", "+$
                  strtrim(kidpar[w1[i]].numdet, 2)
         for ifreq=1, 8 do strexc += ", "+strtrim(peak_ampl[ifreq-1],2)
         printf, u2, strexc

      endfor
      close, u, u1, u2
      free_lun, u, u1, u2

   endif else begin
      ;; apply the fit to the entire TOI, even the first and last
      ;; fractions of HWP rotation that were not used in the fit
      ;message, /info, "fix me: uncomment next line"
      data.toi[w1] -= new_fit
   endelse

   ;; Restore the subtracted baseline
   data.toi[w1] += my_interpol + (dblarr(nsn)+1)##a

endelse

if param.cpu_time then nk_show_cpu_time, param, "nk_hwp_rm_2"

end
