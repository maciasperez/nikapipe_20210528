;+
;PURPOSE: Flag subscans shorter than 2 secondes.
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The flagged data
;
;LAST EDITION: 12/07/2015: creation
;-

pro nika_pipe_flagshortsubscan, param, kidpar, data

  subscan = data.subscan

  for isubscan=1, max(subscan) do begin
     wsubscan = where(subscan eq isubscan, nwsubscan)
     if nwsubscan le long(2.5*!nika.f_sampling) then begin
        if nwsubscan ne 0 then nika_pipe_addflag, data, 11, wsample=wsubscan
     endif
  endfor

  return
end
