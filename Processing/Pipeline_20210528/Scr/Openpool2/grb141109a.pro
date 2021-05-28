
source = 'GRB141109A'
scan_num_list =[128, 129, 130, 131, 132, 133, 134,  135, 136, 137, 138, 139, 140, 142, 143, 144, 145, 146, 147]
day_list = '20141110'

scan_list =  day_list+'s'+strtrim(string(scan_num_list), 2)


nk_default_param, param

param.silent            = 0
param.map_xsize         = 300.d0
param.map_ysize         = 300.d0
param.map_reso          = 2.d0
param.glitch_width      = 200 ; 200 rather than 100: improves glitch detection when there's no planet to fear                                                                            

param.speed_tol =  10.d0

param.project_dir = !nika.plot_dir+"/"+strtrim( strupcase( source),2)
param.plot_dir    = param.project_dir+"/Plots"
param.preproc_dir = param.project_dir+"/Preproc"
param.interpol_common_mode = 1
param.do_plot  = 1
param.plot_png = 0
param.plot_ps  = 0

;;; 1st iteration on a few scans to locate the source
param.decor_method = "common_mode_kids_out"
param.decor_per_subscan = "yes"
param.polynomial        = 1
param.decor_elevation   = 1
param.version           = 1

nk_init_grid, param, grid
d = sqrt( grid.xmap^2 + grid.ymap^2)
w = where( d lt 20, nw)
grid.mask_source[w] = 0.d0


;param.decor_per_subscan = "yes"
;param.decor_method = 'COMMON_MODE_BAND_MASK'

;param.project_dir = !nika.plot_dir+"/"+sourcename
;param.do_plot  = 0
;param.plot_png = 1
nk_init_grid, param, grid
d = sqrt( grid.xmap^2 + grid.ymap^2)
w = where( d lt 20, nw)
grid.mask_source[w] = 0.d0

;; Preproc all files
filing  = 1
preproc = 0
xml =  1
delvarx, simpar

 nk_reset_filing, param, scan_list
 nk, scan_list, param=param, filing=filing, preproc=preproc, $
     grid=grid, simpar=simpar, no_output_map=no_output_map,  xml = xml
;; 
;; ;; Display result
 param.do_plot = 1
 param.plot_ps = 1
 nk_preproc2maps,  scan_list, param, info, grid, simpar = simpar
 
nk_average_scans, param, scan_list, out, total_obs_time, $
                  time_on_source_1mm, time_on_source_2mm, $
                  kidpar=kidpar, grid=grid, beam_pos_list = beam_pos_list

dispim_bar, filter_image(out.map_2mm,fwhm=3), /aspect, /nocont, xmap = xmap, ymap = ymap
end
