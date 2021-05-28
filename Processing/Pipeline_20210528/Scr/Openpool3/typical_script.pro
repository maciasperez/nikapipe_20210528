
pro typical_script, proj_dir, source, source_name, plot_proj_dir, $
                    preproc_only=preproc_only, niter=niter, short=short, version=version, $
                    keep_current_result=keep_current_result, average_only=average_only


  get_lun, u
  openw,   u, proj_dir+"/script_"+strtrim( strlowcase(plot_proj_dir),2)+"_"+strtrim( strlowcase(source_name),2)+".pro"
  printf,  u, "pro script_"+strtrim( strlowcase(plot_proj_dir),2)+"_"+strtrim( strlowcase(source_name),2)+$
           ", nscans=nscans, list_results_only=list_results_only, keep_current_result=keep_current_result, $"
  printf, u, "subtract_maps=subtract_maps, preproc=preproc, average=average, reset=reset"
  
   ;; To run one source script at a time
   printf, u, "if keyword_set(average) then begin"
   printf, u, "rfile = !nika.plot_dir+'/running_"+strtrim( strlowcase(plot_proj_dir),2)+"_"+strtrim( strlowcase(source_name),2)+".dat'"
   printf, u, "if file_test(rfile) eq 1 then begin"
   printf, u, "message, /info, 'Already running'"
   printf, u, "goto, exit"
   printf, u, "endif"
   printf, u, "spawn, 'touch '+rfile"
   printf, u, "endif"

  printf, u, "db_file = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/Log_Iram_tel_Run11_v1.save'"

  printf, u, "!nika.raw_acq_dir = '/home/archeops/NIKA/Data/raw_X9'"

  printf, u, "nscans = 0 ; init"
  printf, u, "restore, db_file"
  printf, u, "w = where( strupcase( strtrim(scan.object,2))  eq strupcase('"+strtrim(source,2)+"') and $"
  printf, u, "           abs( scan.nasx_arcsec+4.4) lt 1 and $"
  printf, u, "           abs( scan.nasy_arcsec-18) lt 1 and $"
  printf, u, "           strupcase( strtrim(scan.obstype,2)) ne 'TRACK' and $"
  printf, u, "           strupcase( strtrim(scan.obstype,2)) ne 'POINTING' and $"
  printf, u, "           strupcase( strtrim(scan.obstype,2)) ne 'DIY' and $"
  printf, u, "           strupcase( strtrim(scan.obstype,2)) ne '0' and long(scan.day) le 20150210, nw)"
  printf, u, "if nw eq 0 then begin"
  printf, u, "   message, /info, 'No scan observing "+strtrim(source,2)+" was found in '+db_file"
  printf, u, "   goto, exit"
  printf, u, "endif"
  printf, u, "scan_list = scan[w].day+'s'+strtrim(scan[w].scannum,2)"
    
  printf, u, "keep = intarr(n_elements(scan_list)) + 1"

 ;;------------------------------------
 ;; 1st test on imbfits to detect potential bad scans
 ;;   printf, u, "for iw=0, nw-1 do begin"
 ;;   printf, u, "   nk_find_raw_data_file, scan[w[iw]].scannum, scan[w[iw]].day, file, imb_fits_file, xml_file, $"
 ;;   printf, u, "                          /silent, /noerror"
 ;;   printf, u, "   ant1 = mrdfits( imb_fits_file, 1, head_ant1, /silent)"
 ;;   printf, u, "   if typename(ant1) eq 'INT' or typename(ant1) eq 'LONG' then keep[iw] = 0"
 ;;   printf, u, "   "
 ;;   printf, u, "   ant2 = mrdfits( imb_fits_file, 2, head_ant2, /silent)"
 ;;   printf, u, "   if typename(ant2) eq 'INT' or typename(ant2) eq 'LONG' then keep[iw] = 0"
 ;;   printf, u, "endfor"
 
 ;;------------------------------------
 ;; Now deal with the black list determined at the fist iteration
   printf, u, "readcol, !nika.pipeline_dir+'/Scr/Openpool3/blacklist.dat', blacklist, format='A', /silent"
   printf, u, "my_match, scan_list, blacklist, suba, subb"
   printf, u, "if n_elements(suba) eq 0 then goto, exit"
   printf, u, "if suba[0] ne -1 then keep[suba] = 0"
 
   printf, u, "wk = where( keep eq 1, nwk)"
   printf, u, "if nwk eq 0 then goto, exit"
   printf, u, "scan_list = scan_list[wk]"

   if keyword_set(short) then begin
      printf, u, ""
      printf, u, "nn = n_elements(scan_list)"
      printf, u, "short = "+strtrim(short,2)
      printf, u, "scan_list = scan_list[0:(short<(nn-1))>1]"
   endif
   
   printf, u, "nscans = n_elements(scan_list)"

  printf, u, "nk_default_param, param"

  printf, u, "param.noerror = 1"
  printf, u, "param.no_polar = 1"
  printf, u, "param.grid_auto_init = 0"
  printf, u, "param.source        = '"+strtrim(source,2)+"'"
  printf, u, "param.silent            = 1"
  printf, u, "param.map_reso          = 2.d0 ; arcsec"
  printf, u, "param.name4file = '"+strtrim(source,2)+"'"

