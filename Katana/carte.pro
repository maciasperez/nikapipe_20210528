
;; Wrapper for the instrumentalists to katana, /fast

pro carte, force_file

source   = "labo"

check_sn_range = 0

nk_default_param, param
param.map_xsize = 400.
param.map_ysize = 400.
param.map_reso  = 8.
param.math      = "RF"
param.flag_ovlap = 0
param.flag_sat=0
param.flag_oor=0
param.flag_ovlap=0

param.speed_tol = 20 ; 10.

sn_min = 0
sn_max = 0

filename = file_basename( force_file)
filename = str_replace( strmid( filename, 2, 10), "_", "")
filename = str_replace( filename, "_", "")
day = strtrim( filename,2)

feeline = 'unknown'
input_kidpar_file = ''


run_timelines = 0

scan_num = strtrim( long( randomu( seed, 1)*1e8),2)

scan              = strtrim(day,2)+"s"+strtrim(scan_num,2)
param.scan        = scan
param.day         = day
param.project_dir = !nika.plot_dir+"/Lab_tests"
param.plot_dir    = param.project_dir+'/Plots'
;; param.preproc_dir = param.project_dir+'/Preproc'
;; param.up_dir      = param.project_dir+'/UP_files'
param.output_dir  = param.project_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+param.project_dir
spawn, "mkdir -p "+param.plot_dir
;; spawn, "mkdir -p "+param.preproc_dir
;; spawn, "mkdir -p "+param.up_dir
spawn, "mkdir -p "+param.output_dir

param.lab = 1

katana, scan_num, day, "labo", check_sn_range=check_sn_range, $
        force_file=force_file, /lab, in_param=param, output_kidpar_fits="kidpar_"+scan+".fits", $
        sn_min=sn_min, sn_max=sn_max, /fast
print, ""
print, "All plots and summary files are in "+param.output_dir

end
