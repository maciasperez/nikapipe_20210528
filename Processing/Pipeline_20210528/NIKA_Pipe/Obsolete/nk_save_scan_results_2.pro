
;+
;
; SOFTWARE:
;
; NAME: 
; nk_save_scan_results_2
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;            - nk_save_scan_results_2, param, info, data, kidpar, filing=filing
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

pro nk_save_scan_results_2, param, info, grid, kidpar, filing=filing
  
if n_params() lt 1 then begin
   message, /info, 'Calling sequence:'
   print, "nk_save_scan_results_2, param, info, grid, kidpar, filing=filing"
   return
endif

;; Do not exit if info.status here !
;; You do want to save the parameters and info and everything to diagnose a
;; problem that might have occured when the pipeline was running

;; Compute photometry if everything went fine
if info.status eq 1 then return

;; Aperture photometry directly puts all the results into info
;; if param.do_aperture_photometry eq 1 then nk_aperture_photometry, param, info, grid
if param.do_aperture_photometry eq 1 then nk_aperture_photometry_2, param, info, grid

;; noplot is useful to compute fluxes while not displaying the maps
noplot   = 1 - long( param.do_plot)

pp1 = fltarr(6,4)
if param.plot_ps eq 0 then begin
   if param.do_plot eq 1 then wind, 1, 1, /free, xs=1500, ys=900
   if info.polar eq 0 then begin
      my_multiplot, 2, 1, pp, pp1, /rev, gap_x=0.1, xmargin=0.1
   endif else begin
      my_multiplot, 3, 2, pp, pp1, /rev, gap_x=0.1, xmargin=0.1
   endelse
endif

stokes_par = ["I", "Q", "U"]
grid_tags = tag_names( grid)
info_tags = tag_names(info)

;; Main loop
p = 0
for lambda=1, 2 do begin

   if lambda eq 1 then begin
      fwhm = param.input_fwhm_1mm
   endif else begin
      fwhm = param.input_fwhm_2mm
   endelse

   ;; Loop on I, Q and U
   for istokes=0, 2 do begin
      outfile = param.plot_dir+"/maps_"+strtrim(param.scan,2)

      ;; Check if the map exists (in particular, are we in polarized mode ?)
      wmap = where( strupcase(grid_tags) eq "MAP_"+stokes_par[istokes]+"_"+strtrim(lambda,2)+"MM", nwmap)
      if nwmap ne 0 then begin
      
         ;; Check if the map is not empty (e.g. "one mm only"...)
         whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(lambda,2)+"MM", nwhits)
         if max( grid.(whits)) gt 0 then begin
            wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+stokes_par[istokes]+"_"+strtrim(lambda,2)+"MM", nwvar)
         
            nefd_source = 1
            nefd_center = 1
            if param.plot_ps  then ps_file = outfile+"_"+stokes_par[istokes]+"_"+strtrim(lambda,2)+"mm.ps"

            ;; Re-init fit parameters
            if istokes eq 0 then delvarx, input_fit_par

            nk_map_photometry, grid.(wmap), grid.(wvar), grid.(whits), $
                               grid.xmap, grid.ymap, fwhm, $
                               flux, sigma_flux, sigma_bg, output_fit_par, output_fit_par_error, $
                               bg_rms, flux_center, sigma_flux_center, sigma_bg_center, $
                               map_var_conv=map_var_conv, input_fit_par=input_fit_par, map_sn_smooth=map_sn_smooth, $
                               educated=param.educated, ps_file=ps_file, position=pp1[p,*], $
                               k_noise=k_noise, noplot=noplot, param=param, $
                               title=param.scan+" "+stokes_par[istokes]+" "+strtrim(lambda,2)+"mm", $
                               info=info, nefd_source=nefd_source, nefd_center=nefd_center, $
                               aperture_phot_contours=aperture_phot_contours
            p++

            ;; Force the I centroid position for the Q and U maps
            if istokes eq 0 then input_fit_par = output_fit_par

            ;;-------------------------------------------------------
            ;; Fill the info structure
            wtag = where( strupcase(info_tags) eq "RESULT_FLUX_"+strtrim(stokes_par[istokes],2)+"_"+strtrim(lambda,2)+"MM", nwtag)
            info.(wtag) = flux

            wtag = where( strupcase(info_tags) eq "RESULT_ERR_FLUX_"+strtrim(stokes_par[istokes],2)+"_"+strtrim(lambda,2)+"MM", nwtag)
            info.(wtag) = sigma_flux

            wtag = where( strupcase(info_tags) eq "RESULT_FLUX_CENTER_"+strtrim(stokes_par[istokes],2)+"_"+strtrim(lambda,2)+"MM", nwtag)
            info.(wtag) = flux_center
            
            wtag = where( strupcase(info_tags) eq "RESULT_ERR_FLUX_CENTER_"+strtrim(stokes_par[istokes],2)+"_"+strtrim(lambda,2)+"MM", nwtag)
            info.(wtag) = sigma_flux_center

            wtag = where( strupcase(info_tags) eq "RESULT_NEFD_"+strtrim(stokes_par[istokes],2)+"_"+strtrim(lambda,2)+"MM", nwtag)
            info.(wtag) = nefd_source

            wtag = where( strupcase(info_tags) eq "RESULT_NEFD_CENTER_"+strtrim(stokes_par[istokes],2)+"_"+$
                          strtrim(lambda,2)+"MM", nwtag)
            info.(wtag) = nefd_center

            if istokes eq 0 then begin
               wtag = where( strupcase(info_tags) eq "RESULT_OFF_X_"+strtrim(lambda,2)+"MM", nwtag)
               info.(wtag) = output_fit_par[4]

               wtag = where( strupcase(info_tags) eq "RESULT_OFF_Y_"+strtrim(lambda,2)+"MM", nwtag)
               info.(wtag) = output_fit_par[5]

               wtag = where( strupcase(info_tags) eq "RESULT_FWHM_X_"+strtrim(lambda,2)+"MM", nwtag)
               info.(wtag) = output_fit_par[2]/!fwhm2sigma

               wtag = where( strupcase(info_tags) eq "RESULT_FWHM_Y_"+strtrim(lambda,2)+"MM", nwtag)
               info.(wtag) = output_fit_par[3]/!fwhm2sigma

               wtag = where( strupcase(info_tags) eq "RESULT_FWHM_"+strtrim(lambda,2)+"MM", nwtag)
               info.(wtag) = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
            endif


            ;; Extra plots for the automatic report
            if param.plot_ps  then begin
               ;; Noise per beam
               ps_file = outfile+"_noise_conv_"+stokes_par[istokes]+"_"+strtrim(lambda,2)+"mm.ps"
               wtag = where( strupcase(info_tags) eq "RESULT_ERR_FLUX_CENTER_"+$
                             strtrim(stokes_par[istokes],2)+"_"+strtrim(lambda,2)+"MM", nwtag)
               imview, sqrt(map_var_conv), xmap=grid.xmap, ymap=grid.ymap, $
                       title='Noise per beam '+strtrim(stokes_par[istokes],2)+" "+strtrim(lambda,2)+"mm", $
                       postscript=ps_file, imr=[0,3]*info.(wtag), /noclose
               ;; display beam to indicate the smoothing
               theta = dindgen(200)/199.*2*!dpi
               xbeam = min(grid.xmap) + fwhm
               ybeam = min(grid.ymap) + fwhm
               polyfill, xbeam + fwhm/2.*cos(theta), ybeam + fwhm/2.*sin(theta), col=255
               close_imview

               ;; Signa/Noise per beam
               ps_file = outfile+"_SNR_conv_"+stokes_par[istokes]+"_"+strtrim(lambda,2)+"mm.ps"
               imview, map_sn_smooth, xmap=grid.xmap, ymap=grid.ymap, $
                       title='Signal/Noise per beam '+strtrim(stokes_par[istokes],2)+" "+strtrim(lambda,2)+"mm", $
                       postscript=ps_file, imr=[-1,1]*5, /noclose
               ;; display beam to indicate the smoothing
               theta = dindgen(200)/199.*2*!dpi
               xbeam = min(grid.xmap) + fwhm
               ybeam = min(grid.ymap) + fwhm
               polyfill, xbeam + fwhm/2.*cos(theta), ybeam + fwhm/2.*sin(theta), col=255
               close_imview
            endif

         endif                  ; nhits ne 0
      endif                     ; map exists
   endfor                       ; istokes
