
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; nk_otf_geometry
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_otf_geometry, scan, kidpar_in, kidpar_out, file_kidpar_ref=file_kidpar_ref
; 
; PURPOSE: 
;        Recomputes offsets and calibration of kids that have already been selected.
; 
; INPUT: 
;        - scan : the scan identifier
;        - kidpar_in : a structure containing with kid types up to date (valid,
;          unvalid...
;
; OUTPUT: 
;         - kidpar_out : the kid structure with newly computed offsets and calibration
; 
; KEYWORDS:
;         - file_kidpar_ref: another kid parameter structure that is immediately
;           compared to kidpar_out
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sept 26th, 2014: NP (replaces otf_geometry from the old RTA package)
;        - Oct. 10th, 2015: NP restarted from scratch, following Katana.
;-
;================================================================================================


;; ; scan = '20151007s115'
;; force_file = '/home/nika2/NIKA/Data/run13_mirror_1m_X/X24_2015_10_07/X_2015_10_07_12h10m08_A0_0112_I_Mars'
;; scan = '20151007s112'
;; kid_step = 5
;; discard_outlyers = 1

pro nk_otf_geometry, scan, kidpar_out, $
                     kid_step=kid_step, $
                     discard_outlyers=discard_outlyers, $
                     force_file=force_file

if n_params() lt 1 then begin
   message, "calling sequence:"
   print, "tbd"
   return
endif


output_dir = !nika.plot_dir+"/Scans/"+scan
spawn, "mkdir -p "+output_dir

;; To be sure that !nika.run won't enter any specific case of a run =< 5
!nika.run = !nika.run > 11

scan2daynum, scan, day, scan_num

nk_default_param, param
param.output_dir      = output_dir
param.scan_num        = scan_num
param.day             = day
param.scan            = strtrim(day,2)+"s"+strtrim(scan_num,2)
param.math            = "RF"               ; to save time
param.do_plot         = 1
param.flag_uncorr_kid = 0
param.flag_sat        = 0
param.flag_oor        = 0
param.flag_ovlap      = 0
param.fast_deglitch   = 1
param.cpu_time        = 1

param.do_opacity_correction = 0

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

;; 1: list_detector = indgen(4799-1600+1) + 1600
;; 2: list_detector = indgen(1599-0+1) + 0
;; 3: list_detector = indgen(7999-4800+1) + 4800
list_detector = lindgen(8000)
if keyword_set(kid_step) then list_detector = list_detector[ where(list_detector mod kid_step eq 0)]

message, /info, "fix me: for now, the array 3 is unplugged => limit list_detector"
message, /info, "to avoid crash in nk_update_kidpar with param_c.m_f_mod"
list_detector = list_detector[where(list_detector lt 4800)]
; stop

nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max, $
            force_file=force_file, xml=xml, read_type=1, list_detector=list_detector, /katana

nk_deglitch_fast, param, info, data, kidpar

;; Deal with template if polarization is present
if info.polar ne 0 then begin
   message, /info, "Not tested yet, Oct. 10th, 2015"
   message, /info, "See Katana to implement the polarized case"
   return
endif

;; Derive Nasmyth offsets
azel2nasm, data.el, data.ofs_az, data.ofs_el, x_1, y_1
data.ofs_nasx = x_1
data.ofs_nasy = y_1

;; Compute pixel coordinates in azel
xra = minmax(data.ofs_az)
yra = minmax(data.ofs_el)
param.map_xsize = (xra[1]-xra[0])*1.1
param.map_ysize = (yra[1]-yra[0])*1.1
nk_init_grid, param, grid_azel
wkill = where( finite(data.ofs_az) eq 0 or finite(data.ofs_el) eq 0, nwkill)
ix    = (data.ofs_az - grid_azel.xmin)/grid_azel.map_reso
iy    = (data.ofs_el - grid_azel.ymin)/grid_azel.map_reso
if nwkill ne 0 then begin
   ix[wkill] = -1
   iy[wkill] = -1
endif
ipix = double( long(ix) + long(iy)*grid_azel.nx)
w = where( long(ix) lt 0 or long(ix) gt (grid_azel.nx-1) or $
           long(iy) lt 0 or long(iy) gt (grid_azel.ny-1), nw)
if nw ne 0 then ipix[w] = !values.d_nan ; for histogram
data.ipix_azel = ipix

;; Compute pixel coordinates in Nasmyth
xra1  = minmax(data.ofs_nasx)
yra1  = minmax(data.ofs_nasy)
param.map_xsize = (xra1[1]-xra1[0])*1.1
param.map_ysize = (yra1[1]-yra1[0])*1.1
nk_init_grid, param, grid_nasmyth
wkill = where( finite(data.ofs_nasx) eq 0 or finite(data.ofs_nasy) eq 0, nwkill)
ix    = (data.ofs_nasx - grid_nasmyth.xmin)/grid_nasmyth.map_reso
iy    = (data.ofs_nasy - grid_nasmyth.ymin)/grid_nasmyth.map_reso
if nwkill ne 0 then begin
   ix[wkill] = -1
   iy[wkill] = -1
endif
ipix = double( long(ix) + long(iy)*grid_nasmyth.nx)
w = where( long(ix) lt 0 or long(ix) gt (grid_nasmyth.nx-1) or $
           long(iy) lt 0 or long(iy) gt (grid_nasmyth.ny-1), nw)
if nw ne 0 then ipix[w] = !values.d_nan ; for histogram
data.ipix_nasmyth = ipix

;; <<<<<<< .working
;; ;; Data cleaning (old median filter to get a first estimation of beam parameters
;; speed = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling
;; median_speed = median( speed)
;; decor_median_width = long(10*20.*!fwhm2sigma/median_speed*!nika.f_sampling) ; 5 sigma on each side at about 35 arcsec/s
;; w1 = where( kidpar.type eq 1, nw1)
;; t0 = systime(0,/sec)
;; print, "median filter..."
;; for i=0, nw1-1 do begin
;;    ikid = w1[i]
;;    data.toi[ikid] -= median( data.toi[ikid], decor_median_width)
;; =======
;; ;; Save photometric information in a .csv file
;; tags = tag_names(info)
;; w = where( strupcase( strmid(tags,0,6)) eq "RESULT", nw)
;; tag_length = strlen( tags)
;; get_lun, lun
;; openw, lun, param.output_dir+"/photometry.csv"
;; title_string = 'Scan, Source, RA, DEC'
;; res_string   = strtrim(param.scan,2)+", "+strtrim(param.source,2)+", "+strtrim(info.longobj,2)+", "+strtrim(info.latobj,2)
;; for i=0, nw-1 do begin
;;    title_string = title_string+", "+strmid( tags[w[i]],7,tag_length[w[i]]-7)
;;    res_string   = res_string+", "+strtrim( info.(w[i]),2)
;; >>>>>>> .merge-right.r8959
;; endfor
;; <<<<<<< .working
;; print, "... done."
;; t1 = systime(0,/sec)
;; print, "median filter cpu time: ", t1-t0
;; =======
;; printf, lun, title_string
;; printf, lun, res_string
;; close, lun
;; free_lun, lun
;; >>>>>>> .merge-right.r8959

;; Entering ktn_prepare.pro
nsn = n_elements(data)
w8  = fltarr( nsn) + 1.d0

;; Compute Individual kid maps in (Az,el)
message, /info, "Computing kid maps in azel..."
t0 = systime(0,/sec)
get_bolo_maps_6, data.toi, data.ipix_azel, w8, kidpar, grid_azel, map_list_azel
t1 = systime(0,/sec)
if param.cpu_time eq 1 then print, "get_bolo_maps_6 azel: ", t1-t0

;; Compute Individual kid maps in Nasmyth
t0 = systime(0,/sec)
get_bolo_maps_6, data.toi, data.ipix_nasmyth, w8, kidpar, grid_nasmyth, map_list_nasmyth
t1 = systime(0,/sec)
if param.cpu_time eq 1 then print, "get_bolo_maps_6 Nasmyth: ", t1-t0


beam_fit_method = "nika"
;;if keyword_set(fast) then beam_fit_method = 'GAUSS2D'

;; Entering ktn_beam_calibration

;; Get beam properties in (az,el)
t0 = systime(0,/sec)
;; save, map_list_azel, $
;;       grid_azel, kidpar, beam_fit_method, file='test.save'
beam_guess, map_list_azel, $
            grid_azel.xmap, $
            grid_azel.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_1, theta_1, rebin=rebin_factor, $
            verbose=verbose, parinfo=parinfo, noplot=noplot, $
            method=beam_fit_method, cpu_time=cpu_time
t1 = systime(0,/sec)
;; beam_guess, map_list_azel, $
;;             grid_azel.xmap, $
;;             grid_azel.ymap, kidpar, $
;;             x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
;;             beam_list_1, theta_1, rebin=rebin_factor, $
;;             verbose=verbose, parinfo=parinfo, noplot=noplot, $
;;             method='gauss2d', cpu_time=cpu_time
;; t2 = systime(0,/sec)
;; print, "beam_guess 'nika' t1-t0: ", t1-t0
;;print, "beam_guess 'gauss2d' t2-t1: ", t2-t1
;;stop

;; nproc = 4
;; nproc = 16
;; t1 = systime(0,/sec)
;; beam_guess_parallel, map_list_azel, $
;;                      grid_azel.xmap, $
;;                      grid_azel.ymap, kidpar, $
;;                      x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
;;                      beam_list_1, theta_1, rebin=rebin_factor, $
;;                      verbose=verbose, method=beam_fit_method, cpu_time = cpu_time2, nproc = nproc
;; t2 = systime(0,/sec)
;; print, "beam_guess 'nika' t1-t0: ", t1-t0
;; print, "beam_guess_parallel, nproc, t2-t1: ", nproc, t2-t1
;; stop

if param.cpu_time eq 1 then print, "beam_guess azel: ", t1-t0
kidpar.x_peak       = x_peaks_1
kidpar.y_peak       = y_peaks_1
kidpar.x_peak_azel  = x_peaks_1
kidpar.y_peak_azel  = y_peaks_1

;; Compute also in Nasmyth to avoid pixelization errors that sometimes finds
;; beams way out of the Focal Plane
t0 = systime(0,/sec)
beam_guess, map_list_nasmyth, $
            grid_nasmyth.xmap, $
            grid_nasmyth.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_1, theta_1, rebin=rebin_factor, $
            verbose=verbose, parinfo=parinfo, noplot=noplot, $
            method=beam_fit_method, cpu_time=cpu_time
t1 = systime(0,/sec)
if param.cpu_time eq 1 then print, "beam_guess Nasmyth: ", t1-t0
kidpar.x_peak_nasmyth = x_peaks_1
kidpar.y_peak_nasmyth = y_peaks_1
kidpar.nas_x          = x_peaks_1
kidpar.nas_y          = y_peaks_1
kidpar.a_peak         = a_peaks_1
kidpar.sigma_x        = sigma_x_1
kidpar.sigma_y        = sigma_y_1
kidpar.fwhm_x         = sigma_x_1/!fwhm2sigma
kidpar.fwhm_y         = sigma_y_1/!fwhm2sigma
kidpar.fwhm           = sqrt( sigma_x_1*sigma_y_1)/!fwhm2sigma
kidpar.theta          = theta_1
ww = where( sigma_y_1 ne 0., nww)
if nww ne 0 then kidpar[ww].ellipt = sigma_x_1[ww]/sigma_y_1[ww]

;; Fit peak amplitude with the fixed nominal FWHM
for ikid=0, n_elements(kidpar)-1 do begin
   if kidpar[ikid].type eq 1 then begin
      if kidpar[ikid].array eq 1 then sigma_gauss = !nika.fwhm_nom[0]*!fwhm2sigma else sigma_gauss = !nika.fwhm_nom[1]*!fwhm2sigma

      d        = sqrt( (grid_nasmyth.xmap-kidpar[ikid].x_peak_nasmyth)^2 + (grid_nasmyth.ymap-kidpar[ikid].y_peak_nasmyth)^2)
      gauss_w8 = exp( -d^2/(2.d0*sigma_gauss^2))
      junk     = reform( map_list_nasmyth[ikid,*,*])
      w        = where( finite(junk) eq 1)
      kidpar[ikid].flux = total( junk[w]*gauss_w8[w])/total(gauss_w8[w]^2)
   endif
endfor

;; Sub selection of kids if requested
make_ct, 3, ct
xra = [-1,1]*250
yra = [-1,1]*250
phi = dindgen(100)/99.*2*!dpi

if keyword_set(discard_outlyers) then begin
   nk_discard_outlyers, kidpar

   wind, 1, 1, /free, /large, iconic = param.iconic
   !p.multi=[0,2,2]
   kidpar.plot_flag = 0         ; init
   
   if not keyword_set(fwhm_min)   then fwhm_min   = 5.
   if not keyword_set(fwhm_max)   then fwhm_max   = 30.
   if not keyword_set(a_peak_min) then a_peak_min = 0.
   if not keyword_set(a_peak_max) then a_peak_max = max( kidpar.a_peak)
   if not keyword_set(ellipt_max) then ellipt_max = max( kidpar.ellipt)
   if not keyword_set(noise_max)  then noise_max  = max( kidpar.noise)
   if not keyword_set(ellipt_max) then ellipt_max = 5
;;   if not keyword_set(noise_max)  then noise_max = max( kidpar.noise)

   n_arrays = max(kidpar.array)-min(kidpar.array)+1
   for iarray=min(kidpar.array), max(kidpar.array) do begin
      wk = where( kidpar.array eq iarray, nwk)

      wtest = where( kidpar.array eq iarray and $
                     kidpar.type eq 1 and $
                     kidpar.fwhm ge fwhm_min and $
                     kidpar.fwhm le fwhm_max and $
                     kidpar.a_peak ge a_peak_min and $
                     kidpar.a_peak le a_peak_max and $
                     kidpar.ellipt le ellipt_max, nwtest, compl=w_discard, ncompl=nw_discard)
      
      if nw_discard ne 0 then kidpar[w_discard].plot_flag = 1

      plot, xra, yra, /iso, /nodata, xtitle='Nasmyth x', ytitle='Nasmyth y'
      legendastro, ['Array '+strtrim(iarray,2), $
                    'beam display diameter = FWHM', $
                    'All kids', 'To keep'], box=0, textcol=[0,0,0,ct[iarray-1]]
      oplot, kidpar[wk].nas_x, kidpar[wk].nas_y, psym=1
      oplot, kidpar[wtest].nas_x, kidpar[wtest].nas_y, psym=1, col=ct[iarray-1]
      for ii=0, nwk-1 do $
         oplot, kidpar[wk[ii]].nas_x + kidpar[wk[ii]].fwhm/2*cos(phi), $
                kidpar[wk[ii]].nas_y + kidpar[wk[ii]].fwhm/2*sin(phi)
      for ii=0, nwtest-1 do $
         oplot, kidpar[wtest[ii]].nas_x + kidpar[wtest[ii]].fwhm/2*cos(phi), $
                kidpar[wtest[ii]].nas_y + kidpar[wtest[ii]].fwhm/2*sin(phi), col=ct[iarray-1]

      ;; ;; derive simple statistics on non-absurd kids to flag out outlyers
      ;; med   = median( kidpar[wtest].(ifield))
      ;; sigma = stddev( kidpar[wtest].(ifield))
      ;; w = where( finite(kidpar.(ifield)) ne 1 or abs(kidpar.(ifield)-med) gt 4*sigma, nw)
      ;; if nw ne 0 then kidpar[w].plot_flag = 1

   endfor
   
endif else begin
   wind, 1, 1, /free, iconic = param.iconic
   make_ct, 3, ct
   plot, xra, yra, /iso, /nodata, xtitle='Nasmyth x', ytitle='Nasmyth y'
   for i=1, 3 do begin
      w = where( kidpar.array eq i, nw)
      if nw ne 0 then begin
         oplot, kidpar[w].nas_x, kidpar[w].nas_y, psym=1, col=ct[i-1]
         for ii=0, nw-1 do $
            oplot, kidpar[w[ii]].nas_x + kidpar[w[ii]].fwhm/2*cos(phi), $
                   kidpar[w[ii]].nas_y + kidpar[w[ii]].fwhm/2*sin(phi), col=ct[i-1]
      endif
      legendastro, ['Array 1', 'Array 2', 'Array 3'], psym=1, $
                   textcol=ct, col=ct, box=0
   endfor
endelse

;; Absolute Calibration (Relative only here since t_planet is unknown
;; and data are median_filtered)
nk_planet_calib, param, data, kidpar

;; Noise and sensitivity estimation (same commment as for
;; "absolute" calibration"
;; NEEDS TO BE DONE ARRAY BY ARRAY
;; ktn_noise_estim

;; Take the power spectrum on the 2 most quiet minutes
n_2mn = 2*60.*!nika.f_sampling
nsn_noise = 2L^round( alog(n_2mn)/alog(2))
wk = where( kidpar.type eq 1, nwk)
for i=0, nwk-1 do begin
   ikid = wk[i]
   rms  = 1e10
   ixp  = 0
   while (ixp+nsn_noise-1) lt nsn do begin
      d = reform( data[ixp:ixp+nsn_noise-1].toi[ikid])
      if stddev(d) lt rms then ix1 = ixp
      ixp += nsn_noise
   endwhile
   
   power_spec, data[ix1:ix1+nsn_noise-1].toi[ikid] - $
               my_baseline( data[ix1:ix1+nsn_noise-1].toi[ikid]), !nika.f_sampling, pw, freq
   wf = where( freq gt 4.d0)
   kidpar[ikid].noise = avg(pw[wf]) ; Hz/sqrt(Hz) since data is in Hz

   wf = where( abs(freq-1.d0) lt 0.2, nwf)
   if nwf ne 0 then kidpar[ikid].noise_1hz = avg(pw[wf])
   wf = where( abs(freq-2.d0) lt 0.2, nwf)
   if nwf ne 0 then kidpar[ikid].noise_2hz = avg(pw[wf])
   wf = where( abs(freq-10.d0) lt 1, nwf)
   if nwf ne 0 then kidpar[ikid].noise_10hz = avg(pw[wf])
endfor

;; Derive sensitivity
kidpar.sensitivity_decorr  = kidpar.calib * kidpar.noise * 1000 ; Jy/Hz x Hz/sqrt(Hz) x 1000 = mJy/sqrt(Hz) x 1
kidpar.sensitivity_decorr /= sqrt(2.d0) ; /Hz^1/2 to s^1/2

kidpar_out = kidpar

t1 = systime(0,/sec)
if param.cpu_time then message, /info, "CPU Time: "+strtrim(t1-cpu_time_0,2)

end
