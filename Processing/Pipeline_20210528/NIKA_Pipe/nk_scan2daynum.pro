;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; NAME:
; nk_scan2daynum
;
; PURPOSE: 
;        Extracts the day and scan number from the scan string
; 
; INPUT: 
;        - scan: string for the format YYYYMMDDsNUM
; 
; OUTPUT: 
;        - day: string
;        - scan_num: string
; 
; KEYWORDS:
;        
; MODIFICATION HISTORY: 
;        - NP, March 2015, from old IDLtools/scan2daynum
;-

pro nk_scan2daynum, scan_string, day, scan_num

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_scan2daynum, scan_string, day, scan_num"
   return
endif

if n_elements(scan_string) eq 1 then begin
   r        = strsplit( scan_string, "s", /extract)
   day      = r[0]
   scan_num = r[1]
endif else begin
   day      = scan_string
   scan_num = scan_string
   for i=0, n_elements(scan_string)-1 do begin
      r           = strsplit( scan_string[i], "s", /extract)
      day[i]      = r[0]
      scan_num[i] = r[1]
   endfor
endelse
end
