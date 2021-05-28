

pro merge_scan_kidpars, scan_list, kidpar_list, nickname, $
                        ptg_numdet_ref=ptg_numdet_ref, $
                        nostop=nostop, version=version, $
                        ofs_el_min=ofs_el_min, ofs_el_max=ofs_el_max, $
                        black_list=black_list, dist_reject=dist_reject

nscans = n_elements(kidpar_list)

;; Quicklook: highlight kids fitted on the edges of a scan and which
;; might be discarded
wind, 1, 1, /free, /large
make_ct, 3, ct
my_multiplot, nscans, 3, pp, pp1, /rev
for iscan=0, nscans-1 do begin
   kidpar = mrdfits( kidpar_list[iscan], 1, /silent)
   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         plot, [kidpar[w1].x_peak_azel], [kidpar[w1].y_peak_azel], psym=1, $
               position=pp[iarray-1,iscan,*], /noerase, xtitle='Az', $
               ytitle='El', /iso, xra=[-1,1]*300, yra=[-1,1]*300, title='scan '+strtrim(iscan,2)

         oplot, [kidpar[w1].x_peak_azel], [kidpar[w1].y_peak_azel], psym=1, col=ct[iscan]

         ;; flag out kids that are on the edge of the scan
         w = where( kidpar.type eq 1 and kidpar.array eq iarray and $
                    (kidpar.y_peak_azel le ofs_el_min[iscan] or kidpar.y_peak_azel ge ofs_el_max[iscan]), nw)
         if nw ne 0 then begin
            oplot, [kidpar[w].x_peak_azel], [kidpar[w].y_peak_azel], psym=4, col=0
            kidpar[w].plot_flag = 9
         endif
         legendastro, 'A'+strtrim(iarray,2), box=0
      endif
   endfor
   kidpar2 = kidpar
   save, kidpar2, file='kidpar_temp_'+strtrim(iscan,2)+".save"
endfor
my_multiplot, /reset

;; Merge the three kidpars into the final one
wind, 1, 1, /free, /xlarge
my_multiplot, 3, 1, pp, pp1, /rev
make_ct, 3, ct
;; init kidpar and type
restore, 'kidpar_temp_'+strtrim(0,2)+".save"
kidpar = kidpar2
kidpar.type = 3
wd,/a
for iarray=1,3 do begin
   for iscan=0, nscans-1 do begin
      restore, 'kidpar_temp_'+strtrim(iscan,2)+".save"
      if n_elements(kidpar) ne n_elements(kidpar2) then begin
         message, /info, "incompatible kidpar and kidpar2"
         message, /info, "fix this otherwise wkeep indices will crash below."
         stop
      endif

      nk_kidpar_outlyers, kidpar2, wkeep, array=iarray, /plot_flag_zero
      nwkeep = n_elements(wkeep)
      warray = where( kidpar2.type eq 1 and kidpar2.array eq iarray, nwarray)
      print, "iarray, iscan, nwarray, nwkeep: ", iarray, iscan, nwarray, nwkeep

      if iscan eq 0 then begin
         w = where( kidpar2.array eq iarray and kidpar2.type eq 1, nw)
         if nw ne 0 then begin
            plot, [kidpar2[w].x_peak_azel], [kidpar2[w].y_peak_azel], psym=1, $
                  /iso, syms=0.5, $
                  xra=[-1,1]*400, yra=[-1,1]*400, /nodata, position=pp[iarray-1,0,*], /noerase, $
                  title=kidpar_list[iscan]
         endif
      endif
      if nwkeep ne 0 then oplot, [kidpar2[wkeep].x_peak_azel], [kidpar2[wkeep].y_peak_azel], psym=1, col=ct[iscan]
      legendastro, ['A'+strtrim(iarray,2)], box=0

      if nwkeep ne 0 then begin
         kidpar[wkeep]      = kidpar2[wkeep]
         kidpar[wkeep].scan = scan_list[iscan]
      endif
      
   endfor

endfor
my_multiplot, /reset
if not keyword_set(nostop) then stop

;; clean up
for iscan=0,nscans-1 do spawn, "rm -f kidpar_temp_"+strtrim(iscan,2)+".save"

