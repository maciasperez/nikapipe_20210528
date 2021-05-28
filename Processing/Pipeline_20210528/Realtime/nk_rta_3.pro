

;; pro nk_rta_3, polar=polar, nasmyth=nasmyth

pro nk_rta_3, nasmyth=nasmyth

;;----------------------------------------------------------------------------
;; force for convenience for the polarization run of Feb-Mar 2020
polar = 1
max_nsubscans_to_reduce = 50
do_not_reduce_skydips = 1
;;----------------------------------------------------------------------------

;; init my directories, one for the ref, one for the comparison
mydir = "F_temp_files"
spawn, "rm -rf "+mydir ; reset  
spawn, "mkdir "+mydir
mydir2 = "F_temp_files_2"
spawn, "rm -rf "+mydir2

;; Data directory
;; start from now: build list of files as they are now
spawn, "rsync -avuzq "+!nika.raw_acq_dir+"/X36*/F* --exclude '*man' --exclude '*tim' "+mydir+"/. 2> /dev/null"
spawn, "rm -f "+mydir+"/*tim"
spawn, "ls "+mydir+"/F*", data_flist
nf_data = n_elements( data_flist)

;; init a local copy
spawn, "cp -r "+mydir+" "+mydir2
spawn, "ls "+mydir2+"/F*", my_flist
nf_temp = n_elements( my_flist)

;; 3 seconds is reasonable to let time to produce the antennaIMBfits
nsec = 3
nwait_cycles = -1
while nf_temp eq nf_data do begin
;   print, "nwait_cycles: ", nwait_cycles
   
   ;; Check if a new data file has been produced, perhaps in a new
   ;; directory when we cross midnight
   spawn, "rsync -avuzq "+!nika.raw_acq_dir+"/X36*/F* --exclude '*man' --exclude '*tim' "+mydir+"/. 2> /dev/null"
   spawn, "rm -f "+mydir+"/*tim"
   spawn, "ls "+mydir+"/F*", data_flist
   nf_data = n_elements( data_flist)

   ;;leave time for the antennaimbfits to be closed as well
   wait, nsec
   
   ;; If a new file is here, then process and update list of scans to stay in the loop
   if nf_temp ne nf_data then begin
      nwait_cycles = -1
      ;; find the new file
      inewfile = -1
      for i=0, nf_data-1 do begin
         w = where( strupcase( file_basename(data_flist[i])) eq strupcase( file_basename(my_flist)), nw)
         if nw eq 0 then inewfile = i
      endfor

     ll = strlen('F_2018_12_05_18h18m45_')
;      ll = strlen('F_2019_02_12_15h51m29_AA_')
      scan_num = strtrim( long(strmid( file_basename(data_flist[inewfile]), ll, 4)),2)
      year  = long( strmid( file_basename(data_flist[inewfile]), 2, 4))
      month = long( strmid( file_basename(data_flist[inewfile]), 7, 2))
      day   = long( strmid( file_basename(data_flist[inewfile]), 10, 2))
      scan = string(year,form='(I4.4)')+string(month,form='(I2.2)')+string(day,form='(I2.2)')+'s'+scan_num
print,scan
;; Reduce the scan
    nk_get_kidpar_ref, scan_num, day, info, kidpar_file, scan=scan
    nk_rta, scan, polar=polar, nasmyth=nasmyth, kidfile=kidpar_file, $
            max_nsubscans_to_reduce=max_nsubscans_to_reduce, $
            do_not_reduce_skydips=do_not_reduce_skydips
      
      ;; Check if we are in a focus sequence and defined the list of scans
      xml_file = !nika.xml_dir+"/iram30m-scan-"+scan+".xml"
      if file_test( xml_file) then begin
         ;; in case of a track, the xml_file does not exist
         spawn, "grep -i comment "+xml_file, res
         if res ne '' then begin
            junk = strsplit( res, "value=", /ex, /reg)
            junk = strsplit( junk[1], " ", /ex, /reg)
            comment = strmid( junk[0],1)
            if strupcase(strmid(comment,0,5)) eq "FOCUS" then begin
               if defined(focus_scan_list) eq 0 then begin
                  focus_scan_list = [scan]
               endif else begin
                  focus_scan_list = [focus_scan_list, scan]
               endelse
            endif
            print, "focus_scan_list: ", focus_scan_list
         endif
      endif
   endif            

   if defined(focus_scan_list) then begin
      nfocus_scans = n_elements(focus_scan_list)
      ;; check if enough scans to fit and if the last scan of the
      ;; series is done (a longer time than usual has elapsed since
      ;; the last reduction)
      if nfocus_scans ge 5 and nwait_cycles ge 2 then begin
         nk_focus_otf, focus_scan_list
         ;; reset focus_scan_list and nwait_cycles
         delvarx, focus_scan_list
         nwait_cycles = -1
      endif
   endif
   
   ;; Update the list of F files and wait for the next one
   nwait_cycles++
   spawn, "rm -rf "+mydir2
   spawn, "cp -r "+mydir+" "+mydir2
   spawn, "ls "+mydir2+"/F*", my_flist
   nf_temp = n_elements( my_flist)   
endwhile


end
