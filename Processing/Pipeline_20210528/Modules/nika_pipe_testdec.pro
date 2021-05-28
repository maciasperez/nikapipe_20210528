;+
;PURPOSE: Test new decorrelation technics
;
;INPUT: changes all the time
;
;OUTPUT: The decorrelated data structure.
;
;-

pro nika_pipe_testdec, elev, subscan, kidpar_a, kidpar_b, $
                       TOI_a, TOI_b, TOI_out_a, TOI_out_b

  N_pt = n_elements(TOI_a[0,*])
  n_kid_a = n_elements(TOI_a[*,0])
  n_kid_b = n_elements(TOI_b[*,0])
  
  w_on_a = where(kidpar_a.type eq 1, n_on_a, COMPLEMENT=comp_on_a) ;Number of detector ON
  w_on_b = where(kidpar_b.type eq 1, n_on_b, COMPLEMENT=comp_on_b) ;Number of detector ON
  w_off_a = where(kidpar_a.type eq 2, n_off_a)                     ;Number of detector OFF
  w_off_b = where(kidpar_b.type eq 2, n_off_b)                     ;Number of detector OFF
  
  TOI_out_a = dblarr(n_kid_a, N_pt)
  TOI_out_b = dblarr(n_kid_b, N_pt)
  
;#########################################
  ;;------- Define the filter
  fc1 = 1.5
  fc2 = 2.0
  
  npt2 = N_pt/2
  freq  = dindgen(npt2+1)/double(npt2) * !nika.f_sampling/2.0 
  if ((N_pt mod 2) eq 0) then freq=[freq, -1*reverse(freq[1:npt2-1])]
  if ((N_pt mod 2) eq 1) then freq=[freq, -1*reverse(freq[1:*])]

  z1 = where(abs(freq) lt fc1)              ;low freq zone
  z2 = where(freq gt fc1 and freq lt fc2)   ;transition at positive low freq
  z3 = where(freq gt -fc2 and freq lt -fc1) ;transition at negative low freq
  z4 = where(abs(freq) gt fc2)              ;high freq zone
  
  filter_lp = dblarr(N_pt)
  filter_lp[z1] = 1.0
  filter_lp[z2] = (cos((!pi/2)*(freq[z2]-fc1)/(fc2-fc1)))^2
  filter_lp[z3] = (cos((!pi/2)*(freq[z3]+fc1)/(fc2-fc1)))^2

  filter_hp = dblarr(N_pt)
  filter_hp[z4] = 1.0
  filter_hp[z2] = (sin((!pi/2)*(freq[z2]-fc1)/(fc2-fc1)))^2
  filter_hp[z3] = (sin((!pi/2)*(freq[z3]+fc1)/(fc2-fc1)))^2

  ;;------- Get the FFT and TOI filtered
  TOI_a_lp = dblarr(n_on_a,N_pt)
  TOI_a_hp = dblarr(n_on_a,N_pt)     
  TOI_b_lp = dblarr(n_on_b,N_pt)
  TOI_b_hp = dblarr(n_on_b,N_pt)       
  for ikid=0, n_on_a-1 do begin
     FT = FFT(TOI_a[w_on_a[ikid], *] - mean(TOI_a[w_on_a[ikid], *]), 1)
     TOI_a_lp[ikid,*] = double(FFT(FT * filter_lp,-1))
     TOI_a_hp[ikid,*] = double(FFT(FT * filter_hp,-1))
  endfor
  for ikid=0, n_on_b-1 do begin
     FT = FFT(TOI_b[w_on_b[ikid], *] - mean(TOI_b[w_on_b[ikid], *]), 1)
     TOI_b_lp[ikid,*] = double(FFT(FT * filter_lp,-1))
     TOI_b_hp[ikid,*] = double(FFT(FT * filter_hp,-1))
  endfor
  
;#########################################

  for isubscan=(min(subscan)>0), max(subscan) do begin
     wsubscan = where(subscan eq isubscan, nwsubscan)
     if nwsubscan ne 0 then begin
        
        ;;------- LP cross calibration
        lp_x_calib = dblarr(n_on_a, 2)
        for ikid=0, n_on_a-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
           fit = linfit(TOI_a_lp[ikid,wsubscan], TOI_a_lp[0,wsubscan])
           lp_x_calib[ikid,0] = fit[0]
           lp_x_calib[ikid,1] = fit[1]
        endfor

        ;;------- HP cross calibration
        hp_x_calib = dblarr(n_on_b, 2)
        for ikid=0, n_on_b-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
           fit = linfit(TOI_b_hp[ikid,wsubscan], TOI_b_hp[0,wsubscan])
           hp_x_calib[ikid,0] = fit[0]
           hp_x_calib[ikid,1] = fit[1]
        endfor
        
        ;;------- Get the template
        ntemp = 2
        templates = dblarr(ntemp, nwsubscan)        
        for ikid=0, n_on_a-1 do templates[0,*] += $
           (lp_x_calib[ikid,0] + lp_x_calib[ikid,1]*TOI_a_lp[ikid,wsubscan])/n_on_a
        for ikid=0, n_on_b-1 do templates[1,*] += $
           (hp_x_calib[ikid,0] + hp_x_calib[ikid,1]*TOI_b_hp[ikid,wsubscan])/n_on_b
        templates[0,*] = templates[0,*] - mean(templates[0,*]) ;Remove 0 level
        templates[1,*] = templates[1,*] - mean(templates[1,*])

        ;;------- Decorelate from template
        pc = 5
        pvec = dindgen(nwsubscan)/(nwsubscan-1)*100
        loc_vec = where(pvec lt pc or pvec gt 100-pc)
        for ikid=0, n_on_b-1 do begin
           y = reform(TOI_b[w_on_b[ikid],wsubscan] - mean(TOI_b[w_on_b[ikid],wsubscan]))
           coeff = regress(templates[*,loc_vec], y[loc_vec], /DOUBLE)
           yfit = coeff[0]*templates[0,*] + coeff[1]*templates[1,*]
           TOI_out_b[w_on_b[ikid],wsubscan] = y - yfit
           TOI_out_b[w_on_b[ikid],wsubscan] -= mean(TOI_out_b[w_on_b[ikid],wsubscan])
        endfor
     endif                      ;valid subscan
  endfor                        ;loop on subscans
  
  return
end
