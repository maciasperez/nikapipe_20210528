;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_jk_set
;
; CATEGORY:
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;   hacked from nk_average_scans to allow various signs for scans
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
;        - June 13th 2014, NP
;        - June 16th, 2015: add the /cumul option, NP
;          - Oct. 17th, 2015: NP, clean up nk_average_scan (most
;            results can be retrieved from the photometry.csv instead)
;            and adapted to NIKA2.
;-

pro nk_jk_set, param, scan_list, grid_tot, nickname, sign_list=sign_list, info=info, $
               imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
               imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
               imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
               imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
               noplot=noplot, beam_pos_list = beam_pos_list, syst_err = syst_err, $
               sigma_beam_pos = sigma_beam_pos, cumul = cumul, photometry=photometry, $
               flux_cumul=flux_cumul, sigma_flux_cumul=sigma_flux_cumul, $
               flux_center_cumul=flux_center_cumul, sigma_flux_center_cumul=sigma_flux_center_cumul, $
               time_center_cumul=time_center_cumul, center_nefd_only=center_nefd_only, parity=parity, $
               project_dir=project_dir, output_fits_file=output_fits_file, $
               average_only=average_only, sum_one_over_sigma_flux_center_sq=sum_one_over_sigma_flux_center_sq, $
               nofits=nofits, noboost = noboost, time_gauss_beam_cumul=time_gauss_beam_cumul, $
               tau_w8=tau_w8, $
               bypass_unmatched_grid = bypass_unmatched_grid
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_jk_set, param, scan_list, grid_tot, info=info, $"
   print, "                   imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $"
   print, "                   imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $"
   print, "                   imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $"
   print, "                   imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $"
   print, "                   png=png, ps=ps, noplot=noplot, beam_pos_list = beam_pos_list, syst_err = syst_err, $"
   print, "                   sigma_beam_pos = sigma_beam_pos, cumul = cumul, photometry=photometry, bypass_unmatched_grid = bypass_unmatched_grid"
   return
endif

nscans        = n_elements(scan_list)
neffscan      = 0  ; effective number of scans used in the combination
do_projection = 0
init_done     = 0
stokes        = ['I', 'Q', 'U']

time_gauss_beam_cumul             = dblarr(nscans, 15) ; 12) ; 15)
time_center_cumul                 = dblarr(nscans, 15) ; 12) ; 15)
flux_cumul                        = dblarr(nscans, 15) ; 12) ; 15)
sigma_flux_cumul                  = dblarr(nscans, 15) ; 12) ; 15)
flux_center_cumul                 = dblarr(nscans, 15) ; 12) ; 15)
sigma_flux_center_cumul           = dblarr(nscans, 15) ; 12) ; 15)
sum_one_over_sigma_flux_center_sq = dblarr(nscans, 15) ; 12) ; 15)

if not keyword_set(project_dir) then project_dir = param.project_dir
if not keyword_set(sign_list) then sign_list = dblarr(nscans)+1.d0

;; Ensure even number of scans for the Jackknife map
jk_scan_list = scan_list
keep = intarr(nscans)
for iscan=0, nscans-1 do begin
   dir = project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim( scan_list[iscan], 2)
   if file_test(dir+"/results.save") then keep[iscan]=1
endfor
wkeep = where( keep eq 1, nkeep_jk)
if nkeep_jk eq 0 then begin
   message, /info, "No result file found."
   return
endif
if (nkeep_jk mod 2) eq 1 then nkeep_jk = nkeep_jk-1

