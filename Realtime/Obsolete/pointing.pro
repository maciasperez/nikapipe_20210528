
pro pointing, day, scan_num, offsets1, offsets2, numdet1_in=numdet1_in, numdet2_in=numdet2_in, param=param, $
              one_mm_only=one_mm_only, two_mm_only=two_mm_only, png=png, ps=ps, check=check, $
              common_mode_radius=common_mode_radius, sn_min=sn_min, sn_max=sn_max, $
              simu=simu, noskydip=noskydip, nomap=nomap, p2cor=p2cor, p7cor=p7cor, nas_offset_x=nas_offset_x, $
              nas_offset_y=nas_offset_y, imbfits=imbfits, $
              simple=simple, focal_plane=focal_plane, RF=RF, educated=educated, online=online, no_acq_flag=no_acq_flag,  $
              antimb =  antimb, jump = jump

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " pointing, day, scan_num, offsets1, offsets2, numdet1_in=numdet1_in, numdet2_in=numdet2_in, param=param, $"
   print, "              one_mm_only=one_mm_only, two_mm_only=two_mm_only, png=png, ps=ps, check=check, $"
   print, "              common_mode_radius=common_mode_radius, force=force, sn_min=sn_min, sn_max=sn_max, $"
   print, "              simu=simu, noskydip=noskydip, nomap=nomap, p2cor=p2cor, p7cor=p7cor, nas_offset_x=nas_offset_x, $"
   print, "              nas_offset_y=nas_offset_y, imbfits=imbfits, $"
   print, "              simple=simple, focal_plane=focal_plane, RF=RF, educated=educated, online=online, no_acq_flag=no_acq_flag"
   print, "              antimb = antimb, jump=jump"
   return
endif

if keyword_set(online) and keyword_set(imbfits) then begin
   message, /info, "Please do not set /online and /imbfits at the same time"
   return
endif


;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")


fmt = "(F6.2)"

if not keyword_set(common_mode_radius) then common_mode_radius = 40.

lambda_min = 1
lambda_max = 2
if keyword_set(one_mm_only) then lambda_max = 1
if keyword_set(two_mm_only) then lambda_min = 2

if not keyword_set(param) then begin
   ;; Init param to be used in pipeline modules
   nika_pipe_default_param, scan_num, day, param
endif

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+output_dir
param.output_dir = output_dir

;;--------------------------------------------------------------
;; Retrieve p2cor and p7cor info
xml     = 1 ; default
if keyword_set(online) then begin
   xml = 0
   if not keyword_set(p2cor) then begin
      message, /info, "Please set p2cor as an input keyword if you're in /online mode"
      message, /info, "If your want to put p2cor = zero, then set p2cor=1e-10"
      return
   endif
   if not keyword_set(p7cor) then begin
      message, /info, "Please set p7cor as an input keyword if you're in /online mode"
      message, /info, "If your want to put p7cor = zero, then set p7cor=1e-10"
      return
   endif
   if not keyword_set(nas_offset_x) then begin
      message, /info, "Please set nas_offset_x as an input keyword if you're in /online mode"
      message, /info, "If your want to put nas_offset_x = zero, then set nas_offset_x=1e-10"
      return
   endif
   if not keyword_set(nas_offset_y) then begin
      message, /info, "Please set nas_offset_y as an input keyword if you're in /online mode"
      message, /info, "If your want to put nas_offset_y = zero, then set nas_offset_y=1e-10"
      return
   endif

   init_pako_str, pako_str
   pako_str.p2cor = p2cor
   pako_str.p7cor = p7cor
   pako_str.NAS_OFFSET_X = nas_offset_x
   pako_str.NAS_OFFSET_Y = nas_offset_y
   pako_str.obs_type = "pointing"
endif

if keyword_set(imbfits) then begin
   xml = 0
   init_pako_str, pako_str
   pako_str.obs_type = "pointing"

   nika_find_raw_data_file, scan_num, day, file, imb_fits_file, /silent

   imbHeader = HEADFITS( imb_fits_file,EXTEN='IMBF-scan')
   pako_str.p2cor  = SXPAR(imbHeader, 'P2COR')/!pi*180.d0*3600.d0
   pako_str.p7cor  = SXPAR(imbHeader, 'P7COR')/!pi*180.d0*3600.d0
   pako_str.source = sxpar(imbheader, 'OBJECT')
   r = mrdfits( imb_fits_file, 1)
   pako_str.NAS_OFFSET_X = r.XOFFSET/!arcsec2rad
   pako_str.NAS_OFFSET_Y = r.YOFFSET/!arcsec2rad

endif

if xml eq 1 then parse_pako, scan_num, day, pako_str

pcor_az = pako_str.p2cor
pcor_el = pako_str.p7cor

