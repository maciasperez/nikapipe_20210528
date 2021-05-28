;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_average_scans
;
; CATEGORY:
;
; CALLING SEQUENCE:
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
;        - June 13th 2014, NP
;        - June 16th, 2015: add the /cumul option, NP
;          - Oct. 17th, 2015: NP, clean up nk_average_scan (most
;            results can be retrieved from the photometry.csv instead)
;            and adapted to NIKA2.

pro nk_average_scans, param, scan_list, grid_tot, grid_jk0, info=info, $
                      imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                      imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                      imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                      imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                      noplot=noplot, beam_pos_list = beam_pos_list, syst_err = syst_err, $
                      sigma_beam_pos = sigma_beam_pos, cumul = cumul, step=step, $
                      photometry=photometry, $
                      flux_cumul=flux_cumul, sigma_flux_cumul=sigma_flux_cumul, $
                      flux_center_cumul=flux_center_cumul, sigma_flux_center_cumul=sigma_flux_center_cumul, $
                      time_center_cumul=time_center_cumul, center_nefd_only=center_nefd_only, parity=parity, $
                      project_dir=project_dir, output_fits_file=output_fits_file, $
                      average_only=average_only, sum_one_over_sigma_flux_center_sq=sum_one_over_sigma_flux_center_sq, $
                      nofits=nofits, noboost = noboost, time_gauss_beam_cumul=time_gauss_beam_cumul, $
                      tau_w8=tau_w8, $
                      bypass_unmatched_grid = bypass_unmatched_grid, results2=results2, pdf = k_pdf, $
                      dmm_grid_tot=dmm_grid_tot
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_average_scans'
   return
endif

nscans        = n_elements(scan_list)
neffscan      = 0               ; effective number of scans used in the combination
do_projection = 0
init_done     = 0
stokes        = ['I', 'Q', 'U']

time_gauss_beam_cumul             = dblarr(nscans, 15)   ; 12) ; 15)
time_center_cumul                 = dblarr(nscans, 15)   ; 12) ; 15)
flux_cumul                        = dblarr(nscans, 15)   ; 12) ; 15)
sigma_flux_cumul                  = dblarr(nscans, 15)   ; 12) ; 15)
flux_center_cumul                 = dblarr(nscans, 15)   ; 12) ; 15)
sigma_flux_center_cumul           = dblarr(nscans, 15)   ; 12) ; 15)
sum_one_over_sigma_flux_center_sq = dblarr(nscans, 15)   ; 12) ; 15)

if not keyword_set(project_dir) then project_dir = param.project_dir
if not keyword_set(step)        then step = 1

;; Which scans were processed
keep = intarr(nscans)
scan_angle = fltarr( nscans)
for iscan=0, nscans-1 do begin
   dir = project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim( scan_list[iscan], 2)
   if file_test(dir+"/info.csv") then begin
      nk_read_csv_2, dir+"/info.csv", info1
      if info1.status ne 1 then begin
         keep[iscan]=1
         scan_angle[iscan] = info1.scan_angle
      endif
   endif
endfor
wkeep = where( keep eq 1, nwkeep)
if param.silent lt 2 then message, /info, "Found "+strtrim(nwkeep,2)+" reduced scans out of the requested "+strtrim(nscans,2)
if nwkeep eq 0 then begin
   message, /info, "No scan reduced, exiting:"
   return
endif
nkeep_jk = nwkeep
if (nkeep_jk mod 2) eq 1 then nkeep_jk--
scan_list    = scan_list[wkeep]
scan_angle   = scan_angle[wkeep]
nscans       = n_elements(scan_list)
jk_sign_list = (-1.d0)^indgen(nscans)

if keyword_set( param.split_horver) then begin
   hor = where( scan_angle gt param.split_hor1 and $
                scan_angle lt param.split_hor2, nhor)
   if param.split_horver eq 1 or param.split_horver eq 2 then begin
      jk_sign_list[*] = -1d0
      if nhor gt 0 then jk_sign_list[ hor] = +1D0
                                ; JK map will be made of (Hor-Ver)/2
      if abs(nhor - nscans/2) gt nscans/10 then $
         print, 'Hor. Vert. scans not very well balanced, ' + $
                'consider changing param.split_hor1 and 2'
   endif else begin             ; Assumes 3
      jk_sign_list[*] = +1d0
      info_all_csv_file = param.project_dir+ $
                          '/info_all_'+ param.source+ $
                             '_v'+ strtrim(param.version, 2)+'.csv'
      message, /info, 'info_all_csv_file '+ info_all_csv_file
      nk_read_csv_3, info_all_csv_file, inforead
      if nscans gt n_elements( inforead) then $
         message, 'Inconsistency on number of valid scans'
      hor_all = inforead.scan_angle gt param.split_hor1 and $
                inforead.scan_angle lt param.split_hor2
      nk_jk_horver_scan_assign, hor_all, pindex1, jksign1
      match, scan_list, inforead.scan, ia, ib
      jk_sign_list[ia] = jksign1[ ib]  ; graceful matching
   endelse 
