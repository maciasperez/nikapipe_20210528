
;; Trying to have a single routine to make maps and derive associated
;; parameters, polar or not, otf or lissajou...

pro rta_map, day, scan_num, maps, bg_rms, png=png, ps=ps, param=param, $
             xmap=xmap, ymap=ymap, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
             noskydip=noskydip, RF=RF, lissajous=lissajous, $
             azel=azel, diffuse=diffuse, slow=slow, $
             sn_min=sn_min, sn_max=sn_max, k_noise=k_noise, $
             convolve=convolve, educated=educated, focal_plane=focal_plane, $
             map_t_fit_params=map_t_fit_params, err_map_t_fit_params=err_map_t_fit_params, check=check, $
             calibrate=calibrate, flux_1mm=flux_1mm, flux_2mm=flux_2mm, no_acq_flag=no_acq_flag, $
             online=online, imbfits=imbfits, p2cor=p2cor, p7cor=p7cor, force=force, $
             antimb = antimb, jump = jump, method =  method, xsize = xsize, ysize = ysize

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " rta_map, day, scan_num, maps, bg_rms, png=png, ps=ps, param=param, $"
   print, "             xmap=xmap, ymap=ymap, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $"
   print, "             noskydip=noskydip, RF=RF, lissajous=lissajous, $"
   print, "             azel=azel, diffuse=diffuse, slow=slow, $"
   print, "             sn_min=sn_min, sn_max=sn_max, k_noise=k_noise, $"
   print, "             convolve=convolve, educated=educated, focal_plane=focal_plane, $"
   print, "             map_t_fit_params=map_t_fit_params, err_map_t_fit_params=err_map_t_fit_params, check=check, $"
   print, "             calibrate=calibrate, flux_1mm=flux_1mm, flux_2mm=flux_2mm, no_acq_flag=no_acq_flag, $"
   print, "             online=online, imbfits=imbfits, p2cor=p2cor, p7cor=p7cor, force=force, antimb = antimb,jump=jump"
   return
endif

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

;; quick sanity checks
if keyword_set(calibrate) and keyword_set(noskydip) then begin
   message, /info, "If you ask for /calibrate, you must not set /noskydip"
   return
endif

;;if keyword_set(diffuse) and keyword_set(fast) then begin
;;   message, /info, "Please do not set /diffuse together with /fast"
;;   return
;;endif

if keyword_set(diffuse) and keyword_set(slow) then begin
   message, /info, "Please do not set /slow together with /diffuse"
   return
endif

if keyword_set(online) and keyword_set(imbfits) then begin
   message, /info, "Please do not set /online and /imbfits at the same time"
   return
endif

if not keyword_set(k_noise) then k_noise = 0.05 ; S/N max = 20

;; Init param to be used in pipeline modules
if not keyword_set(param) then begin
   nika_pipe_default_param, scan_num, day, param
   param.map.size_ra                = 300.
   param.map.size_dec               = 300.

   if keyword_set(xsize) then param.map.size_ra  = xsize
   if keyword_set(ysize) then param.map.size_dec = ysize


   param.map.reso                   = 4.
   if keyword_set(diffuse) then begin
      param.decor.method = "COMMON_MODE"
   endif else begin
      param.decor.method = 'COMMON_MODE_KIDS_OUT'
   endelse
   param.decor.iq_plane.apply       = 'no'
   param.decor.common_mode.d_min    = 30 ; 40. ; 55.0
   param.w8.dist_off_source         = 40.0
   param.zero_level.dist_off_source = 60.0
endif

;;***************
;;***************
if keyword_set(method) then param.decor.method = method
;;***************
;;***************

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+output_dir
param.output_dir = output_dir

lambda_min = 1
lambda_max = 2
if keyword_set(one_mm_only) then lambda_max = 1
if keyword_set(two_mm_only) then lambda_min = 2

;; Extract relevant modules from nika_pipe_launch to keep results alive and
;; prevent from writing fits and .ps files (problems with their size ?)
  
;; Guess if need to reset coordinates or not for each scan in case not provided
if ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0 eq 0 $
   and ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2]) eq 0 then $
      reset_coord_pointing = 'yes' else reset_coord_pointing = 'no'
if ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 eq 0 $
   and ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) eq 0 then $
      reset_coord_source = 'yes' else reset_coord_source = 'no'

if reset_coord_pointing eq 'yes'  then param.coord_pointing.ra  *= 0
if reset_coord_pointing eq 'yes'  then param.coord_pointing.dec *= 0
if reset_coord_source   eq 'yes'  then param.coord_source.ra    *= 0
if reset_coord_source   eq 'yes'  then param.coord_source.dec   *= 0

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
;;   if not keyword_set(focusz) then begin
;;      message, /info, "Please set focusz as an input keyword if you're in /online mode"
;;      message, /info, "If your want to put focusz = zero then focusz=1e-10"
;;      return
;;   endif

   init_pako_str, pako_str
   pako_str.p2cor = p2cor
   pako_str.p7cor = p7cor
;;   pako_str.focusz = focusz
   pako_str.obs_type = "map"
endif

