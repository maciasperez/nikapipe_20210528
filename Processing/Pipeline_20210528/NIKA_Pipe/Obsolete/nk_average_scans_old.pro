;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_average_scans_old
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_average_scans, info_in, info_out
; 
; PURPOSE: 
;        Averages several scan into a single 1mm map and a single 2mm
;        map. It does the same as nk_data_coadd and nk_coadd2maps, but it
;        works with pre-processed data stores on the disk.
; 
; INPUT: 
;        - info_in: the structure containing the weightd coadded maps
; 
; OUTPUT: 
;        - info_out: info_out.map_1mm, info_out.2mm, info_out.map_var_1mm,
;          info_out.map_var_2mm
; 
; KEYWORDS:
;       - noplot : set to 1 to estimate fluxes and other photometry quantities
;         from the maps without displaying them.
;       - info1: output information structure of the combined
;         map. Useful to access directly photometric information
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 13th, NP
;-

pro nk_average_scans_old, param, scan_list, output_maps, total_obs_time, $
                          time_on_source_1mm, time_on_source_2mm, $
                          noplot=noplot, info=info, show=show, $
                          png=png, ps=ps, kidpar=kidpar, image_only=image_only, $
                          not_educated=not_educated, input_dir=input_dir, grid=grid1, $
                          w8_sign=w8_sign, title_ext=title_ext,  beam_pos_list = beam_pos_list

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_average_scans_old, param, scan_list, output_maps, total_obs_time, $"
   print, "                  time_on_source_1mm, time_on_source_2mm, $"
   print, "                  noplot=noplot, info=info, show=show, $"
   print, "                  png=png, ps=ps, kidpar=kidpar, image_only=image_only, $"
   print, "                  not_educated=not_educated, input_dir=input_dir, grid=grid1, $"
   print, "                  w8_sign=w8_sign, title_ext=title_ext,  beam_pos_list = beam_pos_list"
   return
endif

if keyword_set(not_educated) then educated = 0 else educated = 1

nscans    = n_elements(scan_list)
init_done = 0
neffscan = 0  ; effective number of scans used in the combination

if not keyword_set(input_dir) then input_dir = param.project_dir+"/v_"+strtrim(param.version,2)
if not keyword_set(w8_sign)   then w8_sign   = dblarr( nscans) + 1.d0
if not keyword_set(title_ext) then title_ext = ''

total_obs_time     = 0.d0
time_on_source_1mm = 0.d0
time_on_source_2mm = 0.d0

nk_default_info, info
for iscan=0, nscans-1 do begin

   dir = input_dir+"/"+strtrim( scan_list[iscan], 2)
   file_save = dir+"/results.save"

   if file_test(file_save) eq 0 then begin
      message, /info, file_save+" not found"
   endif else begin

      do_projection = 1

      restore, file_save

      ;; Update output info that will be further used e.g. when we write the
      ;; output fits
      info.polar           = info1.polar
      param.map_center_ra  = param1.map_center_ra
      param.map_center_dec = param1.map_center_dec
      if iscan eq 0 then info.obs_type = info1.obs_type ; init
      if strupcase( strtrim( info1.obs_type,2)) ne strupcase( strtrim( info.obs_type,2)) then info.obs_type = 'Mixed'

      if info1.status ne 1 then begin

         if init_done eq 0 then begin
            ;; Init output maps
            coadd_1mm = grid1.xmap*0.d0
            coadd_2mm = grid1.xmap*0.d0
            nhits_1mm = grid1.xmap*0.d0
            nhits_2mm = grid1.xmap*0.d0
            w8_1mm    = grid1.xmap*0.d0
            w8_2mm    = grid1.xmap*0.d0

            if info1.polar ne 0 then begin
               coadd_q_1mm = grid1.xmap*0.d0
               coadd_u_1mm = grid1.xmap*0.d0
               w8_q_1mm    = grid1.xmap*0.d0
               w8_u_1mm    = grid1.xmap*0.d0
               coadd_q_2mm = grid1.xmap*0.d0
               coadd_u_2mm = grid1.xmap*0.d0
               w8_q_2mm    = grid1.xmap*0.d0
               w8_u_2mm    = grid1.xmap*0.d0
            endif
            init_done = 1
            ;;param = param1

            ;; Init the .csv file that contains all the photometric information
            tags = tag_names(info1)
            wtags = where( strupcase( strmid(tags,0,6)) eq "RESULT", nwtags)
            tag_length = strlen( tags)
            get_lun, file_unit
            openw, file_unit, param1.project_dir+"/all_scans_photometry.csv"
            title_string = 'Scan, Source, RA, DEC'
            for i=0, nwtags-1 do title_string = title_string+", "+strmid( tags[wtags[i]],7,tag_length[wtags[i]]-7)
            printf, file_unit, title_string
         endif

         info.total_obs_time += info1.total_obs_time
