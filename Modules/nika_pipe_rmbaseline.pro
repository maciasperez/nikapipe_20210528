;+
;PURPOSE: Remove a baseline per subscan
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The data structure baseline corrected.
;
;LAST EDITION: 
;   21/09/2013: creation (adam@lpsc.in2p3.fr)
;   20/07/2014: use polynomial fit now
;   07/07/2015: polynome removal always per subscan
;-

pro nika_pipe_rmbaseline, param, data, kidpar

  N_pt = n_elements(data)
  n_kid = n_elements(kidpar)
  
  w_on = where(kidpar.type eq 1, n_on)   ;Number of detector ON
  w_off = where(kidpar.type eq 2, n_off) ;Number of detector OFF
  
  ;;========== Polynomial baseline per subscan
  ;;if param.decor.common_mode.per_subscan eq 'yes' then begin
     for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
        wsubscan   = where(data.subscan eq isubscan, nwsubscan)
        if nwsubscan gt long(2.5*!nika.f_sampling) then begin
           time = dindgen(nwsubscan)/nwsubscan
           for ikid=0, n_on-1 do begin
              wfit = where(data[wsubscan].on_source_dec[w_on[ikid]] eq 0, nwfit)
              if nwfit gt 2*param.decor.baseline[0] then begin
                 sig = dblarr(nwsubscan)+(param.decor.baseline[1])^2
                 sig[wfit] = 1
                 y = reform(data[wsubscan].RF_dIdQ[w_on[ikid]])
                 coeff = SVDFIT(time, Y, param.decor.baseline[0], STATUS=status, MEASURE_ERRORS=sig, yfit=yfit)
                 data[wsubscan].RF_dIdQ[w_on[ikid]] -= reform(yfit)
              endif
           endfor
        endif                   ;valid subscan
     endfor                     ;loop on subscans
  ;;endif 

  ;;========== Polynomial baseline per scan  
  ;;if param.decor.common_mode.per_subscan eq 'no' then begin
  ;;   time = dindgen(n_pt)/n_pt
  ;;   for ikid=0, n_on-1 do begin
  ;;      wfit = where(data.on_source_dec[w_on[ikid]] eq 0, nwfit)
  ;;      if nwfit gt 2*param.decor.baseline[0] then begin
  ;;         sig = dblarr(n_pt)+(param.decor.baseline[1])^2
  ;;         sig[wfit] = 1
  ;;         y = reform(data.RF_dIdQ[w_on[ikid]])
  ;;         Result = SVDFIT(time, Y, param.decor.baseline[0], STATUS=status, MEASURE_ERRORS=sig, yfit=yfit)
  ;;         data.RF_dIdQ[w_on[ikid]] -= reform(yfit)
  ;;      endif
  ;;   endfor
  ;;endif

  return
end
