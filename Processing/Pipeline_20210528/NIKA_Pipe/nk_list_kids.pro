
pro nk_list_kids, kidpar, $
                  lambda=lambda, $
                  valid=valid, nvalid=nvalid, $
                  on=on, non=non, $
                  off=off, noff=noff, $
                  multi=multi, nmulti=nmulti, nkids=nkids

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_list_kids, kidpar, $"
   print, "              lambda=lambda, $"
   print, "              valid=valid, nvalid=nvalid, $"
   print, "              on=on, non=non, $"
   print, "              off=off, noff=noff, $"
   print, "              multi=multi, nmulti=nmulti, nkids=nkids"
   return
endif


if not keyword_set(lambda) then begin
   message, /info, "You must specify lambda"
   return
endif

nkids = n_elements(kidpar)
if long(!nika.run) le 12 then begin
   valid = where( kidpar.type eq 1 and kidpar.array eq lambda, nvalid)
   on    = where( kidpar.type ne 0 and kidpar.array eq lambda, non)
   off   = where( kidpar.type eq 2 and kidpar.array eq lambda, noff)
   multi = where( kidpar.type gt 2 and kidpar.array eq lambda, nmulti)
endif else begin
   ;; For NIKA2, arrays 1 and 3 are 1mm, array 2 is 2mm
   if lambda eq 1 then begin
      valid = where( kidpar.type eq 1 and (kidpar.array eq 1 or kidpar.array eq 3), nvalid)
      on    = where( kidpar.type ne 0 and (kidpar.array eq 1 or kidpar.array eq 3), non)
      off   = where( kidpar.type eq 2 and (kidpar.array eq 1 or kidpar.array eq 3), noff)
      multi = where( kidpar.type gt 2 and (kidpar.array eq 1 or kidpar.array eq 3), nmulti)
   endif else begin
      valid = where( kidpar.type eq 1 and kidpar.array eq 2, nvalid)
      on    = where( kidpar.type ne 0 and kidpar.array eq 2, non)
      off   = where( kidpar.type eq 2 and kidpar.array eq 2, noff)
      multi = where( kidpar.type gt 2 and kidpar.array eq 2, nmulti)
   endelse
endelse
end
