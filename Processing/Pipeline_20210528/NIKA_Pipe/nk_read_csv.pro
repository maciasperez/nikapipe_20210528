;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_read_csv
;
; CATEGORY: 
;
; CALLING SEQUENCE:
;        nk_read_csv, file, struct
; 
; PURPOSE: 
;        Reads a NIKA .csv file that summarizes fluxes and scan information
; 
; INPUT: 
; 
; OUTPUT: 
;        - A structure with appropriate tags
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;          - NP, June 2015
;-


pro nk_read_csv, csv_file, str

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_read_csv, csv_file, str"
   return
endif

spawn, "cat "+csv_file, lines
nlines = n_elements(lines)
tags   = strtrim( strsplit( lines[0], ",", /extract), 2)
ntags  = n_elements(tags)

;; Scan and source, fotransl
str = create_struct( tags[0], tags[0], tags[1], tags[1], tags[2], tags[2])

;; Other tags
for i=3, ntags-1 do str = create_struct( str, tags[i], 0.d0)
str = replicate( str, nlines-1)

;; Fill structure line by line
for i=1, nlines-1 do begin
   string_values = strsplit( lines[i], ",", /extract)
   str[i-1].(0) = string_values[0] ; scan
   str[i-1].(1) = string_values[1] ; source
   str[i-1].(2) = string_values[2] ;fotransl
   if n_elements(string_values) ne ntags then stop
   for j=3, ntags-1 do str[i-1].(j) = double( string_values[j])
endfor

;;---------------------------------------------------------------
;; ;; Restore the current ascii template and tags
;; restore, !nika.off_proc_dir+"/csv_template.save"
;; ntags = long( n_elements(tags))
;; 
;; ;; Retrieve results
;; res = read_ascii( csv_file, template=nika_csv_template)
;; 
;; ;; Create the output structure with correct tag names
;; str = create_struct( tags[0], tags[0], tags[1], tags[1])
;; for i=2, n_elements(tags)-1 do str = create_struct( str, tags[i], 0.d0)
;; str = replicate( str, n_elements( res.(0)))
;; for i=0, n_elements(tags)-1 do str.(i) = res.(i)


end
