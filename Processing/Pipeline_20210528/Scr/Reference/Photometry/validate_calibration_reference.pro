;
;
;   Cross-checks of Absolute calibration
;
;   LP, April, 2018
;
;____________________________________________________________________

pro validate_calibration_reference, runname, input_kidpar_file, $
                                    output_dir=output_dir, showplot=showplot, png=png, $
                                    opa_version_name=opa_version_name, $
                                    recalibration_coef = recalibration_coef, $
                                    outlier_scan_list = outlier_scan_list, $
                                    extra_scan_list = extra_scan_list, $
                                    opacity_from_tau225 = opacity_from_tau225, $
                                    nostop=nostop, $
                                    test_version_name=test_version_name, $
                                    output_allinfo_file = output_allinfo_file

  
  if not(keyword_set(output_dir)) then $
     output_dir = getenv('NIKA_PLOT_DIR')+'/'+runname+'/Photometry'
  
  if file_test(output_dir, /directory) gt 1 then spawn, "mkdir -p "+output_dir
  
  if keyword_set(nostop) then nostop=1 else nostop = 0
  
  nickname = runname
  if keyword_set(opa_version_name) then nickname = nickname+opa_version_name
  if keyword_set(test_version_name) then nickname = nickname+test_version_name
   
  opa_suf = ''
  if keyword_set(opacity_from_tau225) then opa_suf = '_use_tau225_v0'

    
;; MWC349
;;---------------------------------------------------------------
  source            = 'MWC349'
  lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0], !nika.lambda[0]]
  nu = !const.c/(lambda*1e-3)/1.0d9
  th_flux           = 1.69d0*(nu/227.)^0.26
  th_flux           = 1.16d0*(nu/100.0)^0.60
;; assuming indep param
  err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)
  ;;fill_nika_struct, '27'
  
;; CRL2688
;;---------------------------------------------------------------
;;  source            = 'CRL2688'
;;  th_flux_jfl       = [2.51, 0.54] ;; JFL
;;  th_flux           = [th_flux_jfl[0],th_flux_jfl[1],th_flux_jfl[0],th_flux_jfl[0] ]


;; NGC7027
;;--------------------------------------------------------------- 
;;  source            = 'NGC7027'
;;  th_flux_jfl       = [3.46, 4.26] ;; JFL
;;  th_flux           = [th_flux_jfl[0],th_flux_jfl[1],th_flux_jfl[0],th_flux_jfl[0] ]


  
  outlier_list = ''
  if keyword_set(outlier_scan_list) then outlier_list = outlier_scan_list


  
;; planets
;;----------------------------------------------------------------
;;source            = 'MARS'
;;lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
;;nu = !const.c/(lambda*1e-3)/1.0d9
;;fill_nika_struct, '27'
  
;; day-to-day variation of the flux expectations

;; FWHM selection cut
;;fwhm_a1_max = 12.7
;;fwhm_a3_max = 12.7
;;fwhm_a2_max = 18.1

;;decor_cm_dmin     = 90.0d0
;;==================


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
  
  opacity_correction = 6
  ;; options are:
  ;; - 0 = no correction
  ;; - 1 = a constant correction per scan
  ;; - 2 = elevation-dependent correction per scan
  ;; - 3 = constant correction per scan after decorrelation
  ;; - 4 = elevation-dependent and array dependent correction per scan
  ;; - 5 = hybrid opacity correction: elevation-dependent,
  ;;   array-dependent correction and array 2 opacities extrapolated
  ;;   from array 1 ones
  ;; - 6 = same as 4 but using the correcting factor to the skydip opacity
  ;;corrected_skydip   = 1
  
  ;; PHOTOMETRIC CORRECTION
  ;; SANS CORRECTION PHOTOMETRIQUE
  to_use_photocorr = 0
  photocorr        = 0
  
  ;; Scan selection
  
  restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_"+strupcase(runname)+"_v0.save"
  
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
  
  wtokeep = where(strupcase(scan[wok].obstype) eq 'ONTHEFLYMAP' $
                  and scan[wok].n_obs gt 4  $
                  and strupcase(scan[wok].object) eq strupcase(source), nkeep)
  
  
  scan_str = scan[wok[wtokeep]]
  scan_list = scan_str.day+"s"+strtrim( scan_str.scannum,2)

  if keyword_set(extra_scan_list) then begin
     ori_scan_list = scan_list
     add_scan_into_list, ori_scan_list, extra_scan_list, scan_list
  endif
  
  all_day       = scan.day
  all_day_list  = all_day[uniq(all_day, sort(all_day))]
  ndays         = n_elements(all_day_list)
  
  print, scan_list
  
  