endif

if param.n_jk_maps ge 2 then begin
   for ijk=1, param.n_jk_maps-1 do begin
      junk = lindgen(nscans)
      order = junk[ sort( randomu( seed, nscans))]
      junk = execute( "jk_sign_list_"+strtrim(ijk,2)+" = jk_sign_list[order]")
   endfor
endif

;; Main loop
for iscan=0, nscans-1 do begin

   dir = project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim( scan_list[iscan], 2)
   if keyword_set(results2) then begin
      file_save = dir+"/results_2.save"
   endif else begin
      file_save = dir+"/results.save"
   endelse
   ;; @ Restore results of each individual scan
   if file_test(file_save) then begin
      restore, file_save
      if param.silent lt 2 then percent_status, iscan, nscans, 10, message='nk_average_scans'

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
      endelse
      
      ;; check the scan was reduced correctly
;   if info1.status ne 1 then begin
      tau_elev_corr1 = exp(info1.result_tau_1mm/sin(info1.result_elevation_deg*!dtor))
      tau_elev_corr2 = exp(info1.result_tau_2mm/sin(info1.result_elevation_deg*!dtor))

      if init_done eq 0 then begin
         info = info1           ; init
         info.nscan = 1
         neffscan = 1
         info.obs_type = info1.obs_type ; init
;;;FXD: this variable does not seem to be used
;;;output_grid          = grid1
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
         openw, file_unit, filen
         title_string = 'Scan, Source, RA, DEC'
         for i=0, nwtags-1 do title_string = title_string+", "+strmid( tags[wtags[i]],7,tag_length[wtags[i]]-7)
         printf, file_unit, title_string
         grid_tot = grid1
         grid_jk0  = grid1
         if keyword_set( param.split_horver) then begin
            grid_hor = grid1
            grid_ver = grid1
         endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;         dp = {coltable:4, imrange:[-1,1]/50., fwhm:3., $
;;               xmap:grid1.xmap, ymap:grid1.ymap, legend_text:"iscan = "+strtrim(iscan,2), nobar:1, $
;;               charsize:0.6}
;;         imview, grid_tot.map_i_1mm, dp=dp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



         ;; extra JK maps if requested
         if param.n_jk_maps ge 2 then begin
            for ijk=1, param.n_jk_maps-1 do begin
               junk = execute( "grid_jk"+strtrim(ijk,2)+" = grid1")
            endfor
         endif

         init_done = 1
      endif

      if strupcase( strtrim( info1.obs_type,2)) ne strupcase( strtrim( info.obs_type,2)) then info.obs_type = 'Mixed'
      
      ;; If we want to weigh the map by its map rms for future coaddition
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

         if param.use_flux_var_w8 ne 0 then begin
            ;; rather than weighting the average by the variance per
            ;; pixel, use the variance per beam (=> sigma_boost)
            stokes = ['I', 'Q', 'U']
            ext = ['1', '2', '3', '_1mm']
            fwhm_list = [!nika.fwhm_array, !nika.fwhm_array[0]]
            grid_step = [!nika.grid_step, !nika.grid_step[0]]
            grid_tags = strupcase( tag_names(grid1))
            for istokes=0, n_elements(stokes)-1 do begin
               for iext=0, n_elements(ext)-1 do begin
                  wmap  = where( grid_tags eq "MAP_"+stokes[istokes]+ext[iext], nwmap)
                  wvar  = where( grid_tags eq "MAP_VAR_"+stokes[istokes]+ext[iext], nwvar)
                  whits = where( grid_tags eq "NHITS_"+ext[iext], nwhits)
                  if nwmap ne 0 and nwvar ne 0 and nwhits ne 0 then begin
                     nk_map_photometry, grid1.(wmap), grid1.(wvar), grid1.(whits), grid1.xmap, grid1.ymap, $
                                        fwhm_list[iext], $
                                        map_var_flux = map_var_flux, grid_step=grid_step[iext]
                     ;; replace grid.(wvar)
                     grid1.(wvar) = map_var_flux
                  endif
               endfor
            endfor
         endif
         nk_average_grids, grid_tot, grid1, junk, $
                           bypass_unmatched_grid = bypass_unmatched_grid, $
                           no_variance_w8=param.no_variance_w8
         grid_tot = temporary(junk)
         ;; print, minmax( grid_tot.map_i1), $
         ;;        minmax( grid_tot.map_var_i1), scan_list[iscan]
         ;; print, minmax( grid1.map_i1), $
         ;;        minmax( sqrt(grid1.map_var_i1)), scan_list[iscan]
         if param.do_dmm eq 1 then begin
            restore, dir+"/dmm.save"
            if defined(dmm_grid_tot) eq 0 then begin
               dmm_grid_tot = dmm_grid
            endif else begin
               nk_average_grids, dmm_grid_tot, dmm_grid, junk
               dmm_grid_tot = temporary(junk)
            endelse
         endif
         
