;+
;
;  read all processed scans for the performance campaigns (N2R9,
;N2R12, N2R14)
;
;  read processed scans in /data/Workspace/macias/NIKA2/Plots/CalibTests
;
;  LP, July,2018
;-

pro get_all_scan_result_files, result_files, outputdir=outputdir, photocorr_demo=photocorr_demo, photocorr_pointing=photocorr_pointing
  
  run   = ['N2R9', 'N2R12', 'N2R14']
  rname = ['baseline', 'atmlike', 'atmlike']
  
  dir0 = '/data/Workspace/macias/NIKA2/Plots/CalibTests'

  dir9  = dir0+'/RUN9_OTFS_pipeline'
  dir12 = dir0+'/RUN12_OTFS_pipeline'
  dir14 = dir0+'/RUN14_OTFS_baseline'
  
  dir   = [dir9, dir12, dir14]

  if keyword_set(outputdir) then outdir = outputdir else $
     outdir = '/home/perotto/NIKA/Plots/Performance_plots/'
  
  suf='_baseline'
  if keyword_set(photocorr_demo) then suf = '_photocorr_demo'
  if keyword_set(photocorr_pointing) then suf = '_photocorr_pointing'

  photocorr_suf = ''
  if keyword_set(photocorr_demo) then photocorr_suf = '_photocorr_mod_var1'
  if keyword_set(photocorr_pointing) then photocorr_suf = '_photocorr_fwhm_pointing'
  
  
;;  Create table of result structures
;;----------------------------------------------------------------------
resultfile_9    = outdir+'N2R9_all_scan_result'+suf+'.save'
resultfile_12   = outdir+'N2R12_all_scan_result'+suf+'.save'
resultfile_14   = outdir+'N2R14_all_scan_result'+suf+'.save'

result_files = [resultfile_9, resultfile_12, resultfile_14]

nrun = n_elements(run)
nscan_perrun = lonarr(nrun)


for irun = 0, nrun-1 do begin
   juan_list_file = outdir+'OTF_scan_list_'+run[irun]+'.save'

   ;; recalibration factor for 'baseline' calibration
   recalibration_file = !nika.soft_dir+'/Labtools/LP/datamanage/Calibration_coefficients_'+run[irun]+'_JFMP_to_'+rname[irun]+photocorr_suf+'.save'
   restore, recalibration_file, /v
   
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
            test_tags = tag_names(info1)
            my_match, tags, test_tags, suba, subb
            if min(suba-subb) eq 0 and max(suba-subb) eq 0 then allscan_info[i] = info1 else $
               flag_info_incompatible[i] = 1
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
            
         juan_list = strtrim(string(allscan_info.day, format='(i8)'), 2)+'s'+$
                     strtrim(string(allscan_info.scan_num, format='(i8)'), 2)

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
      save, juan_list, filename=juan_list_file

      save, allscan_info, filename=result_files[irun]
      
   endif
 
endfor


  
end
