;+
;PURPOSE: Remove estimates of the source from the data and decorrelate
;from atmosphere simultaneously
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: - 2014/07/06: use nika_pipe_extract_map.pro
;-

pro nika_pipe_cmmapsubtract, param, data, kidpar

  ;;========== Sanity check
  if strupcase(param.decor.common_mode.per_subscan) ne 'YES' $
     and strupcase(param.decor.common_mode.per_subscan) ne 'NO' then begin
     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"
  endif

  if param.decor.common_mode.map_guess1mm eq '' or param.decor.common_mode.map_guess2mm eq '' then $
     message, 'You need to provide an estimate map of the source for this decorrelation method'

  if param.decor.common_mode.x_calib eq 'yes' then message, /info, "Atmospheric calibration far from the source"
  if param.decor.common_mode.x_calib eq 'no' then message, /info, "No atmospheric cross calibration"

  ;;========== Define variables
  N_pt  = n_elements(data)
  if param.decor.common_mode.median eq 'yes' then k_median = 1 else k_median=0

  toi_est = nika_pipe_extract_estimated_toi(param, data, kidpar)

  ;;========== Decorrelation per full scan
  if param.decor.common_mode.per_subscan eq 'no' then begin
     for lambda=1, 2 do begin
        arr = where(kidpar.array eq lambda, narr)
        if narr ne 0 then begin
           kidpar_arr = kidpar[arr]
           wscan = lindgen(n_pt)
           TOI = data.rf_didq[arr]
           TOI_est_arr = TOI_est[arr, *]
           w8source = 1 - data.on_source_dec[arr]
           elev = data.el
           ofs_el = data.ofs_el
           nika_pipe_subtract_common_atm_and_map, param, TOI, TOI_est_arr, kidpar_arr, wscan, w8source, $
                                                  elev=elev, ofs_el=ofs_el, k_median=k_median
           data.rf_didq[arr] = TOI
        endif
     endfor
  endif

  ;;========== Decorrelation per subscan
  if param.decor.common_mode.per_subscan eq 'yes' then begin
     ;;---------- Loop over lambda
     for lambda=1, 2 do begin
        arr = where(kidpar.array eq lambda, narr)
        if narr ne 0 then begin
           kidpar_arr = kidpar[arr]
           ;;---------- Loop over subscan
           for isubscan=1, max(data.subscan) do begin
              wsubscan = where(data.subscan eq isubscan, nwsubscan)
              if nwsubscan gt long(2.5*!nika.f_sampling) then begin
                 TOI = data[wsubscan].rf_didq[arr]
                 TOI_est_arr = (TOI_est[arr, *])[*, wsubscan]
                 w8source = 1 - data[wsubscan].on_source_dec[arr]
                 elev = data[wsubscan].el
                 ofs_el = data[wsubscan].ofs_el
                 nika_pipe_subtract_common_atm_and_map, param, TOI, TOI_est_arr, kidpar_arr, wsubscan, w8source, $
                                                        elev=elev, ofs_el=ofs_el, k_median=k_median
                 data[wsubscan].rf_didq[arr] = TOI
              endif
           endfor
        endif
     endfor
  endif

  return
end