;;            wind, 1, 1, /free, /large
;;            my_multiplot, 2, 1, pp, pp1, /rev
;;            imview, grid1.map_i_1mm, imr=[-1,1]/5., title='scan '+strtrim(scan_list[iscan],2), $
;;                    position=pp1[0,*]
;;            imview, grid_tot.map_i_1mm, imr=[-1,1]/5., title='grid_tot', /noerase, $
;;                    position=pp1[1,*]
;;            stop

         
;         imview, grid_tot.map_i2, title=scan_list[iscan], imr=[-1,1]/500.


;; ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;          dp = {coltable:4, imrange:[-1,1]/50., fwhm:3., $
;;                xmap:grid1.xmap, ymap:grid1.ymap, legend_text:"iscan = "+strtrim(iscan,2), nobar:1, $
;;                charsize:0.6}
;;          imview, grid_tot.map_i_1mm, dp=dp
;; ;stop
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;


         ;; Jackknife: on an even number of scans.
         if iscan lt nkeep_jk then begin
            nk_average_grids, grid_jk0, grid1, junk, $
                              sign=jk_sign_list[iscan], $
                              bypass_unmatched_grid = bypass_unmatched_grid, $
                              no_variance_w8=param.no_variance_w8

;;          wind, 1, 1, /free, /xlarge
;;          my_multiplot, 3, 1, pp, pp1
;;          imview, grid_jk0.map_i_1mm, imr=[-1,1]/100., fwhm=5, position=pp1[0,*], title=strtrim(iscan,2)
;;          imview, grid1.map_i_1mm, imr=[-1,1]/100., fwhm=5., position=pp1[1,*], /noerase, title=strtrim(jk_sign_list[iscan],2)
;;          imview, junk.map_i_1mm, imr=[-1,1]/100., fwhm=5., position=pp1[2,*], /noerase
;;          print, info1.result_flux_i_1mm, info1.result_flux_i2
;;          stop
            
            grid_jk0 = temporary(junk)

            if param.n_jk_maps ge 2 then begin
               for ijk=1, param.n_jk_maps-1 do begin
                  bidon = execute( "my_grid = grid_jk"+strtrim(ijk,2))
                  bidon = execute( "my_sign_list = jk_sign_list_"+strtrim(ijk,2))
                  nk_average_grids, my_grid, grid1, junk, $
                                    sign=my_sign_list[iscan], $
                                    bypass_unmatched_grid = bypass_unmatched_grid, $
                                    no_variance_w8=param.no_variance_w8
                  bidon = execute( "grid_jk"+strtrim(ijk,2)+" = temporary(junk)")
               endfor
            endif 

         endif 
         if keyword_set( param.split_horver) then begin
            if jk_sign_list[ iscan] gt 0 then begin ; put it in hor map
               nk_average_grids, grid_hor, grid1, junk, sign=1, $
                              bypass_unmatched_grid = bypass_unmatched_grid, $
                              no_variance_w8=param.no_variance_w8
               grid_hor = temporary(junk)
            endif else begin ; put it in the vert. map
               nk_average_grids, grid_ver, grid1, junk, sign=1, $
                              bypass_unmatched_grid = bypass_unmatched_grid, $
                              no_variance_w8=param.no_variance_w8            
               grid_ver = temporary(junk)
            endelse
          endif
         ;; Update info (total or average quantities)
         info.result_total_obs_time         += info1.result_total_obs_time
         info.result_valid_obs_time         += info1.result_valid_obs_time
         
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
         tags = tag_names(info1)
         wtags = where( strupcase( strmid(tags,0,6)) eq "RESULT", nwtags)
         for i=0, nwtags-1 do res_string   = res_string+", "+strtrim( info1.(wtags[i]),2)
         printf, file_unit, res_string
         
         ;; For cumulative plots
         if keyword_set(cumul) then begin

            if (iscan mod step) eq 0 then begin
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
            endif
            
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
   endif else begin
      message, /info, "could not find "+file_save
   endelse
