;
pro nika_pipe_freqbanddec, tones, subscan, dmin, kidpar, TOI_in, TOI_out, all_subscans=all_subscans

  N_pt = n_elements(TOI_in[0,*])
  n_kid = n_elements(TOI_in[*,0])
  
  w_on = where(kidpar.type eq 1, n_on, COMPLEMENT=comp_on) ;Number of detector ON
  w_off = where(kidpar.type eq 2, n_off)                   ;Number of detector OFF
  
  TOI_out = dblarr(n_kid, N_pt)
  
  ;########### Define zones in the FP and in frequency ##############
  centre_fp = [mean(kidpar[w_on].nas_x), mean(kidpar[w_on].nas_y)]
  zfp_nn = where(kidpar[w_on].nas_x lt centre_fp[0] and kidpar[w_on].nas_y lt centre_fp[1], nfp_nn) ;--
  zfp_np = where(kidpar[w_on].nas_x lt centre_fp[0] and kidpar[w_on].nas_y ge centre_fp[1], nfp_np) ;-+
  zfp_pn = where(kidpar[w_on].nas_x ge centre_fp[0] and kidpar[w_on].nas_y lt centre_fp[1], nfp_pn) ;+-
  zfp_pp = where(kidpar[w_on].nas_x ge centre_fp[0] and kidpar[w_on].nas_y ge centre_fp[1], nfp_pp) ;++
  
  cut_fl = (max(tones[w_on]) - min(tones[w_on])) * [0.25, 0.5, 0.75] + min(tones[w_on])
  zfl_1 = where(tones[w_on] lt cut_fl[0], nfl_1)
  zfl_2 = where(tones[w_on] lt cut_fl[1] and tones[w_on] ge cut_fl[0], nfl_2)
  zfl_3 = where(tones[w_on] lt cut_fl[2] and tones[w_on] ge cut_fl[1], nfl_3)
  zfl_4 = where(tones[w_on] gt cut_fl[2], nfl_4)

  ;########### Case of all the scan ##############
  if keyword_set(all_subscans) then begin

     ;Define the filter
     fc1 = 0.06
     fc2 = 0.07
     fc3 = 4.0
     fc4 = 4.1

     npt2 = N_pt/2
     freq  = dindgen(npt2+1)/double(npt2) * !nika.f_sampling/2.0 ;Frequency
     if ((N_pt mod 2) eq 0) then freq=[freq, -1*reverse(freq[1:npt2-1])]
     if ((N_pt mod 2) eq 1) then freq=[freq, -1*reverse(freq[1:*])]

     z1 = where(abs(freq) lt fc1)                      ;low freq zone
     z2 = where(freq gt fc1 and freq lt fc2)           ;transition at positive low freq
     z3 = where(freq gt -fc2 and freq lt -fc1)         ;transition at negative low freq
     z4 = where(abs(freq) lt fc3 and abs(freq) gt fc2) ;mid freq zone
     z5 = where(freq gt fc3 and freq lt fc4)           ;transition at positive high freq
     z6 = where(freq gt -fc4 and freq lt -fc3)         ;transition at negative high freq
     z7 = where(abs(freq) gt fc4)                      ;high freq zone
  
     filter_lp = dblarr(N_pt)
     filter_lp[z1] = 1
     filter_lp[z2] = (cos((!pi/2)*(freq[z2]-fc1)/(fc2-fc1)))^2
     filter_lp[z3] = (cos((!pi/2)*(freq[z3]+fc1)/(fc2-fc1)))^2

     filter_mp = dblarr(N_pt) + 1
     filter_mp[z1] = 0
     filter_mp[z7] = 0
     filter_mp[z2] = (sin((!pi/2)*(freq[z2]-fc1)/(fc2-fc1)))^2
     filter_mp[z3] = (sin((!pi/2)*(freq[z3]+fc1)/(fc2-fc1)))^2
     filter_mp[z5] = (cos((!pi/2)*(freq[z5]-fc3)/(fc4-fc3)))^2
     filter_mp[z6] = (cos((!pi/2)*(freq[z6]+fc3)/(fc4-fc3)))^2

     filter_hp = dblarr(N_pt)
     filter_hp[z7] = 1
     filter_hp[z5] = (sin((!pi/2)*(freq[z5]-fc3)/(fc4-fc3)))^2
     filter_hp[z6] = (sin((!pi/2)*(freq[z6]+fc3)/(fc4-fc3)))^2

     ;Get the FFT and TOI filtered
     TOI_lp = dblarr(n_on,N_pt)
     TOI_mp = dblarr(n_on,N_pt)
     TOI_hp = dblarr(n_on,N_pt)     
     
     for ikid=0, n_on-1 do begin
        FT = FFT(TOI_in[w_on[ikid], *] - mean(TOI_in[w_on[ikid], *]), 1)
        TOI_lp[ikid,*] = double(FFT(FT * filter_lp,-1))
        TOI_mp[ikid,*] = double(FFT(FT * filter_mp,-1))
        TOI_hp[ikid,*] = double(FFT(FT * filter_hp,-1))
     endfor

     ;Loop for the KIDs
     for ikid = 0, n_on-1 do begin
        
        ;Cross calibration
        lp_x_calib = dblarr(n_on, 2)
        for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
           fit = linfit(TOI_lp[jkid,*], TOI_lp[0,*])
           lp_x_calib[jkid,0] = fit[0]
           lp_x_calib[jkid,1] = fit[1]
        endfor
        
        mp_x_calib = dblarr(n_on, 2)
        for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
           fit = linfit(TOI_mp[jkid,*], TOI_mp[0,*])
           mp_x_calib[jkid,0] = fit[0]
           mp_x_calib[jkid,1] = fit[1]
        endfor
        
        hp_x_calib = dblarr(n_on, 2)
        for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
           fit = linfit(TOI_hp[jkid,*], TOI_hp[0,*])
           hp_x_calib[jkid,0] = fit[0]
           hp_x_calib[jkid,1] = fit[1]
        endfor

        ;get the kids in a given radius
        distance = sqrt((kidpar[w_on].nas_x - kidpar[w_on[ikid]].nas_x)^2 $
                        + (kidpar[w_on].nas_y - kidpar[w_on[ikid]].nas_y)^2)
        ok = where(distance ge dmin, nok) ; KIDs far enough (de w_on)
        
        ;Build templates
        temp_lp = dblarr(4,n_pt)
        temp_mp = dblarr(4,n_pt)
        temp_hp = dblarr(4,n_pt)
        
        for jkid=0,nfp_nn-1 do begin 
           variable = where(ok eq zfp_nn[jkid], nval)
           if nval eq 1 then temp_lp[0,*] += lp_x_calib[zfp_nn[jkid],0] + $
                                             lp_x_calib[zfp_nn[jkid],1]*TOI_lp[zfp_nn[jkid],*]
        endfor
        for jkid=0,nfp_np-1 do begin 
           variable = where(ok eq zfp_np[jkid], nval)
           if nval eq 1 then temp_lp[1,*] += lp_x_calib[zfp_np[jkid],0] + $
                                             lp_x_calib[zfp_np[jkid],1]*TOI_lp[zfp_np[jkid],*]
        endfor
        for jkid=0,nfp_pn-1 do begin
           variable = where(ok eq zfp_pn[jkid], nval)
           if nval eq 1 then temp_lp[2,*] += lp_x_calib[zfp_pn[jkid],0] + $
                                             lp_x_calib[zfp_pn[jkid],1]*TOI_lp[zfp_pn[jkid],*]
        endfor
        for jkid=0,nfp_pp-1 do begin
           variable = where(ok eq zfp_pp[jkid], nval)
           if nval eq 1 then temp_lp[3,*] += lp_x_calib[zfp_pp[jkid],0] + $
                                             lp_x_calib[zfp_pp[jkid],1]*TOI_lp[zfp_pp[jkid],*]
        endfor
        
        for jkid=0,nfl_1-1 do begin
           variable = where(ok eq zfl_1[jkid], nval)
           if nval eq 1 then temp_mp[0,*] += mp_x_calib[zfl_1[jkid],0] + $
                                             mp_x_calib[zfl_1[jkid],1]*TOI_mp[zfl_1[jkid],*]
        endfor
        for jkid=0,nfl_2-1 do begin
           variable = where(ok eq zfl_2[jkid], nval)
           if nval eq 1 then temp_mp[1,*] += mp_x_calib[zfl_2[jkid],0] + $
                                             mp_x_calib[zfl_2[jkid],1]*TOI_mp[zfl_2[jkid],*]
        endfor
        for jkid=0,nfl_3-1 do begin
           variable = where(ok eq zfl_3[jkid], nval)
           if nval eq 1 then temp_mp[2,*] += mp_x_calib[zfl_3[jkid],0] + $
                                             mp_x_calib[zfl_3[jkid],1]*TOI_mp[zfl_3[jkid],*]
        endfor
        for jkid=0,nfl_4-1 do begin
           variable = where(ok eq zfl_4[jkid], nval)
           if nval eq 1 then temp_mp[3,*] += mp_x_calib[zfl_4[jkid],0] + $
                                             mp_x_calib[zfl_4[jkid],1]*TOI_mp[zfl_4[jkid],*]
        endfor

        
        for jkid=0,nfl_1-1 do begin
           variable = where(ok eq zfl_1[jkid], nval)
           if nval eq 1 then temp_hp[0,*] += hp_x_calib[zfl_1[jkid],0] + $
                                             hp_x_calib[zfl_1[jkid],1]*TOI_hp[zfl_1[jkid],*]
        endfor
        for jkid=0,nfl_2-1 do begin
           variable = where(ok eq zfl_2[jkid], nval)
           if nval eq 1 then temp_hp[1,*] += hp_x_calib[zfl_2[jkid],0] + $
                                             hp_x_calib[zfl_2[jkid],1]*TOI_hp[zfl_2[jkid],*]
        endfor
        for jkid=0,nfl_3-1 do begin
           variable = where(ok eq zfl_3[jkid], nval)
           if nval eq 1 then temp_hp[2,*] += hp_x_calib[zfl_3[jkid],0] + $
                                             hp_x_calib[zfl_3[jkid],1]*TOI_hp[zfl_3[jkid],*]
        endfor
        for jkid=0,nfl_4-1 do begin
           variable = where(ok eq zfl_4[jkid], nval)
           if nval eq 1 then temp_hp[3,*] += hp_x_calib[zfl_4[jkid],0] + $
                                             hp_x_calib[zfl_4[jkid],1]*TOI_hp[zfl_4[jkid],*]
        endfor
       
        ;Remove empty templates
        if min(temp_lp[0,*]) eq max(temp_lp[0,*]) then tlp0 = 0 else tlp0 = 1
        if min(temp_lp[1,*]) eq max(temp_lp[1,*]) then tlp1 = 0 else tlp1 = 1
        if min(temp_lp[2,*]) eq max(temp_lp[2,*]) then tlp2 = 0 else tlp2 = 1
        if min(temp_lp[3,*]) eq max(temp_lp[3,*]) then tlp3 = 0 else tlp3 = 1
        temp_lp_reg = dblarr(tlp0+tlp1+tlp2+tlp3, n_pt)
        nombre = 0
        if tlp0 eq 1 then temp_lp_reg[nombre,*] = temp_lp[0,*] 
        if tlp0 eq 1 then nombre = nombre + 1
        if tlp1 eq 1 then temp_lp_reg[nombre,*] = temp_lp[1,*] 
        if tlp1 eq 1 then nombre = nombre + 1
        if tlp2 eq 1 then temp_lp_reg[nombre,*] = temp_lp[2,*] 
        if tlp2 eq 1 then nombre = nombre + 1
        if tlp3 eq 1 then temp_lp_reg[nombre,*] = temp_lp[3,*]

        if min(temp_mp[0,*]) eq max(temp_mp[0,*]) then tmp0 = 0 else tmp0 = 1
        if min(temp_mp[1,*]) eq max(temp_mp[1,*]) then tmp1 = 0 else tmp1 = 1
        if min(temp_mp[2,*]) eq max(temp_mp[2,*]) then tmp2 = 0 else tmp2 = 1
        if min(temp_mp[3,*]) eq max(temp_mp[3,*]) then tmp3 = 0 else tmp3 = 1
        temp_mp_reg = dblarr(tmp0+tmp1+tmp2+tmp3, n_pt)
        nombre = 0
        if tmp0 eq 1 then temp_mp_reg[nombre,*] = temp_mp[0,*] 
        if tmp0 eq 1 then nombre = nombre + 1
        if tmp1 eq 1 then temp_mp_reg[nombre,*] = temp_mp[1,*] 
        if tmp1 eq 1 then nombre = nombre + 1
        if tmp2 eq 1 then temp_mp_reg[nombre,*] = temp_mp[2,*] 
        if tmp2 eq 1 then nombre = nombre + 1
        if tmp3 eq 1 then temp_mp_reg[nombre,*] = temp_mp[3,*]

        if min(temp_hp[0,*]) eq max(temp_hp[0,*]) then thp0 = 0 else thp0 = 1
        if min(temp_hp[1,*]) eq max(temp_hp[1,*]) then thp1 = 0 else thp1 = 1
        if min(temp_hp[2,*]) eq max(temp_hp[2,*]) then thp2 = 0 else thp2 = 1
        if min(temp_hp[3,*]) eq max(temp_hp[3,*]) then thp3 = 0 else thp3 = 1
        temp_hp_reg = dblarr(thp0+thp1+thp2+thp3, n_pt)
        nombre = 0
        if thp0 eq 1 then temp_hp_reg[nombre,*] = temp_hp[0,*] 
        if thp0 eq 1 then nombre = nombre + 1
        if thp1 eq 1 then temp_hp_reg[nombre,*] = temp_hp[1,*] 
        if thp1 eq 1 then nombre = nombre + 1
        if thp2 eq 1 then temp_hp_reg[nombre,*] = temp_hp[2,*] 
        if thp2 eq 1 then nombre = nombre + 1
        if thp3 eq 1 then temp_hp_reg[nombre,*] = temp_hp[3,*]

        ;Build data
        y_lp = reform(TOI_lp[ikid,*])   ;y containing high freq only
        y_mp = reform(TOI_mp[ikid,*])   ;y containing mid freq only
        y_hp = reform(TOI_hp[ikid,*])   ;y containing low freq only
        
        ;decorrelate each template
        coeff_lp = regress(temp_lp_reg, y_lp,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                           /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_lp)
        coeff_mp = regress(temp_mp_reg, y_mp,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                           /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_mp)
        coeff_hp = regress(temp_hp_reg, y_hp,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                           /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_hp)
        
        TOI_out[w_on[ikid],*] = y_lp + y_mp + y_hp - reform(yfit_lp + yfit_mp + yfit_hp)

     endfor
