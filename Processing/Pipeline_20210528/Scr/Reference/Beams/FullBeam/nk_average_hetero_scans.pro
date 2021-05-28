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
;-

pro nk_average_hetero_scans, param, scan_list, grid_tot, info=info, $
                      imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                      imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                      imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                      imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                      noplot=noplot, beam_pos_list = beam_pos_list, syst_err = syst_err, $
                      sigma_beam_pos = sigma_beam_pos, cumul = cumul, photometry=photometry, $
                      flux_cumul=flux_cumul, sigma_flux_cumul=sigma_flux_cumul, $
                      flux_center_cumul=flux_center_cumul, sigma_flux_center_cumul=sigma_flux_center_cumul, $
                      time_center_cumul=time_center_cumul, center_nefd_only=center_nefd_only, parity=parity, $
                      project_dir=project_dir

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_average_scans, param, scan_list, grid_tot, info=info, $"
   print, "                   imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $"
   print, "                   imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $"
   print, "                   imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $"
   print, "                   imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $"
   print, "                   png=png, ps=ps, noplot=noplot, beam_pos_list = beam_pos_list, syst_err = syst_err, $"
   print, "                   sigma_beam_pos = sigma_beam_pos, cumul = cumul, photometry=photometry"
   return
endif

nscans        = n_elements(scan_list)
neffscan      = 0  ; effective number of scans used in the combination
do_projection = 0
init_done     = 0
stokes        = ['I', 'Q', 'U']

time_center_cumul       = dblarr(nscans, 15)
flux_cumul              = dblarr(nscans, 15)
sigma_flux_cumul        = dblarr(nscans, 15)
flux_center_cumul       = dblarr(nscans, 15)
sigma_flux_center_cumul = dblarr(nscans, 15)

if not keyword_set(project_dir) then project_dir = param.project_dir