w = where( kidpar.type eq 1 and (finite(kidpar.nas_x) ne 1 or finite(kidpar.fwhm) ne 1), nw)
if nw ne 0 then begin
   print, strtrim(nw,2)+" kids have infinite(nas_x or y) but type=1 => setting type to 3."
   kidpar[w].type = 3
endif

message, /info, "The three kidpars have been merged into only one."

wind, 1, 1, /free, /large
xra = [-1, 1]*60
yra = [-1, 1]*60
my_multiplot, 3, 2, pp, pp1, /rev
for iarray=1,3 do begin
   w = where( kidpar.array eq iarray and kidpar.type eq 1, nw)
   if nw ne 0 then begin
      plot, [kidpar[w].nas_x], [kidpar[w].nas_y], psym=1, /iso, syms=0.5, xtitle='Nasmyth x', ytitle='Nasmyth y', $
            position=pp[iarray-1,0,*], /noerase, title='Array '+strtrim(iarray,2)
      plots, [xra[0], xra[0], xra[1], xra[1], xra[0]], $
             [yra[0], yra[1], yra[1], yra[0], yra[0]], col = 250
      plot, [kidpar[w].x_peak_azel], [kidpar[w].y_peak_azel], psym=1, /iso, syms=0.5, $
            xtitle='Azimuth', ytitle='elevation', title='Array '+strtrim(iarray,2), $
            position=pp[iarray-1,1,*], /noerase
   endif
endfor
!p.multi=0
if not keyword_set(nostop) then stop

print, "Now, choose the ref pixel"
;; wind, 1, 1, /free, /xlarge
;; !p.multi = [0, 3, 1]
;; for iarray = 1, 3 do begin
;;    w = where( kidpar.array eq iarray and kidpar.type eq 1 and $
;;               kidpar.nas_x ge xra[0] and kidpar.nas_x le xra[1] and $
;;               kidpar.nas_y ge yra[0] and kidpar.nas_y le yra[1], nw)
;;    if nw gt 2 then begin
;;       plot, kidpar[w].nas_x, kidpar[w].nas_y, psym=1, /iso, $
;;             syms=0.5, xtitle='Nasmyth x', ytitle='Nasmyth y', title = 'A'+strtrim(iarray, 2), $
;;             xra = xra, yra = yra
;;       for i=-3, 3 do begin
;;          oplot, [i,i]*10, [-1,1]*1e10, line=2
;;          oplot, [-1,1]*1e10, [i,i]*10, line=2
;;       endfor
;;       xyouts, kidpar[w].nas_x, kidpar[w].nas_y, strtrim(kidpar[w].numdet,2), chars=0.6, col=250
;;       oplot, [0,0], [-1,1]*1e10, line=2
;;       oplot, [-1,1]*1e10, [0,0], line=2
;;    endif
;; endfor
;; !p.multi = 0
;; delvarx,w

wind, 1, 1, /free, /large
init_plot=0
ct = [70, 150, 250]
for iarray = 1, 3 do begin
   w = where( kidpar.array eq iarray and kidpar.type eq 1 and $
              kidpar.nas_x ge xra[0] and kidpar.nas_x le xra[1] and $
              kidpar.nas_y ge yra[0] and kidpar.nas_y le yra[1], nw)
   if nw gt 2 then begin
      if init_plot eq 0 then begin
         plot, kidpar[w].nas_x, kidpar[w].nas_y, psym=1, /iso, $
               syms=0.5, xtitle='Nasmyth x', ytitle='Nasmyth y', title = 'A'+strtrim(iarray, 2), $
               xra = xra, yra = yra, /nodata
         init_plot=1
      endif
      oplot, kidpar[w].nas_x, kidpar[w].nas_y, col=ct[iarray-1], psym=1, syms=0.5
      xyouts, kidpar[w].nas_x, kidpar[w].nas_y, strtrim(kidpar[w].numdet,2), chars=0.6, col=ct[iarray-1]
   endif
endfor

if not keyword_set(ptg_numdet_ref) then begin
   message, /info, "Select the pointing reference detector and relaunch the code"
   message, /info, "with ptg_numdet_ref as keyword"
   stop
endif

print, "stop just before fitting the center of rotation and angle"
if not keyword_set(nostop) then stop

;; The rotation angle depends on elevation, that changes accross the
;; scan and i've no info on elevation here.
;; Fit rotation and magnification
w1 = where(kidpar.type eq 1 and kidpar.plot_flag eq 0,  nw1)
xavg = avg( kidpar[w1].nas_x)
yavg = avg( kidpar[w1].nas_y)

