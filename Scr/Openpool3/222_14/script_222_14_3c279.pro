pro script_222_14_3c279, nscans=nscans, list_results_only=list_results_only, keep_current_result=keep_current_result, $
subtract_maps=subtract_maps, preproc=preproc, average=average, reset=reset
if keyword_set(average) then begin
rfile = !nika.plot_dir+'/running_222_14_3c279.dat'
if file_test(rfile) eq 1 then begin
message, /info, 'Already running'
goto, exit
endif
spawn, 'touch '+rfile
endif
db_file = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/Log_Iram_tel_Run11_v1.save'
!nika.raw_acq_dir = '/home/archeops/NIKA/Data/raw_X9'
nscans = 0 ; init
restore, db_file
w = where( strupcase( strtrim(scan.object,2))  eq strupcase('3C279') and $
           abs( scan.nasx_arcsec+4.4) lt 1 and $
           abs( scan.nasy_arcsec-18) lt 1 and $
           strupcase( strtrim(scan.obstype,2)) ne 'TRACK' and $
           strupcase( strtrim(scan.obstype,2)) ne 'POINTING' and $
           strupcase( strtrim(scan.obstype,2)) ne 'DIY' and $
           strupcase( strtrim(scan.obstype,2)) ne '0' and long(scan.day) le 20150210, nw)
if nw eq 0 then begin
   message, /info, 'No scan observing 3C279 was found in '+db_file
   goto, exit
endif
scan_list = scan[w].day+'s'+strtrim(scan[w].scannum,2)
keep = intarr(n_elements(scan_list)) + 1
readcol, !nika.pipeline_dir+'/Scr/Openpool3/blacklist.dat', blacklist, format='A', /silent
my_match, scan_list, blacklist, suba, subb
if n_elements(suba) eq 0 then goto, exit
if suba[0] ne -1 then keep[suba] = 0
wk = where( keep eq 1, nwk)
if nwk eq 0 then goto, exit
scan_list = scan_list[wk]
nscans = n_elements(scan_list)
nk_default_param, param
param.noerror = 1
param.no_polar = 1
param.grid_auto_init = 0
param.source        = '3C279'
param.silent            = 1
param.map_reso          = 2.d0 ; arcsec
param.name4file = '3C279'
param.project_dir = !nika.plot_dir+'/222_14/'+param.source
param.plot_dir    = param.project_dir+'/Plots'
param.preproc_dir = param.project_dir+'/Preproc'
param.up_dir      = param.project_dir+'/UP_files'
param.interpol_common_mode = 1
param.do_plot  = 1
param.plot_png = 0
param.plot_ps  = 1
param.delete_all_windows_at_end = 1
param.decor_method    = 'common_mode' ; 'common_mode_kids_out' 
param.set_zero_level_full_scan   = 0
param.set_zero_level_per_subscan = 0
param.map_xsize = 700.d0
param.map_ysize = 700.d0
param.decor_per_subscan  = 1
param.polynomial         = 0
param.decor_elevation    = 1
param.fine_pointing      = 1
param.fourier_opt_sample = 1
nk_default_info, info
nk_init_grid, param, grid
nk_default_mask, param, info, grid, dist=30
param.decor_method    = 'common_mode_kids_out'
param.polynomial = 0
param.version          = 0
param.line_filter      = 0
param.flag_sat         = 0   ; to be safe for the first iteration
param.flag_uncorr_kid  = 0   ; ditto
param.w8_per_subscan   = 1
param.delete_all_windows_at_end = 0
param.discard_outlying_samples_in_subscan = 1
if keyword_set(list_results_only) then begin
   myfile = param.project_dir+'/'+param.source+'/MAPS_1mm_'+param.source+'_v1_iter_1.fits'
   if file_test(myfile) ne 1 then print, 'missing '+myfile
   goto, exit
endif
;;========== Preproc all files
filing  = 1
;   xml = 1
if keyword_set(reset) then nk_reset_filing, param, scan_list
if keyword_set(keep_current_result) then begin
   file = strtrim(param.project_dir,2)+'/MAPS_1mm_'+strtrim(param.name4file,2)+'_v'+strtrim(param.version,2)+'.fits'
   if file_test( file) eq 1 then begin
      message, /info, 'Source already reduced'
      goto, exit
   endif
endif
if keyword_set(subtract_maps) then begin
   subtract_map_file = !nika.plot_dir+'/output_maps_'+strtrim(param.name4file,2)+'.save'
   restore, subtract_map_file
   subtract_maps = output_maps
endif

if keyword_set(preproc) then begin
   nk, scan_list, subtract_maps=subtract_maps, $
       param=param, $
       filing=filing, $
       info = info, grid = grid, xml = xml, results_filing=results_filing
endif
if keyword_set(average) then begin
   nk_average_scans, param, scan_list, output_maps, info=info
   save, param, output_maps, grid, file=!nika.plot_dir+'/output_maps_'+strtrim(param.name4file,2)+'.save'
;; Write final map to fits file
param.output_dir = param.project_dir
nk_map2fits, param, info, output_maps
endif
exit:
end