endfor    ; end loop on iscan

;; Subtract everywhere the average of the map at large radius if
;; requested (to force the overall zero level).
if param.outskirt_zero_radius ge 0.d0 then begin
   grid_tags = tag_names(grid_tot)
   field_list = ['i1', 'i2', 'i3', 'i_1mm', 'i_2mm', $
                 'q1', 'q2', 'q3', 'q_1mm', $
                 'u1', 'u2', 'u3', 'u_1mm']
   for ifield=0, n_elements(field_list)-1 do begin
      wmap = where( strupcase(grid_tags) eq "MAP_"+strupcase(field_list[ifield]), nwmap)
      wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+strupcase(field_list[ifield]), nwvar)
      if nwmap ne 0 then begin
         wout = where( sqrt( grid_tot.xmap^2 + grid_tot.ymap^2) gt param.outskirt_zero_radius and $
                       grid_tot.(wvar) gt 0.d0, nwout)
         win = where( grid_tot.(wvar) gt 0.d0, nwout)
         if nwout ne 0 then begin
            map    = grid_tot.(wmap)
            sigma2 = grid_tot.(wvar)
            map[win] -= total( map[wout]/sigma2[wout])/total(1.d0/sigma2[wout])
            grid_tot.(wmap) = map
         endif
      endif
   endfor
endif

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
   param.plot_dir = project_dir + '/Plots' ; param and plot_dir keywords are a bit redundant (FXD)
   if nscans eq 1 then suffix = '_v'+param.version else suffix = '_nsc'+strtrim(nscans, 2)+'_v'+strtrim(param.version,2)

     if not keyword_set(average_only) then begin
        ;; @ {\tt nk_grid2info} computes the final photometry on
        ;; @^ the combined map, finds the source centroid location
        ;; etc...
        parici = param
        parici.noiseup = 0
        nk_grid2info, grid_tot, info_out, info_in=info, noplot_in=noplot, $
                      imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                      imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                      imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                      imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                      aperture_photometry = param.do_aperture_photometry, param = parici, $
                      plot_dir = project_dir + '/Plots', $
                      ps = param.plot_ps, png = param.plot_png, educated=param.educated, $
                      title =  param.name4file, $
                      nickname = strtrim(info1.object,2)+'_'+strtrim( scan_list[0], 2)+ suffix, $
                      old_formula=param.old_pol_deg_formula, ata_fit_beam_rmax=param.ata_fit_beam_rmax, $
                      noboost = noboost;, pdf = k_pdf
; NB: The noise boost (via this routine) is computed and stored in info but not applied to the maps
        info = info_out
     endif
     info.nscan = nscans
     
     ;; Update .csv file with the results of all scans cumulated
     res_string   = "# "+strtrim( neffscan, 2)+" scans combined, "+strtrim(param.source,2)+ $
                    ", "+strtrim(info.longobj,2)+", "+strtrim(info.latobj,2)
     tags = tag_names(info)
     wtags = where( strupcase( strmid(tags,0,6)) eq "RESULT", nwtags)
     for i=0, nwtags-1 do res_string   = res_string+", "+strtrim( info.(wtags[i]),2)
;   printf, file_unit, res_string
;   close, file_unit
;   free_lun, file_unit
  endelse

;; Update LaTeX documents with all maps
if param.plot_ps eq 1 then $
   nk_latex_project_report, param, scan_list, project_dir=project_dir

loadct, 39,  /silent
if defined( file_unit) then free_lun, file_unit

;; Write output fits map
param1 = param
param1.output_dir = project_dir
if not keyword_set(nofits) then begin

; need to truncate output map
   if param.method_num eq 120 then begin
