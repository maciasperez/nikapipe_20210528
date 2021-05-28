
pro my_skydip, isc, scan_list, outdir, force_file_kidpar, output_dir

  ;isc = 0
  ;scan_list=['20210119s13']
  ;outdir = getenv('NIKA_PLOT_DIR')+'/N2R49/Opacity'
  ;force_file_kidpar=!nika.off_proc_dir+'/kidpar_20201122s4_v2_LP_26120.fits'
  
  print, '--------------------------------------------'
  scanname = scan_list[isc]
  nscans = n_elements(scan_list)
  print, "scan "+strtrim(isc,2)+" on "+strtrim(nscans-1,2)+": ", scanname
  nk_scan2run, scanname

  result_dir = outdir +"/Skydips/"+scanname 
  file_save  = result_dir+"/results.save"
  day = strmid( scanname,0,8)
  scan_num = long( strmid( scanname,9))

  nk_default_param, param
  param.plot_dir = outdir+"/Skydips/"+day+"s"+strtrim(scan_num,2)
  spawn, "mkdir -p "+param.plot_dir
  param.force_kidpar = 1
  param.file_kidpar  = force_file_kidpar
  param.silent= 0
  param.do_plot=1 
  param.plot_png=1
  ;; LP fix raw_acq_dir issue
  ;;raw_acq_dir=getenv('NIKA_RAW_ACQ_DIR')
  
  nk_skydip_5, scan_num, day, param, info, kidpar, data, dred, kidout = kidout;;, raw_acq_dir=raw_acq_dir
  spawn, "mkdir -p "+output_dir
  save, param, info, kidpar, dred, kidout, file=file_save
end
