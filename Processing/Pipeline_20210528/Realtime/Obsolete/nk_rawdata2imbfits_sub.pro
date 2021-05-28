pro nk_rawdata2imbfits_sub, file, status, imb_dir = imb_dir,  $
                              noexe = noexe,  verb = verb,  $
                              ftp = ftp, lpsc = lpsc, $
                              updp = updp, nowait = nowait, $
                              noimb = noimb, cfits = cfits

; FXD October 2014, start from convert2_raw2imbfits_sub
; adapt to nk pipeline progressively

if n_params() eq 0 then begin
  message, /info, 'Call with : nk_rawdata2imbfits_sub, '
  message, /info, '  file(dir included) [, ' + $
           'imb_dir = imb_dir,  /noexe, /ftp,/lpsc] '
  return
endif
; Used by nk_rawdata2imbfits.pro or as a standalone program for one given file
; (give full name including directory)

; Write that message in any case (verb=1 or not)
status = 0  ; init at good
print, 'Start processing ' + file
timebeg = systime( /second)
; Make sure /NikaData is mounted (see archeops .cshrc)
if not keyword_set( imb_dir) then imb_dir ='/NikaData/'
;;; initial

dirin = file_dirname( file)
dirout = imb_dir
filebase = file_basename( file)
on_ioerror, NOPROC              ; case of a file not corresponding to a scan

str2 = strsplit(filebase,'_',/extract)
date = str2[1]+str2[2]+str2[3]
if !nika.run le 10 then stop, 'That should not happen in 2015'

if !nika.run le 10 or date ge '20150126' then begin
   scan_num = strtrim(long(str2[5]),2) 
endif else begin  ;bug fixing during the technical time
   if n_elements( str2) lt 11 then scan_num = 0 else $
      scan_num = strtrim(long(str2[9]),2) 
endelse
if keyword_set( verb) then print, filebase,  ' scan_num ', scan_num

if scan_num le 0 then goto,  NOPROC
; here the "not a scan" file case is handled

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

; Check that it is equal No it is not. But it does not matter
if keyword_set( verb) then print, scan_num,  ' ', date
file2scan_day,  file, scan_num2, day
if keyword_set( verb) then print, scan_num2, ' ', day

; ----------------------------- 
scan_name = date+ 's'+scan_num
nk_default_param, param
nk_init_info, param, info
; Use now
info.status = 0
param.silent= 1 - keyword_set( verb) 
param.do_plot = 0 ; no plot
;; Update param for the current scan
;nk_update_scan_param, scan_name, param, info
nk_update_param_info, scan_name, param, info
;; Get the data and KID parameters
; Do not search for antenna imbfits (it is not yet produced !) for raw imbfits
if keyword_set( cfits) then begin
   param.make_imbfits = 0
   xml = 0
   param.imbfits_ptg_restore =  1  ; 0=default (for run11 it is a must)
   param.fine_pointing =  0
   endif else begin
      param.make_imbfits = 1
      xml = 1
   endelse
; TEMPORARY for test on bambini
; xml = 0

nk_getdata, param, info, strdat, kidpar, param_c = param_c, xml = xml

if info.status ge 1 then begin
   ;;Case of a bad scan
   status = info.status
endif
; Some kidpar are put at 3

if info.polar eq 1 then param.polar_lockin_freqhigh = 0.9*info.hwp_rot_freq

; reference kidpar containing 5 for double-kids (or anomalous), 1 for ok, 2
; for off-reso. No zero-signal channels.
; kidpar.array = 1 (1mm), 2 (2mm) 
; original kidpar can be retrieved by setting param.kid_file.a='' idem for b.
; Prepare true MJD (communicate to Nicolas).

; -----------------------------

;Init imbfits file names
totalimbfits_dir = '/home/archeops/NIKA/Data/TotalImbfits/'
fifits1 = 'iram30m-NIKA1mm-'+date+ 's'+scan_num+ '-imb.fits'
fifits2 = 'iram30m-NIKA2mm-'+date+ 's'+scan_num+ '-imb.fits'

;;;;if keyword_set( updp) or keyword_set( cfits) then begin
if keyword_set( updp) then begin
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
nstrdat = n_elements( strdat)
if nstrdat le 10 then begin
   nscan = -1
   nsubscan = 0
endif else begin
   nscan = round( median( strdat.scan))
   nsubscan = round( max( strdat.subscan))
endelse

if keyword_set( verb) then print, 'ndat = ', nstrdat, ', nsubscan = ',  nsubscan

if nsubscan ge 1 then begin     ; true scan file
   fileout = nika_transform_iram_name( filebase, nscan, $
                                       k_nscan = nscanfile,  teltime = teltime)
   
   if keyword_set( updp) then begin
      if keyword_set( verb) then $
         print,   'nk_rawdata2imbfits_sub2 ', dirin, '  ',  filebase, ' Into '
      if keyword_set( verb) then $
         print, totalimbfits_dir, fifits2
      nk_rawdata2imbfits_sub2, dirin, filebase, param_c, kidpar, strdat, $
                            totalimbfits_dir, fifits2, info = info, $
                            noexe = noexe,  verb = verb, $
                            updp = updp
   endif else begin
         if keyword_set( cfits) then fout = fifits2 else fout = fileout
         if keyword_set( verb) then $
            print,   'nk_rawdata2imbfits_sub2 ', dirin, '  ',  filebase, ' Into '
         if keyword_set( verb) then $
            print, dirout, fileout
                      ; truncate the data to the useful part in this routine 
         if keyword_set( cfits) then $
            nk_rawdata2imbfits_sub2, dirin, filebase, param_c, kidpar, strdat, $
                               dirout, fout, info = info, $
                               noexe = noexe,  verb = verb, $
                               cfits = [cfits, cfifits1, cfifits2] else $
            nk_rawdata2imbfits_sub2, dirin, filebase, param_c, kidpar, strdat, $
                               dirout, fout, info = info, $
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
if keyword_set( noexe)  or keyword_set( noimb) or keyword_set( cfits) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command
   spawn, command, res, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse

command =   'gzip -f '+ totalimbfits_dir+ fifits2 
if keyword_set( noexe)  or keyword_set( noimb) or keyword_set( cfits) then begin
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
