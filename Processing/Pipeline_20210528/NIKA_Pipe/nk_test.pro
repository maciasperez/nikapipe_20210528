;+
; SOFTWARE: NIKA pipeline
;
; NAME:
;       nk_test
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;         nk, scan_list, param, info
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software. It launches the reduction of each scan of scan_list
;        and averages the output maps into the final one using inverse
;        variance noise weighting.
; 
; INPUT: 
;        - scan_list : e.g. ['20140221s0024', '20140221s0025', '20140221s0026']
;        - param: the pipeline parameters
;        - info: must be passed in input to allow for mask_source
; 
; OUTPUT: 
;        - info
; 
; KEYWORDS:
;        - filing: if set, we run the pipeline in a mode where it processes only
;          files for which a companion with prefix UP_ exists.
;        - polar: set to make the intensity I and polarization Q,U maps
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 17/06/2014: creation (Nicolas Ponthieu, Remi Adam, Alessia Ritacco). The NIKA offline reduction (mainly
;        nika_pipe_launch.pro and nika_anapipe_launch.pro) are put
;        together in this software
;-

pro nk_test, scan_list_in, param=param, info=info, $
        filing=filing, data=data, kidpar=kidpar, $
        print_status=print_status, grid=grid, $
        simpar=simpar, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
        subtract_maps=subtract_maps, no_output_map=no_output_map, prism=prism, $
        parity=parity, force_file=force_file, xml = xml, $
        kill_subscan = kill_subscan, show_maps_only=show_maps_only, results_filing=results_filing, $
        lab=lab, input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel, nas_center=nas_center, $
        list_detector=list_detector, xguess=xguess, yguess=yguess, polar=polar, $
        raw_acq_dir=raw_acq_dir, header=header, astr=astr

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " nk, scan_list_in, param=param, info=info, $"
   print, "     filing=filing, data=data, kidpar=kidpar, $"
   print, "     print_status=print_status, grid=grid, $"
   print, "     simpar=simpar, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $"
   print, "     subtract_maps=subtract_maps, no_output_map=no_output_map, prism=prism, $"
   print, "     parity=parity, force_file=force_file, xml = xml, $"
   print, "     kill_subscan = kill_subscan, show_maps_only=show_maps_only, results_filing=results_filing, $"
   print, "     lab=lab, input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel, katana=katana"
   return
endif

xml=0  ; FXD  to be fixed
if not keyword_set(sn_min_list) then sn_min_list = lonarr( n_elements(scan_list_in))
if not keyword_set(sn_max_list) then sn_max_list = lonarr( n_elements(scan_list_in))

if n_elements(sn_min_list) ne n_elements(sn_max_list) then begin
   message, /info, "sn_min_list and sn_max_list must have the same size."
   return
endif
if n_elements(sn_min_list) ne n_elements(scan_list_in) then begin
   message, /info, "sn_min_list must have the same size as scan_list_in."
   return
endif

;; Check if the scans are fine and returns the good scans
if not keyword_set(force_file) then begin
   scan_list = scan_list_in
   nscans = n_elements(scan_list)
   ok_scans = indgen(nscans)
   if nscans eq 0 then begin
      nk_error, info, "No valid scans were selected"
      return
   endif
   sn_min_list = sn_min_list[ok_scans]
   sn_max_list = sn_max_list[ok_scans]
endif else begin
   nscans = 1
   scan_list = scan_list_in
endelse

;; nk_default_param, nk_default_info and nk_init_grid create
;; @^ param, info and grid if they have not been passed in input
if not keyword_set(param) then nk_default_param,   param
if not keyword_set(info)  then nk_default_info, info

init_grid_done = 0
;;if not keyword_set(grid)  then nk_init_grid, param, info, grid, header=header
;; if keyword_set(grid) then begin
;;    init_grid_done = 1
;;    if strupcase(param.map_proj) eq "RADEC" then begin
;;       s = size(grid.xmap)
;;       nx = s[1]
;;       ny = s[2]
;;       xmin = (-nx/2-0.5)*param.map_reso
;;       ymin = (-ny/2-0.5)*param.map_reso
;;       crpix = double( [nx/2+1, ny/2+1])
;;       astr = create_struct("naxis", [nx, ny], $
;;                            "cd", double( [[1,0], [0,1]]), $
;;                            "cdelt", [-1.d0, 1.d0]*param.map_reso/3600.d0, $
;;                            "crpix", crpix, $
;;                            "crval", double([param.map_center_ra, param.map_center_dec]), $
;;                            "ctype", ["RA---TAN", "DEC--TAN"], $
;;                            "longpole", 180.d0, $
;;                            "latpole", 90.d0, $
;;                            "pv2", dblarr(2))
;;    endif
;; endif else begin
;;    init_grid_done = 0
;; endelse