param.source = strtrim( pako_str.source, 2)

;; Get data
pf = 1
if keyword_set(RF) then pf = 0
nika_pipe_getdata,  param, data, kidpar, /nocut, ext_params=ext_params, pf=pf, $
                    one_mm_only=one_mm_only, two_mm_only=two_mm_only, no_acq_flag=no_acq_flag, $
                    /silent, jump = jump

;; Discard tunings and unreliable sections of data
if not keyword_set(no_acq_flag) then nika_pipe_valid_scan, param, data, kidpar

; Replace bad pointing data
if keyword_set( imbfits) and keyword_set( antimb) then begin
  nika_pipe_antenna2pointing, data, imb_fits_file
                                ; in case of missing pointing data paralactic
                                ; angle is bad, replace it by the last known
                                ; value
  u = where( data.paral eq 0., nu)
  v = where( data.paral ne 0., nv)
  if nu ne 0 then data[u].paral = mean( data[v].paral)
endif

;; Flag saturated, out of resonance kids etc...
if not keyword_set(force) then nika_pipe_outofres, param, data, kidpar, /bypass

;; Account for telescope gain dependence on elevation
nika_pipe_gain_cor, param, data, kidpar

wind, 2, 2, /free
plot, data.ofs_az, data.ofs_el

;;--------------------------------
wind, 1, 1, /free
time = dindgen( n_elementS(data))/!nika.f_sampling
ikid = where( kidpar.numdet eq 406)

wa = where( data.a_masq ne 0, nwa)
wb = where( data.b_masq ne 0, nwb)
plot, time, data.rf_didq[ikid]
if nwa ne 0 then begin
   for i=0, nwa-1 do oplot, time[wa[i]]*[1,1], [-1,1]*1e10, col=70
endif
if nwb ne 0 then begin
   for i=0, nwb-1 do oplot, time[wb[i]]*[1,1], [-1,1]*1e10, col=250
endif
legendastro, ['N masq a'+strtrim(nwa,2), 'N masq b'+strtrim(nwb,2)], box=0
w = where( data.subscan eq 1)
oplot, time[w], data[w].rf_didq[ikid], psym=1, col=250
w = where( data.subscan eq 4)
oplot, time[w], data[w].rf_didq[ikid], psym=1, col=150
w = where( data.subscan eq 3)
oplot, time[w], data[w].rf_didq[ikid], psym=1, col=70
w = where( data.subscan eq 2)
oplot, time[w], data[w].rf_didq[ikid], psym=1, col=40
;;---------------------------------
;;stop


if not keyword_set(sn_min) then sn_min = 0
if not keyword_set(sn_max) then sn_max = n_elements(data)-1
data = data[sn_min:sn_max]

nkids = n_elements( kidpar)

;; !nika.numdet_ref_Xmm is initialized in get_kidpar_ref, called by nika_pipe_getdata
if keyword_set(numdet1_in) then numdet1 = numdet1_in else numdet1 = !nika.numdet_ref_1mm
if keyword_set(numdet2_in) then numdet2 = numdet2_in else numdet2 = !nika.numdet_ref_2mm
numdet_ref = [numdet1, numdet2]

;; Subscans include travel between the ends of each cross arm that must be
;; flagged off looking the azimuth and elevation speeds
vx   = ( data.ofs_az - shift( data.ofs_az, 1))*!nika.f_sampling
vy   = ( data.ofs_el - shift( data.ofs_el, 1))*!nika.f_sampling
vx   =   vx[1:*]                ; discard first sample due to shift
vy   =   vy[1:*]
data = data[1:*]                ; to align with vx and vy

v_thres = 5. ; 10 ; 5.

;; Select subscans
;; Overwrite data.subscan for convenience
subscan_ori  = data.subscan
data_copy    = data
data.subscan = 0
for i=1, 4 do begin
   w = where( data_copy.subscan eq i)
   ;; Speed at mid-subscan
   vy_mid = median( vy[w])
   vx_mid = median( vx[w])
   w = where( data_copy.subscan eq i and $
              abs(vx-vx_mid) le v_thres and $
              abs(vy-vy_mid) le v_thres)
   data[w].subscan = i
endfor
;; fill in holes left by the loop just above
i1           = min( where( data.subscan ge 1 and data.subscan le 4), max=i2)
data         = data[i1:i2]
w            = where( data.subscan ne 0)
ind          = lindgen(n_elements(data))
data.subscan = interpol( data[w].subscan, ind[w], ind)

;; Check if we are in "total power" or "polarization" mode
;nika_pipe_get_hwp_angle, param, data, kidpar
;synchro_med = median( data.c_synchro)
polar = 0 ; default
;if max( abs(data.c_synchro - median( data.c_synchro))) gt 1e5 then polar = 1

