;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; NAME:
; nk_shrink_data
;
; PURPOSE: 
;        Removes useless fields from the data structure to same memory
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
;        - data: the data structure
;        - kidpar: the kid structure
; 
; OUTPUT: 
;        - data: data is modified
; 
; KEYWORDS:
;        - rm_fields: the list of fields to remove
; 
; MODIFICATION HISTORY: 
;        - June 11th, 2014: (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;-
;====================================================================================================

pro nk_shrink_data, param, info, data, kidpar, rm_fields=rm_fields


if not keyword_set(rm_fields) then begin
   return
endif else begin

   if info.status eq 1 then begin
   if param.silent eq 0 then       message, /info, "info.status = 1 from the beginning => exiting"
      return
   endif

   if param.cpu_time then param.cpu_t0 = systime(0, /sec)

   tags = tag_names(data)
   ntags = n_elements(tags)
   
   ;; Create the new structure
   ;; TOI is sure to be kept ;-)
   data_out = create_struct( "toi", data[0].toi)
   for i=0, ntags-1 do begin
      if strupcase(tags[i]) ne "TOI" then begin ; TOI is already in
         w = where( strupcase(rm_fields) eq strupcase(tags[i]), nw)
         if nw eq 0 then begin
            data_out = create_struct( data_out, tags[i], data[0].(i))
         endif
      endif
   endfor

   ;; Upgrade to number of elements
   data_out = replicate( data_out, n_elements(data))

   ;; Copy each field of the input data
   tags_out = tag_names(data_out)
   my_match, tags_out, tags, suba, subb
   for i=0, n_elements(suba)-1 do data_out.(suba[i]) = data.(subb[i])

   ;; ;; check
   ;; for i=0, n_elements(tags)-1 do begin
   ;;    w = where( strupcase(tags_out) eq strupcase(tags[i]), nw)
   ;;    if nw eq 0 then begin
   ;;       print, "missing tag : "+tags[i]
   ;;    endif else begin
   ;;       print, tags[i], ": diff minmax = ", minmax( data_out.(w)-data.(i))
   ;;    endelse
   ;; endfor

   ;; Update output
   data = temporary(data_out)

   if param.cpu_time then nk_show_cpu_time, param, "nk_shrink_data"

endelse


end