;; Main loop
i_jk = 0 ; init jackknife counter
for iscan=0, nscans-1 do begin

   dir = project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim( scan_list[iscan], 2)

   ;; Check if the requested result file exists
   file_save = dir+"/results.save"
   if file_test(file_save) eq 0 then begin
      message, /info, file_save+" not found"
   endif else begin
      ;; @ Restore results of each individual scan
      restore, file_save
      if not param.silent then percent_status, iscan, nscans, 10, message='nk_average_scans'

      ;; Cumulative error on the center flux as derived from
      ;; individual scans
      if iscan eq 0 then begin
         sum_one_over_sigma_flux_center_sq[iscan,  0] = 1.d0/info1.result_err_flux_center_i1^2
         sum_one_over_sigma_flux_center_sq[iscan,  1] = 1.d0/info1.result_err_flux_center_q1^2
         sum_one_over_sigma_flux_center_sq[iscan,  2] = 1.d0/info1.result_err_flux_center_u1^2

         sum_one_over_sigma_flux_center_sq[iscan,  3] = 1.d0/info1.result_err_flux_center_i2^2
         sum_one_over_sigma_flux_center_sq[iscan,  4] = 1.d0/info1.result_err_flux_center_q2^2
         sum_one_over_sigma_flux_center_sq[iscan,  5] = 1.d0/info1.result_err_flux_center_u2^2

         sum_one_over_sigma_flux_center_sq[iscan,  6] = 1.d0/info1.result_err_flux_center_i3^2
         sum_one_over_sigma_flux_center_sq[iscan,  7] = 1.d0/info1.result_err_flux_center_q3^2
         sum_one_over_sigma_flux_center_sq[iscan,  8] = 1.d0/info1.result_err_flux_center_u3^2

         sum_one_over_sigma_flux_center_sq[iscan,  9] = 1.d0/info1.result_err_flux_center_i_1mm^2
         sum_one_over_sigma_flux_center_sq[iscan, 10] = 1.d0/info1.result_err_flux_center_q_1mm^2
         sum_one_over_sigma_flux_center_sq[iscan, 11] = 1.d0/info1.result_err_flux_center_u_1mm^2

;         sum_one_over_sigma_flux_center_sq[iscan, 12] = 1.d0/info1.result_err_flux_center_i2^2
;         sum_one_over_sigma_flux_center_sq[iscan, 13] = 1.d0/info1.result_err_flux_center_q2^2
;         sum_one_over_sigma_flux_center_sq[iscan, 14] = 1.d0/info1.result_err_flux_center_u2^2
      endif else begin
         sum_one_over_sigma_flux_center_sq[iscan,  0] = sum_one_over_sigma_flux_center_sq[iscan-1,  0] + 1.d0/info1.result_err_flux_center_i1^2
         sum_one_over_sigma_flux_center_sq[iscan,  1] = sum_one_over_sigma_flux_center_sq[iscan-1,  1] + 1.d0/info1.result_err_flux_center_q1^2
         sum_one_over_sigma_flux_center_sq[iscan,  2] = sum_one_over_sigma_flux_center_sq[iscan-1,  2] + 1.d0/info1.result_err_flux_center_u1^2
                                                                                                
         sum_one_over_sigma_flux_center_sq[iscan,  3] = sum_one_over_sigma_flux_center_sq[iscan-1,  3] + 1.d0/info1.result_err_flux_center_i2^2
         sum_one_over_sigma_flux_center_sq[iscan,  4] = sum_one_over_sigma_flux_center_sq[iscan-1,  4] + 1.d0/info1.result_err_flux_center_q2^2
         sum_one_over_sigma_flux_center_sq[iscan,  5] = sum_one_over_sigma_flux_center_sq[iscan-1,  5] + 1.d0/info1.result_err_flux_center_u2^2
                                                                                                
         sum_one_over_sigma_flux_center_sq[iscan,  6] = sum_one_over_sigma_flux_center_sq[iscan-1,  6] + 1.d0/info1.result_err_flux_center_i3^2
         sum_one_over_sigma_flux_center_sq[iscan,  7] = sum_one_over_sigma_flux_center_sq[iscan-1,  7] + 1.d0/info1.result_err_flux_center_q3^2
         sum_one_over_sigma_flux_center_sq[iscan,  8] = sum_one_over_sigma_flux_center_sq[iscan-1,  8] + 1.d0/info1.result_err_flux_center_u3^2
                                                                                                
         sum_one_over_sigma_flux_center_sq[iscan,  9] = sum_one_over_sigma_flux_center_sq[iscan-1,  9] + 1.d0/info1.result_err_flux_center_i_1mm^2
         sum_one_over_sigma_flux_center_sq[iscan, 10] = sum_one_over_sigma_flux_center_sq[iscan-1, 10] + 1.d0/info1.result_err_flux_center_q_1mm^2
         sum_one_over_sigma_flux_center_sq[iscan, 11] = sum_one_over_sigma_flux_center_sq[iscan-1, 11] + 1.d0/info1.result_err_flux_center_u_1mm^2
                                                                                                
