pro select_beammap_scan, n2runname, allscan_info, $
                         input_kidpar_file=input_kidpar_file, $
                         c0c1_available=c0c1_available, $
                         wikitable=wikitable, $
                         label=label, $
                         pdf_fig_dir=pdf_fig_dir
  
  no_opacity_correction = 1 ;; no correction of the atmospheric opacity
  if keyword_set(c0c1_available) then no_opacity_correction = 0
  
  source_list=['Uranus', '3C84', '0316+413', 'Neptune', 'Mars', 'Venus', '3C279']

  nrun = n_elements(n2runname)
  runname = n2runname[0]
  
  ;; define the kidpar 
  get_nika2_run_info, nika2run_info
  w=where(strmatch(nika2run_info.nika2run, runname) eq 1, n)
  mockscan = ''
  if n lt 1 then print, 'Please update get_nika2_run_info.pro for ', runname else begin
     firstday = nika2run_info[w].firstday
     lastday  = nika2run_info[w].lastday
     mockscan = firstday+"s1"
  endelse
  kidpar_file = ''
  if keyword_set(input_kidpar_file) then kidpar_file = input_kidpar_file else begin
     if mockscan ne '' then nk_get_kidpar_ref, s, d, info, kidpar_file, scan=mockscan
  endelse
     
  ;; get the list of all beammaps
  nso = n_elements(source_list)
  allscanlist = ''
  allcomment  = ''
  allrunid    = ''
  for irun = 0, nrun-1 do begin
     for i = 0, nso-1 do begin
        beammap_info_i = 1
        get_calibration_scan_list, n2runname[irun], scan_list, source_list=source_list[i], beammap=1, scan_info=beammap_info_i
        if scan_list[0] ne '' then begin
           print, source_list[i], ': ', scan_list
           allscanlist = [allscanlist, scan_list]
           allcomment  = [allcomment, beammap_info_i.comment]
           allrunid    = [allrunid, replicate(n2runname[irun], n_elements(scan_list))]
        endif
     endfor
  endfor
  if n_elements(allscanlist) gt 1 then begin
     allscanlist=allscanlist[1:*]
     allcomment=allcomment[1:*]
     allrunid=allrunid[1:*]
  endif

  ;; reduce all beammaps using nk
  ;; output in outplot_dir = getenv('NIKA_PLOT_DIR')+'/'+runname+'/Calibrators'+label
  if (n_elements(allscanlist) gt 0 and strlen(allscanlist[0]) gt 1) then begin
     if strlen(kidpar_file) le 1 then print, 'default reference kidpar file' else $
        print, 'kidpar_file: ', file_basename(kidpar_file)
     stop
     for irun = 0, nrun-1 do begin
        wrun = where(strmatch(allrunid,  n2runname[irun]) eq 1, nscan)
        if nscan gt 0 then launch_baseline_nk_batch, n2runname[irun], kidpar_file, label=label, force_scan_list = allscanlist[wrun], relaunch=1, no_opacity_correction = no_opacity_correction
     endfor
     
  endif

  ;; criteres
  ;; -- opacity and elevation
  ;; -- FWHM
  ;; -- UT hours
  ;; -- TAPAS comment
  ;;outdir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]+'/Calibrators'+label
  nscans = n_elements(allscanlist)
  result_files = ''
  if keyword_set(label) then suf = label else suf=''
  for irun = 0, nrun-1 do begin
     outdir = getenv('NIKA_PLOT_DIR')+'/'+n2runname[irun]+'/Calibrators'+suf
     wrun = where(strmatch(allrunid,  n2runname[irun]) eq 1, nscan)
     for i=0, nscan-1 do begin
        spawn, 'ls '+outdir+'/v_1/'+allscanlist[wrun[i]]+'/results.save', res_files
        if res_files[0] gt '' then result_files = [result_files, res_files] 
     endfor
  endfor
  if n_elements(result_files) gt 1 then result_files = result_files[1:*]
  
  nscans = n_elements(result_files)
  ;; initialise the info structure
  restore, result_files[0], /v
  allscan_info = replicate(info1, nscans)
  
  ;; test consistency between structures 
  tags = tag_names(allscan_info)
  flag_info_incompatible = intarr(nscans)
  for i=0, nscans-1 do begin
     restore, result_files[i]
     test_tags = tag_names(info1)
     my_match, tags, test_tags, suba, subb
     if min(suba-subb) eq 0 and max(suba-subb) eq 0 then allscan_info[i] = info1 else $
        flag_info_incompatible[i] = 1
     print, i, flag_info_incompatible[i]
  endfor
  
  ;; treat inconsistent structures
  wdiff = where(flag_info_incompatible gt 0, ndiff)
  if ndiff gt 0 then begin
     print, 'inconsistent structure info for files : ',result_files[wdiff]
     stop
     for i=0, ndiff-1 do begin
        restore, result_files[wdiff[i]]
        test_tags = tag_names(info1)
        my_match, tags, test_tags, suba, subb
        ntags = min([n_elements(suba), n_elements(subb)])
        for it = 0, ntags-1 do allscan_info[wdiff[i]].(suba(it)) = info1.(subb(it))
     endfor
  endif
        
  ;; sort by day and scan-num
  ;;----------------------------------------------------------------
  allday   = allscan_info.day
  ;; sort by day
  indday = sort(allday)
  allscan_info = allscan_info[indday]
  allscanlist = allscanlist[indday]
  allcomment = allcomment[indday]
  ;; sort by scan_num
  day_list = allday[uniq(allday, indday)]
  nday     = n_elements(day_list)
  for id = 0, nday-1 do begin
     wd = where(allscan_info.day eq day_list[id], nd)
     ind = wd[sort((allscan_info.scan_num)[wd])]
     allscan_info[wd] = allscan_info[ind]
     allscanlist[wd] = allscanlist[ind]
     allcomment[wd] = allcomment[ind]
  endfor
        
  
  for i=0, nscans-1 do begin
     print, '* ', allscanlist[i], ', ', $
            allscan_info[i].object, $
            ', UT=', strmid(allscan_info[i].ut, 0, 5), $
            ', el=', string(allscan_info[i].elev, format = '(I3)'), $
            ', tau225=', string(allscan_info[i].tau225, format='(F4.2)'), $
            ', tau1=', string(allscan_info[i].RESULT_TAU_1, format='(F4.2)'), $
            ', tau3=', string(allscan_info[i].RESULT_TAU_3, format='(F4.2)'), $
            ', tau1mm=', string(allscan_info[i].RESULT_TAU_1mm, format='(F4.2)'), $
            ', tau2mm=', string(allscan_info[i].RESULT_TAU_2, format='(F4.2)'), $
            ', FWHM1=', string(allscan_info[i].RESULT_FWHM_1, format='(F4.1)'), $
            ', FWHM3=', string(allscan_info[i].RESULT_FWHM_3, format='(F4.1)'), $
            ', FWHM1mm=', string(allscan_info[i].RESULT_FWHM_1mm, format='(F4.1)'), $
            ', FWHM2mm=', string(allscan_info[i].RESULT_FWHM_2, format='(F4.1)'), $
            ', Comment=', allcomment[i]
     print, '<!----------------------------------------------------------------------------->'
  endfor

  if keyword_set(wikitable) then begin

     print,'{| class="wikitable" style="vertical-align:bottom; text-align:right; color: black; width: 95%;" '
     print,'|- style="text-align:center; color: black; background-color: #d3d9df;"'
     print,'| colspan="11" | Properties of beammap scans '
     print,'|-'
     print,'| style="width: 9%" | Campaign'
     print,'| style="width: 10%" | Scan ID'
     print,'| style="width: 9%" | Source'
     print,'| style="width: 8%"  | UT'
     print,'| style="width: 7%"  | elev'
     print,'| style="width: 8%"  | tau225'
     if keyword_set(c0c1_available) then begin
        print,'| style="width: 8%"  | tau A1'
        print,'| style="width: 8%"  | tau A3'
        print,'| style="width: 8%"  | tau 1mm'
        print,'| style="width: 8%"  | tau 2mm'
     endif
     print,'| style="width: 8%"  | FWHM A1'
     print,'| style="width: 8%"  | FWHM A3'
     print,'| style="width: 8%"  | FWHM 1mm'
     print,'| style="width: 8%"  | FWHM 2mm'
     print,'| style="width: 40%"  | Comments'

     style = ''
     for i=0, nscans-1 do begin
        print, '|-'
        print, '| '
        print, '| ', allscanlist[i]
        print, '| ', allscan_info[i].object
        if (strmid(allscan_info[i].ut, 0, 2) ge 15 and strmid(allscan_info[i].ut, 0, 2) le 20) then $
        style = ' style = "background-color: #ffffb3" |' else style = '' 
        print, '|', style , strmid(allscan_info[i].ut, 0, 5)
        
        if (allscan_info[i].elev lt 30)  then $
        style = ' style = "background-color: #ffffb3" |'else style = '' 
        print, '|', style , string(allscan_info[i].elev, format = '(I3)')

        if (allscan_info[i].tau225 gt 0.4)  then $
        style = ' style = "background-color: #ffffb3" |'else style = '' 
        print, '|', style, string(allscan_info[i].tau225, format='(F4.2)')
        if keyword_set(c0c1_available) then begin
           if (allscan_info[i].RESULT_TAU_1 gt 0.7)  then $
           style = ' style = "background-color: #ffffb3" |'else style = '' 
           print, '|', style, string(allscan_info[i].RESULT_TAU_1, format='(F4.2)')
           if (allscan_info[i].RESULT_TAU_3 gt 0.7)  then $
           style = ' style = "background-color: #ffffb3" |'else style = '' 
           print, '|', style, string(allscan_info[i].RESULT_TAU_3, format='(F4.2)')
           if (allscan_info[i].RESULT_TAU_1mm gt 0.7)  then $
           style = ' style = "background-color: #ffffb3" |'else style = '' 
           print, '|', style, string(allscan_info[i].RESULT_TAU_1mm, format='(F4.2)')
           if (allscan_info[i].RESULT_TAU_2 gt 0.4)  then $
           style = ' style = "background-color: #ffffb3" |'else style = '' 
           print, '|', style, string(allscan_info[i].RESULT_TAU_2, format='(F4.2)')
        endif
        if (allscan_info[i].RESULT_FWHM_1 gt 12.5)  then $
        style = ' style = "background-color: #ffffb3" |'else style = '' 
        print, '|', style, string(allscan_info[i].RESULT_FWHM_1, format='(F4.1)')
        if (allscan_info[i].RESULT_FWHM_3 gt 12.5)  then $
        style = ' style = "background-color: #ffffb3" |'else style = '' 
        print, '|', style, string(allscan_info[i].RESULT_FWHM_3, format='(F4.1)')
        if (allscan_info[i].RESULT_FWHM_1mm gt 12.5)  then $
        style = ' style = "background-color: #ffffb3" |'else style = '' 
        print, '|', style, string(allscan_info[i].RESULT_FWHM_1mm, format='(F4.1)')
        if (allscan_info[i].RESULT_FWHM_2 gt 17.9)  then $
        style = ' style = "background-color: #ffffb3" |'else style = '' 
        print, '|', style, string(allscan_info[i].RESULT_FWHM_2, format='(F4.1)')
        if strcmp(allcomment[i], 'none', /fold_case) lt 1 then print, '| style = "background-color: #ffffb3"', allcomment[i] else print, '| '
     endfor
     print, '|}'
  endif

  ;; plot the blueprint of the kidpars
  if keyword_set(pdf_fig_dir) then begin
     ;; save the kidpars without any 'human' selection to fits file
     for i=0, nscans-1 do begin
        out_fits_file = pdf_fig_dir+'/kidpar_'+allscanlist[i]+'_noselection.fits'
        restore, result_files[i], /v
        nk_write_kidpar, kidpar1, out_fits_file, silent=silent
        compare_kidpar_plot, [kidpar_file, out_fits_file], saveps=1, file_suffixe='_'+strtrim(allscanlist[i],2), $
                             out_plot_dir=pdf_fig_dir
     endfor
     
  endif
  

  stop


  
  
end
