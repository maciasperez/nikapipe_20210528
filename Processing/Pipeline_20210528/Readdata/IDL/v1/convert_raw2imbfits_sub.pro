pro convert_raw2imbfits_sub, file, imb_dir = imb_dir,  $
                             noexe = noexe,  verb = verb,  ftp = ftp

if n_params() eq 0 then begin
  message, /info, 'Call with : convert_raw2imbfits_sub, '
  message, /info, '  file(dir included) [, ' + $
           'imb_dir = imb_dir,  /noexe, /ftp] '
  return
endif
; Used by convert_fits_files2 or as a standalone program for one given file
; (give full name including directory)

; Write that message in any case (verb=1 or not)
print, 'Start processing ' + file
if not keyword_set( imb_dir) then imb_dir ='/NikaData/'
;;; initial
; list_data = 'sample MJD subscan scan I Q dI dQ RF_didq F_TONE DF_TONE retard 49'
;;; with official shift by Nicolas
list_data = "sample MJD subscan scan I Q dI dQ RF_didq retard "+ $
            strtrim( !nika.retard,2)+" F_TONE DF_TONE"

dirin = file_dirname( file)
dirout = imb_dir
filebase = file_basename( file)
;;filein = 'AB' + strmid( filebase,  1) + '.txt'
;;fileA = dirin +'/' + filein
;;if keyword_set( verb) then print,  fileA
;;command = 'touch '+ fileA 
; This mechanism is not used anymore
;; if keyword_set( noexe) then begin
;;    if keyword_set( verb) then print, 'Not doing '+ command 
;; endif else begin
;;    if keyword_set( verb) then print, 'Doing '+ command
;; ;   spawn, command
;; endelse
on_ioerror, NOPROC              ; case of a file not corresponding to a scan

str2 = strsplit(filebase,'_',/extract)
date = str2[1]+str2[2]+str2[3]
scan_num = strtrim(long(str2[5]),2) 
if scan_num le 0 then goto,  NOPROC
; here the "not a scan" file case is handled

list_data = 'all'
                                ;stop
status =  READ_NIKA_BRUTE( file, param_c, kidpar, strdat, units, periode, $
                           list_data=list_data,  read_type = 12, /silent)

; 12 means that only the valid kid and offs are kept

; Prepare and correct data here
nscan = round( median( strdat.scan))
nsubscan = round( max( strdat.subscan))
if nsubscan ge 1 then begin     ; true scan file
   fileout = nika_transform_iram_name( filebase, nscan, $
                                       k_nscan = nscanfile,  teltime = teltime)
   
   if keyword_set( verb) then $
      print,   'convert_raw2imbfits ', dirin, '  ',  filebase, ' Into '
   if keyword_set( verb) then $
      print, dirout, fileout
   ndeg = 3                     ; 0 if pf is done before
   convert_str2imbfits, dirin, filebase, param_c, kidpar, strdat, $
                        dirout, fileout, ndeg, noexe = noexe,  verb = verb
endif

; Produce Total imbfits files
command = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/ssh_for_imbfits.sh '+ $
          date + ' ' + scan_num + ' ' + scan_num + $
          ' >> /home/archeops/temp/log/ssh_for_imbfits.log'
if keyword_set( verb) then $
   print, ' Making telescope imbfits and combining with NIKA data: '
if keyword_set( noexe) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command 
   spawn, command
endelse 

; Transfer antenna fits first to sami
;antennafile = '"/mrt-lx3/vis/t21/observationData/imbfits/'+'*antenna*'+ $
;              date+ '*'+strtrim(scan_num, 2) +'*.fits"'
antennafile = '/mrt-lx3/vis/t21/observationData/imbfits/iram30m-antenna-'+ $
              date+ 's'+strtrim(scan_num, 2) +'-imb.fits'

command1 = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/' + $
           'ssh_check_antenna_imbfits.sh '+ antennafile ;+ $
;           ' >> /home/archeops/temp/log/ssh_check_antenna_imbfits.log'

command2 = "scp 't21@mrt-lx3.iram.es:"+ antennafile + "' $IMB_FITS_DIR/"+ $
           ' >> /home/archeops/temp/log/scp_antenna_imbfits.log '
if keyword_set( noexe) then begin
   if keyword_set( verb) then print, 'Not done '+ command1+ ' AND '+ command2
endif else begin
   if keyword_set( verb) then $
      print, 'Doing ' + command1 + ' AND '+ command2
                                ; Check antenna files are available
   spawn, command1, res, /stderr, /sh
   if keyword_set( verb) then print,  res
   spawn, command2, res, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse

; Here send something to the ftp site
totalimbfits_dir = '/home/archeops/NIKA/Data/TotalImbfits/'
fifits1 = "iram30m-NIKA1mm-"+date+ "s"+scan_num+ "-imb.fits"
fifits2 = "iram30m-NIKA2mm-"+date+ "s"+scan_num+ "-imb.fits"

; First copy the total imbfits files to sami
command = 'scp t21@mrt-lx3.iram.es:' + $
          '/mrt-lx3/vis/t21/observationData/imbfits/'+ $
          fifits1 + ' '+ totalimbfits_dir+ $
          ' >> /home/archeops/temp/log/scp_total_imbfits1.log '
if keyword_set( noexe) then begin
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
if keyword_set( noexe) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command
   spawn, command, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse


command = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/lftp_sami2neel.sh ' + $
          'NikaRun6AllData TotalImbfits ' + totalimbfits_dir+ fifits1 + $
          ' ' + fifits1 + $
          ' >> /home/archeops/temp/log/lftp_total_imbfits1.log   &  '
if keyword_set( noexe) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command 
   spawn, command, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse

command = '$NIKA_SOFT_DIR/NIKA_lib/Readdata/IDL/lftp_sami2neel.sh ' + $
          'NikaRun6AllData TotalImbfits ' + totalimbfits_dir+ fifits2 + $
          ' ' + fifits2 + $
          ' >> /home/archeops/temp/log/lftp_total_imbfits2.log   &  '
if keyword_set( noexe) then begin
   if keyword_set( verb) then print, 'Not doing '+ command 
endif else begin
   if keyword_set( verb) then print, 'Doing '+ command
   spawn, command, /stderr, /sh
   if keyword_set( verb) then print,  res
endelse

; Clear out memory
delvarx, strdat
print, 'Scan processed:  ' + file
goto,  DONE

NOPROC: print, 'No processing, File is not a scan ', file
DONE: 

return
end