if keyword_set(polar) then param.polar = 1
if strupcase(param.map_proj) eq "NASMYTH" then !mamdlib.coltable = 3
if keyword_set(lab) then param.lab = 1
if param.latex_pdf eq 1 then param.plot_ps = 1
if param.plot_png and param.plot_ps then param.plot_png = 0
if strlen( param.plot_dir) eq 0 then param.plot_dir = param.project_dir+"/Plots"
;; @ Creates the necessary directories for output products and plots
spawn, "mkdir -p "+param.project_dir
spawn, "mkdir -p "+param.project_dir+"/UP_files"
spawn, "mkdir -p "+param.project_dir+"/Plots"
spawn, "mkdir -p "+param.plot_dir
spawn, "mkdir -p "+param.preproc_dir

;; Sanity checks
if keyword_set(lkg_kernel) then begin
   lkg_reso = abs(lkg_kernel.xmap[1,0]-lkg_kernel.xmap[0,0])
   if lkg_reso ne param.map_reso then begin
      nk_error, info, "lkg maps resolution must be the same as param.map_reso"
      return
   endif
endif

;;---------------------------------------------------------------------------------
;; Main loop
random_string = strtrim( long( abs( randomu( seed, 1)*1e8)),2)
error_report_file = param.project_dir+"/error_report_"+random_string+".dat"

for iscan=0, nscans-1 do begin
   ;;message, /info, "iscan/nscans-1: "+strtrim(iscan,2)+", "+strtrim(nscans-1,2)+", "+strtrim(scan_list[iscan],2)

;;   ;; to adjust to NIKA2a and Run13 configuration
;;   nk_scan2run, scan_list[iscan], run
;;   if keyword_set(raw_acq_dir) then !nika.raw_acq_dir = raw_acq_dir
   
   ;; Moved nk_check_filing up here for convenience, NP, Dec. 21st, 2015.
   ;; @ nk_check_filing checks if the file has already been processed or not.
   process_file = 1
   if keyword_set(filing) then nk_check_filing, param, scan_list[iscan], process_file

   info.status = 0

   if process_file ne 0 then begin

      param.iscan = iscan
      ;; commented out NP, June 21st, 2016
      if keyword_set(parity) then parity = (-1)^iscan
      
      info.error_report_file = error_report_file
      
      ;; @ nk_update_param_info retrieves scan information such as map_center_ra and dec from the
      ;; @^ first scan of the list, even if the current scan will not be
      ;; @^ processed.
      nk_update_param_info, scan_list[iscan], param, info, xml=xml, katana=katana, raw_acq_dir=raw_acq_dir
      param.cpu_date0             = systime(0, /sec)
      param.cpu_time_summary_file = param.output_dir+"/cpu_time_summary_file.dat"
      param.cpu_date_file         = param.output_dir+"/cpu_date.dat"
      spawn, "rm -f "+param.cpu_time_summary_file
      spawn, "rm -f "+param.cpu_date_file
      
      info.error_report_file = error_report_file
      
      if keyword_set(show_maps_only) then param.do_plot=0

      ;; nk_init_grid moved here to initialize the header with the Ra
      ;; and dec of the target that is passed to info in
      ;; nk_update_param_info.
      ;; print, '1/ ', sixty( sxpar( header, "crval1")/15.), sixty( sxpar( header, "crval2"))
      if init_grid_done eq 0 then begin
         nk_init_grid, param, info, grid, header=header, astr=astr
         init_grid_done = 1
      endif
      ;; print, '2/ ', sixty( sxpar( header, "crval1")/15.), sixty( sxpar( header, "crval2"))
      if strupcase(param.map_proj) eq "RADEC" then begin
         if total(finite(astr.crval)) ne 2 then begin
            astr.crval = [param.map_center_ra, param.map_center_dec]
         endif
      endif
      ;; print, '3/ ', sixty( sxpar( header, "crval1")/15.), sixty( sxpar( header, "crval2"))
      
      ;; @ nk_scan_preproc performs all operations on data that are not projection nor cleaning
      ;; @^ dependent (and a few other ones actually for parallel data
      ;; reading)
;      if param.restore_copy eq 1 then begin
;         restore, param.preproc_dir+"/data_"+strtrim(param.scan,2)+".save"
;      endif else begin
      nk_scan_preproc_test, param, info, data, kidpar, grid, preproc_copy=param.preproc_copy, $
                            sn_min=sn_min_list[iscan], sn_max=sn_max_list[iscan], $
                            simpar=simpar, parity=parity, $
                            prism=prism, force_file=force_file, xml=xml, nas_center=nas_center, $
                            list_detector=list_detector, polar=param.polar, katana=katana, badkid=badkid, $
                            astr=astr
;         if param.preproc_copy eq 1 then return
;      endelse
      ;; print, '4/ ', sixty( sxpar( header, "crval1")/15.), sixty( sxpar( header, "crval2"))      
      if info.status eq 1 then goto, ciao

      if param.kid_monitor eq 1 then $
         kid_monitor, param.scan, data=data, kidpar=kidpar, $
                      output_kidpar_dir=!nika.plot_dir+"/KidMonitor", $
                      badkid=badkid