; we truncate at the coaddition level (truncate_map will be used for
; all grids)
      nk_truncate_filter_map, param, info, grid_tot, truncate_map = truncate_map
   endif

                                ; Prepare zero mask if any
   bgzl_mask_1mm = 0
   bgzl_mask_2mm = 0
   if strlen( param.zero_mask_fits_file) ne 0 then begin
      if file_test( param.zero_mask_fits_file) then begin
         nk_fits2grid, param.zero_mask_fits_file, gridmask
         bgzl_mask_1mm = gridmask.zero_level_mask_1mm
         bgzl_mask_2mm = gridmask.zero_level_mask_2mm
      endif else message, /info, param.zero_mask_fits_file+ ' could not be found, all pixels will be used for background estimation'
   endif
   
   ;;; FXD Jan 2021: we do JK processing first in order to save the
   ;;; boosts and apply them to the maps
;;; ----------------  JK processing and Saving ---------------------
   infojk = info
   if keyword_set( output_fits_file) then begin
   ;; Write JK maps to disk
   l = strlen(output_fits_file)
   for ijk=0, param.n_jk_maps-1+2*keyword_set( param.split_horver) do begin
; Main loop on JK maps
      
      if ijk eq 0 then begin
         jk_file = strmid(output_fits_file,0,l-5)+"_JK.fits"
      endif else begin
         jk_file = strmid(output_fits_file,0,l-5)+"_JK_"+strtrim(ijk,2)+".fits"
      endelse
      if ijk le param.n_jk_maps-1 then junk = $
         execute( "my_grid = grid_jk"+strtrim(ijk,2))
      if keyword_set( param.split_horver) then begin
         if ijk eq param.n_jk_maps then begin
            junk = execute( 'my_grid = grid_hor')
            jk_file = strmid(output_fits_file,0,l-5)+"_HOR.fits"
         endif
         if ijk eq param.n_jk_maps+1 then begin
            junk = execute( 'my_grid = grid_ver')
            jk_file = strmid(output_fits_file,0,l-5)+"_VER.fits"
         endif
      endif

      gx = my_grid.xmap
      gy = my_grid.ymap

      my_grid.map_i_2mm = my_grid.map_i2
      my_grid.map_var_i_2mm = my_grid.map_var_i2
      if tag_exist(grid_tot,"map_var_q_2mm") then begin
         my_grid.map_var_q_2mm = my_grid.map_var_q2
         my_grid.map_var_u_2mm = my_grid.map_var_u2
         my_grid.map_q_2mm = my_grid.map_q2
         my_grid.map_u_2mm = my_grid.map_u2
      endif
      if param.method_num eq 120 then begin
         nk_truncate_filter_map, param, infojk, my_grid, truncate_map = truncate_map
      endif

;; start ATMB specific part for Jacknife 
      if param.method_num eq 120 and keyword_set( param.noiseup) then begin
         wma = where( sqrt( gx^2 + gy^2) ge param.map_bg_zero_level_radius $
                      and truncate_map gt 0.99, nwma)
         my_grid.zero_level_mask = 1
;      my_grid.zero_level_mask = 0
; No for JK      if nwma ne 0 then my_grid.zero_level_mask[ wma] = 1
;1 are pixels which are used for zero level measurement
         
;Analysis of sources
         ;; Nsa = infojk.subscan_arcsec/!nika.fwhm_nom[0] ; how many beams per subscan
         ;; Np = nk_atmb_count_param( info,  param, 1)    ; 1mm
         ;; noiseup = (1./(1.-1.505*Np/Nsa)) ; this part is done at nk_w8 level now
         noiseup = 1.
