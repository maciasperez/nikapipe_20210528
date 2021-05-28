
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; geom_prepare_toi
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

pro geom_prepare_toi, scan, kidpar, $
                      map_list_azel_tot, map_list_nasmyth_tot, $ ; nhits_azel_tot, nhits_nasmyth_tot, $
                      grid_azel, grid_nasmyth, param, maps_dir, nickname, decor_method=decor_method, $
                      kid_step=kid_step, gamma=gamma, $
                      discard_outlyers=discard_outlyers, $
                      force_file=force_file, nproc=nproc, noplot=noplot, $
                      kids_out=kids_out, input_kidpar_file=input_kidpar_file, reso = reso, el_avg=el_avg, $
                      zigzag=zigzag, sn_min=sn_min, sn_max=sn_max, $
                      map_list_nhits_nasmyth_tot=map_list_nhits_nasmyth_tot, $
                      map_list_nhits_azel_tot=map_list_nhits_azel_tot, plot_dir=plot_dir, $
                      multiscans=multiscans, toi_dir=toi_dir, no_opacity_correction=no_opacity_correction, $
                      lockin_freqhigh=lockin_freqhigh, decor_cm_dmin=decor_cm_dmin, $
                      mask_default_radius=mask_default_radius
  
if keyword_set(kids_out) and not keyword_set(input_kidpar_file) then begin
   message, /info, "I need input_kidpar_file to derive a first pointing and know where the source is"
   message, /info, "to perform a common_kids_out decorrelation"
   return
endif

if not keyword_set(plot_dir) then plot_dir = !nika.plot_dir+"/"+scan

;; To be sure that !nika.run won't enter any specific case of a run =< 5
!nika.run = !nika.run > 11

scan2daynum, scan, day, scan_num

nk_default_param, param
param.scan_num        = scan_num
param.day             = day
param.scan            = strtrim(day,2)+"s"+strtrim(scan_num,2)

;; to reduce polarized beammaps, we must change the default lockin
;; high frequency otherwise it cuts right into the beam bandpass and
;; generates ringing
if keyword_set(lockin_freqhigh) then param.polar_lockin_freqhigh = lockin_freqhigh

;; to save time, avoid the computation of PF or even RF and
;; keep Alain's estimate
param.math            = "CF"
;;param.alain_rf        = 1

param.do_plot         = 1
param.flag_uncorr_kid = 0
param.flag_sat        = 0
param.flag_oor        = 0
param.flag_ovlap      = 0
param.flag_ident      = 0
param.fast_deglitch   = 1
param.cpu_time        = 0 ; 1
param.plot_dir = plot_dir
param.do_opacity_correction = 0

if keyword_set(noplot) then param.do_plot = 0

if param.cpu_time then cpu_time_0 = systime( 0, /sec)

nk_default_info, info

imb_fits_file = !nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits"
if file_test(imb_fits_file) eq 0 then begin
   message, /info, "copying imbfits file from mrt-lx1"
   spawn, "scp nikaw-17@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/"
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
   param.do_opacity_correction = 6 ; switch to 6 : NP+LP, April 17th, 2020

   ;;---------------
   ;;if (!db.lvl eq 1 or !db.lvl eq 3)  then begin
   if (keyword_set(no_opacity_correction) or !db.lvl eq 1 or !db.lvl eq 3) then begin
      message, /info, "fix me: set back opacity correction:"
      param.do_opacity_correction = 0
   endif
   ;;endif
   ;;---------------

   if keyword_set(decor_method) then param.decor_method = decor_method else param.decor_method = 'common_mode_kids_out'
   param.set_zero_level_per_subscan =  1
   
   ;; ;; LP modif
   ;; param.set_zero_level_per_subscan =  0
   
   param.map_center_ra  =  !values.d_nan
   param.map_center_dec =  !values.d_nan
   param.interpol_common_mode =  1
   katana = 0
endif

if keyword_set(input_kidpar_file) then begin
   param.file_kidpar = input_kidpar_file
   param.force_kidpar = 1
endif

if keyword_set(zigzag) then param.zigzag_correction = 1

nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max, $
            force_file=force_file, xml=xml, read_type=1, list_detector=list_detector, katana = katana

;; for i=0, 2 do message, /info, "****************************"
;; message, /info, "FIX ME: restricting to 2mm"
;; w = where( kidpar.array ne 2, nw)
;; kidpar[w].type = 3
;; for i=0, 2 do message, /info, "****************************"
;; stop

