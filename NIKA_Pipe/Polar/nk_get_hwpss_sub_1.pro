
;+
;
; SOFTWARE:
;; NIKA pipeline / Polarization
;
; NAME: 
; nk_get_hwpss_sub_1
;
; CATEGORY:
;
; CALLING SEQUENCE:
;  nk_get_hwpss_sub, param, info, toi_in, synchro, position, kidpar, hwpss
;
; PURPOSE: 
;        Estimate the HWP parasitic signal as a sum of harmonics of the
;rotation frequency and subtract it from data.toi
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - slower kid by kid fit (off_source) to try

pro nk_get_hwpss_sub_1, param, info, toi_in, synchro, position, flag, kidpar, hwpss, $
                        plot=plot, off_source=off_source, amplitudes=amplitudes, $
                        multiplot_pp1=multiplot_pp1, multiplot_index=multiplot_index, $
                        in_w8_source=in_w8_source
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_get_hwpss_sub_1'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids  = n_elements( kidpar)
nsn    = n_elements(toi_in[0,*])
t      = dindgen(nsn)/!nika.f_sampling
index  = lindgen(nsn)

if param.hwp_harmonics_only eq 1 then begin
   amplitudes = dblarr(nkids,2*param.polar_n_template_harmonics)
endif else begin
   amplitudes = dblarr(nkids,4*param.polar_n_template_harmonics)
endelse

;; Restrict the fit to an integer number of HWP full rotations
womega = where( abs(synchro-median(synchro)) gt 3*stddev(synchro), nwomega)

hwpss = dblarr(nkids, nsn)
for ikid=0, nkids-1 do begin
;;   if (ikid mod round(nkids/10.)) eq 0 then print, strtrim(ikid,2)+"/"+strtrim(nkids-1,2)

;; ;;   if param.ignore_mask_for_decorr eq 1 then begin
   if param.off_source_for_hwpss eq 1 then begin
      wfit = where( index ge womega[0] and index le womega[nwomega-1] and $
                    off_source[ikid,*] eq 1 and (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11), nwfit)
   endif else begin
      wfit = where( index ge womega[0] and index le womega[nwomega-1] and $
                    (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11),  nwfit)
   endelse
   
   if nwfit lt 100 then begin
      error_message = "No valid sample to fit for KID "+strtrim(ikid,2)
;      message, /info, error_message
      nk_error, info, error_message, status=2
      flag[ikid,*] = 2L^7
   endif else begin

      if param.hwp_harmonics_only eq 1 then begin
         ncoeff = 2*param.polar_n_template_harmonics
         ;; Fitting template, only on good positions
         temp = dblarr( ncoeff, nwfit)
         for i=0, param.polar_n_template_harmonics-1 do begin
            temp[ i*2,   *] = cos( (i+1)*position[wfit])
            temp[ i*2+1, *] = sin( (i+1)*position[wfit])
         endfor
         ;; Global template for the reconstruction
         outtemp = dblarr( ncoeff, nsn)
         for i=0, param.polar_n_template_harmonics-1 do begin
            outtemp[ i*2,     *] = cos( (i+1)*position)
            outtemp[ i*2 + 1, *] = sin( (i+1)*position)
         endfor
      endif else begin
         ncoeff = 4*param.polar_n_template_harmonics
         temp = dblarr( ncoeff, nwfit)
         ;; Fitting template, only on good positions
         for i=0, param.polar_n_template_harmonics-1 do begin
            temp[ i*4,     *] =         cos( (i+1)*position[wfit])
            temp[ i*4 + 1, *] = t[wfit]*cos( (i+1)*position[wfit])
            temp[ i*4 + 2, *] =         sin( (i+1)*position[wfit])
            temp[ i*4 + 3, *] = t[wfit]*sin( (i+1)*position[wfit])
         endfor
         ;; Global template for the reconstruction
         outtemp = dblarr( ncoeff, nsn)
         for i=0, param.polar_n_template_harmonics-1 do begin
            outtemp[ i*4,     *] =   cos( (i+1)*position)
            outtemp[ i*4 + 1, *] = t*cos( (i+1)*position)
            outtemp[ i*4 + 2, *] =   sin( (i+1)*position)
            outtemp[ i*4 + 3, *] = t*sin( (i+1)*position)
         endfor
      endelse

;;       ata   = matrix_multiply( temp, temp, /btranspose)
;;       atam1 = invert(ata)

      my_interpol = interpol( toi_in[ikid,womega], womega, index)

;; before womega[0] and after womega[nwomega-1], my_interpol is
;; zero anyway, so we can subtract it on all wfit for convenience
      toi4fit = toi_in[ikid,wfit] - my_interpol[wfit]

      if defined(in_w8_source) then measure_errors = reform(sqrt( 1.d0/in_w8_source[ikid,wfit]))

      ;; Coeff fits a constant in addition to the provided templates
      coeff = regress( temp, reform(toi4fit,nwfit), const=const, $
                       /double, measure_errors=measure_errors)

      ;; hwpss[     ikid,*] = const + outtemp##coeff
      hwpss[     ikid,*] = outtemp##coeff
      amplitudes[ikid,*] = coeff

