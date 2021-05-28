pro plot_photometric_correction

  png = 0
  ps  = 1
  pdf = 1

  
  photocorr = 1
  fix_photocorr   = 0
  variable        = 0
  weakly_variable = 1
  delta_fwhm      = 0   ;; use default value
  delta_stable    = [0., 0., 0.]  ;; use default value

  ;; variable fwhm from 10 to 20
  fwhm_min = 10.
  fwhm_max = 20.
  ntest = 1000.
  fwhm_arr = dindgen(ntest)/ntest*(fwhm_max-fwhm_min) + fwhm_min
  fwhm = transpose([[fwhm_arr],[fwhm_arr],[fwhm_arr],[fwhm_arr]])
  
  ;; reference flux
  f_150 = 1.0
  f_260 = 1.0 ;f_150 * (260./150.)^2
  
  flux_1 = [f_260, f_260, f_150, f_260] ;; Jy
  flux_2 = [!nika.flux_uranus, !nika.flux_uranus[0]]

  ;; call to compile fwhm_stable
  photometric_correction, flux_1, fwhm[*, 0], corr_flux_factor,weakly_variable=1, add1mm=1
  
  fwhm_star_1 = fwhm_stable(flux_1,  weakly_variable=1, add1mm=1)
  fwhm_star_2 = fwhm_stable(flux_2,  weakly_variable=1, add1mm=1)

  corr_flux_factor_1 = dblarr(4, ntest)
  for ia=0, 2 do corr_flux_factor_1[ia, *] = (fwhm[ia, *]^2 + !nika.fwhm_array[ia]^2)/(fwhm_star_1[ia]^2 + !nika.fwhm_array[ia]^2)
  corr_flux_factor_1[3, *] = (fwhm[3, *]^2 + !nika.fwhm_array[0]^2)/(fwhm_star_1[3]^2 + !nika.fwhm_array[0]^2)

  corr_flux_factor_2 = dblarr(4, ntest)
  for ia=0, 2 do corr_flux_factor_2[ia, *] = (fwhm[ia, *]^2 + !nika.fwhm_array[ia]^2)/(fwhm_star_2[ia]^2 + !nika.fwhm_array[ia]^2)
  corr_flux_factor_2[3, *] = (fwhm[3, *]^2 + !nika.fwhm_array[0]^2)/(fwhm_star_2[3]^2 + !nika.fwhm_array[0]^2)

  
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14, col_1mm

;; window size
  wxsize = 700.
  wysize = 400.
  ;; plot size in files
  pxsize = 14.
  pysize =  8.
  ;; charsize
  charsize  = 1.
  if keyword_set(ps) then charthick = 2.0 else charthick = 1.0 
  if keyword_set(ps) then thick     = 3.0 else thick = 1.0
  symsize   = 1.
  outdir = '/home/perotto/NIKA/Plots/Performance_plots/'
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
  outfile = outdir+'photometric_correction_function_1Jy'
  outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
  plot, reform(fwhm[3, *]),reform(fwhm[3, *]), xrange = [fwhm_min, fwhm_max], /xs, yrange= [0.6, 1.4], /ys, /nodata, xtitle="FWHM' [arcsec]", ytitle='Photometric correction f'
  oplot, reform(fwhm[3, *]),  reform(corr_flux_factor_2[3, *]), col= col_1mm, thick=2*thick
  oplot, reform(fwhm[1, *]),  reform(corr_flux_factor_2[1, *]), col= col_a2, thick=2*thick
  oplot, reform(fwhm[3, *]),  reform(corr_flux_factor_1[3, *]), col= col_1mm, thick=1*thick
  oplot, reform(fwhm[1, *]),  reform(corr_flux_factor_1[1, *]), col= col_a2, thick=1*thick
  oplot, [fwhm_min, fwhm_max], [1., 1.], col=0
  oplot, [11.2, 11.2], [0.5, 2.], col=col_1mm
  oplot, [17.4, 17.4], [0.5, 2.], col=col_a2
  
  legendastro, ['1 mm', '2 mm'], col=[col_1mm, col_a2], textcol=[col_1mm, col_a2], box=0, charsize=charsize, pos=[18.5, 0.7]

  outplot, /close
 
  if pdf gt 0 then spawn, 'epstopdf '+outfile+'.eps'

  stop
  
end