;for iarray=1, 3 do print, n_elements( where( kidpar.type eq 1 and kidpar.array eq iarray))
;stop

;; subtract template from TOIs if polarization ON.
if info.polar ne 0 then begin
   param.polar_lockin_freqlow   = 0.01
   param.polar_lockin_freqhigh = info.hwp_rot_freq - 0.01
   nk_deal_with_hwp_template, param, info, data, kidpar
endif

nk_deglitch_fast, param, info, data, kidpar

if param.do_opacity_correction ge 1 then nk_get_opacity, param, info, data, kidpar

xra_map = [-400, 400] ; [-200, 200]
if keyword_set(reso) then param.map_reso = reso

;; Derive Nasmyth offsets
azel2nasm, data.el, data.ofs_az, data.ofs_el, ofs_nasx, ofs_nasy

;; Compute pixel coordinates in Nasmyth
xra1 = xra_map
yra1 = xra_map
param.map_xsize = (xra1[1]-xra1[0])*1.1
param.map_ysize = (yra1[1]-yra1[0])*1.1
nk_init_grid_2, param, info, grid_nasmyth
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

;message, /info, "fix me:"
;print, "gamma = ", gamma
;stop

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
nk_init_grid_2, param, info, grid_azel

;; Account for gamma rotation in coordinates as well
;; moved it here, NP, Aug. 19th, 2016 for convenience, it used to be
;; done in geom_fit_beam_parameters_sub (rev <= 12213).
xmap = grid_azel.xmap
grid_azel.xmap = cos(gamma)*xmap - sin(gamma)*grid_azel.ymap
grid_azel.ymap = sin(gamma)*xmap + cos(gamma)*grid_azel.ymap

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

;; TOI Processing
if keyword_set(kids_out) then begin
   ;; LP: replacing obsolete parameter
   ;; param.decor_cm_dmin = 90.    ;    60.    ; take some margin to cope with approximate kidpar offsets and source centering
   ;;if (!db.lvl eq 2 or !db.lvl eq 3) then param.decor_cm_dmin = !db.cm_dmin
   ;;if keyword_set(decor_cm_dmin) then param.decor_cm_dmin = decor_cm_dmin
   param.mask_default_radius    = 90.
   if (!db.lvl eq 2 or !db.lvl eq 3) then param.mask_default_radius = !db.cm_dmin
   if keyword_set(mask_default_radius) then param.mask_default_radius = mask_default_radius
   if keyword_set(decor_cm_dmin) then param.mask_default_radius = decor_cm_dmin
   ;; end LP
   nk_init_grid_2, param, info, grid

   param.map_proj = 'AZEL'

   nk_get_kid_pointing, param, info, data, kidpar
   nk_get_ipix, param, info, data, kidpar, grid
   nk_mask_source, param, info, data, kidpar, grid
   nk_clean_data_3, param, info, data, kidpar, out_temp_data = out_temp_data
   nk_set0level_2,  param,  info,  data,  kidpar
   toi = data.toi
   
endif else begin
   ;; median filter per timeline for robustness at the first iteration
   speed = sqrt( deriv(ofs_az)^2 + deriv(ofs_el)^2)*!nika.f_sampling
   median_speed = median( speed)
   decor_median_width = long(10*20.*!fwhm2sigma/median_speed*!nika.f_sampling) ; 5 sigma on each side at about 35 arcsec/s
   toi = data.toi
   w1 = where( kidpar.type eq 1, nw1)
   for i=0, nw1-1 do begin
      ikid = w1[i]
      toi[ikid,*] -= median( reform(toi[ikid,*]), decor_median_width)
   endfor
endelse

;;stop
;; restrict to valid kids only from here
;; Aug. 12th, 2016
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then message, "No valid kids"

;; Entering ktn_prepare.pro
nsn = n_elements(toi[0,*])

w8  = fltarr( nsn) + 1.d0
toi1 = toi[w1,*]
kidpar1 = kidpar[w1,*]

;; Compute Individual kid maps in (Az,el)
get_bolo_maps_6, toi1, ipix_azel, w8, kidpar1, grid_azel, map_list_azel_tot, nhits_azel_tot
;; Compute Individual kid maps in Nasmyth
get_bolo_maps_6, toi1, ipix_nasmyth, w8, kidpar1, grid_nasmyth, map_list_nasmyth_tot, nhits_nasmyth_tot
   
