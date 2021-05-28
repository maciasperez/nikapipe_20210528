;+
;PURPOSE: Cross calibrate the TOI with respect to the atmosphere
;
;INPUT: The TOI, source flags
;
;OUTPUT: The cross calibration coefficients
;
;LAST EDITION: 05/07/2014: creation
;-

function nika_pipe_atmxcalib, TOI, wsource
  
  Nkid = n_elements(TOI[*,0])
  
  atm_guess = median(TOI, dim=1) ;First atmospheric guess used to cross calibrate
  xcal = dblarr(Nkid, 2)

  for ikid=0, Nkid-1 do begin
     woff_source = where(wsource[ikid, *] ne 1, nwoff)
     if nwoff gt 2 then begin
        fit = linfit((TOI[ikid,*])[woff_source], atm_guess[woff_source])
        xcal[ikid,0] = fit[0]
        xcal[ikid,1] = fit[1]
     endif else begin
        xcal[ikid,0] = 0
        xcal[ikid,1] = 1
     endelse
  endfor

  return, xcal
end
