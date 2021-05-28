pro nk_main_beam_sub, iscan, scan_list, input_dir=input_dir, output_dir=output_dir, $
                      do_opacity_correction=do_opacity_correction, $
                      file_kidpar=file_kidpar, decor_method=decor_method, decor_cm_dmin=decor_cm_dmin, $
                      map_reso=map_reso, map_size=map_size, $
                      map_proj = map_proj, version=version, relaunch_nk=relaunch_nk, file_suffixe=file_suffixe, $
                      fixmask=fixmask, noplot=noplot

  if keyword_set(do_opacity_correction) then do_opacity_correction=do_opacity_correction else do_opacity_correction=2
  if keyword_set(file_kidpar) and file_kidpar ne '' then begin
     force_kidpar = 1
     file_kidpar  = file_kidpar
  endif else force_kidpar=0
  if keyword_set(decor_method) then decor_method = decor_method else decor_method  = 'COMMON_MODE_KIDS_OUT'
  if keyword_set(decor_cm_dmin) then decor_cm_dmin=decor_cm_dmin else decor_cm_dmin=60.
  if keyword_set(map_reso) then map_reso = map_reso else map_reso =2.d0
  if keyword_set(map_size) then map_size = map_size else map_size =400.d0
  if keyword_set(map_proj) then map_proj = map_proj else map_proj ='radec'
  if keyword_set(input_dir) then indir = input_dir else indir = !nika.plot_dir
  if keyword_set(output_dir) then outdir = output_dir else outdir = !nika.plot_dir
  if keyword_set(version)  then version = version else version = '1'
  if keyword_set(fixmask)  then fixmask = 1 else fixmask = 0

  
  nk_default_param, param

  ;; cp params from launch_all_otfs
  
  param.silent               = 0
  param.map_reso             = 2.d0
  param.ata_fit_beam_rmax    = 60.d0
  param.polynomial           = 0
  param.map_xsize            = 15.*60.d0
  param.map_ysize            = 15.*60.d0
  param.interpol_common_mode = 1
  param.do_plot              = 1
  param.plot_png             = 0
  param.plot_ps              = 1
  param.new_deglitch         = 0
  param.flag_sat             = 0
  param.flag_oor             = 0
  param.flag_ovlap           = 0
  param.line_filter          = 0
  param.fourier_opt_sample   = 1
  param.do_meas_atmo         = 0
  param.w8_per_subscan       = 1
  param.decor_elevation      = 1
  param.version              = '1'
  param.do_aperture_photometry = 1
  param.output_noise = 1
  param.preproc_copy = 0
  param.preproc_dir = !nika.plot_dir+"/Preproc"
  ;;param.source    = source
  ;;param.name4file = source
  
  param.FLAG_OVLAP =        1
  param.decor_method = 'COMMON_MODE_ONE_BLOCK'
  param.NSIGMA_CORR_BLOCK =        1
  param.BANDPASS =        1                   ;; 0 chez Juan....
  if keyword_set(juan) then param.BANDPASS =        0
  param.FREQHIGH =        7.0000000
  param.W8_PER_SUBSCAN =        1
  param.map_xsize  =        900.00000
  param.MAP_YSIZE  =        900.00000
  param.ATA_FIT_BEAM_RMAX =        60.000000
  param.DO_OPACITY_CORRECTION =        4
  param.DO_TEL_GAIN_CORR =        0
  param.FOURIER_OPT_SAMPLE =        1
  param.ALAIN_RF  =        1
  param.MATH = 'RF' 
  ;; end copy
  
  param.do_opacity_correction = do_opacity_correction
  param.force_kidpar          = force_kidpar
  param.file_kidpar           = file_kidpar
  param.do_plot               = 0
  param.decor_method          = decor_method
  param.decor_cm_dmin         = decor_cm_dmin
  param.map_reso              = map_reso
  param.map_xsize             = map_size
  param.map_ysize             = map_size
  param.map_proj              = map_proj
  param.version               = version
  param.project_dir           = indir
  
  
  scan = scan_list[iscan]

  if keyword_set(relaunch_nk) then nk, scan, param=param
  
  nk_scan2run, scan
  result_file = indir+'/v_'+strtrim(version,2)+'/'+scan+'/results.save'
  restore, result_file, /v
  
  dir = outdir+'/v_'+strtrim(version,2)+'/'+scan
  spawn, 'mkdir -p '+dir
  
  if keyword_set(noplot) then begin
     param1.do_plot  = 0
     param1.plot_ps  = 0
     param1.plot_png = 0
  endif
  
  if fixmask gt 0 then begin
     nk_main_beam_fwhm_fixmask, param1, info1, kidpar1, grid1, $
                                output_dir = dir, $
                                file_suffixe=file_suffixe, filing=filing, xguess=xguess, $
                                yguess=yguess, chisquare=1, mask_inner_radius=[9.d0, 14.d0] ;[3.d0, 9.d0]
  endif else begin
     nk_main_beam_fwhm, param1, info1, kidpar1, grid1, $
                        output_dir = dir, $
                        file_suffixe=file_suffixe, filing=filing, xguess=xguess, $
                        yguess=yguess, chisquare=1
  endelse
  
end
