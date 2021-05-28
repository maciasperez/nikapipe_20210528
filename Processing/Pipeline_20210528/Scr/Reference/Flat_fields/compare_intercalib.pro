pro compare_intercalib, png=png, ps=ps, label=label

  ;; 3 runs
  kidpar_file_list = !nika.off_proc_dir+'/'+[$
                     'kidpar_20180920s35_v0_NP.fits',$
                     'kidpar_20180920s35_v2_LP.fits',$
                     'kidpar_20180921s43_v0.fits',$
                     'kidpar_20180921s44_v2_LP.fits',$
                     'kidpar_20180920s46_v0.fits', $
                     'kidpar_20181103s314_v2_LP.fits', $
                     'kidpar_20181124s252_v2_LP.fits' $
                                            ]

  ;; N2R21-N2R23
  kidpar_file_list = !nika.off_proc_dir+'/'+[$
                     'kidpar_20180920s35_v2_LP.fits',$
                     'kidpar_20180920s35_v2_JFMP.fits',$
                     'kidpar_20181103s314_v2_LP.fits',$
                     'kidpar_N2R24_ref_baseline_BL.fits']

  ;;
  kp1 = mrdfits(kidpar_file_list[0],1)
  f1 = kp1.frequency
  ft1 = kp1.f_tone

  kp2 = mrdfits(kidpar_file_list[1],1)
  f2 = kp2.frequency
  ft2 = kp2.f_tone

  kp3 = mrdfits(kidpar_file_list[2],1)
  f3 = kp3.frequency
  ft3 = kp3.f_tone
  ;;
  
  ;; NAME
  ntot1 = n_elements(kp1.name)
  wmiss = where(strmid(kp1.name, 0, 1) ne 'K', nmiss, compl=wok, ncompl=nok)
  for i=0, nok-1 do print, kp1[wok[i]].name, ' ', kp1[wok[i]].numdet
  
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14, col_1mm
  colors  = [30, 160, 85, 238, 50, 118, 200]
  
  if keyword_set(ps) then begin
     ps=1
     ps_xsize    = 20       ;; in cm
     ps_ysize    = 18       ;; in cm
     ps_charsize = 1.
     ps_yoffset  = 0.
     ps_thick    = 4.
  endif

  if keyword_set(label) then suf = label else suf=''

  
  
  nk = n_elements(kidpar_file_list)


  ;; list of numdet  
  all_numdets = ''
  all_arrays  = ''
  for i=0, nk-1 do begin
     kp = mrdfits(kidpar_file_list[i], 1)
     wok= where(kp.type eq 1)
     all_numdets = [all_numdets, kp[wok].numdet]
     all_arrays  = [all_arrays,  kp[wok].array]
  endfor
  all_numdets = all_numdets[1:*]
  all_arrays  = all_arrays[ 1:*]
  index = uniq(all_numdets, sort(all_numdets))
  numdet_list = all_numdets[index]
  array_list  = all_arrays[index]

  
  ;; choose a reference KID per array
  ref_kid0 = [3137, 823, 6026] ;; first guess
  nkids = n_elements(numdet_list)
  count_numdet = lonarr(nkids)
  for i=0, nk-1 do begin
     kp = mrdfits(kidpar_file_list[i], 1)
     kp = kp[where(kp.type eq 1)]
     my_match, kp.numdet, numdet_list, suba, subb
     count_numdet[subb] += 1
  endfor

  ref_kid = ref_kid0
  for ia = 0, 2 do begin
     wa = where(array_list eq (ia+1))
     w=where(count_numdet[wa] eq nk, nall)
     ref_kid[ia] = numdet_list[wa[w[nall/2]]]
  endfor

  print, "reference KIDs = ", ref_kid
  w=where(numdet_list eq ref_kid0[1])
  if count_numdet[w] eq nk then ref_kid[1] = ref_kid0[1]
  print, "reference KIDs = ", ref_kid


  for ia = 0, 2 do begin

     ar = ia+1
     print,''
     print,'Array ', strtrim(ar, 2)
     numdet_pera = numdet_list(where(array_list eq ar))
     
     ;; table of the gains
     nkids = n_elements(numdet_pera)
     print, "n KID in A", strtrim(ar, 2), ' = ', nkids
     tab_calib = dblarr(nkids, nk)
     leg_tab = strarr(nk)
     for i=0, nk-1 do begin
        kp = mrdfits(kidpar_file_list[i], 1)
        kp = kp[where(kp.type eq 1 and kp.array eq ar)]
        iref = where(kp.numdet eq ref_kid[ia], nref)
        if nref lt 1 then stop
        kp.calib_fix_fwhm = kp.calib_fix_fwhm/kp[iref].calib_fix_fwhm  
        my_match, kp.numdet, numdet_pera, suba, subb
        tab_calib[subb, i] = kp[suba].calib_fix_fwhm
        leg_tab[i] = strmid(FILE_BASENAME(kidpar_file_list[i], '.fits'), 7, 20)
     endfor

     ;; plot
     gmed = median(tab_calib)
     grms = stddev(tab_calib)
     index = indgen(nkids)
     wind, 1, 1, /free, xsize=1300, ysize=450
     outplot, file='plot_compare_intercalib_arr'+strtrim(ar, 2)+suf, png=png, $
              ps=ps, xsize=22., ysize=8., charsize=ps_charsize, thick=ps_thick
     plot, index, tab_calib[*, 0], yr=[-0.1, gmed+7.*grms], /ys, /xs, /nodata, $
           ytitle='Gain A'+strtrim(ar,2), xtitle='KID index'
     for i=0, nk-1 do oplot, index, tab_calib[*, i], col=colors[i], psym=8, symsize=0.7
     legendastro, leg_tab, line=0, col=colors[0:nk-1], box=0, /trad
     outplot, /close
  endfor

  stop
  


                     

  
end