d = sqrt( (kidpar.nas_x-xavg)^2 + (kidpar.nas_y-yavg)^2)
;; First guess minimizing the contribution of potential outlyers
snr_min = 10
w11 = where(kidpar.type eq 1 and d lt 70 and kidpar.plot_flag eq 0 and $
           kidpar.peak_snr_azel ge snr_min and kidpar.peak_snr_nasmyth ge snr_min, nw11)
if nw11 eq 0 then begin
   message, /info, "No good enough kids to fit the first rotation"
   stop
endif
distance = kidpar.nas_x*0.d0
grid_fit_5, kidpar[w11].nas_x, kidpar[w11].nas_y, kidpar[w11].x_peak_azel, kidpar[w11].y_peak_azel, /nowarp, $
            delta_out, alpha_rot_deg, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, xfit, yfit, names=names, $
            title = 'grid_fit_5', noplot=noplot
;;apply this first guess to the entire array to derive distance and
;;flag out outlyers
w1 = where(kidpar.type eq 1 and kidpar.plot_flag eq 0, nw1)
cosalpha = cos(alpha_rot_deg*!dtor)
sinalpha = sin(alpha_rot_deg*!dtor)
xfit = delta_out*( (kidpar[w1].nas_x-nas_center_x)*cosalpha - (kidpar[w1].nas_y-nas_center_y)*sinalpha)
yfit = delta_out*( (kidpar[w1].nas_x-nas_center_x)*sinalpha + (kidpar[w1].nas_y-nas_center_y)*cosalpha)

wd, /a
wind, 1, 1, /f, /large
plot, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, psym = 1, /iso, $
      title = 'Looking for outlyers', xtitle='Azimuth', ytitle='Elevation'
oplot, xfit, yfit, psym = 4, col = 70
legendastro, ['Rotation parameters determined on central kids only', $
              'Kids from ALL arrays'],  box = 0
dd = sqrt( (xfit-kidpar[w1].x_peak_azel)^2 + (yfit-kidpar[w1].y_peak_azel)^2)
distance = kidpar.nas_x*0.d0 + !values.d_nan
distance[w1] = dd

if not keyword_set(dist_reject) then dist_reject = 40 ; conservative
w = where(kidpar.type eq 1 and distance gt dist_reject, nw)

;; make a copy of kidpar in case we need to iterate
kidpar1 = kidpar
if nw ne 0 then begin
   kidpar1[w].type = 3
   kidpar1[w].plot_flag = 1
endif

wind, 1, 1, /free, /large
;w = where(kidpar.numdet eq 1488)
;kidpar[w].type = 3
if keyword_set(black_list) then begin
   my_match, black_list, kidpar1.numdet, suba, subb
   kidpar1[subb].type = 3
endif

get_geometry_3, kidpar1, ptg_numdet_ref, distance=distance, xfit=xfit, yfit=yfit, charsize = 0.6
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

;;-----------------------------------------------
;; Doesn't work automatically actually... :(
;; ;; Determine grid_step
;; alpha_start = [13, 45, 0]
;; delta_start = [9, 10, 0]
;; 
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    if nw1 ne 0 then begin
;;       stop
;;       get_grid_nodes, kidpar[w1].x_peak_nasmyth, kidpar[w1].y_peak_nasmyth, $
;;                       xnode, ynode, alpha_opt, delta_opt, $
;;                       delta_start=delta_start[iarray-1], alpha_start=alpha_start[iarray-1], $
;;                       d_alpha_min=-5, d_alpha_max=5, d_delta_min=-3, d_delta_max=3
;;       kidpar[w1].grid_step = delta_opt
;;    endif
;; if not keyword_set(nostop) then    stop
;; endfor
;; print, "grid_step done."
;;--------------------------------------------

if not keyword_set(nostop) then begin
   print, ""
   print, "Ready to write kidpar"
   stop
endif

if not keyword_set(version) then begin
   nk_write_kidpar, kidpar, "kidpar_"+nickname+"_noskydip.fits"
endif else begin
   nk_write_kidpar, kidpar, "kidpar_"+nickname+"_noskydip_v"+strtrim(version, 2)+".fits"
endelse

end
