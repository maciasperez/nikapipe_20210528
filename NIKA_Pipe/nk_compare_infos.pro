
;+
;
; SOFTWARE:
;
; NAME:
; nk_compare_infos
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         r = nk_compare_infos( info, info1)
; 
; PURPOSE: 
;        Compares the key parameters of two pipeline parameter
;        structures. If they match, the two scans have been processed by the
;        same pipeline parameters and may be coadded.
; 
; INPUT:
;      - param, param1: the two structures to compare
; 
; OUTPUT: 
;     r = 0 if ok, anything else if there was a problem
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014: Nicolas Ponthieu
;-
;================================================================================================

function nk_compare_infos, info1, info2

;; Tags that must match for a coaddition in a pipeline
tags = ["xmap", $
        "ymap", $
        "mask_source"]

ntags = n_elements(tags)

r = 0 ; init
tags1 = tag_names(info1)
tags2 = tag_names(info2)
for itag=0, ntags-1 do begin

   ;; Check that info1 has the correct tags
   w1 = where( strupcase(tags1) eq strupcase( tags[itag]), nw1)
   if nw1 eq 0 then begin
      print, "missing tag "+strtrim( tags[itag],2)+" in info1"
      return, 2
   endif

   ;; Check that info2 has the correct tags
   w2 = where( strupcase(tags2) eq strupcase( tags[itag]), nw2)
   if nw2 eq 0 then begin
      print, "missing tag "+strtrim( tags[itag],2)+" in info2"
      return, 2
   endif

   ;; Check if they match
   if info1.nx ne info2.nx or info1.ny ne info2.ny then r = 1

end

return, r
end
