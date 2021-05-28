
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; nk_otf_geometry_bcast_data
;
; CATEGORY:
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
; 
; INPUT: 
;
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct. 11th, 2015: NP restarted from scratch, following Katana.
;-
;================================================================================================


pro nk_otf_geometry_bcast_data, scan, beam_map_subindex, kidpar, $
                                map_list_azel, map_list_nasmyth, nhits_azel, nhits_nasmyth, $
                                grid_azel, grid_nasmyth, param, $
                                kid_step=kid_step, gamma=gamma, $
                                discard_outlyers=discard_outlyers, $
                                force_file=force_file, nproc=nproc, noplot=noplot, $
                                kids_out=kids_out, input_kidpar_file=input_kidpar_file, reso = reso, el_avg=el_avg, $
                                zigzag=zigzag


;; if n_params() lt 1 then begin
;;    message, /info, "calling sequence:"
;;    print, "nk_otf_geometry_bcast_data, scan, file_list, $"
;;    print, "                                kid_step=kid_step, $"
;;    print, "                                discard_outlyers=discard_outlyers, $"
;;    print, "                                force_file=force_file, nproc=nproc, $"
;;    print, "                                kids_out=kids_out, input_kidpar_file=input_kidpar_file, reso=reso"
;;    return
;; endif

;; scan = scan_list[iscan]
  
if keyword_set(kids_out) and not keyword_set(input_kidpar_file) then begin
   message, /info, "I need input_kidpar_file to derive a first pointing and know where the source is"
   message, /info, "to perform a common_kids_out decorrelation"
   return
endif


;; To be sure that !nika.run won't enter any specific case of a run =< 5
!nika.run = !nika.run > 11

scan2daynum, scan, day, scan_num

nk_default_param, param
param.scan_num        = scan_num
param.day             = day
param.scan            = strtrim(day,2)+"s"+strtrim(scan_num,2)
;;param.math            = "RF"               ; to save time
param.do_plot         = 1
param.flag_uncorr_kid = 0
param.flag_sat        = 0
param.flag_oor        = 0
param.flag_ovlap      = 0
param.fast_deglitch   = 1
param.cpu_time        = 0 ; 1

param.do_opacity_correction = 0

if keyword_set(noplot) then param.do_plot = 0

if param.cpu_time then cpu_time_0 = systime( 0, /sec)

nk_default_info, info

imb_fits_file = !nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits"
if file_test(imb_fits_file) eq 0 then begin
   message, /info, "copying imbfits file from mrt-lx1"
   spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
endif

if keyword_set(force_file) then begin
   nk_imbfits2info, imb_fits_file, info
endif else begin
   nk_update_param_info, param.scan, param, info, xml=xml, /katana
endelse

;; Pass source to param to have at least an approximate calibration
;; (uncorrected for opacity at this stage, but still better than nothing).
param.source = info.object

list_detector = lindgen(8000)
if keyword_set(kid_step) then list_detector = list_detector[ where(list_detector mod kid_step eq 0)]

;; Read data
param.silent=0
param.do_plot=0
katana = 1
if keyword_set(kids_out) then begin
   param.do_opacity_correction = 1
;   message, /info, "fix me: put opacity_correction back"
;   param.do_opacity_correction = 0
;   stop
   
   param.decor_method = 'common_mode_kids_out'
   param.set_zero_level_per_subscan =  1
   param.map_center_ra  =  !values.d_nan
   param.map_center_dec =  !values.d_nan
   param.interpol_common_mode =  1
   ;; param.decor_cm_dmin =  40 ; enlarge a bit in case the input kidpar offsets are too approximative
   param.mask_default_radius = 40
   katana = 0
endif

if keyword_set(input_kidpar_file) then begin
   param.file_kidpar = input_kidpar_file
   param.force_kidpar = 1
endif

nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max, $
            force_file=force_file, xml=xml, read_type=1, list_detector=list_detector, katana = katana

