;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_find_raw_data_file
;
; CATEGORY: 
;        data manager
;
; CALLING SEQUENCE:
;        scan_num, day, file, imb_fits_file, xml_file, $
;        [SILENT=, NOERROR=]
;
; PURPOSE: 
;        Search for the filenames of the requested scans
; 
; INPUT: 
;        - scan_list_in: The list of scans to be used as a string vector
;        e.g. ['20140221s0024', '20140221s0025', '20140221s0026']
; 
; OUTPUT: 
;        - antenna_file: the string list of antenna IMBFITS file
;        - rawdata_file: the string list of raw data file
;        - xml_file: the string list of xml (input to PAKO) file (optional)
; 
; KEYWORDS:
;        - SILENT: usual silent keyword
;        - NOERROR: set this keyword to continue even if no file is found
;        - XML: set this keyword to search also for XML files
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 15/03/2014: creation form nika_find_raw_data_file.pro 
;        (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)


pro nk_find_raw_data_file, scan_num, day, file, imb_fits_file, xml_file, $
                           file_found=file_found, $
                           SILENT=SILENT,$
                           NOERROR=NOERROR, $
                           scan=scan, polar_force_grep_x=polar_force_grep_x, $
                            uncompressed=uncompressed, raw_acq_dir=raw_acq_dir ; , xml=xml
;-


if n_params() lt 1 then begin
   dl_unix, 'nk_find_raw_data_file'
   return
endif

if keyword_set(scan) then scan2daynum, scan, day, scan_num

test_uncompressed_file = 0

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")
date = strmid(day,0,4)+"_"+strmid(day,4,2)+"_"+strmid(day,6,2)

if not keyword_set(scan) then scan = strtrim(day,2)+"s"+strtrim(scan_num,2)

nk_scan2run, scan, run

if keyword_set(raw_acq_dir) then !nika.raw_acq_dir = raw_acq_dir

if long(run) ge 13 then begin
   file_found = 0               ; init

   yyyy = strmid(day,0,4)
   mm   = strmid(day,4,2)
   dd   = strmid(day,6,2)
   scan = yyyy+mm+dd+"s"+strtrim(scan_num,2)
   
   imb_fits_file = !nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits"
   xml_file      = !nika.xml_dir+"/iram30m-scan-"+scan+".xml"

   if keyword_set( silent) eq 0 then print, !nika.raw_acq_dir
   if keyword_set( silent) eq 0 then print, '****************'


;;;;;;;;;;;;;;;;;;;;;;;;;;;; HR, 10/07/2020 ;;;;;;;;;;;;;;;;;;;;;;
;;;
   suffix = date+"*"+string(scan_num,format="(I4.4)")+"*"
   did_cmd = 0
   restart_cmd:
;;;
   if strupcase(!host) eq "NIKA2A" or $
      strupcase(!host) eq "MUSE" or $
      strupcase(!host) eq "NIKA2B" then begin
      if long(run) le 16 then begin
         if keyword_set(uncompressed) then begin
            cmd = "ls "+!nika.raw_acq_dir+"/*24_"+date+"/Y*" + suffix
         endif else begin
            cmd = "ls "+!nika.raw_acq_dir+"/*24_"+date+"/X*" + suffix
         endelse
      endif else begin
         cmd = "ls "+!nika.raw_acq_dir+"/*36_"+date+"/X*" + suffix
      endelse
   endif else begin
      racd = !nika.raw_data_dir
      ;racd = getenv( 'NIKA_RAW_ACQ_DIR')
      if long(!nika.run) ge 19 then begin
         cmd = 'ls '+racd+'*/X36_'+date+'/X*' + suffix
      endif else begin
         cmd = 'ls '+racd+'*/X24_'+date+'/X*' + suffix
      endelse
   endelse
   if did_cmd gt 0 then begin  ; Fix by FXD to see /data (e.g. 2015) if /data3 does not contain data
      res = get_login_info()
      if strupcase( res.machine_name) eq 'LPSC-NIKA2C' then begin
         racd = '/data/'
         if long(!nika.run) ge 19 then begin
            cmd = 'ls '+racd+'*/X36_'+date+'/X*' + suffix
         endif else begin
            cmd = 'ls '+racd+'*/X24_'+date+'/X*' + suffix
         endelse
      endif
   endif
   
   ;; if !nika.run eq 58 then begin
   ;;    print, cmd
   ;;    racd = !nika.raw_acq_dir
   ;;    cmd = 'ls '+racd+'*/X36_'+date+'/X*' + suffix
   ;;    print, cmd
   ;; endif
   print, 'Find raw file command ', cmd
   spawn, cmd, file
