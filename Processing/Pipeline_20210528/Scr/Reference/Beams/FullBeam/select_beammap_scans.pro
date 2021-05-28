pro select_beammap_scans, selected_scan_list, selected_source

  ;; from the DB
  calib_run = ['N2R9', 'N2R12', 'N2R14']
  nrun=3
  
  scan_list = ''
  source    = ''
  n_beammap = lonarr(3)
  
  for irun = 0, 2 do begin

     runname = calib_run[irun] 
     
     filesave_out = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_tel_'+strupcase(runname)+'_v00.save'
     restore, filesave_out, /v
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
     
     wfocus = where((strupcase(scan.obstype) eq 'ONTHEFLYMAP' and $
                     (dz1 gt 0.3 or dx1 gt 0.5 or dy1 gt 0.5)) or  $
                    (strmid(scan.comment,0, 5) eq 'focus'), nscans, compl=wok, ncompl=nok)
     
     wtokeep = where(strupcase(scan[wok].obstype) eq 'ONTHEFLYMAP' $
                     and scan[wok].n_obs gt 50, nkeep)
     
     scan_str = scan[wok[wtokeep]]
     scan_list_run = scan_str.day+"s"+strtrim( scan_str.scannum,2)

     n_beammap[irun] = n_elements(scan_list_run)
     scan_list = [scan_list, scan_list_run]
     source    = [source, scan_str.object]
     
  endfor

  scan_list = scan_list[1:*]
  source    = source[1:*]

  
  ;; baseline selection
  ;;____________________________________________________________________
  
  get_all_scan_result_files_v2, result_files

  selected_scan_list = ''
  selected_source    = ''
  
  for irun = 0, nrun-1 do begin
     print,''
     print,'------------------------------------------'
     print,'   ', strupcase(calib_run[irun])
     print,'------------------------------------------'
     print,'READING RESULT FILE: '
     allresult_file = result_files[irun] 
     print, allresult_file
     
     ;;
     ;;  restore result tables
     ;;____________________________________________________________
     restore, allresult_file, /v
     ;; allscan_info

     
     ;; remove known outliers
     ;;___________________________________________________________
     scan_list_ori = allscan_info.scan
     
     outlier_list =  ['20170223s16', $  ; dark test
                      '20170223s17', $  ; dark test
                      '20171024s171', $ ; focus scan
                      '20171026s235', $ ; focus scan
                      '20171028s313', $ ; RAS from tapas
                      '20180114s73', $  ; TBC
                      '20180116s94', $  ; focus scan
                      '20180118s212', $ ; focus scan
                      '20180119s241', $ ; Tapas comment: 'out of focus'
                      '20180119s242', $ ; Tapas comment: 'out of focus'
                      '20180119s243', $  ; Tapas comment: 'out of focus'   '20180122s98', $
                      '20180122s118', '20180122s119', '20180122s120', '20180122s121', $ ;; the telescope has been heated
                      '20170226s415', $                                                 ;; wrong ut time
                      '20170226s416','20170226s417', '20170226s418', '20170226s419'] ;; defocused beammaps
     
     out_index = 1
     remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
     allscan_info = allscan_info[out_index]

     scan_list_run = allscan_info.scan

     my_match, scan_list, scan_list_run, suba, subb
     allscan_info = allscan_info[subb]

     ;;
     ;; Scan selection
     ;;____________________________________________________________ 
     to_use_photocorr = 0
     complement_index = 0
     beamok_index     = 0
     largebeam_index  = 0
     tauok_index      = 0
     hightau_index    = 0
     obsdateok_index  = 0
     afternoon_index  = 0
     fwhm_max         = 0
     nefd_index       = 0
     scan_selection, allscan_info, wtokeep, $
                     to_use_photocorr=to_use_photocorr, complement_index=wout, $
                     beamok_index = beamok_index, largebeam_index = wlargebeam,$
                     tauok_index = tauok_index, hightau_index=whitau3, $
                     osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                     fwhm_max = fwhm_max, nefd_index = nefd_index
     
     allscan_info = allscan_info[wtokeep]

     scan_list_run = allscan_info.scan 
     source_run    = allscan_info.object
     
     selected_scan_list = [selected_scan_list, scan_list_run]
     selected_source    = [selected_source, source_run]
     
  endfor

  selected_scan_list = selected_scan_list[1:*]
  selected_source = selected_source[1:*]
    
end