if keyword_set(imbfits) then begin
   xml = 0
   init_pako_str, pako_str
   pako_str.obs_type = "pointing"

   nika_find_raw_data_file, scan_num, day, file, imb_fits_file, /silent

   test  = file_test( imb_fits_file, /dir) ; is a directory
   test2 = file_test( imb_fits_file)       ; file/dir exists

   antexist = (test eq 0) and (test2 eq 1)
   if antexist then begin 
      imbHeader = HEADFITS( imb_fits_file,EXTEN='IMBF-scan')
      pako_str.p2cor = SXPAR(imbHeader, 'P2COR')/!pi*180.d0*3600.d0
      pako_str.p7cor = SXPAR(imbHeader, 'P7COR')/!pi*180.d0*3600.d0
      r = mrdfits( imb_fits_file, 1)
      pako_str.NAS_OFFSET_X = r.XOFFSET/!arcsec2rad
      pako_str.NAS_OFFSET_Y = r.YOFFSET/!arcsec2rad
      a = mrdfits( imb_fits_file,0,hdr,/sil)
      pako_str.obs_type = sxpar( hdr,'OBSTYPE',/silent)
      pako_str.source = sxpar(imbheader, 'OBJECT')
      ;; iext = 1
      ;; status = 0
      ;; WHILE status EQ 0 AND  iext LT 100 DO BEGIN
      ;;    aux = mrdfits(  strtrim( imb_fits_file), iext, haux, status = status, /silent)
      ;;    extname = sxpar( haux, 'EXTNAME')
      ;;    if strupcase(extname) eq 'IMBF-SCAN' then begin
      ;;       pako_str.focusz = sxpar( haux, 'FOCUSZ')
      ;;       print, "iext, focusz: ", iext, focusz
      ;;    endif
      ;;    iext = iext + 1
      ;; endwhile

      
   endif else begin
      message, /info, "the AntennaIMBfits file does not exist"
      return
   endelse
endif

if xml eq 1 then parse_pako, scan_num, day, pako_str

param.source    = strtrim( pako_str.source, 2)
param.name4file = day+"s"+strtrim(scan_num,2)
param.version   = "v1"
nickname        = param.source+"  "+param.day+"s"+strtrim(param.scan_num,2)

pf = 1
if keyword_set(RF) then pf=0
nika_pipe_getdata, param, data, kidpar, pf=pf, ext_params=ext_params, /silent, $
                   one_mm_only=one_mm_only, two_mm_only=two_mm_only, no_acq_flag=no_acq_flag, $
                   jump = jump,  list_data = list_data

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

  junk = mrdfits(imb_fits_file, 2, h)
  param.projection.type = sxpar(h, "systemof")

endif

;; Flag saturated, out of resonance kids etc...
if not keyword_set(force) then nika_pipe_outofres, param, data, kidpar, /bypass
;;nika_pipe_outofres, param, data, kidpar, bypass = keyword_set(force)

;; Account for telescope gain dependence on elevation
nika_pipe_gain_cor, param, data, kidpar

if not keyword_set(sn_min) then sn_min = 0
if not keyword_set(sn_max) then sn_max = n_elements(data)-1
data = data[sn_min:sn_max]

;; Check if we are in "total power" or "polarization" mode
;; nika_pipe_get_hwp_angle, param, data, kidpar
;; synchro_med = median( data.c_synchro)
polar = 0 ; default
;;if max( abs(data.c_synchro - median( data.c_synchro))) gt 1e5 then polar = 1

;; Additional sanity check on subscan value and try to take margin
;; with tunings

if strupcase(pako_str.obs_type) eq "LISSAJOUS" or keyword_set(lissajous) then begin
   pako_str.obs_type = "lissajous" ; fill if /lissajous

   nika_pipe_lissajou_select, param, data, kidpar;, /show

   ;; values out of sections have a w8=0, but we keep them for common
   ;; mode estimationt.
   ;; We reject samples outside subscans to avoid tunings and other problems
   wkeep = where( data.subscan ge 1, nw)
endif else begin
   ;;w = where( data.subscan ge 1 and data.subscan lt
   ;;max(data.subscan), nw)
   wkeep = where( data.subscan ge 1, nw) ;  and data.subscan lt max(data.subscan), nw)
endelse

nika_pipe_speedflag2, param, data

;wkeep =  wkeep[50:*]

;; Quicklook at a raw timeline
nsubscans =  max(data.subscan)-min(data.subscan)+1
make_ct, nsubscans, ct
nsn = n_elements(data)
index = lindgen(nsn)
wind, 1, 1, /free, xs=1000, ys=700
!p.multi=[0,1,2]
xra = minmax(index)

w = where( kidpar.numdet eq !nika.numdet_ref_1mm, nw)
if nw ne 0 then begin
   ikid = w[0]
endif else begin
   w = where( kidpar.numdet eq !nika.numdet_ref_2mm, nw)
   if nw eq 0 then begin
      message, /info, "No reference kid available neither at 1mm nor at 2mm ?!"
      message, /info, "I'll take the first valid one"
      ikid = min( where( kidpar.type eq 1))
   endif else begin
      ikid = w[0]
   endelse
endelse

subscan_plot =  data.subscan/max(data.subscan)*max(data.rf_didq[ikid])

plot, index, data.rf_didq[ikid], xtitle='Sample Number', ytitle='Flux', title=nickname+' Raw timeline', $
      xra=xra, /xs
for i=(min(data.subscan)>1), max(data.subscan) do begin
   w = where( data.subscan eq i, nw)
   oplot, index[w], data[w].rf_didq[ikid], col=ct[i-min(data.subscan)], psym=1
