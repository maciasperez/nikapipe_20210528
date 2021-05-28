;+
;PURPOSE: Compute the power spectrum of the atmospheric noise within a
;         set of frequency
;
;INPUT: The parameter, the data and the kidpar structures
;
;LAST EDITION: - 20/11/2013: creation (adam@lpsc.in2p3.fr)
;              - 05/07/2014: no need to compute if KIDs are on
;              source. Using nika_pipe_onsource.pro
;-

function power_spec_mpfit,x,p
  return, p[0] * x^(p[1]) + p[2]
end

pro nika_pipe_measure_atmo, param, data, kidpar, $
                            ps=ps, no_merge_fig=no_merge_fig, noplot=noplot

  ;;------- Define variables
  N_pt = n_elements(data)
  n_kid = n_elements(kidpar)
  won = where(kidpar.type eq 1, non)   ; Number of detector ON
  woff = where(kidpar.type eq 2, noff) ; Number of detector OFF

  ;;------- Determine if kids are "on" or "off source"
  time = dindgen(n_elements(data))/!nika.f_sampling

  ;;------- Init output plot
  if not keyword_set(ps) and not keyword_set(noplot) then $
     window, 10, xsize=1600, ysize=900, title='Common mode properties'
  if keyword_set(ps) then begin
     SET_PLOT, 'PS'
     device,/color, bits_per_pixel=256, filename=param.output_dir+'/check_atm_cm_'+strtrim(param.scan_list[param.iscan],2)+'.ps'
  endif
  !p.multi=[0,2,2]

  ;;------- Main loop
  for lambda=1, 2 do begin
     wk = where( kidpar.type eq 1 and kidpar.array eq lambda, nwk)
     if nwk ne 0 then begin

        ;;------- Get the common mode
        wsubscan   = lindgen( n_pt)
        rf_didq_a  = data[wsubscan].rf_didq[wk]
        kidpar_a   = kidpar[wk]
        w8source_a = 1 - data.on_source_dec[wk]
        nika_pipe_subtract_common_atm, param, rf_didq_a, kidpar_a, w8source_a, temp_atmo, base

        ;;------- Regress out the air mass dependence
        w = where( data.scan_valid eq 0 and median( data.flag[wk],dim=1) eq 0, nw, compl=winterp, ncompl=nwinterp)
        if nw le 10 then continue ; avoid undefined parameters
        i1 = min(w)
        i2 = max(w)
        air_mass = 1.0/sin(data.el)
        fit = linfit( air_mass[w], temp_atmo[w])
        ;;plot, temp_atmo
        ;;oplot, fit[0] + fit[1]*air_mass,col=250
        ;;plot, temp_atmo-(fit[0] + fit[1]*air_mass)
        
        param.meas_atmo.am2jy.(lambda-1) = fit[1]
        
        temp_atmo = temp_atmo-(fit[0] + fit[1]*air_mass)
        if nwinterp ne 0 then begin
           junk = fix(temp_atmo*0.)
           junk[winterp] = 1
           qd_interpol, temp_atmo, junk, out
           temp_atmo = out
        endif

        ;;------- Keep only safe range (interpol, scan_valid, speed...)
        wkeep = indgen(i2-i1+1) + i1

        temp_atmo = temp_atmo[wkeep]
        time = time[wkeep]

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

        ;; NP+FXD: addd square to pw before integrating to get the
        ;; actual rms
        if nbin1 ge 2 then param.meas_atmo.flux_bin.(lambda-1)[param.iscan, 0] = sqrt( INT_TABULATED(freq[bin1], pw[bin1]^2))
        if nbin2 ge 2 then param.meas_atmo.flux_bin.(lambda-1)[param.iscan, 1] = sqrt( INT_TABULATED(freq[bin2], pw[bin2]^2)) 
        if nbin3 ge 2 then param.meas_atmo.flux_bin.(lambda-1)[param.iscan, 2] = sqrt( INT_TABULATED(freq[bin3], pw[bin3]^2)) 
        if nbin4 ge 2 then param.meas_atmo.flux_bin.(lambda-1)[param.iscan, 3] = sqrt( INT_TABULATED(freq[bin4], pw[bin4]^2)) 
        if nbin5 ge 2 then param.meas_atmo.flux_bin.(lambda-1)[param.iscan, 4] = sqrt( INT_TABULATED(freq[bin5], pw[bin5]^2)) 
        if nbin6 ge 2 then param.meas_atmo.flux_bin.(lambda-1)[param.iscan, 5] = sqrt( INT_TABULATED(freq[bin6], pw[bin6]^2)) 
        if nbin7 ge 2 then param.meas_atmo.flux_bin.(lambda-1)[param.iscan, 6] = sqrt( INT_TABULATED(freq[bin7], pw[bin7]^2)) 
        if nbin8 ge 2 then param.meas_atmo.flux_bin.(lambda-1)[param.iscan, 7] = sqrt( INT_TABULATED(freq[bin8], pw[bin8]^2)) 

        if (param.meas_atmo.dofitatmo eq "yes") then begin
           ;;------- Fit the spectra
           weights = freq       ;Spectrum slope is close to -1 so weight for having log fit (first guess)
           parinfo = replicate({value:0.D,fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
           parinfo[2].limited = [1,0]
           parinfo[2].limits = [0.0,0.0]
           
           par0 = [mean(pw[n_elements(pw)/2:*]), -1.0, mean(pw[n_elements(pw)/2:*])]

           par = mpfitfun('power_spec_mpfit',freq, pw, 0, par0, $
                          weights=weights, parinfo=parinfo, yfit=yfit, AUTODERIVATIVE=1, /QUIET)

           weights = freq^(-par[1]) ;Spectrum slope used for weigthing
           par = mpfitfun('power_spec_mpfit',freq, pw, 0, par0, $
                          weights=weights,parinfo=parinfo,yfit=yfit,AUTODERIVATIVE=1,/QUIET)

           ;;------- Plot the results
           if not keyword_set(noplot) then begin
              
              if total( finite( temp_atmo)) gt 2 then begin
                 plot, time, temp_atmo, xtitle='Time (s)', ytitle='Flux (Jy)', title=' common mode TOI '+strtrim(lambda,2)+"mm",/xs, /ys, charsize=0.7 
              endif else plot, time, title = 'No valid samples to compute sky noise common mode'
              
              plot_oo, freq, pw, xtitle='Frequency (Hz)', ytitle='P(f) (Jy.Hz!U-1/2!N)', title=' common mode PS '+strtrim(lambda,2)+"mm",/xs, /ys,charsize=0.7, yr=[0.0001,10000]
              oplot, freq, yfit, col=250
              oplot, freq, par[2] + freq*0, col=150, linestyle=2
              oplot, freq, par[0]*freq^par[1], col=150, linestyle=2
              oplot, freq, pw*0+0.0001, col=50, linestyle=1
              oplot, freq, pw*0+0.001, col=50, linestyle=1
              oplot, freq, pw*0+0.01, col=50, linestyle=1
              oplot, freq, pw*0+0.1, col=50, linestyle=1
              oplot, freq, pw*0+1, col=50, linestyle=1
              oplot, freq, pw*0+10, col=50, linestyle=1
              oplot, freq, pw*0+100, col=50, linestyle=1
              oplot, freq, pw*0+1000, col=50, linestyle=1
              oplot, freq, pw*0+10000, col=50, linestyle=1
              oplot, freq*0+0.0001, dindgen(n_pt)/(n_pt-1)*10000+1.01e-4, col=50, linestyle=1
              oplot, freq*0+0.001, dindgen(n_pt)/(n_pt-1)*10000+1.01e-4, col=50, linestyle=1
              oplot, freq*0+0.01, dindgen(n_pt)/(n_pt-1)*10000+1.01e-4, col=50, linestyle=1
              oplot, freq*0+0.1, dindgen(n_pt)/(n_pt-1)*10000+1.01e-4, col=50, linestyle=1
              oplot, freq*0+1, dindgen(n_pt)/(n_pt-1)*10000+1.01e-4, col=50, linestyle=1
              oplot, freq*0+10, dindgen(n_pt)/(n_pt-1)*10000+1.01e-4, col=50, linestyle=1
              oplot, freq*0+100, dindgen(n_pt)/(n_pt-1)*10000+1.01e-4, col=50, linestyle=1
              legendastro, ['Best fit: '+strtrim(par[2],2)+' + '+strtrim(par[0],2)+$
                            ' x !12f!3!U'+strtrim(par[1],2)],box=0,/right,/top, charsize=0.7
              cgText, 0.5, 1.0, ALIGNMENT=0.5, CHARSIZE=1.25, /NORMAL, strtrim(param.scan_list[param.iscan],2)
           endif
        endif

        ;;------- Remember the numbers for statistics
        param.meas_atmo.ampli.(lambda-1)[param.iscan] = par[0]
        param.meas_atmo.slope.(lambda-1)[param.iscan] = par[1]
     endif                      ; kids at this frequency
  endfor

  if keyword_set(ps) then begin
     device,/close
     SET_PLOT, 'X'
     ps2pdf_crop, param.output_dir+'/check_atm_cm_'+strtrim(param.scan_list[param.iscan],2)
  endif

  if keyword_set(ps) and not keyword_set(no_merge_fig) and $
     param.iscan eq n_elements(param.scan_list)-1 then $
        spawn, 'pdftk '+param.output_dir+'/check_atm_cm_*.pdf cat output '+param.output_dir+'/check_atm_cm.pdf'
  if keyword_set(ps) and not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then $
     spawn, 'rm -rf '+param.output_dir+'/check_atm_cm_*.pdf'
  
  !p.multi=0

end
