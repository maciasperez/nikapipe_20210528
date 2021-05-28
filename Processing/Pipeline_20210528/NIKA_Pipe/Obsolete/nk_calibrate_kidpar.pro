
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME:
;   nk_calibrate_kidpar
;
; CATEGORY:
;
; CALLING SEQUENCE:
;   nk_calibrate_kidpar, scan, source, kidpar_in_file, kidpar_out_file, $
;                         slow=slow, ptg_numdet_ref=ptg_numdet_ref, $
;                         xpeak_ref=xpeak_ref, ypeak_ref=ypeak_ref, RF=RF, fast=fast, undersamp=undersamp, $
;                         xml=xml, skydip_kidpar_file = skydip_kidpar_file, $
;                         noplot=noplot
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
;        - Sept 26th, 2014: NP (replaces otf_geometry from the old RTA package)
;        - Oct. 2nd, 2015: from Labtools/NP/Dev/my_final_kidpar.pro
;-
;================================================================================================

pro nk_calibrate_kidpar, scan, source, kidpar_in_file, kidpar_out_file, $
                         slow=slow, ptg_numdet_ref=ptg_numdet_ref, $
                         xpeak_ref=xpeak_ref, ypeak_ref=ypeak_ref, RF=RF, fast=fast, undersamp=undersamp, $
                         xml=xml, skydip_kidpar_file = skydip_kidpar_file, $
                         noplot=noplot, noskydip=noskydip, data=data, kidpar=kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence"
   print, "nk_calibrate_kidpar, scan, source, kidpar_in_file, kidpar_out_file, $"
   print, "                     slow=slow, ptg_numdet_ref=ptg_numdet_ref, $"
   print, "                     xpeak_ref=xpeak_ref, ypeak_ref=ypeak_ref, RF=RF, fast=fast, undersamp=undersamp, $"
   print, "                     xml=xml, skydip_kidpar_file = skydip_kidpar_file, $"
   print, "                     noplot=noplot, noskydip=noskydip"
   return
endif

if keyword_set(fast) then begin
   kidpar = mrdfits( kidpar_in_file,1)
   get_geometry_3, param, kidpar, ptg_numdet_ref
   nika_write_kidpar, kidpar, kidpar_out_file
   return
endif

nk_default_param,   param
param.fourier_opt_sample = 1
if keyword_set(noplot) then param.do_plot=0
param.map_reso = 5d0

nk_init_grid, param, grid
nk_default_info,    info

if keyword_set(RF) then param.math="RF"
if keyword_set(undersamp) then param.undersamp = undersamp

param.source = source
param.silent = 0

if keyword_set(undersamp) then param.undersamp=undersamp

param.plot_dir = !nika.plot_dir+"/"+scan
spawn, "mkdir -p "+param.plot_dir

nk_update_param_info, scan, param, info, xml=xml

;; Force kidpar to the current one and update param with scan infos
param.file_kidpar = kidpar_in_file

;; -----------------------------------------------------------------------------------
;; Perform all operations on data that are not projection nor cleaning dependent
;; Explode nk_scan_preproc to avoid the calibration at this stage

;; Get the data and KID parameters
if keyword_set(feb15) then param.readdata_feb15 = 1
nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max, xml=xml

;; Compute individual kid pointing once for all
;; Needed here for simulations
nk_get_kid_pointing, param, info, data, kidpar

;; Deglitch
nk_deglitch, param, info, data, kidpar
;; ------------------------------------------------------------------------------------

;; Put skydip coefficients if available
if keyword_set(skydip_kidpar_file) then begin
   kidpar_skydip = mrdfits( skydip_kidpar_file, 1)
   for i=0, n_elements(kidpar)-1 do begin
      w = where( kidpar_skydip.numdet eq kidpar[i].numdet, nw)
      if nw ne 0 then begin
         kidpar[i].c0_skydip = kidpar_skydip[w].c0_skydip
         kidpar[i].c1_skydip = kidpar_skydip[w].c1_skydip
      endif
   endfor
   param.do_opacity_correction = 1 ; make sure (it is sometimes forced to 0 in rta when no skydip is available yet)

   ;; Compute opacity and affect it to kidpar
   nk_get_opacity, param, info, data, kidpar
endif