;         print, noiseup, ' nup jk at 1mm'
         if max(abs(my_grid.map_i_1mm)) gt 0.d0 then begin
            mp = my_grid.map_i_1mm
            mv = my_grid.map_var_i_1mm
            print, 'Boost 1mm JK final map noise & zero level'
            nk_snr_flux_map, mp, mv, $
                             my_grid.nhits_1mm, !nika.fwhm_nom[0], $
                             my_grid.map_reso, infojk, snr_flux_map_1mm, $
                             method = param.k_snr_method, $
                             noiseup = noiseup, $
                             keep_only_high_snr = param.keep_only_high_snr, $
                             k_snr = param.k_snr, found_boost = found_boost, $
                             truncate_map = truncate_map, gridx = gx, gridy = gy, $
                             bg_zero_level_radius = param.map_bg_zero_level_radius, $
                             bg_zero_level_mask = bgzl_mask_1mm
            my_grid.map_i_1mm = mp
            my_grid.map_var_i_1mm = mv
            if ijk eq 0 then jkboost1mm = found_boost  ; save for later
            infojk.result_sigma_boost_i_1mm = found_boost
            
            mp = my_grid.map_i1
            mv = my_grid.map_var_i1
            print, 'Boost 1mm A1 JK final map noise & zero level'
            nk_snr_flux_map, mp, mv, $
                             my_grid.nhits_1, !nika.fwhm_nom[0], $
                             my_grid.map_reso, infojk, snr_flux_map_1, $
                             method = param.k_snr_method, $
                             noiseup = noiseup, $
                             keep_only_high_snr = param.keep_only_high_snr, $
                             k_snr = param.k_snr, found_boost = found_boost, $
                             truncate_map = truncate_map, gridx = gx, gridy = gy, $
                             bg_zero_level_radius = param.map_bg_zero_level_radius, $
                             bg_zero_level_mask = bgzl_mask_1mm
            my_grid.map_i1 = mp
            my_grid.map_var_i1 = mv
            if ijk eq 0 then jkboost1 = found_boost  ; save for later
            infojk.result_sigma_boost_i1 = found_boost
            
            mp = my_grid.map_i3
            mv = my_grid.map_var_i3
            print, 'Boost 1mm A3 JK final map noise & zero level'
            nk_snr_flux_map, mp, mv, $
                             my_grid.nhits_3, !nika.fwhm_nom[0], $
                             my_grid.map_reso, infojk, snr_flux_map_3, $
                             method = param.k_snr_method, $
                             noiseup = noiseup, $
                             keep_only_high_snr = param.keep_only_high_snr, $
                             k_snr = param.k_snr, found_boost = found_boost, $
                             truncate_map = truncate_map, gridx = gx, gridy = gy, $
                             bg_zero_level_radius = param.map_bg_zero_level_radius, $
                             bg_zero_level_mask = bgzl_mask_1mm
            my_grid.map_i3 = mp
            my_grid.map_var_i3 = mv
            if ijk eq 0 then jkboost3 = found_boost  ; save for later
            infojk.result_sigma_boost_i3 = found_boost
         endif
         ;; Nsa = infojk.subscan_arcsec/!nika.fwhm_nom[1]
         ;; Np = nk_atmb_count_param( info,  param, 2)    ; 2mm
         ;; noiseup = (1./(1.-1.505*Np/Nsa)) ; this part is done at
         ;; the nk_w8 level
         noiseup = 1.
;         print, noiseup, ' nup jk at 2mm'
         if max( abs( my_grid.map_i_2mm)) gt 0.d0 then begin
            mp = my_grid.map_i_2mm
            mv = my_grid.map_var_i_2mm
            print, 'Boost 2mm JK final map noise & zero level'
            nk_snr_flux_map, mp, mv, $
                             my_grid.nhits_2mm, !nika.fwhm_nom[1], $
                             my_grid.map_reso, infojk, snr_flux_map_2mm, $
                             method = param.k_snr_method, $
                             noiseup = noiseup, $
                             keep_only_high_snr = param.keep_only_high_snr, $
                             k_snr = param.k_snr, found_boost = found_boost, $
                             truncate_map = truncate_map, $
                             gridx = gx, gridy = gy, $
                             bg_zero_level_radius = param.map_bg_zero_level_radius, $
                             bg_zero_level_mask = bgzl_mask_2mm
            my_grid.map_i_2mm = mp
            my_grid.map_var_i_2mm = mv
            if ijk eq 0 then jkboost2mm = found_boost  ; save for later
            infojk.result_sigma_boost_i_2mm = found_boost
            
            mp = my_grid.map_i2
            mv = my_grid.map_var_i2
            nk_snr_flux_map, mp, mv, $
                             my_grid.nhits_2, !nika.fwhm_nom[1], $
                             my_grid.map_reso, infojk, snr_flux_map_2, $
                             method = param.k_snr_method, $
                             noiseup = noiseup, $
                             keep_only_high_snr = param.keep_only_high_snr, $
                             k_snr = param.k_snr, found_boost = found_boost, $
                             truncate_map = truncate_map, gridx = gx, gridy = gy, $
                             bg_zero_level_radius = param.map_bg_zero_level_radius, $
                             bg_zero_level_mask = bgzl_mask_2mm
            my_grid.map_i2 = mp
            my_grid.map_var_i2 = mv
            if ijk eq 0 then jkboost2 = found_boost  ; save for later
            infojk.result_sigma_boost_i_2mm = found_boost
         endif
      endif
;; End ATMB specific part for Jackknife
      
      nk_map2fits_3, param1, infojk, my_grid, output_fits_file=jk_file, $
                     header=header, scan_list=scan_list

   endfor
   
endif
   