endfor
data.a_masq = double( data.a_masq ne 0)
oplot, index, data.a_masq*max(data.rf_didq[ikid]), col=70, thick=2
data.b_masq = double( data.b_masq ne 0)
oplot, index, data.b_masq*max(data.rf_didq[ikid]), col=250
oplot, index, subscan_plot,  line = 2,  thick = 2, col = 200
for i = min(data.subscan),  max(data.subscan) do begin
   m =  min(where(data.subscan eq i))
   xyouts,  index[m], subscan_plot[m], "Subscan = "+strtrim( long(i), 2), chars = 1.5
endfor
legendastro, "Subscan "+strtrim( indgen(nsubscans)+long(min(data.subscan)), 2), col=ct, box=0, line=0, chars=0.6
legendastro, ['a_masq', 'b_masq'], col=[70,250], line=0, /bottom, box=0

;ww = where( data[wkeep].w8[0] ne 0 and data[wkeep].flag[0] eq 0)
plot, index[wkeep], data[wkeep].rf_didq[ikid], xtitle='Sample Number', $
      ytitle='Flux [Hz]', title='Kept samples', xra=xra, /xs
;oplot, index[wkeep[ww]], data[wkeep[ww]].rf_didq[ikid], col=250
legendastro, ['Selection on subscans', 'Selection on subscans and flags'], $
             col=[0,250], line=0, box=0
legendastro, [strtrim(kidpar[ikid].array,2)+" mm, Numdet "+strtrim( kidpar[ikid].numdet, 2)], box=0, /right
!p.multi=0
if keyword_set(check) then stop


;; update
data    = data[wkeep]
nsn     = n_elements(data)
index   = lindgen(nsn)
;;w8_proj = data.w8

;;;; Deal with tunings if some remain during subscans
;;tunings = where(data.a_masq ne 0 or data.b_masq ne 0, ntunings)
;;if ntunings ne 0 then begin
;;   message, /info, "Tunings during subscans remain"
;;   stop
;;
;;   tuningsAtEnd = where( (nsn - tunings) lt 1000, tot_tun_atEnd )
;;
;;   if tot_tun_atEnd gt 0 then begin
;;      if (ntunings - tot_tun_atEnd) gt 0 then begin
;;         sn_min = tunings(ntunings - tot_tun_atEnd -1 ) + 20
;;      endif else begin
;;         sn_min = 20
;;      endelse
;;      sn_max = tunings(ntunings - tot_tun_atEnd) - 20
;;   endif else begin
;;      sn_min = tunings(ntunings - 1) + 20
;;      sn_max = nsn - 20
;;   endelse
;;endif

;; Ensure data has an even number of samples to speed up FFT
;; (polarized case)
data                = data[0:2*long(n_elements(data)/2.)-1]
nsn                 = n_elements(data)
param.integ_time[0] = nsn/!nika.f_sampling
nsubscans           =  max(data.subscan)-min(data.subscan)+1
index               = lindgen(nsn)
make_ct, nsubscans, ct

if polar eq 1 then begin
   ;; Determine HWP rotation speed
   get_hwp_rot_freq, data, rot_freq_hz
   param.polar.nu_rot_hwp = rot_freq_hz

   ;; Subtract HWP template
   nika_pipe_hwp_rm, param, kidpar, data, fit
endif

;;------- Correct the pointing from antenna data !!!!!!!!!!!!!! TO BE IMPROVED !!!!!!!!!!!!!!
;nika_pipe_corpointing, param, data, kidpar, simu=simu, azel=azel
     
;; Calibrate the data
nika_pipe_deglitch,          param, data, kidpar
nika_pipe_opacity,           param, data, kidpar, simu=simu, noskydip=noskydip
nika_pipe_calib,             param, data, kidpar, noskydip=noskydip
     
;;------- Flag KIDs that are far from the resonance
;;nika_pipe_outofres, param, data, kidpar

data_copy = data ; for iteration with cmkidout
;; Now that we'll use this routine in pointing_liss, we cannot
;; assume that the source is near the center of the map anymore
;; ==> Need to iterate
source_pos = dblarr(2,2)
box = ['A', 'B']
if keyword_set(diffuse) then begin
   ;; No iteration, only subtract a simple common mode
   iter_min = 0
   iter_max = 0
endif else begin
   ;; Assume the source is point like, at the center and jump directly
   ;; to cmkidout
   source_pos = dblarr(2,2)
   iter_min = 1
   iter_max = 1
   educated = 1
endelse

if keyword_set(slow) then begin
   ;; In case the source may not be in the center (pointing_liss)
   ;; we assume nothing about it's position and first look for it with a
   ;; simple median filter
   iter_min = 0
   iter_max = 1
end

;;------------------------------------------------------------------------
;; Main loop
for iter=iter_min, iter_max do begin

   ;;------------------------------------------------------------------------
   ;; Decorrelation
   if iter eq 0 then begin
      if not keyword_set(diffuse) then begin
         data2speed, data, median_speed
         param.decor.method = 'median_simple'
         param.decor.median.width = long(10.*max(!nika.fwhm_nom)/median_speed*!nika.f_sampling)
      endif

      ;; Decorrelation
      nika_pipe_decor, param, data, kidpar

   endif else begin
      data = data_copy          ; restore unfiltered data

      pos = avg( source_pos, 0)
      if keyword_set(one_mm_only) then pos = reform( source_pos[0,*])
      if keyword_set(two_mm_only) then pos = reform( source_pos[1,*])

      if keyword_set(method) then begin
         nika_pipe_decor,  param,  data,  kidpar
      endif else begin
         param.decor.method = 'COMMON_MODE_KIDS_OUT'
         nika_pipe_cmkidout, param, data, kidpar, baseline, pos=pos
      endelse

   endelse