endfor                          ; lambda

;; Compute degrees of polarization
iqu2poldeg, info.result_flux_I_1mm, info.result_flux_Q_1mm, info.result_flux_U_1mm, $
            info.result_err_flux_I_1mm,  info.result_err_flux_Q_1mm,  info.result_err_flux_U_1mm,  pol_deg, sigma_pol_deg
info.result_pol_deg_1mm = pol_deg
info.result_err_pol_deg_1mm = sigma_pol_deg

iqu2poldeg, info.result_flux_I_2mm, info.result_flux_Q_2mm, info.result_flux_U_2mm, $
            info.result_err_flux_I_2mm,  info.result_err_flux_Q_2mm,  info.result_err_flux_U_2mm,  pol_deg, sigma_pol_deg
info.result_pol_deg_2mm = pol_deg
info.result_err_pol_deg_2mm = sigma_pol_deg

;; Change names of variables for easier comparison to the current ones
;; when we restore them
param1      = param
info1       = info
grid1 = grid
if defined(kidpar) then kidpar1 = kidpar

save, file=param.output_dir+'/results.save', param1, info1, kidpar1, grid1
if param.silent eq 0 then message, /info, "saved "+param.output_dir+'/results.save'

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
get_lun,  lu
openw, lu, param.output_dir+"/photometry.csv"
title_string = 'Scan, Source, RA, DEC'
res_string   = strtrim(param.scan,2)+", "+strtrim(param.source,2)+", "+strtrim(info.longobj,2)+", "+strtrim(info.latobj,2)
for i=0, nw-1 do begin
   title_string = title_string+", "+strmid( tags[w[i]],7,tag_length[w[i]]-7)
   res_string   = res_string+", "+strtrim( info.(w[i]),2)
endfor
printf, lu, title_string
printf, lu, res_string
close, lu
free_lun, lu
;; Prepare LaTeX report with all plots produced for this scan
;;nk_latex_scan_report, param


end
