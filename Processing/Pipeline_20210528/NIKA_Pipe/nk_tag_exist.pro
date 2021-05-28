;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_tag_exist
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         r = nk_tag_exist( structure, tag, tag_index)
; 
; PURPOSE: 
;        Checks if a given tag is present in a structure and if yet,
;returns its index
; 
; INPUT: 
;        - structure
; 
; OUTPUT: 
;        - r=1 if the tag is present, 0 if not
;        - tag_index: the tag index :)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Jan. 27th, 2016: NP
;-

function nk_tag_exist, str, tag, tag_index

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   message, /info, "r = nk_tag_exist( str, tag, tag_index)"
   return, -1
endif

str_tags = tag_names(str)
w = where( strupcase( str_tags) eq strupcase(tag), nw)
if nw eq 0 then begin
   r = 0
   tag_index = -1
endif else begin
   r = 1
   tag_index = w[0]
endelse

return, r

end