;;;;-------------------------------
;;   w1 =  where( kidpar.type eq 1 and kidpar.array eq 2,  nw1)
;;   index =  dindgen( n_elements(data))
;;   fit =  linfit( index,  data.el)
;;   y =  data.el-(fit[0]+fit[1]*data.el)
;;   plot,  index, data.rf_didq[w1[25]]
;;   oplot, index, y*1e3, col = 250
;;stop




;stop

   ;;------------------------------------------------------------------------
   ;; Projection

   ;; Get weight TOI

   ;; ;;---------------------------
   ;; w1 =  wherE( kidpar.array eq 2 and kidpar.type eq 1,  nw1)
   ;; make_ct,  nw1, ct
   ;; plot,  data.w8[w1[0]],  yra = minmax(data.w8),  /ys
   ;; for i = 0,  nw1-1 do begin
   ;;    oplot, data.w8[w1[i]],  col = ct[i]
   ;;    cont_plot,  nostop = nostop
   ;; endfor
   ;; stop
   ;; ;;---------------------------

   if polar eq 0 then begin
      nika_pipe_map, param, data, kidpar, maps, azel=azel, astr=astrometry, $
                     /undef_var2nan, one_mm_only=one_mm_only, two_mm_only=two_mm_only, xmap=xmap, ymap=ymap
   endif else begin
      ;; Project (Lock-in)
      param.polar.do_lockin       = 1
      param.polar.lockin_freqhigh = param.polar.nu_rot_hwp * 0.9
      nika_pipe_polar_maps, param, data, kidpar, maps_S0, maps_S1, maps_S2, maps_covar, nhits, $
                            xmap=xmap, ymap=ymap, azel=azel
      
      ;; Create a map structure similar to that output by nika_pipe_map
      ;; in the case of total power
      nx    = n_elements(xmap[*,0])
      ny    = n_elements(xmap[0,*])
      mymap = dblarr(nx,ny)
      str   = {jy:mymap, var:mymap, time:mymap} ;, noise_map:mymap, jy_s1:mymap, jy_s2:mymap}
      maps  = {a:str, b:str}
      
      maps.a.jy   = maps_s0[*,0]
      maps.a.var  = maps_covar[*,0,0]
      maps.a.time = nhits[*,0]/!nika.f_sampling
      
      maps.b.jy   = maps_s0[*,1]
      maps.b.var  = maps_covar[*,1,0]
      maps.b.time = nhits[*,1]/!nika.f_sampling
   endelse

   for lambda=lambda_min, lambda_max do begin
      junk = execute( "map     = maps."+box[lambda-1]+".jy")
      junk = execute( "map_var = maps."+box[lambda-1]+".var")
      fitmap, map, map_var, xmap, ymap, params, covar, educated=educated
      source_pos[lambda-1,0] = params[4]
      source_pos[lambda-1,1] = params[5]
   endfor

endfor

;; Now that data have been decorrelated, monitor the noise
nika_pipe_quick_noise_estim, param, data, kidpar, /mjy

;;==========================================================================
;;==========================================================================
;; Analyse the maps

if (lambda_max-lambda_min) ne 0 then begin
   wind, 1, 1, /free, xs=1200
   my_multiplot, 2, 1, pp, pp1
endif else begin
   wind, 1, 1, /free, /large
   pp1 = transpose([[0.1, 0.1, 0.95, 0.95], [0.1, 0.1, 0.95, 0.95]])
endelse

;; Get useful information for the logbook
nika_get_log_info, scan_num, day, data, log_info, kidpar=kidpar
log_info.source    = pako_str.source
log_info.scan_type = pako_str.obs_type
if polar eq 1 then log_info.scan_type = pako_str.obs_type+"_polar"

box = ['A', 'B']
phi = dindgen( 200)/199*2*!dpi
outplot, file=output_dir+"/plot", png=png, ps=ps;, /transp
p = 0 ; index of results to save in log_info
;; Display
if keyword_set(azel) then begin
   xtitle = 'Azimuth'
   ytitle = 'Elevation'
   dx_leg = "!7D!3az"
   dy_leg = "!7D!3el"
   coord = "Az, El"
endif else begin
   xtitle='RA'
   ytitle='DEC'
   dx_leg = "!7D!3RA"
   dy_leg = "!7D!3Dec"
   coord = "RA, Dec"
endelse
if keyword_set(convolve) then coord = [coord, "Beam convolved"]

closest_kid          = intarr( 2)
offsetmap            = dblarr( 2, 2)
map_t_fit_params     = dblarr( 2, 2)
err_map_t_fit_params = dblarr( 2, 2)
flux_mes             = dblarr( 2)
for lambda=lambda_min, lambda_max do begin
   junk = execute( "map = maps."+box[lambda-1])
   junk = execute( "map_var = maps."+box[lambda-1]+".var")
   
   ;; Point source photometry
   w1 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw1) ;  and finite(kidpar.noise), nw1)
   ;;fwhm = median( kidpar[w1].fwhm)
   fwhm = !nika.fwhm_nom[lambda-1]
   nika_map_noise_estim, param, map, xmap, ymap, fwhm, flux, $
                         sigma_flux, sigma_bg, map_conv, fit_params, bg_rms, $
                         flux_center, sigma_flux_center, output_fit_par_error, educated=educated, k_noise=k_noise
