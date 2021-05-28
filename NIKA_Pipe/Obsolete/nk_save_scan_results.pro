
;+
;
; SOFTWARE:
;
; NAME: 
; nk_save_scan_results
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;            - nk_save_scan_results, param, info, data, kidpar
; 
; PURPOSE: 
;        Save intermediate quantities relevant to this scan for
;        further combination with other scans
; 
; INPUT: 
;       - param, info, kidpar, grid
; 
; OUTPUT: 
;      - a .save for the moment in
;        !nika.plot_dir+"/Pipeline/scan_YYYYMMDD
;      - an .csv file containing photometry information on the scan
;        processed as if it was a single pointi source at the map center.
; 
; KEYWORDS:
;      - map_1mm, map_2mm: maps of the current scan *only* (not the
;        cumulative of all scans until this one)
;
; SIDE EFFECT:
;      - creates directories and writes results on disk
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014: Nicolas Ponthieu
;-
;================================================================================================

pro nk_save_scan_results, param, info, grid, kidpar, filing=filing

if n_params() lt 1 then begin
   message, /info, 'Calling sequence:'
   print, "nk_save_scan_results, param, info, grid, kidpar, filing=filing"
   return
endif

;; Do not exit if info.status here !
;; You do want to save the parameters and info and everything to diagnose a
;; problem that might have occured when the pipeline was running

;; Compute photometry if everything went fine
if info.status ne 1 then begin

   ;; Aperture photometry directly puts all the results into info
   if param.do_aperture_photometry eq 1 then nk_aperture_photometry, param, info, grid

   map_var  = double(finite(grid.map_w8_1mm))*0.d0
   w        = where( grid.map_w8_1mm gt 0, nw)

   if param.do_plot then begin
      if not param.plot_ps then wind, 1, 1, /free, xs=1500, ys=900
   endif
   noplot   = 1 - long( param.do_plot)
   if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_1mm[w]

   outfile = param.plot_dir+"/maps_"+strtrim(param.scan,2)
   outplot, file=outfile, png=param.plot_png
   
   pp1 = fltarr(6,4)
   if param.plot_ps eq 0 then begin
      if info.polar eq 0 then begin
         my_multiplot, 2, 1, pp, pp1, /rev, gap_x=0.1, xmargin=0.1
      endif else begin
         my_multiplot, 3, 2, pp, pp1, /rev, gap_x=0.1, xmargin=0.1
      endelse
   endif


   p = 0
   if param.two_mm_only ne 1 then begin
      nefd_source_1mm = 1
      nefd_center_1mm = 1
      if param.plot_ps  then ps_file = outfile+"_1mm.ps"
      nk_map_photometry, grid.map_i_1mm, map_var, grid.nhits_1mm, $
                         grid.xmap, grid.ymap, param.input_fwhm_1mm, $
                         flux_1mm, sigma_flux_1mm, $
                         sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                         bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                         educated=param.educated, ps_file=ps_file, position=pp1[p,*], $
                         k_noise=k_noise, noplot=noplot, param=param, lambda=1, $
                         title=param.scan+" 1mm", info=info, nefd_source=nefd_source_1mm, nefd_center=nefd_center_1mm

      if info.status eq 1 then return
;   print,  "ps_file: ",  ps_file
;   stop
;   outplot, /close
;   if param.plot_png then erase
      p++

      info.result_flux_I_1mm             = flux_1mm
      info.result_err_flux_I_1mm         = sigma_flux_1mm
      info.result_flux_center_I_1mm     = flux_center_1mm
      info.result_err_flux_center_I_1mm = sigma_flux_center_1mm
      info.result_off_x_1mm           = output_fit_par_1mm[4]
      info.result_off_y_1mm           = output_fit_par_1mm[5]
      info.result_fwhm_x_1mm          = output_fit_par_1mm[2]/!fwhm2sigma
      info.result_fwhm_y_1mm          = output_fit_par_1mm[3]/!fwhm2sigma
      info.result_fwhm_1mm            = sqrt( output_fit_par_1mm[2]*output_fit_par_1mm[3])/!fwhm2sigma
      info.result_nefd_I_1mm            = nefd_source_1mm
      info.result_nefd_center_I_1mm     = nefd_center_1mm

      print, "nefd_source_1mm, nefd_center_1mm: ", nefd_source_1mm, nefd_center_1mm

