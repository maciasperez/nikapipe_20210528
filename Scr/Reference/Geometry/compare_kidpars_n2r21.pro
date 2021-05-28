pro compare_kidpars_n2r21
  
  kidpar_file_list = !nika.off_proc_dir+'/'+[$
                     'kidpar_20180920s35_v0.fits',$
                     'kidpar_20180921s43_v0.fits',$
                     'kidpar_20180921s44_v2_LP.fits',$
                     'kidpar_20180920s46_v0.fits', $
                     'kidpar_20181103s314_v2_LP.fits', $
                     'kidpar_20181124s252_v2_LP.fits' $
                                            ]
  nobeam = 1
  ;; set to some nasmyth offset coordinates to zoom in 
  zoom_coord = [1,1]
  zoom_coord = 0
  ;; plot histograms (for fwhm and ellipticity)
  plot_histo = 1
  ;; save the plots
  savepng = 1
  saveps  = 0

  ;; all N2R21
  suf = 'N2R21'
  compare_kidpar_plot, kidpar_file_list[0:3], nobeam=nobeam, zoom_coord=zoom_coord, $
                       savepng=savepng, saveps=saveps, $
                       file_suffixe='_'+suf, $
                       plot_histo=plot_histo, wikitable=0

  ;; run a run
  suf = '3runs'
  compare_kidpar_plot, kidpar_file_list[[0, 4, 5]], nobeam=nobeam, zoom_coord=zoom_coord, $
                       savepng=savepng, saveps=saveps, $
                       file_suffixe='_'+suf, $
                       plot_histo=plot_histo, wikitable=0
  
  nobeam = 0
  ;; set to some nasmyth offset coordinates to zoom in 
  zoom_coord = [1,1]
  zoom_coord = 0
  ;; plot histograms (for fwhm and ellipticity)
  plot_histo = 1
  ;; save the plots
  savepng = 1
  saveps  = 0

 ;; N2R21-N2R23
  suf = '2runs'
  compare_kidpar_plot, kidpar_file_list[[0, 4]], nobeam=nobeam, zoom_coord=zoom_coord, $
                       savepng=savepng, saveps=saveps, $
                       file_suffixe='_'+suf, $
                       plot_histo=plot_histo, wikitable=0
  
  ;; one by one
  for ik = 0, n_elements(kidpar_file_list)-1 do begin
     suf = strmid(FILE_BASENAME(kidpar_file_list[ik], '.fits'), 7, strlen(FILE_BASENAME(kidpar_file_list[ik], '.fits')))
     compare_kidpar_plot, kidpar_file_list[ik], nobeam=nobeam, zoom_coord=zoom_coord, $
                          savepng=savepng, saveps=saveps, $
                          file_suffixe='_'+suf, $
                          plot_histo=plot_histo, wikitable=1
  endfor



end
  