;;  printf, u, "param.project_dir = !nika.plot_dir+'/"+strtrim(plot_proj_dir,2)+"'";+"/'+param.source"
  printf, u, "param.project_dir = !nika.plot_dir+'/"+strtrim(plot_proj_dir,2)+"/'+param.source"
  printf, u, "param.plot_dir    = param.project_dir+'/Plots'"
  printf, u, "param.preproc_dir = param.project_dir+'/Preproc'"
  printf, u, "param.up_dir      = param.project_dir+'/UP_files'"
  printf, u, "param.interpol_common_mode = 1"
  printf, u, "param.do_plot  = 1"
  printf, u, "param.plot_png = 0"
  printf, u, "param.plot_ps  = 1"

  printf, u, "param.delete_all_windows_at_end = 1"

  ;; default values
  printf, u, "param.decor_method    = 'common_mode' ; 'common_mode_kids_out' "
  printf, u, "param.set_zero_level_full_scan   = 0"
  printf, u, "param.set_zero_level_per_subscan = 0"
  xsize = '500.d0'
  ysize = '500.d0'
  if strupcase( strtrim(source,2)) eq 'NGC2366' then begin
     xsize = '1000.d0'
     ysize = '1000.d0'
  endif
  if strupcase( strtrim(source,2)) eq '3C279' then begin
     xsize = '700.d0'
     ysize = '700.d0'
  endif
  if strupcase( strtrim(source,2)) eq 'MACS0717' then begin
     xsize = '700.d0'
     ysize = '700.d0'
  endif
  if strupcase( strtrim(source,2)) eq 'W3OH' then begin
     xsize = '700.d0'
     ysize = '700.d0'
  endif
  if strupcase( strtrim(source,2)) eq 'PSZ1G046' then begin
     xsize = '700.d0'
     ysize = '700.d0'
  endif
  if strupcase( strtrim(source,2)) eq 'NGC4449' then begin
     xsize = '1000.d0'
     ysize = '1000.d0'
  endif
  if strupcase( strtrim(source,2)) eq 'IC10' then begin
     xsize = '1000.d0'
     ysize = '1000.d0'
  endif
  if strupcase( strtrim(source,2)) eq '3C84' then begin
     xsize = '700.d0'
     ysize = '700.d0'
  endif
  
  printf, u, "param.map_xsize = "+xsize
  printf, u, "param.map_ysize = "+ysize

  printf, u, "param.decor_per_subscan  = 1"
  printf, u, "param.polynomial         = 0"
  printf, u, "param.decor_elevation    = 1"
  printf, u, "param.fine_pointing      = 1"
  printf, u, "param.fourier_opt_sample = 1"

  printf, u, "nk_default_info, info"
  printf, u, "nk_init_grid, param, grid"

;;   point_source_list = ['w3oh', 'rcas', 'oh231', 'ngc7027', 'm2-9', $
;;                        'irc+10216', '3c84', '3c345', '3c279', '3c273', $
;;                        '2251+158', '1741-038', '1156+295', '0923+392', '0851+202', $
;;                        '0814+425', '0745+241', '0716+714', '0439+360']
  point_source_list = ['2251+158', '1741-038', '3c345', 'm2-9', $
                       'ngc7027', 'oh231', '0851+202', '0923+392', '3c273', $
                       '0716+714', '0814+425', '0851+202', '3c279', '3c84', '1156+295', '0439+360', 'irc+10216']
;;  point_source_list = ['dummy']
  w = where( strupcase( strtrim( point_source_list,2)) eq strupcase( strtrim(source,2)), nw)
  bypass_iteration = 0 ; default
  if nw ne 0 then begin
     if strupcase( strtrim(source,2)) eq 'IRC+10216' then begin
        printf, u, "nk_default_mask, param, info, grid, dist=40"
     endif else begin
        printf, u, "nk_default_mask, param, info, grid, dist=30"
     endelse
     printf, u, "param.decor_method    = 'common_mode_kids_out'"
     bypass_iteration = 1
  endif

  printf, u, "param.polynomial = 0"

  printf, u, "param.version          = "+strtrim(version,2)

  printf, u, "param.line_filter      = 0"
  printf, u, "param.flag_sat         = 0   ; to be safe for the first iteration"
  printf, u, "param.flag_uncorr_kid  = 0   ; ditto"
  printf, u, "param.w8_per_subscan   = 1"
  printf, u, "param.delete_all_windows_at_end = 0"
  printf, u, "param.discard_outlying_samples_in_subscan = 1"
  
;;  printf, u, "results_filing=0"

