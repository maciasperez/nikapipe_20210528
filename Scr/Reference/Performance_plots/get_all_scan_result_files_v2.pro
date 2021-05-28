;+
;
;  read all processed scans for the performance campaigns (N2R9,
;N2R12, N2R14)
;
;  read processed scans in
;/data/Workspace/macias/NIKA2/Plots/CalibTests
;
;  save raw results without any recalibration
;
;  LP, Sept 2018
;-

pro get_all_scan_result_files_v2, result_files, outputdir=outputdir

  run    = ['N2R9', 'N2R12', 'N2R14']
  runnum = [9, 12, 14]


  dir0 = '/data/Workspace/macias/NIKA2/Plots/CalibTests'
  dir1 = '/data/Workspace/Laurence/Plots/CalibTests'
    
  dir9  = dir0+'/RUN9_OTFS_v2_calpera'
  dir12 = dir1+'/RUN12_OTFS_v2_calpera'
  dir14 = dir0+'/RUN14_OTFS_v2_calpera'
  ;; April 2020
  ;;dir14 = '/data3/Workspace/perotto/Plots/N2R14_debug/Calibrators'
  ;;dir14 = '/data3/Workspace/perotto/Plots/N2R14_debug/Calibrators_2'
  ;;dir14 = '/data3/Workspace/perotto/Plots/N2R14_debug/Calibrators_3'
  
  dir   = [dir9, dir12, dir14]

  if keyword_set(outputdir) then outdir = outputdir else $
     outdir = getenv('NIKA_PLOT_DIR')+'/Performance_plots/'
  if file_test(outdir, /directory) lt 1 then spawn, "mkdir -p "+outdir

  
;;  Create table of result structures
;;----------------------------------------------------------------------

nrun         = n_elements(run)
nscan_perrun = lonarr(nrun)

result_files = strarr(nrun)

for irun = 0, nrun-1 do begin

   spawn, 'ls '+dir[irun]+'/v_1/*/results.save', res_files
   nscans = 0
   if res_files[0] gt '' then nscans = n_elements(res_files)
   
   result_file = outdir+'N2R'+strtrim(runnum[irun],2)+'_all_scan_result_'+strtrim(nscans,2)+'.save'

   result_files[irun] = result_file 

   if file_test(result_file) lt 1 then begin

      print,''
      print,'------------------------------------------'
      print,'   ', strupcase(run[irun])
      print,'------------------------------------------'
      print,'CREATING RESULT FILE: '
      print, result_files[irun]
      print, ''

      scan_list_file = outdir+'N2R'+strtrim(runnum[irun],2)+'_all_scan_list_'+strtrim(nscans,2)+'.save'
      
      spawn, 'ls '+dir[irun]+'/v_1/*/results.save', res_files
      nscans = 0
      if res_files[0] gt '' then nscans = n_elements(res_files)
      nscan_perrun[irun] = nscans
      
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
            
         scan_list = strtrim(string(allscan_info.day, format='(i8)'), 2)+'s'+$
                     strtrim(string(allscan_info.scan_num, format='(i8)'), 2)

         
         save, scan_list, filename=scan_list_file
         save, allscan_info, filename=result_files[irun]
      
      endif

   endif 
     
   
   
endfor


  
end
