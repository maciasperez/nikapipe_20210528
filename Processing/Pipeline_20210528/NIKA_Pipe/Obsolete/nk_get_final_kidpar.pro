
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; nk_get_final_kidpar
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_get_final_kidpar, scan, kidpar, skydip_scan=skydip_scan
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
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sept 26th, 2014: NP (replaces otf_geometry from the old RTA package)
;-
;================================================================================================

pro nk_get_final_kidpar, scan, source, kidpar_in_file, kidpar_out_file, $
                         slow=slow, skydip_scan=skydip_scan, ptg_numdet_ref=ptg_numdet_ref, $
                         xpeak_ref=xpeak_ref, ypeak_ref=ypeak_ref, RF=RF, fast=fast, undersamp=undersamp, $
                         xml=xml, keep_offsets=keep_offsets, kidpar_skydip_file = kidpar_skydip_file

if keyword_set(fast) then begin
   kidpar = mrdfits( kidpar_in_file,1)
   get_geometry_3, param, kidpar, ptg_numdet_ref
   nika_write_kidpar, kidpar, kidpar_out_file
endif else begin

   nk_default_param,   param
   nk_init_grid, param, grid
   nk_default_info,    info

   if keyword_set(RF) then param.math="RF"
   if keyword_set(undersamp) then param.undersamp = undersamp

   param.source = source
   param.silent = 0
   if keyword_set(undersamp) then param.undersamp=undersamp

   param.plot_dir = !nika.plot_dir+"/"+scan
   spawn, "mkdir -p "+param.plot_dir

   nk_update_scan_param, scan, param, info

;; Force kidpar to the current one and update param with scan infos
   param.file_kidpar = kidpar_in_file

;;-----------------------------------------------------------------------------------
;; Perform all operations on data that are not projection nor cleaning dependent
;nk_scan_preproc, param, info, data, kidpar, $
;                 sn_min=sn_min_list[iscan], sn_max=sn_max_list[iscan]
;; Explode nk_scan_preproc to avoid the calibration at this stage
   
;; Get the data and KID parameters
   nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max, xml=xml

;; Compute individual kid pointing once for all
;; Needed here for simulations
   nk_get_kid_pointing, param, info, data, kidpar

;; Deglitch
   nk_deglitch, param, info, data, kidpar
;;------------------------------------------------------------------------------------

;; Put skydip coefficients if available
;;   if keyword_set(skydip_scan) then begin
;;      ;nk_skydip, skydip_scan, kidpar = kidpar_skydip
;;      scan2daynum, skydip_scan, skydip_day, skydip_scan_num
;;      nk_skydip_2, skydip_scan_num, skydip_day, kidpar_skydip
   if keyword_set(kidpar_skydip_file) then begin
      kidpar_skydip = mrdfits( kidpar_skydip_file, 1)
      for i=0, n_elements(kidpar)-1 do begin
         w = where( kidpar_skydip.numdet eq kidpar[i].numdet, nw)
         if nw ne 0 then begin
            kidpar[i].c0_skydip = kidpar_skydip[w].c0_skydip
            kidpar[i].c1_skydip = kidpar_skydip[w].c1_skydip
         endif
      endfor
      param.do_opacity_correction = 1 ; make sure (it is sometimes forced to 0 in rta when no skydip is available yet)
      nk_get_opacity, param, info, data, kidpar
   endif

