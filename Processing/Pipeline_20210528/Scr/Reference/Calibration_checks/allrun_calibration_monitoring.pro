;+
; Aim: 1) gather basic information on the calibration of each runs  
;      2) calculate an absolute calibration rescaling factor
;      w.r.t. the Baseline calibration
;
; creation, LP, Feb. 2020
;-
pro allrun_calibration_monitoring, ps=ps

  first_run_id = 9
  last_run_id  = 41
  
  ;;-------------------------------------------------------------------------
  ;;
  ;;  Selection of the Science Pools
  ;;--------------------------------------------------------------------------
  first_nika2_run = 'N2R'+strtrim(first_run_id,2)
  last_nika2_run = 'N2R'+strtrim(last_run_id,2)
  get_science_pool_info, science_pool_info, first_nika2_run=first_nika2_run, last_nika2_run=last_nika2_run
  
  list_of_kidpars  = science_pool_info.kidpar_ref
  list_of_cryoruns = science_pool_info.cryorun
  list_of_runs     = science_pool_info.nika2run

  nruns = n_elements(list_of_runs)
  
  ;;-------------------------------------------------------------------------
  ;;
  ;;  Selection of calibrated runs
  ;;--------------------------------------------------------------------------
  print, 'Kidpar checks: '
  for irun = 0, nruns-1 do print, list_of_runs[irun],', ', file_basename(list_of_kidpars[irun])
  noskydip_runs = ['N2R34', 'N2R35', 'N2R39', 'N2R40']
     
  ;;-------------------------------------------------------------------------
  ;;
  ;;  Calibration checks
  ;;--------------------------------------------------------------------------
  calib_sources = ['uranus', 'mwc349', 'crl2688', 'ngc7027']
  calib_sources = ['uranus', 'neptune', 'mwc349']
  
  do_data_analysis = 0

;;===========================================================================
;;===========================================================================
;;
;;          DATA ANALYSIS
;;
;;===========================================================================
;;===========================================================================
  if do_data_analysis gt 0 then begin

     
     nno = n_elements(noskydip_runs)
     run_to_analyse = intarr(nruns)+1
     for i=0, nno-1 do begin
        w=where(list_of_runs eq noskydip_runs[i], nn)
        if nn gt 0 then  run_to_analyse[w] = 0
     endfor

     wok = where(run_to_analyse gt 0, nok)
     for ii = 0, nok-1 do begin

        irun = wok[ii]
        runname = list_of_runs[irun]
        print,''
        print,'------------------------------------------'
        print,'   ', strupcase(runname)
        print,'------------------------------------------'
        
        ;; calibrators
        get_calibration_scan_list, runname, scan_list, source_list=calib_sources, outlier_scan_list=outlier_scan_list
        
        ;; nk analysis using baseline parameters
        kidpar_file = list_of_kidpars[irun]
        if (n_elements(scan_list) gt 0 and strlen(scan_list[0]) gt 1) then begin
           print,kidpar_file
           launch_baseline_nk_batch, runname, kidpar_file, label='', force_scan_list = scan_list, relaunch=1
           help, scan_list
           print, scan_list
        endif
     endfor

     stop
  endif



;;===========================================================================
;;===========================================================================
;;
;;          CALIBRATION FACTORS
;;
;;===========================================================================
;;===========================================================================

;; calibration per cryoruns
;;==============================================================
run_index = uniq(list_of_cryoruns, sort(list_of_cryoruns))
list_of_cryoruns_uniq = list_of_cryoruns[run_index]
list_of_kidpars = list_of_kidpars[run_index]
ncryoruns = n_elements(list_of_cryoruns_uniq)

calibration = create_struct( "nika2run", strarr(2), $
                             "cryorun", 22, $
                             "kidpar_ref", '', $
                             "detector_ref", 0, $
                             "skydip_ok", 0B, $
                             "problem", 0B, $
                             "baseline_selection", 0B, $
                             "uranus_ntot", 10, $
                             "uranus_nsel", 5, $
                             "neptune_ntot", 10, $
                             "neptune_nsel", 5, $
                             "mwc349_ntot", 10, $
                             "mwc349_nsel", 5, $
                             "abs_calib_factors", dblarr(4))

calibration = replicate(calibration, ncryoruns)
for irun = 0, ncryoruns-1 do begin
   cryorun = list_of_cryoruns_uniq[irun]
   calibration[irun].cryorun = cryorun
   calibration[irun].kidpar_ref = list_of_kidpars[irun]
   w=where(list_of_cryoruns eq cryorun, n)
   calibration[irun].nika2run = list_of_runs[w]
