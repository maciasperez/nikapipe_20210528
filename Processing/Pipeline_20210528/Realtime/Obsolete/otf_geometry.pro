
;; Quickly outputs the beam map and compares it the the reference geometry

pro otf_geometry, day_in, scan_num, RF=RF, noskydip=noskydip, $
                  sn_min=sn_min, sn_max=sn_max, $
                  nopng=nopng, ps=ps, param=param, polar=polar, $
                  one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
                  output_kidpar_nickname=output_kidpar_nickname, $
                  flux_1mm=flux_1mm, flux_2mm=flux_2mm, $
                  no_acq_flag=no_acq_flag, offsets_reset=offsets_reset, source=source, slow=slow, force=force, $
                  online=online;, imbfits=imbfits, antimb = antimb


imbfits = 1
antimb  = 1

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " otf_geometry, day_in, scan_num, RF=RF, noskydip=noskydip, $"
   print, "               sn_min=sn_min, sn_max=sn_max, $"
   print, "               nopng=nopng, ps=ps, param=param, polar=polar, $"
   print, "               one_mm_only=one_mm_only, two_mm_only=two_mm_only, $"
   print, "               output_kidpar_nickname=output_kidpar_nickname, $"
   print, "               flux_1mm=flux_1mm, flux_2mm=flux_2mm, $"
   print, "               no_acq_flag=no_acq_flag, offsets_reset=offsets_reset, source=source, slow=slow, force=force, $"
   print, "               online=online, imbfits=imbfits"
   return
endif

;; Ensure correct format for "day"
t = size( day_in, /type)
if t eq 7 then day = strtrim(day_in,2) else day = string( day_in, format="(I8.8)")

pf  = 1 - keyword_set(RF)
png = 1 - keyword_set(nopng)

lambda_min = 1
lambda_max = 2
if keyword_set(one_mm_only) then lambda_max = 1
if keyword_set(two_mm_only) then lambda_min = 2

if not keyword_set(param) then begin
   ;; Init param to be used in pipeline modules
   nika_pipe_default_param, scan_num, day, param
   param.map.size_ra                = 400.
   param.map.size_dec               = 400.
   param.map.reso                   = 4.
   param.decor.method               = 'COMMON_MODE_KIDS_OUT'
   param.decor.iq_plane.apply       = 'no'
   param.decor.common_mode.d_min    = 55.0
   param.w8.dist_off_source         = 60.0
   param.zero_level.dist_off_source = 60.0
endif

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+output_dir
param.output_dir = output_dir

;; if not keyword_set(source) then begin
;;    parse_pako, scan_num, day, pako_str
;;    param.source    = pako_str.source
;; endif else begin
;;    param.source = source
;; endelse

xml     = 1 ; default
if keyword_set(online) then begin
   xml = 0
   param.source = strtrim(source,2)
endif

if keyword_set(imbfits) then begin
   xml = 0

   nika_find_raw_data_file, scan_num, day, file, imb_fits_file, /silent
   imbHeader = HEADFITS( imb_fits_file,EXTEN='IMBF-scan')
   param.source = SXPAR(imbHeader, 'OBJECT')
endif

if xml eq 1 then begin
   parse_pako, scan_num, day, pako_str
   param.source = pako_str.source
endif

param.source = strtrim( param.source,2)

param.name4file = day+"s"+strtrim(scan_num,2)
param.version   = "v1"

;; Get data
if keyword_set(polar) then ext_params='c_position c_synchro' else delvarx, ext_params
nika_pipe_getdata, param, data, kidpar, pf=pf, ext_params=ext_params, silent=silent, $
                   one_mm_only=one_mm_only, two_mm_only=two_mm_only, no_acq_flag=no_acq_flag
kidpar_ref = kidpar

;; Discard tunings and unreliable sections of data
if not keyword_set(no_acq_flag) then nika_pipe_valid_scan, param, data, kidpar