;;      ;;---------
;;      ;; Add noise map in .ps only for now
;;      if param.plot_ps  then begin
;;         ps_file = outfile+"_noise_I_1mm.ps"
;;         w = where( grid.map_var_i_1mm ne 0, nw)
;;         mm = median( sqrt(grid.map_var_i_1mm[w]))
;;         nk_map_photometry, sqrt(grid.map_var_i_1mm), map_var, grid.nhits_1mm, $
;;                            grid.xmap, grid.ymap, param.input_fwhm_1mm, $
;;                            flux_1mm, sigma_flux_1mm, $
;;                            sigma_bg_1mm, output_fit_par_1mm_junk, output_fit_par_error_1mm, $
;;                            bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
;;                            ps_file=ps_file, $ ;, position=pp1[p,*], $
;;                            k_noise=k_noise, noplot=noplot, param=param, lambda=1, $
;;                            title=param.scan+" Noise I 1mm", info=info, /image, imr=[-1,1]*mm
;;      endif
;;      ;;---------

      if info.polar ne 0 then begin
         w        = where( grid.map_w8_1mm gt 0, nw)
         if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_q_1mm[w]
;;      outfile = param.plot_dir+"/map_q"+strtrim(param.scan,2)
;;      if param.plot_png then outplot, file=outfile+"_1mm", /png
         if param.plot_ps  then ps_file = outfile+"_Q_1mm.ps"
         nefd_source_q_1mm=1
         nefd_center_q_1mm=1

         nk_map_photometry, grid.map_q_1mm, map_var, grid.nhits_1mm, $
                            grid.xmap, grid.ymap, param.input_fwhm_1mm, $
                            fluxq_1mm, sigma_fluxq_1mm, $
                            sigma_bg_1mm, output_fit_par_1mm_junk, output_fit_par_error_1mm_junk, $
                            bg_rms_1mm, fluxq_center_1mm, sigma_fluxq_center_1mm, sigma_bg_center_1mm, $
                            educated=param.educated, ps_file=ps_file, position=pp1[p,*], input_fit_par=output_fit_par_1mm, $
                            k_noise=k_noise, noplot=noplot, param=param,  $
                            title=param.scan+" Q 1mm", info=info, nefd_source=nefd_source_q_1mm, nefd_center=nefd_center_q_1mm
         if info.status eq 1 then return
         info.result_flux_Q_1mm             = fluxq_1mm
         info.result_err_flux_Q_1mm         = sigma_fluxq_1mm
         info.result_flux_center_Q_1mm     = fluxq_center_1mm
         info.result_err_flux_center_Q_1mm = sigma_fluxq_center_1mm
         info.result_nefd_Q_1mm           = nefd_source_q_1mm
         info.result_nefd_center_Q_1mm    = nefd_center_q_1mm

;      outplot, /close
;      if param.plot_png then erase
         p++

;;      ;;---------
;;      ;; Add noise map in .ps only for now
;;      if param.plot_ps  then begin
;;         ps_file = outfile+"_noise_Q_1mm.ps"
;;         w = where( grid.map_var_q_1mm ne 0, nw)
;;         mm = median( sqrt(grid.map_var_q_1mm[w]))
;;         nk_map_photometry, sqrt(grid.map_var_q_1mm), map_var, grid.nhits_1mm, $
;;                            grid.xmap, grid.ymap, param.input_fwhm_1mm, $
;;                            flux_1mm, sigma_flux_1mm, $
;;                            sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
;;                            bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
;;                            educated=param.educated, ps_file=ps_file, $ ;, position=pp1[p,*], $
;;                            k_noise=k_noise, noplot=noplot, param=param, $
;;                            title=param.scan+" Noise Q 1mm", info=info, /image, imr=[-1,1]*mm
;;      endif
;;      ;;---------

         w        = where( grid.map_w8_2mm gt 0, nw)
         if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_u_1mm[w]