;         sum_one_over_sigma_flux_center_sq[iscan, 12] = sum_one_over_sigma_flux_center_sq[iscan-1, 12] + 1.d0/info1.result_err_flux_center_i2^2
;         sum_one_over_sigma_flux_center_sq[iscan, 13] = sum_one_over_sigma_flux_center_sq[iscan-1, 13] + 1.d0/info1.result_err_flux_center_q2^2
;         sum_one_over_sigma_flux_center_sq[iscan, 14] = sum_one_over_sigma_flux_center_sq[iscan-1, 14] + 1.d0/info1.result_err_flux_center_u2^2
      endelse
      
      ;; check the scan was reduced correctly
      if info1.status ne 1 then begin
         tau_elev_corr1 = exp(info1.result_tau_1mm/sin(info1.result_elevation_deg*!dtor))
         tau_elev_corr2 = exp(info1.result_tau_2mm/sin(info1.result_elevation_deg*!dtor))

         if init_done eq 0 then begin
            info = info1        ; init
            info.nscan = 1
            neffscan = 1
            info.obs_type = info1.obs_type ; init
            output_grid          = grid1
            info.polar           = info1.polar
            param.source = param1.source
            param.map_center_ra  = param1.map_center_ra
            param.map_center_dec = param1.map_center_dec

            ;; Init the .csv file that contains all the photometric information
            tags = tag_names(info1)
            wtags = where( strupcase( strmid(tags,0,6)) eq "RESULT", nwtags)
            tag_length = strlen( tags)
            get_lun, file_unit
            suffix = ''
            filen = project_dir+'/photometry_'+ $
                    strtrim(param.name4file,2)+'_'+suffix+ 'v'+strtrim(param.version,2)+'.csv'
            ;; @ Produce a .csv output file that will gather results
            ;; @^ per scan and for their combintation via the
            ;; @^ structure info.
;            openw, file_unit, filen
            title_string = 'Scan, Source, RA, DEC'
            for i=0, nwtags-1 do title_string = title_string+", "+strmid( tags[wtags[i]],7,tag_length[wtags[i]]-7)
;            printf, file_unit, title_string
            grid_tot = grid1
;            grid_jk  = grid1
            init_done = 1
         endif

         if strupcase( strtrim( info1.obs_type,2)) ne strupcase( strtrim( info.obs_type,2)) then info.obs_type = 'Mixed'
         
         ;; If we want to weight the map by its map rms for future coaddition
         ;; (to try... NP, March 9th, 2016).
         if param.w8_map_rms eq 1 then begin
            stokes = ['I', 'Q', 'U']
            for iarray=1, 3 do begin
               r = nk_tag_exist( grid1, "Nhits_"+strtrim(iarray,2), wi)
               if r eq 1 then begin
                  wpix = where( sqrt( grid1.xmap^2 + grid1.ymap^2) lt param.w8_map_rms_radius and $
                                grid1.(wi) ne 0, nwpix)
                  if nwpix eq 0 then begin
                     txt = "No valid pixel to derive a map rms"
                     nk_error, info, txt
                     return
                  endif
                  
                  for istokes=0, 2 do begin
                     r1 = nk_tag_exist( grid1, "map_"+Stokes[istokes]+strtrim(iarray,2), wq)
                     r2 = nk_tag_exist( grid1, "map_var_"+Stokes[istokes]+strtrim(iarray,2), wvarq)
                     if r1 eq 1 then begin
                        map = grid1.(wq)
                        grid1.(wvarq) = stddev( map[wpix])^2
                     endif
                  endfor
               endif
            endfor
         endif 
         
         if iscan ge 1 and defined(grid_tot) then begin
            ;; @ {\tt nk_average_grids} combines scan results on the
            ;; @^ fly with inverse variance noise weighting.
            nk_average_grids, grid_tot, grid1, junk, sign=sign_list[iscan], $
                              bypass_unmatched_grid = bypass_unmatched_grid
            grid_tot = temporary(junk)
            
            ;; Update info (total or average quantities)
            info.result_total_obs_time         += info1.result_total_obs_time
            info.result_valid_obs_time         += info1.result_valid_obs_time