;; Correct for zigzag effects
nsn = n_elements(data)
time = dindgen(nsn)/!nika.f_sampling
data1 = data
for iarray=1, 3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin
      time1 = time + !nika.zigzag[iarray-1]*1d-3
      data1.ofs_az = interpol( data.ofs_az, time, time1)
      data1.ofs_el = interpol( data.ofs_el, time, time1)
      data1.az     = interpol( data.az,     time, time1)
      data1.el     = interpol( data.el,     time, time1)
      data1.paral  = interpol( data.paral,  time, time1)
      nk_get_kid_pointing, param, info, data1, kidpar
      
      data.dra[ w1] = data1.dra[ w1]
      data.ddec[w1] = data1.ddec[w1]
      
      nsnflag = round( !nika.zigzag[iarray-1]*1d-3*!nika.f_sampling) > 1
      data[0:nsnflag-1].flag       += 1
      data[nsn-nsnflag:nsn-1].flag += 1
   endif
endfor
delvarx, data1

;; subtract template from TOIs if polarization ON.
if info.polar ne 0 then begin
   param.polar_lockin_freqlow   = 0.01
   param.polar_lockin_freqhigh = info.hwp_rot_freq - 0.01
   nk_deal_with_hwp_template, param, info, data, kidpar
endif

nk_deglitch_fast, param, info, data, kidpar

if param.do_opacity_correction eq 1 then $
   nk_get_opacity, param, info, data, kidpar

;; If this is the second iteration with /kids_out, i need to perform
;; the decorrelation here to extract toi for the .save files and
;; nk_otf_geometry_sub here. It's slower but better for
;; now... (Oct. 29th)
if keyword_set(kids_out) then begin
   message, /info, "Inside kids_out"
   ;;param.decor_cm_dmin = 60.    ; take some margin to cope with approximate kidpar offsets and source centering
   param.mask_default_radius = 60. ; take some margin to cope with approximate kidpar offsets and source centering
   nk_init_grid, param, info, grid
   nk_get_kid_pointing, param, info, data, kidpar
   nk_get_ipix, data, info, grid
   nk_mask_source, param, info, data, kidpar, grid
   nk_clean_data_2, param, info, data, kidpar, out_temp_data = out_temp_data
   nk_set0level,  param,  info,  data,  kidpar

;;    ;; quick check on display
;;    nk_w8,  param,  info,  data,  kidpar
;;    nk_projection_4, param, info, data, kidpar, grid
;;    nk_display_maps, grid
endif

toi = data.toi

xra_map = [-400, 400] ; [-200, 200]
if keyword_set(reso) then param.map_reso = reso

if keyword_set(zigzag) then begin
   nsn = n_elements(data)
   time = dindgen(nsn)/!nika.f_sampling
   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         time1 = time - zigzag[iarray-1]*1d-3
         data.ofs_az = interpol( data.ofs_az, time, time1)
         data.ofs_el = interpol( data.ofs_el, time, time1)
         data.az     = interpol( data.az,     time, time1)
         data.el     = interpol( data.el,     time, time1)
         data.paral  = interpol( data.paral,  time, time1)
         nsnflag = round( !nika.zigzag[iarray-1]*1d-3*!nika.f_sampling) > 1
         data[0:nsnflag-1].flag       += 1
         data[nsn-nsnflag:nsn-1].flag += 1
      endif
   endfor
endif

;; Derive Nasmyth offsets
azel2nasm, data.el, data.ofs_az, data.ofs_el, ofs_nasx, ofs_nasy

;; Compute pixel coordinates in Nasmyth
xra1 = xra_map
yra1 = xra_map
param.map_xsize = (xra1[1]-xra1[0])*1.1
param.map_ysize = (yra1[1]-yra1[0])*1.1
nk_init_grid, param, info, grid_nasmyth
wkill = where( finite(ofs_nasx) eq 0 or finite(ofs_nasy) eq 0, nwkill)
ix    = (ofs_nasx - grid_nasmyth.xmin)/grid_nasmyth.map_reso
iy    = (ofs_nasy - grid_nasmyth.ymin)/grid_nasmyth.map_reso
if nwkill ne 0 then begin
   ix[wkill] = -1
   iy[wkill] = -1
endif
ipix = double( long(ix) + long(iy)*grid_nasmyth.nx)
w = where( long(ix) lt 0 or long(ix) gt (grid_nasmyth.nx-1) or $
           long(iy) lt 0 or long(iy) gt (grid_nasmyth.ny-1), nw)
if nw ne 0 then ipix[w] = !values.d_nan ; for histogram
ipix_nasmyth = ipix

