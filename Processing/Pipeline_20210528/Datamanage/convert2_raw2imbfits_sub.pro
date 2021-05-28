pro convert2_raw2imbfits_sub, file, imb_dir = imb_dir,  $
                              noexe = noexe,  verb = verb,  $
                              ftp = ftp, lpsc = lpsc, $
                              updp = updp, nowait = nowait, $
                              noimb = noimb, cfits = cfits

if n_params() eq 0 then begin
  message, /info, 'Call with : convert2_raw2imbfits_sub, '
  message, /info, '  file(dir included) [, ' + $
           'imb_dir = imb_dir,  /noexe, /ftp,/lpsc] '
  return
endif
; Used by convert2_rawdata2imbfits.pro or as a standalone program for one given file
; (give full name including directory)

; Write that message in any case (verb=1 or not)
print, 'Start processing ' + file
timebeg = systime( /second)
if not keyword_set( imb_dir) then imb_dir ='/NikaData/'
;;; initial
; list_data = 'sample MJD subscan scan I Q dI dQ RF_didq F_TONE DF_TONE retard 49'
;;; with official shift by Nicolas
;; list_data = "sample MJD subscan scan I Q dI dQ RF_didq retard "+ $
;;             strtrim( !nika.retard,2)+" F_TONE DF_TONE"

dirin = file_dirname( file)
dirout = imb_dir
filebase = file_basename( file)
on_ioerror, NOPROC              ; case of a file not corresponding to a scan

str2 = strsplit(filebase,'_',/extract)
date = str2[1]+str2[2]+str2[3]
scan_num = strtrim(long(str2[5]),2) 
if scan_num le 0 then goto,  NOPROC
; here the "not a scan" file case is handled

; list_data = 'all'
                                ;stop
; Better for runCryo
;; retard = !nika.retard
;; list_data = "sample subscan scan el I Q dI dQ RF_didq retard "+ $
;;             strtrim(retard,2)+$
;;                  " ofs_az ofs_el paral scan_st F_TONE DF_TONE MJD LST"
;; status =  READ_NIKA_BRUTE( file, param_c, kidpar, strdat, units, periode, $
;;                            list_data=list_data,  read_type = 12, /silent)
; 12 means that only the valid kid and offs are kept


if keyword_set( lpsc) then begin 
; Send the data straight to the lpsc (for Nicolas)
   dirin1 = file_dirname( dirin)
   dirin2 = file_basename( dirin)
   command = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/scp_to_lpsc.sh ' + $
             dirin1 + ' '+ dirin2+' '+filebase+ $
             ' >> /home/archeops/temp/log/scp_to_lpsc.log   &  '
   if keyword_set( noexe) then begin
      if keyword_set( verb) then print, 'Not doing '+ command 
   endif else begin
      if keyword_set( verb) then print, 'Doing '+ command
      spawn, command, /stderr, /sh
      if keyword_set( verb) then print,  res
   endelse
   
; send xml as well
; hard code to go faster
   dir1 = '/home/archeops/NIKA/Data'
   dir2 = 'Pako_xml'
   fixml = 'iram30m-scan-'+date+ 's'+scan_num+ '.xml'
   command = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/scp_to_lpsc2.sh ' + $
             dir1 + ' '+ dir2+' '+fixml + $
             ' >> /home/archeops/temp/log/scp_to_lpsc2.log   &  '
   if keyword_set( noexe) then begin
      if keyword_set( verb) then print, 'Not doing '+ command 
   endif else begin
      if keyword_set( verb) then print, 'Doing '+ command
      spawn, command, /stderr, /sh
      if keyword_set( verb) then print,  res
   endelse
   
   
endif



; Run7,8
; Check that it is equal No it is not. But it does not matter
if keyword_set( verb) then print, scan_num,  ' ', date
file2scan_day,  file, scan_num2, day
if keyword_set( verb) then print, scan_num2, ' ', day
nika_pipe_default_param, scan_num, date, param
nika_pipe_getdata, param, strdat, kidpar, silent = 1-keyword_set( verb),  $
                   param_c = param_c, param_d = param_d, /no_bandpass
if size( strdat, /type) ne 8 then begin
   ; there is a problem with the scan
   strdat = -1
   print, 'Scan could not be processed:  ' + file
   goto,  DONE
endif

; reference kidpar containing 5 for double-kids (or anomalous), 1 for ok, 2
; for off-reso. No zero-signal channels.
; kidpar.array = 1 (1mm), 2 (2mm) 
; original kidpar can be retrieved by setting param.kid_file.a='' idem for b.
; Prepare true MJD (communicate to Nicolas).

