
readcol, 'blacklist.dat', scan_list, format='A'

;; nw = n_elements(scan_list)
;; keep = intarr(nw) + 1
;; for iw=0, nw-1 do begin
;;    nk_find_raw_data_file, s, d, file, imb_fits_file, xml_file, $
;;                           /silent, /noerror, scan=scan_list[iw]
;;    ant1 = mrdfits( imb_fits_file, 1, head_ant1, /silent)
;;    if typename(ant1) eq 'INT' or typename(ant1) eq 'LONG' then keep[iw] = 0
;;    
;;    ant2 = mrdfits( imb_fits_file, 2, head_ant2, /silent)
;;    if typename(ant2) eq 'INT' or typename(ant2) eq 'LONG' then keep[iw] = 0
;; endfor
;; wk = where( keep eq 1, nwk)
;; 
;; scan_list = scan_list[wk]
nscans = n_elements(scan_list)

nk_default_param, param
;param.grid_auto_init = 1
param.noerror = 1
param.no_polar = 1
param.source        = 'junk'
param.silent            = 1
param.map_reso          = 2.d0 ; arcsec
param.name4file = 'IC10'
param.project_dir = !nika.plot_dir+'/Junk/'+param.source
param.plot_dir    = param.project_dir+'/Plots'
param.preproc_dir = param.project_dir+'/Preproc'
param.up_dir = param.project_dir+'/UP_files'
param.interpol_common_mode = 1
param.do_plot  = 1
param.plot_png = 0
param.plot_ps  = 1
param.delete_all_windows_at_end = 1
param.map_xsize          = 1000.d0
param.map_ysize          = 1000.d0
param.decor_per_subscan  = 1
param.polynomial         = 0
param.decor_elevation    = 1
param.fine_pointing      = 1
param.fourier_opt_sample = 1
nk_default_info, info
nk_init_grid, param, grid
;;========== 1st iteration on a few scans to locate the source
param.decor_method    = 'common_mode' ; 'common_mode_kids_out' 
param.polynomial = 0
param.version          = 1
param.line_filter      = 0
param.flag_sat         = 0   ; to be safe for the first iteration
param.flag_uncorr_kid  = 0   ; ditto
param.w8_per_subscan   = 1
param.delete_all_windows_at_end = 0
niter = 1
results_filing=1
;;========== Preproc all files
filing  = 1
preproc = 0                   ; to save memory
;   xml = 1
;   nk_reset_filing, param, scan_list
new_black_list = ['']
grey_list = ['']
for is=0, n_elements(scan_list)-1 do begin
   param1 = param
   grid1  = grid
   delvarx, info
   nk, scan_list[is], $
       param=param1, $
       filing=filing, $
       preproc=preproc, info = info, grid = grid1
   if info.status eq 1 then new_black_list = [new_black_list, scan_list[is]]
   if info.status ne 0 and info.status ne 1 then grey_list = [grey_list, scan_list[is]]
endfor

exit:
end