;;      if keyword_set(niter) then begin
;;         junk = execute("data"+scan_list[iscan]+" = data")
;;         ;; will reduce everything later
;;      endif else begin
         
         ;; @ nk_scan_reduce processes, decorrelates, filters, computes noise weights...
         nk_scan_reduce_test, param, info, data, kidpar, grid,$
                              subtract_maps=subtract_maps, input_polar_maps=input_polar_maps, $
                              lkg_kernel=lkg_kernel, simpar=simpar
         if info.status eq 1 then goto, ciao

         ;; @ nk_projection_4 projects data onto maps
         if info.polar eq 2 then begin
            ;; Try to optimize with the Woodbury
            ;; nk_projection_2beams, param, info, data, kidpar, grid
            nk_toi2map_matrix_inverse, param, info, data, kidpar, grid
            if info.status eq 1 then goto, ciao
         endif else begin
            nk_projection_4, param, info, data, kidpar, grid
            if info.status eq 1 then goto, ciao
         endelse

         ;; @ Gather information in info and produce plots
         ;; Total scan time
         info.result_total_obs_time = n_elements(data)/!nika.f_sampling

         ;; Actually projected time (discarding unvalid
         ;; sections of the scan (inter-subscans, slews))
         ;; Added Jan. 13th, 2016
         w1 = where( kidpar.type eq 1, nw1)
         ikid = w1[0]
         junk = nk_where_flag( data.flag[ikid], [8,11], ncompl=ncompl)
         info.result_valid_obs_time = ncompl/!nika.f_sampling
         
         if param.output_noise eq 1 then begin
            nsn = n_elements(data)
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
               
               y = reform( data[ix1:ix1+nsn_noise-1].toi[ikid])
               power_spec, y - my_baseline( y), !nika.f_sampling, pw, freq
               wf = where( freq gt 4.d0)
               if finite(avg(pw[wf])) eq 0 then stop
               kidpar[ikid].noise = avg(pw[wf]) ; Jy/beam/sqrt(Hz) since data is in Jy/beam
               wf = where( abs(freq-1.d0) lt 0.2, nwf)
               if nwf ne 0 then kidpar[ikid].noise_1hz = avg(pw[wf])
               wf = where( abs(freq-2.d0) lt 0.2, nwf)
               if nwf ne 0 then kidpar[ikid].noise_2hz = avg(pw[wf])
               wf = where( abs(freq-10.d0) lt 1, nwf)
               if nwf ne 0 then kidpar[ikid].noise_10hz = avg(pw[wf])
               wf = where( freq ge 4, nwf)
               if nwf ne 0 then kidpar[ikid].noise_above_4hz = avg(pw[wf])
            endfor
         endif
         ;; print, '5/ ', sixty( sxpar( header, "crval1")/15.), sixty( sxpar( header, "crval2"))
         if keyword_set(show_maps_only) then param.do_plot=1
         ;; @ nk_save_scan_results_3 saves results in param.output_dir+"/results.save"
         nk_save_scan_results_3, param, info, data, kidpar, grid, filing=filing, xguess=xguess, yguess=yguess, header=header
         ;; print, '6/ ', sixty( sxpar( header, "crval1")/15.), sixty( sxpar( header, "crval2"))
         if info.status eq 1 then goto, ciao

         if keyword_set(print_status) and info.status ne 0 then begin
            message, /info, "Problem with scan "+strtrim(scan_list[iscan],2)+":"
            print, info.routine
            print, info.error_message
         endif
;;      endelse ; niter
   endif      ; process_file

   if param.delete_all_windows_at_end ne 0 then begin
      wait, 0.3
      wd, /all
   endif
   close, /all                  ; remove a nagging bug if a session of rta is too long: message iswas "all units are used" 

   ciao:
endfor

;; ;; Iterative MM
;; if keyword_set(niter) then begin
;; 
;;    ;; Iterate and reduce each scan
;;    for iter=0, niter do begin
;; 
;;       if iter eq 0 then begin
;;          param.decor_method = 'raw_median'
;;       endif else begin
;;          param.decor_method = 'common_mode'
;;       endelse
;;       
;;       ;; Reinit a grid
;;       nk_init_grid, param, info, grid_tot, header=header
;;       for iscan=0, nscans-1 do begin
;;          ;; retrieve data from the current scan as they were after scan_preproc
;;          junk = execute( "data = data"+scan_list[iscan])
;; 
;;          ;; Reduce data
;;          nk_scan_reduce_test, param, info, data, kidpar, grid,$
;;                               subtract_maps=subtract_maps, input_polar_maps=input_polar_maps, $
;;                               lkg_kernel=lkg_kernel, simpar=simpar
;;          if info.status eq 1 then goto, ciao
;;          ;; Project it
;;          nk_projection_4, param, info, data, kidpar, grid
;;          if info.status eq 1 then goto, ciao
;;          ;; Co-add current scan
;;          nk_average_grids, grid_tot, grid, grid_tot
;;       endfor
;;       
;;       ;; Update:
;;       subtract_maps = grid_tot
;;       save, param, info, grid_tot, file='grid_tot_iter'+strtrim(iter,2)+'.save'
;;    endfor
;; endif


      



end