;stop
   ;; store results
   offsetmap[ lambda-1,0] = fit_params[4]
   offsetmap[ lambda-1,1] = fit_params[5]

   ;; Modif, Nico and Barbara, July 23rd, 2014
   ;; flux_mes[  lambda-1]   = flux
   flux_mes[  lambda-1]   = fit_params[1] ; flux

   matrix_surface = nw1 * kidpar[w1[0]].grid_step^2
   scan_surface   = (max(data.ofs_az)-min(data.ofs_az)) * (max(data.ofs_el)-min(data.ofs_el))
   rho            = (matrix_surface/scan_surface) < 1.d0 ; fraction of scan spent on the source
   ndet_per_beam  = fwhm^2/kidpar[w1[0]].grid_step^2
   sensit_toi     = sigma_flux*1000*sqrt(rho*param.integ_time[0])/sqrt(ndet_per_beam)
   sensit_map     = sigma_bg  *1000*sqrt(rho*param.integ_time[0])/sqrt(ndet_per_beam)

   ;; Sensitivity using Remi's formula (At map center)
   d         = sqrt( xmap^2 + ymap^2)
   loc_time  = where( d lt 20.)  ; region where time per pixel is homogeneous
   time_pix  = mean( map.time[loc_time]) * kidpar[w1[0]].grid_step^2/param.map.reso^2
   NEFD      = sigma_bg * sqrt(time_pix) * 1000

   xx  = fit_params[2]*cos(phi)
   yy  = fit_params[3]*sin(phi)
   xx1 =  cos(fit_params[6])*xx + sin(fit_params[6])*yy
   yy1 = -sin(fit_params[6])*xx + cos(fit_params[6])*yy
   
   !mamdlib.coltable = 1
   if keyword_set(convolve) then disp_map = map_conv else disp_map = map.jy

   w = where( map_var gt 0, nw, compl=wcompl, ncompl=nwcompl)
   if nwcompl ne 0 then map_var[wcompl] = !values.d_nan
   var_med = median( map_var[w])
   imrange = [-1,1]*4*stddev( disp_map[where( map_var le var_med and map_var gt 0)])
   imview, disp_map, xmap=xmap, ymap=ymap, /noerase, imrange=imrange, $
           title=nickname+" "+strtrim(lambda,2)+'mm', $
           xtitle=xtitle, ytitle=ytitle, position=pp1[lambda-1,*]
   loadct, /silent, 39
   oplot, [0], [0], psym=1, syms=2, col=150
   oplot, fwhm*!fwhm2sigma*cos(phi), fwhm*!fwhm2sigma*sin(phi), col=150
   oplot, fit_params[4] + xx1, fit_params[5] + yy1, col=250
   oplot, [fit_params[4]], [fit_params[5]], psym=1, col=250

   legendastro, coord, box=0, /right, charsize=1, textcol=255
   legendastro, ['Gaussian fit:', $
                 dx_leg+" "+num2string(fit_params[4]), $
                 dy_leg+" "+num2string(fit_params[5]), $
                 'Peak '+num2string(fit_params[1]), $
                 'FWHM '+num2string( sqrt(fit_params[2]*fit_params[3])/!fwhm2sigma)], $
                textcol=255, box=0
   legendastro, ['Tau = '+num2string(kidpar[w1[0]].tau_skydip), $
                 'Flux = '+num2string( flux)+" +- "+num2string(sigma_bg)+" Jy", $
                 'Flux (center) = '+num2string(flux_center)+" +- "+num2string(sigma_flux_center), $
                 'NEFD '+num2string(NEFD)+" mJy/Beam.s!u1/2!n", $
                 'RMS = '+num2string(bg_rms*1000)+" mJy/Beam (eq. 10 arcsec)"], $
                textcol=[255, 250, 150, 255, 255], box=0, /bottom, charsize=1

   ;; Store results
   map_t_fit_params[lambda-1,0] = flux
   map_t_fit_params[lambda-1,1] = sqrt(fit_params[2]*fit_params[3])/!fwhm2sigma

   ;; Take the error on the gaussian peak as the approx error on the flux (with
   ;; k_noise set by hand anyway...)
   err_map_t_fit_params[lambda-1,0] = output_fit_par_error[1]
   err_map_t_fit_params[lambda-1,1] = sqrt(output_fit_par_error[2]*output_fit_par_error[3])/!fwhm2sigma

   log_info.result_name[ p]   = 'Flux '+strtrim(lambda,2)+'mm: '
   log_info.result_value[p]   = flux
   log_info.result_name[ p+1] = 'NEFD (mJy/Beam) '
   log_info.result_value[p+1] = nefd
   log_info.result_name[ p+2] = 'RMS mJy/Beam'
   log_info.result_value[p+2] = bg_rms*1000
   p+=3

   print, ""
   print, "-------------------------------------"
   if (flux lt 0.1) then begin
      print, "Flux = "+strtrim(flux*1000,2)+" +- "+strtrim(sigma_bg*1000)+" mJy"
   endif else begin
      print, "Flux = "+strtrim(flux,2)+" +- "+strtrim(sigma_bg,2)+" Jy"
   endelse
   if (flux_center lt 0.1) then begin
      print, "Flux at center = "+strtrim(flux_center*1000,2)+" +- "+strtrim(sigma_flux_center*1000)+" mJy"
   endif else begin
      print, "Flux at center = "+strtrim(flux_center,2)+" +- "+strtrim(sigma_flux_center,2)+" Jy"
   endelse
   print, "NEFD = "+num2string(NEFD)+" mJy/Beam.s!u1/2!n"
   print, "RMS = "+strtrim(bg_rms*1000,2)+" mJy/Beam"

   ;;***************************
   ;; Derive approximate errors bars

   ;; ;; Need to swicth angle convention because it was done in fitmap
   ;; junk     = fit_params
   ;; junk[6]  = -junk[6]
   ;; map_fit  = nika_gauss2( xmap, ymap, junk)
   ;; map_diff = map.jy - map_fit
   ;; 
   ;; ;imview, map_diff, title='map - fit'
   ;; 
   ;; ;; Integrate the difference in a gaussian beam
   ;; fwhm        = sqrt(fit_params[2]*fit_params[3])/!fwhm2sigma
   ;; sigma_gauss = fwhm*!fwhm2sigma
   ;; dist        = sqrt( (xmap-fit_params[4])^2 + (ymap-fit_params[5])^2)
   ;; w           = where( map.var gt 0 and dist le 5*sigma_gauss)
   ;; gauss_w8    = exp( -dist^2/(2.d0*sigma_gauss^2))
   ;; diff_flux   = abs( total( map_diff[w] *gauss_w8[w])/total(gauss_w8[w]^2))
   ;; 
   ;; ;; Assume the entire diff comes from the amplitude
   ;; ;; (=flux in Jy/beam in nika_gauss2fit convention)
   ;; err_ampl = diff_flux
   ;; 
   ;; ;; Assume the entire diff comes from the FWHM
   ;; ;; The integral of exp(-d^2/(2*sigma^2)) is 2*!dpi*sigma^2...
   ;; err_fwhm = sqrt( sigma_gauss^2 + diff_flux/(2.d0*!dpi*flux)) - sigma_gauss
   ;; err_fwhm = err_fwhm/!fwhm2sigma
   ;; 
   ;; 
   ;; err_map_t_fit_params[lambda-1,0] = err_ampl
   ;; err_map_t_fit_params[lambda-1,1] = err_fwhm
   ;; 
   ;; ;;***************************

   ;; Determine which is closest to the source for convenience
   if keyword_set(azel) then begin
      nika_nasmyth2azel, kidpar.nas_x, kidpar.nas_y, $
                         0.0, 0.0, data[nsn/2].el*!radeg, kid_off_x, kid_off_y, $
                         nas_x_ref=kidpar.nas_center_X, nas_y_ref=kidpar.nas_center_Y
   endif else begin
      nika_nasmyth2draddec, 0., 0., data[nsn/2].el, data[nsn/2].paral, $
                            kidpar.nas_x, kidpar.nas_y, $
                            0., 0., kid_off_x, kid_off_y, nas_x_ref=kidpar.nas_center_X, $
                               nas_y_ref=kidpar.nas_center_Y
   endelse
   d = sqrt( (kid_off_x-fit_params[4])^2 + (kid_off_y-fit_params[5])^2)
   dmin = min( d[w1])
   ikid = where( d eq dmin and kidpar.type eq 1 and kidpar.array eq lambda)
   ikid = ikid[0] ; just in case...
   closest_kid[lambda-1] = kidpar[ikid].numdet

