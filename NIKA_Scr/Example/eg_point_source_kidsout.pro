;;========== Properties of the source to be given here
;;------------------
source =  'SOURCE_NAME'
version =  '1'
name4file =  strjoin(strsplit(source, /EXTRACT), '_')
coord_source =  {ra:[0., 0., 0.], dec:[0., 0., 0.]}

;;========== Prepare output directory for plots and logbook
;;--------------
output_dir =  'where_the_maps_are_saved'
spawn, "mkdir -p "+output_dir

;;========== Scan list
s1 =  [1, ,2, 3, 4]
scan_list1 =  '20151128s'+strarr(n_elements(s1))+strtrim(s1,  2)
scan_list =  [scan_list1]
N_scan =  n_elements(scan_list)

;;========== Init default param and change the ones you want to change
;;---
nk_default_param,  param

param.source =  source
param.silent =  1
param.map_reso = 5.d0
param.project_dir = output_dir
param.plot_dir = output_dir+"/Plots"
param.interpol_common_mode = 1
param.plot_ps = 1
param.do_plot = 0

param.name4file = name4file
param.version = version
param.output_dir =   output_dir
param.map_reso =   5.0
param.map_xsize =  1000
param.map_ysize =   1000
nx =  param.map_xsize/param.map_reso + 1
ny =   param.map_ysize/param.map_reso + 1

param.decor_method = 'COMMON_MODE_KIDS_OUT'
param.decor_cm_dmin = 2.*max(!nika.fwhm_array)
param.decor_per_subscan =   1
param.decor_elevation   =   1
param.w8_per_subscan =   1
param.fine_pointing =   1
param.imbfits_ptg_restore =   0

param.do_opacity_correction =  1

nk_default_info,  info
nk_init_grid,  param,  info,  grid
nk_default_mask,   param,   info,   grid

;;========== Launch the pipeline

nk,   scan_list,   param =  param,   info =  info,   grid =  grid
;nk_parallel,   scan_list,   param =  param,   info =  info,   grid =  grid,  nproc = 10

;;========== Combine the maps

nk_average_scans,   param,   scan_list,   output_maps

stop
end