;; Flag saturated, out of resonance kids etc...
if not keyword_set(force) then nika_pipe_outofres, param, data, kidpar, /bypass

; Replace bad pointing data
if keyword_set( imbfits) and keyword_set( antimb) then begin
  nika_pipe_antenna2pointing, data, imb_fits_file
                                ; in case of missing pointing data paralactic
                                ; angle is bad, replace it by the last known
                                ; value
  u = where( data.paral eq 0., nu)
  v = where( data.paral ne 0., nv)
  if nu ne 0 then data[u].paral = mean( data[v].paral)

  junk = mrdfits(imb_fits_file, 2, h)
  param.projection.type = sxpar(h, "systemof")

endif

;; Account for telescope gain dependence on elevation
nika_pipe_gain_cor, param, data, kidpar

if keyword_set(polar) then begin
   ;; Determine HWP rotation speed
   get_hwp_rot_freq, data, rot_freq_hz
   param.polar.nu_rot_hwp = rot_freq_hz
   ;; Determine angle
   nika_pipe_get_hwp_angle, param, data, kidpar
   ;; Subtract template
   nika_pipe_hwp_rm, param, kidpar, data, fit
endif

if not keyword_set(sn_min) then sn_min = 0
if not keyword_set(sn_max) then sn_max = n_elements(data)-1
data = data[sn_min:sn_max]

;; Additional sanity check on subscan value
w = where( data.subscan ge 1, nw)
data = data[w]
nsn = n_elements(data)

;; Deglitch
nika_pipe_deglitch, param, data, kidpar

;; Calibration
nika_pipe_opacity, param, data, kidpar, noskydip=noskydip


data_hz = data                  ; keep for calibration later on

if keyword_set(offsets_reset) then begin
   ;; Do not take the offsets already present in kidpar, keep only the selection
   ;; based on kidpar.type and recompute all the offsets from scratch

   data_jy = temporary(data)    ; init
   nika_pipe_calib, param, data_jy, kidpar, noskydip=noskydip

   ;; Quick median filter as first iteration to locate the source and then feed
   ;; common_modes_kids_out
   data2speed, data_hz, median_speed
   param1 = param
   param1.decor.method = 'median_simple'
   param1.decor.median.width = long( 10.*max(!nika.fwhm_nom)/median_speed*!nika.f_sampling)
   nika_pipe_decor, param1, data_jy, kidpar
   nika_pipe_w8toi, param1, data_jy, kidpar

   ;; Project in Nasmyth coordinates
   azel2nasm, data_hz.el, data_hz.ofs_az, data_hz.ofs_el, x_1, y_1
   xra1  = minmax(x_1)
   yra1  = minmax(y_1)
   xyra2xymaps, xra1, yra1, param.map.reso, xmap1, ymap1
   get_bolo_maps, data_hz.rf_didq, x_1, y_1, param.map.reso, xmap1, ymap1, kidpar, map_list

   ;; Derive beam parameters
   beam_guess, map_list, xmap1, ymap1, kidpar, $
               x_peaks, y_peaks, a_peaks, sigma_x, sigma_y, $
               beam_list, theta, /noplot

   ;; Re-center beams on the reference kid.
   ikid_ref = where( kidpar.type eq 1 and kidpar.nas_x eq 0 and kidpar.nas_y eq 0, nkid_ref)
   if nkid_ref eq 0 then begin
      message, /info, ""
      print, "No ref kid ?!"
      stop
   endif
   w1 = where( kidpar.type eq 1, nw1)
   x_peaks[w1] -= x_peaks[ikid_ref[0]]
   y_peaks[w1] -= y_peaks[ikid_ref[0]]
   kidpar[w1].nas_x = x_peaks[w1]
   kidpar[w1].nas_y = y_peaks[w1]
endif

box = ['A', 'B']
phi = dindgen( 200)/199*2*!dpi