;if polar eq 1 then begin
;   ;; Determine HWP rotation speed
;   get_hwp_rot_freq, data, rot_freq_hz
;   param.polar.nu_rot_hwp = rot_freq_hz;;;

;   ;; Subtract HWP template
;   nika_pipe_hwp_rm, param, kidpar, data, fit
;endif

nika_pipe_deglitch,          param, data, kidpar
nika_pipe_opacity,           param, data, kidpar, noskydip=noskydip
nika_pipe_calib,             param, data, kidpar, noskydip=noskydip                     
data_copy    = data

;; Get overall median speed
data2speed, data, median_speed

;; check pointing data
if keyword_set(check) then begin
   ct_subscan = [70, 200, 150, 250]

   wind, 1, 1, /free
   plot, data_copy.ofs_az, data_copy.ofs_el
   for i=1, 4 do begin
      w = where( data_copy.subscan eq i, nw)
      oplot, data_copy[w].ofs_az, data_copy[w].ofs_el, col=ct_subscan[i-1], thick=2, psym=1
   endfor
;;   banner, "If you see a cross, press .c if not, then the file is corrupted", n=4

   index = lindgen( n_elements(data_copy))
   wind, 1, 1, /free, /large
   !p.multi=[0,3,2]
   plot, index, data_copy.ofs_az, title='Azimuth cut on Subscan only'
   for i=1, 4 do begin
      w = where( data_copy.subscan eq i, nw)
      oplot, index[w], data_copy[w].ofs_az, col=ct_subscan[i-1], psym=1, thick=2
   endfor
   oplot, index, data_copy.ofs_az
   plot, index, data_copy.ofs_el, title='elevation cut on Subscan only'
   for i=1, 4 do begin
      w = where( data_copy.subscan eq i, nw)
      oplot, index[w], data_copy[w].ofs_el, col=ct_subscan[i-1], psym=1, thick=2
   endfor
   oplot, index, data_copy.ofs_el

   ;;--------------
   plot, index, data.ofs_az, title='Azimuth cut on Subscan and speed'
   for i=1, 4 do begin
      w = where( data.subscan eq i)
      oplot, index[w], data[w].ofs_az, col=ct_subscan[i-1], psym=1, thick=2
   endfor

   plot, index, data_copy.ofs_el, title='Elevation cut on subscan and speed'
   for i=1, 4 do begin
      w = where( data.subscan eq i)
      oplot, index[w], data[w].ofs_el, col=ct_subscan[i-1], psym=1, thick=2
   endfor

   ;;--------------
   ikid = where( kidpar.numdet eq numdet1)
   plot, index, data.rf_didq[ ikid], /xs, /ys, xtitle='Sample', title="Numdet "+strtrim( numdet1,2)
   for i=1,4 do begin
      w = where( data.subscan eq i)
      oplot, index[w], data[w].rf_didq[ikid], psym=1, col=ct_subscan[i-1]
   endfor

   ikid = where( kidpar.numdet eq numdet2)
   plot, index, data.rf_didq[ ikid], /xs, /ys, xtitle='Sample', title="Numdet "+strtrim(numdet2,2)
   for i=1,4 do begin
      w = where( data.subscan eq i)
      oplot, index[w], data[w].rf_didq[ikid], psym=1, col=ct_subscan[i-1]
   endfor

   !p.multi=0
endif


;; Get useful information for the logbook
nika_get_log_info, scan_num, day, data, log_info, kidpar=kidpar
log_info.scan_type = pako_str.obs_type
log_info.source    = pako_str.source
if keyword_set(polar) then log_info.scan_type = pako_str.obs_type+'_polar'

;; test  = file_test( param.imb_fits_file, /dir) ; is a directory
;; test2 = file_test( param.imb_fits_file)      ; file/dir exists
;; antexist = (test eq 0) and (test2 eq 1)
;; if  antexist then begin 
;;    a=mrdfits( param.imb_fits_file,0,hdr,/sil)
;;    log_info.scan_type = sxpar( hdr,'OBSTYPE',/silent)
;; endif

;; Subtract a common mode built with kids far from the source
source_pos  = dblarr(2,2)
closest_kid = intarr(2)

;; We may be not centered at all, so we look for the source first
;; Quick median filter for the first iteration
;param.decor.method = 'median_simple'
;param.decor.median.width = long( 10.*max(!nika.fwhm_nom)/median_speed*!nika.f_sampling)
;nika_pipe_decor, param, data, kidpar