;; remove outliers if any
;; define outlier_list and relaunch
;;-------------------------------------------------------------
if (n_elements(outlier_list) gt 0 and outlier_list[0] ne '') then begin
   scan_list_ori = scan_list
   remove_scan_from_list, scan_list_ori, outlier_list, scan_list
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
         file = output_dir+'/'+source+"_photometry_"+nickname+'/v_1/'+scan_list[isc]+'/results.save'
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
      project_dir = output_dir+'/'+source+"_photometry_"+nickname
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
                           'reset', 'do_tel_gain_corr', 'decor_cm_dmin', $
                           'opacity_correction']
   endif
endif

scan_list = scan_list[ sort(scan_list)]
nscans = n_elements(scan_list)

;file = 'MWC349_scanlist_all.save'
;save, scan_list, filename=file
;stop


;; check if all scans were indeed processed
run = !nika.run
project_dir = output_dir+"/"+source+"_photometry_"+nickname

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


if keyword_set(opacity_from_tau225) then begin
   
   opa_file = !nika.pipeline_dir+'/Datamanage/Tau225/results_opacity_tau225interp_'+strupcase(runname)+'.fits'
   restore, !nika.pipeline_dir+'/Datamanage/Tau225/modified_ATM_tau225_ratios.save'
   if file_test(opa_file) then begin
      
      opa = mrdfits(opa_file, 1)
      
      scan_list_opa = strtrim(opa.day,2)+'s'+strtrim(opa.scannum,2)
      my_match, scan_list_opa, scan_list, suba, subb
      
      if n_elements(subb) ne nscans then begin
         print, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
         print, "BEWARE: some scans are not found in the tau225 file"
      endif
      
      tau1_interp = dblarr(nscans)
      tau2_interp = dblarr(nscans)
      tau3_interp = dblarr(nscans)
      tau_1mm_interp = dblarr(nscans)
      
      tau225[subb] = opa[suba].tau225_medfilt
      
      tau1_interp[subb] = opa[suba].tau1_medfilt + modified_atm_tau225_ratio[0]*tau225[subb]
      tau2_interp[subb] = opa[suba].tau2_medfilt + modified_atm_tau225_ratio[1]*tau225[subb]
      tau3_interp[subb] = opa[suba].tau3_medfilt + modified_atm_tau225_ratio[2]*tau225[subb]
      tau_1mm_interp[subb] = opa[suba].tau3_medfilt + modified_atm_tau225_ratio[3]*tau225[subb]
      
      ;;tau1_interp[subb] = modified_atm_tau225_ratio[0]*tau225[subb]
      ;;tau2_interp[subb] = modified_atm_tau225_ratio[1]*tau225[subb]
      ;;tau3_interp[subb] = modified_atm_tau225_ratio[2]*tau225[subb]

      ;;tau1_interp[subb] = opa[suba].tau1_medfilt + modified_atm_tau225_ratio[0]
      ;;tau2_interp[subb] = opa[suba].tau2_medfilt + modified_atm_tau225_ratio[1]
      ;;tau3_interp[subb] = opa[suba].tau3_medfilt + modified_atm_tau225_ratio[2]

      
      flux[subb, 0] = flux[subb, 0]*exp((tau1_interp[subb]-tau1[subb])/sin(elev[subb]*!dtor))
      flux[subb, 1] = flux[subb, 1]*exp((tau2_interp[subb]-tau2[subb])/sin(elev[subb]*!dtor))
      flux[subb, 2] = flux[subb, 2]*exp((tau3_interp[subb]-tau3[subb])/sin(elev[subb]*!dtor))
      flux[subb, 3] = flux[subb, 3]*exp((tau_1mm_interp[subb]-tau_1mm[subb])/sin(elev[subb]*!dtor))
      tau1_ori = tau1
      tau2_ori = tau2
      tau3_ori = tau3
      tau_1mm_ori = tau_1mm
      tau1 = tau1_interp
      tau2 = tau2_interp
      tau3 = tau3_interp
      tau_1mm = tau_1mm_interp


      ;; plot
      wind, 1, 1, /free, xsize=1000, ysize=500
      my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6
      plot, tau225, tau1_ori, /nodata, ytitle='A1 tau skydip', xtitle = 'tau225 medfilt', yr=[0., 0.5], /ys, position=pp1[0,*]
      oplot, tau225, tau1_ori, psym=8, col=80
      oplot, tau225, tau1_interp, psym=4, col=250
      oplot, tau225+0.005, tau225*1.35, psym=1, col=250
      oplot, tau225+0.005, tau225*1.25, psym=1, col=150
      oplot, tau225+0.005, tau225*1.05, psym=1, col=100
      legendastro, ['NIKA2', 'extrapol tau225', '1.35 x tau255', '1.25 x tau225', '1.05 x tau225'],$
                   textcol=[80, 250, 250, 150, 100], col=[80, 250, 250, 150, 100], $
                   box=0, psym=[8, 4, 1, 1, 1]
      
      plot, tau225, tau2_ori, /nodata, ytitle='A2 tau skydip', xtitle = 'tau225 medfilt', yr=[0., 0.5], /ys, position=pp1[1,*], /noerase
      oplot, tau225, tau2_ori, psym=8, col=80
      oplot, tau225, tau2_interp, psym=1, col=250
      oplot, tau225+0.005, tau225*0.7, psym=1, col=150
      oplot, tau225+0.005, tau225*1.05, psym=1, col=100
      legendastro, ['NIKA2', 'extrapol tau225', '0.7 x tau255', '1.05 x tau225'], $
                   textcol=[80, 250, 150, 100], col=[80, 250, 150, 100], $
                   box=0, psym=[8, 4, 1, 1]
      stop
   endif else print, "File containing interpolated opacities from tau225 not found: ",opa_file 
