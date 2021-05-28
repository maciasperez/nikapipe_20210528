;
;
;   Cross-checks of Absolute calibration
;
;   LP, April, 2018
;
;____________________________________________________________________

pro validate_calibration_reference_quasar, runname, input_kidpar_file, $
   output_dir=output_dir, showplot=showplot, png=png, $
   opa_version_name=opa_version_name, $
   nostop=nostop, $
   test_version_name=test_version_name, $
   output_allinfo_file = output_allinfo_file, $
   outlier_scan_list = outlier_scan_list
  


  quasar = ['3C84', '3C273', '3C279', '3C345', '0316+413', '2251+158']
  ;;quasar = ['3C273']
  source = 'quasar'
  
  
  if not(keyword_set(output_dir)) then $
     output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry'
  
  if file_test(output_dir, /directory) gt 1 then spawn, "mkdir -p "+output_dir
  
  if keyword_set(nostop) then nostop=1 else nostop = 0
  
  nickname = runname
  if keyword_set(opa_version_name) then nickname = nickname+opa_version_name
  if keyword_set(test_version_name) then nickname = nickname+test_version_name
  ;;if keyword_set(use_hybrid_opacity) then nickname = nickname+'_hybrid'
  
  opa_suf = ''
  ;;if keyword_set(hybrid_opacity_after_reduction) then opa_suf = '_hybrid_v0'
  ;;if keyword_set(opacity_from_tau225) then opa_suf = '_use_tau225_v0'

  cal_suf = ''
  cal_suf = '_calpera'

  ;;if keyword_set(delta_fwhm) then delta_fwhm=delta_fwhm else delta_fwhm=0.
  
  outlier_list = ''
  if keyword_set(outlier_scan_list) then outlier_list = outlier_scan_list
  
  
  
;; REFERENCE ANALYSIS PARAMS
;;------------------------------------------------------------------------------
  compute           = 1
  reset             = 0         ; 1 to reanalysis all the scans
  
  ;; PARAMS
  ;; No telescope elevation-gain correction 
  do_tel_gain_corr  = 0 ;; NIKA2 telescope elevation-gain correction (if photocorr=0)
  
  ;; cut in elevation
  elevation_min     = 0.0d0
  
  method = 'common_mode_one_block'
  decor_cm_dmin     =  60.0d0 ;; 80.0d0 ;; 40.0d0
  
  opacity_correction = 4
  
  
  ;; PHOTOMETRIC CORRECTION
  ;; SANS CORRECTION PHOTOMETRIQUE
  to_use_photocorr = 0
  photocorr        = 0
 
  
  ;; Scan selection
  
  restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_"+strupcase(runname)+"_v00.save"
  
  dz1 = abs(scan.focusz_mm - shift(scan.focusz_mm, -1)) ; 0.8
  dz2 = scan.focusz_mm - shift(scan.focusz_mm, -2)      ; 0.4
  dz3 = scan.focusz_mm - shift(scan.focusz_mm, -3)      ; -0.4
  dz4 = scan.focusz_mm - shift(scan.focusz_mm, -4)      ; -0.8
  
  dx1 = abs(scan.focusx_mm - shift(scan.focusx_mm, -1)) ; 1.4
  dx2 = scan.focusx_mm - shift(scan.focusx_mm, -2)      ; 0.7
  dx3 = scan.focusx_mm - shift(scan.focusx_mm, -3)      ; -0.7
  dx4 = scan.focusx_mm - shift(scan.focusx_mm, -4)      ; -1.4
  
  dy1 = abs(scan.focusy_mm - shift(scan.focusy_mm, -1)) ; 1.4
  dy2 = scan.focusy_mm - shift(scan.focusy_mm, -2)      ; 0.7
  dy3 = scan.focusy_mm - shift(scan.focusy_mm, -3)      ; -0.7
  dy4 = scan.focusy_mm - shift(scan.focusy_mm, -4)      ;-1.4
  
  wfocus = where(strupcase(scan.obstype) eq 'ONTHEFLYMAP' and $
                 (dz1 gt 0.3 or dx1 gt 0.5 or dy1 gt 0.5)   $
                 , nscans, compl=wok, ncompl=nok)
  
  wtokeep = where((strupcase(scan[wok].obstype) eq 'ONTHEFLYMAP' or strupcase(scan[wok].obstype) eq 'POINTING') $
                  and scan[wok].n_obs gt 4, nkeep)

  ;wtokeep = where(strupcase(scan[wok].obstype) eq 'POINTING' $
  ;                and scan[wok].n_obs gt 4, nkeep)
  
  
  scan_str = scan[wok[wtokeep]]
  
  nquasar = n_elements(quasar)
  wquasar = 0
  for iq=0, nquasar-1 do begin
     wq = where(strupcase(scan_str.object) eq quasar[iq], nn)
     if nn gt 0 then wquasar = [wquasar, wq]
  endfor
  wquasar = wquasar[1:*]
  scan_str = scan_str[wquasar]
  scan_list = scan_str.day+"s"+strtrim( scan_str.scannum,2)

  
  all_day       = scan.day
  all_day_list  = all_day[uniq(all_day, sort(all_day))]
  ndays         = n_elements(all_day_list)
  
  print, scan_list
  
  ;; 3C273 3C279 3C345 3C84
  ;;w=where(strupcase(scan.obstype) eq 'ONTHEFLYMAP' and scan.n_obs gt 4 and scan.object eq '3C84' and strmid(scan.comment, 0, 4) eq 'none', n)
  ;;for i=0, n-1 do print, scan[w[i]].tiptau225ghz, ', ', scan[w[i]].date, ', ', scan[w[i]].n_obs

  
;; remove outliers if any
;; define outlier_list and relaunch
;;-------------------------------------------------------------
if (n_elements(outlier_list) gt 0 and outlier_list[0] ne '') then begin
   scan_list_ori = scan_list
   remove_scan_from_list, scan_list_ori, outlier_list, scan_list, out_index=index_to_keep
   scan_str = scan_str[index_to_keep]