printf, u, "if keyword_set(list_results_only) then begin"
printf, u, "   myfile = param.project_dir+'/'+param.source+'/MAPS_1mm_'+param.source+'_v1_iter_1.fits'"
printf, u, "   if file_test(myfile) ne 1 then print, 'missing '+myfile"
printf, u, "   goto, exit"
printf, u, "endif"
;  printf, u, "  if keyword_set(list_results_only) then $"
;  printf, u, "     print, !nika.plot_dir+'/'+param.project_dir+'/'+param.source+'/MAPS_1mm_'+param.source+'_v1_iter_1.fits'"
;  printf, u, "  goto, exit"

  printf, u, ";;========== Preproc all files"
  printf, u, "filing  = 1"
;;  printf, u, "preproc = 0                   ; to save memory"
  printf, u, ";   xml = 1"
  printf, u, "if keyword_set(reset) then nk_reset_filing, param, scan_list"

  printf, u, "if keyword_set(keep_current_result) then begin"
  printf, u, "   file = strtrim(param.project_dir,2)+'/MAPS_1mm_'+strtrim(param.name4file,2)+'_v'+strtrim(param.version,2)+'.fits'"
  printf, u, "   if file_test( file) eq 1 then begin"
  printf, u, "      message, /info, 'Source already reduced'"
  printf, u, "      goto, exit"
  printf, u, "   endif"
  printf, u, "endif"

  printf, u, "if keyword_set(subtract_maps) then begin"
  printf, u, "   subtract_map_file = !nika.plot_dir+'/output_maps_'+strtrim(param.name4file,2)+'.save'"
  printf, u, "   restore, subtract_map_file"
  printf, u, "   subtract_maps = output_maps"
  printf, u, "endif"
  printf, u, ""
  printf, u, "if keyword_set(preproc) then begin"
  printf, u, "   nk, scan_list, subtract_maps=subtract_maps, $"
  printf, u, "       param=param, $"
  printf, u, "       filing=filing, $"
  printf, u, "       info = info, grid = grid, xml = xml, results_filing=results_filing"
  printf, u, "endif"
  printf, u, "if keyword_set(average) then begin"
  printf, u, "   nk_average_scans, param, scan_list, output_maps, info=info"
  printf, u, "   save, param, output_maps, grid, file=!nika.plot_dir+'/output_maps_'+strtrim(param.name4file,2)+'.save'"
  printf, u, ";; Write final map to fits file"
  printf, u, "param.output_dir = param.project_dir"
  printf, u, "nk_map2fits, param, info, output_maps"
  printf, u, "endif"

;;   if not keyword_set(preproc_only) then begin
;;      printf, u, ";; Average and iterate"
;;      printf, u, "nk_average_scans, param, scan_list, output_maps, info=info"
;; ;  printf, u, "nk_display_maps, output_maps, title='Iter 0'"
;; ;     printf, u, "save, output_maps, file='"+strtrim(source,2)+"_iter0.save'"
;;      printf, u, "param.output_dir = param.project_dir"
;;      printf, u, " nk_map2fits, param, info, output_maps, suffix='iter_0', $"
;;      printf, u, "              output_file_1mm=output_file_1mm, output_file_2mm=output_file_2mm"
;; 
;;      printf, u, ";; Gather results for convenience"
;;      printf, u, "spawn, 'cp '+output_file_1mm+' '+!nika.plot_dir+'/.'"
;;      printf, u, "spawn, 'cp '+output_file_2mm+' '+!nika.plot_dir+'/.'"
;;  ;    printf, u, "print, output_file_1mm"
;;  ;    printf, u, "print, output_file_2mm"
;;      
;;      if bypass_iteration eq 0 then begin
;; 
;;         if keyword_set(niter) then begin
;;            printf, u, "niter = "+strtrim(niter,2)
;;            printf, u, "subtract_maps = output_maps"
;;            printf, u, "for iter=1, niter do begin"
;;            printf, u, "   nk, scan_list, param=param, $"
;;            printf, u, "       info = info, grid = grid, xml = xml, subtract_maps=subtract_maps"
;;            printf, u, "   nk_average_scans, param, scan_list, output_maps, info=info"
;;            
;;            printf, u, "   subtract_maps = output_maps"
;;            printf, u, "param.output_dir = param.project_dir"
;;            printf, u, " nk_map2fits, param, info, output_maps, suffix='iter_'+strtrim(iter,2), $"
;;            printf, u, "              output_file_1mm=output_file_1mm, output_file_2mm=output_file_2mm"
;;            printf, u, "spawn, 'cp '+output_file_1mm+' '+!nika.plot_dir+'/.'"
;;            printf, u, "spawn, 'cp '+output_file_2mm+' '+!nika.plot_dir+'/.'"
;;                                 ;       printf, u, "print, output_file_1mm"
;;                                 ;       printf, u, "print, output_file_2mm"
;; ;        printf, u, "   save, output_maps, file='"+strtrim(source,2)+"_iter'+strtrim(iter,2)+'.save'"
;;            printf, u, "endfor"
;;         endif
;;      endif     
;;      printf, u, ";; Write final map to fits file"
;;      printf, u, "param.output_dir = param.project_dir"
;;      printf, u, "nk_map2fits, param, info, output_maps"
;;   endif

  printf, u, "exit:"
  printf, u, "end"
  close, u
  free_lun, u

end