endfor

calibration.skydip_ok = 1
noskydip_runs = [48, 51, 52]
nno = n_elements(noskydip_runs)
calibration.skydip_ok = 1
print, ''
print, 'Kidpar checks: '
for irun = 0, ncryoruns-1 do print, 'cryo run'+strtrim(calibration[irun].cryorun,2), ', ', file_basename(calibration[irun].kidpar_ref)
for i=0, nno-1 do begin
   w=where(calibration.cryorun eq noskydip_runs[i], nn)
   if nn gt 0 then calibration[w].skydip_ok = 0
endfor


;;________________________________________________________________
;;
;; create result table
;;________________________________________________________________
;;________________________________________________________________

flux_1mm     = 0.
flux_a2      = 0.
flux_a1      = 0.
flux_a3      = 0.
err_flux_1mm = 0.
err_flux_a2  = 0.
err_flux_a1  = 0.
err_flux_a3  = 0.
tau_1mm      = 0.0d0
tau_a2       = 0.0d0
tau_a1       = 0.0d0
tau_a3       = 0.0d0
fwhm_1mm     = 0.
fwhm_a2      = 0.
fwhm_a1      = 0.
fwhm_a3      = 0.
elev         = 0.
source       = ''
day          = ''
cryorunid    = ''
ut           = ''
ut_float     = 0.
scan_list    = ''
mjd          = 0.0d0
index_select = -1

th_flux_1mm  = 0.0d0
th_flux_a2   = 0.0d0
th_flux_a1   = 0.0d0
th_flux_a3   = 0.0d0

nsource = n_elements(calib_sources)

wok = where(calibration.skydip_ok gt 0, nruns)
for ii = 0, nruns-1 do begin
   irun = wok[ii]
   runname = calibration[irun].nika2run
   if strcmp(runname[1], '') gt 0 then runname = runname[0]
   print,''
   print,'------------------------------------------'
   print,'   ', strupcase(runname)
   print,'------------------------------------------'
   
   ;; calibrators
   get_calibration_scan_list, runname, scan_list, source_list=calib_sources, outlier_scan_list=outlier_scan_list
  
   outdir = getenv('NIKA_PLOT_DIR')+'/'+runname+'/Calibrators/'
   get_all_scan_result_file, runname, allresult_file, outputdir = outdir, ecrase_file=0

   print, ''
   print,'READING RESULT FILE: '
   print, allresult_file
   ;;
   ;;  restore result tables
   ;;____________________________________________________________
   restore, allresult_file, /v
   ;; allscan_info

   ;; select scans for the source
   ;;____________________________________________________________
   wsource = -1
   for isou = 0, nsource-1 do begin
      wtokeep = where( strupcase(allscan_info.object) eq strupcase(calib_sources[isou]), nkeep)
      if nkeep gt 0 then wsource = [wsource, wtokeep]
   endfor
   if n_elements(wsource) gt 1 then wsource = wsource[1:*] else begin
      print, 'no scan for the sources'
      stop
   endelse
   print, 'nb of found scan of the sources = ', n_elements(wsource)
   allscan_info = allscan_info[wsource]
   scan_list_ori = allscan_info.scan

   ;; ABSOLUTE CALIBRATION
   get_calibration_info, allscan_info, wselect, calibration_irun

   nscans = n_elements(allscan_info)
   scan_list_run = allscan_info.scan
   
   mask = intarr(nscans)
   mask[wselect] = 1
         
   th_flux_1mm_run = dblarr(nscans)
   th_flux_a2_run  = dblarr(nscans)
   th_flux_a1_run  = dblarr(nscans)
   th_flux_a3_run  = dblarr(nscans)
   
   w = where(strupcase(allscan_info.object) eq 'URANUS', ntot) 
   if ntot gt 0 then for ui=0, ntot-1 do begin
      i=w[ui]
      nk_scan2run, scan_list_run[i], run
      th_flux_1mm_run[i]     = !nika.flux_uranus[0]
      th_flux_a2_run[i]      = !nika.flux_uranus[1]
      th_flux_a1_run[i]      = !nika.flux_uranus[0]
      th_flux_a3_run[i]      = !nika.flux_uranus[0]
   endfor
   w = where(strupcase(allscan_info.object) eq 'NEPTUNE', ntot) 
   if ntot gt 0 then for ui=0, ntot-1 do begin
      i = w[ui]
      nk_scan2run, scan_list_run[i], run
      th_flux_1mm_run[i]     = !nika.flux_neptune[0]
      th_flux_a2_run[i]      = !nika.flux_neptune[1]
      th_flux_a1_run[i]      = !nika.flux_neptune[0]
      th_flux_a3_run[i]      = !nika.flux_neptune[0]
   endfor


   calibration[irun] = calibration_irun
   ;;
   ;; add in tables
   ;;____________________________________________________________
   scan_list    = [scan_list, allscan_info.scan]
   
   flux_1mm     = [flux_1mm, allscan_info.result_flux_i_1mm]
   flux_a2      = [flux_a2, allscan_info.result_flux_i2]
   flux_a1      = [flux_a1, allscan_info.result_flux_i1]
   flux_a3      = [flux_a3, allscan_info.result_flux_i3]
   err_flux_1mm = [err_flux_1mm, allscan_info.result_err_flux_i_1mm]
   err_flux_a2  = [err_flux_a2, allscan_info.result_err_flux_i2]
   err_flux_a1  = [err_flux_a1, allscan_info.result_err_flux_i1]
   err_flux_a3  = [err_flux_a3, allscan_info.result_err_flux_i3]
   ;;
   fwhm_1mm     = [fwhm_1mm, allscan_info.result_fwhm_1mm]
   fwhm_a2      = [fwhm_a2, allscan_info.result_fwhm_2]
   fwhm_a1      = [fwhm_a1, allscan_info.result_fwhm_1]
   fwhm_a3      = [fwhm_a3, allscan_info.result_fwhm_3]
   ;;
   tau_1mm      = [tau_1mm, allscan_info.result_tau_1mm]
   tau_a2       = [tau_a2, allscan_info.result_tau_2mm]
   tau_a1       = [tau_a1, allscan_info.result_tau_1]
   tau_a3       = [tau_a3, allscan_info.result_tau_3]
   ;;
   elev         = [elev, allscan_info.result_elevation_deg*!dtor]
   source       = [source, allscan_info.object]
   day          = [day, allscan_info.day]
   cryorunid    = [cryorunid, replicate(calibration[irun].cryorun, n_elements(allscan_info.day))]
   ut           = [ut, strmid(allscan_info.ut, 0, 5)]
   mjd          = [mjd, allscan_info.mjd]
   index_select = [index_select, mask]
   
   ;;
   th_flux_1mm  = [th_flux_1mm, th_flux_1mm_run]
   th_flux_a2   = [th_flux_a2, th_flux_a2_run]
   th_flux_a1   = [th_flux_a1, th_flux_a1_run]
   th_flux_a3   = [th_flux_a3, th_flux_a3_run]
   ;;
   
