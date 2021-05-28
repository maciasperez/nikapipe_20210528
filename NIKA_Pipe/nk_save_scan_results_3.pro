
;+
;
; SOFTWARE:
;
; NAME: 
; nk_save_scan_results_3
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
;        - Oct. 2015: NP
;================================================================================================

pro nk_save_scan_results_3, param, info, data, kidpar, grid, $
                            filing=filing, xguess=xguess, yguess=yguess, $
                            header=header, grid2=grid2, grid3=grid3, $
                            info2=info2, info3=info3, results2=results2
;-  
if n_params() lt 1 then begin
   message, /info, 'Calling sequence:'
   dl_unix, 'nk_save_scan_results_3'
   return
endif

;; Do not exit if info.status here !
;; You do want to save the parameters and info and everything to diagnose a
;; problem that might have occured when the pipeline was running

;; Compute photometry if everything went fine
if info.status eq 1 then return


;; noplot is useful to compute fluxes while not displaying the maps
noplot = 1 - long( param.do_plot)

;; Gather information from the maps (photometry, centroid position...)
if strupcase( param.map_proj) eq "NASMYTH" then coltable=3
;; LP add (for focus study using small maps)
if (param.rmax_keep le 100. and strupcase( param.map_proj) eq "NASMYTH") then guess_fit_par=1. 
if defined(kidpar) then kidpar1 = kidpar

;; Save photometric information in a .csv file
w = where( kidpar.type ne 2 and kidpar.array eq 1, nw)
info.RESULT_NKIDS_TOT1 = nw
w = where( kidpar.type eq 1 and kidpar.array eq 1, nw)
info.RESULT_NKIDS_VALID1 = nw

w = where( kidpar.type ne 2 and kidpar.array eq 2, nw)
info.RESULT_NKIDS_TOT2 = nw
w = where( kidpar.type eq 1 and kidpar.array eq 2, nw)
info.RESULT_NKIDS_VALID2 = nw

w = where( kidpar.type ne 2 and kidpar.array eq 3, nw)
info.RESULT_NKIDS_TOT3 = nw
w = where( kidpar.type eq 1 and kidpar.array eq 3, nw)
info.RESULT_NKIDS_VALID3 = nw

;; Fraction of valid kids
grid.eta = [info.result_nkids_valid1/!nika.ntot_nom[0], $
            info.result_nkids_valid2/!nika.ntot_nom[1], $
            info.result_nkids_valid3/!nika.ntot_nom[2], $
            0.5*(info.result_nkids_valid1/!nika.ntot_nom[0] + info.result_nkids_valid3/!nika.ntot_nom[2]), $
            info.result_nkids_valid2/!nika.ntot_nom[1]]
info.result_eta_1   = grid.eta[0]
info.result_eta_2   = grid.eta[1]
info.result_eta_3   = grid.eta[2]
info.result_eta_1mm = grid.eta[3]
;info.result_eta_2mm = grid.eta[4]

;; Aperture photometry directly puts all the results into info
if param.do_aperture_photometry eq 1 then nk_aperture_photometry_3, param, info, grid

charsize=0.7
if param.rta eq 1 then nika_title, info, title=rta_title, /scan, /silent, /object
if param.do_plot eq 0 or param.plot_z eq 1 then noplot=1
nk_grid2info, grid, info_out, info_in=info, noplot=noplot, $
              educated = param.educated, iconic = param.iconic, ps = param.plot_ps, $
              png = param.plot_png, title=rta_title, $; montier=param.montier, $
              plot_dir = param.plot_dir, nickname = param.scan, coltable=coltable, xguess=xguess, yguess=yguess,$
              guess_fit_par=guess_fit_par, dmax=param.educated_fit_dmax, old_formula=param.old_pol_deg_formula, $
              all_time_matrix_center=all_time_matrix_center, ata_fit_beam_rmax=param.ata_fit_beam_rmax, $
              charsize=charsize, /nefd_maps, silent=param.silent, all_t_gauss_beam=all_t_gauss_beam, $
              commissioning_plot=param.commissioning_plot, noboost = long(param.boost eq 0), $
              param=param
                                ; FXD 2nd October (added param to have
                                ; param.k_snr_method available in nk_map_photometry)

if defined(grid2) then begin
   nk_grid2info, grid2, info_out2, info_in=info2, noplot=noplot, $
                 educated = param.educated, iconic = param.iconic, ps = param.plot_ps, $
                 png = param.plot_png, title=rta_title, $ ;montier=param.montier, $
                 plot_dir = param.plot_dir, nickname = param.scan, coltable=coltable, xguess=xguess, yguess=yguess,$
                 guess_fit_par=guess_fit_par, dmax=param.educated_fit_dmax, old_formula=param.old_pol_deg_formula, $
                 all_time_matrix_center=all_time_matrix_center, ata_fit_beam_rmax=param.ata_fit_beam_rmax, $
                 charsize=charsize, /nefd_maps, silent=param.silent, all_t_gauss_beam=all_t_gauss_beam, $
                 commissioning_plot=param.commissioning_plot, noboost = long(param.boost eq 0), $
                 param = param
                               
   info2 = info_out2
