;+
;PURPOSE: Remove a simple common mode in the TOI
;
;INPUT: The parameter structure, the TOI of the given array, the
;kidpar and the subscan
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 21/01/2012: creation(adam@lpsc.in2p3.fr)
;              10/01/2014: use an other kidpar with flagged KIDs
;              05/07/2104: use nika_pipe_atmxcalib now and no loop for
;                          common mode construction
;-

pro nika_pipe_cmdec, param, TOI, kidpar, subscan, silent=silent
  
  N_pt = n_elements(TOI[0,*])
  n_kid = n_elements(TOI[*,0])
  
  w_on = where(kidpar.type eq 1, n_on)   ;Number of detector ON
  w_off = where(kidpar.type eq 2, n_off) ;Number of detector OFF
  
  TOI_in = TOI
  TOI_out = dblarr(n_kid, N_pt)
  wsource = TOI * 0             ;No source considered in simple common mode

  if not keyword_set(silent) then begin
     if param.decor.common_mode.x_calib eq 'yes' then $
        message,/info,'Atmospheric cross calibration' $
     else message,/info,'No atmospheric cross calibration'
  endif

  ;;========== Common mode is all the scan
  if param.decor.common_mode.per_subscan eq 'no' then begin 
     ;;---------- Atmosphere cross calibration
     if param.decor.common_mode.x_calib eq 'yes' then $
        atm_x_calib = nika_pipe_atmxcalib(TOI_in[w_on,*], wsource[w_on, *]) $
     else atm_x_calib = [[dblarr(n_elements(w_on))], [dblarr(n_elements(w_on))+1]]
     
     ;;---------- Get the atmosphere template
     TOI_xcal = TOI[w_on, *]
     TOI_xcal = TOI_xcal * (atm_x_calib[*,1] # replicate(1, N_pt))
     TOI_xcal = TOI_xcal + (atm_x_calib[*,0] # replicate(1, N_pt))
     common_mode = total(TOI_xcal, 1)/n_on

     ;;---------- Decorelate from template
     for ikid=0, n_on-1 do begin
        y = reform(TOI_in[w_on[ikid],*])
        coeff = regress(common_mode, y, CONST=const, YFIT=yfit)
        TOI_out[w_on[ikid],*] = TOI_in[w_on[ikid],*] - reform(yfit)
     endfor
  endif
  
  ;;========== Common mode per subscan
  if param.decor.common_mode.per_subscan eq 'yes' then begin
     ;;---------- Loop over subscans
     for isubscan=(min(subscan)>0), max(subscan) do begin
        wsubscan = where(subscan eq isubscan, nwsubscan)
        if nwsubscan gt long(2.5*!nika.f_sampling) then begin
           ;;---------- Atmosphere cross calibration
           if param.decor.common_mode.x_calib eq 'yes' then $
              atm_x_calib = nika_pipe_atmxcalib((TOI_in[w_on,*])[*, wsubscan], (wsource[w_on, *])[*, wsubscan]) $
           else atm_x_calib = [[dblarr(n_elements(w_on))], [dblarr(n_elements(w_on))+1]]

           ;;---------- Get the atmosphere template
           TOI_xcal = (TOI[w_on, *])[*, wsubscan]
           TOI_xcal = TOI_xcal * (atm_x_calib[*,1] # replicate(1, nwsubscan))
           TOI_xcal = TOI_xcal + (atm_x_calib[*,0] # replicate(1, nwsubscan))
           common_mode = total(TOI_xcal, 1)/n_on

           ;;---------- Decorelate from template
           for ikid=0, n_on-1 do begin
              y = reform(TOI_in[w_on[ikid],wsubscan])
              coeff = regress(common_mode, y, CONST=const, YFIT=yfit)
              TOI_out[w_on[ikid],wsubscan] = TOI_in[w_on[ikid],wsubscan] - reform(yfit)
           endfor
        endif                   ;valid subscan
     endfor                     ;loop on subscans
  endif
  
  TOI = TOI_out

  ;;========== Case the parameter is not right
  if param.decor.common_mode.per_subscan ne 'yes' $
     and param.decor.common_mode.per_subscan ne 'no' then begin
     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"
  endif

  return
end
