;+
;
; SOFTWARE:
;        NIKA pipeline
;
; NAME:
;        nk_check_scan_list
;
; CATEGORY:
;        initialization
;
; CALLING SEQUENCE:
;        nk_check_scan_list, scan_list_in, scan_list_out, $
;        antenna_file, rawdata_file, xml_file, [FORCE=]
; 
; PURPOSE:         Check if the list of requested scans is valid
; 
; INPUT: 
;        - scan_list_in: The list of scans to be used as a string vector
;        e.g. ['20140221s0024', '20140221s0025', '20140221s0026']
; 
; OUTPUT: 
;        - scan_list_out: The list of days and scans without unvalid
;          scans
;        - day: the list of days (e.g. 20140223)
;        - scan_num: the list of scan number (e.g. 23)
;        - antenna_file: the corresponding string list of antenna IMBFITS file
;        - rawdata_file: the corresponding string list of raw data file
;        - xml_file: the corresponding string list of xml (input to PAKO) file
; 
; KEYWORDS:
;        - FORCE: Use this keyword to force the list of scans used
;          instead of checking if they are valid
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 04/03/2014: creation form check_scan_exist.pro
;-


pro nk_check_scan_list, scan_list_in, $  
                        scan_list_out, $ 
                        day, $
                        scan_num, $
                        antenna_file, $ 
                        rawdata_file, $
                        FORCE=FORCE, info=info, ok_scans=ok_scans
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_check_scan_list, scan_list_in, $"
   print, "                        scan_list_out, $"
   print, "                        day, $"
   print, "                        scan_num, $"
   print, "                        antenna_file, $"
   print, "                        rawdata_file, $"
   print, "                        FORCE=FORCE, info=info"
   return
endif

Nscans       = n_elements(scan_list_in)
flag_scans   = bytarr(Nscans)

antenna_file = strarr(Nscans)
rawdata_file = strarr(Nscans)
name2num, scan_list_in, day, scan_num  

;;========== Get the files and flag missing
for iscan=0, Nscans-1 do begin
   nk_scan2run, strtrim(day[iscan],2)+"s"+strtrim(scan_num,2), run
   fill_nika_struct, run

   nk_find_raw_data_file, scan_num[iscan], day[iscan], file, imb_fits_file, xml_file, /NOERROR, /SILENT

   ;; imbfits file are mandatory for Run8
;   if long(!nika.run) eq 8 then begin
      if file ne "" and imb_fits_file ne "" then flag_scans[iscan] = 1
;   endif else begin
;      if file ne "" then flag_scans[iscan] = 1
;   endelse

   rawdata_file[iscan] = file
   antenna_file[iscan] = imb_fits_File
endfor 

ok_scans = where(flag_scans gt 0, Nok_scans, comp=bad_scans)

;;========== Take only the good scans
if Nok_scans gt 0 then begin
   if not keyword_set(FORCE) then scan_list_out = scan_list_in[ok_scans] else scan_list_out = scan_list_in
   if not keyword_set(FORCE) then day = day[ok_scans]
   if not keyword_set(FORCE) then scan_num = scan_num[ok_scans]
   if not keyword_set(FORCE) then antenna_file = antenna_file[ok_scans]
   if not keyword_set(FORCE) then rawdata_file = rawdata_file[ok_scans]
endif else begin
   if keyword_set(info) then begin
      nk_error, info, 'None of the input scans exist on this disk.'
      return
   endif else begin
      message, /info, 'None of the input scans exist on this disk.'
   endelse
endelse

if nok_scans ne nscans then begin
   if keyword_set(info) then begin
      nk_error, info, 'The following scans do not exist: '+strtrim( scan_list_in[bad_scans],2)+", ", status=2
   endif else begin
      message, /info, 'The following scans do not exist: '
      message, /info, strjoin( string( scan_list_in[bad_scans], format = '(A25)'))
   endelse
endif

end