;; If the planet is not centered, make a first iteration map to locate it, then
;; mask for optimal decorrelation
   if keyword_set(slow) then begin
      data_copy = data

      ;; Apply the preliminary calibration derived when the kids where selected in
      ;; Katana.
      ;; It differs from the future absolute calibrtion but it's a good
      ;; proxy to relative calibration that can be used for the map projections.
      nk_apply_calib, param, info, data, kidpar

      ;; Makes no assumption about the source location, make a first map to locate
      ;; it, then iterate to have the best calibration.
      grid.mask_source = 1.d0 ; make sure
      param.decor_method = "common_mode"
      nk_scan_reduce, param, info, data, kidpar, grid
      nk_projection_3, param, info, data, kidpar, grid

      ;; Quicklook and fit the planet position
      map_var  = double(finite(grid.map_w8_1mm))*0.d0
      w        = where( grid.map_w8_1mm gt 0, nw)
      if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_1mm[w]

      wind, 1, 1, /free, xs=1500, ys=900
      my_multiplot, 2, 1, pp, pp1, gap_x=0.1, xmargin=0.1
      nk_map_photometry, grid.map_i_1mm, map_var, grid.nhits_1mm, $
                         grid.xmap, grid.ymap, param.input_fwhm_1mm, $
                         flux_1mm, sigma_flux_1mm, $
                         sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                         bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                         /educated, ps_file=ps_file, position=pp1[0,*], $
                         k_noise=k_noise, noplot=noplot, param=param, $
                         title=param.scan+" 1mm (1st iteration) [Hz]"

      map_var  = double(finite(grid.map_w8_2mm))*0.d0
      w        = where( grid.map_w8_2mm gt 0, nw)
      if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_2mm[w]
      nk_map_photometry, grid.map_i_2mm, map_var, grid.nhits_2mm, $
                         grid.xmap, grid.ymap, param.input_fwhm_2mm, $
                         flux_2mm, sigma_flux_2mm, $
                         sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
                         bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
                         /educated, ps_file=ps_file, position=pp1[1,*], $
                         k_noise=k_noise, noplot=noplot, param=param, $
                         title=param.scan+" 2mm (1st iteration) [Hz]"

      xsource = (output_fit_par_1mm[4]+output_fit_par_2mm[4])/2.
      ysource = (output_fit_par_1mm[5]+output_fit_par_2mm[5])/2.
      d = sqrt( (grid.xmap-xsource)^2 + (grid.ymap-ysource)^2)

      ;; restore original (uncalibrated, still in Hz) data for the next decorrelation
      data = data_copy
      message, /info, ""
      message, /info, "Check these maps"
      stop
   endif else begin
      ;; Assume directly that the source is very close from the center
      d = sqrt( (grid.xmap)^2 + (grid.ymap)^2)
   endelse

;; Derive mask
   w = where( d lt 1.5*!nika.fwhm_nom[1], nw)
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

;; Final decorrelation
   param.decor_method = "common_mode_kids_out"
   nk_scan_reduce, param, info, data, kidpar, grid, subtract_maps=subtract_maps

;; Account for elevation dependent gain of the telescope
   nk_tel_gain_cor, param, info, data, kidpar

;; Valid samples
   w = where( data.scan_valid[0] eq 0, nw)
   if nw eq 0 then begin
      message, /info, "no valid sample."
      stop
   endif

;; Make individual maps in Az, El
   param.map_reso = 6. ; a bit larger than the 4 arcsec elevation step

   xra = minmax(data[w].ofs_az)
   yra = minmax(data[w].ofs_el)
   param.map_xsize = (xra[1]-xra[0])*1.1
   param.map_ysize = (yra[1]-yra[0])*1.1
   nk_init_grid, param, grid_azel
   get_bolo_maps_3, data.toi, data.ofs_az, data.ofs_el, data.w8, kidpar, grid_azel, map_list_azel, map_var_list_azel

;; Map in Nasmyth
   azel2nasm, data.el, data.ofs_az, data.ofs_el, ofs_nasx, ofs_nasy
   xra1  = minmax(ofs_nasx[w])
   yra1  = minmax(ofs_nasy[w])
   param.map_xsize = (xra1[1]-xra1[0])*1.1
   param.map_ysize = (yra1[1]-yra1[0])*1.1
   nk_init_grid, param, grid_nasmyth
   get_bolo_maps_3, data.toi, ofs_nasx, ofs_nasy, data.w8, kidpar, grid_nasmyth, map_list_nasmyth, map_var_list_nasmyth

;; Derive beam parameters
   beam_guess, map_list_azel, grid_azel.xmap, grid_azel.ymap, kidpar, $
               x_peaks_azel, y_peaks_azel, a_peaks_azel, sigma_x_azel, sigma_y_azel, $
               beam_list_azel, theta_azel, /noplot

   beam_guess, map_list_nasmyth, grid_nasmyth.xmap, grid_nasmyth.ymap, kidpar, $
               x_peaks, y_peaks, a_peaks, sigma_x, sigma_y, $
               beam_list, theta, /noplot

