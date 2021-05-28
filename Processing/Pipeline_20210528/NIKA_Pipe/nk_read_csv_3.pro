;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_read_csv_3
;
; CATEGORY: 
;
; CALLING SEQUENCE:
;        nk_read_csv_3, file, struct
; 
; PURPOSE: 
;        Reads a NIKA .csv file that summarizes fluxes and scan
;information (as made by nk_log_iram_tel for example)
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
;          -FXD, March 2018
;-


pro nk_read_csv_3, csv_file, str

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_read_csv_3, csv_file, str"
   return
endif

if file_test( csv_file) lt 1 then begin
   message, /info, 'That file does not exist '+ csv_file
   return
endif

rds = read_csv( csv_file,  header = hd)
nlines = n_elements(rds.(0))
tag   = strtrim( hd, 2)
ntags  = n_elements(tag)

for itag=0, ntags-1 do begin
   delvarx, v
   typ = size(/type, rds.(itag)[0])
   case typ of
      1:      v = byte(    0)
      2:      v = long(    0)
      3:      v = long(    0)
      4:      v = float( 0)
      5:      v = double(0)
      6:      v = complex(0)
      7:      v = ''
      8:      v = dcomplex(0)
      9:      v = uint(0)
      10:     v = ulong(0)
      11:     v = long64(0)
      12:     v = ulong64(0)
      else: message, 'Unsupported format in '+csv_file+ ': type found: '+strtrim(typ,2)
   endcase
   if itag eq 0 then begin
      str = create_struct( tag[0], v)
   endif else begin
      str = create_struct( str, tag[itag], v)
   endelse
endfor
str = replicate( str, nlines)
for itag = 0, ntags-1 do begin
   str.(itag) = rds.(itag)
endfor


end