;         print, "info1.total_obs_time, info.total_obs_time: ", info1.total_obs_time,info.total_obs_time

         info.nscan          += 1
         info.tau_1mm        += info1.tau_1mm
         info.tau_2mm        += info1.tau_2mm
         time_on_source_1mm  += info1.rho_on_source_1mm*info1.total_obs_time
         time_on_source_2mm  += info1.rho_on_source_2mm*info1.total_obs_time

         ;; Check that the results were computed with the correct parameters
         r = nk_compare_params( param1, param)
         if r ne 0 then begin
            get_lun, lun
            openw, lun, input_dir+"/average_scan_error_report.dat", /append
            printf, lun, strtrim(param1.scan,2)+", param1 does not match param"
            close, lun
            free_lun, lun
            do_projection = 0
         endif

         ;;------------------------------------------------------------
         ;; Coadd scan maps
         if do_projection eq 1 then begin
            neffscan = neffscan+1
            
            ;; 1mm
            nk_coadd_sub, param, coadd_1mm, w8_1mm, nhits_1mm, grid1.map_i_1mm, grid1.map_w8_1mm, grid1.nhits_1mm, grid1.mask_source
            if info1.polar ne 0 then begin
               nk_coadd_sub, param, coadd_q_1mm, w8_q_1mm, nhits_1mm, grid1.map_q_1mm, $
                             grid1.map_w8_q_1mm, grid1.nhits_1mm, grid1.mask_source
               nk_coadd_sub, param, coadd_u_1mm, w8_u_1mm, nhits_1mm, grid1.map_u_1mm, $
                             grid1.map_w8_u_1mm, grid1.nhits_1mm, grid1.mask_source
            endif

            ;; 2mm
            nk_coadd_sub, param, coadd_2mm, w8_2mm, nhits_2mm, grid1.map_i_2mm, grid1.map_w8_2mm, grid1.nhits_2mm, grid1.mask_source
            if info1.polar ne 0 then begin
               nk_coadd_sub, param, coadd_q_2mm, w8_q_2mm, nhits_2mm, grid1.map_q_2mm, $
                             grid1.map_w8_q_2mm, grid1.nhits_2mm, grid1.mask_source
               nk_coadd_sub, param, coadd_u_2mm, w8_u_2mm, nhits_2mm, grid1.map_u_2mm, $
                             grid1.map_w8_u_2mm, grid1.nhits_2mm, grid1.mask_source
            endif

            ;; Update .csv
            res_string   = strtrim(param1.scan,2)+", "+strtrim(param1.source,2)+$
                           ", "+strtrim(info1.longobj,2)+", "+strtrim(info1.latobj,2)
            for i=0, nwtags-1 do res_string   = res_string+", "+strtrim( info1.(wtags[i]),2)
            printf, file_unit, res_string

         endif                  ; do_projection
      endif                     ; status
   endelse                      ; file exist
endfor                          ; scan

;; average the opacities (for info in the products .fits file)
info.tau_1mm /= info.nscan
info.tau_2mm /= info.nscan

if init_done eq 0 then begin    ; no scan could be used
   info.routine       = 'nk_average_scans'
   info.status        = 100
   info.error_message = 'No valid scans could be averaged'
