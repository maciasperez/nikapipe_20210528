
;; Oct. 22nd, 2017

;; This script provides the skeleton to reduce your observations.
;; For any question: nicolas.ponthieu@univ-grenoble-alpes.fr

;;=====================================================================

;; Taylor the two following lines to your needs
source = "Pluto"
project_dir = !nika.plot_dir+"/"+source
spawn, "mkdir -p "+project_dir

;; If you running the pipeline on multiple core machine, you may set
;; parallel to 1 and define the maximum number of cpus that you can use
parallel = 1
ncpu_max = 24

;; If you already have a header on which you want to project the
;; scans, define it here
;; header = 

;; Define your list of scans.
;; One way of doing this is the following:
restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v0.save"
db_scan = scan
w = where( strupcase(db_scan.object) eq strupcase(source) and $
           db_scan.obstype eq "onTheFlyMap", nw)

scan_list = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
nscans = n_elements(scan_list)

;; Define the pipeline parameters
;; The parameters are explained in !nika.pipeline_dir+"/NIKA_Pipe/nk_default_param.pro
nk_default_param, param
param.decor_method = "COMMON_MODE_KIDS_OUT"
param.NSIGMA_CORR_BLOCK = 1
param.W8_PER_SUBSCAN =        1
param.map_xsize  =  600           ; arcsec (ignored if you use a header)
param.MAP_YSIZE  =  600           ; arcsec (ignored if you use a header)
param.map_reso             = 2.d0 ; arcsec (ignored if you use a header)
param.DO_OPACITY_CORRECTION =  2
param.DO_TEL_GAIN_CORR = 1
param.ALAIN_RF  =  1
param.MATH = "RF"
param.do_aperture_photometry = 0
param.silent               = 0
param.polynomial           = 1
param.interpol_common_mode = 1
param.do_plot              = 1
param.plot_ps              = 1
param.w8_per_subscan       = 1
param.decor_elevation      = 1
param.source    = source
param.name4file = source
param.project_dir = project_dir

;; Save the paramfile for further use
in_param_file = project_dir+"/param.save"
save, param, heaader, file=in_param_file

;; Process the data
if keyword_set(parallel) then begin
   optimize_nproc, nscans, ncpu_max, nproc
   split_for, 0, nscans-1, nsplit = nproc, $
              commands=['obs_nk_ps_2, i, scan_list, in_param_file'], $
              varnames=['scan_list', 'in_param_file']
endif else begin
   for iscan=0, nscans-1 do obs_nk_ps, iscan, scan_list, in_param_file
endelse

;; Keep only the scans that were processed correctly
keep = intarr(nscans)
for iscan=0, nscans-1 do begin
   if file_test(project_dir+"/v_1/"+scan_list[iscan]+"/info.csv") then keep[iscan]=1
endfor
w = where( keep eq 1, nw)
if nw eq 0 then begin
   message, /info, "No valid scan ?!"
   stop
endif
scan_list = scan_list[w]
nscans = n_elements(scan_list)

;; Produce the combined map
nk_average_scans, param, scan_list, grid, info=info

;; Display the result
nk_grid2info, grid, info

end