endif

 ;************************************************************************************
 ;************************************************************************************

 ;########### Case of subscan ##############
  if not keyword_set(all_subscans) then begin
     for isubscan=(min(subscan)>0), max(subscan) do begin
        wsubscan = where(subscan eq isubscan, nwsubscan)
        
        if nwsubscan ne 0 then begin

     ;Define the filter
           fc1 = 0.4
           fc2 = 0.5
           fc3 = 4.0
           fc4 = 4.1
           
           npt2 = nwsubscan/2
           freq  = dindgen(npt2+1)/double(npt2) * !nika.f_sampling/2.0 ;Frequency
           if ((nwsubscan mod 2) eq 0) then freq=[freq, -1*reverse(freq[1:npt2-1])]
           if ((nwsubscan mod 2) eq 1) then freq=[freq, -1*reverse(freq[1:*])]
           
           z1 = where(abs(freq) lt fc1)                      ;low freq zone
           z2 = where(freq gt fc1 and freq lt fc2)           ;transition at positive low freq
           z3 = where(freq gt -fc2 and freq lt -fc1)         ;transition at negative low freq
           z4 = where(abs(freq) lt fc3 and abs(freq) gt fc2) ;mid freq zone
           z5 = where(freq gt fc3 and freq lt fc4)           ;transition at positive high freq
           z6 = where(freq gt -fc4 and freq lt -fc3)         ;transition at negative high freq
           z7 = where(abs(freq) gt fc4)                      ;high freq zone
           
           filter_lp = dblarr(nwsubscan)
           filter_lp[z1] = 1
           filter_lp[z2] = (cos((!pi/2)*(freq[z2]-fc1)/(fc2-fc1)))^2
           filter_lp[z3] = (cos((!pi/2)*(freq[z3]+fc1)/(fc2-fc1)))^2
           
           filter_mp = dblarr(nwsubscan) + 1
           filter_mp[z1] = 0
           filter_mp[z7] = 0
           filter_mp[z2] = (sin((!pi/2)*(freq[z2]-fc1)/(fc2-fc1)))^2
           filter_mp[z3] = (sin((!pi/2)*(freq[z3]+fc1)/(fc2-fc1)))^2
           filter_mp[z5] = (cos((!pi/2)*(freq[z5]-fc3)/(fc4-fc3)))^2
           filter_mp[z6] = (cos((!pi/2)*(freq[z6]+fc3)/(fc4-fc3)))^2
           
           filter_hp = dblarr(nwsubscan)
           filter_hp[z7] = 1
           filter_hp[z5] = (sin((!pi/2)*(freq[z5]-fc3)/(fc4-fc3)))^2
           filter_hp[z6] = (sin((!pi/2)*(freq[z6]+fc3)/(fc4-fc3)))^2
           
     ;Get the FFT and TOI filtered
           TOI_lp = dblarr(n_on,nwsubscan)
           TOI_mp = dblarr(n_on,nwsubscan)
           TOI_hp = dblarr(n_on,nwsubscan)     
     
           for ikid=0, n_on-1 do begin
              FT = FFT(TOI_in[w_on[ikid], wsubscan] - mean(TOI_in[w_on[ikid], wsubscan]), 1)
              TOI_lp[ikid,*] = double(FFT(FT * filter_lp,-1))
              TOI_mp[ikid,*] = double(FFT(FT * filter_mp,-1))
              TOI_hp[ikid,*] = double(FFT(FT * filter_hp,-1))
           endfor

     ;Loop for the KIDs
           for ikid = 0, n_on-1 do begin
        
        ;Cross calibration
              lp_x_calib = dblarr(n_on, 2)
              for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
                 fit = linfit(TOI_lp[jkid,*], TOI_lp[0,*])
                 lp_x_calib[jkid,0] = fit[0]
                 lp_x_calib[jkid,1] = fit[1]
              endfor
              
              mp_x_calib = dblarr(n_on, 2)
              for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
                 fit = linfit(TOI_mp[jkid,*], TOI_mp[0,*])
                 mp_x_calib[jkid,0] = fit[0]
                 mp_x_calib[jkid,1] = fit[1]
              endfor
        
              hp_x_calib = dblarr(n_on, 2)
              for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
                 fit = linfit(TOI_hp[jkid,*], TOI_hp[0,*])
                 hp_x_calib[jkid,0] = fit[0]
                 hp_x_calib[jkid,1] = fit[1]
              endfor
              
        ;get the kids in a given radius
        distance = sqrt((kidpar[w_on].nas_x - kidpar[w_on[ikid]].nas_x)^2 $
                        + (kidpar[w_on].nas_y - kidpar[w_on[ikid]].nas_y)^2)
        ok = where(distance ge dmin, nok) ; KIDs far enough (de w_on)

        ;Build templates
              temp_lp = dblarr(4,nwsubscan)
              temp_mp = dblarr(4,nwsubscan)
              temp_hp = dblarr(4,nwsubscan)

              for jkid=0,nfp_nn-1 do begin 
                 variable = where(ok eq zfp_nn[jkid], nval)
                 if nval eq 1 then temp_lp[0,*] += lp_x_calib[zfp_nn[jkid],0] + $
                                                   lp_x_calib[zfp_nn[jkid],1]*TOI_lp[zfp_nn[jkid],*]
              endfor
              for jkid=0,nfp_np-1 do begin 
                 variable = where(ok eq zfp_np[jkid], nval)
                 if nval eq 1 then temp_lp[1,*] += lp_x_calib[zfp_np[jkid],0] + $
                                                   lp_x_calib[zfp_np[jkid],1]*TOI_lp[zfp_np[jkid],*]
              endfor
              for jkid=0,nfp_pn-1 do begin
                 variable = where(ok eq zfp_pn[jkid], nval)
                 if nval eq 1 then temp_lp[2,*] += lp_x_calib[zfp_pn[jkid],0] + $
                                                   lp_x_calib[zfp_pn[jkid],1]*TOI_lp[zfp_pn[jkid],*]
              endfor
              for jkid=0,nfp_pp-1 do begin
                 variable = where(ok eq zfp_pp[jkid], nval)
                 if nval eq 1 then temp_lp[3,*] += lp_x_calib[zfp_pp[jkid],0] + $
                                                   lp_x_calib[zfp_pp[jkid],1]*TOI_lp[zfp_pp[jkid],*]
              endfor
              
              for jkid=0,nfl_1-1 do begin
                 variable = where(ok eq zfl_1[jkid], nval)
                 if nval eq 1 then temp_mp[0,*] += mp_x_calib[zfl_1[jkid],0] + $
                                                   mp_x_calib[zfl_1[jkid],1]*TOI_mp[zfl_1[jkid],*]
              endfor
              for jkid=0,nfl_2-1 do begin
                 variable = where(ok eq zfl_2[jkid], nval)
                 if nval eq 1 then temp_mp[1,*] += mp_x_calib[zfl_2[jkid],0] + $
                                                   mp_x_calib[zfl_2[jkid],1]*TOI_mp[zfl_2[jkid],*]
              endfor
              for jkid=0,nfl_3-1 do begin
                 variable = where(ok eq zfl_3[jkid], nval)
                 if nval eq 1 then temp_mp[2,*] += mp_x_calib[zfl_3[jkid],0] + $
                                                   mp_x_calib[zfl_3[jkid],1]*TOI_mp[zfl_3[jkid],*]
              endfor
              for jkid=0,nfl_4-1 do begin
                 variable = where(ok eq zfl_4[jkid], nval)
                 if nval eq 1 then temp_mp[3,*] += mp_x_calib[zfl_4[jkid],0] + $
                                                   mp_x_calib[zfl_4[jkid],1]*TOI_mp[zfl_4[jkid],*]
              endfor

              
              for jkid=0,nfl_1-1 do begin
                 variable = where(ok eq zfl_1[jkid], nval)
                 if nval eq 1 then temp_hp[0,*] += hp_x_calib[zfl_1[jkid],0] + $
                                                   hp_x_calib[zfl_1[jkid],1]*TOI_hp[zfl_1[jkid],*]
              endfor
              for jkid=0,nfl_2-1 do begin
                 variable = where(ok eq zfl_2[jkid], nval)
                 if nval eq 1 then temp_hp[1,*] += hp_x_calib[zfl_2[jkid],0] + $
                                                   hp_x_calib[zfl_2[jkid],1]*TOI_hp[zfl_2[jkid],*]
              endfor
              for jkid=0,nfl_3-1 do begin
                 variable = where(ok eq zfl_3[jkid], nval)
                 if nval eq 1 then temp_hp[2,*] += hp_x_calib[zfl_3[jkid],0] + $
                                                   hp_x_calib[zfl_3[jkid],1]*TOI_hp[zfl_3[jkid],*]
              endfor
              for jkid=0,nfl_4-1 do begin
                 variable = where(ok eq zfl_4[jkid], nval)
                 if nval eq 1 then temp_hp[3,*] += hp_x_calib[zfl_4[jkid],0] + $
                                                   hp_x_calib[zfl_4[jkid],1]*TOI_hp[zfl_4[jkid],*]
              endfor
              
        ;Remove empty templates
              if min(temp_lp[0,*]) eq max(temp_lp[0,*]) then tlp0 = 0 else tlp0 = 1
              if min(temp_lp[1,*]) eq max(temp_lp[1,*]) then tlp1 = 0 else tlp1 = 1
              if min(temp_lp[2,*]) eq max(temp_lp[2,*]) then tlp2 = 0 else tlp2 = 1
              if min(temp_lp[3,*]) eq max(temp_lp[3,*]) then tlp3 = 0 else tlp3 = 1
              temp_lp_reg = dblarr(tlp0+tlp1+tlp2+tlp3, nwsubscan)
              nombre = 0
              if tlp0 eq 1 then temp_lp_reg[nombre,*] = temp_lp[0,*] 
              if tlp0 eq 1 then nombre = nombre + 1
              if tlp1 eq 1 then temp_lp_reg[nombre,*] = temp_lp[1,*] 
              if tlp1 eq 1 then nombre = nombre + 1
              if tlp2 eq 1 then temp_lp_reg[nombre,*] = temp_lp[2,*] 
              if tlp2 eq 1 then nombre = nombre + 1
              if tlp3 eq 1 then temp_lp_reg[nombre,*] = temp_lp[3,*]

              if min(temp_mp[0,*]) eq max(temp_mp[0,*]) then tmp0 = 0 else tmp0 = 1
              if min(temp_mp[1,*]) eq max(temp_mp[1,*]) then tmp1 = 0 else tmp1 = 1
              if min(temp_mp[2,*]) eq max(temp_mp[2,*]) then tmp2 = 0 else tmp2 = 1
              if min(temp_mp[3,*]) eq max(temp_mp[3,*]) then tmp3 = 0 else tmp3 = 1
              temp_mp_reg = dblarr(tmp0+tmp1+tmp2+tmp3, nwsubscan)
              nombre = 0
              if tmp0 eq 1 then temp_mp_reg[nombre,*] = temp_mp[0,*] 
              if tmp0 eq 1 then nombre = nombre + 1
              if tmp1 eq 1 then temp_mp_reg[nombre,*] = temp_mp[1,*] 
              if tmp1 eq 1 then nombre = nombre + 1
              if tmp2 eq 1 then temp_mp_reg[nombre,*] = temp_mp[2,*] 
              if tmp2 eq 1 then nombre = nombre + 1
              if tmp3 eq 1 then temp_mp_reg[nombre,*] = temp_mp[3,*]

              if min(temp_hp[0,*]) eq max(temp_hp[0,*]) then thp0 = 0 else thp0 = 1
              if min(temp_hp[1,*]) eq max(temp_hp[1,*]) then thp1 = 0 else thp1 = 1
              if min(temp_hp[2,*]) eq max(temp_hp[2,*]) then thp2 = 0 else thp2 = 1
              if min(temp_hp[3,*]) eq max(temp_hp[3,*]) then thp3 = 0 else thp3 = 1
              temp_hp_reg = dblarr(thp0+thp1+thp2+thp3, nwsubscan)
              nombre = 0
              if thp0 eq 1 then temp_hp_reg[nombre,*] = temp_hp[0,*] 
              if thp0 eq 1 then nombre = nombre + 1
              if thp1 eq 1 then temp_hp_reg[nombre,*] = temp_hp[1,*] 
              if thp1 eq 1 then nombre = nombre + 1
              if thp2 eq 1 then temp_hp_reg[nombre,*] = temp_hp[2,*] 
              if thp2 eq 1 then nombre = nombre + 1
              if thp3 eq 1 then temp_hp_reg[nombre,*] = temp_hp[3,*]

        ;Build data
              y_lp = reform(TOI_lp[ikid,*]) ;y containing high freq only
              y_mp = reform(TOI_mp[ikid,*]) ;y containing mid freq only
              y_hp = reform(TOI_hp[ikid,*]) ;y containing low freq only
              
              temp_lp = reform(temp_lp[0,*] + temp_lp[1,*] + temp_lp[2,*] + temp_lp[3,*])
              temp_mp = reform(temp_mp[0,*] + temp_mp[1,*] + temp_mp[2,*] + temp_mp[3,*])
              temp_hp = reform(temp_hp[0,*] + temp_hp[1,*] + temp_hp[2,*] + temp_hp[3,*])
        ;decorrelate each template
              coeff_lp = regress(temp_lp_reg, y_lp,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                                 /DOUBLE,FTEST=ftest,MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_lp)
              coeff_mp = regress(temp_mp_reg, y_mp,  CHISQ=chi,CONST= const, CORRELATION= corr, $
                                 /DOUBLE,FTEST=ftest,MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_mp)
              coeff_hp = regress(temp_hp_reg, y_hp,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                                 /DOUBLE,FTEST=ftest,MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit_hp)
              
              TOI_out[w_on[ikid],wsubscan] = y_lp + y_mp + y_hp - reform(yfit_lp + yfit_mp + yfit_hp)

     endfor
  endif                         ;valid subscan
      endfor                    ;loop on subscans
   endif

  return
end