;;;
   did_cmd += 1
   nfiles =  n_elements(file)
   if nfiles gt 1 then begin
      if did_cmd gt 1 then begin
         print, 'unsolved problem with the naming conventions !'
         stop
      endif
      suffix = date+"*" + "_AA_" + string(scan_num,format="(I4.4)")+"*"
      goto, restart_cmd
   endif else file = file[0]

; Fix for 2015 data on lpsc machine
   if strlen(file) eq 0 then begin
      res=get_login_info()
      if did_cmd le 1 and $
         strupcase( res.machine_name) eq 'LPSC-NIKA2C' then goto, restart_cmd
   endif
;;;



   ;; distinguish between the scan number and the source name :)
;   nfiles =  n_elements(file)
;   if nfiles gt 1 then begin
;      i =  0
;      found =  0
;      while (found eq 0) and (i lt nfiles) do begin
;         dir =   file_dirname( file[i])
;         l   =   strlen( dir+"/X_2015_10_30_00h07m53_A0_")
;         if long(!nika.run) ge 35 then l = strlen( dir+"/X_2015_10_30_00h07m53_")
;         num =   strmid( file[i],   l,   4)
;         if num eq string( scan_num,   format =  "(I4.4)") then begin
;            file  =   file[i]
;            found =   1
;         endif
;         i++
;      endwhile
;   endif else begin
;      file =  file[0]
;   endelse
;;;;;;;;;;;;;;;;;;;;;;;;;;;; HR, 10/07/2020 ;;;;;;;;;;;;;;;;;;;;;;


   file_found = file_test(file)
   if file_found eq 0 and (not keyword_set(silent)) then begin
;; WARNING CHange this to avoid stopping auto_nk_rta !
;           message, "Did not find "+file
      message, "Did not find "+file, /info
      message, 'With command: '+ cmd, /info
      return
   endif
;      if file_test(imb_fits_file) then $
;         message, /info, "found imbfits   "+imb_fits_file else message, /info, "did not find "+imb_fits_file

;      if file_test(xml_file) then $
;         message, /info, "found xml file  "+xml_file      else message, /info, "did not find "+xml_file

   endif else begin
   
   ;; Define Command
   cmd = "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string(scan_num, format='(I4.4)')

   ;;---------- Run5
   if strmid(date,0,7) eq '2012_11' then $
      cmd = "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string(scan_num, format='(I4.4)')+' | grep Z_'

   ;;---------- Run7 and beyond
   if long(day) ge 20140101 and long(day) lt 20150210 then $
      cmd = "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string(scan_num,format='(I4.4)')+' | grep /X_'
   
   ;; The polarization run started on Feb. 10th in the evening while the
   ;; Openpool3 ended on Feb. 10th in the morning.
   ;; For polarization, we use the uncompressed files, e.g. Y_*
   if long(day) ge 20150210 then begin
      if long(day) eq 20150210 and scan_num le 157 then begin
         ;; still openpool3
         cmd = "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string(scan_num,format='(I4.4)')+' | grep /X_'
      endif else begin
         ;; Polarization run
         test_uncompressed_file = 1
         if strupcase( strtrim(!host,2)) eq "BAMBINI" then polar_force_grep_x = 1
