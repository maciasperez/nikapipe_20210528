

;; pro merge_sub_kidpars, scan_list, kidpars_dir, nproc, nostop = nostop, version = version, raw = raw
pro auto_merge_sub_kidpars, kidpars_dir, nproc, nickname, nostop=nostop, version=version, raw=raw, $
                            ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject, plot_dir=plot_dir, png=png, ps=ps, $
                            black_list=black_list, no_ref_center=no_ref_center
  
if not keyword_set(nostop) then nostop = 0

output_kidpar_file_name = "kidpar_"+nickname
if not keyword_set(version) then begin
   output_kidpar_file_name += "_v0"
endif else begin
   output_kidpar_file_name += "_v"+strtrim(version, 2)
endelse

if keyword_set(no_ref_center) then output_kidpar_file_name += "_NoRefCenter"

;; Gather all sub-kidpars into a single global one
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
wind, 1, 1, /free, xsize=1300, ysize=700
;; my_multiplot, 3, 2, pp, pp1, /rev, gap_x=0.05
my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.03, $
              xmin=0.02, xmargin=0.01, xmax=0.5, ymin=0.5, ymax=0.97, $
              /full, /dry
xra = [-1,1]*250
yra = [-1,1]*250
chars=0.6
syms=0.3
for iarray=1,3 do begin
   w = where( kidpar.array eq iarray, nw)
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   if nw gt 1 then begin
      plot, kidpar[w].nas_x, kidpar[w].nas_y, psym=1, /iso,  chars=chars, $
            position=pp[iarray-1,0,*], /noerase, xra=xra, yra=yra, syms=syms, /xs, /ys
      legendastro, ['Nasmyth', 'Array '+strtrim(iarray,2)], box=0

      plot, kidpar[w].x_peak_azel, kidpar[w].y_peak_azel, psym=1, /iso,  $
            chars=chars, position=pp[iarray-1,1,*], /noerase, xra=xra, yra=yra, $
            syms=syms, /xs, /ys
      legendastro, ['Azel', 'Array '+strtrim(iarray,2)], box=0
   endif
endfor
my_multiplot, /reset

;; make sure no NaN remains
w = where( finite(kidpar.nas_x) eq 0 or $
           finite(kidpar.nas_y) eq 0 or $
           finite(kidpar.fwhm) eq 0, nw)
if nw ne 0 then kidpar[w].type = 3

;; Reference pixel:
;wind, 1, 1, /free, /large
init_plot=0
ct = [70, 150, 250]
xra = [-1,1]*40
yra = [-1,1]*40
position = [0.7, 0.05, 0.95, 0.95]
for iarray = 1, 3 do begin
   w = where( kidpar.array eq iarray and kidpar.type eq 1 and $
              kidpar.nas_x ge xra[0] and kidpar.nas_x le xra[1] and $
              kidpar.nas_y ge yra[0] and kidpar.nas_y le yra[1], nw)
   if nw gt 2 then begin
      if init_plot eq 0 then begin
         plot, kidpar[w].nas_x, kidpar[w].nas_y, psym=1, /iso, $
               syms=0.5, xtitle='Nasmyth x', ytitle='Nasmyth y', yra=yra+[0, 20], $
               xra = xra, /nodata, /xs, /ys, position=position, /noerase, chars=0.7
         init_plot=1
      endif
      oplot, kidpar[w].nas_x, kidpar[w].nas_y, col=ct[iarray-1], psym=1, syms=0.5
      draw0
      xyouts, kidpar[w].nas_x, kidpar[w].nas_y - (iarray eq 3)*2, $
              strtrim(kidpar[w].numdet,2), chars=0.7, col=ct[iarray-1]
      legendastro, 'Array '+strtrim([1,2,3],2), col=ct, textcol=ct, psym=1, box=0
   endif
endfor
message, /info, "Now, check or choose the ref pixel"
if not keyword_set(ptg_numdet_ref) then begin
      print, "Enter ptg_numdet_ref: "
      read, ptg_numdet_ref
endif

;; Discard kids with absurd offsets or amplitudes or noise...
position = [0.04, 0.25, 0.4, 0.5]
nk_discard_outlyers, kidpar, kidpar_out, title='First cut on absurd values', $
                     position=position, charsize=0.6
kidpar = kidpar_out

;; Discard kids who behave badly during the azel to nasmyth rotation
;; Fit rotation and magnification
w1 = where(kidpar.type eq 1,  nw1)
xavg = avg( kidpar[w1].nas_x)
yavg = avg( kidpar[w1].nas_y)
d = sqrt( (kidpar.nas_x-xavg)^2 + (kidpar.nas_y-yavg)^2)
;; First guess minimizing the contribution of potential outlyers
snr_min = 10
w11 = where(kidpar.type eq 1 and d lt 70 and $
            kidpar.peak_snr_nasmyth ge snr_min, nw11)
if nw11 eq 0 then begin
   message, /info, "No good enough kids to fit the first rotation"
   message, /info, "I stop here to let you have a look."
   stop, ''
endif
distance = kidpar.nas_x*0.d0
position = [0.2, 0.25, 0.7, 0.5]
charsize = 0.6
grid_fit_5, kidpar[w11].nas_x, kidpar[w11].nas_y, kidpar[w11].x_peak_azel, kidpar[w11].y_peak_azel, /nowarp, $
            delta_out, alpha_rot_deg, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, xfit, yfit, names=names, $
            title = 'grid_fit_5 1st guess ', noplot=noplot, position=position, charsize=charsize

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

