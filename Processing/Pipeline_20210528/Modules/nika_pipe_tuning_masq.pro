
;; Detectcs tunings on a_masq and b_masq and sets w8 to 0

pro nika_pipe_tuning_masq, param, data, kidpar

if tag_exist( data, "a_masq") then begin
   wa = where( data.a_masq ne 0, nwa)

   if nwa ne 0 then begin
      wkida = where( kidpar.array eq 1, nwkida)
      if nwkida ne 0 then begin
         mask = long( data.a_masq ne 0)
         ;; enlarge it to flag adjacent samples
         kernel = dblarr(100) + 1.d0
         r = convol( mask, kernel)
         w = where( r ne 0)
         ;; set w8 to 0
         data[w].w8[wkida] = 0.d0
      endif
   endif
endif

if tag_exist( data, "b_masq") then begin
   wa = where( data.b_masq ne 0, nwa)

   if nwa ne 0 then begin
      wkidb = where( kidpar.array eq 1, nwkidb)
      if nwkidb ne 0 then begin
         mask = long( data.b_masq ne 0)
         ;; enlarge it to flag adjacent samples
         kernel = dblarr(100) + 1.d0
         r = convol( mask, kernel)
         w = where( r ne 0)
         ;; set w8 to 0
         data[w].w8[wkidb] = 0.d0
      endif
   endif
endif

end
