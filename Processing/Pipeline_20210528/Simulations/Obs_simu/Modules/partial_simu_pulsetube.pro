;+
;PURPOSE: Add the pulse tube line to the simulated data.
;INPUT: The parameters and the data.
;OUTPUT: Idem with pulse tube line.
;LAST EDITION: 13/04/2012
;LAST EDITOR: Remi ADAM (adam@lpsc.in2p3.fr)
;-

pro partial_simu_pulsetube, param, data, kidpar

  N_pt = n_elements(data)
  N_kid = n_elements(kidpar)

  time = dindgen(N_pt)/!nika.f_sampling

  ptube = dblarr(N_pt)

  n_lines = n_elements(param.pulse_tube.freq)
  for iline = 0, n_lines - 1 do ptube = ptube + $
     param.pulse_tube.amp[iline]*cos(2*!pi*time*param.pulse_tube.freq[iline] + param.pulse_tube.phase[iline])
  
  for ikid=0, N_kid-1 do begin
     if kidpar[ikid].type eq 1 then data.RF_dIdQ[ikid] =  data.RF_dIdQ[ikid] + ptube
  endfor

  return
end
