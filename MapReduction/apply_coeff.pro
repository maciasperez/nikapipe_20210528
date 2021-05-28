pro apply_coeff, map_list_in, coeff, kidpar, map_list_out

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "apply_coeff, map_list_in, coeff, kidpar, map_list_out"
   return
endif

; Warning : coeff is ordered like *matrices* (not arrays) in IDL convention

map_list_out = map_list_in*0.0d0
nbol = n_elements( coeff[*,0])
for ibol=0, nbol-1 do begin
   for jbol=0, nbol-1 do begin
      ;;if kidpar[jbol].type eq 1 then begin
      if kidpar[jbol].type ne 0 and kidpar[jbol].type ne 2 then begin
         map_list_out[ibol,*,*] = map_list_out[ibol,*,*] + coeff[jbol,ibol]*map_list_in[jbol,*,*]
      endif
   endfor
endfor

end