;; ;; subtract a baseline per kid per subscan
;; ;;ikid = 302
;; ;;index = lindgen(n_elements(data))
;; ;;plot, index, data.rf_didq[ikid]
;; for isubscan=1, 4 do begin
;;    wsubscan    = where( data.subscan eq isubscan, nwsubscan)
;;    nsn_edge    = long( 0.05*nwsubscan) > 10
;;    sample_edge = [wsubscan[0:nsn_edge], wsubscan[nwsubscan-1-nsn_edge:*]]
;; 
;;    for ikid=0, nkids-1 do begin
;;       if kidpar[ikid].type eq 1 then begin
;;          fit = linfit( sample_edge, data[sample_edge].rf_didq[ikid])
;;          baseline = fit[0] + fit[1]*wsubscan
;;          data[wsubscan].rf_didq[ikid] -= baseline
;;       endif
;;    endfor
;; endfor


;;data_copy = data
;;ikid = 331
;;w1 = wherE( kidpar.type eq 1, nw1)
;;make_ct, nw1, ct
;;wind, 1, 1, /free, /large
;;plot, data.rf_didq[ikid], yra=minmax(data.rf_didq[w1]), /ys
;;for i=0, nw1-1 do begin &$
;;print, i &$
;;   oplot, data.rf_didq[w1[i]], col=ct[i] &$
;;   cont_plot &$
;;endfor

param.decor.method = 'common_mode'
param.decor.common_mode.per_subscan = "no"
nika_pipe_decor, param, data, kidpar

;; Project maps at this iteration **in RADEC** for nika_pipe_cmkidout
box = ['A', 'B']
w   = where( data.subscan ne round(data.subscan), nw)
if nw ne 0 then data[w].w8 = 0.d0
nika_pipe_map, param, data, kidpar, box_maps, $
               xmap=xmap, ymap=ymap, one_mm_only=one_mm_only, two_mm_only=two_mm_only

if keyword_set(check) then begin
   wind, 1, 1, /free, xs=1200
   my_multiplot, 2, 1, pp, pp1
   phi = dindgen(200)/199*2*!dpi
endif
for lambda=lambda_min, lambda_max do begin
   junk = execute( "map     = box_maps."+box[lambda-1]+".jy")
   junk = execute( "map_var = box_maps."+box[lambda-1]+".var")

   fitmap, map, map_var, xmap, ymap, params, educated=educated
   source_pos[lambda-1,0] = params[4]
   source_pos[lambda-1,1] = params[5]

   if keyword_set(check) then begin
      xx  = params[2]*cos(phi)
      yy  = params[3]*sin(phi)
      xx1 = cos(params[6])*xx - sin(params[6])*yy
      yy1 = sin(params[6])*xx + cos(params[6])*yy
      !mamdlib.coltable = 1
      imview, map, xmap=xmap, ymap=ymap, position=pp1[lambda-1,*], /noerase, nsigma=5, $
              title=param.day+"s"+strtrim(param.scan_num,2)+" "+strtrim(lambda,2)+'mm', $
              xtitle='RA', ytitle='DEC'
      loadct, 39
      oplot, [0,0], minmax(ymap), line=2, col=255
      oplot, minmax(xmap), [0,0], line=2, col=255
      oplot, params[4] + xx1, params[5] + yy1, col=250
      oplot, [params[4]], [params[5]], psym=1, col=250
      legendastro, ['!7D!3RA '+num2string(params[4]), $
                    '!7D!3DEC '+num2string(params[5]), $
                    'Peak '+num2string(params[1]), $
                    'FWHM '+num2string( sqrt(params[2]*params[3])/!fwhm2sigma)], textcol=255, box=0
      legendastro, ['Median simple (RA, Dec)'], textcol=255, /right, box=0
   endif
endfor

;; Subtract common mode
pos = avg( source_pos, 0)
if keyword_set(one_mm_only) then pos = reform( source_pos[0,*])
if keyword_set(two_mm_only) then pos = reform( source_pos[1,*])
data = data_copy

nika_pipe_cmkidout, param, data, kidpar, baseline;, pos=pos

;; Now that data have been decorrelated, monitor the noise
nika_pipe_quick_noise_estim, param, data, kidpar, /mjy

;; Project final maps in (Az,el) this time to compute pointing corrections
box    = ['A', 'B']
nika_pipe_map, param, data, kidpar, box_maps, /azel, $
               xmap=xmap, ymap=ymap, one_mm_only=one_mm_only, two_mm_only=two_mm_only

p_res = 0
offsets = dblarr(2,2) ; to print summary
nterms = 5