; mask out of reso kids
nika_pipe_outofres, param, strdat, kidpar, /changekid, /bypass_error
if keyword_set( verb) then print, 'Bad kids were flagged'

;Init imbfits file names
totalimbfits_dir = '/home/archeops/NIKA/Data/TotalImbfits/'
fifits1 = 'iram30m-NIKA1mm-'+date+ 's'+scan_num+ '-imb.fits'
fifits2 = 'iram30m-NIKA2mm-'+date+ 's'+scan_num+ '-imb.fits'

if keyword_set( updp) or keyword_set( cfits) then begin
; unzip the fits files
   command =   'gunzip -f '+ totalimbfits_dir+ fifits1+ '.gz'
   if keyword_set( noexe) then begin
      if keyword_set( verb) then print, 'Not doing '+ command 
   endif else begin
      if keyword_set( verb) then print, 'Doing '+ command
      spawn, command, res, /stderr, /sh
      if keyword_set( verb) then print,  res
   endelse
   command =   'gunzip -f '+ totalimbfits_dir+ fifits2+ '.gz'
   if keyword_set( noexe) then begin
      if keyword_set( verb) then print, 'Not doing '+ command 
   endif else begin
      if keyword_set( verb) then print, 'Doing '+ command
      spawn, command, res, /stderr, /sh
      if keyword_set( verb) then print,  res
   endelse
endif

if keyword_set( cfits) then begin
; create the names
   cfifits1 = "iram30m-NIKA1mm-"+date+ "s"+scan_num+ "-clean_imb.fits"
   cfifits2 = "iram30m-NIKA2mm-"+date+ "s"+scan_num+ "-clean_imb.fits"
endif


; Prepare and correct data here
nscan = round( median( strdat.scan))
nsubscan = round( max( strdat.subscan))
if keyword_set( verb) then print, 'nsubscan = ',  nsubscan

if nsubscan ge 1 then begin     ; true scan file
   fileout = nika_transform_iram_name( filebase, nscan, $
                                       k_nscan = nscanfile,  teltime = teltime)
   
   ndeg = 3                     ; 0 if pf is done before
   if keyword_set( updp) then begin
      if keyword_set( verb) then $
         print,   'convert2_str2imbfits ', dirin, '  ',  filebase, ' Into '
      if keyword_set( verb) then $
         print, totalimbfits_dir, fifits2
      convert2_str2imbfits, dirin, filebase, param_c, kidpar, strdat, $
                            totalimbfits_dir, fifits2, $
                            ndeg, noexe = noexe,  verb = verb, $
                            updp = updp
   endif else begin
         if keyword_set( cfits) then fout = fifits2 else fout = fileout
         if keyword_set( verb) then $
            print,   'convert2_str2imbfits ', dirin, '  ',  filebase, ' Into '
         if keyword_set( verb) then $
            print, dirout, fileout
                      ; truncate the data to the useful part in this routine 
         if keyword_set( cfits) then $
            convert2_str2imbfits, dirin, filebase, param_c, kidpar, strdat, $
                               dirout, fout, ndeg, $
                               noexe = noexe,  verb = verb, $
                               cfits = [cfits, cfifits1, cfifits2] else $
         convert2_str2imbfits, dirin, filebase, param_c, kidpar, strdat, $
                               dirout, fout, ndeg, $
                               noexe = noexe,  verb = verb
   endelse
endif

if not keyword_set( updp) and not keyword_set( cfits) then begin 

; Produce Total imbfits files
; 'remote' added in produce_nika_imbfits.sh for Albrecht before run8
command = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/ssh_for_imbfits.sh '+ $
          date + ' ' + scan_num + ' ' + scan_num + $
          ' >> /home/archeops/temp/log/ssh_for_imbfits.log'
if keyword_set( verb) then $
   print, ' Making telescope imbfits and combining with NIKA data: '
if keyword_set( noexe) or keyword_set( noimb) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command 
   spawn, command
endelse 

; Transfer antenna fits first to sami
antennafile = '/mrt-lx3/vis/t21/observationData/imbfits/iram30m-antenna-'+ $
              date+ 's'+strtrim(scan_num, 2) +'-imb.fits'

command1 = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/' + $
           'ssh_check_antenna_imbfits.sh '+ antennafile ;+ $

command2 = "scp 't21@mrt-lx3.iram.es:"+ antennafile + "' $IMB_FITS_DIR/"+ $
           ' >> /home/archeops/temp/log/scp_antenna_imbfits.log '
if keyword_set( noexe) or keyword_set( noimb) or keyword_set( cfits) then begin
   if keyword_set( verb) then print, 'Not done '+ command1+ ' AND '+ command2
