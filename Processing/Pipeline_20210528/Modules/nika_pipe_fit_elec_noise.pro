;+
;PURPOSE: Fit the electronique noise spectrum after having removed the atmosphere
;
;INPUT: The parameter, the data and the kidpar structures
;
;LAST EDITION: -05/01/2015: creation
;
;-

function power_spec_mpfit,x,p
  return, p[0] * x^(p[1]) + p[2]
end

pro nika_pipe_fit_elec_noise, param, data, kidpar

  N_pt = n_elements(data)
  n_kid = n_elements(kidpar)
  won = where(kidpar.type eq 1, non)   ; Number of detector ON
  woff = where(kidpar.type eq 2, noff) ; Number of detector OFF

  time = dindgen(n_elements(data))/!nika.f_sampling

  ;;---------- Blocs
  bloc_value = long(kidpar.numdet)/long(80)
  Nbloc = max(bloc_value)

  SET_PLOT, 'PS'
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/check_elec_cm_'+strtrim(param.scan_list[param.iscan],2)+'.ps'

  for ibloc = 0, Nbloc-1 do begin
     bloc = where(bloc_value eq ibloc, nkid_bloc)
     if nkid_bloc gt 3 then begin
        ;;---------- Get CM
        w8source = 1 - data.on_source_dec[bloc]
        kidpar_bloc = kidpar[bloc]
        TOI = data.RF_dIdQ[bloc]
        nika_pipe_subtract_common_atm, param, TOI, kidpar_bloc, w8source, $
                                       eln, base, $
                                       elev=data.el, ofs_el=data.ofs_el, k_median=k_median

        ;;---------- Get PS and fit
        power_spec, eln, !nika.f_sampling, pw, freq
        weights = freq          ;Spectrum slope is close to -1 so weight for having log fit (first guess)
        parinfo = replicate({value:0.D,fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
        parinfo[2].limited = [1,0]
        parinfo[2].limits = [0.0,0.0]
        
        par0 = [mean(pw[n_elements(pw)/2:*]), -1.0, mean(pw[n_elements(pw)/2:*])]
        
        par = mpfitfun('power_spec_mpfit',freq, pw, 0, par0, $
                          weights=weights, parinfo=parinfo, yfit=yfit, AUTODERIVATIVE=1, /QUIET)
        
        weights = freq^(-par[1]) ;Spectrum slope used for weigthing
        par = mpfitfun('power_spec_mpfit',freq, pw, 0, par0, $
                       weights=weights,parinfo=parinfo,yfit=yfit,AUTODERIVATIVE=1,/QUIET)
        
        ;;---------- Plot
        !p.multi=[0,2,2]
        plot, time, eln, xtitle='Time (s)', ytitle='Flux (Jy)', title=' common mode TOI block'+strtrim(ibloc,2),/xs, /ys, charsize=0.7 
        plot_oo, freq, pw, xtitle='Frequency (Hz)', ytitle='P(f) (Jy.Hz!U-1/2!N)', title=' common mode PS block'+strtrim(ibloc,2),/xs, /ys,charsize=0.7, yr=[0.0001,10]
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
        legendastro, ['Best fit: '+strtrim(string(par[2], format='(F10.6)'),2)+' + '+strtrim(string(par[0], format='(F10.6)'),2)+$
                      ' x !12f!3!U'+strtrim(string(par[1], format='(F10.6)'),2)],box=0,/right,/top, charsize=0.7
        cgText, 0.5, 1.0, ALIGNMENT=0.5, CHARSIZE=1.25, /NORMAL, strtrim(param.scan_list[param.iscan],2)
        !p.multi=0
     endif
  endfor
  device,/close
  SET_PLOT, 'X'
  ps2pdf_crop, param.output_dir+'/check_elec_cm_'+strtrim(param.scan_list[param.iscan],2)
  
end
