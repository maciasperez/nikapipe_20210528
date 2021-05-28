;+
; SOFTWARE: NIKA pipeline
;
; NAME:
;       nk
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;    nk, scan_list_in, param=param, info=info, $
;        filing=filing, data=data, kidpar=kidpar, $
;        print_status=print_status, grid=grid, $
;        simpar=simpar, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
;        subtract_maps=subtract_maps, no_output_map=no_output_map, prism=prism, $
;        parity=parity, force_file=force_file, xml = xml, $
;        kill_subscan = kill_subscan, show_maps_only=show_maps_only, results_filing=results_filing, $
;        lab=lab, input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel, nas_center=nas_center, $
;        list_detector=list_detector, xguess=xguess, yguess=yguess, polar=polar, $
;        raw_acq_dir=raw_acq_dir, header=header, astr=astr
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

pro nk_all_hwp, scan_list_in, param=param, info=info, $
        filing=filing, data=data, kidpar=kidpar, $
        print_status=print_status, grid=grid, $
        simpar=simpar, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
        subtract_maps=subtract_maps, no_output_map=no_output_map, prism=prism, $
        parity=parity, force_file=force_file, xml = xml, $
        kill_subscan = kill_subscan, show_maps_only=show_maps_only, results_filing=results_filing, $
        lab=lab, input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel, nas_center=nas_center, $
        list_detector=list_detector, xguess=xguess, yguess=yguess, polar=polar, $
        raw_acq_dir=raw_acq_dir, header=header, astr=astr, second_header=second_header
;-
if n_params() lt 1 then begin
   dl_unix, 'nk'
   return
endif

xml=0                           ; FXD  to be fixed
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

;; @ init param and info if they have not been passed in input
if not keyword_set(param) then nk_default_param,   param
if not keyword_set(info)  then nk_default_info, info

nk_check_param, param, info
if defined(simpar) then nk_check_simpar, simpar, info

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
   if strupcase(lkg_kernel.map_proj) ne "NASMYTH" then begin
      text = "lkg_kernel.map_proj = "+lkg_kernel.map_proj+": should be NASMYTH"
      nk_error, info, text
      return
   endif
endif

;;---------------------------------------------------------------------------------
;; Main loop
;random_string = strtrim( long( abs( randomu( seed, 1)*1e8)),2)
;error_report_file = param.project_dir+"/error_report_"+random_string+".dat"

for iscan=0, nscans-1 do begin

   ;; for convenience in cluster log files
   print, "scan = ", scan_list[iscan]
   print, "method_num ", param.method_num

   ;; Moved nk_check_filing up here for convenience, NP, Dec. 21st, 2015.
   ;; @ nk_check_filing checks if the file has already been processed or not.
   process_file = 1
   if keyword_set(filing) then nk_check_filing, param, scan_list[iscan], process_file

   info.status = 0

   if process_file ne 0 then begin

      param.iscan = iscan
;;      info.error_report_file = param.project_dir+"/error_report_"+scan_list[iscan]+".dat"

      ;; @ nk_update_param_info retrieves scan information such as map_center_ra and dec from the
      ;; @^ first scan of the list, even if the current scan will not be
      ;; @^ processed.
      nk_update_param_info, scan_list[iscan], param, info, xml=xml, katana=katana, raw_acq_dir=raw_acq_dir
      info.error_report_file = param.output_dir+"/error_report.dat"
      info.logfile           = param.output_dir+"/logfile.dat"
      param.cpu_date0             = systime(0, /sec)
      param.cpu_time_summary_file = param.output_dir+"/cpu_time_summary_file.dat"
      param.cpu_date_file         = param.output_dir+"/cpu_date.dat"
      spawn, "rm -f "+param.cpu_time_summary_file
      spawn, "rm -f "+param.cpu_date_file    
      spawn, "rm -f "+info.logfile
      ;; useful to parse job*out:
      print, "param.output_dir = "+param.output_dir