;; If the planet is not centered, make a first iteration map to locate it, then
;; mask for optimal decorrelation
if keyword_set(slow) then begin
   data_copy = data

   ;; Apply the preliminary calibration derived when the kids where selected in
   ;; Katana.
   ;; It differs from the future absolute calibration but it's a good
   ;; relative calibration that can be used for the map projections.
   param.do_opacity_correction = 0
   nk_apply_calib, param, info, data, kidpar

   ;; Makes no assumption about the source location, make a first map to locate
   ;; it, then iterate to have the best calibration.
   grid.mask_source = 1.d0      ; make sure
   param.decor_method = "common_mode"
   nk_scan_reduce, param, info, data, kidpar, grid
   ;;nk_projection_3, param, info, data, kidpar, grid
   nk_projection_4, param, info, data, kidpar, grid
   
   ;; Quicklook and fit the planet position
   wind, 1, 1, /free, xs=1500, ys=900, iconic = param.iconic
   my_multiplot, 3, 1, pp, pp1, gap_x=0.1, xmargin=0.1
   grid_tags = tag_names(grid)
   p       = 0.d0
   xsource = 0.d0
   ysource = 0.d0
   for iarray=1, 3 do begin
      wh = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2))
      if max(grid.(wh)) gt 0 then begin
         wt   = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2))
         wvar = where( strupcase(grid_tags) eq "MAP_VAR_I"+strtrim(iarray,2))
         nk_map_photometry, grid.(wt), grid.(wvar), grid.(wh), $
                            grid.xmap, grid.ymap, !nika.fwhm_array[iarray-1], $
                            flux_1mm, sigma_flux_1mm, $
                            sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                            bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                            /educated, ps_file=ps_file, position=pp1[iarray-1,*], $
                            k_noise=k_noise, noplot=noplot, param=param, $
                            title=param.scan+" A"+strtrim(iarray,2)+" (1st iteration) [Hz]"

         xsource += output_fit_par_1mm[4]
         ysource += output_fit_par_1mm[5]
         p       += 1.d0
      endif
   endfor
   xsource /= p
   ysource /= p
   d = sqrt( (grid.xmap-xsource)^2 + (grid.ymap-ysource)^2)

   ;; restore original (uncalibrated, still in Hz) data for the next decorrelation
   data = data_copy
endif else begin
   ;; Assume directly that the source is very close from the center
   d = sqrt( (grid.xmap)^2 + (grid.ymap)^2)
endelse

;; Derive mask
w = where( d lt 2*!nika.fwhm_nom[1], nw)
if nw eq 0 then begin
   message, /info, "Wrong planet position"
   stop
endif else begin
   grid.mask_source[w] = 0.d0
endelse

;; Keep all kids for individual maps (make sure)
param.flag_uncorr_kid = 0
param.flag_sat        = 0
param.flag_ovlap      = 0

;; Final decorrelation, HWP template subtraction if polarized scan
param.decor_method = "common_mode_kids_out"
nk_scan_reduce, param, info, data, kidpar, grid, subtract_maps=subtract_maps

;;----------------------------------------------------
;; Recompute offsets with this new decorrelation, improved w.r.t katana's
;; median_simple.

;; recentering done in Katana, not necessary here ?
;; data.ofs_az -= avg( data.ofs_az)
;; data.ofs_el -= avg( data.ofs_el)

;; Compute Nasmyth offsets once for all
azel2nasm, data.el, data.ofs_az, data.ofs_el, ofs_nasx, ofs_nasy

;; Maps in Az,el
w8 = data.ofs_az*0.d0 + 1.d0
xra = minmax(data.ofs_az)
yra = minmax(data.ofs_el)
param.map_xsize = (xra[1]-xra[0])*1.1
param.map_ysize = (yra[1]-yra[0])*1.1
nk_init_grid, param, grid_azel
wkill = where( finite(ofs_az) eq 0 or finite(ofs_el) eq 0, nwkill)
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
ipix_azel = ipix
get_bolo_maps_6, toi, ipix_azel, w8, kidpar, grid_azel, map_list_azel

;; Maps in Nasmyth
xra1  = minmax(ofs_nasx)
yra1  = minmax(ofs_nasy)
param.map_xsize = (xra1[1]-xra1[0])*1.1
param.map_ysize = (yra1[1]-yra1[0])*1.1
nk_init_grid, param, grid_nasmyth
;get_bolo_maps_2, data.toi, ofs_nasx, ofs_nasy, w8, kidpar, grid_nasmyth, map_list_nasmyth, map_var_list_nasmyth
get_bolo_maps_5, data.toi, data.ipix_nasmyth, w8, kidpar, grid_azel, map_list_nasmyth, nhits_nasmyth

