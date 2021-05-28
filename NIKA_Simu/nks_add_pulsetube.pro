;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nks_add_pulsetube
;
; CATEGORY: general,launcher
;
; CALLING SEQUENCE:
;         nks_add_pulsetube, param, simpar, data, kidpar
; 
; PURPOSE:
;         Add the pulse tube line to the simulated data.
; INPUT: 
;         The parameters and the data.
; OUTPUT: 
;         Idem with pulse tube line.
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - May 25rd, 2015: creation (Alessia Ritacco & Nicolas
;          Ponthieu - ritacco@lpsc.in2p3.fr)
;          From partial_simu_pulsetube.pro-  Remi Adam - adam@lpsc.in2p3.fr
;-


pro nks_add_pulsetube, param,simpar, data, kidpar

  N_pt = n_elements(data)
  N_kid = n_elements(kidpar)

  time = dindgen(N_pt)/!nika.f_sampling

  ptube = dblarr(N_pt)

  n_lines = n_elements(simpar.pt_freq)
  for iline = 0, n_lines - 1 do ptube = ptube + $
     simpar.pt_amp[iline]*cos(2*!pi*time*simpar.pt_freq[iline] + simpar.pt_phase[iline])
  
  for ikid=0, N_kid-1 do begin
     if kidpar[ikid].type eq 1 then data.toi[ikid] =  data.toi[ikid] + ptube
  endfor

  return
end