endif else begin

   output_maps = {map_1mm:coadd_1mm*0.d0, $
                  map_2mm:coadd_1mm*0.d0, $
                  map_var_1mm:coadd_1mm*0.d0, $
                  map_var_2mm:coadd_1mm*0.d0, $
                  nhits_1mm:coadd_1mm*0.d0, $
                  nhits_2mm:coadd_1mm*0.d0, $
                  xmap:grid1.xmap, $
                  ymap:grid1.ymap}
   if info1.polar ne 0 then $
      output_maps = create_struct( output_maps, $
                                   "map_q_1mm", coadd_1mm*0.d0, $
                                   "map_q_2mm", coadd_1mm*0.d0, $
                                   "map_var_q_1mm", coadd_1mm*0.d0, $
                                   "map_var_q_2mm", coadd_1mm*0.d0, $
                                   "map_u_1mm", coadd_1mm*0.d0, $
                                   "map_u_2mm", coadd_1mm*0.d0, $
                                   "map_var_u_1mm", coadd_1mm*0.d0, $
                                   "map_var_u_2mm", coadd_1mm*0.d0)
   
   ;; Normalize raw coaddition by weights
   w = where( w8_1mm ne 0, nw)
   if nw ne 0 then begin
      output_maps.nhits_1mm[w]   = nhits_1mm[w]
      output_maps.map_1mm[w]     = coadd_1mm[w]/w8_1mm[w]
      output_maps.map_var_1mm[w] =         1.d0/w8_1mm[w]

      if info1.polar ne 0 then begin
         output_maps.map_q_1mm[w]     = coadd_q_1mm[w]/w8_q_1mm[w]
         output_maps.map_var_q_1mm[w] =           1.d0/w8_q_1mm[w]
         output_maps.map_u_1mm[w]     = coadd_u_1mm[w]/w8_u_1mm[w]
         output_maps.map_var_u_1mm[w] =           1.d0/w8_u_1mm[w]
      endif
   endif

   w = where( w8_2mm ne 0, nw)
   if nw ne 0 then begin
      output_maps.nhits_2mm[w]   = nhits_2mm[w]
      output_maps.map_2mm[w]     = coadd_2mm[w]/w8_2mm[w]
      output_maps.map_var_2mm[w] =         1.d0/w8_2mm[w]
      if info1.polar ne 0 then begin
         output_maps.map_q_2mm[w]     = coadd_q_2mm[w]/w8_q_2mm[w]
         output_maps.map_var_q_2mm[w] =           1.d0/w8_q_2mm[w]
         output_maps.map_u_2mm[w]     = coadd_u_2mm[w]/w8_u_2mm[w]
         output_maps.map_var_u_2mm[w] =           1.d0/w8_u_2mm[w]
      endif
   endif

   ;; Display result
   pp1 = fltarr(6,4)
   p   = 0
   if param.plot_ps eq 0 and param.plot_png eq 0 then begin
      wind, 1, 1, /free, xs=1500, ys=900, iconic = param.iconic
      if info.polar eq 0 then begin
         my_multiplot, 2, 1, pp, pp1, /rev, gap_x=0.1, xmargin=0.1
      endif else begin
         my_multiplot, 4, 2, pp, pp1, /rev, gap_x=0.1, xmargin=0.1
      endelse
   endif