;;; ----------------  END JK processing and Saving ---------------------


;;; ----------------  Start Map processing and Saving ---------------------

; When several scans are coadded change the suffix of fits files
;; @ {\tt nk_map2fits_3} produces a .fits file with the combined maps,
;; @^ the param structure and various information from info.
;; @^ 'header' comes from the restore of results.save
   if tag_exist(grid_tot,"nhits_2mm") then begin
      grid_tot.nhits_2mm = grid_tot.nhits_2
      grid_jk0.nhits_2mm = grid_jk0.nhits_2
      if param.split_horver gt 0 then begin
         grid_hor.nhits_2mm = grid_hor.nhits_2
         grid_ver.nhits_2mm = grid_ver.nhits_2
      endif
   endif
   grid_tot.map_i_2mm = grid_tot.map_i2
   grid_tot.map_var_i_2mm = grid_tot.map_var_i2
   if tag_exist(grid_tot,"map_var_q_2mm") then begin
      grid_tot.map_var_q_2mm = grid_tot.map_var_q2
      grid_tot.map_var_u_2mm = grid_tot.map_var_u2
      grid_tot.map_q_2mm = grid_tot.map_q2
      grid_tot.map_u_2mm = grid_tot.map_u2
   endif


;FXD July 2020
;; start ATMB specific part
; Need to rescale the map in case of ATMB method
   if param.method_num eq 120 and $
      keyword_set( param.noiseup) then begin
;Analysis of sources
;;       Nsa = info.subscan_arcsec/!nika.fwhm_nom[0] ; how many beams per subscan
;; ; How many parameters in atmb method: atm, atmbis, datm, atm^2 and max 5 subbands for
;; ; 1 scan, 2*nharm+ (offset and no slope) per subscan
;;       Np = nk_atmb_count_param( info,  param, 1) ; 1mm
;; ; Noise ( and low signal) is reduced by 
;;       noiseup = (1./(1. - (1.505*Np)/Nsa)) ; this part is done at the map making level here at the coaddition stage
; This was a mistake (sqrt) and an approximation
;      noiseup = sqrt(Nsa/(Nsa-Np)) ; before 29 september 2020
;      (i.e. including version I)
;      noiseup is done at the individual map level but we still need
;      it here to correct high-end fluxes
      noiseup = 1.  ; now done in nk_w8
;      print, noiseup, ' nup at 1mm'
      gx = grid_tot.xmap
      gy = grid_tot.ymap
      wma = where( sqrt( gx^2 + gy^2) ge param.map_bg_zero_level_radius $
                   and truncate_map gt 0.99, nwma)
      grid_tot.zero_level_mask = 0
      if nwma ne 0 then grid_tot.zero_level_mask[ wma] = 1  ;1 are pixels which are used for zero level measurement
      if max(abs(grid_tot.map_i_1mm)) gt 0.d0 then begin
         mp = grid_tot.map_i_1mm
         mv = grid_tot.map_var_i_1mm * jkboost1mm^2    ; apply the boost (Found from JK map)
         ;;  truncate, noise up, but correct signal and variance to
         ;;  make a normal distribution, k_snr and keep_high_snr are
         ;;  used in order to correct and make a smooth transition from low snr to high snr
         print, 'Boost 1mm final map noise & zero level'
         nk_snr_flux_map, mp, mv, $
                          grid_tot.nhits_1mm, !nika.fwhm_nom[0], $
                          grid_tot.map_reso, info, snr_flux_map_1mm, $
                          method = param.k_snr_method, $
                          noiseup = noiseup, $
                          keep_only_high_snr = param.keep_only_high_snr, $
                          k_snr = param.k_snr, $
                          truncate_map = truncate_map, $
                          found_boost = found_boost, gridx = gx, gridy = gy, $
                          bg_zero_level_radius = param.map_bg_zero_level_radius, $
                          bg_zero_level_mask = bgzl_mask_1mm
         grid_tot.map_i_1mm = mp
         grid_tot.map_var_i_1mm = mv
         info.result_sigma_boost_i_1mm = found_boost
         
         mp = grid_tot.map_i1
         mv = grid_tot.map_var_i1 * jkboost1^2    ; apply the boost (Found from JK map)
         print, 'Boost 1mm A1 final map noise & zero level'
         nk_snr_flux_map, mp, mv, $
                          grid_tot.nhits_1, !nika.fwhm_nom[0], $
                          grid_tot.map_reso, info, snr_flux_map_1, $
                          method = param.k_snr_method, $
                          noiseup = noiseup, $
                          keep_only_high_snr = param.keep_only_high_snr, $
                          k_snr = param.k_snr, $
                          truncate_map = truncate_map, $
                          found_boost = found_boost, gridx = gx, gridy = gy, $
                          bg_zero_level_radius = param.map_bg_zero_level_radius, $
                          bg_zero_level_mask = bgzl_mask_1mm
         grid_tot.map_i1 = mp
         grid_tot.map_var_i1 = mv
         info.result_sigma_boost_i1 = found_boost

         mp = grid_tot.map_i3
         mv = grid_tot.map_var_i3 * jkboost3^2    ; apply the boost (Found from JK map)
         print, 'Boost 1mm A3 final map noise & zero level'
         nk_snr_flux_map, mp, mv, $
                          grid_tot.nhits_3, !nika.fwhm_nom[0], $
                          grid_tot.map_reso, info, snr_flux_map_3, $
                          method = param.k_snr_method, $
                          noiseup = noiseup, $
                          keep_only_high_snr = param.keep_only_high_snr, $
                          k_snr = param.k_snr, $
                          truncate_map = truncate_map, $
                          found_boost = found_boost, gridx = gx, gridy = gy, $
                          bg_zero_level_radius = param.map_bg_zero_level_radius, $
                          bg_zero_level_mask = bgzl_mask_1mm
         grid_tot.map_i3 = mp
         grid_tot.map_var_i3 = mv
         info.result_sigma_boost_i3 = found_boost
      endif
      ;; Nsa = info.subscan_arcsec/!nika.fwhm_nom[1]
      ;; Np = nk_atmb_count_param( info,  param, 2) ; 2mm
      ;; noiseup = (1./(1.-(1.505*Np)/Nsa)) ; this part is done at the nk_w8 level
      noiseup = 1.
