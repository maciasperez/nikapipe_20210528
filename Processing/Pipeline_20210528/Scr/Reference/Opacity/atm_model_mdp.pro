pro atm_model_mdp, tau_1, tau_2, tau_3, tau_225, atm_em_1, atm_em_2, atm_em_3,$
                   old_a2=old_a2, nostop=nostop, tau225=tau225, $
                   bpfiltering=bpfiltering, bpshift = bpshift, noplot=noplot, output_pwv=output_pwv, $
                   effective_opa=effective_opa, approx=approx, error_bp=error_bp, old_model=old_model, $
                   o2leak=o2leak, nika1_bandpasses=nika1_bandpasses, dichroic=dichroic
  ;; +
  ;; KEYWORDS:
  ;;  ++ effective opacity: determined from the average absorption for a
  ;;     nu2 source
  ;;  ++ approx: average zenith opacity
  ;;  ++ by default: "skydip opacity" (from the average emission of
  ;;     the atmosphere)
  ;;  ++ bpshift: global frequency shift of the A2 bandpass [in GHz]
  ;;  ++ bpfiltering: top-hat filtering of the bandpass
  ;;  ++ old_model: previous version of the ATM model (atm_model.save)
  ;; - 

  
  file = !nika.pipeline_dir+"/Calibration/Atmo/atm_pardo_2017.save"  
  restore, file ;,/ver

  if keyword_set(output_pwv) then output_pwv = pwv
  nwv = n_elements(pwv)
  
  tau_1 = fltarr(nwv)
  tau_2 = fltarr(nwv)
  tau_3 = fltarr(nwv)
  if keyword_set(tau225) then tau_225 = fltarr(nwv)

  showplot=1
  if keyword_set(noplot) then showplot=0

  pasapas=1
  if keyword_set(nostop) then pasapas=0
  