;        if keyword_set(polar_force_grep_x) then begin
         cmd =  "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string(scan_num, format = '(I4.4)')+' | grep /X_'
;;        endif else begin
;;           cmd =  "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string(scan_num, format = '(I4.4)')+' | grep /Y_'
;;        endelse

      endelse
   endif
;
   ;;========== Search for the file
   spawn, cmd, file
   maindir = strmid(file_basename(file_dirname(file)), 0, 2)
   ;;---------- Take the file that start with L_ (Run7 data are written
   ;;           twice and only one of the file is good)
   okdir = where(maindir eq 'L_', nokdir)
   if nokdir gt 0 then file = file[okdir]

   ;;========== Check if it is ok
   ;;---------- Error message if no file
   if file[0] eq "" then begin
      if not keyword_set(NOERROR) then begin 
         message, /info, ""
         message, /info, "FAILED to execute: "+cmd
         message, /info, ""
         message, /info, "No data file found for scan_num="+strtrim(scan_num,2)+", day="+day
         if test_uncompressed_file eq 1 then begin
            message, /info, "It seems you looked for an UNcompressed file (polarization run ?) but"
            message, /info, "in a directory that holds compressed files only, 'raw_X' :"
            message, /info, "!nika.raw_acq_dir = "+strtrim(!nika.raw_acq_dir, 2)
            message, /info, "Try to redefine !nika.raw_acq_dir as e.g. /home/archeops/NIKA/Data/raw_Y9"
            message, /info, ""
            cmd =  "find "+!nika.raw_acq_dir+" -name '*"+date+"*' | grep _"+string(scan_num, format = '(I4.4)')+' | grep /X_'
            spawn, cmd, file
            maindir = strmid(file_basename(file_dirname(file)), 0, 2)
            okdir = where(maindir eq 'L_', nokdir)
            if nokdir gt 0 then file = file[okdir]
            if file[0] ne "" then begin
               message, /info, "Trying "+cmd
               message, /info, "returns "+file[0]
               message, /info, "Press .c to proceed"
            endif
         endif
         stop
      endif 
   endif
   
   ;;---------- Remove unwanted names
   n = where(file_basename(file_dirname(file)) ne '.AppleDouble' and strmatch(file,'*/._*') ne 1, nw)
   if nw eq 0 then begin
      if not keyword_set(NOERROR) then begin 
         message, /info, ""
         message, /info, cmd+" FAILED"
         message, "No data file without .AppleDouble found for scan_num="+strtrim(scan_num,2)+", day="+day
      endif
   endif else begin
      file = file[n]

      ;;---------- Check for observations of a sources whose name can
      ;;           also be a scan number...
      i     = 0
      found = 0
      while (found eq 0) and (i lt nw) do begin
         dir = file_dirname( file[i])
         l   = strlen( dir+"/Z_2012_11_23_19h19m37_")
         num = strmid( file[i], l, 4)
         if num eq string( scan_num, format="(I4.4)") then begin
            file  = file[i]
            found = 1
         endif
         i++
      endwhile
   endelse

   ;;========== IMBfits file
   cmd = "find "+!nika.imb_fits_dir+" -name '*"+day+"s"+strtrim(long(scan_num),2)+"-*' -print"
   spawn, cmd, imb_fits_file

   ;;----------Deal with .Appledouble like issues
   n = where(file_basename(file_dirname(imb_fits_file)) ne '.AppleDouble' and $
             strmatch(imb_fits_file,'*/._*') ne 1 and $
             strmatch(imb_fits_file, '*~') ne 1)

   imb_fits_file = imb_fits_file[n]
   imb_fits_file = imb_fits_file[0] ;just to make sure

   ;;========== XML file (from Run7 on)
   nika_find_xml_file, scan_num, day, xml_file, SILENT=SILENT

   if not keyword_set(SILENT) then begin
      message, /info, "Data file found   : "+file
      message, /info, "IMBfits file found: "+imb_fits_file
;      message, /info, "PaKO XML file found: "+xml_file
   endif

endelse
  

end
