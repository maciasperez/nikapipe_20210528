function fwhm_stable, flux, fix=fix, weakly_variable=weakly_variable, variable=variable, $
                      step=step, showplot=showplot, $
                      input_fwhm_base=input_fwhm_base, $
                      input_delta_fwhm=input_delta_fwhm, $
                      add1mm = add1mm, png=png, ps=ps, pdf=pdf
  

  ;; no flux dependency
  if keyword_set(fix) then begin
     print,"fixed FWHM"
     if n_elements(fix) eq 3 then fwhm_max   = fix else $
        fwhm_max   = [12.0, 18.0, 12.0]
     print,"values: ", fwhm_max
     fwhm = flux
     for ia = 0, 2 do fwhm[ia, *] = fwhm_max[ia]
     if keyword_set(add1mm) then fwhm[3, *] = fwhm_max[0]
  endif else begin
     ;; variation depending on the flux
     print,"variable FWHM"
     
     fwhm_base  = [11.2, 17.4, 11.2]
     flux_pivot = !nika.flux_uranus
          
     delta_fwhm = [0.5, 0.5, 0.5]
     
     if keyword_set(variable) then delta_fwhm = [0.7, 0.4, 0.7] else $
        if keyword_set(weakly_variable) then delta_fwhm = [0.4, 0.25, 0.4];; [0.5, 0.3, 0.5]
     if keyword_set(step) then begin
        angdiam = 4.0; 3.3 - 4.1
        fwhm_disc = sqrt(fwhm_base^2 + alog(2.0d0)/2.0d0*angdiam^2 )
        delta_fwhm = fwhm_disc-fwhm_base
     endif

     if keyword_set(input_fwhm_base)  then fwhm_base   = input_fwhm_base
     if keyword_set(input_delta_fwhm) then delta_fwhm  = input_delta_fwhm
     
     fwhm = flux
     for ia = 0, 2 do begin
        w=where(flux[ia, *] gt 0.0d0, nw)
        if nw gt 0 then fwhm[ia, w] = 2.0d0*delta_fwhm[ia]/((flux_pivot[ia]/flux[ia, w])^2+1.0d0)+fwhm_base[ia]
     endfor

     if keyword_set(add1mm) then begin
        w=where(flux[3, *] gt 0.0d0, nw)
        if nw gt 0 then fwhm[3, w] = 2.0d0*delta_fwhm[0]/((flux_pivot[0]/flux[3, w])^2+1.0d0)+fwhm_base[0]
     endif
     
     
     if keyword_set(showplot) then begin
        ;ps  = 1
        ;pdf = 1
        
        ;; window size
        wxsize = 550.
        wysize = 400.
        ;; plot size in files
        pxsize = 11.
        pysize =  8.
        ;; charsize
        charsize  = 1.2
        if keyword_set(ps) then charthick = 3.0 else charthick = 1.0
        if keyword_set(ps) then mythick   = 3.0 else mythick = 1.0
        mysymsize   = 0.8

        ;;
        flux_max   = !nika.flux_mars
        fwhm_max   = [13., 18.5, 13.]
        fwhm_max   = [12.0, 18.0, 12.0]
        fm = dblarr(1000., 2)
        fm[*, 0] = dindgen(1000)*flux_max[0]/999.+flux_max[0]/999.
        fm[*, 1] = dindgen(1000)*flux_max[1]/999.+flux_max[1]/999.


        plot_color_convention, col_a1, col_a2, col_a3, $
                               col_mwc349, col_crl2688, col_ngc7027, $
                               col_n2r9, col_n2r12, col_n2r14, col_1mm
        
        quoi = ['A1&A3', 'A2']
        suf  = ['_1mm', '_a2']
        ymi  = [11.0, 17.0]
        yma  = [12.5, 18.5]
        xmi  = [0, 0]
        xma  = [100, 50]
        col_tab = [col_1mm, col_a2]
        legpos = [-10., 0.]
        
        for ilam = 0, 1 do begin
           
           wind, 1, 1, /free, xsize=wxsize, ysize=wysize
           outplot, file='FWHM_stable_empiric_ref'+suf[ilam], png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
           
           plot, fm[*, ilam], $
                 fwhm_base[ilam] + fwhm_max[ilam]/fwhm_base[ilam]/(1.0d0+(flux_pivot[ilam]/fm[*, ilam])^2), $
                 yr=[ymi[ilam], yma[ilam]], /ys, ytitle='Stable condition FWHM [arcsec]',  $
                 xtitle='Flux density [Jy/beam]', xr=[xmi[ilam], xma[ilam]], /nodata, charsize=charsize
           ;;delta_fwhm = [0.4, 0.3, 0.4]
           ;;oplot,  fm[*, 0], fwhm_base[0]+2.0d0*delta_fwhm[0]/(1.0d0+(flux_pivot[0]/fm[*, 0])^2), col=col_a1
           ;;delta_fwhm = [0.7, 0.4, 0.7]
           ;;oplot,  fm[*, 0], fwhm_base[0]+2.0d0*delta_fwhm[0]/(1.0d0+(flux_pivot[0]/fm[*,0])^2), col=col_a3
           oplot,  fm[*, ilam], fwhm_base[ilam]+2.0d0*delta_fwhm[ilam]/(1.0d0+(flux_pivot[ilam]/fm[*, ilam])^2), col=col_tab[ilam], thick=mythick
           oplot, [flux_pivot[ilam], flux_pivot[ilam]], [ymi[ilam], yma[ilam]], col=0, linestyle=2, thick=mythick
           ;;stop
           oplot, [xmi[ilam], xma[ilam]], (fwhm_base[ilam]+delta_fwhm[ilam])*[1., 1.], col=0, linestyle=2, thick=mythick
           ;;oplot, [0, flux_max[0]], fwhm_max[0]*[1.,1.], col=150
           ;;legendastro, ['fix', 'variable1', 'variable2'],
           ;;textcol=[150, 80, 250], box=0
           legendastro, [quoi[ilam]], box=0, col=0, charsize=charsize, pos=[xma[ilam]-0.15*(xma[ilam]-xmi[ilam])+legpos[ilam], yma[ilam]-0.15*(yma[ilam]-ymi[ilam])]

           outplot, /close

           if keyword_set(pdf) then $
              spawn, 'epspdf --bbox FWHM_stable_empiric_ref'+suf[ilam]+'.eps'
           
        endfor
           
        

        ;; restore default color table
        loadct, 39
        stop
     endif
  endelse

  ;stop
  
  return, fwhm
  