;   outfile = param.project_dir+'/map_'+strtrim(param.source,2)+$                                                             
;             '_v'+strtrim(param.version,2)
   outfile = param.plot_dir+'/map'
   if param.plot_png then begin
      wind, 1, 1, /free, /large, iconic = param.iconic
      outplot, file=outfile+"_1mm", /png
   endif
   if param.plot_ps  then ps_file = outfile+"_1mm.ps"
   nefd_1mm = 1
   lambda   = 1

   kidpar = kidpar1
   nk_map_photometry, output_maps.map_1mm, output_maps.map_var_1mm, output_maps.nhits_1mm, $
                      output_maps.xmap, output_maps.ymap, param.input_fwhm_1mm, $
                      flux_1mm, sigma_flux_1mm, $
                      sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                      bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                      educated=educated, title=title_ext+' '+param.source+' 1mm', ps_file=ps_file, position=pp1[p,*], $
                      k_noise=k_noise, param=param, noplot=1-long(param.do_plot), image_only=image_only, $
                      lambda=1, NEFD_source=nefd_1mm, beam_pos_list = beam_pos_list ; , time_on_source=time_on_source_1mm
   outplot, /close
   p++

   info.result_flux1mm             = flux_1mm ; save in mJy
   info.result_err_flux1mm         = sigma_flux_1mm
   info.result_flux_center_1mm     = flux_center_1mm
   info.result_err_flux_center_1mm = sigma_flux_center_1mm
   info.result_off_x_1mm           = output_fit_par_1mm[4]
   info.result_off_y_1mm           = output_fit_par_1mm[5]
   info.result_fwhm_x_1mm          = output_fit_par_1mm[2] / !fwhm2sigma
   info.result_fwhm_y_1mm          = output_fit_par_1mm[3] / !fwhm2sigma
   info.result_fwhm_1mm            = sqrt( output_fit_par_1mm[2]*output_fit_par_1mm[3]) / !fwhm2sigma
   info.result_nefd_1mm            = nefd_1mm

   if info.polar ne 0 then begin
      nefd_q_1mm = 1
      nk_map_photometry, output_maps.map_q_1mm, output_maps.map_var_q_1mm, output_maps.nhits_1mm, $
                         output_maps.xmap, output_maps.ymap, param.input_fwhm_1mm, $
                         fluxq_1mm, sigma_fluxq_1mm, $
                         sigma_bg_1mm, output_fit_par_1mm_junk, output_fit_par_error_1mm_junk, $
                         bg_rms_1mm, fluxq_center_1mm, sigma_fluxq_center_1mm, sigma_bg_center_1mm, $
                         /educated, title=title_ext+' '+param.source+' Q 1mm', ps_file=ps_file, $
                         position=pp1[p,*], input_fit_par=output_fit_par_1mm, $
                         k_noise=k_noise, param=param, noplot=1-long(param.do_plot), image_only=image_only, $
                         lambda=1, nefd_source=nefd_q_1mm, beam_pos_list = beam_pos_list ;, time_on_source=time_on_source_1mm
      p++
      info.result_fluxq1mm             = fluxq_1mm
      info.result_err_fluxq1mm         = sigma_fluxq_1mm
      info.result_fluxq_center_1mm     = fluxq_center_1mm
      info.result_err_fluxq_center_1mm = sigma_fluxq_center_1mm
      info.result_nefd_q_1mm           = nefd_q_1mm
      
      nefd_u_1mm = 1
      nk_map_photometry, output_maps.map_u_1mm, output_maps.map_var_u_1mm, output_maps.nhits_1mm, $
                         output_maps.xmap, output_maps.ymap, param.input_fwhm_1mm, $
                         fluxu_1mm, sigma_fluxu_1mm, $
                         sigma_bg_1mm, output_fit_par_1mm_junk, output_fit_par_error_1mm_junk, $
                         bg_rms_1mm, fluxu_center_1mm, sigma_fluxu_center_1mm, sigma_bg_center_1mm, $
                         /educated, title=title_ext+' '+param.source+' U 1mm', ps_file=ps_file, $
                         position=pp1[p,*], input_fit_par=output_fit_par_1mm, $
                         k_noise=k_noise, param=param, noplot=1-long(param.do_plot), image_only=image_only, $
                         lambda=1, nefd_source=nefd_u_1mm, beam_pos_list = beam_pos_list ; time_on_source=time_on_source_1mm
      p++
      info.result_fluxu1mm             = fluxu_1mm
      info.result_err_fluxu1mm         = sigma_fluxu_1mm
      info.result_fluxu_center_1mm     = fluxu_center_1mm
      info.result_err_fluxu_center_1mm = sigma_fluxu_center_1mm
      info.result_nefd_u_1mm           = nefd_u_1mm
      
      iqu2pol_info, info.result_flux1mm, info.result_fluxq1mm, info.result_fluxu1mm, $
                  info.result_err_flux1mm,  info.result_err_fluxq1mm,  info.result_err_fluxu1mm,  $
                    pol_deg, sigma_pol_deg, alpha_pol,  sigma_alpha_pol
      info.result_pol_deg_1mm       = pol_deg
      info.result_err_pol_deg_1mm   = sigma_pol_deg
      info.result_pol_angle_1mm     = alpha_pol
      info.result_err_pol_angle_1mm = sigma_alpha_pol


      map_var_ipol = 2.d0*( output_maps.map_q_2mm*sqrt(output_maps.map_var_q_2mm) + $
                            output_maps.map_u_2mm*sqrt(output_maps.map_var_u_2mm)) + $
                     3.d0*( output_maps.map_var_q_2mm^2 + output_maps.map_var_u_2mm^2)
      nk_map_photometry, sqrt(output_maps.map_q_1mm^2+ output_maps.map_u_1mm^2), map_var_ipol, $
                         output_maps.nhits_1mm, $
                         output_maps.xmap, output_maps.ymap, param.input_fwhm_1mm, $
                         input_fit_par=output_fit_par_1mm, $
                         educated=educated, title=title_ext+' '+param.source+' Sqrt(Q!u2!n+U!u2!n) 1mm', $
                         ps_file=ps_file, position=pp1[p,*], $
                         k_noise=k_noise, param=param, noplot=1-long(param.do_plot), image_only=image_only, $
                         beam_pos_list = beam_pos_list;, time_on_source=time_on_source_1mm
      p++
   endif

   if param.plot_png then begin
      wind, 1, 1, /free, /large, iconic = param.iconic
      outplot, file=outfile+"_2mm", /png
   endif
   if param.plot_ps  then ps_file = outfile+"_2mm.ps"
   lambda   = 2
   nefd_2mm = 1
   nk_map_photometry, output_maps.map_2mm, output_maps.map_var_2mm, output_maps.nhits_2mm, $
                      output_maps.xmap, output_maps.ymap, param.input_fwhm_2mm, $
                      flux_2mm, sigma_flux_2mm, $
                      sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
                      bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
                      educated=educated, title=title_ext+' '+param.source+' 2mm', ps_file=ps_file, position=pp1[p,*], $
                      k_noise=k_noise, param=param, noplot=1-long(param.do_plot), image_only=image_only, $
                      lambda=2, NEFD_source=NEFD_2mm, beam_pos_list = beam_pos_list ;, time_on_source=time_on_source_2mm
   p++
   outplot, /close

   info.result_flux2mm             = flux_2mm
   info.result_err_flux2mm         = sigma_flux_2mm
   info.result_flux_center_2mm     = flux_center_2mm
   info.result_err_flux_center_2mm = sigma_flux_center_2mm
   info.result_off_x_2mm           = output_fit_par_2mm[4]
   info.result_off_y_2mm           = output_fit_par_2mm[5]
   info.result_fwhm_x_2mm          = output_fit_par_2mm[2] / !fwhm2sigma
   info.result_fwhm_y_2mm          = output_fit_par_2mm[3] / !fwhm2sigma
   info.result_fwhm_2mm            = sqrt( output_fit_par_2mm[2]*output_fit_par_2mm[3]) / !fwhm2sigma
   info.result_nefd_2mm            = nefd_2mm

   if info.polar ne 0 then begin
      nefd_q_2mm = 1
      nk_map_photometry, output_maps.map_q_2mm, output_maps.map_var_q_2mm, output_maps.nhits_2mm, $
                         output_maps.xmap, output_maps.ymap, param.input_fwhm_2mm, $
                         fluxq_2mm, sigma_fluxq_2mm, $
                         sigma_bg_2mm, output_fit_par_2mm_junk, output_fit_par_error_2mm_junk, $
                         bg_rms_2mm, fluxq_center_2mm, sigma_fluxq_center_2mm, sigma_bg_center_2mm, $
                         /educated, title=title_ext+' '+param.source+' Q 2mm', ps_file=ps_file, $
                         position=pp1[p,*], input_fit_par=output_fit_par_2mm, map_conv = map_conv_q, $
                         k_noise=k_noise, param=param, noplot=1-long(param.do_plot), image_only=image_only, $
                         lambda=2, nefd_source=nefd_q_2mm, beam_pos_list = beam_pos_list ;, time_on_source=time_on_source_2mm
      p++
      info.result_fluxq2mm             = fluxq_2mm
      info.result_err_fluxq2mm         = sigma_fluxq_2mm
      info.result_fluxq_center_2mm     = fluxq_center_2mm
      info.result_err_fluxq_center_2mm = sigma_fluxq_center_2mm
      info.result_nefd_q_2mm           = nefd_q_2mm

      nefd_u_2mm = 1
      nk_map_photometry, output_maps.map_u_2mm, output_maps.map_var_u_2mm, output_maps.nhits_2mm, $
                         output_maps.xmap, output_maps.ymap, param.input_fwhm_2mm, $
                         fluxu_2mm, sigma_fluxu_2mm, $
                         sigma_bg_2mm, output_fit_par_2mm_junk, output_fit_par_error_2mm_junk, $
                         bg_rms_2mm, fluxu_center_2mm, sigma_fluxu_center_2mm, sigma_bg_center_2mm, $
                         /educated, title=title_ext+' '+param.source+' U 2mm', ps_file=ps_file, $
                         position=pp1[p,*], input_fit_par=output_fit_par_2mm, map_conv = map_conv_u, $
                         k_noise=k_noise, param=param, noplot=1-long(param.do_plot), image_only=image_only, $
                         lambda=2, nefd_source=nefd_u_2mm, beam_pos_list = beam_pos_list ;, time_on_source=time_on_source_2mm
      p++
      info.result_fluxu2mm             = fluxu_2mm
      info.result_err_fluxu2mm         = sigma_fluxu_2mm
      info.result_fluxu_center_2mm     = fluxu_center_2mm
      info.result_err_fluxu_center_2mm = sigma_fluxu_center_2mm
      info.result_nefd_u_2mm           = nefd_u_2mm

      iqu2pol_info, info.result_flux2mm, info.result_fluxq2mm, info.result_fluxu2mm, $
                    info.result_err_flux2mm,  info.result_err_fluxq2mm,  info.result_err_fluxu2mm, $
                    pol_deg, sigma_pol_deg, alpha_pol, sigma_alpha_pol
      info.result_pol_deg_2mm       = pol_deg
      info.result_err_pol_deg_2mm   = sigma_pol_deg
      info.result_pol_angle_2mm     = alpha_pol
      info.result_err_pol_angle_2mm =  sigma_alpha_pol

      map_var_ipol = 2.d0*( output_maps.map_q_2mm*sqrt(output_maps.map_var_q_2mm) + $
                            output_maps.map_u_2mm*sqrt(output_maps.map_var_u_2mm)) + $
                     3.d0*( output_maps.map_var_q_2mm^2 + output_maps.map_var_u_2mm^2)
      nk_map_photometry, sqrt(output_maps.map_q_2mm^2+ output_maps.map_u_2mm^2), map_var_ipol, $
                         output_maps.nhits_1mm, $
                         output_maps.xmap, output_maps.ymap, param.input_fwhm_1mm, $
                         input_fit_par=output_fit_par_2mm, $
                         educated=educated, title=title_ext+' '+param.source+' Sqrt(Q!u2!n+U!u2!n) 2mm', $
                         ps_file=ps_file, position=pp1[p,*], $
                         k_noise=k_noise, param=param, noplot=1-long(param.do_plot), image_only=image_only, $
                         beam_pos_list = beam_pos_list;, time_on_source = time_on_source_2mm

