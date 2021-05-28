pro make_hybrid_geom, file_1mm, file_2mm, output_kidpar_file

  ;; compare N2R21
  kp_file = !nika.off_proc_dir+'/'+[$
            'kidpar_20180920s35_v2_LP.fits', $
            'kidpar_20180920s35_v2_JFMP.fits']
  
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
  
  ;;compare_kidpar_plot, kp_file, nobeam=nobeam, zoom_coord=zoom_coord, $
  ;;                     savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
  ;;                     plot_histo=plot_histo
  
  
  
  ;; N2R21-N2R23
  kidpar_file_list = !nika.off_proc_dir+'/'+[$
                     'kidpar_20180920s35_v2_JFMP.fits', $
                     'kidpar_20181103s314_v2_LP.fits']
  file_2mm = kidpar_file_list[0]
  file_1mm = kidpar_file_list[1]

  output_kidpar_file = 'kidpar_hybrid_a2_20180920s35_a13_20181103s314_v2.fits'
  
  ;; for the ref KID selection, let's see compare_intercalib.pro
  ref_kid = [3129,  823, 6408]

  kp1 = mrdfits(file_1mm, 1)
  kp2 = mrdfits(file_2mm, 1)

  ;; rescaling intercalibration coef
  for ia = 0, 2 do begin
     ar = ia+1
     ;; 1
     iref = where(kp1.numdet eq ref_kid[ia], nref)
     if nref lt 1 then stop
     kp1.calib_fix_fwhm = kp1.calib_fix_fwhm/kp1[iref].calib_fix_fwhm
     ;; 2
     iref = where(kp2.numdet eq ref_kid[ia], nref)
     if nref lt 1 then stop
     kp2.calib_fix_fwhm = kp2.calib_fix_fwhm/kp2[iref].calib_fix_fwhm 
  endfor

  nkid_per_array = lonarr(3)
  w1=where(kp1.array eq 1, n1)
  nkid_per_array[0] = n1
  w3=where(kp1.array eq 3, n3)
  nkid_per_array[2] = n3
  w2=where(kp2.array eq 2, n2)
  nkid_per_array[1] = n2

  ;; init
  nkids = total(nkid_per_array)
  kp = replicate(kp1[0], nkids)

  ;; kp.array
  ibeg = 0
  iend = 0
  for ia = 0, 2 do begin
     ar = ia+1
     iend = ibeg+nkid_per_array[ia]-1
     print, 'A', strtrim(ar,2), ', ibeg = ',ibeg, ', iend = ', iend 
     kp[ibeg:iend].array = ar
     ibeg = iend+1
  endfor
  
  ;; A1&A3
  w11 = where(kp.array eq 1, n11)
  print, "check A1: ",n1, n11
  kp[w11] = kp1[w1]
  w33 = where(kp.array eq 3, n33)
  print, "check A3: ",n3, n33
  kp[w33] = kp1[w3]

  
  ;; A2
  w22 = where(kp.array eq 2, n22)
  tag1 = tag_names(kp1) ;; also tags of kp
  tag2 = tag_names(kp2)
  my_match, tag1, tag2, suba, subb

  ;; which tags are not common ?
  wd1 = where(deriv(suba) gt 1, nd1)
  print, nd1
  wd2 = where(deriv(subb) gt 1, nd2)
  print, nd2
  print, 'champs supplementaires:'
  ndiff = floor(deriv(suba(wd1)))
  for i=0, nd1-1 do if (i mod 2 eq 0) then print, tag1(suba(wd1[i])+indgen(ndiff[i])+1)
  
  stop
  
  ncommon = n_elements(suba)
  ctag = tag1[suba]
  for i=0, ncommon-1 do begin
     mytag = ctag[i]
     print, mytag
     ww = where(strmatch(tag1, mytag, /fold_case) eq 1)
     w  = where(strmatch(tag2, mytag, /fold_case) eq 1)
     kp[w22].(ww) = kp2[w2].(w) 
  endfor


  print, "Writing hybrid kidpar in ", output_kidpar_file
  nk_write_kidpar, kp, output_kidpar_file


end
