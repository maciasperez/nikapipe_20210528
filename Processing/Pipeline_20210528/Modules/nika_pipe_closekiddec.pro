pro nika_pipe_closekiddec,subscan, kidpar, TOI_in, TOI_out, nkid_dec, all_subscans=all_subscans

  N_pt = n_elements(TOI_in[0,*])
  n_kid = n_elements(TOI_in[*,0])
  
  w_on = where(kidpar.type eq 1, n_on, COMPLEMENT=comp_on) ;Number of detector ON
  w_off = where(kidpar.type eq 2, n_off)                   ;Number of detector OFF

  TOI_out = dblarr(n_kid, N_pt)

;########### LOOP FOR ALL KIDS ############
  for ikid=0, n_on-1 do begin
     ;get the kids in a given radius
     distance = sqrt((kidpar[w_on].nas_x - kidpar[w_on[ikid]].nas_x)^2 $
                     + (kidpar[w_on].nas_y - kidpar[w_on[ikid]].nas_y)^2)
     distance[where(distance lt 20)] = max(distance) + 1.0 ;We do not want KIDs in the same Airy stain
     kid_ok = where(distance le (distance(sort(distance)))[nkid_dec-1], nkid_ok) ;nkid_dec closest KIDs

     ;$$$$$$$$$$$$$ All the scan is used for decorrelation $$$$$$$$$$$$$
     if keyword_set(all_subscans) then begin

        ;Atmosphere cross calibration
        atm_x_calib = dblarr(n_on, 2)
        for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
           fit = linfit(TOI_in[w_on[jkid],*], TOI_in[w_on[0],*])
           atm_x_calib[jkid,0] = fit[0]
           atm_x_calib[jkid,1] = fit[1]
        endfor
        
        templates = dblarr(nkid_ok, N_pt)

        ;Get the atmosphere template
        for jkid=0,nkid_ok-1 do templates[jkid,*] = atm_x_calib[kid_ok[jkid],0] + $
           atm_x_calib[kid_ok[jkid],1]*TOI_in[w_on[kid_ok[jkid]],*]
              
        ;Decorelate from template
        y = reform(TOI_in[w_on[ikid],*])
        coeff = regress(templates, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                        /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)
        TOI_out[w_on[ikid],*] = TOI_in[w_on[ikid],*] - reform(yfit)
     endif
     
     ;$$$$$$$$$$$$$ decorrelation per subscan $$$$$$$$$$$$$
     if not keyword_set(all_subscans) then begin
        
         for isubscan=(min(subscan)>0), max(subscan) do begin
            wsubscan = where(subscan eq isubscan, nwsubscan)
            if nwsubscan ne 0 then begin

               ;Atmosphere cross calibration
               atm_x_calib = dblarr(n_on, 2)
               for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
                  fit = linfit((TOI_in[w_on[jkid],*])[*,wsubscan], (TOI_in[w_on[0],*])[*,wsubscan])
                  atm_x_calib[jkid,0] = fit[0]
                  atm_x_calib[jkid,1] = fit[1]
               endfor
               
               templates = dblarr(nkid_ok, nwsubscan)

               ;Get the atmosphere template
               for jkid=0,nkid_ok-1 do templates[jkid,*] = atm_x_calib[kid_ok[jkid],0] +$
                  atm_x_calib[kid_ok[jkid],1]*TOI_in[w_on[kid_ok[jkid]],wsubscan]
                              
              ;Decorelate from template
               y = reform(TOI_in[w_on[ikid],wsubscan])
               coeff = regress(templates, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                               /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)
               TOI_out[w_on[ikid],wsubscan] = TOI_in[w_on[ikid],wsubscan] - reform(yfit)
            endif
         endfor
         
      endif

    ;$$$$$$$$$$$$$$$$$$$$$$$$$

  endfor
  
  return
end