;;            info.result_time_matrix_center_1   += info1.result_time_matrix_center_1
;;            info.result_time_matrix_center_2   += info1.result_time_matrix_center_2
;;            info.result_time_matrix_center_3   += info1.result_time_matrix_center_3
;;            info.result_time_matrix_center_1mm += info1.result_time_matrix_center_1mm
;;            info.result_time_matrix_center_2mm += info1.result_time_matrix_center_2mm
            
            info.nscan          += 1
            neffscan            += 1
            info.result_tau_1mm += info1.result_tau_1mm
            info.result_tau_2mm += info1.result_tau_2mm
            info.az_source      += info1.az_source
            info.el_source      += info1.el_source
            
            info.RESULT_NKIDS_TOT1   += info1.RESULT_NKIDS_TOT1
            info.RESULT_NKIDS_TOT2   += info1.RESULT_NKIDS_TOT2
            info.RESULT_NKIDS_TOT3   += info1.RESULT_NKIDS_TOT3
            info.RESULT_NKIDS_VALID1 += info1.RESULT_NKIDS_VALID1
            info.RESULT_NKIDS_VALID2 += info1.RESULT_NKIDS_VALID2
            info.RESULT_NKIDS_VALID3 += info1.RESULT_NKIDS_VALID3
         endif

         ;;================================================================================================
         ;; To avoid photometry and failures when we project on
         ;; external headers not centered on the observed region
         if not keyword_set(average_only) then begin
            
            ;; redo photometry if requested and if maps have already been
            ;; produced. This avoids to reprocess all the maps if we want
            ;; to change only e.g. the aperture photometry radius...
            if keyword_set(photometry) then begin
               ;; Aperture photometry directly puts all the results into info
               if param.do_aperture_photometry eq 1 then begin
                  nk_aperture_photometry_3, param1, info1, grid1
               endif
               nk_grid2info, grid1, info_out, info_in=info1, noplot=(1 - long( param.do_plot)), $
                             educated = param.educated, iconic = param.iconic, ps = param.plot_ps, $
                             plot_dir = param.plot_dir, nickname = param1.scan, $
                             ata_fit_beam_rmax=param.ata_fit_beam_rmax, noboost = noboost
               info1 = info_out
            endif

            ;; Update .csv
            res_string   = strtrim(param1.scan,2)+", "+strtrim(param1.source,2)+$
                           ", "+strtrim(info1.longobj,2)+", "+strtrim(info1.latobj,2)
            for i=0, nwtags-1 do res_string   = res_string+", "+strtrim( info1.(wtags[i]),2)