for iscan=0, nscans-1 do begin

   dir = project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim( scan_list[iscan], 2)

   ;; Check if the requested result file exists
   file_save = dir+"/results.save"
   if file_test(file_save) eq 0 then begin
      message, /info, file_save+" not found"
   endif else begin
      ;; @ Restore results of each individual scan
      restore, file_save

      ;; check the scan was reduced correctly
      if info1.status ne 1 then begin

         if init_done eq 0 then begin
            info = info1        ; init
            info.nscan = 1
            neffscan = 1
            info.obs_type = info1.obs_type ; init
            output_grid          = grid1
            info.polar           = info1.polar
            param.source         = param1.source
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
            init_done = 1
         endif

         if strupcase( strtrim( info1.obs_type,2)) ne strupcase( strtrim( info.obs_type,2)) then info.obs_type = 'Mixed'
         if strupcase( strtrim( param1.source,2))  ne strupcase( strtrim( param.source,2)) then param.source = 'Combo'
         
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


         
         ;; normalization and shift
         ;;---------------------------------------------------------------------
         stokes = ['I', 'Q', 'U']
         suffix = ['1', '2', '3', '_1MM', '_2MM']
         alpha_flux_cuts = [0.35, 0.2, 0.35, 0.35, 0.2]
         for isuff=0, 4 do begin
            ;;for istokes=0, 2 do begin
            istokes=0

            suf    = (strsplit(suffix[isuff], '_', /extract))[0]
            i_flux = nk_tag_exist( info1, 'RESULT_PEAK_'+strtrim(suf,2), wa)
            a_peak = info1.(wa)

            print, "A_peak ori = ", a_peak
            
            i_flux = nk_tag_exist( info1, "RESULT_FLUX_I"+suffix[isuff], wb)
            flux   = info1.(wb)
            i_x    = nk_tag_exist( info1, "RESULT_OFF_X_"+strtrim(suf,2), wx)
            x0     = info1.(wx)
            i_y    = nk_tag_exist( info1, "RESULT_OFF_Y_"+strtrim(suf,2), wy)
            y0     = info1.(wy)
            
            d    = sqrt( (grid1.xmap-x0)^2 + (grid1.ymap-y0)^2)
            rbg  = 100.

            
            r1 = nk_tag_exist( grid1, "map_"+Stokes[istokes]+strtrim(suffix[isuff],2), wq)
            r2 = nk_tag_exist( grid1, "map_var_"+Stokes[istokes]+strtrim(suffix[isuff],2), wvarq)
            if r1 eq 1 then begin
               map = grid1.(wq)
               var = grid1.(wvarq)
            endif
            
            alpha_flux_cut = alpha_flux_cuts[isuff]
            wfit = where( (map gt alpha_flux_cut*flux and d le rbg) or (d ge rbg and var lt mean(var)), nwfit, compl=wout)
            map_var0 = var
            map_var0[wout] = 0.d0
            nk_fitmap, map, map_var0, grid1.xmap, grid1.ymap, output_fit_par, covar, output_fit_par_error, $
                       educated=educated, k_noise=k_noise, info=info_out, status=status, dmax=dmax, $
                       xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, sigma_guess=input_sigma_beam, map_fit=best_model
            ww = where(map_var0 gt 0., ndata)
            chi2 = total((map[ww]-best_model[ww])^2/map_var0[ww])/(ndata-7.)
            print,"max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2

            ;; normalisation
            a_peak = output_fit_par[1]
            
            print, "A_peak 2 = ", a_peak
            
            r1 = nk_tag_exist( grid1, "map_"+Stokes[istokes]+strtrim(suffix[isuff],2), wq)
            r2 = nk_tag_exist( grid1, "map_var_"+Stokes[istokes]+strtrim(suffix[isuff],2), wvarq)
            if r1 eq 1 then begin
               map = grid1.(wq)/a_peak
               var = grid1.(wvarq)/a_peak^2
           

               ;; recalage
               x0 = output_fit_par[4]
               y0 = output_fit_par[5]

               reso = param1.map_reso
               nx   = n_elements(map[*, 0])
               ny   = n_elements(map[0, *])
               pix_x0 = -1.*x0/reso
               pix_y0 = -1.*y0/reso

               print, "X0 = ",x0,", X0 en pixel = ", pix_x0
               print, "Y0 = ",y0,", Y0 en pixel = ", pix_y0
               if (abs(pix_x0) ge 1. or abs(pix_y0) ge 1.) then begin
                  map = shift(map, pix_x0, pix_y0)
                  var = shift(var, pix_x0, pix_y0)

                  ;; cut borders
                  x1 = 0
                  x2 = 0
                  if pix_x0 gt 0 then begin
                     x2 = pix_x0
                  endif else if pix_x0 lt 0 then begin
                     x1 = nx-1+pix_x0
                     x2 = nx-1
                  endif
                  y1 = 0
                  y2 = 0
                  if pix_y0 gt 0 then begin
                     y2 = pix_y0
                  endif else if pix_y0 lt 0 then begin
                     y1 = ny-1+pix_y0
                     y2 = ny-1
                  endif
                  print,"cut border : ", x1, x2, y1, y2
                  
                  var[x1:x2, y1:y2] = 0.d0
                  
               endif

               grid1.(wq)    = map
               grid1.(wvarq) = var
               
            endif
            ;;endfor
            
         endfor

         
         if iscan ge 1 and defined(grid_tot) then begin
            sign = 1
            if keyword_set(parity) then begin
               if (iscan mod 2) eq 0 then sign = 1 else sign = -1
            endif
            ;; @ {\tt nk_average_grids} combines scan results on the
            ;; @^ fly with inverse variance noise weighting.
            nk_average_grids, grid_tot, grid1, junk, sign=sign
            grid_tot = temporary(junk)

            ;; Update info (total or average quantities)
            info.result_total_obs_time += info1.result_total_obs_time
            info.result_valid_obs_time += info1.result_valid_obs_time
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
                          plot_dir = param.plot_dir, nickname = param1.scan, ata_fit_beam_rmax=param.ata_fit_beam_rmax
            info1 = info_out
         endif

         ;; Update .csv
         res_string   = strtrim(param1.scan,2)+", "+strtrim(param1.source,2)+$
                        ", "+strtrim(info1.longobj,2)+", "+strtrim(info1.latobj,2)
         for i=0, nwtags-1 do res_string   = res_string+", "+strtrim( info1.(wtags[i]),2)
         printf, file_unit, res_string
         
         ;; For cumulative plots
         if keyword_set(cumul) then begin
            if keyword_set(center_nefd_only) then input_fit_par = [1.d0, 1.d0, 0.d0, 0.d0, 0.d0, 0.d0, 0.d0]

            nk_grid2info, grid_tot, info_temp, aperture_photometry=param.do_aperture_photometry, $
                          title=param.source+" "+param1.scan, educated=param.educated, all_time_matrix_center=all_time_matrix_center, $
                          all_flux_source=all_flux_source, all_sigma_flux_source=all_sigma_flux_source, $
                          all_flux_center=all_flux_center, all_sigma_flux_center=all_sigma_flux_center, $
                          ata_fit_beam_rmax=param.ata_fit_beam_rmax, /noplot
            ;; attention, l'ordre change entre all_flux de
            ;; nk_grid2info et de l'ancien nk_map_photometry_3
            flux_cumul[              iscan,*] = reform(all_flux_source)
            sigma_flux_cumul[        iscan,*] = reform(all_sigma_flux_source)
            flux_center_cumul[       iscan,*] = reform(all_flux_center)
            sigma_flux_center_cumul[ iscan,*] = reform(all_sigma_flux_center)
            