if keyword_set(slow) then begin
   ;; Locate source in Radec for common_modes_kid_out
   nika_pipe_map, param1, data_jy, kidpar, maps, $
                  /undef_var2nan, one_mm_only=one_mm_only, $
                  two_mm_only=two_mm_only, xmap=xmap, ymap=ymap

   wind, 1, 1, /free, xs=1200
   my_multiplot, 2, 1, pp, pp1
   offsets = dblarr(2,2)
   for lambda=lambda_min, lambda_max do begin
      junk = execute( "map = maps."+box[lambda-1])

      w1 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw1)
      fwhm = median( kidpar[w1].fwhm)
      nika_map_noise_estim, param1, map, xmap, ymap, fwhm, flux, sigma_flux, sigma_bg, map_conv, fit_params

      xtitle='RA'
      ytitle='DEC'

      xx  = fit_params[2]*cos(phi)
      yy  = fit_params[3]*sin(phi)
      xx1 = cos(fit_params[6])*xx - sin(fit_params[6])*yy
      yy1 = sin(fit_params[6])*xx + cos(fit_params[6])*yy
      
      !mamdlib.coltable = 1
      imview, map.jy, xmap=xmap, ymap=ymap, /noerase, nsigma=5, $
              title='1st iter. '+param.day+"s"+strtrim(param.scan_num,2)+" "+strtrim(lambda,2)+'mm', $
              xtitle=xtitle, ytitle=ytitle, position=pp1[lambda-1,*]
      loadct, 39
      oplot, fit_params[4] + xx1, fit_params[5] + yy1, col=250
      oplot, [fit_params[4]], [fit_params[5]], psym=1, col=250
      legendastro, ['!7D!3x '+num2string(fit_params[4]), $
                    '!7D!3y '+num2string(fit_params[5])], $
                   textcol=255, box=0

      offsets[lambda-1,0] = fit_params[4]
      offsets[lambda-1,1] = fit_params[5]
   endfor

   offset_x = avg( offsets[*,0]) ; default
   offset_y = avg( offsets[*,1]) ; default
   if keyword_set(one_mm_only) then begin
      offset_x = offsets[0,0]
      offset_y = offsets[0,1]
   endif
   if keyword_set(two_mm_only) then begin
      offset_x = offsets[1,0]
      offset_y = offsets[1,1]
   endif

endif else begin
   ;; Assume that the source is at the center
   data     = data_hz
   offset_x = 0.d0
   offset_y = 0.d0
endelse

;; Final decorelation on original data
nika_pipe_cmkidout, param, data_hz, kidpar, pos=[offset_x,offset_y]

;; Project in Nasmyth coordinates
azel2nasm, data_hz.el, data_hz.ofs_az, data_hz.ofs_el, x_1, y_1
xra1  = minmax(x_1)
yra1  = minmax(y_1)
xyra2xymaps, xra1, yra1, param.map.reso, xmap1, ymap1
get_bolo_maps, data_hz.rf_didq, x_1, y_1, param.map.reso, xmap1, ymap1, kidpar, map_list

;; Derive beam parameters
beam_guess, map_list, xmap1, ymap1, kidpar, $
            x_peaks, y_peaks, a_peaks, sigma_x, sigma_y, $
            beam_list, theta, /noplot

;; Re-center beams on the reference kid.
ikid_ref = where( kidpar.type eq 1 and kidpar.nas_x eq 0 and kidpar.nas_y eq 0, nkid_ref)
if nkid_ref eq 0 then begin
   message, /info, ""
   print, "No ref kid ?!"
   stop
endif
w1 = where( kidpar.type eq 1)
x_peaks[w1] -= x_peaks[ikid_ref[0]]
y_peaks[w1] -= y_peaks[ikid_ref[0]]