endfor
outplot, /close

if keyword_set(focal_plane) then begin
   my_multiplot, /reset

   el_deg_avg = data[nsn/2].el*!radeg

   for lambda=lambda_min, lambda_max do begin
      wind, lambda, lambda, /free, /large
      junk = execute( "map = maps."+box[lambda-1])
      junk = execute( "map_var = maps."+box[lambda-1]+".var")
      
      ;; Point source photometry
      w1 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw1) ;  and finite(kidpar.noise), nw1)

      !mamdlib.coltable = 1
      if keyword_set(convolve) then disp_map = map_conv else disp_map = map.jy

      if keyword_set(azel) then begin
         nika_nasmyth2azel, kidpar.nas_x, kidpar.nas_y, $
                            0.0, 0.0, data[nsn/2].el*!radeg, kid_off_x, kid_off_y, $
                            nas_x_ref=kidpar.nas_center_X, nas_y_ref=kidpar.nas_center_Y
      endif else begin
         nika_nasmyth2draddec, 0., 0., data[nsn/2].el, data[nsn/2].paral, $
                               kidpar.nas_x, kidpar.nas_y, $
                               0., 0., kid_off_x, kid_off_y, nas_x_ref=kidpar.nas_center_X, $
                               nas_y_ref=kidpar.nas_center_Y
      endelse
      xrange = minmax( kid_off_x[w1])
      xrange = xrange + [-1,1]*0.1*(xrange[1]-xrange[0])
      yrange = minmax( kid_off_y[w1])
      yrange = yrange + [-1,1]*0.1*(yrange[1]-yrange[0])

      w = where( map_var gt 0, nw, compl=wcompl, ncompl=nwcompl)
      if nwcompl ne 0 then map_var[wcompl] = !values.d_nan
      var_med = median( map_var[w])
      imrange = minmax( disp_map[where( map_var le var_med and map_var gt 0)])
      imview, disp_map, xmap=xmap, ymap=ymap, /noerase, imrange=imrange, $
              title=nickname+" "+strtrim(lambda,2)+'mm', $
              xtitle=xtitle, ytitle=ytitle, $
              xrange=xrange, yrange=yrange
      loadct, /silent, 39
      legendastro, coord, box=0, /right, charsize=1, textcol=255

      oplot,  kid_off_x[w1], kid_off_y[w1], psym=1, col=250
      xyouts, kid_off_x[w1], kid_off_y[w1], strtrim( kidpar[w1].numdet,2), col=250
   endfor
