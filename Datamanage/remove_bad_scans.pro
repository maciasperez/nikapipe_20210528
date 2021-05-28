;+
; NAME:
;
;    remove_bad_scans
;
; PURPOSE:
;
;   REmove from scan list, those are flag as bad ones
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;
;
;
; INPUTS:
;
;
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
;
;
; OUTPUTS:
;
;
;
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;  JFMP - Nov 2014
;-
pro remove_bad_scans,scan_list,day_list,scan_remove,day_remove

  nbad = n_elements(scan_remove)
  ntot = n_elements(day_list)
  if nbad ge ntot then stop
  
  for iscan = 0,nbad-1 do begin
    lb = where(scan_remove[iscan] eq scan_list and day_remove[iscan] eq day_list,nlb,comp=lkeep,ncomp=nlkeep)
    if nlkeep gt 0 then begin
       scan_list = scan_list[lkeep]
       day_list = day_list[lkeep]
    endif

  endfor
  return
end
