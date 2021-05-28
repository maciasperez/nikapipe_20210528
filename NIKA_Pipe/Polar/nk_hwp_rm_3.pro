
;+
;
; SOFTWARE:
;; NIKA pipeline / Polarization
;
; NAME: 
; nk_hwp_rm_3
;
; CATEGORY:
;
; CALLING SEQUENCE:
;     nk_hwp_rm_3, param, kidpar, data, amplitudes
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
;        - changed the matrix multiplication to improve speed,
;          Feb. 2016 (NP)
;        - deal with my_interpol differently from nk_hwp_rm_2,
;          NP. Nov. 2017
;-

pro nk_hwp_rm_3, param, info, data, kidpar, amplitudes, $
                 fit=fit, df_tone=df_tone, plot=plot, new_fit=new_fit

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_hwp_rm_3, param, info, data, kidpar, amplitudes, fit=fit, df_tone=df_tone"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements( kidpar)
nsn   = n_elements( data)

ncoeff = 2 + 4*param.polar_n_template_harmonics


w1     = where(kidpar.type eq 1, nw1)

;; Changed the definition of womeag to start from the first sample
;; womega = where( data.position eq min(data.position), nwomega)
;; womega = where( data.position eq data[0].position, nwomega)
;; Nov. 26th, 2017: Take data.synchros as a reference now that
;; data.position comes from an interpolation and is not strictly equal
;; from period to the next.
womega = where( abs(data.synchro-median(data.synchro)) gt 3*stddev(data.synchro), nwomega)

;; Kill the end of the scan after the last data[0].position, otherwise
;; the interpolation below will leave the toi untouched and create a
;; huge jump
;; data = temporary(data[0:womega[nwomega-1]])
;; Nov. 26th, 2017

;; data = temporary( data[womega[0]:womega[nwomega-1]])
womega = womega - womega[0]
nsn    = n_elements(data)
t      = dindgen(nsn)/!nika.f_sampling
index  = lindgen(nsn)

;; wall = where( avg( data.flag[w1], 0) eq 0, nwall)
wall = where( avg( data.flag[w1], 0) eq 0 and $
              index ge womega[0] and index le womega[nwomega-1], nwall)

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
   df_tone = data.df_tone[w1] - my_interpol
   
   ;; Ditto here, the constant is computed on the correct range but
   ;; can be subtracted everywhere
   a = avg( df_tone[*,womega[0]:womega[nwomega-1]],1)
   df_tone -= (dblarr(nsn)+1)##a
   
   atd = transpose(temp)##df_tone[*,wall]
   amplitudes = atam1##atd
;   stop
   new_fit    = outtemp##amplitudes
   
   ;; apply the fit to the entire DF_TONE, even the first and last
   ;; fractions of HWP rotation that were not used in the fit
   data.df_tone[w1] -= new_fit

endif else begin

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
   ;; data.toi[w1] -= my_interpol
   toi = data.toi[w1] - my_interpol
   
   ;; Ditto here, the constant is computed on the correct range but
   ;; can be subtracted everywhere
   ;; a = avg( data[womega[0]:womega[nwomega-1]].toi[w1], 1)
   ;; data.toi[w1] -= (dblarr(nsn)+1)##a
   a = avg( toi[*,womega[0]:womega[nwomega-1]], 1)
   toi -= (dblarr(nsn)+1)##a
   
   ;; atd        = transpose(temp) ## data[wall].toi[w1]
   atd        = transpose(temp) ## toi[*,wall]
   amplitudes = atam1##atd
   new_fit    = outtemp##amplitudes
   
   if param.output_hwpss_residuals eq 1 then begin
      message, /info, "Not adapted to nk_hwp_rm_3 yet"
      stop
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

      ;; Store the phase of each harmonic (ignore the drift with time
      ;; for now)
      for i=0, nw1-1 do begin
         ikid = w1[i]
         for ih=0, 3 do begin
            c0 = amplitudes[i,ih*4]
            c1 = amplitudes[i,ih*4+2]
            norm = sqrt(c0^2+c1^2)
            phi = atan( c1/norm, c0/norm)*!radeg
            junk = execute( "kidpar[ikid].a_hwpss_phi_"+strtrim(ih+1,2)+" = phi")
         endfor
      endfor
      
      ;; Monitor the phase of the template harmonics and the
      ;; synchronization top differently
      if param.harmonics_and_synchro then begin
         data1 = data           ; init
         data1.toi[w1] = toi    ; atmospheric drift subtracted
         kidpar1 = kidpar[w1]
         nk_get_harmonics_and_synchro, param, info, data1, kidpar1
         kidpar[w1] = kidpar1
      endif
      
