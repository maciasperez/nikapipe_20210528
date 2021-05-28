pro plot_flatfields, kidpar_file, plotwhat, el_avg_deg, tau225, use_tau225=use_tau225, no_opacorr=no_opacorr, $
                     saveplot=saveplot, kidpar=kidpar, mooncut_a1=mooncut_a1, normalization=normalization,$
                     png_nickname=png_nickname, project_dir = project_dir

  ;; plotwhat : gain, gain_aperphot, mbff, fbff  

  if kidpar_file eq '' then nickname = '' else nickname=file_basename(kidpar_file, '.fits')
  if keyword_set(png_nickname) then nickname=nickname+png_nickname

  
  charsize = 0.6

  normalised = 0
  if keyword_set(normalization) then normalised=1
  
  if plotwhat eq 'gain' then begin
     field = 'calib_fix_fwhm'
     format='(f6.1)'
     zrg = 0
     title = 'Main beam FF in (Hz/beam) / Jy'
     histo_title = "Gain [(Hz/beam)/Jy]"
     histo_min   = 20
     histo_max   = 300
     histo_bin   = 4
  endif else if plotwhat eq 'gain_aperphot' then begin
     field = 'calib_fix_fwhm'
     format='(f6.1)'
     zrg = 0
     title  = 'Main beam FF in Hz/Jy'
     histo_title = "Gain [Hz/Jy]"
     histo_min   = 20
     histo_max   = 300
     histo_bin   = 4
  endif else if plotwhat eq 'gain_peak' then begin
     field = 'calib'
     format='(f6.1)'
     zrg = 0
     title  = 'Peak amplitude FF in Hz/Jy'
     histo_title = "Gain [Hz/Jy]"
     histo_min   = 20
     histo_max   = 300
     histo_bin   = 4
  endif else if plotwhat eq 'mbff' then begin
     field = 'calib_fix_fwhm'
     format='(f8.1)'
     zrg = 0
     title = 'Main beam FF in mJy / (Hz/beam)'
     histo_title = "Gain [mJy / (Hz/beam)]"
     histo_min   = 0.
     histo_max   = 20.
     histo_bin   = 0.5
  endif else if plotwhat eq 'fbff' then begin
     field = 'corr2cm'
     format='(f7.2)'
     zrg = 0
     title = 'Forward beam FF'
     histo_title = "Corr to CM"
     histo_min   = 0
     histo_max   = 2
     histo_bin   = 0.02
  endif else if plotwhat eq 'apeak' then begin
     field = 'a_peak'
     format='(f8.1)'
     zrg = 0
     title = 'Peak flux in Hz'
     histo_title = "A_peak [Hz]"
     histo_min   = 800.
     histo_max   = 8000.
     histo_bin   = 50.
  endif else if plotwhat eq 'noise' then begin
     field = 'calib'
     format='(f8.1)'
     zrg = 0
     title = 'NEP in mJy/sqrt(Hz)'
     histo_title = "NEP [mJy/sqrt(Hz)]"
     histo_min   = 0.
     histo_max   = 100.
     histo_bin   = 1.
  endif else begin
     field = plotwhat
     format='(f6.2)'
     zrg = 0
     title = plotwhat
     histo_title = plotwhat
     histo_min   = 0
     histo_max   = 0
     histo_bin   = 0
  endelse

  letsgo = 1
  if kidpar_file ne '' then kp = mrdfits(kidpar_file, 1) else $
     if keyword_set(kidpar) then kp=kidpar else begin
     print, "input kidpar needed..."
     letsgo = 0
  endelse

  if letsgo gt 0 then begin
     array_tab = [1, 3, 2]
     char_tab  = [0.5, 0.5, 0.8]
     charsize = 0.8
     
     if keyword_set(use_tau225) then begin
        
        ;; faut un truc pour recuperer tau_225
        ;;tau225 = 0.15
        ;; simple nu2
        ;;tau1mm = tau225 * (250./225.)*(250./225.)
        ;;tau2mm = tau225 * (160./225.)*(160./225.)
        ;; fit from :
        ;; atm_model_mdp, atm_tau1_p1, atm_tau2_p1, atm_tau3_p1,
        ;; atm_tau_225, nostop=1, bpshift=1.5, /tau225
        ;; atm_model_mdp, atm_tau1_p1, atm_tau2_p1, atm_tau3_p1, atm_tau_225, nostop=1, bpshift=0, /tau225,  bpfiltering=1
        tau1mm = tau225 * 1.24170
        tau2mm = tau225 * 0.514786 +0.02
        
        mytau = [tau1mm, tau1mm, tau2mm]
     endif
     if keyword_set(no_opacorr) then mytau = dblarr(3)
     
     kp_tags  = tag_names( kp)
     wfield = where( strupcase(kp_tags) eq strupcase(field), nwfield)

     
     wind, 1, 1,  xsize = 1200, ysize =  400, /free
     for ilam=0, 2 do begin
        iarray = array_tab[ilam]
        w1 = where(kp.type eq 1 and kp.array eq iarray, n1)

        if n1 gt 0 then begin
           nas_x = kp(w1).nas_x
           nas_y = kp(w1).nas_y
           corr2cm  = kp(w1).corr2cm
           calib    = kp(w1).calib_fix_fwhm
           noise    = kp(w1).noise
           fov   = (kp.(wfield))[w1]

           stop
           
           if keyword_set(use_tau225) or keyword_set(no_opacorr) then begin
              print,"tau_skydip = ", mean(kp[w1].tau_skydip)
              el_avg_rad = el_avg_deg*!dtor
              tau = mytau[ilam]
              opacor = exp((kp[w1].tau_skydip-tau)/sin(el_avg_rad))
              fov  = fov*opacor
           endif

           
           if plotwhat eq 'noise' then fov = noise*fov*1.d3 ; mJy/sqrt(Hz)
           
           if iarray eq 1 and keyword_set(mooncut_a1) then begin
              
              angle = 13.*!dtor
              rot_x = nas_x*cos(angle) + nas_y*sin(angle)
              rot_y = -1*nas_x*sin(angle) + cos(angle)*nas_y
              
              wok = where(((rot_x-100.)^2 + rot_y^2) lt 3d4, nmoon, compl=wmoon)
              nas_x = rot_x(wok)*cos(angle) - rot_y(wok)*sin(angle)
              nas_y = rot_x(wok)*sin(angle) + cos(angle)*rot_y(wok)
              fov = fov(wok)
           endif

           if (plotwhat eq 'gain' or plotwhat eq 'gain_aperphot' or plotwhat eq 'gain_peak') then fov = 1.d0/fov
           if plotwhat eq 'mbff' then fov = 1000.d0*fov
           
           if (normalised gt 0.) then begin
              med = median(fov)
              fov = fov/med 
              zrg = [0.7, 1.3]
              format='(f6.2)'
           endif
        
           ;; plot
           xra = [-220, 220]
           yra = [-220, 220]
           
           zr = zrg
           matrix_plot, nas_x, nas_y, fov, xtitle='Nasmyth offset x', ytitle='Nasmyth offset y',title = 'Array '+strtrim(iarray, 2)+': '+title, xr = xra, yr=yra, /iso, format=format, charsize=charsize, symsize=char_tab[ilam], position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], zr=zr, /noerase
        endif else print, 'no valid KIDs'
           
        
     endfor
     
     if keyword_set(saveplot) then begin
        if keyword_set(project_dir) then pdir = project_dir else pdir = !nika.plot_dir+"/Flats"
        if file_test(project_dir, /dir) eq 0 then spawn, 'mkdir '+project_dir
        png = project_dir+'/fov_maps_'+strtrim(plotwhat)+'_'+nickname+'.png'
        WRITE_PNG, png, TVRD(/TRUE)
     endif
     
     
     