endif

;; Display polarization maps
if polar eq 1 then begin
   results = dblarr(2,3,3)
   bg_rms  = dblarr(3)

   for lambda=lambda_min, lambda_max do begin
      wind, lambda, lambda, /free, xs=1200, ys=500
      my_multiplot, 3, 1, pp, pp1, /rev

      delvarx, input_fit_par    ; to re-init with istokes=0
      for istokes=0,2 do begin
         junk = execute( "jy   = reform( maps_s"+strtrim(istokes,2)+"[*,lambda-1], nx, ny)")
         junk = execute( "var  = reform( maps_covar[*,lambda-1,istokes], nx, ny)")
         junk = execute( "time = 1./!nika.f_sampling*reform( nhits[*,lambda-1], nx, ny)")
         
         map = {jy:jy, var:var, time:time}
         
         ;; Point source photometry
         w1 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw1) ;  and finite(kidpar.noise), nw1)
         ;;fwhm = median( kidpar[w1].fwhm)
         fwhm = !nika.fwhm_nom[lambda-1]
         nika_map_noise_estim, param, map, xmap, ymap, fwhm, flux, $
                               sigma_flux, sigma_bg, map_conv, fit_par, rms, $
                               input_fit_par=input_fit_par, educated=educated
         bg_rms[istokes] = rms
         input_fit_par = fit_par ; init with parameters derived on S0 and apply to S1 and S2

         matrix_surface = nw1 * kidpar[w1[0]].grid_step^2
         scan_surface   = (max(data.ofs_az)-min(data.ofs_az)) * (max(data.ofs_el)-min(data.ofs_el))
         rho            = (matrix_surface/scan_surface) < 1.d0 ; fraction of scan spent on the source
         ndet_per_beam  = fwhm^2/kidpar[w1[0]].grid_step^2
         sensit_toi     = sigma_flux*1000*sqrt(rho*param.integ_time[0])/sqrt(ndet_per_beam)
         sensit_map     = sigma_bg  *1000*sqrt(rho*param.integ_time[0])/sqrt(ndet_per_beam)
         
         xx  = fit_par[2]*cos(phi)
         yy  = fit_par[3]*sin(phi)
         xx1 = cos(fit_par[6])*xx - sin(fit_par[6])*yy
         yy1 = sin(fit_par[6])*xx + cos(fit_par[6])*yy
         
         !mamdlib.coltable = 1
         if keyword_set(convolve) then disp_map = map_conv else disp_map = map.jy
         w = where( finite(disp_map) ne 1, nw)
         if nw ne 0 then disp_map[w] = 0.d0
         imview, disp_map, xmap=xmap, ymap=ymap, /noerase, nsigma=5, $
                 title=nickname+" "+strtrim(lambda,2)+'mm', $
                 xtitle=xtitle, ytitle=ytitle, position=pp1[istokes,*]
         loadct, 39
         oplot, fit_par[4] + xx1, fit_par[5] + yy1, col=250
         oplot, [fit_par[4]], [fit_par[5]], psym=1, col=250
         legendastro, ['S'+strtrim(istokes,2)], box=0, /right, textcol=255
         legendastro, ['Gaussian fit:', $
                       '!7D!3x '+num2string(fit_par[4]), $
                       '!7D!3y '+num2string(fit_par[5]), $
                       'Flux '+num2string(flux), $
                       'FWHM '+num2string( sqrt(fit_par[2]*fit_par[3])/!fwhm2sigma)], $
                      textcol=255, box=0
         legendastro, ['Tau = '+num2string(kidpar[w1[0]].tau_skydip), $
                       'Flux = '+num2string( flux)+" +- "+num2string(sigma_flux)+" ("+num2string(sigma_bg)+" Jy", $
                       'Sens. TOI (Map) = '+num2string(sigma_flux*1000)+" ("+num2string(sigma_bg*1000)+") mJy/Beam", $
                       'Sens. TOI (Map) = '+num2string(sensit_toi)+" ("+num2string(sensit_map)+") mJy./Beam.s!u1/2!n"], $
                      textcol=255, box=0, /bottom, charsize=1
         if keyword_set(convolve) then legendastro, "Beam convolved", /right, box=0, textcol=250

         results[lambda-1,  istokes, 0] = flux
         results[lambda-1,  istokes, 1] = sigma_flux
         results[lambda-1,  istokes, 2] = sigma_bg
      endfor
   endfor
endif

