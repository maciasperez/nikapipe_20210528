pro get_tau_nika_from_tau225, runname, scan_list, tau_nika, $
                              flux_driven=flux_driven, skydip_driven=skydip_driven, atm=atm, tau225=tau225

  ;; tau225
  opa_file = !nika.pipeline_dir+'/Datamanage/Tau225/results_opacity_tau225interp_'+strupcase(runname)+'.fits'
  opa = mrdfits(opa_file, 1)
    
  ;; matching
  nscans = n_elements(scan_list)
  scan_list_opa = strtrim(opa.day,2)+'s'+strtrim(opa.scannum,2)
  my_match, scan_list_opa, scan_list, suba, subb
  if n_elements(subb) ne nscans then begin
     print, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
     print, "BEWARE: some scans are not found in the tau225 file"
  endif

  ;; tau_nika init
  tau_nika = dblarr(nscans, 4)
    
  ;; model
 
  if keyword_set(atm) then begin
     tau_nika[subb, 0] = opa[suba].tau1_medfilt 
     tau_nika[subb, 1] = opa[suba].tau2_medfilt 
     tau_nika[subb, 2] = opa[suba].tau3_medfilt 
     tau_nika[subb, 3] = opa[suba].tau3_medfilt 
  endif else begin
  
     if keyword_set(flux_driven)   then begin
        ;; nika2b
        ;; chi2 
        ;;a = [1.92, 0.95, 1.90, 1.96]
        ;;b = [-0.04, 0.01, -0.08, -0.07]
        ;;----------------------------------
        ;; rms 
        ;;a = [1.94, 0.93, 1.82, 1.88]
        ;;b = [-0., -0.01, -0.08, -0.07]
        ;;----------------------------------
        ;;a = [ 1.92,  0.97,  1.90,  1.92]
        ;;b = [-0.06,  0.0,  -0.10, -0.08]
        ;;---------------------------------
        ;; nika2c
        ;; chi2 
        ;;a = [1.93,  0.936, 1.92, 1.96]
        ;;b = [-0.04, 0.007,-0.05,-0.04]
        ;;----------------------------------
        ;; rms 
        ;;a = [1.947,  0.949, 1.83, 1.89]
        ;;b = [-0.047,-0.007, -0.08, -0.07]
        ;;----------------------------------
        ;;a = [ 1.93,  0.95,  1.90,  1.92]
        ;;b = [-0.04,  0.0,  -0.05, -0.05]

        ;; final test
        a = [1.94,  0.94,  1.86,  1.92]
        b = [-0.04, 0.00, -0.07, -0.06]
        
     endif
     if keyword_set(skydip_driven) then b = [1.4, 1.1, 1.3, 1.35]
     
     tau225   = dblarr(nscans)
     tau225[subb] = opa[suba].tau225_medfilt
     
     for ilam = 0, 3 do tau_nika[*, ilam] = a[ilam]*tau225[*] +b[ilam]
  endelse

  ;; test of the use of the ATM model
  ;;atm_model_mdp, atmtau_a1, atmtau_a2, atmtau_a3, atmtau_225, atm_em_1, atm_em_2, atm_em_3,$
  ;;               nostop=1, tau225=1, bpfiltering=1
  ;;tau = lindgen(50)/50.*0.8
  ;;plot, atmtau_225, atmtau_a1
  ;;oplot, tau225[*], tau_nika[*, 0], col=250
  ;;oplot, tau, 1.24*tau-0.00025, col=50
  ;;
  ;;plot, atmtau_225, atmtau_a3
  ;;oplot, tau225[*], tau_nika[*, 2], col=250
  ;;oplot, tau, 1.27*tau-0.00025, col=50
  ;;
  ;;plot, atmtau_225, atmtau_a3
  ;;oplot, tau225[*], tau_nika[*, 3], col=250
  ;;oplot, tau, 1.27*tau-0.00025, col=50
  ;;
  ;;plot, atmtau_225, atmtau_a2
  ;;oplot, tau225[*], tau_nika[*, 1], col=250
  ;;oplot, tau, 0.515*tau+0.02, col=50
  ;;
  ;;stop
  ;;


  
end
