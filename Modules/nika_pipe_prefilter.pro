;+
;PURPOSE: Filter the TOI in order to remove spectral lines and the
;         very low frequency noise.
;
;INPUT: The parameter and data structures.
;
;OUTPUT: The filters data structure.
;
;LAST EDITION: 
;   17/01/2013: creation (adam@lpsc.in2p3.fr)
;   21/09/2013: adapted to Run6-like data (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_prefilter, param, data, kidpar

  N_pt = n_elements(data)
  N_kid = n_elements(kidpar)
  
  for ikid=0, N_kid-1 do begin
     if kidpar[ikid].type eq 1 then begin
        nika_pipe_linefilter, param.filter.low_cut, param.filter.width, param.filter.nsigma, $
                              param.filter.freq_start, data.RF_dIdQ[ikid], data_clean
        data.RF_dIdQ[ikid] = data_clean
     endif
  endfor
  

  return
end