endfor


;; discard the placeholder first element of each tables
flux_1mm     = flux_1mm[1:*]
flux_a2      = flux_a2[1:*]
flux_a1      = flux_a1[1:*]
flux_a3      = flux_a3[1:*]
err_flux_1mm = err_flux_1mm[1:*]
err_flux_a2  = err_flux_a2[1:*]
err_flux_a1  = err_flux_a1[1:*]
err_flux_a3  = err_flux_a3[1:*]
;;
fwhm_1mm     = fwhm_1mm[1:*]
fwhm_a2      = fwhm_a2[1:*]
fwhm_a1      = fwhm_a1[1:*]
fwhm_a3      = fwhm_a3[1:*]
;;
tau_1mm      = tau_1mm[1:*]
tau_a2       = tau_a2[1:*]
tau_a1       = tau_a1[1:*]
tau_a3       = tau_a3[1:*]
;;
elev         = elev[1:*]
source       = source[1:*]
day          = day[1:*]
cryorunid    = cryorunid[1:*]
ut           = ut[1:*]
mjd          = mjd[1:*]
index_select = index_select[1:*]

scan_list    = scan_list[1:*]
;;
th_flux_1mm  = th_flux_1mm[1:*]
th_flux_a2   = th_flux_a2[1:*]
th_flux_a1   = th_flux_a1[1:*]
th_flux_a3   = th_flux_a3[1:*]


;; calculate ut_float and get flux expectations
nscans      = n_elements(day)
ut_float    = fltarr(nscans)
for i=0, nscans-1 do begin
   ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
endfor
  
