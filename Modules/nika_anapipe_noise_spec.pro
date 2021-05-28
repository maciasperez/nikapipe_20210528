;+
;PURPOSE: Compute the spectral index of the noise
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: give the amplitude and slope of the noise. Also provide plots
;
;KEYWORDS: 
;
;LAST EDITION: 
;   08/12/2014: creation
;   04/07/2015: add keywords par1/2mm
;
;-

pro nika_anapipe_noise_spec, param, anapar, $
                             map_1mm, noise_1mm, noise_nfm_1mm, time_1mm, $
                             map_2mm, noise_2mm, noise_nfm_2mm, time_2mm,$
                             map_list_1mm, noise_list_1mm, noise_list_nfm_1mm, time_list_1mm, $
                             map_list_2mm, noise_list_2mm, noise_list_nfm_2mm, time_list_2mm,$
                             head_1mm, head_2mm, $
                             par2mm=par2mm, par1mm=par1mm
  ;;==========
  ;;WARNING: the output of this code works with e.g.
  ;; icm_mapcovmat.pro and nika_anapipe_nefd_spec.pro
  ;; So if you change something, please make sure it is still
  ;; compatible with these other routines and contact Remi Adam
  ;;==========

  mydevice = !d.name

  ;;------- Get the resolution of the maps
  EXTAST, head_1mm, astr1mm
  EXTAST, head_2mm, astr2mm
  reso1mm = astr1mm.cdelt[1]*3600
  reso2mm = astr2mm.cdelt[1]*3600
  reso = reso1mm

  nmap = n_elements(map_list_1mm[0,0,*])
  if nmap eq 1 then message, /info, '========== Cannot compute Jack-Knife since only one scan is available'
  if nmap eq 1 then return

  Ntest = anapar.noise_meas.noise_NJK
  pars1mm = dblarr(3, Ntest)
  pars2mm = dblarr(3, Ntest)
  for itest=0, Ntest-1 do begin
     ;;========== Get a noise realisation and the mask
     ordre = sort(randomn(seed, nmap))
     map_jk_1mm = nika_anapipe_jackknife(map_list_1mm[*,*,ordre], (noise_list_1mm[*,*,ordre])^2)
     map_jk_2mm = nika_anapipe_jackknife(map_list_2mm[*,*,ordre], (noise_list_2mm[*,*,ordre])^2)
     map_jk_1mm *= 0.5
     map_jk_2mm *= 0.5
     
     map_sens_1mm = map_jk_1mm/noise_nfm_1mm ;Warning: in case very different kind of scans we would need 
     map_sens_2mm = map_jk_2mm/noise_nfm_2mm ;to have the time normalisation for the given scans
     
     wsens_1mm = where(finite(map_sens_1mm) eq 1 and $
                       noise_nfm_1mm gt 0 and finite(noise_nfm_1mm) ne 0 and $
                       map_jk_1mm ne 0, nwsens_1mm,comp=wnosens_1mm,ncomp=nwnosens_1mm)
     wsens_2mm = where(finite(map_sens_2mm) eq 1 and $
                       noise_nfm_2mm gt 0 and finite(noise_nfm_2mm) ne 0 and $
                       map_jk_2mm ne 0, nwsens_2mm,comp=wnosens_2mm,ncomp=nwnosens_2mm)
     if nwsens_1mm eq 0 then message, 'No pixel available for Jack-Knife'
     if nwsens_2mm eq 0 then message, 'No pixel available for Jack-Knife'
     
     if nwnosens_1mm ne 0 then map_sens_1mm[wnosens_1mm] = 0
     if nwnosens_2mm ne 0 then map_sens_2mm[wnosens_2mm] = 0
     
     mask1mm = map_sens_1mm * 0
     mask1mm[wsens_1mm] = 1
     if nwnosens_1mm eq 0 then byp1mm = 1 else byp1mm = 0 ;Faster in Poker
     
     mask2mm = map_sens_2mm * 0
     mask2mm[wsens_2mm] = 1
     if nwnosens_2mm eq 0 then byp2mm = 1 else byp2mm = 0 ;Faster in Poker
     
     ;;========== Get a spectrum
     if itest eq Ntest-1 then clean = 1 else clean = 0

     ipoker, map_sens_1mm, reso/60.0, k1mm, pk1mm, sigma_pk1mm, mask=mask1mm, rem=1, clean=clean, bypass=byp1mm
     pk1mm = pk1mm *(180.0/!pi*3600.0/reso)^2
     sigma_pk1mm = sigma_pk1mm *(180.0/!pi*3600.0/reso)^2
     k1mm = k1mm * !arcmin2rad  ;/ (2*!pi)
     
     ipoker, map_sens_2mm, reso/60.0, k2mm, pk2mm, sigma_pk2mm, mask=mask2mm, rem=1, clean=clean, bypass=byp2mm
     pk2mm = pk2mm *(180.0/!pi*3600.0/reso)^2
     sigma_pk2mm = sigma_pk2mm *(180.0/!pi*3600.0/reso)^2
     k2mm = k2mm * !arcmin2rad  ;/ (2*!pi)
     
     ;;========= Fit the spectrum with a a1 k^beta+a0 law
     ;;---------- 1mm
     weights1mm = k1mm          ;Spectrum slope is close to -1 so weight for having log fit (first guess)
     parinfo1mm = replicate({value:0.D,fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
     parinfo1mm[2].limited = [1,0]
     parinfo1mm[2].limits = [0.0,0.0]
     
     par01mm = [mean(pk1mm[n_elements(pk1mm)/2:*]), -1.0, mean(pk1mm[n_elements(pk1mm)/2:*])]
     
     par1mm = mpfitfun('power_spec_mpfit',k1mm, pk1mm, 0, par01mm, $
                       weights=weights1mm, parinfo=parinfo1mm, yfit=yfit1mm, AUTODERIVATIVE=1, /QUIET)
     
     ;;weights1mm = k1mm^(-par1mm[1]) ;Spectrum slope used for weigthing
     ;;par1mm = mpfitfun('power_spec_mpfit',k1mm, pk1mm, 0, par01mm, $
     ;;                  weights=weights1mm,parinfo=parinfo1mm,yfit=yfit1mm,AUTODERIVATIVE=1,/QUIET)
     
     ;;---------- 2mm
     weights2mm = k2mm          ;Spectrum slope is close to -1 so weight for having log fit (first guess)
     parinfo2mm = replicate({value:0.D,fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
     parinfo2mm[2].limited = [1,0]
     parinfo2mm[2].limits = [0.0,0.0]
     
     par02mm = [mean(pk2mm[n_elements(pk2mm)/2:*]), -1.0, mean(pk2mm[n_elements(pk2mm)/2:*])]
     
     par2mm = mpfitfun('power_spec_mpfit',k2mm, pk2mm, 0, par02mm, $
                       weights=weights2mm, parinfo=parinfo2mm, yfit=yfit2mm, AUTODERIVATIVE=1, /QUIET)
     
     ;;weights2mm = k2mm^(-par2mm[1]) ;Spectrum slope used for weigthing
     ;;par2mm = mpfitfun('power_spec_mpfit',k2mm, pk2mm, 0, par02mm, $
     ;;                  weights=weights2mm,parinfo=parinfo2mm,yfit=yfit2mm,AUTODERIVATIVE=1,/QUIET)

     pars1mm[*,itest] = par1mm
     pars2mm[*,itest] = par2mm
  endfor
  save, filename=param.output_dir+'/NoiseSpecFit.save', pars1mm, pars2mm, k1mm, k2mm

  ;;========== Plot the spectra  
  beam = [2*!pi/(12.0/60.0), 2*!pi/(18.0/60.0)]
  FOV = [2*!pi/2.0, 2*!pi/2.0]

  set_plot, 'ps'
  ;;1mm
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_Noise_Spectrum_1mm.ps'
  ploterror, k1mm, pk1mm, sigma_pk1mm, $
             xtitle='k (arcmin!E-1!N)', ytitle='P!Ik!N (JK/Naive noise)',$
             psym=8, /xlog, /ylog, xr=[min(k1mm/1.1), max(k1mm*1.1)], yr=[min(pk1mm/1.5), max(pk1mm*1.5)], $
             ystyle=1, xstyle=1, /nodata,$
             charsize=1.5, charthick=3
  oploterror, k1mm, pk1mm, sigma_pk1mm,$
              col=0, errcolor=0, errthick=2, psym=8, symsize=0.7
  oplot, k1mm, yfit1mm, col=250, thick=3
  oplot, k1mm, par1mm[2] + k1mm*0, col=150, linestyle=2, thick=3
  oplot, k1mm, par1mm[0]*k1mm^par1mm[1], col=150, linestyle=2, thick=3
  oplot, [0,0]+fov[0], [0.01,100], linestyle=2, col=200, thick=6

  legendastro, ['Best fit: '+strtrim(par1mm[2],2)+' + '+strtrim(par1mm[0],2)+$
                ' x (k!I1 arcmin!E-1!N!N)!U'+strtrim(par1mm[1],2), '2!4p!3/2arcmin, FOV'],$
               col=[250,200],psym=[0,0],linestyle=[0,2],thick=[4,4], box=0,/right,/top, charsize=1
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_Noise_Spectrum_1mm'
  
  ;;2mm
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_Noise_Spectrum_2mm.ps'
  ploterror, k2mm, pk2mm, sigma_pk2mm, $
             xtitle='k (arcmin!E-1!N)', ytitle='P!Ik!N (Jk/Naive noise)',$
             psym=8, /xlog, /ylog, xr=[min(k2mm/1.1), max(k2mm*1.1)], yr=[min(pk2mm/1.5), max(pk2mm*1.5)],$
             ystyle=1, xstyle=1, /nodata, $
             charsize=1.5, charthick=3
  oploterror, k2mm, pk2mm, sigma_pk2mm,$
              col=0, errcolor=0, errthick=2, psym=8, symsize=0.7
  oplot, k2mm, yfit2mm, col=250, thick=3
  oplot, k2mm, par2mm[2] + k2mm*0, col=150, linestyle=2, thick=3
  oplot, k2mm, par2mm[0]*k2mm^par2mm[1], col=150, linestyle=2, thick=3
  oplot, [0,0]+fov[1], [0.01,100], linestyle=2, col=200, thick=6
  legendastro, ['Best fit: '+strtrim(par2mm[2],2)+' + '+strtrim(par2mm[0],2)+$
                ' x (k!I1 arcmin!E-1!N!N)!U'+strtrim(par2mm[1],2), '2!4p!3/2arcmin, FOV'],$
 col=[250,200],psym=[0,0],linestyle=[0,2],thick=[4,4], box=0,/right,/top, charsize=1
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_Noise_Spectrum_2mm'

  set_plot, mydevice

  return
end