;      outfile = param.plot_dir+"/map_u"+strtrim(param.scan,2)
;      if param.plot_png then outplot, file=outfile+"_1mm", /png
         if param.plot_ps  then ps_file = outfile+"_U_1mm.ps"
         nefd_source_u_1mm=1
         nefd_center_u_1mm=1
         nk_map_photometry, grid.map_u_1mm, map_var, grid.nhits_1mm, $
                            grid.xmap, grid.ymap, param.input_fwhm_1mm, $
                            fluxU_1mm, sigma_fluxU_1mm, $
                            sigma_bg_1mm, output_fit_par_1mm_junk, output_fit_par_error_1mm_junk, $
                            bg_rms_1mm, fluxU_center_1mm, sigma_fluxU_center_1mm, sigma_bg_center_1mm, $
                            educated=param.educated, ps_file=ps_file, position=pp1[p,*], input_fit_par=output_fit_par_1mm, $
                            k_noise=k_noise, noplot=noplot, param=param, $
                            title=param.scan+" U 1mm", info=info, nefd_source=nefd_source_u_1mm, nefd_center=nefd_center_u_1mm
         if info.status eq 1 then return
         info.result_flux_U_1mm             = fluxu_1mm
         info.result_err_flux_U_1mm         = sigma_fluxu_1mm
         info.result_flux_center_U_1mm     = fluxu_center_1mm
         info.result_err_flux_center_U_1mm = sigma_fluxu_center_1mm
         info.result_nefd_U_1mm           = nefd_source_u_1mm
         info.result_nefd_center_U_1mm    = nefd_center_u_1mm

;;      ;;---------
;;      ;; Add noise map in .ps only for now
;;      if param.plot_ps  then begin
;;         ps_file = outfile+"_noise_U_1mm.ps"
;;         w = where( grid.map_var_u_1mm ne 0, nw)
;;         mm = median( sqrt(grid.map_var_u_1mm[w]))
;;         nk_map_photometry, sqrt(grid.map_var_u_1mm), map_var, grid.nhits_1mm, $
;;                            grid.xmap, grid.ymap, param.input_fwhm_1mm, $
;;                            flux_1mm, sigma_flux_1mm, $
;;                            sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
;;                            bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
;;                            educated=param.educated, ps_file=ps_file, $ ;, position=pp1[p,*], $
;;                            k_noise=k_noise, noplot=noplot, param=param, $
;;                            title=param.scan+" Noise U 1mm", info=info, /image, imr=[-1,1]*mm
;;      endif
;;      ;;---------

         iqu2poldeg, info.result_flux_I_1mm, info.result_flux_Q_1mm, info.result_flux_U_1mm, $
                     info.result_err_flux_I_1mm,  info.result_err_flux_Q_1mm,  info.result_err_flux_U_1mm,  pol_deg, sigma_pol_deg
         info.result_pol_deg_1mm = pol_deg
         info.result_err_pol_deg_1mm = sigma_pol_deg

;      outplot, /close
;      if param.plot_png then erase
         p++
      endif
   endif

   if param.one_mm_only ne 1 then begin
      nefd_source_2mm = 1
      nefd_center_2mm = 1
      map_var  = double(finite(grid.map_w8_2mm))*0.d0
      w        = where( grid.map_w8_2mm gt 0, nw)
      if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_2mm[w]
;   if param.plot_png then outplot, file=outfile+"_2mm", /png
      if param.plot_ps  then ps_file = outfile+"_2mm.ps"
      nk_map_photometry, grid.map_i_2mm, map_var, grid.nhits_2mm, $
                         grid.xmap, grid.ymap, param.input_fwhm_2mm, $
                         flux_2mm, sigma_flux_2mm, $
                         sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
                         bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
                         educated=param.educated, ps_file=ps_file, position=pp1[p,*], $
                         k_noise=k_noise, noplot=noplot, param=param, $
                         title=param.scan+" 2mm", info=info, nefd_source=nefd_source_2mm, nefd_center=nefd_center_2mm

      print, "nefd_source_2mm, nefd_center_2mm: ", nefd_source_2mm, nefd_center_2mm

      if info.status eq 1 then return
;   outplot, /close
;   if param.plot_png then erase
      p++

      !p.multi=0
      info.result_flux_I_2mm             = flux_2mm
      info.result_err_flux_I_2mm         = sigma_flux_2mm
      info.result_flux_center_I_2mm     = flux_center_2mm
      info.result_err_flux_center_I_2mm = sigma_flux_center_2mm
      info.result_off_x_2mm           = output_fit_par_2mm[4]
      info.result_off_y_2mm           = output_fit_par_2mm[5]
      info.result_fwhm_x_2mm          = output_fit_par_2mm[2]/!fwhm2sigma
      info.result_fwhm_y_2mm          = output_fit_par_2mm[3]/!fwhm2sigma
      info.result_fwhm_2mm            = sqrt( output_fit_par_2mm[2]*output_fit_par_2mm[3])/!fwhm2sigma
      info.result_nefd_I_2mm            = nefd_source_2mm
      info.result_nefd_center_I_2mm     = nefd_center_2mm