;; MWC349
;;------------------------------
wsou = where(strupcase(source) eq 'MWC349', nscan_sou)
if nscan_sou gt 0 then begin
     lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
     nu = !const.c/(lambda*1e-3)/1.0d9
     th_flux           = 1.16d0*(nu/100.0)^0.60
     ;; assuming indep param
     err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)
     th_flux_1mm[wsou]     = th_flux[0]
     th_flux_a2[wsou]      = th_flux[1]
     th_flux_a1[wsou]      = th_flux[0]
     th_flux_a3[wsou]      = th_flux[2]
  endif
  
  ;; CRL2688
  ;;------------------------------
  wsou = where(strupcase(source) eq 'CRL2688', nscan_sou)
  if nscan_sou gt 0 then begin
     ;;th_flux           = [2.91, 0.76]
     th_flux           = [2.51, 0.54] ;; JFL
     alpha = 2.44
     ;; Dempsey 2013
     flux_scuba2 = [5.64, 24.9] ;; Jy.beam-1
     lam_scuba2  = [850., 450.]*1.0d-6
     nu_scuba2   = !const.c/(lam_scuba2)/1.0d9
     th_flux_1mm_mbb = flux_scuba2[0] * (nu[0]/nu_scuba2[0])^(0.4)*$
                       black_body(nu[0],210.)/black_body(nu_scuba2[0],210.)
     th_flux_2mm_mbb = flux_scuba2[0] * (nu[1]/nu_scuba2[0])^(0.4)*$
                       black_body(nu[1], 210.)/black_body(nu_scuba2[0],210.)
     ;; 2.71, 0.72
     
     th_flux_1mm_alpha = flux_scuba2 * (nu[0]/nu_scuba2)^(2.44)    ;; 2.6801162   2.5068608
     th_flux_2mm_alpha = flux_scuba2 * (nu[1]/nu_scuba2)^(2.44)    ;; 0.70029542  0.65502500
     ;;
     th_flux_1mm[wsou]     = th_flux[0]
     th_flux_a2[wsou]      = th_flux[1]
     th_flux_a1[wsou]      = th_flux[0]
     th_flux_a3[wsou]      = th_flux[0]
  endif
  
  ;; NGC7027
  ;;------------------------------
  wsou = where(strupcase(source) eq 'NGC7027', nscan_sou)
  if nscan_sou gt 0 then begin
     th_flux           = [3.46, 4.26]
     th_flux_1mm[wsou]     = th_flux[0]
     th_flux_a2[wsou]      = th_flux[1]
     th_flux_a1[wsou]      = th_flux[0]
     th_flux_a3[wsou]      = th_flux[0]
  endif
  

  ;get_lun, lun
  ;openw, lun, getenv('HOME')+'/NIKA/Plots/NIKA2_calibration_factors.txt'
  ;printf, lun, ' runs  A1 factors  A2 factors  A3 factors  A1 and A3 factors '
  ;for irun = 0, nruns-1 do begin
  ;   printf, lun, list_of_runs(irun), calibration[irun].abs_calib_factors
  ;endfor
  ;close, lun

  nruns = n_elements(calibration)
  print, 'NIKA2run ', ' Cryorun ', ' Opacity_done ', '  reference kidpar  ', '  reference KID  ', ' Baseline selection ', ' # Uranus scans ', ' # Neptune scans '
  for i = 0, nruns-1 do begin
     print, (calibration[i].nika2run)(uniq(calibration[i].nika2run)), ' ', $
            strtrim(calibration[i].cryorun, 2), ' ', $
            calibration[i].skydip_ok, '     ', $
            file_basename(calibration[i].kidpar_ref), ' ', $
            strtrim(calibration[i].detector_ref,2), ' ', $
            calibration[i].baseline_selection, ' ',$
            strtrim(calibration[i].uranus_nsel, 2), '/',strtrim(calibration[i].uranus_ntot, 2),' ',$
            strtrim(calibration[i].neptune_nsel, 2), '/',strtrim(calibration[i].neptune_ntot, 2)        
  endfor

 stop 

  

;;===========================================================================
;;===========================================================================
;;
;;          PLOTS
;;
;;===========================================================================