;      info.error_report_file = error_report_file
      if keyword_set(show_maps_only) then param.do_plot=0

      ;;----------------------------------------------------------------------------------------------------------------
      ;; @ nk_scan_preproc performs all operations on data that are not projection nor cleaning
      ;; @^ dependent (and a few other ones actually for parallel data
      ;; reading)

      nk_scan_preproc, param, info, data, kidpar, grid=grid, $
                       preproc_copy=param.preproc_copy, $
                       sn_min=sn_min_list[iscan], sn_max=sn_max_list[iscan], $
                       simpar=simpar, parity=parity, $
                       prism=prism, force_file=force_file, xml=xml, nas_center=nas_center, $
                       list_detector=list_detector, polar=param.polar, katana=katana, badkid=badkid, $
                       astr=astr, header=header

      if info.status eq 1 then goto, ciao

      if param.kid_monitor eq 1 then $
         kid_monitor, param.scan, data=data, kidpar=kidpar, $
                      output_kidpar_dir=!nika.plot_dir+"/KidMonitor", $
                      badkid=badkid
      
      ;; ----------------------------------------------------------------------------------------------------------------
      if param.project_white_noise_nefd eq 0 then begin
         ;; @ nk_scan_reduce processes, decorrelates, filters,
         ;; computes noise weights...
         case param.clean_data_version of
            0: nk_scan_reduce_1, param, info, data, kidpar, grid,$
                                 subtract_maps=subtract_maps, input_polar_maps=input_polar_maps, $
                                 simpar=simpar, astr=astr
            3: nk_scan_reduce, param, info, data, kidpar, grid,$
                               subtract_maps=subtract_maps, input_polar_maps=input_polar_maps, $
                               lkg_kernel=lkg_kernel, simpar=simpar
            4: nk_scan_reduce_1, param, info, data, kidpar, grid,$
                                 subtract_maps=subtract_maps, input_polar_maps=input_polar_maps, $
                                 simpar=simpar, astr=astr
            5: nk_scan_reduce_1, param, info, data, kidpar, grid,$
                                 subtract_maps=subtract_maps, input_polar_maps=input_polar_maps, $
                                 simpar=simpar, astr=astr
            6: begin
               nk_mdc_try, param, info, data, kidpar, grid
               nk_w8, param, info, data, kidpar
            end
            7: begin
               nk_eigenvec_try, param, info, data, kidpar
               nk_w8, param, info, data, kidpar
            end
            else: message, /info, "Wrong value of param.clean_data_version: "+strtrim(param.clean_data_version,2)
         endcase
         
         if info.status eq 1 then goto, ciao
      endif

      ;;----------------------------------------------------------------------------------------------------------------
      ;; @ nk_projection_4 projects data onto maps

      if param.even_odd_subscans eq 1 then begin
         flag_copy = data.flag
         w = where( (data.subscan mod 2) eq 0)
         data[w].flag = 1
         nk_projection_4, param, info, data, kidpar, grid

         odd_grid = grid

         data.flag = flag_copy
         w = where( (data.subscan mod 2) eq 1)
         data[w].flag = 1
         nk_projection_4, param, info, data, kidpar, grid
         even_grid = grid

         save, param, info, kidpar, even_grid, odd_grid, file='even_odd_grid.save'
         message, /info, "saved even_odd_grid.save"
      endif
      
