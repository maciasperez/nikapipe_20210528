;+
;PURPOSE: Remove the atmospheric noise interpoated at the source location
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 21/01/2012: creation(adam@lpsc.in2p3.fr)
;              10/01/2014: use an other kidpar with flagged KIDs
;-

pro nika_pipe_interpol_source, param, data, kidpar

  N_pt = n_elements(data)       ;Nombre de sampling
  N_kid = n_elements(kidpar)    ;Nombre de detecteur
  
  toi_out = dblarr(N_kid, N_pt) ;toi finales
  indice = lindgen(N_pt)        ;Repere le numero du point de donnees

  for ikid = 0, N_kid-1 do begin ;boucle pour chaque KID
     if kidpar[ikid].type eq 1 then begin
        on_source = where(data.on_source_dec[ikid] eq 1, n_on_source)
        off_source = where(data.on_source_dec[ikid] eq 0, n_off_source)
        
        toi_1 = data[off_source].rf_didq[ikid] ; init
        if n_on_source ne 0 then toi_1 = interpol(data[off_source].rf_didq[ikid], indice[off_source], indice)

        toi_out[ikid,*] = data.RF_dIdQ[ikid] - toi_1
     endif
  endfor     

  data.RF_dIdQ = toi_out

  return
end
