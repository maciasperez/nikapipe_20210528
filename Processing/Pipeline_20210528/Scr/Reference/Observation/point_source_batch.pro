
;; Generic script to reduce a bunch of scans on a point source
;; March 15th, 2016
;;--------------------------------------------

pro point_source_batch, scan_list, project_dir, source, info=info, grid=grid, reset=reset, process=process, average=average, $
                        parallel=parallel, simu=simu, test=test, ncpu_max=ncpu_max, decor2=decor2, method=method, $
                        quick_noise_sim=quick_noise_sim, input_kidpar_file=input_kidpar_file, mask_source=mask_source, reso=reso, $
                        map_proj=map_proj, catch_up=catch_up, no_polar=no_polar, ata_fit_beam_rmax=ata_fit_beam_rmax, $
                        polynomial=polynomial, in_param_file=in_param_file, NoTauCorrect=NoTauCorrect, version=version

if not keyword_set(map_proj) then map_proj = 'radec'
if not keyword_set(simu) then simu=0
if not keyword_set(reso) then reso=0
if keyword_set(simu) then simu=1 else simu=0
if keyword_set(decor2) then decor2=1 else decor2=0
if not keyword_set(input_kidpar_file) then input_kidpar_file=''
if keyword_set(quick_noise_sim) then quick_noise_sim = 1 else quick_noise_sim=0
if keyword_set(mask_source) then mask_source = 1 else mask_source=0
if keyword_set(no_polar) then no_polar = 1 else no_polar=0
if not keyword_set(ata_fit_beam_rmax) then ata_fit_beam_rmax=0
if not keyword_set(polynomial) then polynomial=0
if not keyword_set(in_param_file) then in_param_file=0
if not keyword_set(NoTauCorrect) then NoTauCorrect=0
if not keyword_set(method) then method = 'common_mode_kids_out'
if not keyword_set(version) then version=1

if keyword_set(test) then scan_list = scan_list[0]
nscans = n_elements(scan_list)

if keyword_set(reset) then begin
   error_report_file = project_dir+"/error_report.dat"
   spawn, "rm -f "+error_report_file
   for iscan=0, nscans-1 do begin
      scan = strtrim(scan_list[iscan],2)
      spawn, "rm -f "+project_dir+"/UP_files/OK_"+strtrim(scan,2)+".dat"
      spawn, "rm -f "+project_dir+"/UP_files/BP_"+strtrim(scan,2)+".dat"
      spawn, "rm -rf "+project_dir+"/v_"+version+"/"+strtrim(scan,2)
   endfor
endif

if keyword_set(catch_up) then begin
   for iscan=0, nscans-1 do begin
      scan = strtrim(scan_list[iscan],2)
      spawn, "rm -f "+project_dir+"/UP_files/BP_"+strtrim(scan,2)+".dat"
   endfor
endif

if keyword_set(process) then begin
   ;; List scans that actually need to be processed
   keep = intarr(nscans)
   nscans_ori = nscans
   for i=0, nscans-1 do begin
      scan = scan_list[i]
      bp_file = project_dir+"/UP_files/BP_"+scan+".dat"
      ok_file = project_dir+"/UP_files/OK_"+scan+".dat"
      if (file_test(ok_file) eq 0) and $
         (file_test(bp_file) eq 0) then process_file=1 else process_file=0
      keep[i] = process_file
   endfor
   wk = where( keep eq 1, nwk)
   if nwk eq 0 then begin
      message, /info, "all scans have already been processed."
      return
   endif else begin
      scan_list = scan_list[wk]
      nscans = n_elements(scan_list)
   endelse

;;   message, /info, "Nscans left to process (nscan/nscans_ori): "+strtrim(nscans,2)+"/"+strtrim(nscans_ori,2)
;;   i=0
;;   obs_nk_ps, i, scan_list, project_dir, in_param_file=in_param_file, $
;;              method, source, simu=simu, decor2=decor2, mask_source=mask_source, $
;;              quick_noise_sim=quick_noise_sim, input_kidpar_file=input_kidpar_file, reso=reso, $
;;              map_proj=map_proj, no_polar=no_polar, ata_fit_beam_rmax=ata_fit_beam_rmax, $
;;              polynomial=polynomial,NoTauCorrect=NoTauCorrect
;;   stop

   ;; Optimize job distribution
   if not keyword_set(ncpu_max) then ncpu_max = 20 ; to leave space for the acquisition
   ;;optimize_nproc, nscans, ncpu_max, nproc

   if nscans eq 1 then parallel = 0

   if keyword_set(parallel) then begin
      split_for, 0, nscans-1, nsplit = nproc, $
                 commands=['obs_nk_ps, i, scan_list, project_dir, in_param_file=in_param_file, '+$
                           'method, source, simu=simu, decor2=decor2, mask_source=mask_source, '+$
                           'quick_noise_sim=quick_noise_sim, input_kidpar_file=input_kidpar_file, reso=reso, '+$
                           'map_proj=map_proj, no_polar=no_polar, ata_fit_beam_rmax=ata_fit_beam_rmax, '+$
                           'polynomial=polynomial,NoTauCorrect=NoTauCorrect'], $
                 varnames=['scan_list', 'project_dir', 'in_param_file', 'method', 'source', 'simu', 'decor2', $
                           'mask_source', 'quick_noise_sim', 'input_kidpar_file', 'reso', $
                           'map_proj', 'no_polar', 'ata_fit_beam_rmax', 'polynomial', $
                           'NoTauCorrect']
   endif else begin
      for iscan=0, nscans-1 do begin
         obs_nk_ps, iscan, scan_list, project_dir, in_param_file=in_param_file, $
                    method, source, simu=simu, decor2=decor2, mask_source=mask_source, $
                    quick_noise_sim=quick_noise_sim, input_kidpar_file=input_kidpar_file, reso=reso, $
                    map_proj=map_proj, no_polar=no_polar, ata_fit_beam_rmax=ata_fit_beam_rmax, $
                    polynomial=polynomial, NoTauCorrect=NoTauCorrect
      endfor
   endelse

endif

if keyword_set(average) then begin
   ;; retrieve param
   obs_nk_ps, 0, scan_list, project_dir, method, source, $
              simu=simu, decor2=decor2, quick_noise_sim=quick_noise_sim, $
              param=param, /dry, mask_source=mask_source, reso=reso, in_param_file=in_param_file, $
              NoTauCorrect=NoTauCorrect

   ;; Build jackknife signal maps
   nscans = n_elements(scan_list)
   nk_average_scans, param, scan_list[0:nscans/2-1], grid_out, info=info, output_fits_file='map_signal_jk1.fits'
   nk_average_scans, param, scan_list[nscans/2:*], grid_out, info=info, output_fits_file='map_signal_jk2.fits'
;   stop

   ;; perform average
   nk_average_scans, param, scan_list, grid_out, info=info

endif

end