;;            message, /info, "fix me :changing def of time_center_cumul (temp)"
            time_center_cumul[       iscan,*] = reform(all_time_matrix_center)
;;            if iscan eq 0 then begin
;;               time_center_cumul[iscan,0] = info1.result_total_obs_time * info1.result_on_source_frac_array_1
;;               time_center_cumul[iscan,3] = info1.result_total_obs_time * info1.result_on_source_frac_array_2
;;               time_center_cumul[iscan,6] = info1.result_total_obs_time * info1.result_on_source_frac_array_3
;;            endif else begin
;;               time_center_cumul[iscan,0] = time_center_cumul[iscan-1,0] + info1.result_total_obs_time * info1.result_on_source_frac_array_1
;;               time_center_cumul[iscan,3] = time_center_cumul[iscan-1,3] + info1.result_total_obs_time * info1.result_on_source_frac_array_2
;;               time_center_cumul[iscan,6] = time_center_cumul[iscan-1,6] + info1.result_total_obs_time * info1.result_on_source_frac_array_3
;;            endelse
;stop
         endif
         
      endif
   endelse
endfor

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

   ;; @ {\tt nk_grid2info} computes the final photometry on
   ;; @^ the combined map, finds the source centroid location etc...
   nk_grid2info, grid_tot, info_out, info_in=info, noplot=noplot, $
                 imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                 imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                 imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                 imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                 aperture_photometry = param.do_aperture_photometry, param = param, $
                 plot_dir = project_dir + '/Plots', $
                 ps = param.plot_ps, png = param.plot_png, educated=param.educated, $
                 title =  param.name4file, $
                 nickname = strtrim(info1.object,2)+'_'+strtrim( scan_list[0], 2)+ suffix, $
                 old_formula=param.old_pol_deg_formula, ata_fit_beam_rmax=param.ata_fit_beam_rmax
;; print, "NEFD center out of info_out (I1): ", info_out.result_err_flux_center_i1*1e3*sqrt(info_out.result_total_obs_time)
;; print, "NEFD center out of info_out (I3): ", info_out.result_err_flux_center_i3*1e3*sqrt(info_out.result_total_obs_time)
;; print, "NEFD center out of info_out (I2): ", info_out.result_err_flux_center_i2*1e3*sqrt(info_out.result_total_obs_time)
;; stop
   info = info_out
   info.nscan = nscans
   
   ;; Update .csv file with the results of all scans cumulated
   res_string   = "# "+strtrim( neffscan, 2)+" scans combined, "+strtrim(param.source,2)+ $
                  ", "+strtrim(info.longobj,2)+", "+strtrim(info.latobj,2)
   for i=0, nwtags-1 do res_string   = res_string+", "+strtrim( info.(wtags[i]),2)
   printf, file_unit, res_string
   close, file_unit
   free_lun, file_unit
endelse

;; Update LaTeX documents with all maps
if param.plot_ps eq 1 then nk_latex_project_report, param, scan_list, project_dir=project_dir

loadct, 39,  /silent
if defined( file_unit) then free_lun, file_unit

;; Write output fits map
param1 = param
param1.output_dir = project_dir

; When several scans are coadded change the suffix of fits files
suffix = ''
;; @ {\tt nk_map2fits_3} produces a .fits file with the combined maps,
;; @^ the param structure and various information from info.
nk_map2fits_3, param1, info, grid_tot, suffix = suffix

end
