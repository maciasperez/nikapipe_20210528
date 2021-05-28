;+
;PURPOSE: Filter the TOI individually using a median (in time) filter
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The baseline
;
;LAST EDITION: 
;-

pro nika_pipe_median_simple_dec, param, data, kidpar, baseline

  baseline = data.rf_didq*0.d0

  for ikid=0, n_elements(kidpar)-1 do begin
     if kidpar[ikid].type eq 1 then begin
        baseline[ikid,*]    = median( data.rf_didq[ikid], param.decor.median.width)
        data.rf_didq[ikid] -= baseline[ikid,*]
     endif
  endfor
  
  return
end