;; COMMENT Channel 1H: FWHM=42 GHz from 241 to 283 GHz Take 260 GHz as the reference
;; COMMENT Data acquired at I. Neel, Grenoble with a Martin-Puplett Interferometer 
;; COMMENT obtained in 2015                                                        
;; COMMENT NIKA2 initial configuration before going to the 30m telescope           
;; COMMENT reduced v1 2015/10/14                                                   
;; COMMENT by A.Monfardini, A. F.X. Desert                                         
;; COMMENT Frequency in GHz                                                        
;; COMMENT Atmospheric  transmission for pwv=2mm given as representative of Winter 
;; COMMENT NIKA2 transmission is measured with a Rayleigh-Jeans spectrum in input  
;; COMMENT which is thus consistent with Planets                                   
;; COMMENT Hence, colour corrections have to be computed                           
;; COMMENT    with a R-J spectrum as the reference

  ;;; Juan's plot
  ;;;________________________________________________________________
  bandpass_file =  !nika.soft_dir+'/Pipeline/Calibration/BP/Transmission_2017_Jan_NIKA2_v1.fits'
  bp1=mrdfits(bandpass_file,1)
  bp3=mrdfits(bandpass_file,2)
  bp2=mrdfits(bandpass_file,3)

  nu1 = bp1.freq
  nu3 = bp3.freq
  nu2 = bp2.freq

  t1 = bp1.nikatrans
  t3 = bp3.nikatrans
  t2 = bp2.nikatrans


  if keyword_set(nika1_bandpasses) then begin
     bandpass_file =  !nika.soft_dir+'/Pipeline/Calibration/BP/NIKA_bandpass_Run8.fits'
     bp1=mrdfits(bandpass_file,1)
     bp2=mrdfits(bandpass_file,2)
          
     nu1 = bp1.freq
     nu3 = bp1.freq
     nu2 = bp2.freq
     
     t1 = bp1.nikatrans
     t3 = bp1.nikatrans
     t2 = bp2.nikatrans
  endif

  
  bandpass_file = !nika.soft_dir+'/Pipeline/Calibration/BP/Transmission_2015_Sept_NIKA2_v1.fits'
  bp1_=mrdfits(bandpass_file,1)
  bp3_=mrdfits(bandpass_file,2)
  bp2_=mrdfits(bandpass_file,3)

  nu1_ = bp1_.freq
  nu3_ = bp3_.freq
  nu2_ = bp2_.freq

  t1_ = bp1_.nikatrans
  t3_ = bp3_.nikatrans
  t2_ = bp2_.nikatrans
  
  if showplot gt 0 then begin
     ;;outplot, file='NIKA2_bandpasses', png=1
     plot, nu1, t1, /nodata, xr=[50, 350], /ylog, yr=[1d-3, 1.] ;; xr=[100, 140];;xr=[50, 350], /xs  
     oplot, nu1, t1, col=50, psym=8
     oplot, nu3, t3, col=80, psym=8
     oplot, nu2, t2, col=250, psym=8
     if keyword_set(bpshift) then oplot, nu2+bpshift, t2, col=250, linestyle=2
     oplot, nu2+1., t2, col=200
     oplot, nu2+2., t2, col=150
     oplot, nu1_, t1_, col=50, psym=0
     oplot, nu3_, t3_, col=80, psym=0
     oplot, nu2_, t2_, col=250, psym=0
     legendastro, ['new T1', 'new T3', 'new T2', 'old T1', 'old T3', 'old T2', '1GHz-shift', '2GHz-shift'], col=[50, 80, 250, 50, 80, 250, 200, 150], psym = [8, 8, 8, 0, 0, 0, 0, 0], box=0,  textcol=col, charsize=0.8
  endif
     
  bandpass_file =  !nika.soft_dir+'/Pipeline/Calibration/BP/Transmission_2017_Jan_NIKA2_v1.fits'
  if keyword_set(old_a2) then begin
     bandpass_file = !nika.soft_dir+'/Pipeline/Calibration/BP/Transmission_2015_Sept_NIKA2_v1.fits'
  endif
  
  print,"************************************"
  print,"Expected transmission from ATM Model 2017: reading ",bandpass_file
  bp1=mrdfits(bandpass_file,1)
  bp3=mrdfits(bandpass_file,2)
  bp2=mrdfits(bandpass_file,3)
  
  nu1 = bp1.freq
  nu3 = bp3.freq
  nu2 = bp2.freq
  
  t1 = bp1.nikatrans
  t3 = bp3.nikatrans
  t2 = bp2.nikatrans
  
  if keyword_set(dichroic) then begin
     ;; just a crude test
     filt = t1*0.0d0
     w=where(nu1 gt 0)
     filt[w] = 1.0d0/(1.0d0+(225.0d0/nu1[w])^30)
     t3 = t3*filt 
  endif
  
  if keyword_set(bpshift) then begin
     nu2 = nu2 + bpshift
  endif
     
  if keyword_set(tau225) then begin
     nu225 = findgen(600)
     t225  = fltarr(600)
     w=where(nu225 eq 225., n2)
     t225(w) = 1d0
     g = GAUSSIAN_FUNCTION([0.75], WIDTH=10, MAXIMUM=1)
     t225 = convol(t225, g, /normalize)
     t225 = t225/max(t225)
  endif

  ;; values from Marco DP
  if keyword_set(bpfiltering) then begin
     min_1mm = 200
     max_1mm = 300
     min_2mm = 110
     max_2mm = 190
     w1 = where(nu1 lt min_1mm or nu1 gt max_1mm, n1)
     w3 = where(nu3 lt min_1mm or nu3 gt max_1mm, n3)
     w2 = where(nu2 lt min_2mm or nu2 gt max_2mm, n2)
     t1[w1] = 0d0
     t3[w3] = 0d0
     t2[w2] = 0d0
  endif

  ;; 2% error on the transmission measurements
  if keyword_set(error_bp) then begin
     nb_nu1 = n_elements(nu1)
     nu1 = nu1*(1d0 + randomn(seed, nb_nu1)*0.01)
     nb_nu2 = n_elements(nu2)
     nu2 = nu2*(1d0 + randomn(seed, nb_nu2)*0.01)
     nb_nu3 = n_elements(nu3)
     nu3 = nu3*(1d0 + randomn(seed, nb_nu3)*0.01)
     t1 = t1*(1d0 + randomn(seed, nb_nu1)*0.02)
     t2 = t2*(1d0 + randomn(seed, nb_nu2)*0.02)
     t3 = t3*(1d0 + randomn(seed, nb_nu3)*0.02)
  endif
  
  if showplot gt 0 then begin
     oplot, nu1, t1, col=50, psym=2
     oplot, nu3, t3, col=80, psym=2
     oplot, nu2, t2, col=250, psym=2
  endif
  
  if pasapas gt 0 then stop
  
  if showplot gt 0 then begin
  ;;; plot Fig. 2 Catalano et al. (2014)
  ;;;________________________________________________________________
     
     leg = ['A1', 'A3', 'A2']
     col = [50, 80, 250]
     ps  = [8, 8, 8]
     
     outplot, file='ATM_model_2017_NIKA2_transmission', png=0
     ;;plot, freqs, freqs, xr=[100, 400], /ylog, yr=[1d-3, 100.], /nodata, ytitle="zenith transmission exp[-tau]", xtitle="freq [GHz]"
     plot, freqs, freqs, xr=[100, 150], /ylog, yr=[1d-3, 100.], /nodata, ytitle="zenith transmission exp[-tau]", xtitle="freq [GHz]"
     leg2 = strarr(nwv)
     col2 = intarr(nwv)
     for i=0, nwv-1 do begin
        leg2[i] = ['ATM model pwv='+strtrim(string(pwv[i], format='(f6.3)'),2)+'mm']
        col2[i] = 200.-15.*i
        oplot, freqs, exp(-1.d0*zopa(i,*)), col=200.-15.*i
               
        if keyword_set(O2leak) then begin
           
           filter = zopa(i,*)*0.d0+1.d0
           wo2=where(freqs ge 117. and freqs le 120.)
           filter[wo2] = o2leak
           
           tau = zopa(i,*)*filter
           oplot, freqs, exp(-1.d0*tau), col=200.-15.*i
           ;;g = GAUSSIAN_FUNCTION(1., WIDTH=40, MAXIMUM=0.1)
           ;;wo2=where(freqs gt 118.-20. and freqs lt 118.-20.)
           ;;tr_atmo_leak = convol(tr_atmo, g)
           ;;tr_atmo(wo2) = tr_atmo_leak(wo2)
        endif
        
     endfor
     oploterror, nu1, t1, nu1*0., bp1.error, errcol=50, col=50, psym=8, symsize=0.5
     oploterror, nu3, t3, nu3*0., bp3.error, errcol=80, col=80, psym=8, symsize=0.5
     oploterror, nu2, t2, nu2*0., bp2.error, errcol=250, col=250, psym=8, symsize=0.5
     if keyword_set(tau225) then oplot, nu225, t225, col=0
     legendastro,leg, col=col, box=0, /trad, textcol=col, psym=ps
     legendastro,leg2, col=col2, box=0, /trad, textcol=col2, /right
     ;;outplot, /close
