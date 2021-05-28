

;; pro merge_sub_kidpars, scan_list, kidpars_dir, nproc, nostop = nostop, version = version, raw = raw
pro merge_sub_kidpars, kidpars_dir, nproc, nickname, nostop=nostop, version=version, raw=raw, $
                       ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject, plot_dir=plot_dir, png=png, ps=ps
  
if not keyword_set(nostop) then nostop = 0

wind, 1, 1, /free, /large
my_multiplot, 3, 3, pp, pp1, /rev, /full, /dry
   
;; read kidpars as output from katana_light and merge them
kidpar_list = kidpars_dir+"/kidpar_"+nickname+"_"+strtrim(indgen(nproc),2)+".fits"

for iproc=0, nproc-1 do begin
   print, kidpar_list[iproc]
   kidpar1 = mrdfits( kidpar_list[iproc], 1, /silent)
   if iproc eq 0 then begin
      kidpar = kidpar1
   endif else begin
      nk  = n_elements(kidpar)
      nk1 = n_elements(kidpar1)
      kidpar_new = kidpar[0]
      kidpar_new = replicate( kidpar_new, nk+nk1)
      kidpar_new[0:nk-1] = kidpar
      kidpar_new[nk:*]   = kidpar1
      kidpar = kidpar_new
   endelse
endfor

;; Quick plot of beam centroid positions
w = where(kidpar.type eq 1,  nw)
junk = where(kidpar.type eq 1 and finite(kidpar.noise) eq 0,  njunk)
my_multiplot, 3, 2, pp, pp1, /rev, gap_x=0.05
xra = [-1,1]*400
yra = [-1,1]*400
for iarray=1,3 do begin
   w = where( kidpar.array eq iarray, nw)
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   if nw gt 1 then begin
      plot, kidpar[w].nas_x, kidpar[w].nas_y, psym=1, /iso,  chars=0.8, $
            position=pp[iarray-1,0,*], /noerase, xra=xra, yra=yra
      legendastro, ['Nasmyth', 'Array '+strtrim(iarray,2)], box=0

      plot, kidpar[w].x_peak_azel, kidpar[w].y_peak_azel, psym=1, /iso,  $
            chars=0.8, position=pp[iarray-1,1,*], /noerase, xra=xra, yra=yra
      legendastro, ['Azel', 'Array '+strtrim(iarray,2)], box=0
   endif
endfor

;; make sure no NaN remains
w = where( finite(kidpar.nas_x) eq 0 or $
           finite(kidpar.nas_y) eq 0 or $
           finite(kidpar.fwhm) eq 0, nw)
if nw ne 0 then kidpar[w].type = 3
my_multiplot, /reset

w = where( kidpar.type eq 1 and (finite(kidpar.nas_x) ne 1 or finite(kidpar.fwhm) ne 1), nw)
if nw ne 0 then begin
   print, strtrim(nw,2)+" kids have infinite(nas_x or y) but type=1 => setting type to 3."
   kidpar[w].type = 3
endif

print, "Now, check or choose the ref pixel"

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
              strtrim(kidpar[w].numdet,2), chars=1.0, col=ct[iarray-1]
      legendastro, 'Array '+strtrim([1,2,3],2), col=ct, textcol=ct, psym=1, box=0
   endif
endfor

if not keyword_set(ptg_numdet_ref) then begin
      print, "Enter ptg_numdet_ref: "
      read, ptg_numdet_ref
endif

;; Discard kids with absurd offsets or amplitudes or noise...
nk_discard_outlyers, kidpar, kidpar_out
kidpar = kidpar_out

print, "Stop just before fitting the center of rotation and angle."
if not keyword_set(nostop) then stop

;; The rotation angle depends on elevation, that changes accross the
;; scan and i've no info on elevation here.
;; Fit rotation and magnification
w1 = where(kidpar.type eq 1,  nw1)
xavg = avg( kidpar[w1].nas_x)
yavg = avg( kidpar[w1].nas_y)
d = sqrt( (kidpar.nas_x-xavg)^2 + (kidpar.nas_y-yavg)^2)
;; First guess minimizing the contribution of potential outlyers
snr_min = 10
w11 = where(kidpar.type eq 1 and d lt 70 and $
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
w1 = where(kidpar.type eq 1, nw1)
cosalpha = cos(alpha_rot_deg*!dtor)
sinalpha = sin(alpha_rot_deg*!dtor)
xfit = delta_out*( (kidpar[w1].nas_x-nas_center_x)*cosalpha - (kidpar[w1].nas_y-nas_center_y)*sinalpha)
yfit = delta_out*( (kidpar[w1].nas_x-nas_center_x)*sinalpha + (kidpar[w1].nas_y-nas_center_y)*cosalpha)

dd = sqrt( (xfit-kidpar[w1].x_peak_azel)^2 + (yfit-kidpar[w1].y_peak_azel)^2)
distance = kidpar.nas_x*0.d0
distance[w1] = dd

if not keyword_set(dist_reject) then dist_reject = 20 ; 40 ; conservative
w9 = where( distance gt dist_reject, nw9)
if nw9 ne 0 then kidpar[w9].type = 9

wd, /a
wind, 1, 1, /f, /large
outplot, file=plot_dir+"/outlyers_"+nickname, png=png, ps=ps
plot, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, psym = 1, /iso, $
      title = 'Looking for outlyers', xtitle='Azimuth', ytitle='Elevation'
oplot, xfit, yfit, psym = 4, col = 70
if nw9 ne 0 then begin
   oplot, kidpar[w9].x_peak_azel, kidpar[w9].y_peak_azel, psym=4, col=200, thick=2
   oplot, [xfit[w1[w9]]], [yfit[w1[w9]]], psym=1, col=200, thick=2
endif
legendastro, ['Rotation parameters determined on kids near the center only', $
              'Kids from ALL arrays', $
              'Distance > '+strtrim(dist_reject,2)],  $
             box = 0, textcol=[!p.color, !p.color, 200]
legendastro, nickname, /bottom, box=0
if keyword_set(black_list) then begin
   my_match, black_list, kidpar1.numdet, suba, subb
   kidpar[subb].type = 3
endif
plots, [-220, -220, 220, 220, -200], $
       [-220, 250, 250, -200, -220]
outplot, /close
;message, /info, "fix me: early exit"
;return
;stop

w = where( kidpar.x_peak_azel le -200 and kidpar.y_peak_azel ge 200, nw)
if nw ne 0 then kidpar[w].type = 3
w = where( kidpar.x_peak_azel ge 300 and kidpar.y_peak_azel ge 200, nw)
if nw ne 0 then kidpar[w].type = 3
outplot, file=plot_dir+"/outlyers_"+nickname+"_1", png=png, ps=ps
get_geometry_3, kidpar, ptg_numdet_ref, distance=distance, xfit=xfit, yfit=yfit, charsize = 0.6
legendastro, nickname, box=0, /bottom
outplot, /close
message, /info, ""
message, /info, " Outlyers from previous fit in blue have been automatically discarded."
message, /info, " If you see any remaining outlyer, define 'black_list' as keyword and call again this script."
message, /info, " If red squares align well on black crosses and no outlyer remains, press .c"
if not keyword_set(nostop) then stop
message, /info, "Center of rotation done."

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

if not keyword_set(version) then begin
   nk_write_kidpar, kidpar, "kidpar_"+nickname+"_noskydip_v0.fits"
endif else begin
   nk_write_kidpar, kidpar, "kidpar_"+nickname+"_noskydip_v"+strtrim(version, 2)+".fits"
endelse


end
