
;+
;
; SOFTWARE:
;
; NAME:
; nk_compare_params
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         r = nk_compare_params( param, param1)
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
;================================================================================================

function nk_compare_params, param1, param2, info, old=old
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_compare_params'
   return, 0
endif

r = 0                        ; init
tags1 = tag_names(param1)
tags2 = tag_names(param2)

if keyword_set(old) then begin
;; List of tags to compare
   tags = [ 'naive_projection', $ ;1, $            ; to bypass fits headers and astrometry
            'map_reso', $         ;4d0, $
            'map_xsize', $        ;300d0, $
            'map_ysize', $        ;300d0, $
            'map_proj', $         ;'RADEC', $
            'map_center_ra', $    ;0d0, $        ; output map center Ra
            'map_center_dec', $   ;0d0, $       ; output map center Dec
            'source']
   ntags = n_elements(tags)

   for itag=0, ntags-1 do begin

      ;; Check that param1 has the correct tags
      w1 = where( strupcase(tags1) eq strupcase( tags[itag]), nw1)
      if nw1 eq 0 then begin
         nk_error, info, "missing tag "+strtrim( tags[itag],2)+" in param1"
         return, 2
      endif

      ;; Check that param2 has the correct tags
      w2 = where( strupcase(tags2) eq strupcase( tags[itag]), nw2)
      if nw2 eq 0 then begin
         nk_error, info, "missing tag "+strtrim( tags[itag],2)+" in param2"
         return, 2
      endif

      ;; Check if they match
      if tags1[w1] ne tags2[w2] then r = 1
      if size(param1.(w1),/type) ne 7 then begin
         if param1.(w1) ne param2.(w2) then begin
            nk_error, info, "param1."+strtrim(tags1[w1[0]],2)+" does not match param2."+strtrim(tags2[w2[0]],2)+": "+ $
                      strtrim( param1.(w1[0]),2)+" /= "+strtrim(param2.(w2[0]),2)
            return,1
         endif
      endif
   endfor

endif else begin

   ntags1 = n_elements(tags1)
   ntags2 = n_elements(tags2)
   checked_tags2 = intarr(ntags2)
   for i=0, ntags1-1 do begin
      w = (where( strupcase( tags2) eq strupcase(tags1[i]), nw))[0]
      if nw ne 0 then checked_tags2[w] = 1
      for j=0, n_elements(param1.(i))-1 do begin
         if (param1.(i))[j] ne (param2.(w))[j] then print, "param1."+tags1[i]+"["+strtrim(j,2)+"] = "+strtrim((param1.(i))[j],2)+$
            " /= param2."+tags2[w]+"["+strtrim(j,2)+"] = "+strtrim((param2.(w))[j],2)
      endfor
   endfor
   w = where( checked_tags2 eq 0, nw)
   if nw ne 0 then begin
      for i=0, nw-1 do begin
         message, /info, "param2."+strtrim(tags2[w[i]],2)+" absent from param1"
         help, param2.(w[i])
      endfor
   endif

   

endelse



return, r
end
