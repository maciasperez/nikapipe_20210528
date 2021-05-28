function nk_median, data, dim = dim
; computes the median but first eliminate the nan bread
                                ; works in the same way as mean (/nan)
  ; FXD June 2020
sizdat = size( data)
case  sizdat[0] of
   1: begin
      u = where( finite(data), nu)
      if nu ge 1 then nkm = median( data[u]) else nkm = !values.d_nan
   end
   2: begin
      if not keyword_set( dim) then begin
         u = where( finite(data), nu)
         if nu ge 1 then nkm = median( data[u]) else nkm = !values.d_nan
      endif else begin
         if dim eq 1 then begin
            nkm = dblarr( sizdat[2])
            for i = 0, sizdat[2]-1 do begin
               u = where( finite(data[*, i]), nu)
               if nu ge 1 then nkm[i] = median( data[u, i]) else nkm[i] = !values.d_nan
            endfor
         endif
         if dim eq 2 then begin
            nkm = dblarr( sizdat[1])
            for i = 0, sizdat[1]-1 do begin
               u = where( finite(data[i, *]), nu)
               if nu ge 1 then nkm[i] = median( data[i, u]) else nkm[i] = !values.d_nan
            endfor
         endif
      endelse
   end
   else: message, /info, 'not a valid dimension for the data'
endcase
return, nkm
end
