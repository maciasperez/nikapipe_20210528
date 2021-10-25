pro get_calibration_scan_list, runname, scan_list, $
                               source_list=source_list, $
                               source_rootnames=source_rootnames, $
                               outlier_scan_list=outlier_scan_list, $
                               beammap=beammap, scan_info=scan_info, $
                               minimum_nscan_per_source = minimum_nscan_per_source, $
                               maximum_nscan = maximum_nscan, $
                               out_logbook_dir = out_logbook_dir
  

  ;;
  ;; get the list of scans of interest to monitor the calibration
  ;;
  ;; if the keyword source_list is not set, then output the list of
  ;; all scans. 
  ;;
  ;; if maximum_nscan is set, the total number of selected scans will
  ;; be limited at maximum_nscan. maximum_nscan will not be considered
  ;; if smaller than 10.

  

  allsources = 1
  calib_source=''
  if keyword_set(source_list) or keyword_set(source_rootnames) then begin
     allsources = 0
     if keyword_set(source_list) then calib_sources = source_list else $
        calib_sources = source_rootnames
  endif
  
  
  ;; outlier scans
  if keyword_set(outlier_scan_list) then outlier_scan_list=outlier_scan_list else outlier_scan_list=''
  outlier_list =  [$
                  '20170223s16', $     ; dark test
                  '20170223s17', $     ; dark test
                  '20171024s171', $    ; focus scan
                  '20171026s235', $    ; focus scan
                  '20171028s313', $    ; RAS from tapas
                  '20170608s131', $    ; nk_getdata: no useful data
                  '20180114s73', $     ; TBC
                  '20180116s94', $     ; focus scan
                  '20180118s212', $    ; focus scan
                  '20180119s241', $    ; Tapas comment: 'out of focus'
                  '20180119s242', $    ; Tapas comment: 'out of focus'
                  '20180119s243', $    ; Tapas comment: 'out of focus'
                  '20170224s184', $    ; dark test
                  '20170224s185', $    ; dark test
                  '20170224s186', $    ; dark test
                  '20170224s187', $    ; dark test
                  '20170224s188', $    ; dark test
                  '20170224s189', $    ; dark test
                  ;------------------N2R14---------------------
                  '20180122s98', $
                  '20180122s118', '20180122s119', '20180122s120', '20180122s121',$ ;; the telescope has been heated
                  '20180117s300', '20180120s257', $ ;; pb in antenna imbfits
                  ;;-----------------N2R15------------------------
                  '20180214s19', $  ; End of file encountered in antenna imbfits
                  '20180216s362', $ ; nk_w8: subscan 3 is empty 
                  '20180220s65', '20180217s241', '20180217s247', $ ; no useful data
                  ;;-----------------N2R21------------------------
                  '20180922s284', $ ; polar
                  '20180923s200', $ ; polar
                  '20180923s199', $ ; polar
                  ;;---------------------------------------------
                  '20181125s1', $ ; bug de minuit ?
                  ;;----------------------------------------------
                  '20190116s269', $    ;; NO RAW NIKA DATA FILE
                  '20190116s270', $    ;; NO RAW NIKA DATA FILE
                  '20190213s64', $     ;; uncomplete antenna imbfits
                  '20190307s49', $     ;;
                  '20190320s47', '20190320s48', '20190320s49','20190321s102', '20190322s70', '20190322s71', $ ;; no correlated KID found for a given KID
                  '20190323s228', $    ;; no useful data..
                  '20191103s117'$    ;; subscan 9 empty
                  ;;-----------------------------------------------
                  ;;----         N2R41   --------------------------
                  ;; 
                  ]  
                  
  if outlier_scan_list ne '' then outlier_list = [outlier_list, outlier_scan_list]
  antenna_imbfits_pb_list = ['iram30m-antenna-20190117s127-imb.fits']
  npb = n_elements(antenna_imbfits_pb_list)
  
  scan_list = ''   
  nrun = n_elements(runname)
  for irun=0, nrun-1 do begin
     
     ;; raw_data_dir (only for nika2d)
     set_raw_data_dir, runname[irun]
     logbook_dir = !nika.pipeline_dir+'/Datamanage/Logbook'
     filesave_out = logbook_dir+'/Log_Iram_tel_'+strupcase(runname[irun])+'_v0.save'
     if file_test(filesave_out) lt 1 then begin
        ;; the LogBook file is not present in the Datamanage directory
        ;; create a local version
        logbook_dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]
        if file_test(logbook_dir, /directory) lt 1 then spawn, 'mkdir '+ logbook_dir
        filesave_out = logbook_dir+'/Log_Iram_tel_'+strupcase(runname[irun])+'_v0.save'
        filecsv_out = logbook_dir+'/Log_Iram_tel_'+strupcase(runname[irun])+'_v0.cvs'
        if file_test(filesave_out) lt 1 then begin
           get_nika2_run_info, nika2run         
           index = where(strmatch(nika2run.nika2run, runname[irun]) eq 1, n) 
           ;;myday0 = strmid(nika2run[index].firstday, 0, 7)
           ;;first = strmid(nika2run[index].firstday, 0, 8)
           ;;spawn, "ls "+!nika.imb_fits_dir+'/iram30m-antenna-*'+myday0+'*imb.fits', flist0
           ;;alldays = strmid(file_basename(flist0), 16, 8)
           ;;w=where(alldays ge first, n)
           ;;if n gt 0 then flist0=flist0[w] else flist0=''
           ;;myday1 = strmid(nika2run[index].lastday, 0, 7)
           ;;last  = strmid(nika2run[index].lastday, 0, 8)
           ;;spawn, "ls "+!nika.imb_fits_dir+'/iram30m-antenna-*'+myday1+'*imb.fits', flist1
           ;;alldays = strmid(file_basename(flist1), 16, 8)
           ;;w=where(alldays le last, n)
           ;;if n gt 0 then flist1=flist1[w] else flist1=''
           ;; long runs
           ;;longrun = uint(strmid(myday1,6,1))-uint(strmid(myday0, 6, 1))-1
           ;;if longrun gt 0 then begin
           ;;   myday2 = strcompress(strmid(myday1,0,6)+string(uint(strmid(myday0, 6, 1))+1), /remove_all)
           ;;   spawn, "ls "+!nika.imb_fits_dir+'/iram30m-antenna-*'+myday2+'*imb.fits', flist2
           ;;endif else flist2=''
           ;;flist = ''
           ;;if n_elements(flist0) gt 0 and flist0[0] ne '' then flist = [flist, flist0]
           ;;if n_elements(flist1) gt 0 and flist1[0] ne '' then flist = [flist, flist1]
           ;;if n_elements(flist2) gt 0 and flist2[0] ne '' then flist = [flist, flist2]
           ;;flist = flist[1:*]
           ;;flist = flist(uniq(flist, sort(flist)))
           ;;for i=0, npb-1 do begin
           ;;   w=where(strmatch(file_basename(flist), antenna_imbfits_pb_list[i]) eq 1, n, compl=wok)
           ;;   if n gt 0 then flist=flist[wok]
           ;;endfor
           ;;
           ;;nk_log_iram_tel, flist, filesave_out, filecsv_out, nonika=1, notrim=1
           ;;
           ;; does not work like before....LP, 2020/10/30
           ;;log_iram_tel_onerun, runname[irun], logbook_dir =logbook_dir
           
           n2run = nika2run[index]
           log_iram_tel_onerun, n2run, logbook_dir=logbook_dir
        endif
     endif
     
     
     ;; Selection of scans
     restore, filesave_out
     
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
     
     nsubscan_min = 4
     if keyword_set(beammap) then nsubscan_min = 90

     scan=scan[wok]
     
     if allsources gt 0 then begin
        
        wtokeep = where(strupcase(scan.obstype) eq 'ONTHEFLYMAP' $
                        and scan.n_obs gt nsubscan_min, nkeep)
        
        scan_str    = scan[wtokeep]
        scan_list = [scan_list, scan_str.day+"s"+strtrim( scan_str.scannum,2)]      
        scan_list_ori = scan_list
        remove_scan_from_list, scan_list_ori, outlier_list, scan_list
        
     endif else begin
        nsource = n_elements(calib_sources)
        for isou=0, nsource-1 do begin
           
           source = strupcase(calib_sources[isou])
           print, ''
           print, 'Number of found scans for ', source

           wtokeep = where(strupcase(scan.obstype) eq 'ONTHEFLYMAP' $
                           and scan.n_obs gt nsubscan_min  $
                           and strupcase(scan.object) eq source, nkeep)

           if keyword_set(source_rootnames) then begin
              nsou = strlen(source)
              wtokeep = where(strupcase(scan.obstype) eq 'ONTHEFLYMAP' $
                              and scan.n_obs gt nsubscan_min  $
                              and strmid(strupcase(scan.object), 0, nsou) eq source, nkeep)
              
           endif
                      
           print, nkeep
           print, ''
           if nkeep gt 0 then begin
              scan_str = scan[wtokeep]
              scan_list_i = scan_str.day+"s"+strtrim( scan_str.scannum,2)
              
              scan_list_ori = scan_list_i
              remove_scan_from_list, scan_list_ori, outlier_list, scan_list_i

              print, 'after discarding outliers: ', n_elements(scan_list_i)
              ;;print, scan_list_ori
              ;;print, ''
              scan_list = [scan_list, scan_list_i]
              
           endif
        endfor
     endelse
  endfor
  
  if n_elements(scan_list) gt 1 then begin
     scan_list = scan_list[1:*]
     ;; scan_info
     scan_list_i = scan.day+"s"+strtrim( scan.scannum,2)
     my_match, scan_list_i, scan_list, suba, subb
     scan_list = scan_list[subb]
     scan_info = scan[suba]

     if keyword_set(minimum_nscan_per_source) then begin
        wsource = -1
        allsources = strupcase(scan_info.object)
        thesources = allsources[uniq(allsources, sort(allsources))]
        nsources = n_elements(thesources)
        for isou = 0, nsources-1 do begin
           w = where(allsources eq thesources[isou], nn)
           if (nn ge minimum_nscan_per_source) then wsource = [wsource, w] 
        endfor
        if n_elements(wsource) gt 1 then wsource = wsource[1:*] else $
           print, 'NO SOURCE WITH ENOUGHT SCANS'
        scan_info = scan_info[wsource]
        scan_list = scan_list[wsource]
     endif

     if keyword_set(maximum_nscan) then begin
        max_nscan = maximum_nscan
        nscan = n_elements(scan_list)
        ;; random draw of scans in bins of line-of-sight opacities
        if nscan gt max([max_nscan, 10]) then begin
           obstau = scan_info.tiptau225ghz/sin(scan_info.el_deg*!dtor)
           xbin = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1., 2.0]
           nbin = n_elements(xbin)-1
           ;; (nbin-4): usually observations do not cover the whole range of obstau 
           n_per_bin = max_nscan/(nbin-4) 
           u_scan_list = ''
           for i = 0, nbin-1 do begin
              wbin=where(obstau ge xbin[i] and obstau lt xbin[i+1], nn)
              if nn gt n_per_bin then begin
                 wbin = shuffle(wbin)
                 wsam = indgen(n_per_bin)
                 u_scan_list = [u_scan_list, scan_list[wbin[wsam]]]
              endif else if nn gt 0 then u_scan_list = [u_scan_list, scan_list[wbin]]
           endfor
           scan_list = u_scan_list[1:*]

           ;; restore scan_info
           scan_list_i = scan_info.day+"s"+strtrim( scan_info.scannum,2)
           my_match, scan_list_i, scan_list, suba, subb
           scan_list = scan_list[subb]
           scan_info = scan_info[suba]
          
        endif
     endif


     
  endif else print, "No scan found for the sources"

  if keyword_set(out_logbook_dir) then out_logbook_dir = logbook_dir
  
end
