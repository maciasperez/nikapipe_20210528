;+
;PURPOSE: Compute the transfer function based on input and output
;simulated maps, using FFT and not Poker
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: Plot of the transfer function
;
;LAST EDITION: 
;   12/08/2014: creation
;   08/01/2016: fit and subtract pixel effects, remove TF with NaN
;-

function transfer_function_mpfit,x, p
  return, x*p[0] + (1-exp(-(x-p[1])/p[2]))
end

pro nika_anapipe_transfer_function, param, anapar
  
  mydevice = !d.name
  fwhm1mm = anapar.trans_func_spec.beam.a/60.0
  fwhm2mm = anapar.trans_func_spec.beam.b/60.0
  fov1mm = anapar.trans_func_spec.NIKA_FOV.a
  fov2mm = anapar.trans_func_spec.NIKA_FOV.b
  frac = 10.0

  ;;========== Get the maps
  sn_maps1mm = mrdfits(anapar.trans_func_spec.map_signal.a, 4, head, /SILENT)*1e3
  sn_maps2mm = mrdfits(anapar.trans_func_spec.map_signal.b, 4, head, /SILENT)*1e3

  time_maps1mm = mrdfits(anapar.trans_func_spec.map_signal.a, 7, head, /SILENT)
  time_maps2mm = mrdfits(anapar.trans_func_spec.map_signal.b, 7, head, /SILENT)

  n_maps1mm = mrdfits(anapar.trans_func_spec.map_noise.a, 4, head, /SILENT)*1e3
  n_maps2mm = mrdfits(anapar.trans_func_spec.map_noise.b, 4, head, /SILENT)*1e3

  input_maps1mm = mrdfits(anapar.trans_func_spec.map_in.a, 0, head, /SILENT)*1e3
  input_maps2mm = mrdfits(anapar.trans_func_spec.map_in.b, 0, head, /SILENT)*1e3

  EXTAST, head, astr
  reso = astr.cdelt[1]*3600
  nside = astr.naxis[0]
  fov = nside*reso
  
  ;;========== Defines the k
  kmax = 1.0/reso
  karr = shift(dist(nside,nside),nside/2,nside/2)
  karr = karr/max(karr)*max(kmax)
  
  ;;========== TF for all scans
  Nscan = n_elements(sn_maps1mm[0,0,*])
  for iscan=0, Nscan-1 do begin
     ;;---------- Get the right maps
     time1mm = time_maps1mm[*,*,iscan]
     time2mm = time_maps2mm[*,*,iscan]
     wmask1mm = where(time1mm le 0, nwmask1mm)
     wmask2mm = where(time2mm le 0, nwmask2mm)
     mask1mm = time1mm * 0 + 1
     mask2mm = time2mm * 0 + 1
     if anapar.trans_func_spec.mask eq 'yes' then begin
        if nwmask1mm ne 0 then mask1mm[wmask1mm] = 0
        if nwmask2mm ne 0 then mask2mm[wmask2mm] = 0
        mask1mm = filter_image(mask1mm, fwhm=15.0/reso, /all)
        mask2mm = filter_image(mask2mm, fwhm=15.0/reso, /all)
     endif

     signal1mm = sn_maps1mm[*,*,iscan] * mask1mm
     noise1mm = n_maps1mm[*,*,iscan] * mask1mm
     input1mm = input_maps1mm * mask1mm
     filt1mm = signal1mm - noise1mm

     signal2mm = sn_maps2mm[*,*,iscan] * mask2mm
     noise2mm = n_maps2mm[*,*,iscan] * mask2mm
     input2mm = input_maps2mm * mask2mm
     filt2mm = signal2mm - noise2mm
     
     ;;------- Compute 2D Spectra     
     spec_signal1mm = shift(fft(signal1mm, /double) * conj(fft(signal1mm, /double)),nside/2,nside/2)
     spec_noise1mm = shift(fft(noise1mm, /double) * conj(fft(noise1mm, /double)),nside/2,nside/2)
     spec_input1mm = shift(fft(input1mm, /double) * conj(fft(input1mm, /double)),nside/2,nside/2)
     spec_filt1mm = shift(fft(filt1mm, /double) * conj(fft(filt1mm, /double)),nside/2,nside/2)
     spec_cross1mm = shift(fft(input1mm, /double) * conj(fft(filt1mm, /double)),nside/2,nside/2)
     
     spec_signal2mm = shift(fft(signal2mm, /double) * conj(fft(signal2mm, /double)),nside/2,nside/2)
     spec_noise2mm = shift(fft(noise2mm, /double) * conj(fft(noise2mm, /double)),nside/2,nside/2)
     spec_input2mm = shift(fft(input2mm, /double) * conj(fft(input2mm, /double)),nside/2,nside/2)
     spec_filt2mm = shift(fft(filt2mm, /double) * conj(fft(filt2mm, /double)),nside/2,nside/2)
     spec_cross2mm = shift(fft(input2mm, /double) * conj(fft(filt2mm, /double)),nside/2,nside/2)
     
     ;;---------- Compute 1D spectra
     binkvec = dindgen(nside/2+1)/double(nside/2)*kmax
     kvec = binkvec * 0.0

     signal_spec1mm = dblarr(nside/2+1)
     signal_spec1mm[0] = spec_signal1mm[nside/2,nside/2]
     noise_spec1mm = signal_spec1mm
     noise_spec1mm[0] = spec_noise1mm[nside/2,nside/2]
     input_spec1mm = signal_spec1mm
     input_spec1mm[0] = spec_input1mm[nside/2,nside/2]
     filt_spec1mm = signal_spec1mm
     filt_spec1mm[0] = spec_filt1mm[nside/2,nside/2]
     cross_spec1mm = signal_spec1mm
     cross_spec1mm[0] = spec_cross1mm[nside/2,nside/2]

     signal_spec2mm = dblarr(nside/2+1)
     signal_spec2mm[0] = spec_signal2mm[nside/2,nside/2]
     noise_spec2mm = signal_spec2mm
     noise_spec2mm[0] = spec_noise2mm[nside/2,nside/2]
     input_spec2mm = signal_spec2mm
     input_spec2mm[0] = spec_input2mm[nside/2,nside/2]
     filt_spec2mm = signal_spec2mm
     filt_spec2mm[0] = spec_filt2mm[nside/2,nside/2]
     cross_spec2mm = signal_spec2mm
     cross_spec2mm[0] = spec_cross2mm[nside/2,nside/2]

     for idx=1, nside/2 do begin
        l = where(karr gt binkvec[idx-1] and karr le binkvec[idx], nl)
        if nl gt 1 then begin
           signal_spec1mm[idx] = mean(spec_signal1mm[l])
           noise_spec1mm[idx] = mean(spec_noise1mm[l])
           input_spec1mm[idx] = mean(spec_input1mm[l])
           filt_spec1mm[idx] = mean(spec_filt1mm[l])
           cross_spec1mm[idx] = mean(spec_cross1mm[l])

           signal_spec2mm[idx] = mean(spec_signal2mm[l])
           noise_spec2mm[idx] = mean(spec_noise2mm[l])
           input_spec2mm[idx] = mean(spec_input2mm[l])
           filt_spec2mm[idx] = mean(spec_filt2mm[l])
           cross_spec2mm[idx] = mean(spec_cross2mm[l])

           kvec[idx] = binkvec[idx-1] + (binkvec[idx] -binkvec[idx-1])/2.0 
        endif 
     endfor

     if iscan eq 0 then cross_list1mm = cross_spec1mm else cross_list1mm = [[cross_list1mm], [cross_spec1mm]]
     if iscan eq 0 then noise_list1mm = noise_spec1mm else noise_list1mm = [[noise_list1mm], [noise_spec1mm]]
     if iscan eq 0 then signal_list1mm = signal_spec1mm else signal_list1mm = [[signal_list1mm], [signal_spec1mm]]
     if iscan eq 0 then filt_list1mm = filt_spec1mm else filt_list1mm = [[filt_list1mm], [filt_spec1mm]]
     if iscan eq 0 then input_list1mm = input_spec1mm else input_list1mm = [[input_list1mm], [input_spec1mm]]

     if iscan eq 0 then cross_list2mm = cross_spec2mm else cross_list2mm = [[cross_list2mm], [cross_spec2mm]]
     if iscan eq 0 then noise_list2mm = noise_spec2mm else noise_list2mm = [[noise_list2mm], [noise_spec2mm]]
     if iscan eq 0 then signal_list2mm = signal_spec2mm else signal_list2mm = [[signal_list2mm], [signal_spec2mm]]
     if iscan eq 0 then filt_list2mm = filt_spec2mm else filt_list2mm = [[filt_list2mm], [filt_spec2mm]]
     if iscan eq 0 then input_list2mm = input_spec2mm else input_list2mm = [[input_list2mm], [input_spec2mm]]
  endfor
  
  ;;========== Remove problematic scans
  tf_list1mm = cross_list1mm/input_list1mm
  wkeep1mm = where(finite(total(tf_list1mm, 1)) eq 1, nkeep1mm, comp=wnokeep1mm) ;TF with NaN
  if nkeep1mm ne 0 then tf_list1mm = tf_list1mm[*, wkeep1mm] else message, 'NaN in TF for all scans'
  wkeep1mm = where(abs(tf_list1mm[1,*]) gt median(abs(tf_list1mm[1,*]))-3*stddev(abs(tf_list1mm[1,*])) and $
                   abs(tf_list1mm[1,*]) lt median(abs(tf_list1mm[1,*]))+3*stddev(abs(tf_list1mm[1,*])), $
                   nkeep1mm, comp=wnokeep1mm)
  wkeep1mm = where(abs(tf_list1mm[1,*]) gt median(abs(tf_list1mm[1,wkeep1mm]))-3*stddev(abs(tf_list1mm[1,wkeep1mm])) and $
                   abs(tf_list1mm[1,*]) lt median(abs(tf_list1mm[1,wkeep1mm]))+3*stddev(abs(tf_list1mm[1,wkeep1mm])), $
                   nkeep1mm, comp=wnokeep1mm)
  wkeep1mm = where(abs(tf_list1mm[1,*]) gt median(abs(tf_list1mm[1,wkeep1mm]))-3*stddev(abs(tf_list1mm[1,wkeep1mm])) and $
                   abs(tf_list1mm[1,*]) lt median(abs(tf_list1mm[1,wkeep1mm]))+3*stddev(abs(tf_list1mm[1,wkeep1mm])), $
                   nkeep1mm, comp=wnokeep1mm)

  tf_list2mm = cross_list2mm/input_list2mm
  wkeep2mm = where(finite(total(tf_list2mm, 1)) eq 1, nkeep2mm, comp=wnokeep2mm)
  if nkeep2mm ne 0 then tf_list2mm = tf_list2mm[*, wkeep2mm] else message, 'NaN in TF for all scans'
  wkeep2mm = where(abs(tf_list2mm[1,*]) gt median(abs(tf_list2mm[1,*]))-3*stddev(abs(tf_list2mm[1,*])) and $
                   abs(tf_list2mm[1,*]) lt median(abs(tf_list2mm[1,*]))+3*stddev(abs(tf_list2mm[1,*])), $
                   nkeep2mm, comp=wnokeep2mm)
  wkeep2mm = where(abs(tf_list2mm[1,*]) gt median(abs(tf_list2mm[1,wkeep2mm]))-3*stddev(abs(tf_list2mm[1,wkeep2mm])) and $
                   abs(tf_list2mm[1,*]) lt median(abs(tf_list2mm[1,wkeep2mm]))+3*stddev(abs(tf_list2mm[1,wkeep2mm])), $
                   nkeep2mm, comp=wnokeep2mm)
  wkeep2mm = where(abs(tf_list2mm[1,*]) gt median(abs(tf_list2mm[1,wkeep2mm]))-3*stddev(abs(tf_list2mm[1,wkeep2mm])) and $
                   abs(tf_list2mm[1,*]) lt median(abs(tf_list2mm[1,wkeep2mm]))+3*stddev(abs(tf_list2mm[1,wkeep2mm])), $
                   nkeep2mm, comp=wnokeep2mm)
  
  ;;========== Compute the final TF with errors
  Tk1mm = total(tf_list1mm[*,wkeep1mm], 2)/nkeep1mm
  Tk_err1mm = sqrt(total((tf_list1mm[*,wkeep1mm] - replicate(1,nkeep1mm)##Tk1mm)^2, 2)/(nkeep1mm - 1));; / sqrt(nkeep1mm)

  Tk2mm = total(tf_list2mm[*,wkeep2mm], 2)/nkeep2mm
  Tk_err2mm = sqrt(total((tf_list2mm[*,wkeep2mm] - replicate(1,nkeep2mm)##Tk2mm)^2, 2)/(nkeep2mm - 1));; / sqrt(nkeep2mm)
  
  err_x = kvec*0 + (kvec - shift(kvec,1))[5]/2
  
  ;;========== Fit pixel effects and remove it
  par0 = [0.0, 0.0005, 1.0, 0.0, 1.0]
  par1mm = mpfitfun('transfer_function_mpfit',kvec, Tk1mm, Tk_err1mm, par0, $
                    yfit=yfit,AUTODERIVATIVE=1,/QUIET,covar=covar)
  par2mm = mpfitfun('transfer_function_mpfit',kvec, Tk2mm, Tk_err2mm, par0, $
                    yfit=yfit,AUTODERIVATIVE=1,/QUIET,covar=covar)
  Tk1mm = Tk1mm - par1mm[0]*kvec
  Tk2mm = Tk2mm - par2mm[0]*kvec

  ;;========== DC not measured
  w0 = where(kvec eq 0, nw0)
  if nw0 ne 0 then Tk1mm[w0] = 0
  if nw0 ne 0 then Tk2mm[w0] = 0

  ;;========== Some info
  print, '========== TF - we keep ['+strtrim(nkeep1mm,2)+','+strtrim(nkeep2mm,2)+'] / '+strtrim(Nscan, 2)
  window, /free
  !p.multi = [0,1,2]
  plot, kvec*60, tf_list1mm[*,wkeep1mm[0]], xr=[0,7], yr=[0,1.2],xtitle='Wave numer [arcmin!E-1!N]', ytitle='Transmission',title='1mm'
  for i=0, nkeep1mm-1 do oplot, kvec*60, tf_list1mm[*,wkeep1mm[i]] - par1mm[0]*kvec, col=250.0*(1.0-0.8*float(i-1)/(nkeep1mm-1))
  
  plot, kvec*60, tf_list2mm[*,wkeep2mm[0]], xr=[0,7],yr=[0,1.2],xtitle='Wave numer [arcmin!E-1!N]', ytitle='Transmission',title='2mm'
  for i=0, nkeep2mm-1 do oplot, kvec*60, tf_list2mm[*,wkeep2mm[i]] - par2mm[0]*kvec, col=250.0*(1.0-0.8*float(i-1)/(nkeep2mm-1))
  !p.multi = 0

  ;;========== Make a FITS file for MCMC purposes
  file = param.output_dir+'/TransferFunction.fits'
  tf1mm = {wave_number_arcsec:kvec,$
           tf:Tk1mm,$
           tf_err:Tk_err1mm,$
           reso_ini_arcsec:reso,$
           nside_ini:nside}
  tf2mm = {wave_number_arcsec:kvec,$
           tf:Tk2mm,$
           tf_err:Tk_err2mm,$
           reso_ini_arcsec:reso,$
           nside_ini:nside}
  mwrfits, tf1mm, file, /create, /silent
  bidon = mrdfits(file, 1, head)
  fxaddpar, head, 'CONT1', 'Wave number', '[1/arcsec]'
  fxaddpar, head, 'CONT2', 'Transmission', '[none]'
  fxaddpar, head, 'CONT3', 'Transmission error', '[none]'
  fxaddpar, head, 'CONT5', 'Resolution of the initial map', '[arcsec]'
  fxaddpar, head, 'CONT6', 'Number of pixel along the side', '[none]'
  head1mm = head
  head2mm = head
  mwrfits, tf1mm, file, head1mm, /create, /silent
  mwrfits, tf2mm, file, head2mm, /silent

  ;;========== Plots
  kutil = where(60.0*kvec le 2*sqrt(alog(2)*alog(frac))/!pi/fwhm1mm and kvec ne 0)

  set_plot, 'ps'
  device,/col,bits_per_pixel=256, filename=param.output_dir+'/Transfer_function1mm.ps'
  plot, 60.0*kvec, Tk1mm, $
        xtitle='Wave number (arcmin!U-1!N)', ytitle='Transmission', $
        xstyle=1, ystyle=1, /nodata, charsize=1.5, charthick=3, yr=[0,1.5], xrange=[0,1.2/fwhm1mm]
  oploterror, 60.0*kvec, Tk1mm, 60*err_x, Tk_err1mm, psym=8, col=250, errcol=250
  oplot, [0,0]+2*sqrt(alog(2)*alog(frac))/!pi/fwhm1mm, [0,10], linestyle=3, col=cgcolor('Forest Green'), thick=6
  oplot, [0,0]+1.0/fov1mm, [0,10], linestyle=2, col=cgcolor('Forest Green'), thick=6
  legendastro, [string(100-frac,format='(F4.1)')+'% Beam cutoff'],col=[cgcolor('Forest Green')],$
               thick=thick_plot,symsize=[3], box=0, pos=[2*sqrt(alog(2)*alog(frac))/!pi/fwhm1mm,0.1], CHARTHICK=3
  legendastro, ['1/FOV'],col=[cgcolor('Forest Green')],$
               thick=thick_plot,symsize=[3], box=0, pos=[1.0/fov1mm,0.1], CHARTHICK=3
  device,/close
  ps2pdf_crop, param.output_dir+'/Transfer_function1mm'
  
  device,/col,bits_per_pixel=256, filename=param.output_dir+'/Transfer_function2mm.ps'
  plot, 60.0*kvec, Tk2mm, $
        xtitle='Wave number (arcmin!U-1!N)', ytitle='Transmission', $
        xstyle=1, ystyle=1, /nodata, charsize=1.5, charthick=3, yr=[0,1.5], xrange=[0,1.2/fwhm1mm]
  oploterror, 60.0*kvec, Tk2mm, 60*err_x, Tk_err2mm, psym=8, col=250, errcol=250
  oplot, [0,0]+2*sqrt(alog(2)*alog(frac))/!pi/fwhm2mm, [0,10], linestyle=3, col=cgcolor('Forest Green'), thick=6
  oplot, [0,0]+1.0/fov2mm, [0,10], linestyle=2, col=cgcolor('Forest Green'), thick=6
  legendastro, [string(100-frac,format='(F4.1)')+'% Beam cutoff'],col=[cgcolor('Forest Green')],$
               thick=thick_plot,symsize=[3], box=0, pos=[2*sqrt(alog(2)*alog(frac))/!pi/fwhm2mm,0.1], CHARTHICK=3
  legendastro, ['1/FOV'],col=[cgcolor('Forest Green')],$
               thick=thick_plot,symsize=[3], box=0, pos=[1.0/fov2mm,0.1], CHARTHICK=3
  device,/close
  ps2pdf_crop, param.output_dir+'/Transfer_function2mm'
  
  set_plot, mydevice
  
  return
end
