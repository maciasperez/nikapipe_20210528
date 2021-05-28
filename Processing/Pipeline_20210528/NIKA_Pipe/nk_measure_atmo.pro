
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_measure_atmo
;
; CATEGORY: data quality monitoring
;
; CALLING SEQUENCE:
;         nk_measure_atmo, param, info, data, kidpar, common_mode
; 
; PURPOSE: 
;        Monitors sky noise properties
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
;        - common_mode: the atmosphere common modes derived e.g. in nk_get_cm.pro
; 
; OUTPUT: 
;        - info
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

function power_spec_mpfit,x,p
  return, p[0] * x^(p[1]) + p[2]
end


pro nk_measure_atmo, param, info, data, kidpar, common_mode

if n_params() lt 1 then begin
   message, /info, "Calling sequence"
   print, " nk_measure_atmo, param, info, data, kidpar, common_mode"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if param.plot_ps eq 1 then param.plot_png = 0

if param.do_plot ne 0 then begin
   if param.plot_png eq 1 then wind, 1, 1, /free, /large, iconic = param.iconic
   !p.multi=[0,3,2]
endif

my_multiplot, /reset
outplot, file=param.plot_dir+'/meas_atmo_'+strtrim(param.scan,2), png=param.plot_png, ps=param.plot_ps
for lambda=1, 2 do begin

   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
   wcom = where( finite( common_mode[lambda-1, *]), nwcom)
   if nw1 ne 0 and nwcom gt 10 then begin

      ;; Regress out the air mass dependence
      air_mass = 1./sin(data.el)
      fit = linfit( air_mass[ wcom], common_mode[lambda-1,wcom])
      if param.do_plot gt 0 then begin
         plot, wcom, common_mode[lambda-1, wcom]
         oplot, wcom, fit[0] + fit[1]*air_mass[ wcom],col=250
         legendastro, ['Common mode', 'fit*air_mass'], textcol=[!p.color,250], box=0, /right
      endif
      ;; plot, temp_atmo-(fit[0] + fit[1]*air_mass)     
      if lambda eq 1 then info.result_atmo_am2jy_1mm = fit[1] else info.result_atmo_am2jy_2mm = fit[1]
      temp_atmo = reform( common_mode[lambda-1,*]) - fit[0] - fit[1]*air_mass

      ;;------- Compute the spectrum
      power_spec, temp_atmo, !nika.f_sampling, pw, freq

      ;;------- Integrate the spectrum in requested bins
      bin1 = where(freq ge 0.001 and freq lt 0.003, nbin1)
      bin2 = where(freq ge 0.003 and freq lt 0.01, nbin2)
      bin3 = where(freq ge 0.01 and freq lt 0.03, nbin3)
      bin4 = where(freq ge 0.03 and freq lt 0.1, nbin4)
      bin5 = where(freq ge 0.1 and freq lt 0.3, nbin5)
      bin6 = where(freq ge 0.3 and freq lt 1.0, nbin6)
      bin7 = where(freq ge 1.0 and freq lt 3.0, nbin7)
      bin8 = where(freq ge 3.0 and freq lt 10.0, nbin8)
      bin9 = where(freq ge 5.0 and freq lt 10.d0, nbin9)

      if lambda eq 1 then begin
         if nbin1 ge 2 then info.result_Fatm1mm_b1 = sqrt( INT_TABULATED(freq[bin1], pw[bin1]^2))
         if nbin2 ge 2 then info.result_Fatm1mm_b2 = sqrt( INT_TABULATED(freq[bin2], pw[bin2]^2)) 
         if nbin3 ge 2 then info.result_Fatm1mm_b3 = sqrt( INT_TABULATED(freq[bin3], pw[bin3]^2)) 
         if nbin4 ge 2 then info.result_Fatm1mm_b4 = sqrt( INT_TABULATED(freq[bin4], pw[bin4]^2)) 
         if nbin5 ge 2 then info.result_Fatm1mm_b5 = sqrt( INT_TABULATED(freq[bin5], pw[bin5]^2)) 
         if nbin6 ge 2 then info.result_Fatm1mm_b6 = sqrt( INT_TABULATED(freq[bin6], pw[bin6]^2)) 
         if nbin7 ge 2 then info.result_Fatm1mm_b7 = sqrt( INT_TABULATED(freq[bin7], pw[bin7]^2)) 
         if nbin8 ge 2 then info.result_Fatm1mm_b8 = sqrt( INT_TABULATED(freq[bin8], pw[bin8]^2))
         if nbin9 ge 2 then info.result_Fatm1mm_b9 = sqrt( INT_TABULATED(freq[bin9], pw[bin9]^2)) 
      endif
      if lambda eq 2 then begin
         if nbin1 ge 2 then info.result_Fatm2mm_b1 = sqrt( INT_TABULATED(freq[bin1], pw[bin1]^2))
         if nbin2 ge 2 then info.result_Fatm2mm_b2 = sqrt( INT_TABULATED(freq[bin2], pw[bin2]^2)) 
         if nbin3 ge 2 then info.result_Fatm2mm_b3 = sqrt( INT_TABULATED(freq[bin3], pw[bin3]^2)) 
         if nbin4 ge 2 then info.result_Fatm2mm_b4 = sqrt( INT_TABULATED(freq[bin4], pw[bin4]^2)) 
         if nbin5 ge 2 then info.result_Fatm2mm_b5 = sqrt( INT_TABULATED(freq[bin5], pw[bin5]^2)) 
         if nbin6 ge 2 then info.result_Fatm2mm_b6 = sqrt( INT_TABULATED(freq[bin6], pw[bin6]^2)) 
         if nbin7 ge 2 then info.result_Fatm2mm_b7 = sqrt( INT_TABULATED(freq[bin7], pw[bin7]^2)) 
         if nbin8 ge 2 then info.result_Fatm2mm_b8 = sqrt( INT_TABULATED(freq[bin8], pw[bin8]^2))
         if nbin9 ge 2 then info.result_Fatm2mm_b9 = sqrt( INT_TABULATED(freq[bin9], pw[bin9]^2)) 
      endif

      ;;------- Fit the spectra
      weights = freq            ;Spectrum slope is close to -1 so weight for having log fit (first guess)
      parinfo = replicate({value:0.D,fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
      parinfo[2].limited = [1,0]
      parinfo[2].limits = [0.0,0.0]
         
      par0 = [mean(pw[n_elements(pw)/2:*]), -1.0, mean(pw[n_elements(pw)/2:*])]

      par = mpfitfun('power_spec_mpfit',freq, pw, 0, par0, $
                     weights=weights, parinfo=parinfo, yfit=yfit, AUTODERIVATIVE=1, /QUIET)

      weights = freq^(-par[1])  ;Spectrum slope used for weigthing
      par = mpfitfun('power_spec_mpfit',freq, pw, 0, par0, $
                     weights=weights,parinfo=parinfo,yfit=yfit,AUTODERIVATIVE=1,/QUIET)

         ;;------- Plot the results
      if param.do_plot eq 1 then begin
         time = dindgen( n_elements(data))/!nika.f_sampling
         plot, time, temp_atmo, xtitle='Time (s)', ytitle='Flux (Jy)', /xs, /ys, charsize=0.7
         legendastro, 'common mode TOI '+strtrim(lambda,2)+"mm", box=0
         
         plot_oo, freq, pw, xtitle='Frequency (Hz)', ytitle='P(f) (Jy.Hz!U-1/2!N)', /xs, /ys,charsize=0.7, yr=[0.0001,10000]
         legendastro, 'common mode PS '+strtrim(lambda,2)+"mm", box=0, /bottom
         oplot, freq, yfit, col=250
         oplot, freq, par[2] + freq*0, col=150, linestyle=2
         oplot, freq, par[0]*freq^par[1], col=150, linestyle=2
         for i=-4, 5 do begin
            oplot, minmax(freq), [1,1]*10^i, col=50, line=1
            oplot, [1,1]*10^i, [1e-10,1e10], col=50, line=1
         endfor
         legendastro, ['Best fit: '+strtrim(par[2],2)+' + '+strtrim(par[0],2)+$
                       ' x !12f!3!U'+strtrim(par[1],2)],box=0,/right,/top, charsize=0.7
         cgText, 0.5, 1.0, ALIGNMENT=0.5, CHARSIZE=1.25, /NORMAL, strtrim(param.scan,2)
      endif

      ;;------- Remember the numbers for statistics
      if lambda eq 1 then begin
         info.result_atmo_ampli_1mm = par[0]
         info.result_atmo_slope_1mm = par[1]
         info.result_atmo_level_1mm = par[2]
      endif
      if lambda eq 2 then begin
         info.result_atmo_ampli_2mm = par[0]
         info.result_atmo_slope_2mm = par[1]
         info.result_atmo_level_2mm = par[2]
      endif
         
   endif                        ; kids at this frequency
endfor

outplot, /close

if param.cpu_time then nk_show_cpu_time, param

end
