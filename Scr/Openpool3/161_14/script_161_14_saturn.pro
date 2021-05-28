pro script_161_14_saturn, nscans=nscans
db_file = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/Log_Iram_tel_Run11_v1.save'
;!nika.raw_acq_dir = '/home/archeops/NIKA/Data/raw_X9'
nscans = 0 ; init
restore, db_file
w = where( strupcase( strtrim(scan.object,2))  eq strupcase('SATURN') and $
           abs( scan.nasx_arcsec+4.4) lt 1 and $
           abs( scan.nasy_arcsec-18) lt 1 and $
           strupcase( strtrim(scan.obstype,2)) ne 'TRACK' and $
           strupcase( strtrim(scan.obstype,2)) ne 'POINTING' and $
           strupcase( strtrim(scan.obstype,2)) ne 'DIY' and $
           strupcase( strtrim(scan.obstype,2)) ne '0' and long(scan.day) le 20150210, nw)
if nw eq 0 then begin
   message, /info, 'No scan observing SATURN was found in '+db_file
   goto, exit
endif
scan_list = scan[w].day+'s'+strtrim(scan[w].scannum,2)
keep = intarr(nw) + 1
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
param.source        = 'SATURN'
param.silent            = 1
param.map_reso          = 2.d0 ; arcsec
param.name4file = 'SATURN'
param.project_dir = !nika.plot_dir+'/161_14/'+param.source
param.plot_dir    = param.project_dir+'/Plots'
param.preproc_dir = param.project_dir+'/Preproc'
param.up_dir = param.project_dir+'/UP_files'
param.interpol_common_mode = 1
param.do_plot  = 1
param.plot_png = 0
param.plot_ps  = 1
param.delete_all_windows_at_end = 1
param.map_xsize = 500.d0
param.map_ysize = 500.d0
param.decor_per_subscan  = 1
param.polynomial         = 0
param.decor_elevation    = 1
param.fine_pointing      = 1
param.fourier_opt_sample = 1
nk_default_info, info
nk_init_grid, param, grid
;;========== 1st iteration on a few scans to locate the source
param.decor_method    = 'common_mode' ; 'common_mode_kids_out' 
param.set_zero_level_full_scan   = 0
param.set_zero_level_per_subscan = 0
param.polynomial = 0
param.version          = 1
param.line_filter      = 0
param.flag_sat         = 0   ; to be safe for the first iteration
param.flag_uncorr_kid  = 0   ; ditto
param.w8_per_subscan   = 1
param.delete_all_windows_at_end = 0
results_filing=1
;;========== Preproc all files
filing  = 1
preproc = 0                   ; to save memory
;   xml = 1
;   nk_reset_filing, param, scan_list
nk, scan_list, $
    param=param, $
    filing=filing, $
    preproc=preproc, info = info, grid = grid, xml = xml, results_filing=results_filing
;; Average and iterate
nk_average_scans, param, scan_list, output_maps
param.output_dir = param.project_dir
 nk_map2fits, param, info, output_maps, suffix='iter_0'
niter = 1
subtract_maps = output_maps
for iter=1, niter do begin
   nk, scan_list, param=param, $
       info = info, grid = grid, xml = xml, subtract_maps=subtract_maps
   nk_average_scans, param, scan_list, output_maps
   subtract_maps = output_maps
param.output_dir = param.project_dir
 nk_map2fits, param, info, output_maps, suffix='iter_'+strtrim(iter,2)
endfor
;; Write final map to fits file
nk_map2fits, param, info, output_maps
exit:
end