endif

nscans = n_elements(scan_list)

nk_scan2run, scan_list[0]
  
;; Make maps of all observations
reset=0
if compute eq 1 then begin
   
   if reset gt 0 then begin
      scan_list_to_analyse = scan_list
      nscan_to_analyse = nscans
   endif else begin
      scan_list_to_analyse = ''
      for isc = 0, nscans-1 do begin
         file = output_dir+'/Quasar_photometry_'+nickname+'/v_1/'+scan_list[isc]+'/results.save'
         if file_test(file) lt 1 then scan_list_to_analyse = [ scan_list_to_analyse, scan_list[isc]]
      endfor
      nscan_to_analyse = n_elements(scan_list_to_analyse)-1
      if nscan_to_analyse gt 0 then scan_list_to_analyse = scan_list_to_analyse[1:*] 
   endelse
   if nscan_to_analyse gt 0 then begin 
      ncpu_max = 20 ;24
      optimize_nproc, nscan_to_analyse, ncpu_max, nproc
      nproc = min([nscan_to_analyse, ncpu_max])
      
      reset = 1
      project_dir = output_dir+'/Quasar_photometry_'+nickname
      if file_test(project_dir, /directory) lt 1 then spawn, "mkdir -p "+project_dir
      split_for, 0, nscan_to_analyse-1, $
                 commands=['obs_nk_ps, i, scan_list_to_analyse, project_dir, '+$
                           'method, source, input_kidpar_file=input_kidpar_file, '+$
                           'reset=reset, ' +$
                           'do_tel_gain_corr=do_tel_gain_corr, ' +$
                           'decor_cm_dmin=decor_cm_dmin, ' +$
                           'opacity_correction=opacity_correction'], $
                 nsplit=nproc, $
                 varnames=['scan_list_to_analyse', 'project_dir', 'method', 'source', 'input_kidpar_file', $
                           'reset', 'do_tel_gain_corr', 'decor_cm_dmin', 'opacity_correction']
   endif
endif

sorted_index = sort(scan_list) 
scan_list = scan_list[ sorted_index]
scan_str = scan_str[sorted_index]
nscans = n_elements(scan_list)

;file = 'MWC349_scanlist_all.save'
;save, scan_list, filename=file
;stop


;; check if all scans were indeed processed
run = !nika.run
project_dir = output_dir+"/Quasar_photometry_"+nickname

flux         = fltarr(nscans, 4)
err_flux     = fltarr(nscans, 4)
ap_flux      = fltarr(nscans, 4)
err_ap_flux  = fltarr(nscans, 4)
peak         = fltarr(nscans, 4)
tau_1mm      = fltarr(nscans)
tau_2mm      = fltarr(nscans)
tau1         = dblarr(nscans)
tau2         = dblarr(nscans)
tau2_hybrid  = dblarr(nscans)
tau3         = dblarr(nscans)
tau225       = dblarr(nscans)
fwhm         = fltarr(nscans,4)
nsub         = intarr(nscans)
elev         = dblarr(nscans)
ut           = strarr(nscans)
ut_float     = fltarr(nscans)
fwhm_point_4 = fltarr(nscans,4)
fwhm_point_2 = fltarr(nscans,4)

if photocorr gt 0 then begin
;; Xavier's Log relying on 4''-reso maps
   correction_file = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_corr_'+runname+'_v1.csv'
   pcorr4ok = 0
   if file_test(correction_file) then begin
      nk_read_csv_3, correction_file, pcorr
      
      ns = n_elements(pcorr.(0))
      index = indgen(ns)
      ;;
      wundef = where(pcorr.fwhm1 lt 0., nundef, compl=wdef, ncompl=ndef)
      fwhm1_interp = pcorr.fwhm1
      if nundef gt 0 then fwhm1_interp[wundef] = interpol(fwhm1_interp[wdef], index[wdef], index[wundef] )
      if nundef gt 0 then pcorr[wundef].fwhm1 = !values.f_nan
      fwhm1_lkv = last_known_value(pcorr.fwhm1)
      ;;
      wundef = where(pcorr.fwhm2 lt 0., nundef, compl=wdef, ncompl=ndef)
      fwhm2_interp = pcorr.fwhm2
      if nundef gt 0 then fwhm2_interp[wundef] = interpol(fwhm2_interp[wdef], index[wdef], index[wundef] )
      if nundef gt 0 then pcorr[wundef].fwhm2 = !values.f_nan
      fwhm2_lkv = last_known_value(pcorr.fwhm2)
      
      
      ;;pcorr.fwhm1 = fwhm1_lkv
      ;;pcorr.fwhm2 = fwhm2_lkv
      pcorr.fwhm1 = fwhm1_interp
      pcorr.fwhm2 = fwhm2_interp
      
      pcorr4ok = 1
   endif else print, "Pointing-scan-based correction file not found"
   