;; Get beam properties in (az,el)
w1 = where( kidpar.type eq 1, nw1)
beam_guess, map_list_azel, $
            grid_azel.xmap, $
            grid_azel.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_1, theta_1, rebin=2, $
            verbose=verbose, noplot=noplot, $
            method="nika"
kidpar.x_peak       = x_peaks_1
kidpar.y_peak       = y_peaks_1
kidpar.x_peak_azel  = x_peaks_1
kidpar.y_peak_azel  = y_peaks_1

;; Compute also in Nasmyth to avoid pixelization errors that sometimes finds
;; beams way out of the Focal Plane
beam_guess, map_list_nasmyth, $
            grid_nasmyth.xmap, $
            grid_nasmyth.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_1, theta_1, rebin=2, $
            verbose=verbose, parinfo=parinfo, noplot=noplot, $
            method="nika"
kidpar.a_peak = a_peaks_1
kidpar.x_peak_nasmyth = x_peaks_1
kidpar.y_peak_nasmyth = y_peaks_1
kidpar.nas_x          = x_peaks_1
kidpar.nas_y          = y_peaks_1
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
      case kidpar[ikid].array of
         1: sigma_gauss = !nika.fwhm_nom[0]*!fwhm2sigma
         2: sigma_gauss = !nika.fwhm_nom[1]*!fwhm2sigma
         3: sigma_gauss = !nika.fwhm_nom[0]*!fwhm2sigma
      endcase
      d        = sqrt( (grid_nasmyth.xmap-kidpar[ikid].x_peak_nasmyth)^2 + (grid_nasmyth.ymap-kidpar[ikid].y_peak_nasmyth)^2)
      gauss_w8 = exp( -d^2/(2.d0*sigma_gauss^2))
;;       junk     = reform( map_list_nasmyth[ikid,*,*])
;;       w        = where( finite(junk) eq 1)
;;       kidpar[ikid].flux = total( junk[w]*gauss_w8[w])/total(gauss_w8[w]^2)
      map     = reform( map_list_nasmyth[    ikid,*,*])
;;      map_var = reform( map_var_list_nasmyth[ikid,*,*])
      map_var = map*0.d0
      w = where( nhits_nasmyth ne 0, nw)
      map_var[w] = reform( 1.d0/nhits_nasmyth[w]) ; yes, var goes like 1/n, not 1/sqrt(n)
      nk_ata_fit_beam, map, map_var, gauss_w8, info, flux, sigma_flux
      kidpar[ikid].flux = flux
   endif
endfor
;;----------------------------------------------------

;; Recompute center of rotation with the final Nasmyth offsets
get_geometry_3, param, kidpar, ptg_numdet_ref
kidpar.nas_x_offset_ref = info.nasmyth_offset_x
kidpar.nas_y_offset_ref = info.nasmyth_offset_y

;; Account for elevation dependent gain of the telescope
if keyword_set(noskydip) then param.do_opacity_correction = 0 else param.do_opacity_correction = 1
nk_get_opacity, param, info, data, kidpar
nk_tel_gain_cor, param, info, data, kidpar

;; Absolute calibration accounting for kidpar.tau_skydip computed when the
;; skydip kidpar was read
nk_planet_calib, param, data, kidpar
nk_apply_calib, param, info, data, kidpar

;; Recompute pointing now that the center of rotation has been determined
nk_get_kid_pointing, param, info, data, kidpar
nk_get_ipix, data, info, grid
;; Project
nk_projection_3, param, info, data, kidpar, grid

;; Plot
lambda_min = min(kidpar.array)
lambda_max = max(kidpar.array)
wind, 1, 1, /free, xs=1200, ys=900, iconic = param.iconic
outplot, file=param.plot_dir+"/FocalPlane", png=png, ps=ps
if lambda_min ne lambda_max then !p.multi=[0,2,1]

phi = dindgen(200)/199.*2.d0*!dpi
for lambda=lambda_min, lambda_max do begin
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1

   xra = minmax( kidpar[w1].nas_x)
   xra = xra + [-0.2,0.2]*(xra[1]-xra[0])
   yra = minmax( kidpar[w1].nas_y)
   yra = yra + [-0.2,0.2]*(yra[1]-yra[0])
   
   plot, kidpar[w1].nas_x, kidpar[w1].nas_y, psym=1, /iso, $
         xra=xra, yra=yra, /xs, /ys, title=scan, xtitle='Arcsec', ytitle='Arcsec'
   for i=0, nw1-1 do begin
      ikid = w1[i]
      xx1  = kidpar[ikid].sigma_x*cos(phi)*0.5    ; 0.5 to have diameter=sigma, not radius
      yy1  = kidpar[ikid].sigma_y*sin(phi)*0.5    ; 0.5 to have diameter=sigma, not radius
      x1   =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
      y1   =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
      oplot, kidpar[ikid].nas_x+x1, kidpar[ikid].nas_y+y1
   endfor

   legendastro, [strtrim(lambda,2)+" mm", $
                 '1!7r!3 radius contours'], box=0, /right