;      print, noiseup, ' nup at 2mm'
      if max( abs( grid_tot.map_i_2mm)) gt 0.d0 then begin
         mp = grid_tot.map_i_2mm
         mv = grid_tot.map_var_i_2mm * jkboost2mm^2    ; apply the boost (Found from JK map)
         print, 'Boost 2mm final map noise & zero level'
         nk_snr_flux_map, mp, mv, $
                          grid_tot.nhits_2mm, !nika.fwhm_nom[1], $
                          grid_tot.map_reso, info, snr_flux_map_2mm, $
                          method = param.k_snr_method, $
                          noiseup = noiseup, $
                          keep_only_high_snr = param.keep_only_high_snr, $
                          k_snr = param.k_snr,  $
                          truncate_map = truncate_map, $
                          found_boost = found_boost, gridx = gx, gridy = gy, $
                          bg_zero_level_radius = param.map_bg_zero_level_radius, $
                          bg_zero_level_mask = bgzl_mask_2mm
         grid_tot.map_i_2mm = mp
         grid_tot.map_var_i_2mm = mv
         info.result_sigma_boost_i_2mm = found_boost
         
         mp = grid_tot.map_i2
         mv = grid_tot.map_var_i2 * jkboost2^2    ; apply the boost (Found from JK map)
         nk_snr_flux_map, mp, mv, $
                          grid_tot.nhits_2, !nika.fwhm_nom[1], $
                          grid_tot.map_reso, info, snr_flux_map_2, $
                          method = param.k_snr_method, $
                          noiseup = noiseup, $
                          keep_only_high_snr = param.keep_only_high_snr, $
                          k_snr = param.k_snr,  $
                          truncate_map = truncate_map, $
                          found_boost = found_boost, gridx = gx, gridy = gy, $
                          bg_zero_level_radius = param.map_bg_zero_level_radius, $
                          bg_zero_level_mask = bgzl_mask_2mm
         grid_tot.map_i2 = mp
         grid_tot.map_var_i2 = mv
         info.result_sigma_boost_i2 = found_boost
      endif
   endif
;; End ATMB specific part
   
   nk_map2fits_3, param1, info, grid_tot, $
                  output_fits_file=output_fits_file, $
                  header=header, scan_list=scan_list

   if defined(dmm_grid_tot) then begin
      l = strlen(output_fits_file)
      dmm_file = strmid( output_fits_file, 0, l-5)+"_DMM.fits"
      nk_map2fits_3, param1, info, dmm_grid_tot, $
                     output_fits_file=dmm_file, $
                     scan_list=scan_list
   endif
   
;;; ----------------  END Map processing and Saving ---------------------


endif

   

end
