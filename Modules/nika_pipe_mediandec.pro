;+
;PURPOSE: Remove the median (in time) of the TOI
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 
;-

pro nika_pipe_mediandec, param, data, kidpar

  N_pt = n_elements(data)       ;Nombre de sampling
  N_kid = n_elements(kidpar)    ;Nombre de detecteur
  
  toi_1 = dblarr(N_kid, N_pt)   ;TOI temporaire
  toi_2 = dblarr(N_kid, N_pt)
  toi_3 = dblarr(N_kid, N_pt)
  toi_4 = dblarr(N_kid, N_pt) 
  toi_out = dblarr(N_kid, N_pt) ;toi finales
  indice = lindgen(N_pt)        ;Repere le numero du point de donnees
  sig_1 = dblarr(N_kid) 
  sig_2  = dblarr(N_kid)

  
  for k = 0, N_kid-1 do begin   ;boucle pour chaque KID
     if kidpar[k].type eq 1 then begin

        toi_1[k,*] = data.RF_dIdQ[k] - median(reform(data.RF_dIdQ[k]),param.decor.median.width)
        sig_1[k] = -stdev(toi_1[k,*])/1.5
        
        toi_2[k,*] = data.RF_dIdQ[k]
        test_var_less = where(toi_1[k,*] le sig_1[k], n_var_less)
        test_var_great = where(toi_1[k,*] gt -sig_1[k], n_var_great)
        if n_var_less ne 0 then toi_2[k,indice(test_var_less)] = 0
        if n_var_great ne 0 then toi_2[k,indice(test_var_great )] = 0
        toi_2[k,*] = interpol(data[where(toi_2[k,*] ne 0)].RF_dIdQ[k], indice(where(toi_2[k,*] ne 0)), indice)
        
        toi_3[k,*] = toi_2[k,*] - median(reform(toi_2[k,*]),param.decor.median.width)
        sig_2[k] = -stdev(toi_3[k,*])
        toi_4[k,*] = toi_2[k,*]
        
        test_var_less = where(toi_3[k,*] le sig_2[k], n_var_less)
        test_var_great = where(toi_3[k,*] gt -sig_2[k], n_var_great)
        if n_var_less ne 0 then toi_4[k,indice(test_var_less)] = 0
        if n_var_great ne 0 then toi_4[k,indice(test_var_great)] = 0
        toi_4[k,*] = interpol(toi_2[k,where(toi_4[k,*] ne 0)], indice(where(toi_4[k,*] ne 0)), indice)
        
        TOI_out[k,*] = data.RF_dIdQ[k] - median(reform(toi_4[k,*]),param.decor.median.width)
     endif
  endfor     
  
  data.RF_dIdQ = toi_out

  return
end