help, nu1     
     if pasapas gt 0 then stop
     
     ;; oplot, nu1, bp1.atmtrans, col=0, thick=2
     ;; oplot, nu2, bp2.atmtrans, col=0, thick=2
     ;; oplot, nu3, bp3.atmtrans, col=0, thick=2
     
     ;; FREQUENCY SHIFT
     ;;outplot, file='NIKA2_bandpasses_freqshift', png=1
     plot, nu1, t1, /nodata, xr=[100, 250], /ylog, yr=[1d-3, 1.1], xtitle='frequency [GHz]', ytitle='Ar 2 transmission' ;; xr=[100, 140];;xr=[50, 350], /xs  
     oplot, nu2, t2, col=250
     oplot, nu2, t2+bp2.error, col=250
     oplot, nu2, t2-bp2.error, col=250
     oplot, nu2+1., t2, col=200, thick=2
     oplot, nu2+2., t2, col=150, thick=2
     oplot, nu2_, t2_, col=250, psym=8
     oplot, freqs, exp(-1.d0*zopa(3,*)), col=85
     legendastro, ['2015 Sept.', '2017 Jan.','+ 1GHz-shift','+ 2GHz-shift'], col=[250, 250, 200, 150], psym = [8, 0, 0, 0], box=0, /trad, textcol=[250, 250, 200, 150]