end


pro photometric_correction, flux, fwhm, corr_flux_factor, $
                            fix=fix, weakly_variable=weakly_variable, variable=variable,$
                            step=step, showplot=showplot, delta_fwhm=delta_fwhm, $
                            input_fwhm_base=input_fwhm_base, input_delta_fwhm=input_delta_fwhm, $
                            add1mm=add1mm

  ;; flux = [flux_A1, flux_A2, flux_A3]
  ;; fwhm = [fwhm_A1, fwhm_A2, fwhm_A3]

  ;; if keyword_set(add1mm) then
  ;; flux = [flux_A1, flux_A2, flux_A3, flux_1mm]
  ;; fwhm = [fwhm_A1, fwhm_A2, fwhm_A3, fwhm_1mm]


  if keyword_set(fix) then print, "photometric correction: fixed FWHM " else $
     if keyword_set(weakly_variable) then print, "photometric correction: weakly variable FWHM " else $
        if keyword_set(variable) then print, "photometric correction: variable FWHM " else $
           print,  "photometric correction: default param"
  if keyword_set(delta_fwhm) then print, "Modified variable 1 photometric correction"

  
  if keyword_set(delta_fwhm) then begin
     for ia=0, 2 do fwhm[ia, *] = fwhm[ia, *] - delta_fwhm[ia]
     if keyword_set(add1mm) then fwhm[3, *] = fwhm[3, *] - delta_fwhm[0]
  endif
  
  fwhm_st = fwhm_stable(flux, fix=fix, weakly_variable=weakly_variable, variable=variable, step=step, showplot=showplot, input_fwhm_base=input_fwhm_base, input_delta_fwhm=input_delta_fwhm, add1mm=add1mm)
  corr_flux_factor = fwhm_st
  for ia=0, 2 do corr_flux_factor[ia, *] = (fwhm[ia, *]^2 + !nika.fwhm_array[ia]^2)/(fwhm_st[ia, *]^2 + !nika.fwhm_array[ia]^2)

  if keyword_set(add1mm) then corr_flux_factor[3, *] = (fwhm[3, *]^2 + !nika.fwhm_array[0]^2)/(fwhm_st[3, *]^2 + !nika.fwhm_array[0]^2)
  
end