;; Juan's Log relying on 2''-reso maps
   correction_file = !nika.pipeline_dir+'/Datamanage/Logbook/All_pointings_'+strupcase(runname)+'_baseline.save'
   pcorr2ok = 0
   if file_test(correction_file) then begin
      
      restore, correction_file
      ;; table of 'info' structures
      
      ;; treat NaN
      wok = where(finite(allpoint_info.result_fwhm_1) gt 0 and $
                  finite(allpoint_info.result_fwhm_2) gt 0 and $
                  finite(allpoint_info.result_fwhm_3) gt 0, nok)     
      allpoint_info = allpoint_info[wok]
      
      ;; remove pointing toward extended sources
      wext = where(strlowcase(allpoint_info.object) eq 'ngc7027', next, compl=wok, ncompl=nok)
      allpoint_info = allpoint_info[wok]
      
      ;;reordered allpoint_info
      pday = allpoint_info.day
      pday_list = pday[uniq(pday, sort(pday))]
      npdays = n_elements(pday_list)
      for ip = 0, npdays-1 do begin
         w = where(pday eq pday_list[ip], n)
         allpoint_info[w] = allpoint_info[w[sort((allpoint_info.scan_num)[w])]]
      endfor
      
      pointing_list = strtrim(string(allpoint_info.day, format='(i8)'), 2)+'s'+$
                      strtrim(string(allpoint_info.scan_num, format='(i8)'), 2)
      
      ;; outliers :
      ;; mettre une fenetre glissante pour virer les outliers ?
      pointing_outliers = ['20170225s224']
      remove_scan_from_list, pointing_list, pointing_outliers, olist, out_index = oind
      pointing_list = pointing_list[oind]
      allpoint_info = allpoint_info[oind]
      
      ;;
      np_scans       = n_elements(pointing_list)
      ut_point = fltarr(np_scans)
      ut_str   = strmid(allpoint_info.ut, 0, 5)
      for i = 0, np_scans-1 do ut_point[i]  = float((STRSPLIT(ut_str[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut_str[i], ':', /EXTRACT))[1])/60.
      
      pcorr2ok = 1
   endif else print, "Pointing-scan-based correction file from Juan's analysis not found"
endif


;; init info_all
dir = project_dir+"/v_1/"
spawn, 'ls '+dir+'*/results.save', files
restore,  files[0]
allscan_info = replicate(info1, nscans)

for i =0, nscans-1 do begin
   dir = project_dir+"/v_1/"+strtrim(scan_list[i], 2)
   if file_test(dir+"/results.save") then begin
      restore,  dir+"/results.save"
      
      if info1.polar eq 1 then print, scan_list[i]+" is polarized !"

      allscan_info[i] = info1
      
      fwhm[i,0] = info1.result_fwhm_1
      fwhm[i,1] = info1.result_fwhm_2
      fwhm[i,2] = info1.result_fwhm_3
      fwhm[i,3] = info1.result_fwhm_1mm
      
      flux[i, 0] = info1.result_flux_i1
      flux[i, 1] = info1.result_flux_i2
      flux[i, 2] = info1.result_flux_i3
      flux[i, 3] = info1.result_flux_i_1mm
      
      peak[i, 0] = info1.result_peak_1
      peak[i, 1] = info1.result_peak_2
      peak[i, 2] = info1.result_peak_3
      peak[i, 3] = info1.result_peak_1mm
      
      tau_1mm[ i] = info1.result_tau_1mm
      tau_2mm[ i] = info1.result_tau_2mm
      tau1[ i] = info1.result_tau_1
      tau2[ i] = info1.result_tau_2
      tau3[ i] = info1.result_tau_3
      
      err_flux[i, 0] = info1.result_err_flux_i1
      err_flux[i, 1] = info1.result_err_flux_i2
      err_flux[i, 2] = info1.result_err_flux_i3
      err_flux[i, 3] = info1.result_err_flux_i_1mm
      
      ap_flux[i, 0] = info1.result_aperture_photometry_i1
      ap_flux[i, 1] = info1.result_aperture_photometry_i2
      ap_flux[i, 2] = info1.result_aperture_photometry_i3
      ap_flux[i, 3] = info1.result_aperture_photometry_i_1mm
      
      err_ap_flux[i, 0] = info1.result_err_aperture_photometry_i1
      err_ap_flux[i, 1] = info1.result_err_aperture_photometry_i2
      err_ap_flux[i, 2] = info1.result_err_aperture_photometry_i3
      err_ap_flux[i, 3] = info1.result_err_aperture_photometry_i_1mm
      
      nsub[i]        = info1.nsubscans
      elev[i]        = info1.RESULT_ELEVATION_DEG
      ut[i]          = strmid(info1.ut, 0, 5)
      ut_float[i]    = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
      tau225[i]      = info1.TAU225
   endif
endfor

if photocorr gt 0 then begin
   if pcorr4ok gt 0 then begin
      
      all = strtrim(pcorr.day, 2)+'s'+strtrim(pcorr.scannum,2)
      my_match, all, scan_list, suba, subb
      
      fwhm_point_4[subb, 0] = pcorr[suba].fwhm1
      fwhm_point_4[subb, 1] = pcorr[suba].fwhm2
      fwhm_point_4[subb, 2] = pcorr[suba].fwhm1
      fwhm_point_4[subb, 3] = pcorr[suba].fwhm1
   endif
   
   if pcorr2ok gt 0 then begin
      
      first_val = [(allpoint_info.result_fwhm_1)[0], (allpoint_info.result_fwhm_2)[0], (allpoint_info.result_fwhm_3)[0], (allpoint_info.result_fwhm_1mm)[0]]
      time_index = findgen(ndays*1440.)/60.
      all_fwhm_interp = fltarr(ndays*1440., 4)
      
      time_point = fltarr(np_scans)
      time_otf   = fltarr(nscans)
      for id = 0., ndays-1. do begin
         wpoint = where(allpoint_info.day eq all_day_list[id], npoint)
         wotf   = where(info_all.day eq all_day_list[id], notf)
         ;; bug de minuit
         if npoint gt 1 and ut_point[wpoint[npoint-1]] lt 1.0d-1 then ut_point[wpoint[npoint-1]] = 24.0
         if notf gt 1 and ut_float[wotf[notf-1]] lt 1.0d-1 then ut_float[wotf[notf-1]] = 24.0 
         if npoint gt 0 then time_point[wpoint] = ut_point[wpoint]+24.0*id
         if notf gt 0 then time_otf[wotf] = ut_float[wotf]+24.0*id
      endfor
      
      indpoint = intarr(np_scans)
      for i=0, np_scans-1 do indpoint[i] = (where(time_point[i] gt time_index-0.01 and time_point[i] lt time_index+0.01, nindpoint))[0]
      
      ;; lissage
      p_med = fltarr(np_scans, 4)
      p_rms = fltarr(np_scans, 4)
      nf_tab = intarr(np_scans) 
      
      for i=0, np_scans-1 do begin
         fenetre = where(time_point gt time_point[i]-0.35 and time_point lt time_point[i]+0.35, nf)
         if nf ge 3 then begin
            p_med[i, 0] = median((allpoint_info.result_fwhm_1)[fenetre])
            p_med[i, 1] = median((allpoint_info.result_fwhm_2)[fenetre])
            p_med[i, 2] = median((allpoint_info.result_fwhm_3)[fenetre])
            p_med[i, 3] = median((allpoint_info.result_fwhm_1mm)[fenetre])
         endif else begin
            ;; broader fenetre
            fenetre = where(time_point gt time_point[i]-0.60 and time_point lt time_point[i]+0.60, nf)
            p_med[i, 0] = median((allpoint_info.result_fwhm_1)[fenetre])
            p_med[i, 1] = median((allpoint_info.result_fwhm_2)[fenetre])
            p_med[i, 2] = median((allpoint_info.result_fwhm_3)[fenetre])
            p_med[i, 3] = median((allpoint_info.result_fwhm_1mm)[fenetre])
         endelse
         
         if nf gt 1 then begin 
            p_rms[i, 0] = stddev((allpoint_info.result_fwhm_1)[fenetre])
            p_rms[i, 1] = stddev((allpoint_info.result_fwhm_2)[fenetre])
            p_rms[i, 2] = stddev((allpoint_info.result_fwhm_3)[fenetre])
            p_rms[i, 3] = stddev((allpoint_info.result_fwhm_1mm)[fenetre])
         endif
         nf_tab[i] = nf
      endfor

      ;; A1
      ;; wok1 = where((allpoint_info.result_fwhm_1) le p_med[*,0]+p_rms[*, 0] and $
      ;;             (allpoint_info.result_fwhm_1) ge p_med[*,0]-p_rms[*, 0], compl=wn1)
      ;; all_fwhm_interp[*, 0] = interpol( [first_val[0], (allpoint_info.result_fwhm_1)[wok1]],  $
      ;;                                   [0., time_index[indpoint[wok1]]], time_index)
      ;; A2
      ;; wok2 = where((allpoint_info.result_fwhm_2) lt p_med[*,1]+p_rms[*, 1] and $
      ;;             (allpoint_info.result_fwhm_2) ge p_med[*,1]-p_rms[*, 1])
      ;; all_fwhm_interp[*, 1] = interpol( [first_val[1], (allpoint_info.result_fwhm_2)[wok2]],  [0., time_index[indpoint[wok2]]], time_index)
      ;; A3
      ;; wok3 = where((allpoint_info.result_fwhm_3) lt p_med[*,2]+p_rms[*, 2] and $
      ;;             (allpoint_info.result_fwhm_3) ge p_med[*,2]-p_rms[*, 2])
      ;; all_fwhm_interp[*, 2] = interpol( [first_val[2], (allpoint_info.result_fwhm_3)[wok3]],  [0., time_index[indpoint[wok3]]], time_index)
      ;; 1mm
      ;; wokm = where((allpoint_info.result_fwhm_1mm) lt p_med[*,3]+p_rms[*, 3] and $
      ;;             (allpoint_info.result_fwhm_1mm) ge p_med[*,3]-p_rms[*, 3])
      ;; all_fwhm_interp[*, 3] = interpol( [first_val[3], (allpoint_info.result_fwhm_1mm)[wokm]],  [0., time_index[indpoint[wokm]]], time_index)
      
      ;; using the median
      for i=0, 3 do all_fwhm_interp[*, i] = interpol( [first_val[i], p_med[*, i], p_med[np_scans-1, i]  ],  $
                                                      [0., time_index[indpoint],  time_index[indpoint[np_scans-1]]+1 ] , time_index)
      
      
      indotf = intarr(nscans)
      for i=0, nscans-1 do indotf[i] = (where(time_otf[i] gt time_index-0.01 and time_otf[i] lt time_index+0.01, nindotf))[0]
      
      ;;fwhm_point_2[*, 0] = all_fwhm_interp[indotf, 0]
      fwhm_point_2[*, 1] = all_fwhm_interp[indotf, 1]
      ;;fwhm_point_2[*, 2] = all_fwhm_interp[indotf, 2]
      fwhm_point_2[*, 0] = all_fwhm_interp[indotf, 3]
      fwhm_point_2[*, 2] = all_fwhm_interp[indotf, 3]
      fwhm_point_2[*, 3] = all_fwhm_interp[indotf, 3]
      
      plot,  time_index, all_fwhm_interp[*, 0], yrange=[10., 20.] ;, xr=[100, 160]
      oplot, time_index, all_fwhm_interp[*, 3], col=200
      oplot, time_index[indpoint], (allpoint_info.result_fwhm_1), psym=8, col=250
      for i=0, ndays-1 do oplot, 24.*[i, i], [0., 100]
      oplot, time_index[indpoint], p_med[*, 0], col=50
      oplot, time_index[indpoint], p_med[*, 0]+p_rms[*, 0], col=50
      oplot, time_index[indpoint], p_med[*, 0]-p_rms[*, 0], col=50
      oplot, time_index[indotf], fwhm_point_2[*, 0], psym=8, col=80
      
      if nostop lt 1 then stop
      
      ;; plot,  time_index, all_fwhm_interp[*, 0], yrange=[10., 20.], xr=[80, 105]
      ;; oplot, time_index, all_fwhm_interp[*, 3], col=200
      ;; wu = where(strlowcase(allpoint_info.object) eq 'uranus', nu, compl=ws, ncompl=ns)
      ;; if nu gt 0 then oplot, time_index[indpoint[wu]], (allpoint_info[wu].result_fwhm_1), psym=8, col=250
      ;; if ns gt 0 then oplot, time_index[indpoint[ws]], (allpoint_info[ws].result_fwhm_1), psym=4, col=250
      ;; if nu gt 0 then oplot, time_index[indpoint[wu]], (allpoint_info[wu].result_fwhm_3), psym=8, col=200
      ;; if ns gt 0 then oplot, time_index[indpoint[ws]], (allpoint_info[ws].result_fwhm_3), psym=4, col=200
      ;; if ns gt 0 then oplot, time_index[indpoint[ws]], (allpoint_info[ws].result_fwhm_1mm), psym=4, col=150
      ;; if nu gt 0 then oplot, time_index[indpoint[wu]], (allpoint_info[wu].result_fwhm_1mm), psym=8, col=150
      ;; oplot, time_index[indotf], fwhm_point_2[*, 0], psym=8, col=80
      ;; for i=0, ndays-1 do oplot, 24.*[i, i], [0., 100]
      
      ;;if nostop lt 1 then stop
      
   endif
endif


if keyword_set(output_allinfo_file) then begin
   save, allscan_info, filename=output_dir+'/'+output_allinfo_file
endif


;; scan selection before testing
;;------------------------------------------------------------------

fwhm_sigma = dblarr(3)
fwhm_avg   = dblarr(3)
for j=0, 2 do begin
   w=where(fwhm[*,j] lt !nika.fwhm_array[j]*1.2 and fwhm[*,j] gt !nika.fwhm_array[j]*0.65, nok)
   if nok gt 0 then begin
      fwhm_sigma[j] = stddev( fwhm[w, j])
      fwhm_avg[j]   = avg(    fwhm[w, j])
   endif else print, "all scans have catastrophic fwhm!"
endfor

;; select the needed outputs
nscan_all  = nscans
wout       = 1
wlargebeam = 1 
wdaytime   = 1
whitau3    = 1
fwhm_max   = 1
baseline_scan_selection, allscan_info, wtokeep, $
                to_use_photocorr=to_use_photocorr, complement_index=wout, $
                beamok_index = beamok_index, largebeam_index = wlargebeam,$
                tauok_index = tauok_index, hightau_index=whitau3, $
                osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                fwhm_max = fwhm_max

if wlargebeam[0] ge 0 then nlargebeam = n_elements(wlargebeam) else nlargebeam=0  
if wdaytime[0] ge 0 then ndaytime = n_elements(wdaytime) else ndaytime=0
if whitau3[0] ge 0 then nhitau3 = n_elements(whitau3) else nhitau3=0
if wout[0] ge 0 then nout = n_elements(wout) else nout=0
if wtokeep[0] ge 0 then nscans = n_elements(wtokeep) else nscans=0

;; plot 
day_list = strmid(scan_list,0,8)


photocorr_suffixe= ''

wind, 1, 1, /free, /large
outplot, file='fwhm_'+strtrim(source,2)+'_'+strtrim(nickname,2)+photocorr_suffixe, png=png, ps=ps
!p.multi=[0,1,3]
index = dindgen(n_elements(flux[*, 0]))
for j=0, 2 do begin
   ymin = max( [!nika.fwhm_array[j] - 5.0, min(fwhm[*,j])] )*0.9
   ymax = min( [ !nika.fwhm_array[j] + 5.0, max(fwhm[*,j])] )*1.2
   plot, index, fwhm[*,j], xr=[-1, nscan_all], /xs, psym=-4, xtitle='scan index', ytitle='FWHM (arcsec)', $
         /ys, charsize=1.1, yr=[ymin, ymax], symsize=0.5
   if nlargebeam gt 0 then oplot, index[wlargebeam],   fwhm[wlargebeam,j], psym=7, col=250
   if ndaytime gt 0 then oplot, index[wdaytime], fwhm[wdaytime,j], psym=4, col=250
   if nhitau3 gt 0 then oplot, index[whitau3], fwhm[whitau3,j], psym=6, col=250
   
   if j eq 2 then   xyouts, index[wtokeep]-0.2, fltarr(nscans)+fwhm_avg[j], scan_list[wtokeep], charsi=0.7, orient=90
   ;;if photocorr gt 0 then if nwphot gt 0 then oplot, index[wphot], fwhm[wphot,j], psym=5, col=250
   if nout gt 0 and j eq 2 then  xyouts, index[wout]-0.2, fltarr(nout)+fwhm_avg[j], scan_list[wout], charsi=0.7, orient=90, col=250
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   oplot, [0,nscans+nout+1], index*0.+fwhm_avg[j], col=50, LINESTYLE = 5
   oplot, [0,nscans+nout+1], index*0.+fwhm_max[j], col=50
   oplot, index, fwhm_point_4[*,j], psym=8, col=80
   oplot, index, fwhm_point_2[*,j], psym=8, col=200
   legendastro, 'Array '+strtrim(j+1,2), box=0
   if j eq 0 then legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], textcol=[250, 250, 250], psym=[7, 4, 6], color=[250, 250, 250], box=0, pos=[n_elements(fwhm[*,j])-7, max(fwhm[*,j])*0.9]