;;outplot, /close
     
     if pasapas gt 0 then stop
     
  endif
  
  ;; plot Fig. 11 Catalano et al. (2014)
  ;;________________________________________________________________


  ;; reference frequency
  nu0 = dblarr(3)
  nu0[0] = !const.c/(!nika.lambda[0]*1d-3)*1d-9
  nu0[2] = !const.c/(!nika.lambda[0]*1d-3)*1d-9
  nu0[1] = !const.c/(!nika.lambda[1]*1d-3)*1d-9

  
  dnu1 = shift(nu1, -1)-nu1
  dnu1 = (nu1*0.)+3.22814
  dnu3 = shift(nu3, -1)-nu3
  dnu3 = (nu3*0.)+3.35880
  dnu2 = shift(nu2, -1)-nu2
  dnu2 = (nu2*0.)+3.3590
  dfreqs = shift(freqs, -1)-freqs
  dfreqs = (freqs*0.)+1.d0

  
  ;; test effective zenith opacities (see Herve's email on 28
  ;; June, 2017)

  tau_1_eff = fltarr(nwv)
  tau_2_eff = fltarr(nwv)
  tau_3_eff = fltarr(nwv)
  tau_225_eff = fltarr(nwv)
  
  tau_1_dip = fltarr(nwv)
  tau_2_dip = fltarr(nwv)
  tau_3_dip = fltarr(nwv)
  tau_225_dip = fltarr(nwv)
  
  ;; source spectrum (assuming Planet)
  s1  = (nu1/nu0[0])^2 ;; 
  s2  = (nu2/nu0[1])^2 ;; 
  s3  = (nu3/nu0[2])^2 ;; 
  ;; source spectrum (assuming flat)
  ;;s1  = (nu1/nu1) ;; 
  ;;s2  = (nu2/nu2) ;; 
  ;;s3  = (nu3/nu3) ;;
  
  tau21 = fltarr(nwv)

  ;;powerratio_21 = fltarr(nwv)
  ;;powerratio_23 = fltarr(nwv)
  atm_em_1 = fltarr(nwv)
  atm_em_2 = fltarr(nwv)
  atm_em_3 = fltarr(nwv)

  
  w1 = where(nu1 gt 0.)
  w2 = where(nu2 gt 0.)
  w3 = where(nu3 gt 0.)
  
  tau_atm = zopa(4,*)
  atm_nu1_ref = interpol(tau_atm, freqs, nu1)
  atm_nu2_ref = interpol(tau_atm, freqs, nu2)
  atm_nu3_ref = interpol(tau_atm, freqs, nu3)

  ;; for i=0, nwv-1 do begin
     
  ;;    tau_atm = zopa(i,*)
  ;;    atm_nu1 = interpol(tau_atm, freqs, nu1)
  ;;    atm_nu2 = interpol(tau_atm, freqs, nu2)
  ;;    atm_nu3 = interpol(tau_atm, freqs, nu3)
     
  ;;    tau_1[i] = total(atm_nu1(w1)*t1(w1)*dnu1(w1))/total(t1(w1)*dnu1(w1))
  ;;    tau_3[i] = total(atm_nu3(w3)*t3(w3)*dnu3(w3))/total(t3(w3)*dnu3(w3))
  ;;    tau_2[i] = total(atm_nu2(w2)*t2(w2)*dnu2(w2))/total(t2(w2)*dnu2(w2))

  ;;    tau_1_eff[i] = -1d0*alog(total(s1(w1)*t1(w1)*exp(-1d0*atm_nu1(w1))*dnu1(w1))/total(s1(w1)*t1(w1)*dnu1(w1)) )
  ;;    tau_3_eff[i] = -1d0*alog(total(s3(w3)*t3(w3)*exp(-1d0*atm_nu3(w3))*dnu3(w3))/total(s3(w3)*t3(w3)*dnu3(w3)) )
  ;;    tau_2_eff[i] = -1d0*alog(total(s2(w2)*t2(w2)*exp(-1d0*atm_nu2(w2))*dnu2(w2))/total(s2(w2)*t2(w2)*dnu2(w2)) )

  ;;    tau_1_dip[i] = -1d0*alog(1d0 - total(t1(w1)*(1d0-exp(-1d0*atm_nu1(w1)))*dnu1(w1))/total(t1(w1)*dnu1(w1)) )
  ;;    tau_3_dip[i] = -1d0*alog(1d0 - total(t3(w3)*(1d0-exp(-1d0*atm_nu3(w3)))*dnu3(w3))/total(t3(w3)*dnu3(w3)) )
  ;;    tau_2_dip[i] = -1d0*alog(1d0 - total(t2(w2)*(1d0-exp(-1d0*atm_nu2(w2)))*dnu2(w2))/total(t2(w2)*dnu2(w2)) )
     
  ;;    tau21[i] = tau_2[i]/tau_1[i]
     
  ;;    if keyword_set(tau_225) then begin
  ;;       atm_nu225 = interpol(tau_atm, freqs, nu225)
  ;;       tau_225[i] = total(atm_nu225*t225)/total(t225)
  ;;    endif
     
  ;; endfor
  
  wo2=where(freqs ge 117. and freqs le 120.)
  
  for i=0, nwv-1 do begin
     
     tau_atm = zopa(i,*)
     
     if keyword_set(o2leak) then begin
        filter = zopa(i,*)*0.d0+1.d0
        filter[wo2] = o2leak 
        tau_atm = zopa(i,*)*filter
     endif
     
     t1_freqs = interpol(t1, nu1, freqs)
     t2_freqs = interpol(t2, nu2, freqs)
     t3_freqs = interpol(t3, nu3, freqs)
     
     tau_1[i] = total(tau_atm*t1_freqs/freqs^2*nu0[0]^2*dfreqs)/total(t1_freqs/freqs^2*nu0[0]^2*dfreqs)
     tau_3[i] = total(tau_atm*t3_freqs/freqs^2*nu0[2]^2*dfreqs)/total(t3_freqs/freqs^2*nu0[2]^2*dfreqs)
     tau_2[i] = total(tau_atm*t2_freqs/freqs^2*nu0[1]^2*dfreqs)/total(t2_freqs/freqs^2*nu0[1]^2*dfreqs)

     tau_1_eff[i] = -1d0*alog(total(freqs^2*t1_freqs*exp(-1d0*tau_atm)*dfreqs)/total(freqs^2*t1_freqs*dfreqs) )
     tau_3_eff[i] = -1d0*alog(total(freqs^2*t3_freqs*exp(-1d0*tau_atm)*dfreqs)/total(freqs^2*t3_freqs*dfreqs) )
     tau_2_eff[i] = -1d0*alog(total(freqs^2*t2_freqs*exp(-1d0*tau_atm)*dfreqs)/total(freqs^2*t2_freqs*dfreqs) )
     
     tau_1_dip[i] = -1d0*alog(1d0 - total(t1_freqs/freqs^2*nu0[0]^2*(1d0-exp(-1d0*tau_atm))*dfreqs)/total(t1_freqs/freqs^2*nu0[0]^2*dfreqs) )
     tau_3_dip[i] = -1d0*alog(1d0 - total(t3_freqs/freqs^2*nu0[2]^2*(1d0-exp(-1d0*tau_atm))*dfreqs)/total(t3_freqs/freqs^2*nu0[2]^2*dfreqs) )
     tau_2_dip[i] = -1d0*alog(1d0 - total(t2_freqs/freqs^2*nu0[1]^2*(1d0-exp(-1d0*tau_atm))*dfreqs)/total(t2_freqs/freqs^2*nu0[1]^2*dfreqs) )

          
     tau21[i] = tau_2[i]/tau_1[i]
     
     if keyword_set(tau225) then begin
        t225_freqs     = interpol(t225, nu225, freqs)
        tau_225[i]     = total(tau_atm*t225_freqs*dfreqs)/total(t225_freqs*dfreqs)
        tau_225_dip[i] = -1d0*alog(1d0 - total(t225_freqs*(1d0-exp(-1d0*tau_atm))*dfreqs)/total(t225_freqs*dfreqs) )
        tau_225_eff[i] = -1d0*alog(total(freqs^2*t225_freqs*exp(-1d0*tau_atm)*dfreqs)/total(freqs^2*t225_freqs*dfreqs) )
     endif

     ;;powerratio_21[i] =  total(t2_freqs*(1d0-exp(-1d0*tau_atm))*dfreqs)/ total(t1_freqs*(1d0-exp(-1d0*tau_atm))*dfreqs)*total(t1_freqs*dfreqs) /total(t2_freqs*dfreqs)
     ;;powerratio_23[i] =  total(t2_freqs*(1d0-exp(-1d0*tau_atm))*dfreqs)/ total(t3_freqs*(1d0-exp(-1d0*tau_atm))*dfreqs)*total(t3_freqs*dfreqs) /total(t2_freqs*dfreqs) 

     atm_em_1[i] =  total(t1_freqs/freqs^2*nu0[0]^2*(1.d0-exp(-1d0*tau_atm))*dfreqs)/total(t1_freqs/freqs^2*nu0[0]^2*dfreqs)
     atm_em_2[i] =  total(t2_freqs/freqs^2*nu0[1]^2*(1.d0-exp(-1d0*tau_atm))*dfreqs)/total(t2_freqs/freqs^2*nu0[1]^2*dfreqs) 
     atm_em_3[i] =  total(t3_freqs/freqs^2*nu0[2]^2*(1.d0-exp(-1d0*tau_atm))*dfreqs)/total(t3_freqs/freqs^2*nu0[2]^2*dfreqs) 


     ;; accounting for the beam etendue
     ;; atm_em_1[i] =  total(t1_freqs/freqs^2*nu0[0]^2*(1.d0-exp(-1d0*tau_atm))/(2.d0*!dpi*(!nika.fwhm_nom[0]*!fwhm2sigma)^2*nu0[0]^2)*dfreqs)/total(t1_freqs/freqs^2*nu0[0]^2*dfreqs)
    ;;  atm_em_2[i] =  total(t2_freqs/freqs^2*nu0[1]^2*(1.d0-exp(-1d0*tau_atm))/(2.d0*!dpi*(!nika.fwhm_nom[1]*!fwhm2sigma)^2*nu0[1]^2)*dfreqs)/total(t2_freqs/freqs^2*nu0[1]^2*dfreqs) 
    ;;  atm_em_3[i] =  total(t3_freqs/freqs^2*nu0[2]^2*(1.d0-exp(-1d0*tau_atm))/(2.d0*!dpi*(!nika.fwhm_nom[0]*!fwhm2sigma)^2*nu0[2]^2)*dfreqs)/total(t3_freqs/freqs^2*nu0[2]^2*dfreqs)
     
    ;; ;; accounting for the beam etendue
    ;;  atm_em_1[i] =  total(t1_freqs*(1.d0-exp(-1d0*tau_atm))*dfreqs)/total(t1_freqs*(2.d0*!dpi*(!nika.fwhm_nom[0]*!fwhm2sigma)^2*nu0[0]^2)*dfreqs)
    ;;  atm_em_2[i] =  total(t2_freqs*(1.d0-exp(-1d0*tau_atm))*dfreqs)/total(t2_freqs*(2.d0*!dpi*(!nika.fwhm_nom[1]*!fwhm2sigma)^2*nu0[1]^2)*dfreqs) 
    ;;  atm_em_3[i] = total(t3_freqs*(1.d0-exp(-1d0*tau_atm))*dfreqs)/total(t3_freqs*(2.d0*!dpi*(!nika.fwhm_nom[0]*!fwhm2sigma)^2*nu0[2]^2)*dfreqs)

     ;; accounting for the beam etendue
     ;atm_em_1[i] =  total(t1_freqs/max(t1_freqs)*(1.d0-exp(-1d0*tau_atm))/(2.d0*!dpi*(!nika.fwhm_nom[0]*!fwhm2sigma)^2*nu0[0]^2)*dfreqs)
     ;atm_em_2[i] =  total(t2_freqs/max(t2_freqs)*(1.d0-exp(-1d0*tau_atm))/(2.d0*!dpi*(!nika.fwhm_nom[1]*!fwhm2sigma)^2*nu0[1]^2)*dfreqs)
     ;atm_em_3[i] =  total(t3_freqs/max(t3_freqs)*(1.d0-exp(-1d0*tau_atm))/(2.d0*!dpi*(!nika.fwhm_nom[0]*!fwhm2sigma)^2*nu0[2]^2)*dfreqs)

  endfor

  if showplot gt 0 then begin
     plot, tau_1, tau_2, ytitle = "zenith opacity using A2", xtitle = "zenith opacity using A1 (A3)"
     oplot, tau_3, tau_2, col=250
     oplot, tau_1_eff, tau_2_eff, col=80
  endif

  if keyword_set(effective_opa) then begin
     print,'effective opa'
     tau_1 = tau_1_eff
     tau_2 = tau_2_eff
     tau_3 = tau_3_eff
     if keyword_set(tau225) then tau_225 = tau_225_eff
  endif 

  if not(keyword_set(approx)) then begin
     tau_1 = tau_1_dip
     tau_2 = tau_2_dip
     tau_3 = tau_3_dip
     if keyword_set(tau225) then tau_225 = tau_225_dip
  endif

  
  
  atm_fit = linfit(tau_1, tau_2)
  print,"linear fit: tau_2 vs tau_1 = ", atm_fit
  atm_fit = linfit(tau_3, tau_2)
  print,"linear fit: tau_2 vs tau_3 = ", atm_fit
  if keyword_set(tau225) then begin
     atm_fit = linfit(tau_225, tau_1)
     print,"linear fit: tau_1 vs tau_225 = ", atm_fit
     atm_fit = linfit(tau_225, tau_2)
     print,"linear fit: tau_2 vs tau_225 = ", atm_fit
  endif
  
  if pasapas gt 0  then stop

  
end