;; Main loop
nsubscans = 4
make_ct, nsubscans, ct_subscan
my_multiplot, 3, 2, /rev, pp, pp1
wind, 1, 1, /free, /large
outplot, file=output_dir+"/plot", png=png, ps=ps, /transp
for lambda=lambda_min, lambda_max do begin

   ;; Sanity check on the choice of the reference kids
   w1 = where( kidpar.array eq lambda and kidpar.type eq 1, nw1)
   ikid_ref = (where( kidpar.numdet eq numdet_ref[lambda-1], nw))[0]
   if nw eq 0 then message, "could nof find "+strtrim(numdet_ref[lambda-1],2)+" in kidpar"
   if kidpar[ikid_ref].type ne 1 and not keyword_set(force) then begin
      message, /info, ""
      message, /info, "Ref. kid has type /= 1 ?!"
      message, ""
   endif

   ;; Azimuth / elevation subscans
   for i=0, 1 do begin
      ;; global plot range
      w = where( data.subscan eq (2*i+1) or data.subscan eq (2*i+2), nw)
      yra = minmax( data[w].rf_didq[ikid_ref])
      yra = [yra[0], yra[1]+0.8*(yra[1]-yra[0])]

      ;; Timelines must be plotted as a function of the pointing of the reference
      ;; kid to avoid confusion on the sign of the correction derived on timelines
      ;; or on the map

      ;; 1st scan
      ;;w = where( data.subscan eq (2*i+1), nw)
;      w = where( data.subscan eq (2*i+1) and data.w8[ikid_ref] ne 0., nw)
      w = where( data.subscan eq (2*i+1) and data.flag[ikid_ref] eq 0, nw)
      nika_nasmyth2azel, kidpar[ikid_ref].nas_x, kidpar[ikid_ref].nas_y, $
                         0.0, 0.0, data[w].el*!radeg, daz, del, $
                         nas_x_ref=kidpar[ikid_ref].nas_center_X, nas_y_ref=kidpar[ikid_ref].nas_center_Y
      if i eq 0 then begin
         x      = data[w].ofs_az - daz
         xtitle = 'Azimuth'
         p      = '!7D!3az'
      endif else begin
         x      = data[w].ofs_el - del
         xtitle = 'Elevation'
         p      = '!7D!3el'
      endelse
      xra = minmax( x)
      fit = gaussfit( x, data[w].rf_didq[ikid_ref], a1, nterms=nterms)
      plot,  x, data[w].rf_didq[ikid_ref], position=pp[i,lambda-1,*], $
             /xs, xra=xra, yra=yra, /ys, xtitle=xtitle, /noerase
      oplot, x, a1[3] + a1[4]*x + a1[0]*exp(-(x-a1[1])^2/(2.0d0*a1[2]^2)), col=70, thick=2

      ;; 2nd scan
      ;;w = where( data.subscan eq (2*i+2), nw)
;      w = where( data.subscan eq (2*i+2) and data.w8[ikid_ref] ne 0., nw)
w = where( data.subscan eq (2*i+2) and data.flag[ikid_ref] eq 0, nw)
      nika_nasmyth2azel, kidpar[ikid_ref].nas_x, kidpar[ikid_ref].nas_y, $
                         0.0, 0.0, data[w].el*!radeg, daz, del, $
                         nas_x_ref=kidpar[ikid_ref].nas_center_X, nas_y_ref=kidpar[ikid_ref].nas_center_Y
      if i eq 0 then x = data[w].ofs_az - daz else x = data[w].ofs_el - del
      fit = gaussfit( x, data[w].rf_didq[ikid_ref], a2, nterms=nterms)
      oplot, x, data[w].rf_didq[ikid_ref]
      oplot, x, a2[3] + a2[4]*x + a2[0]*exp(-(x-a2[1])^2/(2.0d0*a2[2]^2)), col=250, thick=2
      legendastro, [strtrim(lambda,2)+"mm, Numdet "+strtrim(kidpar[ikid_ref].numdet,2), $
                    "", $
                    p+'= '+num2string(a1[1]), $
                    'FWHM= '+num2string(a1[2]/!fwhm2sigma), $
                    'Peak= '+num2string(a1[0])+', '+num2string(a2[0]), $
                    "", $
                    p+'= '+num2string(a2[1]), $
                    'FWHM= '+num2string(a2[2]/!fwhm2sigma), $
                    'Peak= '+num2string(a2[0])], box=0, textcol=[0, 0, 70, 70, 70, 0, 250, 250, 250]

      ;; get result
      offsets[lambda-1,i] = (a1[1]+a2[1])/2.
   endfor

endfor

