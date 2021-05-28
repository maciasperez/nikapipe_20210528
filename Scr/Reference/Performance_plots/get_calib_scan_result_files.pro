;+
;
;  read processed calibration scans for the performance campaigns (N2R9,
;N2R12, N2R14)
;
;  read processed scans in /data/Workspace/Laurence/NIKA2/Plots/CalibTests
;
;  LP, July,2018
;-

pro get_calib_scan_result_files, result_files, labels=labels, outputdir=outputdir, photocorr_demo=photocorr_demo, photocorr_pointing=photocorr_pointing, no_recalibration=no_recalibration
  
  run   = ['N2R9', 'N2R12', 'N2R14']
  rname = ['baseline', 'atmlike', 'atmlike']

  ;; suffixe for result directory names and result_file
  ;;-----------------------------------------------------------------
  result_file_suf = '_'+['baseline3', 'baseline3', 'baseline3']
  if keyword_set(labels) then result_file_suf = '_'+strtrim(labels) 
  
  dir0 = '/data/Workspace/Laurence/Plots/CalibTests'
  
  dir9  = dir0+'/RUN9_OTFS'+result_file_suf[0]
  dir12 = dir0+'/RUN12_OTFS'+result_file_suf[1]
  dir14 = dir0+'/RUN14_OTFS'+result_file_suf[2]
  
  dir   = [dir9, dir12, dir14]
  
  if keyword_set(outputdir) then outdir = outputdir else $
     outdir = '/home/perotto/NIKA/Plots/Performance_plots/'

  if keyword_set(photocorr_demo) then result_file_suf = result_file_suf+'_photocorr_demo'
  if keyword_set(photocorr_pointing) then result_file_suf = result_file_suf+'_photocorr_pointing'

  photocorr_suf = ''
  if keyword_set(photocorr_demo) then photocorr_suf = '_photocorr_mod_var1'
  if keyword_set(photocorr_pointing) then photocorr_suf = '_photocorr_fwhm_pointing'
  
  
;;  Create table of result structures
;;----------------------------------------------------------------------
  resultfile_9    = outdir+'N2R9_calib_scan_result'+result_file_suf[0]+'.save'
  resultfile_12   = outdir+'N2R12_calib_scan_result'+result_file_suf[1]+'.save'
  resultfile_14   = outdir+'N2R14_calib_scan_result'+result_file_suf[2]+'.save'

  result_files = [resultfile_9, resultfile_12, resultfile_14]
  
  nrun = n_elements(run)
  nscan_perrun = lonarr(nrun)