;            printf, file_unit, res_string
            
            ;; For cumulative plots
            if keyword_set(cumul) then begin

            if keyword_set(center_nefd_only) then input_fit_par = [1.d0, 1.d0, 0.d0, 0.d0, 0.d0, 0.d0, 0.d0]
            nk_grid2info, grid_tot, info_temp, aperture_photometry=param.do_aperture_photometry, $
                          title=param.source+" "+param1.scan, educated=param.educated, $
                          all_time_matrix_center=all_time_matrix_center, $
                          all_flux_source=all_flux_source, all_sigma_flux_source=all_sigma_flux_source, $
                          all_flux_center=all_flux_center, all_sigma_flux_center=all_sigma_flux_center, $
                          ata_fit_beam_rmax=param.ata_fit_beam_rmax, all_t_gauss_beam=all_t_gauss_beam, $
                          /noplot, noboost = noboost

            ;; attention, l'ordre change entre all_flux de
            ;; nk_grid2info et de l'ancien nk_map_photometry_3
            flux_cumul[              iscan,*] = reform(all_flux_source)
            sigma_flux_cumul[        iscan,*] = reform(all_sigma_flux_source)
            flux_center_cumul[       iscan,*] = reform(all_flux_center)
            sigma_flux_center_cumul[ iscan,*] = reform(all_sigma_flux_center)
            
            if keyword_set(tau_w8) then begin
               if iscan eq 0 then begin
                  time_center_cumul[ iscan, 0]  = info1.result_time_matrix_center_1/tau_elev_corr1^2
                  time_center_cumul[ iscan, 1]  = info1.result_time_matrix_center_1/tau_elev_corr1^2
                  time_center_cumul[ iscan, 2]  = info1.result_time_matrix_center_1/tau_elev_corr1^2
                  time_center_cumul[ iscan, 3]  = info1.result_time_matrix_center_2/tau_elev_corr2^2
                  time_center_cumul[ iscan, 4]  = info1.result_time_matrix_center_2/tau_elev_corr2^2
                  time_center_cumul[ iscan, 5]  = info1.result_time_matrix_center_2/tau_elev_corr2^2
                  time_center_cumul[ iscan, 6]  = info1.result_time_matrix_center_3/tau_elev_corr1^2
                  time_center_cumul[ iscan, 7]  = info1.result_time_matrix_center_3/tau_elev_corr1^2
                  time_center_cumul[ iscan, 8]  = info1.result_time_matrix_center_3/tau_elev_corr1^2
                  time_center_cumul[ iscan, 9]  = info1.result_time_matrix_center_1mm/tau_elev_corr1^2
                  time_center_cumul[ iscan, 10] = info1.result_time_matrix_center_1mm/tau_elev_corr1^2
                  time_center_cumul[ iscan, 11] = info1.result_time_matrix_center_1mm/tau_elev_corr1^2

                  time_gauss_beam_cumul[ iscan, 0]  = info1.result_t_gauss_beam_1/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 1]  = info1.result_t_gauss_beam_1/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 2]  = info1.result_t_gauss_beam_1/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 3]  = info1.result_t_gauss_beam_2/tau_elev_corr2^2
                  time_gauss_beam_cumul[ iscan, 4]  = info1.result_t_gauss_beam_2/tau_elev_corr2^2
                  time_gauss_beam_cumul[ iscan, 5]  = info1.result_t_gauss_beam_2/tau_elev_corr2^2
                  time_gauss_beam_cumul[ iscan, 6]  = info1.result_t_gauss_beam_3/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 7]  = info1.result_t_gauss_beam_3/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 8]  = info1.result_t_gauss_beam_3/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 9]  = info1.result_t_gauss_beam_1mm/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 10] = info1.result_t_gauss_beam_1mm/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 11] = info1.result_t_gauss_beam_1mm/tau_elev_corr1^2
               endif else begin
                  time_center_cumul[ iscan, 0]  = time_center_cumul[ iscan-1, 0]  + info1.result_time_matrix_center_1/tau_elev_corr1^2
                  time_center_cumul[ iscan, 1]  = time_center_cumul[ iscan-1, 1]  + info1.result_time_matrix_center_1/tau_elev_corr1^2
                  time_center_cumul[ iscan, 2]  = time_center_cumul[ iscan-1, 2]  + info1.result_time_matrix_center_1/tau_elev_corr1^2
                  time_center_cumul[ iscan, 3]  = time_center_cumul[ iscan-1, 3]  + info1.result_time_matrix_center_2/tau_elev_corr2^2
                  time_center_cumul[ iscan, 4]  = time_center_cumul[ iscan-1, 4]  + info1.result_time_matrix_center_2/tau_elev_corr2^2
                  time_center_cumul[ iscan, 5]  = time_center_cumul[ iscan-1, 5]  + info1.result_time_matrix_center_2/tau_elev_corr2^2
                  time_center_cumul[ iscan, 6]  = time_center_cumul[ iscan-1, 6]  + info1.result_time_matrix_center_3/tau_elev_corr1^2
                  time_center_cumul[ iscan, 7]  = time_center_cumul[ iscan-1, 7]  + info1.result_time_matrix_center_3/tau_elev_corr1^2
                  time_center_cumul[ iscan, 8]  = time_center_cumul[ iscan-1, 8]  + info1.result_time_matrix_center_3/tau_elev_corr1^2
                  time_center_cumul[ iscan, 9]  = time_center_cumul[ iscan-1, 9]  + info1.result_time_matrix_center_1mm/tau_elev_corr1^2
                  time_center_cumul[ iscan, 10] = time_center_cumul[ iscan-1, 10] + info1.result_time_matrix_center_1mm/tau_elev_corr1^2
                  time_center_cumul[ iscan, 11] = time_center_cumul[ iscan-1, 11] + info1.result_time_matrix_center_1mm/tau_elev_corr1^2

                  time_gauss_beam_cumul[ iscan, 0]  = time_gauss_beam_cumul[ iscan-1, 0]  + info1.result_t_gauss_beam_1/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 1]  = time_gauss_beam_cumul[ iscan-1, 1]  + info1.result_t_gauss_beam_1/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 2]  = time_gauss_beam_cumul[ iscan-1, 2]  + info1.result_t_gauss_beam_1/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 3]  = time_gauss_beam_cumul[ iscan-1, 3]  + info1.result_t_gauss_beam_2/tau_elev_corr2^2
                  time_gauss_beam_cumul[ iscan, 4]  = time_gauss_beam_cumul[ iscan-1, 4]  + info1.result_t_gauss_beam_2/tau_elev_corr2^2
                  time_gauss_beam_cumul[ iscan, 5]  = time_gauss_beam_cumul[ iscan-1, 5]  + info1.result_t_gauss_beam_2/tau_elev_corr2^2
                  time_gauss_beam_cumul[ iscan, 6]  = time_gauss_beam_cumul[ iscan-1, 6]  + info1.result_t_gauss_beam_3/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 7]  = time_gauss_beam_cumul[ iscan-1, 7]  + info1.result_t_gauss_beam_3/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 8]  = time_gauss_beam_cumul[ iscan-1, 8]  + info1.result_t_gauss_beam_3/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 9]  = time_gauss_beam_cumul[ iscan-1, 9]  + info1.result_t_gauss_beam_1mm/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 10] = time_gauss_beam_cumul[ iscan-1, 10] + info1.result_t_gauss_beam_1mm/tau_elev_corr1^2
                  time_gauss_beam_cumul[ iscan, 11] = time_gauss_beam_cumul[ iscan-1, 11] + info1.result_t_gauss_beam_1mm/tau_elev_corr1^2
               endelse
            endif else begin
               ;; Sept. 25th
               time_center_cumul[     iscan,*] = reform( all_time_matrix_center)
               time_gauss_beam_cumul[ iscan,*] = reform( all_t_gauss_beam)
            endelse

            endif
         endif
      endif
   endelse