;;       nk_map_photometry, sqrt(map_conv_q^2+ map_conv_u^2), output_maps.map_var_u_1mm, $
;;                          output_maps.nhits_1mm, $
;;                          output_maps.xmap, output_maps.ymap, param.input_fwhm_1mm, $
;;                          input_fit_par=output_fit_par_2mm, $
;;                          educated=educated, title=title_ext+' '+param.source+' Sqrt(Q!u2!n+U!u2!n) 2mm', $
;;                          ps_file=ps_file, position=pp1[p,*], $
;;                          k_noise=k_noise, param=param, noplot=1-long(param.do_plot), image_only=image_only, $
;;                          beam_pos_list = beam_pos_list;, time_on_source = time_on_source_2mm
;;       stop



      p++
   endif

;; update .csv file with the results of all scans cumulated
   res_string   = strtrim( neffscan, 2)+' Scans combined from '+$
                  strtrim(param.scan,2)+", "+strtrim(param.source,2)+ $
                  ", "+strtrim(info.longobj,2)+", "+strtrim(info.latobj,2)
   for i=0, nwtags-1 do res_string   = res_string+", "+strtrim( info.(wtags[i]),2)
   printf, file_unit, res_string
   close, file_unit
endelse

;; Update LaTeX documents with all maps
;;nk_latex_project_report, param
nk_latex_project_report, param, scan_list

loadct, 39
if defined( file_unit) then free_lun, file_unit

end