;; plot histograms
;;==================================================================
     wind, 1, 1, xsize = 1200, ysize =  350, /free
     for ilam=0, 2 do begin
        iarray = array_tab[ilam]
        w1 = where(kp.type eq 1 and kp.array eq iarray, n1)
        if n1 ge 2 then begin
           nas_x = kp(w1).nas_x
           nas_y = kp(w1).nas_y
           corr2cm = kp(w1).corr2cm
           calib   = kp(w1).calib_fix_fwhm
           noise   = kp(w1).noise
           fov     = (kp.(wfield))[w1]
           
           if keyword_set(use_tau225) or keyword_set(no_opacorr) then begin
              el_avg_rad = el_avg_deg*!dtor
              tau = mytau[ilam]
              opacor = exp((kp[w1].tau_skydip-tau)/sin(el_avg_rad))
              fov  = fov*opacor
           endif
           
           
           if plotwhat eq 'noise' then fov = noise*fov*1.d3 ; mJy/sqrt(Hz)
           
           if (plotwhat eq 'gain' or plotwhat eq 'gain_aperphot' or plotwhat eq 'gain_peak') then fov = 1.d0/fov
           if plotwhat eq 'mbff' then fov = 1000.d0*fov
           
           if iarray eq 1 and keyword_set(mooncut_a1) then begin
              emin = histo_min
              emax = histo_max+0.4
              
              angle = 13.*!dtor
              rot_x = nas_x*cos(angle) + nas_y*sin(angle)
              rot_y = -1*nas_x*sin(angle) + cos(angle)*nas_y
              
              wok = where(((rot_x-100.)^2 + rot_y^2) lt 3d4, nmoon, compl=wmoon)
              
              data_str = {fov:fov, fovok:reform(fov(wok), nok), fovmoon:reform(fov(wmoon),nmoon)}
              ;; use np_histo instead of np_histo_lp
              np_histo, data_str, out_xhist, out_yhist, out_gpar, min=emin, max=emax, binsize=histo_bin, $
                           xrange=[emin, emax], fcol=[80, 118, 220], fit=1, plotfit=0, noerase=1,$
                           position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], nolegend=1, $
                           colorfit=[50], thickfit=ps_thick, nterms_fit=3, xtitle="A"+strtrim(iarray, 2)+": "+histo_title
              
              leg_txt = ['N: '+num2string(n_elements(data_str.(0))), $
                         'Avg: '+num2string(out_gpar[0,1]), $
                         '!7r!3: '+num2string(out_gpar[0,2]), $
                         'N: '+num2string(n_elements(data_str.(1))), $
                         'Avg: '+num2string(out_gpar[1,1]), $
                         '!7r!3: '+num2string(out_gpar[1,2]), $
                         'N: '+num2string(n_elements(data_str.(2)))]
              
              legendastro, leg_txt, textcol=[80, 80, 80, 120, 120, 120, 220], box=0, charsize=1, /right
              
              ;; HIST_PLOT, fov(wmoon), MIN=histo_min, MAX=histo_max, noplot=1, $
              ;;            BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=0, FILL=FILL, X=X1,Y=Y1, hist=hist
              ;; HIST_PLOT, fov(wok), MIN=histo_min, MAX=histo_max, noplot=0, $
              ;;            BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=1, fitgauss=1, FILL=FILL, X=X2,Y=Y2, $
              ;;            xtitle="A"+strtrim(iarray, 2)+": "+histo_title, $
              ;;            position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], $
              ;;            noerase=1, xstyle=1, charsize=charsize 
              
              ;; oplot, x1, y1, col=250
              
              ;; gpar=fltarr(3)
              
              ;; sum=total(hist)
              ;; GPAR[0]=float(SUM[0])
              
              ;; mom=moment(fov(wmoon),sdev=sdev)
              ;; print,mom
              ;; GPAR[1]=float(mom[0])
              ;; GPAR[2]=float(sdev)
              
              ;; gauss = exp(-1.*(x1 - GPAR[1])^2/2./GPAR[2]^2)*max(hist) ;/GPAR[2]/sqrt(2.*!dpi)
              
              ;; oplot,x1,gauss,color=250
              
              ;; legendastro,['N='+string(gpar[0]), $
              ;;              'm='+string(gpar[1]), $
              ;;              'RMS='+string(gpar[2])],/left,/top,/trad, charsize=charsize
           endif else begin
              data_str = {fov:fov}
              ;; np_histo_lp, [fov], out_xhist, out_yhist, out_gpar, min=histo_min, max=histo_max,$
              ;;              binsize=histo_bin, xrange=[histo_min, histo_max], fcol=[80], fit=1, $
              ;;              plotfit=1, noerase=1, position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], $
              ;;              nolegend=1, colorfit=[50], thickfit=ps_thick, nterms_fit=3, $
              ;;              xtitle="A"+strtrim(iarray, 2)+":
              ;;              "+histo_title
              np_histo, [fov], out_xhist, out_yhist, out_gpar, fcol=[80], fit=1, $
                           plotfit=1, noerase=1, position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], $
                           nolegend=1, colorfit=[50], thickfit=ps_thick, nterms_fit=3, $
                           xtitle="A"+strtrim(iarray, 2)+": "+histo_title
              leg_txt = ['N: '+num2string(n_elements(data_str.(0))), $
                         'Avg: '+num2string(out_gpar[0,1]), $
                         '!7r!3: '+num2string(out_gpar[0,2])]
              
              legendastro, leg_txt, textcol=[80, 80, 80], box=0, charsize=1, /right
              
              ;; HIST_PLOT, fov, MIN=histo_min, MAX=histo_max, noplot=noplot, $
              ;;            BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=1,fitgauss=1, FILL=FILL, X=X,Y=Y,$
              ;;            xtitle="A"+strtrim(iarray, 2)+": "+histo_title , $
              ;;            position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], $
              ;;            noerase=1, xstyle=1;, charsize=charsize
           endelse
           
        endif else print, 'too few valid KIDs for plotting histograms'
     endfor
     
     
     if keyword_set(saveplot) then begin
        if keyword_set(project_dir) then pdir = project_dir else pdir = !nika.plot_dir+"/Flats"
        png = project_dir+'/histo_'+strtrim(plotwhat)+'_'+nickname+'.png'
        WRITE_PNG, png, TVRD(/TRUE)
     endif
     
  endif
  
end