;; plot aspect
;;----------------------------------------------------------------
  
  ;; window size
  wxsize = 1000.
  wysize = 500.
  ;; plot size in files
  pxsize = 20.
  pysize = 10.
  ;; charsize
  charsize  = 1.1
  if keyword_set(ps) then charthick = 3.0 else charthick = 1.0
  if keyword_set(ps) then mythick   = 3.0 else mythick = 1.0
  mysymsize   = 0.8
  
  
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14
  
  
  
  ut_col = [10, 35, 50, 65, 80, 95, 115, 118, 140, 170, 188, 225, 240, 20, 45]
  
  wu0 = where(strupcase(source) eq 'URANUS' or strupcase(source) eq 'NEPTUNE', nu)
  index = indgen(nu)
  wok = where(calibration.skydip_ok gt 0, nruns)
  deltax = nu/nruns
  flux_ratio_1mm = flux_1mm[wu0]/th_flux_1mm[wu0]
  flux_ratio_a1  = flux_a1[wu0]/th_flux_a1[wu0]
  flux_ratio_a2  = flux_a2[wu0]/th_flux_a2[wu0]
  flux_ratio_a3  = flux_a3[wu0]/th_flux_a3[wu0]

  dir  = getenv('HOME')+'/NIKA/Plots/'
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize
  outfile = dir+'monitoring_primary_flux_ratio_1mm'
  outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
  
  plot, index, flux_ratio_1mm,/xs, yr=[0.1, 1.9], $
        xr=[-1, nu+5], $
        xtitle='index', ytitle='Primary measured-to-expected flux', /ys, /nodata
  oplot, [-1, nu+5], [1, 1], col=0
  first_index_run = lonarr(nruns)
  for ui = 0, nruns-1 do begin
     u = wok[ui]
     print, calibration[u].cryorun,': ',calibration[u].nika2run 
     w = where(cryorunid[wu0] eq calibration[u].cryorun, nn)
     if nn gt 0 then oplot, index[w], flux_ratio_1mm[w], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[ui], symsize=mysymsize
     first_index_run[ui] = index[w[0]]
     if nn gt 0 then xyouts, index[w[0]], 0.2, (calibration[u].nika2run)[0], col=ut_col[ui], orientation=45
     w = where(cryorunid[wu0] eq calibration[u].cryorun and index_select[wu0] gt 0, nn)
     if nn gt 0 then oplot, index[w], flux_ratio_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[ui], symsize=mysymsize
  endfor
  ;; Tick the calibration using the Baseline scan selection
  w = where(calibration[wok].baseline_selection gt 0, nn)
  if nn gt 0 then oplot, first_index_run[w]+10, (fltarr(nn)+0.4), psym=cgsymcat('FILLEDSTAR'), col=ut_col[12] 
  
  ;; Separate the campaigns included in the Calib paper and the following ones
  w=where(cryorunid[wu0] eq 27, n)
  oplot, [index[w[n-1]],index[w[n-1]] ], [0.1, 1.9], col=0, linestyle=2
  
  legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
               pos=[10, 1.7]
  legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
               pos=[10, 1.5]
  w=where(cryorunid[wu0] eq 53, n) ;; N2R41
  xyouts, index[w[0]], 1.7, '1mm', col=0
  outplot, /close
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize
  outfile = dir+'monitoring_primary_flux_ratio_2mm'
  outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
  plot, index, flux_ratio_a2,/xs, yr=[0.1, 1.9], $
        xr=[-1, nu+5], $
        xtitle='index', ytitle='Primary measured-to-expected flux', /ys, /nodata
  oplot, [-1, nu+5], [1, 1], col=0
  for ui = 0, nruns-1 do begin
     u=wok[ui]
     w = where(cryorunid[wu0] eq calibration[u].cryorun, nn)
     if nn gt 0 then oplot, index[w], flux_ratio_a2[w], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[ui], symsize=mysymsize
     if nn gt 0 then xyouts, index[w[0]], 0.2, (calibration[u].nika2run)[0], col=ut_col[ui], orientation=45
     w = where(cryorunid[wu0] eq calibration[u].cryorun and index_select[wu0] gt 0, nn)
     if nn gt 0 then oplot, index[w], flux_ratio_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[ui], symsize=mysymsize
  endfor
  w=where(cryorunid[wu0] eq 27, n) ;; N2R14
  oplot, [index[w[n-1]],index[w[n-1]] ], [0.1, 1.9], col=0, linestyle=2
  
  ;; Tick the calibration using the Baseline scan selection
  w = where(calibration[wok].baseline_selection gt 0, nn)
  if nn gt 0 then oplot, first_index_run[w]+10, (fltarr(nn)+0.4), psym=cgsymcat('FILLEDSTAR'), col=ut_col[12] 
  
  legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
               pos=[10, 1.7]
  legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
               pos=[10, 1.5]
  w=where(cryorunid[wu0] eq 53, n) ;; N2R41
  xyouts, index[w[0]], 1.7, '2mm', col=0
  outplot, /close
  
  stop

  
end