endif
if defined(grid3) then begin
   nk_grid2info, grid3, info_out3, info_in=info3, noplot=noplot, $
                 educated = param.educated, iconic = param.iconic, ps = param.plot_ps, $
                 png = param.plot_png, title=rta_title, $;montier=param.montier, $
                 plot_dir = param.plot_dir, nickname = param.scan, coltable=coltable, xguess=xguess, yguess=yguess,$
                 guess_fit_par=guess_fit_par, dmax=param.educated_fit_dmax, old_formula=param.old_pol_deg_formula, $
                 all_time_matrix_center=all_time_matrix_center, ata_fit_beam_rmax=param.ata_fit_beam_rmax, $
                 charsize=charsize, /nefd_maps, silent=param.silent, all_t_gauss_beam=all_t_gauss_beam, $
                 commissioning_plot=param.commissioning_plot, noboost = long(param.boost eq 0), $
                 param = param
   info3 = info_out3
endif

;; Change names of variables for easier comparison to the current ones
;; when we restore them
param1 = param
;; postponed to the end of this script
;; NP. Sept. 15th, 2016
;; info = info_out
;; info1  = info
info1 = info_out
grid1  = grid

;; Time spent on source based on geometrical considerations
nsn = n_elements(data)
d = sqrt( data.ofs_az^2 + data.ofs_el^2)
;w = where( d le 6.5/2.*60., nw) ; nominal FOV diameter: 6.5 arcmin
w = where( d le 6.2/2.*60., nw) ; effective FOV diameter: print, sqrt(!nika.ntot_nom*!nika.grid_step^2*4/!dpi)/60.
info1.result_on_source_time_geom = float(nw)/nsn * nsn/!nika.f_sampling
info1.result_T_GAUSS_BEAM_1      = all_t_gauss_beam[0]
info1.result_T_GAUSS_BEAM_2      = all_t_gauss_beam[3]
info1.result_T_GAUSS_BEAM_3      = all_t_gauss_beam[6]
info1.result_T_GAUSS_BEAM_1mm    = all_t_gauss_beam[9]
;info1.result_T_GAUSS_BEAM_2mm    = all_t_gauss_beam[12]

;; ;;--------------- Obsolete ----------
;; ;; Fraction of time actually spent on the source
;; for iarray=1, 3 do begin
;; ;;   thres = 3*!nika.fwhm_array[iarray-1]
;;    thres = !nika.grid_step[iarray-1]/2.
;; ;   thres = 0.5*!nika.fwhm_array[iarray-1]
;; ; thres = sqrt(2.)/2.* !nika.grid_step[iarray-1]  
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    if nw1 ne 0 then begin
;;       on_source = dblarr(nw1, nsn)
;;       for i=0, nw1-1 do begin
;;          ikid = w1[i]
;;          w = where( sqrt(data.dra[ikid]^2+data.ddec[ikid]^2) le thres, nw)
;;          if nw ne 0 then on_source[i,w] = 1.d0
;;       endfor
;;       on_source = double( avg( on_source, 0) ne 0)
;;       case iarray of
;;          1:info1.result_on_source_frac_array_1 = total(on_source)/n_elements(on_source)
;;          2:info1.result_on_source_frac_array_2 = total(on_source)/n_elements(on_source)
;;          3:info1.result_on_source_frac_array_3 = total(on_source)/n_elements(on_source)
;;       endcase
;;    endif
;; endfor

;; print, "all_time_matrix_center: ", $
;;        all_time_matrix_center[0], $
;;        all_time_matrix_center[3], $
;;        all_time_matrix_center[6]
;;        
;; print, "info1.result_on_source_frac_array_1: ", info1.result_on_source_frac_array_1
;; print, "info1.result_on_source_frac_array_2: ", info1.result_on_source_frac_array_2
;; print, "info1.result_on_source_frac_array_3: ", info1.result_on_source_frac_array_3
;; print, "total_obs_time: ", info1.result_total_obs_time
;; print, "total_obs_time check: ", n_elements(data)/!nika.f_sampling
;; print, "info1.result_nefd_i1, i2, i3: ", $
;;        info1.result_nefd_i1, info1.result_nefd_i2, info1.result_nefd_i3
;; print, "sigma_f*sqrt(rho_on_source*tot_obs): ", $
;;        info1.result_err_flux_i1*sqrt(info1.result_on_source_frac_array_1*info1.result_total_obs_time), $
;;        info1.result_err_flux_i2*sqrt(info1.result_on_source_frac_array_2*info1.result_total_obs_time), $
;;        info1.result_err_flux_i3*sqrt(info1.result_on_source_frac_array_3*info1.result_total_obs_time)


