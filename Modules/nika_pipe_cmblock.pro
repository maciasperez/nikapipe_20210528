;+
;PURPOSE: Remove a common mode per block of best correlated detectors
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 15/02/2014: creation(adam@lpsc.in2p3.fr)
;              05/02/2014: use nika_pipe_onsource
;-

pro nika_pipe_cmblock, param, TOI, kidpar, subscan, wsource, elevation, ofs_el, $
                       baseline, $
                       silent=silent, toi_est=toi_est, blocv=blocv

  if keyword_set(blocv) then blocvalue = blocv else blocvalue = 1

  baseline = TOI*0
  warning = 'no'
  
  ;;========== Sanity check and info
  if strupcase(param.decor.common_mode.per_subscan) ne 'YES' $
     and strupcase(param.decor.common_mode.per_subscan) ne 'NO' then begin
     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"
  endif

  if not keyword_set(silent) then begin
     if param.decor.common_mode.x_calib eq 'yes' then $
        message,/info,"Atmospheric calibration far from the source"
     if param.decor.common_mode.x_calib eq 'no' then $
        message,/info,"No atmospheric calibration"
  endif

  if param.decor.common_mode.median eq 'yes' then k_median = 1 else k_median = 0
  
  ;;========== Decorrelation for the full scan
  ;;if param.decor.common_mode.per_subscan eq 'no' then begin
  w8source = 1 - wsource
  if keyword_set(toi_est) then TOI_est2  = toi_est   
  if blocvalue eq 1 then nika_pipe_subtract_common_bloc, param, TOI, kidpar, w8source, temp_atmo, baseline, $
     war=war, elev=elevation, ofs_el=ofs_el, k_median=k_median, toi_est=toi_est2
  if blocvalue eq 2 then nika_pipe_subtract_common_bloc2, param, TOI, kidpar, w8source, temp_atmo, baseline, $
     war=war, elev=elevation, ofs_el=ofs_el, k_median=k_median, toi_est=toi_est2
  if war eq 'yes' then warning = 'yes'
  ;;endif

  ;;========== Build the atmosphere template subscan by subscan
  if param.decor.common_mode.per_subscan eq 'yes' then begin
     for isubscan=1, max(subscan) do begin
        wsubscan = where(subscan eq isubscan, nwsubscan)
        if nwsubscan gt long(2.5*!nika.f_sampling) then begin ;10s min/ss so 1/4 ss min
           TOI_SS  = TOI[*, wsubscan]
           if keyword_set(toi_est) then TOI_est2  = toi_est[*, wsubscan]
           w8source = 1 - wsource[*,wsubscan]
           elevation_ss = elevation[wsubscan]
           ofs_el_ss = ofs_el[wsubscan]
           if blocvalue eq 1 then nika_pipe_subtract_common_bloc, param, TOI_SS, kidpar, w8source, temp_atmo, base, war=war, elev=elevation_ss, ofs_el=ofs_el_ss, k_median=k_median, toi_est=toi_est2
           if blocvalue eq 2 then nika_pipe_subtract_common_bloc2, param, TOI_SS, kidpar, w8source, temp_atmo, base, war=war, elev=elevation_ss, ofs_el=ofs_el_ss, k_median=k_median, toi_est=toi_est2
           if war eq 'yes' then warning = 'yes'
           TOI[*,wsubscan] = TOI_SS
           baseline[*,wsubscan] = base
        endif else begin
           
        endelse
     endfor
  endif

;;========== Warning because the common mode used has been interpolated
  if warning eq 'yes' then begin
     message, /info, '-----------------------------------------------'
     message, /info, '-------------- IMPORTANT WARNING --------------'
     message, /info, '-----------------------------------------------'
     message, /info, 'The bloc common mode has been interpolated at some point. You should increase the minimum number of KIDs used for the common mode (param.decor.common_mode.nbloc_min) or reduce the considered flagged area around the source (param.decor.common_mode.d_min)'
     message, /info, '-----------------------------------------------'
  endif

  return
end