endfor
outplot, /close

;; Apply the correct photometry
if strupcase(param.source) eq "URANUS"  then begin
   flux_source_1mm = !nika.flux_uranus[0]
   flux_source_2mm= !nika.flux_uranus[1]
endif
if strupcase(param.source) eq "MARS"  then begin
   flux_source_1mm = !nika.flux_mars[0]
   flux_source_2mm= !nika.flux_mars[1]
endif
if strupcase(param.source) eq "NEPTUNE"  then begin
   flux_source_1mm = !nika.flux_neptune[0]
   flux_source_2mm= !nika.flux_neptune[1]
endif
if strupcase(param.source) eq "SATURN"  then begin
   flux_source_1mm = !nika.flux_saturn[0]
   flux_source_2mm= !nika.flux_saturn[1]
endif
if strupcase(param.source) eq "SATURN"  then begin
   flux_source_1mm = !nika.flux_saturn[0]
   flux_source_2mm= !nika.flux_saturn[1]
endif

fwhm_1mm = !nika.fwhm_nom[0]
wind, 1, 1, /free, /large, iconic = param.iconic
my_multiplot, 2, 1, pp, pp1
nk_map_photometry, grid.map_i_1mm, grid.map_var_i_1mm, grid.nhits_1mm, $
                   grid.xmap, grid.ymap, fwhm_1mm, $
                   flux_1mm, sigma_flux_1mm, $
                   sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                   bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                   coltable=coltable, imrange=imrange_i_mm, position=pp1[0,*], $
                   educated=educated, title='1mm (uncorrected)', ps_file=ps_file, $
                   k_noise=k_noise, param=param, NEFD_source=nefd_1mm
nk_list_kids, kidpar, lambda = 1, valid = w1
rho1 = flux_source_1mm/flux_1mm
kidpar[w1].calib          *= rho1
kidpar[w1].calib_fix_fwhm *= rho1

fwhm_2mm = !nika.fwhm_nom[1]
wind, 1, 1, /free, /xlarge, iconic = param.iconic
nk_map_photometry, grid.map_i_2mm, grid.map_var_i_2mm, grid.nhits_2mm, $
                   grid.xmap, grid.ymap, fwhm_2mm, $
                   flux_2mm, sigma_flux_2mm, $
                   sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
                   bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
                   coltable=coltable, imrange=imrange_i_mm, position=pp1[1,*], $
                   educated=educated, title='2mm (uncorrected)', ps_file=ps_file, $
                   k_noise=k_noise, param=param, NEFD_source=nefd_2mm
nk_list_kids, kidpar, lambda = 2, valid = w1
rho2 = flux_source_2mm/flux_2mm
kidpar[w1].calib          *= rho2
kidpar[w1].calib_fix_fwhm *= rho2

;; Correct the display to have a clue on sensitivity
erase
nk_map_photometry, grid.map_i_1mm*rho1, grid.map_var_i_1mm*rho1^2, grid.nhits_1mm, $
                   grid.xmap, grid.ymap, fwhm_1mm, $
                   flux_1mm, sigma_flux_1mm, $
                   sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                   bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                   coltable=coltable, imrange=imrange_i_mm, position=pp1[0,*], $
                   educated=educated, title='1mm (corrected)', ps_file=ps_file, $
                   k_noise=k_noise, param=param, NEFD_source=nefd_1mm


;; Correct the display to have a clue on sensitivity
nk_map_photometry, grid.map_i_2mm*rho2, grid.map_var_i_2mm*rho2^2, grid.nhits_2mm, $
                   grid.xmap, grid.ymap, fwhm_2mm, $
                   flux_2mm, sigma_flux_2mm, $
                   sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
                   bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
                   coltable=coltable, imrange=imrange_i_mm, position=pp1[1,*], $
                   educated=educated, title='2mm (corrected)', ps_file=ps_file, $
                   k_noise=k_noise, param=param, NEFD_source=nefd_2mm


;; Write to disk
nika_write_kidpar, kidpar, kidpar_out_file

end