;; Write the summary .csv file
tags = tag_names(info1)
w = where( strupcase( strmid(tags,0,6)) eq "RESULT", nw)
tag_length = strlen( tags)
get_lun,  lu
openw, lu, param.output_dir+"/photometry.csv"
title_string = 'Scan, Source, RA, DEC'
res_string   = strtrim(param.scan,2)+", "+strtrim(param.source,2)+", "+strtrim(info1.longobj,2)+", "+strtrim(info1.latobj,2)
for i=0, nw-1 do begin
   title_string = title_string+", "+strmid( tags[w[i]],7,tag_length[w[i]]-7)
   res_string   = res_string+", "+strtrim( info1.(w[i]),2)
endfor
printf, lu, title_string
printf, lu, res_string
close, lu
;Stop, 'nk_save_scan_results_3'
;; Save results
nk_patch_info, info
if keyword_set(results2) then begin
   save_file = param.output_dir+'/results_2.save'
endif else begin
   save_file = param.output_dir+'/results.save'
endelse
save_cmd = "save, file=save_file, param1, info1, kidpar1, grid1"
if defined(header) then save_cmd += ", header"
if defined(grid2)  then save_cmd += ", grid2"
if defined(grid3)  then save_cmd += ", grid3"
if defined(info2)  then begin
   save_cmd += ", info2"
   nk_patch_info, info2
endif
if defined(info3)  then begin
   save_cmd += ", info3"
   nk_patch_info, info3
endif

if param.save_toi_corr_matrix eq 1 then begin
   mcorr_final = correlate(data.toi)
   delvarx, pk_final
   nkids = n_elements(kidpar)
   for ikid=0, nkids-1 do begin
      if kidpar[ikid].type eq 1 then begin
         power_spec, data.toi[ikid]-my_baseline(data.toi[ikid],base=0.05), $
                     !nika.f_sampling, pw, freq
         if defined(pk_final) eq 0 then begin
            pk_final = dblarr(nkids, n_elements(freq))
         endif
         pk_final[ikid,*] = pw
      endif
   endfor
   save, kidpar, mcorr_final, pk_final, freq, file=param.output_dir+'/toi_corr_matrix_and_pk_final.save'
endif
junk = execute( save_cmd)
if param.silent eq 0 then message, /info, "saved results in "+save_file+" DONE."

if param.one_fitsmap_per_scan eq 1 then begin
   output_fits_file = param.output_dir+'/map.fits'
   nk_map2fits_3, param1, info1, grid1, output_fits_file=output_fits_file, header=header
   if keyword_set(grid2) then begin
      output_fits_file = param.output_dir+'/map_aux_2.fits'
      nk_map2fits_3, param1, info2, grid2, output_fits_file=output_fits_file, header=header
   endif
   if keyword_set(grid3) then begin
      output_fits_file = param.output_dir+'/map_aux_3.fits'
      nk_map2fits_3, param1, info3, grid3, output_fits_file=output_fits_file, header=header
   endif
endif

;; restore info for online studies
;; NP. Sept. 15th, 2016
info = info1

if keyword_set(filing) then begin
   spawn, "rm -f "+param.bp_file
   spawn, "touch "+param.ok_file
   ;; removed UnProcessed file only if everything went well
   ;;if info.status eq 0 then spawn, "rm -f "+param.up_file
endif

;; Produce another copy of info and param in an ascii file. These files are faster
;; to read than the full restore of results.save
tags = tag_names(param)
ntags = n_elements(tags)
get_lun,  lu
free_lun, lu
openw, lu, param.output_dir+"/param.csv"
printf, lu, "# IDL type, tag, value"
for i=0, ntags-1 do begin
   s = size(param.(i))
   if s[0] eq 0 then $
      printf, lu, typename(param.(i))+", "+tags[i]+", "+strtrim(param.(i),2)
endfor
close, lu
free_lun, lu

tags = tag_names(info)
ntags = n_elements(tags)
get_lun,  lu
openw, lu, param.output_dir+"/info.csv"
printf, lu, "# IDL type, tag, value"
for i=0, ntags-1 do begin
   s = size( info.(i))
   if s[0] eq 0 then $
      printf, lu, typename(info.(i))+", "+tags[i]+", "+strtrim(info.(i),2)
endfor
close, lu
free_lun, lu

if defined(info2) then begin
   tags = tag_names(info2)
   ntags = n_elements(tags)
   get_lun,  lu
   openw, lu, param.output_dir+"/info2.csv"
   printf, lu, "# IDL type, tag, value"
   for i=0, ntags-1 do begin
      s = size( info2.(i))
      if s[0] eq 0 then $
         printf, lu, typename(info2.(i))+", "+tags[i]+", "+strtrim(info2.(i),2)
   endfor
   close, lu
   free_lun, lu
endif

if defined(info3) then begin
   tags = tag_names(info3)
   ntags = n_elements(tags)
   get_lun,  lu
   openw, lu, param.output_dir+"/info3.csv"
   printf, lu, "# IDL type, tag, value"
   for i=0, ntags-1 do begin
      s = size( info3.(i))
      if s[0] eq 0 then $
         printf, lu, typename(info3.(i))+", "+tags[i]+", "+strtrim(info3.(i),2)
   endfor
   close, lu
   free_lun, lu
endif



end
