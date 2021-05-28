;+
;PURPOSE: Calculation of the zenith opacity from skydip results 
;
;INPUT: The parameter and data structures.
;
;OUTPUT: Opacity in kidpar.
;
;LAST EDITION: 
;   2013: update (catalano@lpsc.in2p3.fr)
;   05/06/2013: fill param.tau_list with the opacities (adam@lpsc.in2p3.fr)
;   27/06/2013: add /silent (FXD)
;   10/12/13  : changed kidpar.voie into long(kidpar.lambda), NP
;   10/12/13  : clean up to be compatible with latest formats and when not all
;               bands are present, NP
;   08/01/14  : print the opacity value after np_histo
;-

pro nika_pipe_opacity, param, data, kidpar, $
                       noskydip=noskydip, $
                       simu=simu, $
                       silent=silent, $
                       old_method=old_method
  
  fmt = '(1F10.3)'              ; format for the printout
  if keyword_set(noskydip) then goto, fin
  
  nsn               = n_elements(data)
  nkids             = n_elements(kidpar) 
  kidpar.tau_skydip = 0.d0      ; !values.d_nan
  
  ;;==================== Case of simulated data
  if keyword_set(simu) then begin
     opacity_1mm = param.atmo.tau0_a
     opacity_2mm = param.atmo.tau0_b
     message, /info, 'Opacity simulated at 1mm: '+ strtrim(opacity_1mm, 2)
     message, /info, 'Opacity simulated at 2mm: '+ strtrim(opacity_2mm, 2)
     
     ;; update kidpar
     m1 = where( kidpar.array eq 1)
     m2 = where( kidpar.array eq 2)
     kidpar[m1].tau_skydip = opacity_1mm
     kidpar[m2].tau_skydip = opacity_2mm
  endif else begin
     ;;==================== Rustine pour le Run5 sans le kidpar.opcity
     if strmid(param.day[param.iscan], 0, 6) eq '201211' then begin        
        ;;------- Get the scan used here
        file_here = param.scan_list[param.iscan] ;file written as 20121124s0008
        scan_here = param.scan_num[param.iscan] 
        day_here = param.day[param.iscan]
        
        ;;------- In some cases the opacity Run5 file has not been well
        ;;        computed, so we use the opacity taken from the closest scan
        if day_here eq '20121119' then begin
           if scan_here eq 147 or scan_here eq 148 then scan_here = 149
        endif

        if day_here eq '20121122' then begin
           if scan_here eq 78 or scan_here eq 79 or scan_here eq 80 or scan_here eq 81 or scan_here eq 82 $
           then scan_here = 83
           if scan_here eq 184 then scan_here = 180
           if scan_here ge 193 and scan_here le 208 then scan_here = 209
        endif
        if day_here eq '20121123' then begin
           if scan_here eq 14 then scan_here = 13
        endif

        ;;------- Get the opacities for each scan of the Run5
        opa_r5 = mrdfits(!nika.soft_dir+'/OldRuns_pipeline/Run5_pipeline/Calibration/opacity.fits', 1, head_r5)
        loc = where(opa_r5.day eq day_here and opa_r5.scan_num eq scan_here, nloc)
        
        ;;------- Get the right opacity
        if nloc ne 1 then message, 'The scan used here does not have one and only one opacity correspondance'
        opacity_1mm = (opa_r5.tau1mm[loc])[0]>0 ; truncate to avoid amplifying light (FXD)
        opacity_2mm = (opa_r5.tau2mm[loc])[0]>0 

        ;;------- Print the result for info
        if not keyword_set(simu) then if not keyword_set( silent) then $
           message, /info, 'Opacity found at 1mm: '+ $
                    string(opacity_1mm, format = fmt)
        if not keyword_set(simu) then  if not keyword_set( silent) then $
           message, /info, 'Opacity found at 2mm: '+ $
                    string(opacity_2mm, format = fmt)
        
        ;; update param
        param.tau_list.A[param.iscan] = opacity_1mm
        param.tau_list.B[param.iscan] = opacity_2mm
     endif else begin
        ;;==================== Old method
        if keyword_set(old_method) then begin
           w    = where( data.el ne 0)
           am_o = mean(1./sin( data[w].el),/nan)
           
           T_atm   = 270.
           ind     = where(abs(kidpar.c0_skydip) gt 0, nind)
           if nind eq 0 then begin
              message, /info, "*******************************************************"
              message, /info, "all kids have c0_skydip = 0."
              message, /info, "Did you run skydip.pro and update the input kidpar .fits files ?"
              message, /info, "*******************************************************"
              stop
           endif
           
           df_tone = data.df_tone
           f_tone  = data.f_tone  
           
           for i=0, n_elements(ind)-1 do begin
              ikid = ind[i]
              c0 = abs(median(f_tone[ikid,*]) + $
                       median(df_tone[ikid,*]) - $
                       abs(kidpar[ikid].c0_skydip))
              ;;c0 = abs(mean(f_tone(ikid,shi:nsn-shi)) + $
              ;;         mean(df_tone(ikid,shi:nsn-shi)) - $
              ;;         abs(kidpar[ikid].c0_skydip))
              c1 = kidpar[ikid].c1_skydip*T_atm
              if (c0/c1) lt 1 then kidpar[ikid].tau_skydip = -1.*(1./am_o*alog(1.-c0/c1))
           endfor
           
           ;; Compute tau at both wavelengths
           for lambda=1, 2 do begin
              wkids = where( kidpar.array eq lambda and kidpar.tau_skydip ne 0.d0, nwkids)
              if nwkids lt 5 then begin
                 if not keyword_set( silent) then $
                    message, /info, "Not enough valid measurements of tau at "+ $
                             strtrim(lambda,2)+" mm (or only one band in the data) ?!"
              endif else begin
                 ;;nbin = 200
                 ;;bin = mean(tau[wkids])/(nbin-1)
                 
                 np_histo, kidpar[wkids].tau_skydip, x, y, gpar, bin=bin, /fit, /noplot, /noprint ;keyword_set(silent)
                 
                 ;;Put the same tau to all kids for the current lambda
                 wlambda = where( kidpar.array eq lambda)
                 kidpar[wlambda].tau_skydip = gpar[1]>0 ; truncate to avoid amplifying light (FXD)
                 if not keyword_set(silent) then $
                    message,/info,'======= Opacity found at '+strtrim(lambda,2)+'mm :'+ $
                            string(gpar[1]>0, format = fmt)
                 
                 if lambda eq 1 then param.tau_list.A[param.iscan] = gpar[1]>0 else $
                    param.tau_list.B[param.iscan]= gpar[1]>0
              endelse
           endfor
        endif else begin
           ;;==================== New method
           if param.renew_df le 1 then begin ; Old method
              w    = where( data.el ne 0)
              am = mean(1./sin( data[w].el),/nan)
              
              T_atm   = 270.
              ind     = where(abs(kidpar.c0_skydip) gt 0, nind)
              if nind eq 0 then message, "All kids have c0_skydip=0"
              
              df_tone = data.df_tone
              f_tone  = data.f_tone  
              
              for i=0, n_elements(ind)-1 do begin
                 ikid = ind[i]
                 ;; c0 = abs(mean(f_tone(ikid,shi:nsn-shi)) + $
                 ;;          mean(df_tone(ikid,shi:nsn-shi)) - $
                 ;;          abs(kidpar[ikid].c0_skydip))
                 c0 = abs(median(f_tone(ikid,*)) + $
                          median(df_tone(ikid,*)) - $
                          abs(kidpar[ikid].c0_skydip))
                 c1 = kidpar[ikid].c1_skydip*T_atm
                 if (c0/c1) lt 1 and (c0/c1) ge 0 then kidpar[ikid].tau_skydip = -1.*(1./am*alog(1.-c0/c1))
              endfor
              
              ;; Compute tau at both wavelengths
              for lambda=1, 2 do begin
                 wkids = where( kidpar.array eq lambda and kidpar.tau_skydip ne 0.d0, nwkids)
                 if nwkids lt 5 then begin
                    if not keyword_set( silent) then $
                       message, /info, "Not enough valid measurements of tau at "+ $
                                strtrim(lambda,2)+" mm (or only one band in the data) ?!"
                 endif else begin
                    np_histo, kidpar[wkids].tau_skydip, x, y, gpar, bin=bin, /fit, /noplot, /noprint
                    
                    ;; Put the same tau to all kids for the current lambda
                    wlambda = where( kidpar.array eq lambda)
                    gpar[1] = gpar[1]>0 ; truncate to avoid amplifying light (FXD)
                    kidpar[wlambda].tau_skydip = gpar[1]
                    if lambda eq 1 then param.tau_list.A[param.iscan] = gpar[1] $
                    else param.tau_list.B[param.iscan] = gpar[1]
                    if not param.silent  then $
                       message,/info,'======= Opacity found at '+strtrim(lambda,2)+'mm :'+num2string(gpar[1])
                 endelse
              endfor
           endif else begin     ; renew_df=2 method
              scansub= where( $
                       data.subscan gt 0 and $
                       data.scan_valid[0] eq 0 and $
                       data.scan_valid[1] eq 0 and $
                       data.el gt 0, nscansub)
              am = 1./sin( data[ scansub].el)
              taumed = dblarr( nkids)
              rms = taumed
              gk = where( kidpar.type eq 1 and kidpar.c0_skydip lt 0 $
                          and kidpar.c1_skydip gt 0, ngk)
              if ngk eq 0 then message, "All kids have c0_skydip=0"
              
              for idt = 0, ngk-1 do begin
                 idet = gk[ idt]
                 taufit2, am, data[ scansub].f_tone[ idet]+ $
                          data[scansub].df_tone[ idet], $
                          -kidpar[ idet].c0_skydip, $
                          kidpar[ idet].c1_skydip, $
                          taumedk, taumeank, frfit, rmsk, /silent
                 taumed[ idet] = taumedk
                 rms[ idet] = rmsk
              endfor
              goodkid = where( rms gt 0)
              gkid1 = where( kidpar.type eq 1 and kidpar.array eq 1 $
                             and rms gt 0, ngkid1)
              gkid2 = where( kidpar.type eq 1 and kidpar.array eq 2 $
                             and rms gt 0, ngkid2)
              if ngkid1 lt 5 then begin
                 if not keyword_set( silent) then $
                    message, /info, 'Not enough valid measurements of tau at '+ $
                             '1 mm (or only one band in the data) ?!'
                 tau1 = 0       ; Default value
              endif else begin 
                 tau1 = median( taumed[ gkid1])
                 ;; Put the same tau to all kids for the 1mm
                 wlambda = where( kidpar.array eq 1)
                 kidpar[wlambda].tau_skydip = tau1
                 param.tau_list.A[param.iscan] = tau1
                 if not keyword_set(silent)  then $
                    message,/info,'=== Zenith opacity found at 1 mm      : '+ $
                            string( tau1, format = '(1F7.3)')
              endelse
  
              if ngkid2 lt 5 then begin
                 if not keyword_set( silent) then $
                    message, /info, 'Not enough valid measurements of tau at '+ $
                             '2 mm (or only one band in the data) ?!'
                 tau2 = 0       ; default value
              endif else begin 
                 tau2 = median( taumed[ gkid2])
                 ;; Put the same tau to all kids for the 2mm
                 wlambda = where( kidpar.array eq 2)
                 kidpar[wlambda].tau_skydip = tau2
                 param.tau_list.B[param.iscan] = tau2
                 if not keyword_set(silent)  then $
                    message,/info,'=== Zenith opacity found at 2 mm      : '+  $
                            string( tau2, format = '(1F7.3)')
              endelse
           endelse              ; end case of renew df =2
        endelse                 ; end new method
     endelse                    ; if run > 5
  endelse

  ;;------- Fill the list of mean elevation in the param
  param.elev_list[param.iscan] = median(data.el)
  param.paral[param.iscan] = median(data.paral)

fin:

end