;; stop
;; w1 = where( kidpar.type eq 1, nw1)
;; nsn = n_elements(data)
;; data.toi[w1] = randomn( seed, nw1, nsn)
;; data.w8 = 1.d0
;; stop
      ;Experimental setup (FXD) to flag all HWP positions except one
      if param.keep_one_hwp_position eq 0 then message, 'Use nk'
                                ; save the original
      da = data
      pa = param
      inf = info
      for hwp_pos = 1, 16 do begin
         message, /info, 'Start saving hwp position '+strtrim(hwp_pos, 2)
         data = da
         param = pa
         info = inf
         param.keep_one_hwp_position = hwp_pos
         nk_keep_one_hwp_position, param, info, data
         param.output_dir = param.output_dir+ $ ; save files there
                                '/hwp'+strtrim(hwp_pos,2)
         spawn, 'mkdir -p ' + param.output_dir

      nk_projection_4, param, info, data, kidpar, grid

      ;; If requested, make sure the background is zero on average
      if param.map_bg_zero_level_radius gt 0.d0 then begin  ; this should be coded in nk_snr_flux_map  (FXD to be done)
         nextend = 12
         input_sigma_beam = !nika.fwhm_nom[0]*!fwhm2sigma
         nx_kgauss       = 2*long(nextend*input_sigma_beam/grid.map_reso/2)+1
         ny_kgauss       = 2*long(nextend*input_sigma_beam/grid.map_reso/2)+1
         xxg               = dblarr(nx_kgauss, ny_kgauss)
         yyg               = dblarr(nx_kgauss, ny_kgauss)
         for ii=0, nx_kgauss-1 do xxg[ii,*] = (ii-nx_kgauss/2)*grid.map_reso
         for ii=0, ny_kgauss-1 do yyg[*,ii] = (ii-ny_kgauss/2)*grid.map_reso
         kgauss = exp(-(xxg^2+yyg^2)/(2.*input_sigma_beam^2)) ; PSF Gaussian kernel

         if param.k_snr_method eq 3 then begin
            nk_ata_fit_beam3, grid.map_i_1mm, grid.map_var_i_1mm, kgauss, info, $
                              flux_kgauss, sigma_flux_kgauss ; map of flux and error
         endif else begin                                    ; all other cases
            nk_ata_fit_beam2, grid.map_i_1mm, grid.map_var_i_1mm, kgauss, info, $
                              flux_kgauss, sigma_flux_kgauss ; map of flux and error
         endelse
         snr_mask = grid.map_i1*0.d0
         w = where( sigma_flux_kgauss ne 0)
         snr_mask[w] = abs( flux_kgauss[w]/sigma_flux_kgauss[w])
         w = where( sqrt( grid.xmap^2 + grid.ymap^2) le param.map_bg_zero_level_radius and $
                    snr_mask lt 3, nw)
         if nw ne 0 and param.map_bg_zero_level_radius gt 0.d0 then begin
            grid.map_i1    -= avg( grid.map_i1[w])
            grid.map_i3    -= avg( grid.map_i3[w])
            grid.map_i_1mm -= avg( grid.map_i_1mm[w])
         endif

         input_sigma_beam = !nika.fwhm_nom[1]*!fwhm2sigma
         nx_kgauss       = 2*long(nextend*input_sigma_beam/grid.map_reso/2)+1
         ny_kgauss       = 2*long(nextend*input_sigma_beam/grid.map_reso/2)+1
         xxg               = dblarr(nx_kgauss, ny_kgauss)
         yyg               = dblarr(nx_kgauss, ny_kgauss)
         for ii=0, nx_kgauss-1 do xxg[ii,*] = (ii-nx_kgauss/2)*grid.map_reso
         for ii=0, ny_kgauss-1 do yyg[*,ii] = (ii-ny_kgauss/2)*grid.map_reso
         kgauss = exp(-(xxg^2+yyg^2)/(2.*input_sigma_beam^2)) ; PSF Gaussian kernel
         nk_ata_fit_beam2, grid.map_i2, grid.map_var_i2, kgauss, info, $
                           flux_kgauss, sigma_flux_kgauss ; map of flux and error
         snr_mask = grid.map_i2*0.d0
         w = where( sigma_flux_kgauss ne 0)
         snr_mask[w] = abs( flux_kgauss[w]/sigma_flux_kgauss[w])
         w = where( sqrt( grid.xmap^2 + grid.ymap^2) le param.map_bg_zero_level_radius and $
                    snr_mask lt 3, nw)
         if nw ne 0 then begin
            grid.map_i2    -= avg( grid.map_i2[w])
         endif
      endif