;; Re-center beams on the reference kid.
   ikid_ref = where( kidpar.type eq 1 and kidpar.nas_x eq 0 and kidpar.nas_y eq 0, nkid_ref)
   if nkid_ref eq 0 then begin
      message, /info, ""
      print, "No ref kid ?!"
      stop
   endif
   xpeak_ref = x_peaks[ikid_ref[0]]
   ypeak_ref = y_peaks[ikid_ref[0]]
   w1 = where( kidpar.type eq 1)
   x_peaks[w1] -= xpeak_ref
   y_peaks[w1] -= ypeak_ref

   ;; Update kidpar here for nika_pipe_calib and so on
   if not keyword_set(keep_offsets) then begin
      kidpar[w1].nas_x          = x_peaks[w1]
      kidpar[w1].nas_y          = y_peaks[w1]
      kidpar[w1].x_peak_nasmyth = x_peaks[w1]
      kidpar[w1].y_peak_nasmyth = y_peaks[w1]
      kidpar[w1].x_peak_azel    = x_peaks_azel[w1]
      kidpar[w1].y_peak_azel    = y_peaks_azel[w1]
   endif
   kidpar[w1].a_peak         = a_peaks[w1]
   kidpar[w1].sigma_x        = sigma_x[w1]
   kidpar[w1].sigma_y        = sigma_y[w1]
   kidpar[w1].fwhm_x         = sigma_x[w1]/!fwhm2sigma
   kidpar[w1].fwhm_y         = sigma_y[w1]/!fwhm2sigma
   kidpar[w1].fwhm           = sqrt( sigma_x[w1]*sigma_y[w1])/!fwhm2sigma
   kidpar[w1].theta          = theta[w1]

   get_geometry_3, param, kidpar, ptg_numdet_ref

;; Fit peak amplitude with the fixed nominal FWHM
   ata      = dblarr(2,2)
   atd      = dblarr(2)
   for ikid=0, n_elements(kidpar)-1 do begin
      if kidpar[ikid].type eq 1 then begin
         if kidpar[ikid].array eq 1 then $
            sigma_gauss = !nika.fwhm_nom[0]*!fwhm2sigma else $
               sigma_gauss = !nika.fwhm_nom[1]*!fwhm2sigma

         d        = sqrt( (grid_nasmyth.xmap-x_peaks[ikid])^2 + (grid_nasmyth.ymap-y_peaks[ikid])^2)
         gauss_w8 = exp( -d^2/(2.d0*sigma_gauss^2))
         map     = reform( map_list_nasmyth[    ikid,*,*])
         map_var = reform( map_var_list_nasmyth[ikid,*,*])
         w        = where( finite(map) eq 1 and map_var gt 0, nw)
         if nw eq 0 then begin
            message, /info, "Only infinite values for ikid/numdet: "+strtrim(ikid,2)+"/"+strtrim(kidpar[ikid].numdet,2)
            stop
         endif

         ata[0,0] = total( 1.d0/map_var[w])
         ata[1,0] = total( gauss_w8[w]/map_var[w])
         ata[0,1] = ata[1,0]
         ata[1,1] = total( gauss_w8[w]^2/map_var[w])
         atd[0]   = total( map[w]/map_var[w])
         atd[1]   = total( gauss_w8[w]*map[w]/map_var[w])
         atam1    = invert(ata)
         s        = atam1##atd
         
         kidpar[ikid].flux       = s[1] ; Hz
      endif
   endfor

;; Absolute calibration
;   nika_pipe_planet_calib, param, data, kidpar
nk_planet_calib, param, data, kidpar

;; Write to disk
   nika_write_kidpar, kidpar, kidpar_out_file

;; Plot
   lambda_min = min(kidpar.array)
   lambda_max = max(kidpar.array)
   wind, 1, 1, /free, xs=1200, ys=900
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
         xx1  = kidpar[ikid].sigma_x*cos(phi)*0.5 ; 0.5 to have diameter=sigma, not radius
         yy1  = kidpar[ikid].sigma_y*sin(phi)*0.5 ; 0.5 to have diameter=sigma, not radius
         x1   =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
         y1   =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
         oplot, kidpar[ikid].nas_x+x1, kidpar[ikid].nas_y+y1
      endfor

      legendastro, [strtrim(lambda,2)+" mm", $
                    '1!7r!3 radius contours'], box=0, /right
   endfor
   outplot, /close
endelse

end
