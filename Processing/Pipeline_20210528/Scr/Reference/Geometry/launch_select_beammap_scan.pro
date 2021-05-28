;+
; AIM : help selecting the most promising beammap scan to perform a
; geometry
;
; LP, March 2020
;- 

pro launch_select_beammap_scan

  ;; 1) analyse all the beammaps of a list of NIKA2 runs and output
  ;; basic quality indicators (opacity, FWHM, ..)
  
  n2runname         = ['N2R21', 'N2R23', 'N2R24', 'N2R26', 'N2R27', 'N2R28', 'N2R29', 'N2R30']  ;; input one or several NIKA2 runs (e.g. from a same cryo run)
  c0c1_available    = 0    ;; if the skydip reduction were already successfully done
  input_kidpar_file = !nika.off_proc_dir+'/kidpar_20181103s314_v2_LP.fits' ;; kidpar_20181124s252_v2_LP.fits' ;; if '', pick the default reference kidpar of NIKA_Pipe for the first NIKA2 run (as given by n2runname)
  wikitable         = 1   ;; set to 1 if the results are to be copied in a wiki 
  
  select_beammap_scan, n2runname, allscan_info, input_kidpar_file=input_kidpar_file, c0c1_available=c0c1_available, wikitable=wikitable, label='_v2'

  stop
  
  n2runname         = ['N2R49', 'N2R50'] ;; input one or several NIKA2 runs (e.g. from a same cryo run)
  c0c1_available    = 0    ;; if the skydip reduction were already successfully done
  input_kidpar_file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_25766_part2.fits" 
  wikitable         = 1   ;; set to 1 if the results are to be copied in a wiki
  pdf_fig_dir       = '/rdata/perotto/Calibration/Inspect_Beammaps' ;; save fig in pdf
  
  select_beammap_scan, n2runname, allscan_info, input_kidpar_file=input_kidpar_file, c0c1_available=c0c1_available, wikitable=wikitable, pdf_fig_dir=pdf_fig_dir

  
  ;; 2) let's have a look at the current reference kidpar
  get_nika2_run_info, nika2run_info
  wrun = where(strmatch(nika2run_info.nika2run, n2runname[0]) gt 0)
  day = nika2run_info[wrun].lastday
  nk_get_kidpar_ref, '1', day, info, kidpar_file
  kidpar_file_list = [kidpar_file]

  print, "Reference KID at 2mm = ",  !nika.ref_det[1]
  print, "Reference KIDs at 1mm = ", !nika.ref_det[0], !nika.ref_det[2]
  
  ;; set to 1 to plot the kid offsets only (no ellipses)
  nobeam = 0
  ;; set to some nasmyth offset coordinates to zoom in 
  zoom_coord = [1,1]
  zoom_coord = 0
  ;; plot histograms (for fwhm and ellipticity)
  plot_histo = 1
  ;; save the plots
  savepng = 0
  saveps  = 0
  file_suffixe = 0
   
  compare_kidpar_plot, kidpar_file_list, nobeam=nobeam, zoom_coord=zoom_coord, $
                       savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
                       plot_histo=plot_histo


  ;; check the reference KID
  ;;-----------------------------------------------------------------------------
  ;; set to 1 to plot the kid offsets only (no ellipses)
  nobeam = 1
  ;; set to some nasmyth offset coordinates to zoom in 
  zoom_coord = [1,1]
  ;; plot histograms (for fwhm and ellipticity)
  plot_histo = 0
  ;; save the plots
  savepng = 0
  saveps  = 0
  file_suffixe = 0
   
                     
  compare_kidpar_plot, kidpar_file_list, nobeam=nobeam, zoom_coord=zoom_coord, $
                       savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
                       plot_histo=plot_histo

  
  
  
  ;; 3) if several kidpars were already produced, compare them
  kidpar_file_list = !nika.off_proc_dir+'/'+[$
                     ;;'kidpar_20201023s23_LP_v0.fits', $ ;; VENUS
                     ;;'kidpar_20201023s105_NP_v0.fits',$ ;; MARS
                     ;;'kidpar_20201023s107_NP_v0.fits',$ ;; MARS
                     'kidpar_20201023s116_LP_v0.fits',$
                     'kidpar_20201024s22_LP_v0.fits', $
                     'kidpar_20201101s297_LP_v0.fits'$
                                            ]

  
  nobeam = 0
  ;; set to some nasmyth offset coordinates to zoom in 
  zoom_coord = [1,1]
  zoom_coord = 0
  ;; plot histograms (for fwhm and ellipticity)
  plot_histo = 1
  ;; save the plots
  savepng = 1
  saveps  = 0
  file_suffixe = 0
   
  compare_kidpar_plot, kidpar_file_list, nobeam=nobeam, zoom_coord=zoom_coord, $
                       savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
                       plot_histo=plot_histo



  
  
end