;;       ;;---------------------------------------------------
;;       message, /info, "fix me:"
;;       help, amplitudes
;;       wind, 1, 1, /free, /large
;;       my_multiplot, 2, 2, pp, pp1, /rev
;;       for ih=0, 3 do begin &$
;;          junk = execute( 'phase = kidpar1.a_hwpss_phi_'+strtrim(ih+1,2)) &$
;;          plot,  phase, /xs, position=pp1[ih,*], /noerase &$
;;          c1 = amplitudes[*,ih*4+2] &$
;;          c0 = amplitudes[*,ih*4] &$
;;          norm = sqrt(c0^2+c1^2) &$
;;          oplot, atan( c1/norm, c0/norm)*!radeg, col=250 &$
;;       endfor
;;       wind, 2, 2, /free, /large
;;       my_multiplot, 2, 2, pp, pp1, /rev
;;       for ih=0, 3 do begin &$
;;          print, ih &$
;;          junk = execute( 'phase = kidpar1.a_hwpss_phi_'+strtrim(ih+1,2)) &$
;;          c1 = amplitudes[*,ih*4+2] &$
;;          c0 = amplitudes[*,ih*4] &$
;;          norm = sqrt(c0^2+c1^2) &$
;;          np_histo, phase-atan( c1/norm, c0/norm)*!radeg, bin=1, $
;;          position=pp1[ih,*], /noerase, /fit, /fill, min=-100, max=100 &$
;;       endfor
;;       stop
;;       ;;----------------------------------------------------
     
;;      wind, 1, 1, /free, /large
;;      my_multiplot, 1, 3, pp, pp1, /rev
;;      for iarray=1, 3 do begin
;;         wk = where( kidpar.type eq 1 and kidpar.numdet eq !nika.ref_det[iarray-1], nwk)
;;         if nwk ne 0 then begin
;;            ww = where( kidpar[w1].numdet eq !nika.ref_det[iarray-1])
;;            plot, data.position*!radeg, toi[ww,*], /xs, $
;;                  position=pp1[iarray-1,*], /noerase, psym=8, syms=0.5, $
;;                  title=param.scan
;;            legendastro, ['A'+strtrim(iarray,2), $
;;                          'Numdet '+strtrim(kidpar[wk].numdet,2)]
;;            oplot, data.position*!radeg, new_fit[ww,*], col=250
;;         endif
;;      endfor
;;
;;
;;      kidpar1 = kidpar[w1]
;;      help, kidpar1, toi, amplitudes, temp
;;      wind, 1, 1, /free, /large
;;      ikid = (where( kidpar1.numdet eq !nika.ref_det[0]))[0]
;;      xra=[100,150] ; samples
;;      n = xra[1]-xra[0]
;;      time = dindgen(xra[1]-xra[0])/!nika.f_sampling
;;      y = reform(toi[ikid,xra[0]:xra[1]])
;;      scale = max(data.synchro)-min(data.synchro)
;;      synchro=(data[xra[0]:xra[1]].synchro-min(data[xra[0]:xra[1]].synchro))/scale*max(y)
;;      tmax = max(time)
;;      tmin = min(time)
;;      oversamp=10
;;      t1 = interpol( time, dindgen(n), dindgen(n*oversamp)/(n*oversamp-1)*(n-1))
;;      omega1 = 2.d0*!dpi*info.hwp_rot_freq*t1 + data[xra[0]].position
;;      omega1 = omega1 mod (2*!dpi)
;;      y1 = omega1*0.d0
;;      for i=0, param.polar_n_template_harmonics-1 do begin &$
;;         y1 += amplitudes[ikid,i*4]*cos( (i+1)*omega1) &$
;;         y1 += amplitudes[ikid,i*4+1]*t1*cos( (i+1)*omega1) &$
;;         y1 += amplitudes[ikid,i*4+2]*sin( (i+1)*omega1) &$
;;         y1 += amplitudes[ikid,i*4+3]*t1*sin( (i+1)*omega1) &$
;;      endfor
;;
;;      plot,  time, y, /xs, psym=1, thick=2
;;      oplot, time, synchro, col=250
;;      oplot, t1, y1, col=70    
;;      stop
;;

      if keyword_set(plot) then begin
         message, /info, "here"
         wind, 1, 1, /free, /large
         my_multiplot, 1, 3, pp, pp1, /rev
         plot, data.toi[w1[0]], /xs, position=pp1[0,*]
         oplot, my_interpol[0,*], col=250, thick=3
         oplot, womega, data[womega].toi[w1[0]], psym=8, syms=0.5, col=70
         
         plot, toi[0,*], /xs, position=pp1[1,*], /noerase
         
         plot, data.toi[w1[0]]-new_fit[0,*], /xs, /ys, position=pp1[2,*], /noerase
         stop

      endif



;; Subtract HWPSs from the TOI's
      data.toi[w1]  -= new_fit
      
   endelse

;;    ;; Restore the subtracted baseline
;;    data.toi[w1] += my_interpol + (dblarr(nsn)+1)##a

endelse

if param.cpu_time then nk_show_cpu_time, param

end