;; ;      if param.debug then begin
;;          message, /info, "debugging"
;;          wind, 1, 1, /free, /large
;;          outplot, file='map_and_scan_'+param.scan, /png
;;          my_multiplot, 2, 2, pp, pp1, /rev, gap_x=0.1
;;          imview, grid.map_i1, xmap=grid.xmap, ymap=grid.ymap, imr=[-1,1]/100., fwhm=10, colt=1, $
;;                  title=param.scan+" "+info.object, position=pp1[0,*], /nobar
;;          legendastro, ["systemof: "+strtrim(info.systemof,2), $
;;                        "elev: "+strtrim(info.result_elevation_deg,2), $
;;                        "paral: "+strtrim(info.paral,2)], textcol=255
;; ;         loadct, 7 & oplot, -ofs_x, ofs_y, col=200
;;          loadct, 39, /silent
;; 
;;          wsub = where( data.subscan eq 4)
;; ;;          x = ofs_az[wsub]
;; ;;          y = ofs_el[wsub]
;; 
;;          x = ofs_x[wsub]
;;          y = ofs_y[wsub]
;; 
;;          ;; checking Xavier's hypothesis about correlated noise
;;          ;; and box orientation in the FP at 1mm:
;;          alpha = -13.8*!dtor ; 0 ; 
;;          junk  = cos(alpha)*x - sin(alpha)*y
;;          y = sin(alpha)*x + cos(alpha)*y
;;          x = junk
;; 
;;          x -= avg(x)
;;          y -= avg(y)
;; ;;          oplot, 10*x, 10*y, col=100
;; ;;          oplot, -10*x, 10*y, col=150
;; ;;          oplot, 10*x, -10*y, col=200
;; ;;          oplot, -10*x, -10*y, col=250
;; 
;;          for ii=-10, 10 do oplot, 10*x, -10*y + ii*50, col=100
;; 
;;          alpha = !dpi/2.
;;          junk  = cos(alpha)*x - sin(alpha)*y
;;          y = sin(alpha)*x + cos(alpha)*y
;;          x = junk
;;          for ii=-10, 10 do oplot, 10*x, -10*y + ii*50, col=200
;; 
;;          legendastro, ['nasmyth -13.8', 'nasmyth -13.8 + 90'], textcol=[100, 200], /bottom
;; 
;;          plot, data.el*!radeg, /xs, /ys, position=pp1[1,*], /noerase, $
;;                title='elevation', ytitle='deg'
;; 
;;          plot, ofs_el, /xs, /ys, position=pp1[2,*], /noerase, $
;;                title='ofs_elevation', ytitle='arcsec'
;; 
;;          if param.debug eq 1 then stop
;;          outplot, /close, /verb
;;          wd
;; ;      endif

      if info.status eq 1 then goto, ciao
      
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
            if defined( ix1) then begin
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
            endif
         endfor
      endif

      if keyword_set(show_maps_only) then param.do_plot=1
      ;; @ nk_save_scan_results_3 saves results in
      ;; param.output_dir+"/results.save"
;;       if keyword_set(lkg_kernel) then nk_lkg_2018, param, info, data, kidpar, grid, lkg_kernel   

      if keyword_set(lkg_kernel) then begin
         temp_fits_file = param.output_dir+"/bidon.fits"
         nk_map2fits_3, param, info, grid, output_fits_file=temp_fits_file, header=header
         nk_lkg_correct_5, param, info, grid, lkg_kernel, temp_fits_file, /taper, plot=param.debug_lkg_plot
         spawn, "rm -f "+temp_fits_file
      endif
      
      ;; In the case of particular processings (e.g. Saturn moons)
      if strupcase(param.specific_reduction) ne "NONE" then $
         nk_specific, param, info, data, kidpar, grid, grid2, grid3, info2, info3

      ;; Write results on disk
      nk_save_scan_results_3, param, info, data, kidpar, grid, $
                              filing=filing, xguess=xguess, yguess=yguess, $
                              header=header, grid2=grid2, grid3=grid3, info2=info2, info3=info3
      if keyword_set(second_header) then begin
         extast, second_header, astr2
         nk_init_grid_2, param, info, grid, astr=astr2
         nk_get_ipix, param, info, data, kidpar, grid, astr=astr2
         nk_projection_4, param, info, data, kidpar, grid
         nk_save_scan_results_3, param, info, data, kidpar, grid, $
                                 filing=filing, xguess=xguess, yguess=yguess, $
                                 header=second_header, /results2
      endif

      if info.status eq 1 then goto, ciao

      if keyword_set(print_status) and info.status ne 0 then begin
         message, /info, "Problem with scan "+strtrim(scan_list[iscan],2)+":"
         print, info.routine
         print, info.error_message
      endif
   endfor                        ; loop on hwp_pos

   endif                         ; process file

   ;; NP helps FXD to build maps per subscan
   if (param.map_per_subscan eq 1 or param.check_anom_refrac) and $
      size(/type,  data) eq 8 then begin
      flag_copy = data.flag
      data1 = data              ; only once
      for isub=2, max( data.subscan) do begin
         data1.flag = flag_copy
         w = where( data1.subscan eq isub, nw, compl=wout)
         if nw ge 70 then begin ; at least 3 seconds of data
            data1[wout].flag = 1
            info1 = info
            grid1 = grid
            param1 = param
            param1.educated = 1 ; make sure
            param1.output_dir = param.output_dir+ $
                                '/sub'+strtrim(isub,2)
            spawn, 'mkdir -p ' + param1.output_dir
            nk_projection_4, param1, info1, data1, kidpar, grid1
            
            info1.result_total_obs_time = $
               n_elements(data1)/!nika.f_sampling
            w1 = where( kidpar.type eq 1, nw1)
            ikid = w1[0]
            junk = nk_where_flag( data1.flag[ikid], [0, 8,11], $
                                  ncompl=ncompl)
            info1.result_valid_obs_time = ncompl/!nika.f_sampling
            info1.result_elevation_deg = avg( data1[w].el)*!radeg
            nk_save_scan_results_3, param1, info1, data1, kidpar, $
                                    grid1, $
                                    xguess=xguess, yguess=yguess, $
                                    header=header
         endif
      endfor
