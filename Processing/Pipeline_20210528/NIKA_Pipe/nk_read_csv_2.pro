;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_read_csv_2
;
; CATEGORY: 
;
; CALLING SEQUENCE:
;        nk_read_csv_2, file, struct
; 
; PURPOSE: 
;        Reads a NIKA param.csv or info.csv (not photometry.csv) file
;        as produced by nk_save_scan_results_3.pro
; 
; INPUT:
;        file
; 
; OUTPUT: 
;        - struct: an array of structure with appropriate tags
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;          - NP, Apr. 2017
;-

pro nk_read_csv_2, csv_file, str

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_read_csv_2, csv_file, str"
   return
endif

str = -1 ; FXD
if file_test( csv_file) eq 0 then begin
   message,/info, 'That file '+ csv_file+ ' does not exist'
   return
endif

readcol, csv_file, type, tag, val, format='A,A,A', delim=',', comment='#', /silent
tag = strtrim(tag,2)

ntags = n_elements(tag)
for itag=0, ntags-1 do begin

   delvarx, v
   case strupcase( strtrim(type[itag],2)) of
      'BYTE':      v = byte(     val[itag])
      'INT':       v = long(     val[itag]) ; int(      val[itag])
      'LONG':      v = long(     val[itag])
      'FLOAT':     v = float(    val[itag])
      'DOUBLE':    v = double(   val[itag])
      'COMPLEX':   v = complex(  val[itag])
      'STRING':    v = strtrim(  val[itag],2)
      'DCOMPLEX':  v = dcomplex( val[itag])
      'UINT':      v = uint(     val[itag])
      'ULONG':     v = ulong(    val[itag])
      'LONG64':    v = long64(   val[itag])
      'ULONG64':   v = ulong64(  val[itag])
      else: message, "Unsupported format in "+csv_file+": type found: "+strtrim(type[itag],2)
   endcase

   if itag eq 0 then begin
      str = create_struct( tag[itag], v)
   endif else begin
      str = create_struct( str, tag[itag], v)
   endelse
endfor


end