;      if param.mydebug eq 0510 and kidpar[ikid].numdet eq
;      !nika.ref_det[0] then begin
      if param.mydebug eq 0510 and ikid eq 2046 then begin
         delvarx, xra
;         xra = [2000,5000]
;         xra = [3000,3500]
;         xra = [1500,2500]
         wind, 1, 1, /free, /large
         my_multiplot, 1, 3, pp, pp1, /rev
         plot, toi_in[ikid,*], yra=array2range(toi_in[ikid,*]), /xs, /ys, $
               position=pp1[0,*], title='Toi_in', xra=xra
         oplot, womega, toi_in[ikid,womega], psym=8, syms=0.5, col=70
         oplot, my_interpol, col=150
         legendastro, ['Toi_in', 'womega', 'my_interpol'], col=[0,70,150]

         yra = array2range(toi_in[ikid,*]-my_interpol)*2
         plot, toi_in[ikid,*]-my_interpol, /xs, /ys, yra=yra, /noerase, position=pp1[1,*], $
               title='Toi_in - my_interpol', xra=xra
         oplot, toi_in[ikid,*]-my_interpol, thick=2
         oplot, wfit, toi4fit, psym=1, col=150, thick=2
         oplot, const + hwpss[ikid,*], col=250
         legendastro, ['toi_in-my_interpol', 'wfit', 'Const + HWPSS'], col=[0,150,250]

         plot, toi_in[ikid,*]-my_interpol-hwpss[ikid,*], position=pp1[2,*], $
               /noerase, /xs, title='toi_in-my_interpol-hwpss', xra=xra
         stop
      endif

      
      if keyword_set(multiplot_pp1) and kidpar[ikid].numdet eq !nika.ref_det[0] then begin
         my_multiplot, 1, 3, pp, pp1, /rev, $
                       xmin=multiplot_pp1[multiplot_index,0], $
                       xmax=multiplot_pp1[multiplot_index,2], $
                       ymin=multiplot_pp1[multiplot_index,1], $
                       ymax=multiplot_pp1[multiplot_index,3], /full, /dry, xmargin=0.001, ymargin=0.001
         
;         plot, toi_in[ikid,*]-my_interpol, /xs, /ys, yrange=array2range(toi4fit), position=multiplot_pp1[multiplot_index,*], /noerase
         plot, index/!nika.f_sampling, toi_in[ikid,*]-my_interpol, /xs, /ys, yrange=array2range(toi4fit), position=pp1[0,*], /noerase
         yfit = const + outtemp##coeff
         oplot, index/!nika.f_sampling, yfit, col=250
         plot, index/!nika.f_sampling, toi_in[ikid,*]-my_interpol-yfit, /xs, /ys, position=pp1[1,*], /noerase
         power_spec, toi_in[ikid,*]-my_interpol-yfit, !nika.f_sampling, pw, freq
         plot_oo, freq, pw, /xs, /ys, position=pp1[2,*], /noerase
      endif

   endelse
endfor

;; 
;; ;; Build template on the whole sample range
;; hwpss = outtemp##amplitudes
;; 
;; if keyword_set(plot) then begin
;;    wind, 1, 1, /free, /large
;;    my_multiplot, 2, 3, pp, pp1, /rev, xmax=0.7
;; 
;;    yra = array2range(toi_in[0,*], margin=0.4)
;;    plot, toi_in[0,*], /xs, xra=xra, yra=yra, /ys, position=pp[0,0,*]
;;    oplot, wfit, toi_in[0,wfit], col=150
;;    oplot, my_interpol[0,*], col=250, thick=3
;;    oplot, womega, toi_in[0,womega], psym=-8, syms=0.5, col=70
;;    legendastro, ['TOI_in', 'TOI_in (wfit)', 'my_interpol', 'womega'], $
;;                 textcol=[!p.color, 150, 250, 70]
;;    
;;    plot, toi4fit[0,*], /xs, position=pp[0,1,*], /noerase, xra=xra
;;    legendastro, 'TOI4fit = toi_in - my_interpol (wfit)'
;;    
;;    plot, toi_in[0,*]-hwpss[0,*], /xs, /ys, position=pp[0,2,*], /noerase, xra=xra
;;    legendastro, 'TOI_in[0,*] - hwpss[0,*]'
;; 
;;    plot, toi_in[0,*], /xs, position=pp[1,0,*], xra=xra, yra=yra, /ys, /noerase
;;    oplot, toi_in[0,*]-hwpss[0,*], col=250
;; 
;;    power_spec, toi_in[0,*]-my_baseline(toi_in[0,*],base=0.1), !nika.f_sampling, pw, freq
;;    y = toi_in[0,*]-hwpss[0,*]-a[0]
;;    power_spec, y-my_baseline(y,base=0.1), !nika.f_sampling, pw1
;;    plot_oo, freq, pw, /xs, position=pp[1,1,*], /noerase
;;    oplot, freq, pw1, col=250
;;    stop
;; ;;    my_multiplot, 1, 2, pp, pp1, xmin=0.7
;; ;;    plot, [0,10], [0,10], /nodata, position=pp1[0,*], /noerase, xs=4, ys=4
;; ;;    legendastro, ['Amplitudes:', strtrim(reform(amplitudes[0,*]),2)]
;; endif
;; 
;; if param.cpu_time then nk_show_cpu_time, param

end