;; Update kidpar here for nika_pipe_calib and so on
for lambda=1, 2 do begin
   ww = where( kidpar.array eq lambda, nww)
   kidpar[ww].nas_x          = x_peaks[ww]
   kidpar[ww].nas_y          = y_peaks[ww]
   kidpar[ww].x_peak_nasmyth = x_peaks[ww]
   kidpar[ww].y_peak_nasmyth = y_peaks[ww]
   kidpar[ww].a_peak         = a_peaks[ww]
   kidpar[ww].sigma_x        = sigma_x[ww]
   kidpar[ww].sigma_y        = sigma_y[ww]
   kidpar[ww].fwhm_x         = sigma_x[ww]/!fwhm2sigma
   kidpar[ww].fwhm_y         = sigma_y[ww]/!fwhm2sigma
   kidpar[ww].fwhm           = sqrt( sigma_x[ww]*sigma_y[ww])/!fwhm2sigma
   kidpar[ww].theta          = theta[ww]
endfor

;; Fit peak amplitude with the fixed nominal FWHM
for ikid=0, n_elements(kidpar)-1 do begin
   if kidpar[ikid].type eq 1 then begin
      if kidpar[ikid].array eq 1 then sigma_gauss = !nika.fwhm_nom[0]*!fwhm2sigma else sigma_gauss = !nika.fwhm_nom[1]*!fwhm2sigma
      d                 = sqrt( (xmap1-x_peaks[ikid])^2 + (ymap1-y_peaks[ikid])^2)
      gauss_w8          = exp( -d^2/(2.d0*sigma_gauss^2))
      junk              = reform( map_list[ikid,*,*])
      w                 = where( finite(junk) eq 1)
      kidpar[ikid].flux = total( junk[w] *gauss_w8[w])/total(gauss_w8[w]^2)
   endif
endfor

;; Absolute calibration
nika_pipe_planet_calib, param, data_hz, kidpar, flux_1mm=flux_1mm, flux_2mm=flux_2mm

if keyword_set(output_kidpar_nickname) then begin
   for lambda=1, 2 do begin
      ww = where( kidpar.array eq lambda, nww)
      if nww ne 0 then nika_write_kidpar, kidpar[ww], output_kidpar_nickname+"_"+strtrim(lambda,2)+"mm.fits"
   endfor
endif

;; Plot
wind, 1, 1, /free, xs=1200, ys=900
outplot, file=output_dir+"/plot", png=png, ps=ps
my_multiplot, 2, 2, gpp, gpp1, /rev

for lambda=lambda_min, lambda_max do begin
   junk = execute( "kidfile = param.kid_file."+box[lambda-1]+"[0]")
   ;my_multiplot, 3, 1, pp, pp1, xmin=gpp[lambda-1,0,0], xmax=gpp[lambda-1,0,2], $
   ;              ymin=gpp[lambda-1,1,1], ymax=gpp[lambda-1,1,3]
   my_multiplot, 1, 3, pp, pp1, xmin=gpp[lambda-1,0,0], xmax=gpp[lambda-1,0,2], $
                 ymin=gpp[lambda-1,1,1], ymax=gpp[lambda-1,1,3], /rev, gap_x=0.02, gap_y=0.02

   w1 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw1)

   xra = minmax( kidpar[w1].nas_x)
   xra = xra + [-0.2,0.2]*(xra[1]-xra[0])
   yra = minmax( kidpar[w1].nas_y)
   yra = yra + [-0.2,0.2]*(yra[1]-yra[0])
   
   ;; Reference kidpar
   plot, kidpar[w1].nas_x, kidpar_ref[w1].nas_y, psym=1, /iso, $
         position=gpp[lambda-1,0,*], /noerase, xra=xra, yra=yra, /xs, /ys
   for i=0, nw1-1 do begin
      ikid = w1[i]
      xx1  = kidpar_ref[ikid].sigma_x*cos(phi)*0.5 ; 0.5 to have diameter=sigma, not radius
      yy1  = kidpar_ref[ikid].sigma_y*sin(phi)*0.5 ; 0.5 to have diameter=sigma, not radius
      x1   =  cos(kidpar_ref[ikid].theta)*xx1 - sin(kidpar_ref[ikid].theta)*yy1
      y1   =  sin(kidpar_ref[ikid].theta)*xx1 + cos(kidpar_ref[ikid].theta)*yy1
      oplot, kidpar_ref[ikid].nas_x+x1, kidpar_ref[ikid].nas_y+y1
   endfor

   ;; Current beam parameters
   oplot, x_peaks[w1], y_peaks[w1], psym=1, col=250
   for i=0, nw1-1 do begin
      ikid = w1[i]
      xx1  = sigma_x[ikid]*cos(phi)*0.5
      yy1  = sigma_y[ikid]*sin(phi)*0.5
      x1   =  cos(theta[ikid])*xx1 - sin(theta[ikid])*yy1
      y1   =  sin(theta[ikid])*xx1 + cos(theta[ikid])*yy1
      oplot, x_peaks[ikid]+x1, y_peaks[ikid]+y1, col=250
   endfor
   legendastro, [file_basename(kidfile), param.day+"s"+strtrim(param.scan_num,2)], textcol=[0,250], box=0


   dist = sqrt( (x_peaks[w1]-kidpar_ref[w1].nas_x)^2 + (y_peaks[w1]-kidpar_ref[w1].nas_y)^2)
   ;; a la Xavier, until np_histo can deal with identical values ;-)
   if min(dist) eq max(dist) then dist += randomn( seed, nw1)*1e-3

