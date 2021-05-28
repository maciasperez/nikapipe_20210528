;+
;PURPOSE: Get the zero level of a map using the profile
;INPUT: - The profile ({r:radius, y:flux, var:variance})
;       - The largest angular scale recovered
;OUTPUT: the 0 level
;LAST EDITION: 13/04/2013
;LAST EDITOR: Remi ADAM (adam@lpsc.in2p3.fr)
;-

function zero_level, prof, lasr

  npt = n_elements(prof.r)
  frac_prof = lasr/max(prof.r)  ;fraction of the profile at wich we strart
  level = 0d
  norm = 0d
  count = 0
  for k=long(frac_prof*npt), npt-1 do begin
     if prof.var[k]/prof.var[k] eq 1 then begin 
        level = level + prof.y[k]/prof.var[k]
        norm = norm + 1.0/prof.var[k]
        count = count + 1
     endif
  endfor

  level = level/norm

  if count eq 0 then begin 
     print, 'WARNING: No valid point.'
     print, 'Increase the fraction of the profile used here, otherwise the zero level is 0'
     level = 0
  endif

  return, level
end