if not keyword_set(gamma) then gamma = !pi/4.d0
;; ;; Compute pixel coordinates in azel
;; gamma = 0.d0                    ; default
;; Maps in azel are often not well sampled, I therefore force a
;; rotation here to be less sensitive to pixelization, then
;; i'll rotate back the derived offsets
ofs_az = cos(gamma)*data.ofs_az - sin(gamma)*data.ofs_el
ofs_el = sin(gamma)*data.ofs_az + cos(gamma)*data.ofs_el
xra = xra_map
yra = xra_map
param.map_xsize = (xra[1]-xra[0])*1.1
param.map_ysize = (yra[1]-yra[0])*1.1
nk_init_grid, param, info, grid_azel
wkill = where( finite(ofs_az) eq 0 or finite(ofs_el) eq 0, nwkill)
ix    = (ofs_az - grid_azel.xmin)/grid_azel.map_reso
iy    = (ofs_el - grid_azel.ymin)/grid_azel.map_reso
if nwkill ne 0 then begin
   ix[wkill] = -1
   iy[wkill] = -1
endif
ipix = double( long(ix) + long(iy)*grid_azel.nx)
w = where( long(ix) lt 0 or long(ix) gt (grid_azel.nx-1) or $
           long(iy) lt 0 or long(iy) gt (grid_azel.ny-1), nw)
if nw ne 0 then ipix[w] = !values.d_nan ; for histogram
ipix_azel = ipix

;; TOI Processing if needed
;; Old median filter to get a first estimation of beam parameters
if not keyword_set(kids_out) then begin
   speed = sqrt( deriv(ofs_az)^2 + deriv(ofs_el)^2)*!nika.f_sampling
   median_speed = median( speed)
   decor_median_width = long(10*20.*!fwhm2sigma/median_speed*!nika.f_sampling) ; 5 sigma on each side at about 35 arcsec/s
   w1 = where( kidpar.type eq 1, nw1)
   for i=0, nw1-1 do begin
      ikid = w1[i]
      toi[ikid,*] -= median( reform(toi[ikid,*]), decor_median_width)
   endfor
endif

;; Entering ktn_prepare.pro
nsn = n_elements(toi[0,*])
w8  = fltarr( nsn) + 1.d0

;; Compute Individual kid maps in (Az,el)
get_bolo_maps_6, toi, ipix_azel, w8, kidpar, grid_azel, map_list_azel, nhits_azel

;; Compute Individual kid maps in Nasmyth
get_bolo_maps_6, toi, ipix_nasmyth, w8, kidpar, grid_nasmyth, map_list_nasmyth, nhits_nasmyth

;; Take the power spectrum on the 2 most quiet minutes
n_2mn = 2*60.*!nika.f_sampling
nsn_noise = 2L^round( alog(n_2mn)/alog(2))
wk = where( kidpar.type eq 1, nwk)
for i=0, nwk-1 do begin
   ikid = wk[i]
   rms  = 1e10
   ixp  = 0
   while (ixp+nsn_noise-1) lt nsn do begin
      d = reform( toi[ikid,ixp:ixp+nsn_noise-1])
      if stddev(d) lt rms then ix1 = ixp
      ixp += nsn_noise
   endwhile

   y = reform( toi[ikid,ix1:ix1+nsn_noise-1])
   power_spec, y - my_baseline( y), !nika.f_sampling, pw, freq
   wf = where( freq gt 4.d0)
   if finite(avg(pw[wf])) eq 0 then stop
   kidpar[ikid].noise = avg(pw[wf]) ; Hz/sqrt(Hz) since data is in Hz
   
   wf = where( abs(freq-1.d0) lt 0.2, nwf)
   if nwf ne 0 then kidpar[ikid].noise_1hz = avg(pw[wf])
   wf = where( abs(freq-2.d0) lt 0.2, nwf)
   if nwf ne 0 then kidpar[ikid].noise_2hz = avg(pw[wf])
   wf = where( abs(freq-10.d0) lt 1, nwf)
   if nwf ne 0 then kidpar[ikid].noise_10hz = avg(pw[wf])
   wf = where( freq ge 4, nwf)
   if tag_exist( kidpar, "noise_above_4hz") then begin
      if nwf ne 0 then kidpar[ikid].noise_above_4hz = avg(pw[wf])
   endif
endfor

el_avg = median(data.el)

t1 = systime(0,/sec)
if param.cpu_time then message, /info, "CPU Time: "+strtrim(t1-cpu_time_0,2)

end