endfor
!p.multi=0
outplot, /close

   
if nscans le 0 then begin
   print, "all scans have abberant FWHM...."
   print, "stop here and investigate"
   if nostop lt 1 then stop
endif else begin
   
;; apply the selection
   if nout gt 0 then begin
      print,''
      print,'============================================='
      black_list = scan_list[wout]
      print,'outlier_list =  [ $'
      for i=0, nout-2 do print,"'",black_list[i],"', $"
      print,"'",black_list[nout-1],"' ]"
      print,'============================================='
   endif
   
   scan_list_all = scan_list
   scan_list  = scan_list[wtokeep]
   scan_str   = scan_str[wtokeep]

   nscans = n_elements(scan_list)
   flux_all = flux
   err_flux_all = err_flux
   flux = dblarr(nscans,4)
   err_flux = dblarr(nscans,4)
   for i =0, 3 do flux[*, i]=flux_all[wtokeep, i]
   for i =0, 3 do err_flux[*, i]=err_flux_all[wtokeep, i]
   
   flux_1     = flux[*, 0]
   flux_2     = flux[*, 1]
   flux_3     = flux[*, 2]
   flux_1mm   = flux[*, 3]
   err_flux_1     = err_flux[*, 0]
   err_flux_2     = err_flux[*, 1]
   err_flux_3     = err_flux[*, 2]
   err_flux_1mm   = err_flux[*, 3]
   
   day_list = strmid(scan_list,0,8)
   
   
   
