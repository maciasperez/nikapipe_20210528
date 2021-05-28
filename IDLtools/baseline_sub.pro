
;; pro baseline_sub, toi, my_subscan, x_0, y_0, kidpar, nx_width, degree, toi_out, w8_out

pro baseline_sub, toi, my_subscan, kidpar, nx_width, degree, toi_out, w8_out

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "baseline_sub, toi, my_subscan, kidpar, nx_width, degree, toi_out, w8_out"
   return
endif

toi_out = toi
nkids   = n_elements( toi_out[*,0])
nsn = n_elements( toi_out[0,*])
w8_out = dblarr( nsn)

;;for ikid=0, nkids-1 do toi_out[ikid,*] = toi_out[ikid,*] - toi_out[ikid,0]

for i=0, max(my_subscan) do begin

   wscan = where( my_subscan eq i, nwscan)
   if nwscan ne 0 then begin
      w8_out[wscan] = 1.0d0
      xx = dindgen( nwscan)

      for ikid=0, nkids-1 do begin
         if kidpar[ikid].type ne 0 and kidpar[ikid].type ne 2 then begin

            toi_out[ikid,wscan] = toi_out[ikid,wscan] - toi_out[ikid,0]

            xx1 = wscan[0:nx_width-1]
            xx2 = wscan[nwscan-nx_width+1:*]
            y = [ reform(toi_out[ikid, xx1]), reform(toi_out[ikid, xx2])]
            x = [ xx[0:nx_width-1], xx[nwscan-nx_width+1:*]]
            
            R = poly_fit( x, y, degree)
            fit = dblarr(nwscan)
            for n=0, degree do fit = fit + r[n]*xx^n
            ;plot, xx, toi_out[ikid,wscan]
            ;oplot, x, y, psym=1, col=70
            ;oplot, xx, fit, col=250
            
            toi_out[ikid, wscan] = toi_out[ikid, wscan] - fit
         endif
      endfor
   endif
endfor

end
