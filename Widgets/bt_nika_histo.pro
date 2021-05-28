
;; Performs histo on all valid and wplot kids, give kidpar and the field name

pro bt_nika_histo, field, gpar, position, noerase=noerase, k_units=k_units, name=name, $
                   ikid=ikid, light=light, fit=fit

common bt_maps_common


w1    = where( kidpar.type eq 1, nw1)
wplot = where( kidpar.plot_flag eq 0, nwplot)

if nwplot eq 0 then begin

   wind, 1, 1, /free
   plot, [0,1], [0,1], /nodata, xs=4, ys=4
   xyouts, 0.1, 0.3, "No kid is selected for plots"

endif else begin

   junk = execute( "array1 = kidpar[w1]."+field)
   junk = execute( "array2 = kidpar[wplot]."+field)

   !p.position = position
   n_histwork, array2, xhist, yhist, gpar, /fill, fcolor=250, fit=fit, bin=bin, noerase=noerase, title=sys_info.nickname

   if keyword_set(name) then ff=name else ff = strupcase(field)
   if keyword_set(k_units) then ff=ff+" "+k_units

   if keyword_set(light) then begin
      legendastro, ff, /right, box=0, chars=1.5
   endif else begin
      legendastro, [sys_info.ext, $
                    ff, $
                    'Nvalid='+strtrim(nw1,2), $
                    'Nplot='+strtrim(nwplot,2)], chars=2, $
                   box=0, textcol=[!p.color, !p.color, !p.color, 250], /right, /bottom
   endelse

   if keyword_set(ikid) then begin
      cmd = "arrow, kidpar["+strtrim(long(ikid),2)+"]."+$
            field+", "+strtrim(max(yhist)/3.,2)+", kidpar["+strtrim(long(ikid),2)+"]."+field+$
            ", 0, /data, hsize=!d.x_size/128, thick=3, col=150"
      junk = execute( cmd)
   endif


   ;; Global picture
   dx = position[2]-position[0]
   dy = position[3]-position[1]
   !p.position = position + [0.02*dx, 0.5*dy, -0.5*dx, -0.05*dy]
   n_histwork, array1, bin=bin, /fill, /noerase
   n_histwork, array2, bin=bin, xhist, yhist, junk, xfill, yfill, /noplot
   n_hist = n_elements(xhist)
   oplot, [xhist[0] - bin, xhist, xhist[n_hist-1]+ bin] , [0,yhist,0],  psym=10, col=250, thick=2
   polyfill, Xfill,Yfill, color=250, spacing=0, orient=45.

   !p.position = 0
endelse

end