;; ;; To get info on a grid for  a source
;;    nk_grid2info, grid, info, /educated

      if param.check_anom_refrac then begin
         nn = max(data.subscan)-2+1
         x = dblarr(2,nn)
         y = dblarr(2,nn)
         for isub=2, max( data.subscan) do begin
            nk_read_csv_2, param.output_dir+'/sub'+strtrim(isub,2)+'/info.csv', info_sub
            x[0,isub-2] = info_sub.result_off_x_1mm
            y[0,isub-2] = info_sub.result_off_y_1mm
            x[1,isub-2] = info_sub.result_off_x_2
            y[1,isub-2] = info_sub.result_off_y_2
         endfor
         info.result_anom_refrac_scatter_1mm = $
            sqrt( total( (x[0,*]-avg(x[0,*]))^2 + (y[0,*]-avg(y[0,*]))^2))
         info.result_anom_refrac_scatter_2mm = $
            sqrt( total( (x[1,*]-avg(x[1,*]))^2 + (y[1,*]-avg(y[1,*]))^2))

         if param.do_plot ne 0 then begin
            if param.plot_ps eq 0 then wind, 1, 1, /free
            outplot, file=param.plot_dir+"/anom_refrac_scatter", $
                     png=param.plot_png, ps=param.plot_ps
            plot, x[0,*], y[0,*], /iso, xra=[-20,20], yra=[-20,20], $
                  xtitle='!7D!3x (arcsec)', ytitle='!7D!3y (arcsec)', $
                  /nodata
            oplot, x[0,*], y[0,*], psym=8, syms=0.5, col=70
            oplot, x[1,*], y[1,*], psym=8, syms=0.5, col=250
            legendastro, ['Anom. Refrac. Scatter', $
                          '1mm: '+string(info.result_anom_refrac_scatter_1mm,form='(F5.2)'), $
                          '2mm: '+string(info.result_anom_refrac_scatter_2mm,form='(F5.2)')], $
                         textcol=[!p.color, 70, 250]
            nika_title, info, /ut, /az, /el, /scan
            outplot, /close
         endif
      endif
   endif
;; =======
;;      ;; NP helps FXD to build maps per subscan
;;      if param.map_per_subscan eq 1 or param.check_anom_refrac eq 1 then $
;;         nk_map_per_subscan, param, info, data, kidpar, grid, $
;;                             xguess=xguess, yguess=yguess, $
;;                             header=header
;; >>>>>>> .r18685
   
   if param.delete_all_windows_at_end ne 0 then begin
      wait, 0.3
      wd, /all
   endif
   close, /all                  ; remove a nagging bug if a session of rta is too long: message iswas "all units are used" 

   ciao:
endfor

if param.cpu_time eq 1 then begin
   cpu_monitor, dir=param.output_dir, ps=param.plot_ps, png=param.plot_png, zbuffer=param.plot_z, $
                output_plot_file=param.output_dir+"/cpu_monitor_plot"
endif

;; Print warning message if any
np_warning, /stars

end