;; ;wd, /a
;; ;wind, 1, 1, /f, xsize=800, ysize=650
;; ;outplot, file=plot_dir+"/outlyers_"+nickname, png=png, ps=ps
;; plot, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, psym = 1, /iso, $
;;       title = 'Looking for outlyers', xtitle='Azimuth', ytitle='Elevation'
;; oplot, xfit, yfit, psym = 4, col = 70
;; if nw9 ne 0 then begin
;;    oplot, [kidpar[w9].x_peak_azel], [kidpar[w9].y_peak_azel], psym=4, col=200, thick=2
;;    oplot, [xfit[w1[w9]]], [yfit[w1[w9]]], psym=1, col=200, thick=2
;; endif
;; legendastro, ['Rotation parameters determined on kids near the center only', $
;;               'Kids from ALL arrays', $
;;               'Distance > '+strtrim(dist_reject,2)],  $
;;              box = 0, textcol=[!p.color, !p.color, 200]
;; legendastro, nickname, /bottom, box=0
;; if keyword_set(black_list) then begin
;;    my_match, black_list, kidpar.numdet, suba, subb
;;    kidpar[subb].type = 3
;; endif
;; ;plots, [-220, -220, 220, 220, -220], $
;; ;       [-220,  250, 250, -220, -220]
;; ;outplot, /close


;; w = where( kidpar.x_peak_azel le -150 and kidpar.y_peak_azel le -180, nw) & print, nw
;; if nw ne 0 then kidpar[w].type = 3
;; w = where( kidpar.x_peak_azel le -200 and  kidpar.y_peak_azel le -100, nw) & print, nw
;; if nw ne 0 then kidpar[w].type = 3
;; w = where( kidpar.x_peak_azel ge 100 and  kidpar.y_peak_azel le -190, nw) & print, nw
;; if nw ne 0 then kidpar[w].type = 3
;; w = where( kidpar.x_peak_azel ge 190, nw)
;; if nw ne 0 then kidpar[w].type = 3

if keyword_set(no_ref_center) then begin
   ;; keep all kids for RTA for now
   w1 = where(kidpar.type eq 1, nw)
   kidpar[w1].rta = 1
   nk_write_kidpar, kidpar, output_kidpar_file_name+".fits"
   return
endif

;; ;; Account for the ref detector
;; wref = where( kidpar.numdet eq ptg_numdet_ref)
;; w = where( sqrt( (kidpar.x_peak_azel-kidpar[wref].x_peak_azel)^2 + $
;;                  (kidpar.y_peak_azel-kidpar[wref].y_peak_azel)^2) ge 250, nw)
;; if nw ne 0 then kidpar[w].type = 3
;; stop

;;;;--------------------
;;message, /info, "fix me: NP, dec. 6th"
;;message, /info, "fix me: Check that the center of rotation is the same for each array"
;;wkidref = where( kidpar.numdet eq ptg_numdet_ref, nw)
;;w1 = where( kidpar.type eq 1, nw1)
;;kidpar[w1].nas_x -= kidpar[wkidref].nas_x
;;kidpar[w1].nas_y -= kidpar[wkidref].nas_y
;;
;;for iarray=1, 3 do begin
;;   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;   distance = kidpar.nas_x*0.d0
;;   grid_fit_5, kidpar[w1].nas_x, kidpar[w1].nas_y, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, /nowarp, $
;;               delta_out, alpha_rot_deg, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, xfit, yfit, names=names, $
;;               title = 'grid_fit_5 array '+strtrim(iarray,2), $
;;               noplot=noplot, distance=dd, charsize = charsize, xtitle = 'Az (arcsec)', ytitle = 'El (arcsec)'
;;   print, "array, nas_center_x, nas_center_y: ", iarray, nas_center_x, nas_center_y
;;   stop
;;endfor
;;stop
;;;;--------------------

;; message, /info, "fix me:"
;; w = where( kidpar.x_peak_azel le -200, nw)
;; if nw ne 0 then kidpar[w].type = 4
;; w = where( abs(kidpar.y_peak_azel) ge 90, nw)
;; if nw ne 0 then kidpar[w].type = 4
;; stop

outplot, file=plot_dir+"/outlyers_"+nickname+"_1", png=png, ps=ps
position = [0.35, 0.05, 0.75, 0.5]
get_geometry_3, kidpar, ptg_numdet_ref, distance=distance, $
                xfit=xfit, yfit=yfit, charsize = 0.6, no_ref_center=no_ref_center, $
                position=position
legendastro, nickname, box=0, /bottom
outplot, /close
message, /info, ""
message, /info, " Outlyers from previous fit in blue have been automatically discarded."
message, /info, " If you see any remaining outlyer, define 'black_list' as keyword and call again this script."
message, /info, " If red squares align well on black crosses and no outlyer remains, press .c"
if not keyword_set(nostop) then stop, ''
message, /info, "Center of rotation done."
stop

;; Flag out kids that would be superposed
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      for i=0, nw1-2 do begin
         ikid = w1[i]
         for j=i+1, nw1-1 do begin
            jkid = w1[j]
            d = sqrt( (kidpar[ikid].nas_x-kidpar[jkid].nas_x)^2 + $
                      (kidpar[ikid].nas_y-kidpar[jkid].nas_y)^2)
            if d lt !nika.grid_step[iarray-1]/4.d0 then begin
               kidpar[ikid].type = 11
               kidpar[ikid].type = 11
            endif
         endfor
      endfor
   endif
   w = where( kidpar.type eq 11 and kidpar.array eq iarray, nw)
   message, /info, "Found "+strtrim(nw,2)+" superposed kids in Array "+strtrim(iarray,2)
endfor

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


nk_write_kidpar, kidpar, output_kidpar_file_name+".fits"



end