endfor
      
   
;close, 1
;stop

if init_done eq 0 then begin    ; no scan could be used
   nk_default_info, info
   nk_error, info, "No valid scans could be averaged"
   return
endif else begin

   ;; Average informations on scans (for info in the products .fits file)
   info.longobj         = info1.longobj
   info.latobj          = info1.latobj
   info.object          = info1.object
   info.result_tau_1mm /= info.nscan
   info.result_tau_2mm /= info.nscan
   info.az_source      /= info.nscan
   info.el_source      /= info.nscan
   info.RESULT_NKIDS_TOT1   /= float(info.nscan)
   info.RESULT_NKIDS_TOT2   /= float(info.nscan)
   info.RESULT_NKIDS_TOT3   /= float(info.nscan)
   info.RESULT_NKIDS_VALID1 /= float(info.nscan)
   info.RESULT_NKIDS_VALID2 /= float(info.nscan)
   info.RESULT_NKIDS_VALID3 /= float(info.nscan)

   ;; Compute final photometries and display result
   param.plot_dir = project_dir + '/Plots'  ; param and plot_dir keywords are a bit redundant (FXD)
   if nscans eq 1 then suffix = '_v'+param.version else suffix = '_nsc'+strtrim(nscans, 2)+'_v'+strtrim(param.version,2)

   if not keyword_set(average_only) then begin
      ;; @ {\tt nk_grid2info} computes the final photometry on
      ;; @^ the combined map, finds the source centroid location etc...
      nk_grid2info, grid_tot, info_out, info_in=info, noplot_in=noplot, $
                    imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                    imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                    imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                    imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                    aperture_photometry = param.do_aperture_photometry, param = param, $
                    plot_dir = project_dir + '/Plots', $
                    ps = param.plot_ps, png = param.plot_png, educated=param.educated, $
                    title =  param.name4file, $
                    nickname = strtrim(info1.object,2)+'_'+strtrim( scan_list[0], 2)+ suffix, $
                    old_formula=param.old_pol_deg_formula, ata_fit_beam_rmax=param.ata_fit_beam_rmax, $
                    noboost = noboost
      info = info_out
   endif
   info.nscan = nscans
   
   ;; Update .csv file with the results of all scans cumulated
   res_string   = "# "+strtrim( neffscan, 2)+" scans combined, "+strtrim(param.source,2)+ $
                  ", "+strtrim(info.longobj,2)+", "+strtrim(info.latobj,2)
   for i=0, nwtags-1 do res_string   = res_string+", "+strtrim( info.(wtags[i]),2)