;; to be compatible with second iteration
map_list_nhits_nasmyth_tot = dblarr(nw1, grid_nasmyth.nx, grid_nasmyth.ny)
map_list_nhits_azel_tot    = dblarr(nw1, grid_azel.nx, grid_azel.ny)
for i=0, nw1-1 do begin
   map_list_nhits_nasmyth_tot[i,*,*] = nhits_nasmyth_tot
   map_list_nhits_azel_tot[   i,*,*] = nhits_azel_tot
endfor
w1 = where( kidpar.type eq 1, nw1)
kidpar = kidpar[w1]
toi = toi[w1,*]


;; Take the power spectrum on the 2 most quiet minutes
n_2mn = 2*60.*!nika.f_sampling
nsn_noise = (2L^round( alog(n_2mn)/alog(2))) < nsn
wk = where( kidpar.type eq 1, nwk)
for i=0, nwk-1 do begin
   ikid = wk[i]
   rms  = 1e10
   ixp  = 0
   ix1  = 0 ; init
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

;;================= geom_toi2kidmaps_parall
el_avg_rad = el_avg

nkids = n_elements(kidpar)
if not keyword_set(nproc) then begin
;; Split the data into nproc .save files (leave at least 10 cpu for
;; acquisition ?
   nproc_max = (!cpu.hw_ncpu-10)>1
   cpu_time = dblarr( nproc_max)
   for iproc=0, nproc_max-1 do begin
      r = nkids - (iproc+1)*(nkids/(iproc+1))
      cpu_time[iproc] = nkids/(iproc+1) + r
      print, "nprocs, nperproc, r: ", iproc+1, nkids/(iproc+1), r, cpu_time[iproc]
   endfor
   w = where( cpu_time eq min(cpu_time), nw)
   nproc = w[0] + 1
   print, "nproc: ", nproc
   wind, 1, 1, /free, /large
   !p.multi=[0,1,2]
   plot, cpu_time
   plot, cpu_time, yra=[0, 200], /ys
   !p.multi=0
   print, "choose nproc"
   read, nproc
   nproc = long(nproc)
endif

if keyword_set(multiscans) then begin
   file_save = toi_dir+"/beam_map_preproc_toi_"+scan+".save"
   map_list_nhits_nasmyth = map_list_nhits_nasmyth_tot
   map_list_nhits_azel    = map_list_nhits_azel_tot
   map_list_azel          = map_list_azel_tot
   map_list_nasmyth       = map_list_nasmyth_tot
   save, file=file_save, scan, kidpar, $
         map_list_azel, map_list_nasmyth, $
         grid_azel, grid_nasmyth, param, el_avg, map_list_nhits_nasmyth, map_list_nhits_azel
endif else begin
   nkids_per_proc = long( nkids/float(nproc))
   kidpar_tot = kidpar
   for iproc=0, nproc-1 do begin
      if iproc ne (nproc-1) then begin
         kidpar                 = kidpar_tot[                 iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1]
         map_list_azel          = map_list_azel_tot[          iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
         map_list_nasmyth       = map_list_nasmyth_tot[       iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
         map_list_nhits_azel    = map_list_nhits_azel_tot[    iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
         map_list_nhits_nasmyth = map_list_nhits_nasmyth_tot[ iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
      endif else begin
         kidpar                 = kidpar_tot[                 iproc*nkids_per_proc:*]
         map_list_azel          = map_list_azel_tot[          iproc*nkids_per_proc:*, *, *]
         map_list_nasmyth       = map_list_nasmyth_tot[       iproc*nkids_per_proc:*, *, *]
         map_list_nhits_azel    = map_list_nhits_azel_tot[    iproc*nkids_per_proc:*, *, *]
         map_list_nhits_nasmyth = map_list_nhits_nasmyth_tot[ iproc*nkids_per_proc:*, *, *]
      endelse
      file = maps_dir+"/kid_maps_"+nickname+"_"+strtrim(iproc,2)+".save"
      print, file
      save, file=file, $
            kidpar, map_list_azel, map_list_nasmyth, $
            map_list_nhits_azel, map_list_nhits_nasmyth, $
            el_avg_rad, $       ; nhits_azel, nhits_nasmyth,
            grid_azel, grid_nasmyth
   endfor
endelse

t1 = systime(0,/sec)
if param.cpu_time then message, /info, "CPU Time: "+strtrim(t1-cpu_time_0,2)

end
