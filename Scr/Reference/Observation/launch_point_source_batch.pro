;
;  launcher script based on JFMP's launch_all_otfs.pro 
;
pro launch_point_source_batch, runname, input_kidpar_file, reset=reset, png=png, label=label,$
                     force_scan_list = force_scan_list, relaunch=relaunch

reset   = 1
compute = 1
process = 1
average = 0

;;*************
;; Careful for these parameters that are only temporary !
;math = "RF"
;do_opacity_correction = 4

source= strtrim(string(runname),2)+'_OTFS'
if keyword_set(label) then source = source+'_'+label

;; define scan list using JFMP database
;dir_file = !nika.soft_dir+'/Labtools/JM/NIKA2/ScansLists/'
;file = dir_file+'/'+strtrim(string(runname),2)+'/nkotfs_scans.fits'
;scan_list = (mrdfits(sfile,1,h)).scans


if keyword_set(force_scan_list) then scan_list = force_scan_list

outplot_dir = getenv('NIKA_PLOT_DIR')+'/'+runname
project_dir = outplot_dir+"/"+source+'/'

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
method = 'COMMON_MODE_ONE_BLOCK'
decor2 = 0
ATA_FIT_BEAM_RMAX = 60.000000
polynomial = 0
mask_default_radius = 60.0d0
opacity_correction = 6

point_source_default_param, param, simpar, method, source, $
                            decor2=decor2, input_kidpar_file=input_kidpar_file, reso=reso, $
                            map_proj=map_proj, ata_fit_beam_rmax=ata_fit_beam_rmax, $
                            polynomial=polynomial, do_tel_gain_corr=do_tel_gain_corr, $
                            mask_default_radius=mask_default_radius, $
                            opacity_correction=opacity_correction



;nk_default_param, param
;param.silent               = 0
;param.map_reso             = 2.d0
;param.polynomial           = 0
;param.interpol_common_mode = 1
;param.do_plot              = 1
;param.plot_png             = 0
;param.plot_ps              = 1
;param.new_deglitch         = 0
;param.flag_sat             = 0
;param.flag_oor             = 0
;param.flag_ovlap           = 0
;param.line_filter          = 0
;param.fourier_opt_sample   = 1
;param.do_meas_atmo         = 0
;param.w8_per_subscan       = 1
;param.decor_elevation      = 1
;param.version              = '1'
;param.do_aperture_photometry = 1
;param.output_noise = 1
;param.preproc_copy = 0
;param.preproc_dir = !nika.plot_dir+"/Preproc"
;param.source    = source
;param.name4file = source
;param.FLAG_OVLAP   =        1
;param.decor_method = 'COMMON_MODE_ONE_BLOCK'
;param.NSIGMA_CORR_BLOCK =        1
;param.BANDPASS = 0
;param.FREQHIGH = 7.0000000 ;; not used if param.bandpass=0
;param.W8_PER_SUBSCAN =        1
;param.map_xsize  =        900.00000
;param.MAP_YSIZE  =        900.00000
;param.ATA_FIT_BEAM_RMAX =        60.000000
;param.DO_OPACITY_CORRECTION =        4
;param.DO_TEL_GAIN_CORR =        0
;param.FOURIER_OPT_SAMPLE =        1
param.ALAIN_RF  =        1
param.MATH = 'RF'
;param.force_kidpar = 1
;param.file_kidpar  = input_kidpar_file
;param.project_dir = project_dir

spawn, 'mkdir -p '+ project_dir
in_param_file = project_dir+'/'+source+'_param.save'
save, param, file=in_param_file

print, 'number of scans to reduce = ', n_elements(scan_list)

if compute eq 1 then begin
   point_source_batch, scan_list, project_dir, source, $
                       reset=reset, process=process, average=average, $
                       parallel=parallel, simu=simu, test=test, decor2=decor2, $
                       method=method, quick_noise_sim=quick_noise_sim, $
                       input_kidpar_file=input_kidpar_file, $
                       mask=do_mask, in_param_file=in_param_file, version =param.version
endif


return
end