;; Display maps and derive pointing parameters
offsetmap = dblarr(2,2)
for lambda=lambda_min, lambda_max do begin
   
   w1 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw1)

   junk = execute( "map     = box_maps."+box[lambda-1]+".jy")
   junk = execute( "map_var = box_maps."+box[lambda-1]+".var")
   
   fitmap, map, map_var, xmap, ymap, params, educated=educated

   w = where( map_var lt 0, nw)
   if nw ne 0 then map[w] = !values.d_nan
   
   phi = dindgen(200)/199*2*!dpi
   xx  = params[2]*cos(phi)
   yy  = params[3]*sin(phi)
   xx1 = cos(params[6])*xx - sin(params[6])*yy
   yy1 = sin(params[6])*xx + cos(params[6])*yy
   !mamdlib.coltable = 1

   imview, map, xmap=xmap, ymap=ymap, position=pp[2,lambda-1,*], /noerase, nsigma=3, $
           title=param.day+"s"+strtrim(param.scan_num,2)+" "+strtrim(lambda,2)+'mm', $
           xtitle='Azimuth', ytitle='Elevation'
   loadct, 39
   oplot, params[4] + xx1, params[5] + yy1, col=250
   oplot, [params[4]], [params[5]], psym=1, col=250
   legendastro, ['!7D!3az '+num2string(params[4]), $
                 '!7D!3el '+num2string(params[5]), $
                 'Peak '+num2string(params[1]), $
                 'FWHM '+num2string( sqrt(params[2]*params[3])/!fwhm2sigma)], $
                textcol=0, box=0, /bottom, /right

   ;; Overplot focal plane
   w = where( data.subscan eq 1)
   el_deg_avg = avg( data[w].el)*!radeg
   nika_nasmyth2azel, kidpar.nas_x, kidpar.nas_y, $
                      0.0, 0.0, el_deg_avg, daz, del, $
                      nas_x_ref=kidpar.nas_center_X, nas_y_ref=kidpar.nas_center_Y
   oplot, daz[w1], del[w1], psym=3, col=100

   ;; And the reference kid
   w = where( kidpar.numdet eq numdet_ref[lambda-1])
   oplot, daz[w], del[w], psym=1, col=250

   ;; get result
   offsetmap[lambda-1,0] = params[4]
   offsetmap[lambda-1,1] = params[5]

   d = sqrt( (daz-params[4])^2 + (del-params[5])^2)
   dmin = min( d[w1])
   ikid = where( d eq dmin and kidpar.type eq 1 and kidpar.array eq lambda)
   ikid = ikid[0] ; just in case...
   closest_kid[lambda-1] = kidpar[ikid].numdet

endfor
outplot, /close
my_multiplot, /reset