;;      ;;---------
;;      ;; Add noise map in .ps only for now
;;      if param.plot_ps  then begin
;;         ps_file = outfile+"_noise_I_2mm.ps"
;;         w = where( grid.map_var_i_2mm ne 0, nw)
;;         mm = median( sqrt(grid.map_var_i_2mm[w]))
;;         nk_map_photometry, sqrt(grid.map_var_i_2mm), map_var, grid.nhits_2mm, $
;;                            grid.xmap, grid.ymap, param.input_fwhm_2mm, $
;;                            flux_2mm, sigma_flux_2mm, $
;;                            sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
;;                            bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
;;                            educated=param.educated, ps_file=ps_file, $ ;, position=pp1[p,*], $
;;                            k_noise=k_noise, noplot=noplot, param=param, $
;;                            title=param.scan+" Noise I 2mm", info=info, /image, imr=[-1,1]*mm
;;      endif
;;      ;;---------

      if info.polar ne 0 then begin
         if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_q_2mm[w]
;      outfile = param.plot_dir+"/map_q"+strtrim(param.scan,2)
;      if param.plot_png then outplot, file=outfile+"_2mm", /png
         if param.plot_ps  then ps_file = outfile+"_Q_2mm.ps"
         nefd_source_q_2mm=1
         nefd_center_q_2mm=1
         nk_map_photometry, grid.map_q_2mm, map_var, grid.nhits_2mm, $
                            grid.xmap, grid.ymap, param.input_fwhm_2mm, $
                            fluxq_2mm, sigma_fluxq_2mm, $
                            sigma_bg_2mm, output_fit_par_2mm_junk, output_fit_par_error_2mm_junk, $
                            bg_rms_2mm, fluxq_center_2mm, sigma_fluxq_center_2mm, sigma_bg_center_2mm, $
                            educated=param.educated, ps_file=ps_file, position=pp1[p,*], input_fit_par=output_fit_par_2mm, $
                            k_noise=k_noise, noplot=noplot, param=param, $
                            title=param.scan+" Q 2mm", info=info, nefd_source=nefd_source_q_2mm, nefd_center=nefd_center_q_2mm
         if info.status eq 1 then return
         info.result_flux_Q_2mm             = fluxq_2mm
         info.result_err_flux_Q_2mm         = sigma_fluxq_2mm
         info.result_flux_center_q_2mm     = fluxq_center_2mm
         info.result_err_flux_center_q_2mm = sigma_fluxq_center_2mm
         info.result_nefd_q_2mm           = nefd_source_q_2mm
         info.result_nefd_center_q_2mm    = nefd_center_q_2mm

;      outplot, /close
;      if param.plot_png then erase
         p++

;;      ;;---------
;;      ;; Add noise map in .ps only for now
;;      if param.plot_ps  then begin
;;         ps_file = outfile+"_noise_Q_2mm.ps"
;;         w = where( grid.map_var_q_2mm ne 0, nw)
;;         mm = median( sqrt(grid.map_var_q_2mm[w]))
;;         nk_map_photometry, sqrt(grid.map_var_q_2mm), map_var, grid.nhits_2mm, $
;;                            grid.xmap, grid.ymap, param.input_fwhm_2mm, $
;;                            flux_2mm, sigma_flux_2mm, $
;;                            sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
;;                            bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
;;                            educated=param.educated, ps_file=ps_file, $ ;, position=pp1[p,*], $
;;                            k_noise=k_noise, noplot=noplot, param=param, $
;;                            title=param.scan+" Noise Q 2mm", info=info, /image, imr=[-1,1]*mm
;;      endif
;;      ;;---------

         if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_u_2mm[w]
