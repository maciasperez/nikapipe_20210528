;+
;  launcher script of nk.pro with baseline parameters
;
;  By default, reduce the scans of URAMUS, NEPTUNE and MWC349 observed
;  during each of the NIKA2 run of the input list "runname"
;
;  if force_source_list, reduce the scans of the given sources
;
;  if force_scan_list, reduce the given scans
;
;  LP, March 2020
;-
pro launch_baseline_nk_batch, runname, input_kidpar_file, png=png, label=label,$
                              force_scan_list = force_scan_list, $
                              force_source_list = force_source_list, $
                              output_dir = output_dir, $
                              relaunch=relaunch, $
                              no_opacity_correction = no_opacity_correction, $
                              force_param_file = force_param_file, $
                              do_aperture_photometry = do_aperture_photometry


  
reset   = 1
compute = 1
process = 1
average = 0

source = 'Calibrators'
if keyword_set(label) then source = source+label

;; by default, analyse the scans of the main primary and secondary calibrators
if keyword_set(force_source_list) then calib_sources = force_source_list else $
   calib_sources = ['uranus', 'neptune', 'mwc349']

if keyword_set(force_scan_list) then scan_list = force_scan_list else $
   get_calibration_scan_list, runname, scan_list, source_list=calib_sources, outlier_scan_list=outlier_scan_list

if keyword_set(output_dir) then project_dir = output_dir else begin
   ;; if a list of runs is given, all result files will be written in
   ;; the same directory
   outplot_dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]
   project_dir = outplot_dir+'/'+source
endelse
if file_test(project_dir, /directory) lt 1 then spawn, "mkdir -p "+project_dir

;; raw_data_dir (only for nika2d)
set_raw_data_dir, runname[0]

if keyword_set(relaunch) then begin
   spawn, 'ls -1 '+project_dir+'/v_1/*/results.save', done_scans
   if n_elements(done_scans) gt 0 then begin
      for index=0,n_elements(done_scans)-1 do begin
         p0= strpos(done_scans[index],'v_1/')
         p1= strpos(done_scans[index],'results')
         done_scans[index]= strmid(done_scans[index],p0+4,p1-(p0+5))
      endfor
      remove_scan_from_list, scan_list, done_scans, out_scan_list
      scan_list = out_scan_list
   endif 
endif


parallel = 1

;; Param
;; Define the pipeline parameter file here to keep a track

;; Param
nk_default_param, param
param.silent               = 0
param.map_reso             = 2.d0   ;; default
param.ata_fit_beam_rmax    = 60.0d0
param.polynomial           = 0      ;; default
param.map_xsize            = 1200.d0
param.map_ysize            = 1200.d0
;;---------------------------------
param.new_deglitch         = 0  ;; default
param.flag_sat             = 1  ;;0 default
param.flag_oor             = 0  ;;0 default  ; out of reso is a good flag if kidpar is fed with proper frequencies but sometimes, it's not; so, to be safe, flag_oor=0
param.flag_ovlap           = 1  ;; default
param.flag_ident           = 1 ;; default
param.flag_sat_val         = !dpi/2.d0 ;; !dpi/4D0 if RF, Cf can tolerate larger excursion
param.flag_oor_val         = 3.d0 ;; can be reduced from 3 if too many resonances are lost
param.flag_ident_val       = 1.0  ;; default 1Hz
param.flag_ovlap_val       = 0.8  ;; default
param.line_filter          = 0  ;; default
param.bandpass             = 0  ;; default
param.NSIGMA_CORR_BLOCK    = 1  ;; --> default is 2
param.fourier_opt_sample   = 0  ;; default
param.do_meas_atmo         = 0 
param.w8_per_subscan       = 1
param.interpol_common_mode = 1     ;; default
param.decor_per_subscan    = 1  ;; default
param.decor_elevation      = 1  ;; default
param.version              = 1
;;param.math                 = "RF" ;; default ; "PF" leads to a lot of unvalid KIDs ; RF leads to saturated stripes
param.math                 = 'CF'  ; should be the default FXD
param.k_rts                = 0     ; March 2020 FXD (that kills too many Kids)
; this option 1 has to be used only on faint sources
param.decor_method         = 'COMMON_MODE_ONE_BLOCK' ;; default is COMMON_MODE_KIDS_OUT
param.mask_default_radius  = 60.0d0
param.do_opacity_correction = 6  ;; default
param.do_tel_gain_corr     = 0   ;; default

if keyword_set(do_aperture_photometry) then param.do_aperture_photometry=1 else param.do_aperture_photometry=0
; FXD recommends
param.aperture_photometry_zl_rmin = 60. ; 90, 150 default  print, 90.^2-60.^2= 4500.00
param.aperture_photometry_zl_rmax = 112. ; 150, 300 default ; print,112.^2-90^2= 4444.00
param.aperture_photometry_rmeas = 90. ; 150 default

; FXD To avoid too many windows popping in
param.iconic = 1
param.plot_z = 1 ;; LP, To prevent crashes at l. 154 of nk_deal_with_pps_time

if keyword_set(no_opacity_correction) then param.do_opacity_correction = 0

;; define the parameters from an input parameter file
if keyword_set(force_param_file) then begin
   restore, force_param_file, /v
   oldparam = param
   inject_oldparam_in_newparam, oldparam, newparam
   param = newparam
   print, "pipeline parameters from ", force_param_file
   print, '.c if OK'
   stop
endif
;;-----------------------------------
param.do_plot              = 1
param.plot_dir             = project_dir
param.plot_png             = 0
param.plot_ps              = 1
param.iconic               = 1
param.project_dir          = project_dir
;;---------------------------------
param.source               = source
param.name4file            = source

param.clean_data_version   = 4

param.preproc_copy = 0
param.boost = 1  ; FXD 28 Jan 2021 to be sure to have reproducible NEFD

if strlen(input_kidpar_file) gt 1 then begin
   param.force_kidpar = 1
   param.file_kidpar = input_kidpar_file
endif

in_param_file = project_dir+'/'+source+'_param.save'
save, param, file=in_param_file

nscan_to_analyse = n_elements(scan_list)
if nscan_to_analyse eq 1 and scan_list[0] eq '' then nscan_to_analyse = 0
print, 'number of scans to reduce = ', nscan_to_analyse

if (compute eq 1 and nscan_to_analyse gt 0) then begin

   ;;print, scan_list
   ;;stop
   
   ncpu_max = 20 ;; 24
   nproc=min([nscan_to_analyse,ncpu_max])
   
   split_for, 0, nscan_to_analyse-1, $
              commands=['baseline_nk_batch, i, scan_list, in_param_file'], $
              nsplit=nproc, $
              varnames=['scan_list', 'in_param_file']
   
endif


return
end