if keyword_set(zigzag) then begin
;; First check on zigzag
   ishift_min = -7
   ishift_max =  7
   ikid = where( kidpar.numdet eq numdet1, nwkid)
   xc_res = dblarr( ishift_max-ishift_min+1, 2, 2, 2) ; ishift, lambda, az/el, forward/backward
   for lambda=lambda_min, lambda_max do begin

      ;; Sanity check on the choice of the reference kids
      w1 = where( kidpar.array eq lambda and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         ;;wind, 1, 1, /free, /large, xs=1400, ys=600
         ;;my_multiplot, ishift_max-ishift_min+1, 2, pp, pp1, /rev, /full

         ikid_ref = (where( kidpar.numdet eq numdet_ref[lambda-1], nw))[0]

         ;; Azimuth / elevation subscans
         for i=0, 1 do begin
            ;; global plot range
            w = where( data.subscan eq (2*i+1) or data.subscan eq (2*i+2), nw)
            yra = minmax( data[w].rf_didq[ikid_ref])
            yra = [yra[0], yra[1]+0.8*(yra[1]-yra[0])]

            ;; Timelines must be plotted as a function of the pointing of the reference
            ;; kid to avoid confusion on the sign of the correction derived on timelines
            ;; or on the map
            
            for ishift=ishift_min, ishift_max do begin
               ;; 1st scan
               w   = where( data.subscan eq (2*i+1), nw)
               toi = shift( data[w].rf_didq[ikid_ref], ishift)
                                ; pas grave si les qques samples sur les bords
                                ; sont pas strictement corrects...

               nika_nasmyth2azel, kidpar[ikid_ref].nas_x, kidpar[ikid_ref].nas_y, $
                                  0.0, 0.0, data[w].el*!radeg, daz, del, $
                                  nas_x_ref=kidpar[ikid_ref].nas_center_X, nas_y_ref=kidpar[ikid_ref].nas_center_Y
               if i eq 0 then begin
                  x      = data[w].ofs_az - daz
                  xtitle = 'Azimuth'
                  p      = '!7D!3az'
               endif else begin
                  x      = data[w].ofs_el - del
                  xtitle = 'Elevation'
                  p      = '!7D!3el'
               endelse
               xra = minmax( x)
               fit = gaussfit( x, toi, a1, nterms=nterms)
               ;;plot,  x, toi, position=pp[ishift-ishift_min,i,*], $
               ;;       /xs, xra=xra, yra=yra, /ys, xtitle=xtitle, /noerase
               ;;oplot, x, a1[3] + a1[4]*x + a1[0]*exp(-(x-a1[1])^2/(2.0d0*a1[2]^2)), col=70, thick=2

               ;; 2nd scan
               w = where( data.subscan eq (2*i+2), nw)
               toi = shift( data[w].rf_didq[ikid_ref], ishift)
               nika_nasmyth2azel, kidpar[ikid_ref].nas_x, kidpar[ikid_ref].nas_y, $
                                  0.0, 0.0, data[w].el*!radeg, daz, del, $
                                  nas_x_ref=kidpar[ikid_ref].nas_center_X, nas_y_ref=kidpar[ikid_ref].nas_center_Y
               if i eq 0 then x = data[w].ofs_az - daz else x = data[w].ofs_el - del
               fit = gaussfit( x, toi, a2, nterms=nterms)
               ;;oplot, x, toi
               ;;oplot, x, a2[3] + a2[4]*x + a2[0]*exp(-(x-a2[1])^2/(2.0d0*a2[2]^2)), col=250, thick=2
               ;;legendastro, [strtrim(lambda,2)+"mm", $
               ;;              "Numdet "+strtrim(kidpar[ikid_ref].numdet,2), $
               ;;              p+'= '+num2string(a1[1]), $
               ;;              p+'= '+num2string(a2[1])], box=0, textcol=[0, 0, 70, 250]

               xc_res[ishift-ishift_min, lambda-1, i, 0] = a1[1]
               xc_res[ishift-ishift_min, lambda-1, i, 1] = a2[1]
            endfor
         endfor
      endif
   endfor

;; Derive zigzag parameters
   my_multiplot, /reset
   ind_shift = dindgen(ishift_max-ishift_min+1) + ishift_min
   wind, 1, 1, /free, xs=1200
   my_multiplot, 2, 1, pp, pp1
   for lambda=lambda_min, lambda_max do begin
      w1 = where( kidpar.array eq lambda and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         xx = dindgen(100)/99.*(ishift_max-ishift_min+1) + ishift_min

         dist_az = abs( xc_res[*,lambda-1,0,0] - xc_res[*,lambda-1,0,1])
         dist_el = abs( xc_res[*,lambda-1,1,0] - xc_res[*,lambda-1,1,1])

         fit = poly_fit( ind_shift, dist_az, 2)
         yfit_az = fit[0] + fit[1]*xx + fit[2]*xx^2
         optimal_shift_az = -fit[1]/(2.d0*fit[2])
         retard_az    = round( !nika.retard-optimal_shift_az)
         ptg_shift_az = !nika.ptg_shift - (!nika.retard-optimal_shift_az - retard_az)

         fit = poly_fit( ind_shift, dist_el, 2)
         yfit_el = fit[0] + fit[1]*xx + fit[2]*xx^2
         optimal_shift_el = -fit[1]/(2.d0*fit[2])
         retard_el    = round( !nika.retard-optimal_shift_el)
         ptg_shift_el = !nika.ptg_shift - (!nika.retard-optimal_shift_el - retard_el)

         yra = minmax( [dist_az, dist_el])
         yra = yra + [-1,1]*0.1*(max(yra)-min(yra))
         plot, minmax(ind_shift), yra, /xs, /ys, yrange=yra, /nodata, position=pp[lambda-1,0,*], /noerase
         oplot, ind_shift, dist_az, psym=8, col=250
         oplot, xx, yfit_az, col=250
         oplot, ind_shift, dist_el, psym=8, col=70
         oplot, xx, yfit_el, col=70
         legendastro, strtrim(lambda,2)+"mm", /right, box=0, chars=1.5
         legendastro, ['Opt shift az '+num2string(optimal_shift_az), $
                       'Opt shift el '+num2string(optimal_shift_el), $
                       "", $
                       "retard, ptg_shift (az): "+num2string(retard_az)+", "+num2string(ptg_shift_az), $
                       "retard, ptg_shift (el): "+num2string(retard_el)+", "+num2string(ptg_shift_el)], $
                      textcol=[250,70,0,250,70], box=0
      endif
   endfor
endif


;; Print summary
print, ""
for i=0, 1 do print, "*****************************"
print, "      POINTING results"
for lambda=lambda_min, lambda_max do begin
   print, "    "+box[lambda-1]+" "+strtrim(lambda,2)+"mm, Delta az = "+$
          string( offsets[lambda-1,0],format='(F10.1)')+$
          ", Delta el = "+string( offsets[lambda-1,1],format='(F10.1)')
endfor
print, ""
print, "-------------------------------------------------------------------"

;; Derive the equivalent Nasmyth offset (TBC)
for lambda=lambda_min, lambda_max do begin
   azel2nasm, el_deg_avg*!dtor, -offsetmap[lambda-1,0], -offsetmap[lambda-1,1], ofs_x, ofs_y
   print, "    "+box[lambda-1]+" "+strtrim(lambda,2)+ $
          "mm, : Equiv set Nasmyth offset: ", string(ofs_x+pako_str.nas_offset_x,format='(F10.1)'), ", ",  $
          string(ofs_y+pako_str.nas_offset_y, format='(F10.1)')
endfor

;; ;; Instead of putting the source at the center of the coordinates, put it on the
;; ;; reference pixel
;; for lambda=lambda_min, lambda_max do begin
;; 
;;    ;; to place the source at (0,0) in coordinates
;;    delta_az = -offsetmap[lambda-1, 0]
;;    delta_el = -offsetmap[lambda-1, 1]
;; 
;;    ;; (az,el) offsets of the ref pixel
;;    if lambda eq 1 then begin
;;       ikid = where( kidpar.numdet eq !nika.numdet_ref_1mm)
;;    endif else begin
;;       ikid = where( kidpar.numdet eq !nika.numdet_ref_2mm)
;;    endelse
;;    ;; do not take the first subscan in case of a tuning at start
;;    w2         = where( data.subscan eq 2)
;;    el_deg_avg = avg( data[w2].el)*!radeg
;;    nika_nasmyth2azel, kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
;;                       0.0, 0.0, el_deg_avg, daz, del, $
;;                       nas_x_ref=kidpar[ikid_ref].nas_center_X, nas_y_ref=kidpar[ikid_ref].nas_center_Y
;; 
;;    ;; to place the source on the ref detector
;;    delta_az = -delta_az + daz
;;    delta_el = -delta_el + del
;; 
;;    ;; Rotate from az,el to Nasmyth and add current Nasmyth offset
;;    azel2nasm, el_deg_avg*!dtor, delta_az, delta_el, ofs_x, ofs_y
;;    print, "    "+box[lambda-1]+" "+strtrim(lambda,2)+ $
;;           "mm, : Equiv set Nasmyth offset: ", string(ofs_x+pako_str.nas_offset_x,format='(F10.1)'), ", ",  $
;;           string(ofs_y+pako_str.nas_offset_y, format='(F10.1)')
;; endfor

print, ""
print, "-------------------------------------------------------------------"
print, "Reference detectors: "+strtrim(numdet_ref[0],2)+" (1mm), "+strtrim(numdet_ref[1],2)+" (2mm)"
print, ""
print, "Closest kid to the source (1mm): ", closest_kid[0]
print, "Closest kid to the source (2mm): ", closest_kid[1]
print, ""
print, "-------------------------------------------------------"
for lambda=lambda_min, lambda_max do begin
   set_ptg = offsets[lambda-1,*]+[pcor_az,pcor_el]
   print, "    "+box[lambda-1]+" "+strtrim(lambda,2)+ $
          "mm, : (Timeline) (for PAKO) SET POINTING ", string(set_ptg[0],format='(F10.1)'), ", ",  $
          string(set_ptg[1], format='(F10.1)')
endfor
print, ""
print, "-------------------------------------------------------"
;; Don't forget to switch the sign of offset map to have consistent instructions here
p=0
for lambda=lambda_min, lambda_max do begin
   cmd = "SET POINTING "+strtrim( string(-offsetmap[lambda-1, 0]+pcor_az,format="(F5.1)"),2)+$
         " "+strtrim( string(-offsetmap[lambda-1, 1]+pcor_el,format="(F5.1)"),2)

   print, "    "+box[lambda-1]+" "+strtrim(lambda,2)+ $ 
          "mm, : (MAP) (for PAKO) SET POINTING ", string(-offsetmap[lambda-1, 0]+pcor_az,format='(F10.1)'), ", ",  $
          string(-offsetmap[lambda-1, 1]+pcor_el, format='(F10.1)')
   if lambda eq 2 then begin
      log_info.result_name[p]    = cmd
      log_info.result_value[p]   = !undef
   endif
;   log_info.result_name[p+1]  = "set ptg el "+strtrim(lambda,2)+"mm"
;   log_info.result_value[p+1] = -offsetmap[lambda-1, 1]+pcor_el
;   p +=2
endfor
print, ""
print, "-------------------------------------------------------"

;; Create a html page with plots from this scan
save, file=output_dir+"/log_info.save", log_info
nika_logbook_sub, scan_num, day

;; Update logbook
;;nika_logbook, day

offsets1 = reform(offsets[0,*])
offsets2 = reform(offsets[1,*])

nika_pipe_measure_atmo, param, data, kidpar, /noplot
save, file=output_dir+"/param.save", param

exit:
end