endif


if keyword_set(recalibration_coef) then begin
   ;; the absolute calibration coefficients may depend on a
   ;; photometric correction
   ;; recalibrate for consistency
   print,"Recalibrate before photometric correction ", recalibration_coef
   for ia = 0, 3 do flux[*, ia] = flux[*, ia]*recalibration_coef[ia]
endif

;; photometric correction
;;-------------------------------------------------------------------
;; none

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
practical_scan_selection, allscan_info, wtokeep, $
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

wind, 1, 1, /free, /large
outplot, file='fwhm_'+strtrim(source,2)+'_'+strtrim(nickname,2), png=png, ps=ps
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
   flux_1     = flux[wtokeep, 0]
   flux_2     = flux[wtokeep, 1]
   flux_3     = flux[wtokeep, 2]
   flux_1mm   = flux[wtokeep, 3]
   err_flux_1     = err_flux[wtokeep, 0]
   err_flux_2     = err_flux[wtokeep, 1]
   err_flux_3     = err_flux[wtokeep, 2]
   err_flux_1mm   = err_flux[wtokeep, 3]
   day_list = strmid(scan_list,0,8)
   
   
   
;; save scan list
   info_list = scan_str.day+"s"+strtrim( scan_str.scannum,2)
   my_match, info_list, scan_list, suba, subb
   wotf     = where(scan_str[suba].n_obs gt 10 and scan_str[suba].n_obs lt 99, notf)
   otf_list = ''
   if notf gt 0 then otf_list = scan_list[subb[wotf]]
   save, otf_list, filename=output_dir+'/Goodscans_'+strtrim(source, 2)+'_'+runname+'.save'