;; save scan list
   info_list = scan_str.day+"s"+strtrim( scan_str.scannum,2)
   my_match, info_list, scan_list, suba, subb
   wotf     = where(scan_str[suba].n_obs gt 10 and scan_str[suba].n_obs lt 99, notf)
   otf_list = ''
   if notf gt 0 then otf_list = scan_list[subb[wotf]]
   save, otf_list, filename=output_dir+'/Goodscans_'+strtrim(source,2)+'_'+runname+'.save'
;; 
   save, scan_list, filename=output_dir+'/Goodscans_'+strtrim(source,2)+'_'+runname+'_all.save'

   test_tau1 = tau1
   if  keyword_set(opacity_from_tau225) then test_tau1 = tau1_ori
   whi = where( test_tau1 gt 0.2, nhi, compl=wlo, ncompl=nlo)
   scan_list_hitau1 = scan_list[whi]
   scan_list_lotau1 = scan_list[wlo]
   save, scan_list_hitau1, filename=output_dir+'/Goodscans_'+strtrim(source,2)+'_'+runname+'_hightau1.save'
   save, scan_list_lotau1, filename=output_dir+'/Goodscans_'+strtrim(source,2)+'_'+runname+'_lowtau1.save'
   
   ;;stop

   
   if strupcase(source) eq 'MARS' then begin
      ;; average flux expectation (for plotting only)
      nday = n_elements(day_list)
      tab_th_flux = dblarr(nday, 3)
      for j=0, nday-1 do begin
         fill_nika_struct, '27', day=day_list[j]
         tab_th_flux[j, *] = !nika.flux_mars
         print, !nika.flux_mars
      endfor
      th_flux = mean(tab_th_flux, dimension=1) 
   endif

   
   