for irun = 0, nrun-1 do begin
   
   calib_list_file = outdir+'Calib_OTF_scan_list_'+run[irun]+'.save'

   ;; recalibration factor for 'baseline' calibration
   recalibration_needed = 0
   recalibration_file = 'none'
   recalibration_coef = [1.0d0, 1.0d0, 1.0d0]
   if photocorr_suf gt '' then begin
      recalibration_file = !nika.soft_dir+'/Labtools/LP/datamanage/Calibration_coefficients_'+run[irun]+'_LP_to_'+rname[irun]+photocorr_suf+'.save'
      restore, recalibration_file, /v
      recalibration_needed = 1
   endif 

   if keyword_set(no_recalibration) then begin
      recalibration_needed = 0
      recalibration_file = 'none'
   endif
   
   if file_test(result_files[irun]) lt 1 then begin

      print,''
      print,'------------------------------------------'
      print,'   ', strupcase(run[irun])
      print,'------------------------------------------'
      print,'CREATING RESULT FILE: '
      print, result_files[irun]
      print, ''
      print, 'USING RECALIBRATION FILE: '
      print, recalibration_file
      
      spawn, 'ls '+dir[irun]+'/v_1/*/results.save', res_files
      nscans = 0
      if res_files[0] gt '' then nscans = n_elements(res_files)
      nscan_perrun[irun] = nscans
      juan_list = ''
      if nscans gt 0 then begin
         restore, res_files[0], /v
         allscan_info = replicate(info1, nscans)
         tags = tag_names(allscan_info)

         flag_info_incompatible = intarr(nscans)
         for i=0, nscans-1 do begin
            restore, res_files[i]
            ;; test consistency between structures 
            ;;test_tags = tag_names(info1)
            ;;my_match, tags, test_tags, suba, subb
            ;;if min(suba-subb) eq 0 and max(suba-subb) eq 0 then allscan_info[i] = info1 else $
            ;;   flag_info_incompatible[i] = 1
            allscan_info[i] = info1
         endfor

         ;; treat inconsistent structures
         wdiff = where(flag_info_incompatible gt 0, ndiff)
         if ndiff gt 0 then begin
            print, 'inconsistent structure info for files : ',res_files[wdiff] 
            for i=0, ndiff-1 do begin
               restore, res_files[wdiff[i]]
               test_tags = tag_names(info1)
               my_match, tags, test_tags, suba, subb
               ntags = min([n_elements(suba), n_elements(subb)])
               for it = 0, ntags-1 do allscan_info[wdiff[i]].(suba(it)) = info1.(subb(it))
            endfor
         endif
        
         
         ;; sort by scan-num
         ;;----------------------------------------------------------------
         allday   = allscan_info.day
         day_list = allday[uniq(allday, sort(allday))]
         nday     = n_elements(day_list)
         for id = 0, nday-1 do begin
            wd = where(allscan_info.day eq day_list[id], nd)
            allscan_info[wd] = allscan_info[wd[sort((allscan_info.scan_num)[wd])]]
         endfor
            
         calib_list = strtrim(string(allscan_info.day, format='(i8)'), 2)+'s'+$
                      strtrim(string(allscan_info.scan_num, format='(i8)'), 2)

         if recalibration_needed gt 0 then begin

            ;; convert to basline calibration
            ;;------------------------------------------------------------------
            ;; NEFD
            allscan_info.result_nefd_i_1mm = allscan_info.result_nefd_i_1mm*recalibration_coef[2]
            allscan_info.result_nefd_i_2mm = allscan_info.result_nefd_i_2mm*recalibration_coef[1]
            allscan_info.result_nefd_i1    = allscan_info.result_nefd_i1*recalibration_coef[0]
            allscan_info.result_nefd_i2    = allscan_info.result_nefd_i2*recalibration_coef[1]
            allscan_info.result_nefd_i3    = allscan_info.result_nefd_i3*recalibration_coef[2]
            ;; FLUX
            allscan_info.result_flux_i_1mm = allscan_info.result_flux_i_1mm*recalibration_coef[2]
            allscan_info.result_flux_i_2mm = allscan_info.result_flux_i_2mm*recalibration_coef[1]
            allscan_info.result_flux_i1    = allscan_info.result_flux_i1*recalibration_coef[0]
            allscan_info.result_flux_i2    = allscan_info.result_flux_i2*recalibration_coef[1]
            allscan_info.result_flux_i3    = allscan_info.result_flux_i3*recalibration_coef[2]
            ;; FLUX CENTER
            allscan_info.result_flux_center_i_1mm = allscan_info.result_flux_center_i_1mm*recalibration_coef[2]
            allscan_info.result_flux_center_i_2mm = allscan_info.result_flux_center_i_2mm*recalibration_coef[1]
            allscan_info.result_flux_center_i1    = allscan_info.result_flux_center_i1*recalibration_coef[0]
            allscan_info.result_flux_center_i2    = allscan_info.result_flux_center_i2*recalibration_coef[1]
            allscan_info.result_flux_center_i3    = allscan_info.result_flux_center_i3*recalibration_coef[2]
            ;; ERRFLUX
            allscan_info.result_err_flux_i_1mm = allscan_info.result_err_flux_i_1mm*recalibration_coef[2]
            allscan_info.result_err_flux_i_2mm = allscan_info.result_err_flux_i_2mm*recalibration_coef[1]
            allscan_info.result_err_flux_i1    = allscan_info.result_err_flux_i1*recalibration_coef[0]
            allscan_info.result_err_flux_i2    = allscan_info.result_err_flux_i2*recalibration_coef[1]
            allscan_info.result_err_flux_i3    = allscan_info.result_err_flux_i3*recalibration_coef[2]
            ;; ERRFLUX CENTER
            allscan_info.result_err_flux_center_i_1mm = allscan_info.result_err_flux_center_i_1mm*recalibration_coef[2]
            allscan_info.result_err_flux_center_i_2mm = allscan_info.result_err_flux_center_i_2mm*recalibration_coef[1]
            allscan_info.result_err_flux_center_i1    = allscan_info.result_err_flux_center_i1*recalibration_coef[0]
            allscan_info.result_err_flux_center_i2    = allscan_info.result_err_flux_center_i2*recalibration_coef[1]
            allscan_info.result_err_flux_center_i3    = allscan_info.result_err_flux_center_i3*recalibration_coef[2]
         endif

         ;; PHOTOMETRIC CORRECTION
         ;;_________________________________________________________
         photocorr = 0
         
         ;; DEMONSTRATION
         ;; keyword_set(photocorr_demo)
         if photocorr_suf eq '_photocorr_mod_var1' then begin
            photocorr = 1
            fix_photocorr = [12.5, 18.5, 12.5]
            delta_fwhm    = [0.4, 0.3, 0.4]
            photocorr_using_pointing = 0
         endif

         ;; POINTING-BASED
         ;; keyword_set(photocorr_pointing)
         if photocorr_suf eq '_photocorr_fwhm_pointing' then begin
            photocorr = 1
            fix_photocorr = [12.5, 18.5, 12.5]
            photocorr_using_pointing = 1
         endif

         if photocorr gt 0 then begin

            scan_list = allscan_info.scan
            
            fwhm = fltarr(nscans, 4)
            flux = fltarr(nscans, 4)
            for i=0, nscans-1 do begin
               fwhm[i, 0] = allscan_info[i].result_fwhm_1
               fwhm[i, 1] = allscan_info[i].result_fwhm_2
               fwhm[i, 2] = allscan_info[i].result_fwhm_3
               fwhm[i, 3] = allscan_info[i].result_fwhm_1mm
               flux[i, 0] = allscan_info[i].result_flux_i1
               flux[i, 1] = allscan_info[i].result_flux_i2
               flux[i, 2] = allscan_info[i].result_flux_i3
               flux[i, 3] = allscan_info[i].result_flux_i_1mm
            endfor
            
            tfwhm = transpose(fwhm)
            if keyword_set(photocorr_using_pointing) then begin

               day    = allscan_info.day
               ut_otf = fltarr(nscans)
               ut     = strmid(allscan_info.ut, 0, 5)
               for i = 0, nscans-1 do begin
                  ut_otf[i]  = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
               endfor
               get_pointing_based_beams, fwhm_point, day, ut_otf, run[irun]
               tfwhm = transpose(fwhm_point)
            endif
            tflux = transpose(flux)
            
            photometric_correction, tflux, tfwhm, corr_flux_factor, $
                                    fix=fix, weakly_variable=weakly_variable,$
                                    variable=variable, delta_fwhm=delta_fwhm, add1mm=1 


            ;; test plot
            ;;index = indgen(nscans)
            ;;plot, index, reform(corr_flux_factor[0, *]), yr=[0.85, 1.3], /ys, /nodata, $
            ;;      xtitle='scan index', ytitle= 'photometric correction factor', $
            ;;      xr=[-1, nscans], /xs
            ;;oplot, [0, nscans], [1, 1]
            ;;oplot, index, reform(corr_flux_factor[0, *]), col=80, psym=8
            ;;oplot, index, reform(corr_flux_factor[2, *]), col=50, psym=8
            ;;oplot, index, reform(corr_flux_factor[1, *]), col=250, psym=8
            ;;xyouts, index, replicate(0.87,nscans), strmid(scan_list, 4, 10), charsi=0.7, orient=90
            ;;legendastro, ['A1', 'A3', 'A2'], textcol=[80, 50, 250], col=[80, 50, 250], $
            ;;             box=0, psym=[8, 8, 8]
                        
            wphot=where(corr_flux_factor[0, *] gt 1.1 or corr_flux_factor[1, *] gt 1.1 or corr_flux_factor[2, *] gt 1.1, nwphot)
            if nwphot gt 0 then print, 'high photo corr for scans ', scan_list[wphot]
            
            raw_flux = flux
            for ia = 0, 3 do flux[*, ia] = flux[*, ia]*corr_flux_factor[ia,*]

            for i=0, nscans-1 do begin
               allscan_info[i].result_flux_i1    = flux[i, 0]
               allscan_info[i].result_flux_i2    = flux[i, 1]
               allscan_info[i].result_flux_i3    = flux[i, 2]
               allscan_info[i].result_flux_i_1mm = flux[i, 3]
            endfor
            
         endif
         ;; END PHOTOMETRIC CORRECTION
         ;;____________________________________________________________________________
            
      endif
      
      save, calib_list, filename=calib_list_file
      
      save, allscan_info, filename=result_files[irun]
      
   endif
   
endfor


  
end