;; 
   save, scan_list, filename=output_dir+'/Goodscans_'+strtrim(source,2)+'_'+runname+'_all.save'

   test_tau1 = tau1
   if  keyword_set(opacity_from_tau225) then test_tau1 = tau1_ori
   whi = where( test_tau1 gt 0.2, nhi, compl=wlo, ncompl=nlo)
   scan_list_hitau1 = scan_list[whi]
   scan_list_lotau1 = scan_list[wlo]
   save, scan_list_hitau1, filename=output_dir+'/Goodscans_'+strtrim(source, 2)+'_'+runname+'_hightau1.save'
   save, scan_list_lotau1, filename=output_dir+'/Goodscans_'+strtrim(source, 2)+'_'+runname+'_lowtau1.save'
   
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
   sigma_1   = stddev( flux_1)
   sigma_2   = stddev( flux_2)
   sigma_3   = stddev( flux_3)
   sigma_1mm = stddev( flux_1mm)
   flux_avg_1   = avg( flux_1)
   flux_avg_2   = avg( flux_2)
   flux_avg_3   = avg( flux_3)
   flux_avg_1mm = avg( flux_1mm)

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
   outfile = project_dir+'/photometry_'+strtrim(source)+'_'+strtrim(nickname,2)
   outplot, file=outfile, png=png, ps=ps
   my_multiplot, 1, 4, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
   !x.charsize = 1e-10
   
   yra=th_flux[0]*[0.7, 1.3]
   plot,       index, flux_1, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[0,*], yra=yra, /ys, title=file_basename(project_dir)
   oploterror, index, flux_1, err_flux_1, psym=8 
   oplot, [-1,nscans], [flux_avg_1, flux_avg_1], col=70
   oplot, [-1,nscans], th_flux[0]*[1., 1.], col=250
   legendastro, ['Array 1'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_1/flux_avg_1*100.0d0,format=fmt),2)+'%'], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=th_flux[2]*[0.7, 1.3]
   plot,       index, flux_3, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[1,*], /noerase, yra=yra, /ys
   oploterror, index, flux_3, err_flux_3, psym=8
   oplot, [-1,nscans], [flux_avg_3, flux_avg_3], col=70
   oplot, [-1,nscans], th_flux[2]*[1., 1.], col=250
   legendastro, ['Array 3'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_3/flux_avg_3*100.0,format=fmt)+'%',2)], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=th_flux[1]*[0.7, 1.3]
   plot,       index, flux_2, ytitle='Flux Jy',xr=[-1,nscans], /xs, position=pp1[2,*], /noerase, yra=yra, /ys
   oploterror, index, flux_2, err_flux_2, psym=8
   oplot, [-1,nscans], [flux_avg_2, flux_avg_2], col=70
   oplot, [-1,nscans], th_flux[1]*[1., 1.], col=250
   xyouts, index, flux_2, strmid(scan_list,4, 12), charsi=0.7, orient=90
   legendastro, ['Array 2'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_2/flux_avg_2*100.0,format=fmt),2)+'%'], box=0, /bottom
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
   
   ut_tab=['00:00', '07:00', '08:00', '09:00', '09:30', '10:00','12:00', '13:00', '15:00','17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '24:00']

   wok = where(ut ne '', nok) 
   minut = min(ut[wok])
   maxut = max(ut[wok])
   minh = where(ut_tab ge minut)
   maxh = where(ut_tab le maxut)
   ut_tab = ut_tab[minh[0]-1:maxh[n_elements(maxh)-1]+1]
   
   nut = n_elements(ut_tab)-1
   
   ;; 1mm
   ;;--------------------------------------------
   wind, 1, 1, /free, xsize=1150, ysize=670
   outplot, file=project_dir+'/Correlation_plot_'+strtrim(source, 2)+'_1mm_'+$
            strtrim(nickname,2)+opa_suf, png=png, ps=ps
   my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6

      
   plot, fwhm[*, 0] , flux[*, 0], /xs, yr=th_flux[0]*[0.6, 1.4], $
         xr=[min(fwhm[wtokeep, 0])*0.97,min([max(fwhm[*, 0]),17.])], psym=-4, $
         xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[0, *]
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, reform(fwhm[w, 0]) , reform(flux[w, 0]), psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, reform(fwhm[w, 2]) , reform(flux[w, 2]), psym=8, col=(u+1.)*250./nut
      print, 'from ', ut_tab[u], ' to ',  ut_tab[u+1], ' : ', nn, ' scans'
   endfor
   ;;oplot, fwhm[wtokeep, 0] , flux[wtokeep, 0], psym=8, col=coltab[0]
   if nout gt 0 then oplot, reform(fwhm[wout, 0]) , reform(flux[wout, 0]), psym=7, col=0, thick=2
   ;;oplot, fwhm[wtokeep, 2] , flux[wtokeep, 2], psym=8, col=coltab[2]
   if nout gt 0 then oplot, reform(fwhm[wout, 2]) , reform(flux[wout, 2]), psym=7, col=0, thick=2
   
   legendastro, ['A1', 'A3'], psym=[4, 8]
   oplot, [0,50], th_flux[0]*[1., 1.], col=0

   if photocorr lt 1 then oplot, fwhm[*, 0], th_flux[0]*(12.0^2+!nika.fwhm_nom[0]^2)/(fwhm[*,0]^2+!nika.fwhm_nom[0]^2), col=0
   if photocorr gt 0. then oplot, [0,50], flux_avg_1*[1., 1.], col=50
   if photocorr gt 0. then oplot, [0,50], flux_avg_3*[1., 1.], col=80
   
   ;; tau-flux
   t_1mm = exp(-tau_1mm[*]/sin(elev[*]*!dtor))
   t_1   = exp(-tau1/sin(elev*!dtor))
   t_3   = exp(-tau3/sin(elev*!dtor))
   ;;xrange = [min(tau_1mm[wtokeep]/sin(elev[wtokeep]*!dtor))*0.5,
   ;;min([max(tau_1mm[*]/sin(elev[*]*!dtor)),1.])]
   xrange = [0.4, 0.9]     
   plot, t_1mm[*], flux[*, 0], /xs, yr=th_flux[0]*[0.6, 1.4], $
         xr=xrange, $
         xtitle='Atmospheric transmission', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[1, *], /noerase
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      ;;if nn gt 0 then oplot, tau1[w]/sin(elev[w]*!dtor) , flux[w, 0], psym=4, col=(u+1.)*250./nut
      ;;if nn gt 0 then oplot, tau3[w]/sin(elev[w]*!dtor) , flux[w, 2], psym=8, col=(u+1.)*250./nut
      if nn gt 0 then oplot, t_1[w] , reform(flux[w, 0]), psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, t_3[w] , reform(flux[w, 2]), psym=8, col=(u+1.)*250./nut
   endfor
   ;;oplot, tau1[wout]/sin(elev[wout]*!dtor) , flux[wout, 0], psym=7,
   ;;col=0, thick=2
   if nout gt 0 then oplot, t_1[wout] , reform(flux[wout, 0]), psym=7, col=0, thick=2
   ;;oplot, tau3[wout]/sin(elev[wout]*!dtor) , flux[wout, 2], psym=7, col=0, thick=2
   if nout gt 0 then oplot, t_3[wout], reform(flux[wout, 2]), psym=7, col=0, thick=2
   oplot, [0,50], th_flux[0]*[1., 1.], col=0

   
   ;; elev-flux
   plot, elev[*] , flux[*, 0], /xs, yr=th_flux[0]*[0.6, 1.4], $
         xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
         xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[2, *], /noerase
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, elev[w] , reform(flux[w, 0]), psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, elev[w] , reform(flux[w, 2]), psym=8, col=(u+1.)*250./nut
   endfor
   
   ;;oplot, elev[wtokeep] , flux[wtokeep, 0], psym=8, col=coltab[0]
   if nout gt 0 then oplot, elev[wout] , reform(flux[wout, 0]), psym=7, col=0, thick=2
   ;;oplot, elev[wtokeep] , flux[wtokeep, 2], psym=8, col=coltab[2]
   if nout gt 0 then oplot, elev[wout] , reform(flux[wout, 2]), psym=7, col=0, thick=2
   
   oplot, [0,90], th_flux[0]*[1., 1.], col=0
   
   ;; FWHM-elev
   f_max = min([max(fwhm[*, 0]),17.]) ; 15.
   f_min = min(fwhm[wtokeep, 0])*0.90
   plot, elev[*] , FWHM[*, 0], /xs, yr=[f_min,f_max], $
         xr=[10., 80.], psym=-4, $
         xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[3, *], /noerase
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, elev[w] , reform(fwhm[w, 0]), psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, elev[w] , reform(fwhm[w, 2]), psym=8, col=(u+1.)*250./nut
      xyouts, 15., f_max - (f_max-f_min)*(u+0.5)/nut, ut_tab[u], charsi=0.7, orient=0, col=(u+1.)*250./nut
   endfor
   ;;oplot, elev[wtokeep] , fwhm[wtokeep, 0], psym=8, col=coltab[0]
   if nout gt 0 then oplot, elev[wout] , reform(fwhm[wout, 0]), psym=7, col=0, thick=2
   ;;oplot, elev[wtokeep] , fwhm[wtokeep, 2], psym=8, col=coltab[2]
   if nout gt 0 then oplot, elev[wout] , reform(fwhm[wout, 2]), psym=7, col=0, thick=2

   oplot, [0,90], 11.5*[1., 1.], col=0
     
   ;; FWHM-tau
   xrange = [min(tau_1mm[wtokeep]/sin(elev[wtokeep]*!dtor))*0.5, min([max(tau_1mm[*]/sin(elev[*]*!dtor)),1.])]
   plot, tau_1mm[*]/sin(elev[*]*!dtor) , fwhm[*, 0], /xs, yr=[f_min,f_max], $
         xr=xrange, psym=-4, $
         xtitle='observed opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[4, *], /noerase
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, reform(tau1[w]/sin(elev[w]*!dtor)) , reform(fwhm[w, 0]), psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, reform(tau3[w]/sin(elev[w]*!dtor)) , reform(fwhm[w, 2]), psym=8, col=(u+1.)*250./nut    
   endfor
   
   ;;oplot, tau_1mm[wtokeep] , fwhm[wtokeep, 0], psym=8, col=coltab[0]
   if nout gt 0 then oplot, reform(tau1[wout]/sin(elev[wout]*!dtor)) , reform(fwhm[wout, 0]), psym=7, col=0, thick=2
   ;;oplot, tau_1mm[wtokeep] , fwhm[wtokeep, 2], psym=8, col=coltab[2]
   if nout gt 0 then oplot, reform(tau3[wout]/sin(elev[wout]*!dtor)) , reform(fwhm[wout, 2]), psym=7, col=0, thick=2
   oplot, [0,50], 11.5*[1., 1.], col=0

   ;; tau-elev
   plot, elev[*] , tau_1mm[*], /xs, yr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], $
         xr=[10., 80.], psym=-4, $
         xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
         pos=pp1[5, *], /noerase

   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, elev[w] , tau_1mm[w], psym=8, col=(u+1.)*250./nut
   endfor
   ;;oplot, elev[wtokeep] , tau_1mm[wtokeep, 0], psym=8, col=coltab[2]
   if nout gt 0 then oplot, elev[wout] , reform(tau_1mm[wout]), psym=7, col=0, thick=2
   oplot, [0,90], 0.2*[1., 1.], col=0
   
   !p.multi=0
   outplot, /close

   
   
   
   ;; 2mm
   ;;--------------------------------------------
  
   wind, 1, 1, /free, xsize=1150, ysize=670
   outplot, file=project_dir+'/Correlation_plot_'+strtrim(source, 2)+'_2mm_'+$
            strtrim(nickname,2)+opa_suf, png=png, ps=ps
   my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
   
   ;; FWHM- Flux
   plot, fwhm[*, 1] , flux[*, 1], /xs, yr=th_flux[1]*[0.7, 1.2], $
         xr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], psym=-4, $
         xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[0, *]
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, reform(fwhm[w, 1]) , reform(flux[w, 1]), psym=8, col=(u+1.)*250./nut
      xyouts, 17.2, !nika.flux_uranus[1]*(1.2-0.5*(u+0.5)/nut), ut_tab[u], charsi=0.7, orient=0, col=(u+1.)*250./nut
   endfor
   ;;oplot, fwhm[wtokeep, 1] , flux[wtokeep, 1], psym=8, col=coltab[1]
   if nout gt 0 then oplot, reform(fwhm[wout, 1]) , reform(flux[wout, 1]), psym=7, col=0, thick=2
   oplot, [0,50], th_flux[1]*[1., 1.], col=0
   
   if photocorr lt 1 then oplot, fwhm[*, 1], th_flux[1]*(17.5^2+!nika.fwhm_nom[1]^2)/(fwhm[*,1]^2+!nika.fwhm_nom[1]^2), col=0
   if photocorr gt 0. then   oplot, [0,50], flux_avg_2*[1., 1.], col=250
   
   ;; tau-flux     
   plot, tau_2mm[*]/sin(elev[*]*!dtor) , flux[*, 1], /xs, yr=th_flux[1]*[0.7, 1.2], $
         xr=[min(tau_2mm[wtokeep]/sin(elev[wtokeep]*!dtor))*0.5,$
             min([max(tau_2mm[*]/sin(elev[*]*!dtor)),1.])], psym=-4, $
         xtitle='Observed opacity', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[1, *], /noerase
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, tau2[w]/sin(elev[w]*!dtor) , reform(flux[w, 1]), psym=8, col=(u+1.)*250./nut
   endfor
   ;;oplot, tau_2mm[wtokeep] , flux[wtokeep, 1], psym=8, col=coltab[1]
   if nout gt 0 then oplot, tau2[wout]/sin(elev[wout]*!dtor) , reform(flux[wout, 1]), psym=7, col=0, thick=2
   oplot, [0,50], th_flux[1]*[1., 1.], col=0
   
   
   ;; elev-flux
   plot, elev[*] , flux[*, 1], /xs, yr=th_flux[1]*[0.7, 1.2], $
         xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
         xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[2, *], /noerase
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, elev[w] , reform(flux[w, 1]), psym=8, col=(u+1.)*250./nut
   endfor
   ;;oplot, elev[wtokeep] , flux[wtokeep, 1], psym=8, col=coltab[1]
   if nout gt 0 then oplot, elev[wout] , reform(flux[wout, 1]), psym=7, col=0, thick=2
   oplot, [0,90], th_flux[1]*[1., 1.], col=0
   
   ;; FWHM-elev
   plot, elev[*] , FWHM[*, 1], /xs, yr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], $
         xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
         xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[3, *], /noerase
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, elev[w] , reform(fwhm[w, 1]), psym=8, col=(u+1.)*250./nut
   endfor
   ;;oplot, elev[wtokeep] , fwhm[wtokeep, 1], psym=8, col=coltab[1]
   if nout gt 0 then oplot, elev[wout] , reform(fwhm[wout, 1]), psym=7, col=0, thick=2
   oplot, [0,90], 17.5*[1., 1.], col=0
     
   ;; FWHM-tau 
   plot, tau_2mm[*] , fwhm[*, 1], /xs, yr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], $
         xr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], psym=-4, $
         xtitle='zenith opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[4, *], /noerase
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, tau_2mm[w] , reform(fwhm[w, 1]), psym=8, col=(u+1.)*250./nut
   endfor
   ;;oplot, tau_2mm[wtokeep] , fwhm[wtokeep, 1], psym=8, col=coltab[1]
   if nout gt 0 then oplot, tau_2mm[wout] , reform(fwhm[wout, 1]), psym=7, col=0, thick=2
   oplot, [0,50], 17.5*[1., 1.], col=0
   
   ;; tau-elev
   plot, elev[*] , tau_2mm[*], /xs, yr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], $
         xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
         xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
         pos=pp1[5, *], /noerase
   
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, elev[w] , tau_2mm[w], psym=8, col=(u+1.)*250./nut
   endfor
   ;;oplot, elev[wtokeep] , tau_2mm[wtokeep, 0], psym=8, col=coltab[1]
   if nout gt 0 then oplot, elev[wout] , tau_2mm[wout], psym=7, col=0, thick=2
   oplot, [0,90], 0.1*[1., 1.], col=0
   
   !p.multi=0
   outplot, /close
   ;;---------------------------------------------------------------

   
   ;; tau2/tau1
   ;;plot, tau3[*]/sin(elev[*]*!dtor), tau2[*]/tau3[*], /xs, yr=[0, 1.5], $
   ;;      xr=[0, 1.5], psym=-4, $
   ;;      xtitle='Observed tau3', ytitle='tau2/tau3', /ys, /nodata
   ;;for u = 0, nut-1 do begin
   ;;   w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
   ;;   if nn gt 0 then oplot,tau3[w]/sin(elev[w]*!dtor), tau2[w]/tau3[w] , psym=8, col=(u+1.)*250./nut
   ;;endfor

   ;;stop
   
   
   print,''
   print,'======================================================'
   print,"Average flux density A1: "+strtrim(flux_avg_1,2)+" Jy/beam"
   print,"Average flux density A3: "+strtrim(flux_avg_3,2)+" Jy/beam"
   print,"Average flux density A1&A3: "+strtrim(flux_avg_1mm,2)+" Jy/beam"
   print,"Average flux density A2: "+strtrim(flux_avg_2,2)+" Jy/beam"
   print,'======================================================'
   if strupcase(source) ne 'MARS' then begin
      print,"Relative uncertainty A1: "+strtrim(100.*sigma_1/flux_avg_1,2)+" %"
      print,"Relative uncertainty A3: "+strtrim(100.*sigma_3/flux_avg_3,2)+" %"
      print,"Relative uncertainty A1&A3: "+strtrim(100.*sigma_1mm/flux_avg_1mm,2)+" %"
      print,"Relative uncertainty A2: "+strtrim(100.*sigma_2/flux_avg_2,2)+" %"
      print,'======================================================'
      print,"Flux ratio to expectation A1: "+strtrim(flux_avg_1/th_flux[0],2)
      print,"Flux ratio to expectation A3: "+strtrim(flux_avg_3/th_flux[2],2)
      print,"Flux ratio to expectation A1&A3: "+strtrim(flux_avg_1mm/th_flux[3],2)
      print,"Flux ratio to expectation A2: "+strtrim(flux_avg_2/th_flux[1],2)
   endif else begin
      tab_var = dblarr(nscans, 3)
      for j = 0, nscans-1 do tab_var[j, *] = (flux[wtokeep[j], *]-tab_th_flux[j, *])^2/tab_th_flux[j, *]^2
      error = sqrt(mean(tab_var, dimension=1))
      print,"Relative uncertainty A1: "+strtrim(100.*error[0],2)+" %"
      print,"Relative uncertainty A3: "+strtrim(100.*error[2],2)+" %"
      print,"Relative uncertainty A2: "+strtrim(100.*error[1],2)+" %"
      print,'======================================================'
      tab_ratio = dblarr(nscans, 3)
      ;; tab_th_flux is already filled
      for j = 0, nscans-1 do tab_ratio[j, *] = flux[wtokeep[j], *]/tab_th_flux[j, *]
      print,tab_ratio
      ratio = mean(tab_ratio, dimension=1)
      print,"Flux ratio to expectation A1: "+strtrim(ratio[0],2)
      print,"Flux ratio to expectation A3: "+strtrim(ratio[2],2)
      print,"Flux ratio to expectation A2: "+strtrim(ratio[1],2)   
   endelse
   print,'======================================================'
   print,"Half-obstau mean flux diff A1: "+strtrim(diff_1,2)+" sigma"
   print,"Half-obstau mean flux diff A3: "+strtrim(diff_3,2)+" sigma"
   print,"Half-obstau mean flux diff A1&A3: "+strtrim(diff_1mm,2)+" sigma"
   print,"Half-obstau mean flux diff A2: "+strtrim(diff_2,2)+" sigma"
   print,'======================================================'
   print,''

   flux_ratio_to_expect = [flux_avg_1/th_flux[0], flux_avg_2/th_flux[1], flux_avg_3/th_flux[2], flux_avg_1mm/th_flux[3]]
   relative_error = 100.0*[sigma_1/flux_avg_1, sigma_2/flux_avg_2, sigma_3/flux_avg_3, sigma_1mm/flux_avg_1mm  ]
   corr_file = output_dir+"/Crosscheck_calibration_"+strtrim(nickname,2)+opa_suf+'.save'
   nscan_total = n_elements(scan_list_all)
   save, flux_ratio_to_expect, relative_error, nscans, nscan_total, filename=corr_file

endelse


if nostop lt 1 then stop



   
end