;; Save output
scan_name = strtrim(param.day,2)+"s"+strtrim(scan_num,2)
if polar eq 0 then begin
   save, file=!nika.save_dir+"/maps_"+scan_name+".save", $
         maps, param, xmap, ymap, scan_surface, bg_rms, map_t_fit_params, err_map_t_fit_params
endif else begin
   save, file=!nika.save_dir+"/maps_"+scan_name+".save", $
         maps_s0, maps_s1, maps_s2, maps_covar, param, xmap, ymap, scan_surface, bg_rms
endelse


;; Update absolute calibration in a new kidpar
if keyword_set(calibrate) then begin

   message, /info, "Stopped to check the calibrate option in rta_map"
   stop
   ;; Apply measured fluxes for absolute calibration
   nika_pipe_planet_calib, param, data, kidpar, flux_1mm=flux_mes[0], flux_2mm=flux_mes[1]
   
   ;; Save kidpar
   for lambda=1,2 do begin
      w = where( kidpar.array eq lambda, nw)
      if nw ne 0 then begin
         nika_write_kidpar, kidpar[w], !nika.soft_dir+"/Pipeline/Realtime/kidpar_"+$
                            strtrim(lambda,2)+"mm_"+param.day+"s"+strtrim(param.scan_num,2)+".fits"
      endif
   endfor
endif

print, ""
print, "-------------------------------------------------------------------"
print, "Closest kid to the source (1mm): ", closest_kid[0]
print, "Closest kid to the source (2mm): ", closest_kid[1]

if polar eq 1 then begin
   print, ""
   print, "-------------------------------------------------------------------"
   print, "Polarization flux and degree."
   print, ""
   for lambda=lambda_min, lambda_max do begin
      
      S0 = results[lambda-1,0,0]
      S1 = results[lambda-1,1,0]
      S2 = results[lambda-1,2,0]

      sigma_S0 = results[lambda-1,0,1]
      sigma_S1 = results[lambda-1,1,1]
      sigma_S2 = results[lambda-1,2,1]

      sigma_S0_bg = results[lambda-1,0,2]
      sigma_S1_bg = results[lambda-1,1,2]
      sigma_S2_bg = results[lambda-1,2,2]


      print, box[lambda-1]+" "+strtrim(lambda,2)+"mm, I = " + $
             num2string( S0)+" +- "+num2string( sigma_s0)+" / "+num2string( sigma_s0_bg)
      print, box[lambda-1]+" "+strtrim(lambda,2)+"mm, Q = " + $
             num2string( S1)+" +- "+num2string( sigma_s1)+" / "+num2string( sigma_s1_bg)
      print, box[lambda-1]+" "+strtrim(lambda,2)+"mm, U = " + $
             num2string( S2)+" +- "+num2string( sigma_s2)+" / "+num2string( sigma_s2_bg)

      pol_deg          = sqrt( s1^2 + s2^2)/s0
      sigma_pol_deg    = pol_deg*sigma_s0/s0    + 1.d0/s0 * (s1*sigma_s1    + s2*sigma_s2)   /sqrt( s1^2 + s2^2)
      sigma_pol_deg_bg = pol_deg*sigma_s0_bg/s0 + 1.d0/s0 * (s1*sigma_s1_bg + s2*sigma_s2_bg)/sqrt( s1^2 + s2^2)
      print, box[lambda-1]+" "+strtrim(lambda,2)+"mm, pol. deg =" + $
             num2string( pol_deg)+" +- "+num2string( sigma_pol_deg)+" / "+num2string( sigma_pol_deg_bg)
      print, ""
   endfor
endif

print, ""
print, "-------------------------------------------------------------------"
for lambda=lambda_min, lambda_max do begin
   print, box[lambda-1]+" "+strtrim(lambda,2)+ $ 
          "mm, : (MAP) (for PAKO) SET POINTING ", $
          string(-offsetmap[lambda-1, 0]+pako_str.p2cor, format='(F10.1)'), ", ",  $
          string(-offsetmap[lambda-1, 1]+pako_str.p7cor, format='(F10.1)')

   cmd = "SET POINTING "+strtrim( string(-offsetmap[lambda-1, 0]+pako_str.p2cor,format="(F5.1)"),2)+$
         " "+strtrim( string(-offsetmap[lambda-1, 1]+pako_str.p7cor,format="(F5.1)"),2)
   if lambda eq 2 then begin
      log_info.result_name[p]  = cmd
      log_info.result_value[p] = !undef
      p +=1
   endif
endfor
print, ""
print, "-------------------------------------------------------------------"

;; ;; Derive the equivalent Nasmyth offset (TBC)
;; for lambda=lambda_min, lambda_max do begin
;;    azel2nasm, data[nsn/2].el, -offsetmap[lambda-1,0], -offsetmap[lambda-1,1], ofs_x, ofs_y
;;    print, "    "+box[lambda-1]+" "+strtrim(lambda,2)+ $
;;           "mm, : Equiv set Nasmyth offset: ", string(ofs_x+pako_str.nas_offset_x,format='(F10.1)'), ", ",  $
;;           string(ofs_y+pako_str.nas_offset_y, format='(F10.1)')
;; endfor

;; Create a html page with plots from this scan
save, file=output_dir+"/log_info.save", log_info
nika_logbook_sub, scan_num, day

nika_pipe_measure_atmo, param, data, kidpar, /noplot
save, file=output_dir+"/param.save", param

end
