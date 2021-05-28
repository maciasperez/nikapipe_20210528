
;; Performs histo on all valid and wplot kids, give kidpar and the field name

pro ktn_histo, field, position, gpar, noerase=noerase, k_units=k_units, name=name, $
                   ikid=ikid, light=light, fit=fit

common ktn_common


w1    = where( kidpar.type eq 1, nw1)
wplot = where( kidpar.plot_flag eq 0, nwplot)

if nwplot eq 0 then begin

   wind, 1, 1, /free
   plot, [0,1], [0,1], /nodata, xs=4, ys=4
   xyouts, 0.1, 0.3, "No kid is selected for plots"

endif else begin

   junk = execute( "array2 = kidpar[wplot]."+field)

   !p.position = position
;   n_histwork, array2, xhist, yhist, gpar, /fill, fit=fit, bin=bin, $
;               noerase=noerase, title=sys_info.nickname, /nolegend
   np_histo, array2, xhist, yhist, gpar, fcol=70, fit=fit, /nolegend, /noerase;title=sys_info.nickname, /noerase


   if keyword_set(name) then ff=name else ff = strupcase(field)
   if keyword_set(k_units) then ff=ff+" "+k_units

   if keyword_set(light) then begin
      legendastro, ff, /right, box=0, chars=1.5
   endif else begin
      legendastro, ['Nvalid='+strtrim(nw1,2), $
                    'Nplot='+strtrim(nwplot,2)], chars=1, $
                   box=0, textcol=[!p.color, 70]
      if keyword_set(fit) then begin
         legendastro, [ff, $
                       'Median: '+strtrim( string( median(array2), format="(F6.2)"),2), $
                       'Avg: '+strtrim( string(gpar[1], format="(F6.2)"),2), $
                       'Stddev: '+strtrim( string(gpar[2], format="(F6.2)"), 2)], $
                      box=0, chars=1, /right
      endif else begin
         ;;legendastro, [ff, 'Median: '+strtrim( string( median(array2), format="(F6.2)"),2)], box=0, /right, chars=2
         legendastro, [ff, 'Median: '+num2string(median(array2))], box=0, /right, chars=1
      endelse
   endelse

   if keyword_set(ikid) then begin
      cmd = "arrow, kidpar["+strtrim(long(ikid),2)+"]."+$
            field+", "+strtrim(max(yhist)/3.,2)+", kidpar["+strtrim(long(ikid),2)+"]."+field+$
            ", 0, /data, hsize=!d.x_size/128, thick=3, col=150"
      junk = execute( cmd)
   endif

   !p.position = 0
endelse

end
