;+
; 
; SOFTWARE: 
;        Extra routine used by NIKA pipeline
; 
; PURPOSE: 
;        Get the scan list and the day list from the formated list
; 
; INPUT: 
;        - scan_list: The list of scans to be used as a string vector
;        e.g. ['20140221s0024', '20140221s0025', '20140221s0026']
; 
; OUTPUT: 
;        - day: the day list, e.g. [20140221, 20140221, 20140221]
;        - scan_num: the scan number list, e.g. [24, 25, 26]
; 
; KEYWORDS:
;        
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
; 
;-

pro name2num, scan_name, day, scan_num

  nscans = (size(scan_name, /dim))[0]

  if nscans ge 2 then begin
     day      = lonarr( nscans)
     scan_num = lonarr( nscans)
     for i=0, nscans-1 do begin
        r           = strsplit( scan_name[i], "s", /extract)
        day[i]      = r[0]
        scan_num[i] = r[1]
     endfor
  endif else begin
     r        = strsplit( scan_name, "s", /extract)
     day      = long(r[0])
     scan_num = long(r[1])
  endelse

end