;; plot of the flux
;;--------------------------------------------------------------------
   print, ""
   print, "============================================================="
   print, "Baseline photometry"
   print, "============================================================="
   print, ""

   nscans = n_elements(scan_list)
   sigma  =  dblarr(nscans, 4)
   flux_avg = dblarr(nscans, 4)

   for iq=0, nquasar-1 do begin
      wq = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         for i=0, 3 do sigma[wq,i] = stddev(flux[wq, i])
         for i=0, 3 do flux_avg[wq,i] = mean(flux[wq, i])
      endif
      wq = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         for i=0, 3 do sigma[wq,i] = stddev(flux[wq, i])
         for i=0, 3 do flux_avg[wq,i] = mean(flux[wq, i])
      endif   
   endfor
   
   
   sigma_1   = sigma[*, 0]
   sigma_2   = sigma[*, 1]
   sigma_3   = sigma[*, 2]
   sigma_1mm = sigma[*, 3]
   flux_avg_1   = flux_avg[*, 0]
   flux_avg_2   = flux_avg[*, 1]
   flux_avg_3   = flux_avg[*, 2]
   flux_avg_1mm = flux_avg[*, 3]

   atmtrans_1 = exp(tau1[wtokeep]/sin(elev[wtokeep]*!dtor))
   wlow = where( atmtrans_1 lt median(atmtrans_1), nhalf, compl=whi)
   diff_1 = abs(mean(flux_1(whi))-mean(flux_1(wlow)))/sqrt(stddev(flux_1(whi))^2 + stddev(flux_1(wlo))^2)*sqrt(nhalf)
   atmtrans_2 = exp(tau2[wtokeep]/sin(elev[wtokeep]*!dtor))
   wlow = where( atmtrans_2 lt median(atmtrans_2),nhalf, compl=whi)
   diff_2 = abs(mean(flux_2(whi))-mean(flux_2(wlow)))/sqrt(stddev(flux_2(whi))^2 + stddev(flux_2(wlo))^2)*sqrt(nhalf)
   atmtrans_3 = exp(tau3[wtokeep]/sin(elev[wtokeep]*!dtor))
   wlow = where( atmtrans_3 lt median(atmtrans_3),nhalf, compl=whi)
   diff_3 = abs(mean(flux_3(whi))-mean(flux_3(wlow)))/sqrt(stddev(flux_3(whi))^2 + stddev(flux_3(wlo))^2)*sqrt(nhalf)
   atmtrans_1mm = exp(tau_1mm[wtokeep]/sin(elev[wtokeep]*!dtor))
   wlow = where( atmtrans_1mm lt median(atmtrans_1mm),nhalf, compl=whi)
   diff_1mm = abs(mean(flux_1mm(whi))-mean(flux_1mm(wlow)))/sqrt(stddev(flux_1mm(whi))^2 + stddev(flux_1mm(wlo))^2)*sqrt(nhalf)

   
   delvarx, yra    
   index = dindgen(n_elements(flux_1))
   
   fmt = "(F5.1)"
   wind, 1, 1, /free, /large
   outfile = project_dir+'/photometry_'+strtrim(source)+'_'+strtrim(nickname,2)+photocorr_suffixe
   outplot, file=outfile, png=png, ps=ps
   my_multiplot, 1, 4, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
   !x.charsize = 1e-10
   
   yra=[min(flux_avg_1)*0.7, max(flux_avg_1)*1.3]
   plot,       index, flux_1, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[0,*], yra=yra, /ys, title=file_basename(project_dir)
   oploterror, index, flux_1, err_flux_1, psym=8 
   oplot, index, flux_avg_1, col=70
   legendastro, ['Array 1'], box=0, pos=[-0.5, yra[1]*0.9]
   ;legendastro, ['sigma/avg: '+strtrim( string(sigma_1/flux_avg_1*100.0d0,format=fmt),2)+'%'], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=[min(flux_avg_3)*0.7, max(flux_avg_3)*1.3]
   plot,       index, flux_3, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[1,*], /noerase, yra=yra, /ys
   oploterror, index, flux_3, err_flux_3, psym=8
   oplot,index, flux_avg_3, col=70
   legendastro, ['Array 3'], box=0, pos=[-0.5, yra[1]*0.9]
   ;legendastro, ['sigma/avg: '+strtrim( string(sigma_3/flux_avg_3*100.0,format=fmt)+'%',2)], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=[min(flux_avg_2)*0.7, max(flux_avg_2)*1.3]
   plot,       index, flux_2, ytitle='Flux Jy',xr=[-1,nscans], /xs, position=pp1[2,*], /noerase, yra=yra, /ys
   oploterror, index, flux_2, err_flux_2, psym=8
   oplot, index, flux_avg_2, col=70
   xyouts, index, flux_2, strmid(scan_list,4, 12), charsi=0.7, orient=90
   legendastro, ['Array 2'], box=0, pos=[-0.5, yra[1]*0.9]
   ;legendastro, ['sigma/avg: '+strtrim( string(sigma_2/flux_avg_2*100.0,format=fmt),2)+'%'], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   
   plot, index, tau_1mm[wtokeep], xr=[-1,nscans],/xs, position=pp1[3,*], /noerase,/nodata
   oplot, index, tau_1mm[wtokeep], col=250
   oplot, index, tau_2mm[wtokeep], col=50
   legendastro, ['Tau 1mm', 'Tau 2mm'], col=[250, 50],box=0, pos=[-0.5, 0.1]
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   !x.charsize = 1
   myday = day_list[0]
   xyouts, 0.1, 0.01, strtrim(strmid(myday,6),2)
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
         xyouts, i+0.1, 0.01, strtrim(strmid(myday,6),2)
      endif
   endfor
   !p.multi = 0
   outplot, /close


   

   ;; correlation plots
   ;;----------------------------------------------

   index = dindgen(nscans)
   day_list = strmid(scan_list,0,8)
     
   coltab = [200, 80, 250]
   
      
   ;; 1mm
   ;;--------------------------------------------
   wind, 1, 1, /free, xsize=1150, ysize=670
   outplot, file=project_dir+'/Correlation_plot_'+strtrim(source, 2)+'_1mm_'+$
            strtrim(nickname,2)+photocorr_suffixe+opa_suf, png=png, ps=ps
   my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6

      
   plot, fwhm[wtokeep, 0] , flux[*, 0], /xs, yr=[min(flux_avg_1)*0.7, max(flux_avg_1)*1.3], $
         xr=[min(fwhm[wtokeep, 0])*0.97,min([max(fwhm[*, 0]),17.])], psym=-4, $
         xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[0, *]

  
   for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, fwhm[wtokeep[w], 0] , flux[w, 0], psym=4, col=(iq+1.)*250./nquasar, symsize=0.5
         oplot, fwhm[wtokeep[w], 2] , flux[w, 2], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, fwhm[wtokeep[w], 0] , flux[w, 0], psym=4, col=(iq+1.)*250./nquasar
         oplot, fwhm[wtokeep[w], 2] , flux[w, 2], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor
  
   legendastro, ['A1', 'A3'], psym=[4, 8]
   legendastro, quasar, textcol = (indgen(nquasar)+1.)*250./nquasar, box=0, /right
      
   ;; tau-flux
   t_1mm = exp(-tau_1mm[*]/sin(elev[*]*!dtor))
   t_1   = exp(-tau1/sin(elev*!dtor))
   t_3   = exp(-tau3/sin(elev*!dtor))
   ;;xrange = [min(tau_1mm[wtokeep]/sin(elev[wtokeep]*!dtor))*0.5,
   ;;min([max(tau_1mm[*]/sin(elev[*]*!dtor)),1.])]
   xrange = [0.4, 0.9]     
   plot, t_1mm[wtokeep], flux[*, 0], /xs, yr=[min(flux_avg_1)*0.6, max(flux_avg_1)*1.4], $
         xr=xrange, $
         xtitle='Atmospheric transmission', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[1, *], /noerase
   
    for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, t_1[wtokeep[w]] , flux[w, 0], psym=4, col=(iq+1.)*250./nquasar, symsize=0.5
         oplot, t_3[wtokeep[w]] , flux[w, 2], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, t_1[wtokeep[w]] , flux[w, 0], psym=4, col=(iq+1.)*250./nquasar
         oplot, t_3[wtokeep[w]] , flux[w, 2], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor

    
   ;; elev-flux
   plot, elev[wtokeep] , flux[*, 0], /xs, yr=[min(flux_avg_1)*0.6, max(flux_avg_1)*1.4], $
         xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
         xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[2, *], /noerase
   
   for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]] , flux[w, 0], psym=4, col=(iq+1.)*250./nquasar, symsize=0.5
         oplot, elev[wtokeep[w]] , flux[w, 2], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]] , flux[w, 0], psym=4, col=(iq+1.)*250./nquasar
         oplot, elev[wtokeep[w]] , flux[w, 2], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor
  
      
   ;; FWHM-elev
   f_max = min([max(fwhm[*, 0]),17.]) ; 15.
   f_min = min(fwhm[wtokeep, 0])*0.90
   plot, elev[*] , FWHM[*, 0], /xs, yr=[f_min,f_max], $
         xr=[10., 80.], psym=-4, $
         xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[3, *], /noerase
   
   for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]] , fwhm[wtokeep[w], 0], psym=4, col=(iq+1.)*250./nquasar, symsize=0.5
         oplot, elev[wtokeep[w]] , fwhm[wtokeep[w], 2], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]] , fwhm[wtokeep[w], 0], psym=4, col=(iq+1.)*250./nquasar
         oplot, elev[wtokeep[w]] , fwhm[wtokeep[w], 2], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor
   
   oplot, [0,90], 11.5*[1., 1.], col=0
     
   ;; FWHM-tau
   xrange = [min(tau_1mm[wtokeep]/sin(elev[wtokeep]*!dtor))*0.5, min([max(tau_1mm[*]/sin(elev[*]*!dtor)),1.])]
   plot, tau_1mm[*]/sin(elev[*]*!dtor) , fwhm[*, 0], /xs, yr=[f_min,f_max], $
         xr=xrange, psym=-4, $
         xtitle='observed opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[4, *], /noerase

    for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, tau1[wtokeep[w]]/sin(elev[wtokeep[w]]*!dtor) , fwhm[wtokeep[w], 0], psym=4, col=(iq+1.)*250./nquasar, symsize=0.5
         oplot, tau3[wtokeep[w]]/sin(elev[wtokeep[w]]*!dtor) , fwhm[wtokeep[w], 2], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, tau1[wtokeep[w]]/sin(elev[wtokeep[w]]*!dtor) , fwhm[wtokeep[w], 0], psym=4, col=(iq+1.)*250./nquasar
         oplot, tau3[wtokeep[w]]/sin(elev[wtokeep[w]]*!dtor), fwhm[wtokeep[w], 2], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor

   oplot, [0,50], 11.5*[1., 1.], col=0

   ;; tau-elev
   plot, elev[*] , tau_1mm[*], /xs, yr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], $
         xr=[10., 80.], psym=-4, $
         xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
         pos=pp1[5, *], /noerase
   
   for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]], tau_1mm[wtokeep[w]], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot,elev[wtokeep[w]], tau_1mm[wtokeep[w]] , psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor
   
   oplot, [0,90], 0.2*[1., 1.], col=0
   
   !p.multi=0
   outplot, /close

   
   
   
   ;; 2mm
   ;;--------------------------------------------
  
   wind, 1, 1, /free, xsize=1150, ysize=670
   outplot, file=project_dir+'/Correlation_plot_'+strtrim(source, 2)+'_2mm_'+$
            strtrim(nickname,2)+photocorr_suffixe+opa_suf, png=png, ps=ps
   my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
   
   plot, fwhm[wtokeep, 1] , flux[*, 1], /xs, yr=[min(flux_avg_2)*0.7, max(flux_avg_2)*1.3], $
         xr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),20.])], psym=-4, $
         xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[0, *]
   
   for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, fwhm[wtokeep[w], 1] , flux[w, 1], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, fwhm[wtokeep[w], 1] , flux[w, 1], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor
  
         
   ;; tau-flux
   t_2   = exp(-tau2/sin(elev*!dtor))

   xrange = [0.4, 0.9]     
   plot, t_2[wtokeep], flux[*, 0], /xs, yr=[min(flux_avg_2)*0.6, max(flux_avg_2)*1.4], $
         xr=xrange, $
         xtitle='Atmospheric transmission', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[1, *], /noerase
   
    for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, t_2[wtokeep[w]] , flux[w, 1], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, t_2[wtokeep[w]] , flux[w, 1], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor

    
   ;; elev-flux
   plot, elev[wtokeep] , flux[*, 1], /xs, yr=[min(flux_avg_2)*0.6, max(flux_avg_2)*1.4], $
         xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
         xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[2, *], /noerase
   
   for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]] , flux[w, 1], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]] , flux[w, 1], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor
  
      
   ;; FWHM-elev
   f_max = min([max(fwhm[*, 1]),20.]) ; 15.
   f_min = min(fwhm[wtokeep, 1])*0.90
   plot, elev[*] , FWHM[*, 1], /xs, yr=[f_min,f_max], $
         xr=[10., 80.], psym=-4, $
         xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[3, *], /noerase
   
   for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]] , fwhm[wtokeep[w], 1], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]] , fwhm[wtokeep[w], 1], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor
   
   oplot, [0,90], 17.5*[1., 1.], col=0
     
   ;; FWHM-tau
   xrange = [min(tau2[wtokeep]/sin(elev[wtokeep]*!dtor))*0.5, min([max(tau2[*]/sin(elev[*]*!dtor)),1.])]
   plot, tau2[*]/sin(elev[*]*!dtor) , fwhm[*, 0], /xs, yr=[f_min,f_max], $
         xr=xrange, psym=-4, $
         xtitle='observed opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[4, *], /noerase

    for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, tau2[wtokeep[w]]/sin(elev[wtokeep[w]]*!dtor) , fwhm[wtokeep[w], 1], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot, tau2[wtokeep[w]]/sin(elev[wtokeep[w]]*!dtor), fwhm[wtokeep[w], 1], psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor

   oplot, [0,50], 17.5*[1., 1.], col=0

   ;; tau-elev
   plot, elev[*] , tau2[*], /xs, yr=[min(tau2[wtokeep])*0.5,min([max(tau2[*]),1.])], $
         xr=[10., 80.], psym=-4, $
         xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
         pos=pp1[5, *], /noerase
   
   for iq=0, nquasar-1 do begin
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'POINTING', nn)
      if nn gt 0 then begin
         oplot, elev[wtokeep[w]], tau2[wtokeep[w]], psym=8, col=(iq+1.)*250./nquasar, symsize=0.5
      endif
      w = where(strupcase(scan_str.object) eq quasar[iq] and strupcase(scan_str.obstype) eq 'ONTHEFLYMAP', nn)
      if nn gt 0 then begin
         oplot,elev[wtokeep[w]], tau2[wtokeep[w]] , psym=8, col=(iq+1.)*250./nquasar
      endif   
   endfor
   
   oplot, [0,90], 0.2*[1., 1.], col=0
   
   !p.multi=0
   outplot, /close
   ;;---------------------------------------------------------------

   
endelse


if nostop lt 1 then stop



   
end
