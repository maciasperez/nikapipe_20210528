;+
;PURPOSE: Remove a common mode estimated ontside the source
;
;INPUT: The parameter, TOI, kidpar, subscan, source location
;
;OUTPUT: The decorrelated data structure.
;        - The KIDs atmospheric baseline
;        - The atmospheric templates
;
;LAST EDITION: - Last revision before chaning : 1157. Up to 1157, the linear fit of the
;                atmospheric calibration includes the source where as we'd rather
;                interpolate it. Nico. + updated I/O to match other
;                modules
;              - 05/07/2104: 
;-

pro nika_pipe_cmkidout, param, TOI, kidpar, subscan, wsource, elevation, ofs_el, $
                        baseline, temp_atmo, $
                        k_median=k_median, $
                        silent=silent

  ;;---------- Sanity checks
  if n_params() lt 1 then begin
     message, /info, "Calling sequence:"
     print, "nika_pipe_cmkidout, param, TOI, kidpar, $"
     print, "                    baseline, temp_atmo_1mm, temp_atmo_2mm, $"
     print, "                    median=median"
     return
  endif

  if strupcase(param.decor.common_mode.per_subscan) ne 'YES' $
     and strupcase(param.decor.common_mode.per_subscan) ne 'NO' then begin
     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"
  endif

  if not keyword_set(silent) then begin
     if param.decor.common_mode.x_calib eq 'yes' then message, /info, "Atmospheric calibration far from the source"
     if param.decor.common_mode.x_calib eq 'no' then message, /info, "No atmospheric cross calibration"
  endif

  ;;---------- Initialization
  baseline = TOI*0
  temp_atmo = -1
  
  ;;========== Build the common mode over the entire scan
  if param.decor.common_mode.per_subscan eq 'no' then begin
     w8source = 1 - wsource
     nika_pipe_subtract_common_atm, param, TOI, kidpar, w8source, $
                                    atm, base, $
                                    elev=elevation, ofs_el=ofs_el, k_median=k_median
     baseline = base
     temp_atmo = atm
  endif
  
  ;;========== Build the common mode over the subscans
  if param.decor.common_mode.per_subscan eq 'yes' then begin        
     ;;---------- Loop over subscans
     for isubscan=(min(subscan)>0), max(subscan) do begin
        wsubscan   = where(subscan eq isubscan, nwsubscan)
        if nwsubscan gt long(2.5*!nika.f_sampling) then begin
           TOI_ss  = TOI[*, wsubscan]
           w8source_ss = 1 - wsource[*,wsubscan]
           nika_pipe_subtract_common_atm, param, TOI_ss, kidpar, w8source_ss, $
                                          atm, base, $
                                          elev=elevation[wsubscan], ofs_el=ofs_el[wsubscan], $
                                          k_median=k_median
           TOI[*, wsubscan] = TOI_ss
           baseline[*,wsubscan] = base
           temp_atmo[*,wsubscan] = atm
        endif
     endfor
  endif

  return
end