;   printf, file_unit, res_string
;   close, file_unit
;   free_lun, file_unit
endelse

;; Update LaTeX documents with all maps
if param.plot_ps eq 1 then nk_latex_project_report, param, scan_list, project_dir=project_dir

loadct, 39,  /silent
if defined( file_unit) then free_lun, file_unit

;; Write output fits map
param1 = param
param1.output_dir = project_dir

if not keyword_set(nofits) then begin
; When several scans are coadded change the suffix of fits files
;; @ {\tt nk_map2fits_3} produces a .fits file with the combined maps,
;; @^ the param structure and various information from info.
;; @^ 'header' comes from the restore of results.save
   if tag_exist(grid_tot,"nhits_2mm") then begin
      grid_tot.nhits_2mm = grid_tot.nhits_2
;      grid_jk.nhits_2mm = grid_jk.nhits_2
   endif
   grid_tot.map_i_2mm = grid_tot.map_i2
   grid_tot.map_var_i_2mm = grid_tot.map_var_i2
;   grid_jk.map_i_2mm = grid_jk.map_i2
;   grid_jk.map_var_i_2mm = grid_jk.map_var_i2
   if tag_exist(grid_tot,"map_var_q_2mm") then begin
      grid_tot.map_var_q_2mm = grid_tot.map_var_q2
      grid_tot.map_var_u_2mm = grid_tot.map_var_u2
      grid_tot.map_q_2mm = grid_tot.map_q2
      grid_tot.map_u_2mm = grid_tot.map_u2
 ;     grid_jk.map_var_q_2mm = grid_jk.map_var_q2
 ;     grid_jk.map_var_u_2mm = grid_jk.map_var_u2
 ;     grid_jk.map_q_2mm = grid_jk.map_q2
 ;     grid_jk.map_u_2mm = grid_jk.map_u2
   endif

   writefits, param.project_dir+'/map_i_1mm_jk_set_'+nickname+'.fits', grid_tot.map_i_1mm
   writefits, param.project_dir+'/map_std_i_1mm_jk_set_'+nickname+'.fits', sqrt(grid_tot.map_var_i_1mm)
   writefits, param.project_dir+'/map_i_2mm_jk_set_'+nickname+'.fits', grid_tot.map_i2
   writefits, param.project_dir+'/map_std_i_2mm_jk_set_'+nickname+'.fits', sqrt(grid_tot.map_var_i2)

;   nk_map2fits_3, param1, info, grid_tot, output_fits_file=output_fits_file, header=header
;   l = strlen(output_fits_file)
;   jk_file = strmid(output_fits_file,0,l-5)+"_JK.fits"
;   nk_map2fits_3, param1, info, grid_jk,  output_fits_file=jk_file, header=header
endif

end