endif else begin
   if keyword_set( verb) then $
      print, 'Doing ' + command1 + ' AND '+ command2
                                ; Check antenna files are available
   if not keyword_set( nowait) then begin 
      spawn, command1, res, /stderr, /sh
      if keyword_set( verb) then print,  res 
   endif

   spawn, command2, res, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse

; Here manage the imbfits files
; First copy the total imbfits files to sami
command = 'scp t21@mrt-lx3.iram.es:' + $
          '/mrt-lx3/vis/t21/observationData/imbfits/'+ $
          fifits1 + ' '+ totalimbfits_dir+ $
          ' >> /home/archeops/temp/log/scp_total_imbfits1.log '
if keyword_set( noexe)  or keyword_set( noimb) or keyword_set( cfits) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command 
   spawn, command, res, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse 

command =   'scp t21@mrt-lx3.iram.es:' + $
            '/mrt-lx3/vis/t21/observationData/imbfits/'+ $
            fifits2 + ' '+ totalimbfits_dir+ $
          ' >> /home/archeops/temp/log/scp_total_imbfits2.log '
if keyword_set( noexe)  or keyword_set( noimb) or keyword_set( cfits) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command
   spawn, command, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse



; Ftp total imbfits not required anymore by RZ (will rsync another way)
;; command = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/lftp_sami2neel.sh ' + $
;;           'NikapreRun7AllData TotalImbfits ' + totalimbfits_dir+ fifits1 + $
;;           ' ' + fifits1 + $
;;           ' >> /home/archeops/temp/log/lftp_total_imbfits1.log   &  '
;; if keyword_set( noexe) then begin
;;    if keyword_set( verb) then print, 'Not doing '+ command 
;; endif else begin
;;    if keyword_set( verb) then print, 'Doing '+ command 
;;    spawn, command, /stderr, /sh
;;    if keyword_set( verb) then print,  res
;; endelse

;; command = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/lftp_sami2neel.sh ' + $
;;           'NikapreRun7AllData TotalImbfits ' + totalimbfits_dir+ fifits2 + $
;;           ' ' + fifits2 + $
;;           ' >> /home/archeops/temp/log/lftp_total_imbfits2.log   &  '
;; if keyword_set( noexe) then begin
;;    if keyword_set( verb) then print, 'Not doing '+ command 
;; endif else begin
;;    if keyword_set( verb) then print, 'Doing '+ command
;;    spawn, command, /stderr, /sh
;;    if keyword_set( verb) then print,  res
;; endelse
endif else begin ; otherwise  (case of updp) compress the new fits files
   if keyword_set( updp) then begin
      newtotalimbfits_dir = '/home/archeops/NIKA/Data/TotalImbfits/'+updp+'/'
      command =   'gzip -f '+ newtotalimbfits_dir+ fifits1 
      if keyword_set( noexe) then begin
         if keyword_set( verb) then print, 'Not doing '+ command 
      endif else begin
         if keyword_set( verb) then print, 'Doing '+ command
         spawn, command, res, /stderr, /sh
         if keyword_set( verb) then print,  res
      endelse
      command =   'gzip -f '+ newtotalimbfits_dir+ fifits2 
      if keyword_set( noexe) then begin
         if keyword_set( verb) then print, 'Not doing '+ command 
      endif else begin
         if keyword_set( verb) then print, 'Doing '+ command
         spawn, command, res, /stderr, /sh
         if keyword_set( verb) then print,  res
      endelse
   endif  ; end case of updp
endelse         ; end case of updp/cfits                

; Delete previous files and Compress the new ones
;; command =   'rm -f '+ totalimbfits_dir+ fifits1+ '.gz'
;; if keyword_set( noexe) then begin
;;    if keyword_set( verb) then print, 'Not doing '+ command 
;; endif else begin
;;    if keyword_set( verb) then print, 'Doing '+ command
;;    spawn, command, res, /stderr, /sh
;;    if keyword_set( verb) then print,  res
;; endelse
command =   'gzip -f '+ totalimbfits_dir+ fifits1 
if keyword_set( noexe)  or keyword_set( noimb) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command
   spawn, command, res, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse

command =   'gzip -f '+ totalimbfits_dir+ fifits2 
if keyword_set( noexe)  or keyword_set( noimb) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command
   spawn, command, res, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse



; Clear out memory
delvarx, strdat
scanprocduration =  ' in '+ string( (systime( /second) - timebeg),  $
                            format = '(1f10.2)')+ ' seconds, '
print, 'Scan processed:  ' + file+ scanprocduration
goto,  DONE

NOPROC: print, 'No processing, File is not a scan ', file
DONE: 

return
end
