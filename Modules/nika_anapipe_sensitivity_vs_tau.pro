;+
;PURPOSE: Plot the TOI rms as a function of opacity
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: plot
;
;KEYWORDS:
;
;LAST EDITION: 
;   21/10/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_sensitivity_vs_tau, param, anapar,$
                                     noise_list_1mm, time_list_1mm, $
                                     noise_list_2mm, time_list_2mm
  
  mydevice = !d.name
  set_plot, 'ps'

  ntau = n_elements(param.tau_list.a)
  tau1mm = param.tau_list.A
  tau2mm = param.tau_list.B
  noise1mm = param.mean_noise_list.A
  noise2mm = param.mean_noise_list.B
  el1mm = param.elev_list
  el2mm = param.elev_list

  wok1mm = where(el1mm*180.0/!pi gt 10 and tau1mm gt 0 and finite(noise1mm) eq 1, nwok1mm)
  wok2mm = where(el2mm*180.0/!pi gt 10 and tau2mm gt 0 and finite(noise2mm) eq 1, nwok2mm)
  if nwok1mm ne 0 then noise1mm = noise1mm[wok1mm]
  if nwok2mm ne 0 then noise2mm = noise2mm[wok2mm]
  if nwok1mm ne 0 then tau1mm = tau1mm[wok1mm]
  if nwok2mm ne 0 then tau2mm = tau2mm[wok2mm]
  if nwok1mm ne 0 then el1mm = el1mm[wok1mm]
  if nwok2mm ne 0 then el2mm = el2mm[wok2mm]
  
  if ntau gt 1 then begin
     ;;========== RMS of the 10 best timelines vs tau
     ;;---------- 1mm
     if nwok1mm ge 3 then begin
        x = tau1mm/sin(el1mm)
        y = 1e3*noise1mm*exp(-tau1mm/sin(el1mm))
        fit = POLY_FIT(X, Y, 2, yfit=yfit)
        x2 = dindgen(100)/99*5
        
        device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_noiseVSopacity_1mm.ps'
        plot, tau1mm/sin(el1mm), 1e3*noise1mm*exp(-tau1mm/sin(el1mm)), $
              xtitle='!4s!3/sin(el) (1.25 mm)', $
              ytitle='RMS(TOI) x exp(-!4s!3/sin(el)) (mJy)', /nodata, /ys,charthick=3, charsize=1.5
        oplot, tau1mm/sin(el1mm), 1e3*noise1mm*exp(-tau1mm/sin(el1mm)), $
               psym=8,col=250
        oplot, x2, fit[0]+fit[1]*x2+fit[2]*x2^2, col=150, thick=5
        device,/close
        ps2pdf_crop, param.output_dir+'/'+param.name4file+'_noiseVSopacity_1mm'
     endif

     ;;---------- 2mm
     if nwok2mm ge 3 then begin
        x = tau2mm/sin(el2mm)
        y = 1e3*noise2mm*exp(-tau2mm/sin(el2mm))
        fit = POLY_FIT(X, Y, 2, yfit=yfit)
        x2 = dindgen(100)/99*5
        
        device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_noiseVSopacity_2mm.ps'
        plot, tau2mm/sin(el2mm), 1e3*noise2mm*exp(-tau2mm/sin(el2mm)), $
              xtitle='!4s!3/sin(el) (2.05 mm)', $
              ytitle='RMS(TOI) x exp(-!4s!3/sin(el)) (mJy)', /nodata,/ys,charthick=3, charsize=1.5
        oplot, tau2mm/sin(el2mm), 1e3*noise2mm*exp(-tau2mm/sin(el2mm)),$
               psym=8,col=250   ;, symsize=0.5
        oplot, x2, fit[0]+fit[1]*x2+fit[2]*x2^2, col=150, thick=5
        device,/close
        ps2pdf_crop, param.output_dir+'/'+param.name4file+'_noiseVSopacity_2mm'
     endif

     ;;========== Sensitivity versus tau
     nmap = n_elements(time_list_1mm[0,0,*])
     sens_1mm = dblarr(nmap)
     sens_2mm = dblarr(nmap)

     for iscan=0, nmap-1 do begin
        map_sens_1mm = noise_list_1mm[*,*,iscan]*sqrt(time_list_1mm[*,*,iscan])
        map_sens_2mm = noise_list_2mm[*,*,iscan]*sqrt(time_list_2mm[*,*,iscan])
        
        wsens_1mm = where(finite(map_sens_1mm) eq 1)
        wsens_2mm = where(finite(map_sens_2mm) eq 1)
        
        sens_1mm[iscan] = mean(map_sens_1mm[wsens_1mm])
        sens_2mm[iscan] = mean(map_sens_2mm[wsens_2mm])
     endfor

     if nwok1mm ne 0 then sens_1mm = sens_1mm[wok1mm]
     if nwok2mm ne 0 then sens_2mm = sens_2mm[wok2mm]
     
     ;;---------- 1mm
     if nwok1mm ge 3 then begin
        x = tau1mm/sin(el1mm)
        y = 1e3*sens_1mm*exp(-tau1mm/sin(el1mm))
        fit = POLY_FIT(X, Y, 2, yfit=yfit)
        x2 = dindgen(100)/99*5
        
        device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_sensitivityVSopacity_1mm.ps'
        plot, tau1mm/sin(el1mm), 1e3*sens_1mm*exp(-tau1mm/sin(el1mm)), $
              xtitle='!4s!3/sin(el) (1.25 mm)',$
              ytitle='sensitivity x exp(-!4s!3/sin(el)) (mJy s!E1/2!N)', /nodata, /ys,charthick=3, charsize=1.5;, yr=[15,35]
        oplot, tau1mm/sin(el1mm), 1e3*sens_1mm*exp(-tau1mm/sin(el1mm)), $
               psym=8, col=250
        oplot, x2, fit[0]+fit[1]*x2+fit[2]*x2^2, col=150, thick=5
        legendastro,['Data','Fit: !12y!3 = '+strtrim(string(fit[0],format='(F10.2)'),2)+' + '+strtrim(string(fit[1],format='(F10.2)'),2)+' !12x!3 + '+strtrim(string(fit[2],format='(F10.2)'),2)+' !12x!3!E2!N'],$
                    linestyle=[0,0],psym=[0,0],col=[250,150],thick=[5,5],symsize=[1,1],$
                    box=0,/bottom,/right ;, spacing=[1,1],pspacing=[2,2],
        device,/close
        ps2pdf_crop, param.output_dir+'/'+param.name4file+'_sensitivityVSopacity_1mm'
     endif        

     ;;---------- 2mm
     if nwok2mm ge 3 then begin
        x = tau2mm/sin(el2mm)
        y = 1e3*sens_2mm*exp(-tau2mm/sin(el2mm))
        fit = POLY_FIT(X, Y, 2, yfit=yfit)
        x2 = dindgen(100)/99*5
        
        device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_sensitivityVSopacity_2mm.ps'
        plot, tau2mm/sin(el2mm), 1e3*sens_2mm*exp(-tau2mm/sin(el2mm)), $
              xtitle='!4s!3/sin(el) (2.05 mm)', $
              ytitle='sensitivity x exp(-!4s!3/sin(el)) (mJy s!E1/2!N)', /nodata,/ys,charthick=3, charsize=1.5;,yr=[7,10]
        oplot, tau2mm/sin(el2mm), 1e3*sens_2mm*exp(-tau2mm/sin(el2mm)),$
               psym=8,col=250
        oplot, x2, fit[0]+fit[1]*x2+fit[2]*x2^2, col=150, thick=5
        legendastro,['Data','Fit: !12y!3 = '+strtrim(string(fit[0],format='(F10.2)'),2)+' + '+strtrim(string(fit[1],format='(F10.2)'),2)+' !12x!3 + '+strtrim(string(fit[2],format='(F10.2)'),2)+' !12x!3!E2!N'],$
                    linestyle=[0,0],psym=[0,0],col=[250,150],thick=[5,5],symsize=[1,1],$
                    box=0,/bottom,/right ;, spacing=[1,1],pspacing=[2,2],
        device,/close
        ps2pdf_crop, param.output_dir+'/'+param.name4file+'_sensitivityVSopacity_2mm'
     endif
  endif

  set_plot, mydevice

  return
end
