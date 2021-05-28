
pro geom_finalize, kidpar_file, ptg_numdet_ref, kidpar, version, nickname, nostop=nostop, black_list=black_list

kidpar = mrdfits( kidpar_file, 1)

;; check ptg_numdet_ref:
w = where( kidpar.numdet eq ptg_numdet_ref, nw)
if kidpar[w].type ne 1 then begin
   message, /info, "ptg_numdet_ref has type /= 1..."
   message, /info, "you must take another one:"
   wind, 1, 1, /free, /large
   init_plot=0
   ct = [70, 150, 250]
   xra = [-60, 60]
   yra = [-60, 60]
   for iarray = 1, 3 do begin
      w = where( kidpar.array eq iarray and kidpar.type eq 1 and $
                 kidpar.nas_x ge xra[0] and kidpar.nas_x le xra[1] and $
                 kidpar.nas_y ge yra[0] and kidpar.nas_y le yra[1], nw)
      if nw gt 2 then begin
         if init_plot eq 0 then begin
            plot, kidpar[w].nas_x, kidpar[w].nas_y, psym=1, /iso, $
                  syms=0.5, xtitle='Nasmyth x', ytitle='Nasmyth y', yra=yra+[0, 20], $
                  xra = xra, /nodata, /xs, /ys
            init_plot=1
         endif
         oplot, kidpar[w].nas_x, kidpar[w].nas_y, col=ct[iarray-1], psym=1, syms=0.5
         draw0
         xyouts, kidpar[w].nas_x, kidpar[w].nas_y - (iarray eq 3)*2, $
                 strtrim(kidpar[w].numdet,2), chars=0.6, col=ct[iarray-1]
         legendastro, 'Array '+strtrim([1,2,3],2), col=ct, textcol=ct, psym=1, box=0
      endif
   endfor
   print, ""
   print, "Enter ptg_numdet_ref: "
   read, ptg_numdet_ref
endif

wind, 1, 1, /free, /large
xra = [-1, 1]*60
yra = [-1, 1]*60
my_multiplot, 3, 2, pp, pp1, /rev
for iarray=1,3 do begin
   w = where( kidpar.array eq iarray and kidpar.type eq 1, nw)
   if nw ne 0 then begin
      if iarray eq 1 then ytitle = 'Nasmyth y' else ytitle=''
      plot, [kidpar[w].nas_x], [kidpar[w].nas_y], psym=1, /iso, syms=0.5, xtitle='Nasmyth x', ytitle=ytitle, $
            position=pp[iarray-1,0,*], /noerase
;      plots, [xra[0], xra[0], xra[1], xra[1], xra[0]], $
;             [yra[0], yra[1], yra[1], yra[0], yra[0]], col = 250
      if iarray eq 1 then ytitle='elevation' else ytitle=''
      plot, [kidpar[w].x_peak_azel], [kidpar[w].y_peak_azel], psym=1, /iso, syms=0.5, $
            xtitle='Azimuth', ytitle=ytitle, title='Array '+strtrim(iarray,2), $
            position=pp[iarray-1,1,*], /noerase
   endif
endfor
!p.multi=0
if not keyword_set(nostop) then stop

;; Pointing ref pixel
if not keyword_set(ptg_numdet_ref) then begin
   wind, 1, 1, /free, /xlarge
   !p.multi = [0, 3, 1]
   for iarray = 1, 3 do begin
      wind, 1, 1, /free, /large
      w = where( kidpar.array eq iarray and kidpar.type eq 1 and $
                 kidpar.nas_x ge xra[0] and kidpar.nas_x le xra[1] and $
                 kidpar.nas_y ge yra[0] and kidpar.nas_y le yra[1], nw)
      if nw gt 2 then begin
         plot, kidpar[w].nas_x, kidpar[w].nas_y, psym=1, /iso, $
               syms=0.5, xtitle='Nasmyth x', ytitle='Nasmyth y', title = 'A'+strtrim(iarray, 2), $
               xra = xra, yra = yra, /xs, /ys
         xyouts, kidpar[w].nas_x, kidpar[w].nas_y, strtrim(kidpar[w].numdet,2), chars=0.6, col=250
         oplot, [0,0], [-1,1]*1e10, line=2
         oplot, [-1,1]*1e10, [0,0], line=2
      endif
   endfor
   !p.multi = 0
   delvarx,w
   message, /info, "Choose the ref pixel, pass it as keyword to this routine and relaunch"
   stop
endif  

if not keyword_set(nostop) then begin
   message, /info, "stop just before fitting the center of rotation and angle"
   stop
endif

;; Fit rotation center
if keyword_set(black_list) then begin
   my_match, black_list, kidpar.numdet, suba, subb
   kidpar[subb].type = 3
endif

kidpar1 = kidpar
get_geometry_3, kidpar1, ptg_numdet_ref, distance=distance, xfit=xfit, yfit=yfit, charsize = 0.6

message, /info, "fix me: looking for a center rotation per array (not passed to the output kidpar yet)"
message, /info, "NOTE: kids have just been centered on the ref pix"
w1 = where( kidpar.type eq 1)
print, "all arrays together: nas center: ", kidpar[w1[0]].nas_center_x, kidpar[w1[0]].nas_center_y
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      kidpar2 = kidpar[w1]
      get_geometry_3, kidpar2, ptg_numdet_ref, distance=distance, xfit=xfit, yfit=yfit, charsize = 0.6, /no_ref_center
      print, "array "+strtrim(iarray,2)+", nas center: ", kidpar2[0].nas_center_x, kidpar2[0].nas_center_y
   endif
endfor

message, /info, ""
message, /info, " Outlyers from previous fit in blue have been automatically discarded."
message, /info, " If you see any remaining outlyer, define 'black_list' as keyword and call again this script."
message, /info, " If red squares align well on black crosses and no outlyer remains, press .c"
if not keyword_set(nostop) then stop
message, /info, "Center of rotation done."

;; Take kidpar1 as modified by get_geometry_3 (recentered on ptg_numdet_ref)
kidpar = kidpar1

;; keep all kids for RTA for now
w1 = where(kidpar.type eq 1, nw)
kidpar[w1].rta = 1

;; ;; Determine grid_step
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    if nw1 ne 0 then begin
;;       get_grid_nodes, kidpar[w1].x_peak_nasmyth, kidpar[w1].y_peak_nasmyth, $
;;                       xnode, ynode, alpha_opt, delta_opt
;;       kidpar[w1].grid_step = delta_opt
;;    endif
;; if not keyword_set(nostop) then    stop
;; endfor
;; print, "grid_step done."

if not keyword_set(nostop) then begin
   print, ""
   print, "Ready to write kidpar"
   stop
endif

nk_write_kidpar, kidpar, "kidpar_"+nickname+"_v"+strtrim(version, 2)+".fits"


end