;;    np_histo, dist, $
;;              position=pp1[0,*], /noerase, fcol=70
;;    legendastro, [strtrim(lambda,2)+"mm", $
;;                  'Centroids dist', $
;;                  'median '+num2string(median(dist))], box=0
;; 
;;    struct = {a:kidpar_ref[w1].fwhm, $
;;              b:kidpar[    w1].fwhm}
;;    np_histo, struct, position=pp1[1,*], /noerase, colorplot=[0, 70]
;;    legendastro, [strtrim(lambda,2)+"mm", $
;;                  'FWHM'], box=0
;; 
;;    struct = {a:kidpar_ref[w1].calib_fix_fwhm, $
;;              b:kidpar[    w1].calib_fix_fwhm}
;;    np_histo, struct, position=pp1[2,*], /noerase, colorplot=[0, 70]
;;    legendastro, [strtrim(lambda,2)+"mm", $
;;                  'Calib (fix FWHM)'], box=0

   plot, dist, /xs, /ys, position=pp1[0,*], /noerase
   legendastro, ['Centroids dist. (arcsec)'], box=0

   plot, kidpar[w1].fwhm - kidpar_ref[w1].fwhm, /xs, /ys, position=pp1[1,*], /noerase
   legendastro, ['FWHM diff (current-ref)'], box=0

   plot, kidpar[w1].calib_fix_fwhm - kidpar_ref[w1].calib_fix_fwhm, /xs, /ys, position=pp1[2,*], /noerase
   legendastro, ['Calib. diff (fix fwhm) current - ref'], box=0
   if param.source eq "" then legendastro, "No source name found => Incorrect absolute calibration"


endfor
outplot, /close

;; Get useful information for the logbook
nika_get_log_info, scan_num, day, data_hz, log_info, kidpar=kidpar
log_info.scan_type = 'OTF_geometry' ; default
log_info.source    = param.source
if keyword_set(polar) then log_info.scan_type = "OTF_geometry_polar"

;; Create a html page with plots from this scan
save, file=output_dir+"/log_info.save", log_info
nika_logbook_sub, scan_num, day

;; Monitor atmosphere
nika_pipe_measure_atmo, param, data, kidpar, /noplot
save, file=output_dir+"/param.save", param

;;;; Monitor kid noise (calibrated)
;;nika_pipe_calib,             param, data_hz, kidpar, noskydip=noskydip
;;nika_pipe_quick_noise_estim, param, data_hz, kidpar, /mjy


end
