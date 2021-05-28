;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_info2csv
;
; CATEGORY: 
;
; CALLING SEQUENCE:
;        nk_info2csv, info, csv_file
; 
; PURPOSE: 
;        Writes a NIKA .csv file from the info structure
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;          - NP, Nov. 2nd, 2015
;-

pro nk_info2csv, info, csv_file

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_info2csv, info, csv_file"
   return
endif

info_tags  =  tag_names(info)
tag_length = strlen( info_tags)

w = where( strupcase( strmid(info_tags,0,6)) eq "RESULT", nw)

get_lun,  lu
openw, lu, csv_file
title_string = 'Scan, Source, FOTRANSL, RA, DEC'
;; If you add extra fields, also update nk_read_csv to avoid conversion errors
;; between strings and numbers.
res_string   = strtrim(info.scan,2)+", "+strtrim(info.object,2)+", "+strtrim(info.FOTRANSL,2)+", "+$
               strtrim(info.longobj,2)+", "+strtrim(info.latobj,2)
for i=0, nw-1 do begin
   title_string = title_string+", "+strmid( info_tags[w[i]], 7, tag_length[w[i]]-7)
   res_string   = res_string+", "+strtrim( info.(w[i]),2)
endfor
printf, lu, title_string
printf, lu, res_string
close, lu
free_lun, lu

end