;      outfile = param.plot_dir+"/map_u"+strtrim(param.scan,2)
;      if param.plot_png then outplot, file=outfile+"_2mm", /png
         if param.plot_ps  then ps_file = outfile+"_U_2mm.ps"
         nefd_source_u_2mm=1
         nefd_center_u_2mm=1
         nk_map_photometry, grid.map_u_2mm, map_var, grid.nhits_2mm, $
                            grid.xmap, grid.ymap, param.input_fwhm_2mm, $
                            fluxU_2mm, sigma_fluxU_2mm, $
                            sigma_bg_2mm, output_fit_par_2mm_junk, output_fit_par_error_2mm_junk, $
                            bg_rms_2mm, fluxU_center_2mm, sigma_fluxU_center_2mm, sigma_bg_center_2mm, $
                            educated=param.educated, ps_file=ps_file, position=pp1[p,*], input_fit_par=output_fit_par_2mm, $
                            k_noise=k_noise, noplot=noplot, param=param, $
                            title=param.scan+" U 2mm", info=info, nefd_source=nefd_source_u_2mm, nefd_center=nefd_center_u_2mm
               if info.status eq 1 then return
         info.result_flux_U_2mm             = fluxu_2mm
         info.result_err_flux_U_2mm         = sigma_fluxu_2mm
         info.result_flux_center_U_2mm     = fluxu_center_2mm
         info.result_err_flux_center_U_2mm = sigma_fluxu_center_2mm
         info.result_nefd_u_2mm           = nefd_source_u_2mm
         info.result_nefd_center_u_2mm    = nefd_center_u_2mm

;;      ;;---------
;;      ;; Add noise map in .ps only for now
;;      if param.plot_ps  then begin
;;         ps_file = outfile+"_noise_U_2mm.ps"
;;         w = where( grid.map_var_u_2mm ne 0, nw)
;;         mm = median( sqrt(grid.map_var_u_2mm[w]))
;;         nk_map_photometry, sqrt(grid.map_var_u_2mm), map_var, grid.nhits_2mm, $
;;                            grid.xmap, grid.ymap, param.input_fwhm_2mm, $
;;                            flux_2mm, sigma_flux_2mm, $
;;                            sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
;;                            bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
;;                            educated=param.educated, ps_file=ps_file, $ ;, position=pp1[p,*], $
;;                            k_noise=k_noise, noplot=noplot, param=param, $
;;                            title=param.scan+" Noise U 2mm", info=info, /image, imr=[-1,1]*mm
;;      endif
;;      ;;---------

         iqu2poldeg, info.result_flux_I_2mm, info.result_flux_Q_2mm, info.result_flux_U_2mm, $
                     info.result_err_flux_I_2mm,  info.result_err_flux_Q_2mm,  info.result_err_flux_U_2mm,  pol_deg, sigma_pol_deg
         info.result_pol_deg_2mm = pol_deg
         info.result_err_pol_deg_2mm = sigma_pol_deg



;      outplot, /close
;      if param.plot_png then erase
         p++
      endif
   endif

   outplot, /close
endif


;; Change names of variables for easier comparison to the current ones
;; when we restore them
param1      = param
info1       = info
grid1 = grid
if defined(kidpar) then kidpar1 = kidpar

save, file=param.output_dir+'/results.save', param1, info1, kidpar1, grid1
message, /info, "saved "+param.output_dir+'/results.save'

if keyword_set(filing) then begin
   spawn, "rm -f "+param.bp_file
   spawn, "touch "+param.ok_file

   ;; removed UnProcessed file only if everything went well
   ;;if info.status eq 0 then spawn, "rm -f "+param.up_file
endif

;; Save photometric information in a .csv file
tags = tag_names(info)
w = where( strupcase( strmid(tags,0,6)) eq "RESULT", nw)
tag_length = strlen( tags)
;openw, 1, param.output_dir+"/photometry.csv"
get_lun, lu
openw, lu, param.output_dir+"/photometry.csv"
;openw, lu, param.output_dir+"/tags.csv"
title_string = 'Scan, Source, RA, DEC'
res_string   = strtrim(param.scan,2)+", "+strtrim(param.source,2)+", "+strtrim(info.longobj,2)+", "+strtrim(info.latobj,2)
for i=0, nw-1 do begin
   title_string = title_string+", "+strmid( tags[w[i]],7,tag_length[w[i]]-7)
   res_string   = res_string+", "+strtrim( info.(w[i]),2)
endfor
printf, lu, title_string
printf, lu, res_string
;printf, lu, title_string
;close, 1
close, lu
free_lun, lu

;; Prepare LaTeX report with all plots produced for this scan
;;nk_latex_scan_report, param


end
