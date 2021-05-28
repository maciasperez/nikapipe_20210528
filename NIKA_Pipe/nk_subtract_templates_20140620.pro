;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_subtract_templates_20140620
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_subtract_templates, param, info, data, kidpar, wsample, common_mode
; 
; PURPOSE: 
;        Regress and subtract templates from data.toi
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - templates_1mm and templates_2mm: templates to be subtracted at 1 and 2mm
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-
;=================================================================================================

pro nk_subtract_templates, param, info, data, kidpar, templates_1mm, templates_2mm

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_subtract_templates, param, info, data, kidpar, templates_1mm, templates_2mm"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn = n_elements(data)

for lambda=1, 2 do begin
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
   
   if nw1 ne 0 then begin
      if lambda eq 1 then templates = templates_1mm else templates = templates_2mm

      ;; Ensure that "templates" has the correct form for REGRESS
      s = size(templates)
      if s[0] eq 1 then templates = reform( templates, [1,nsn])

      ;; Perform the REGRESS
      for i=0, nw1-1 do begin
         ikid  = w1[i]

         if strupcase(param.decor_per_subscan) eq "YES" then begin

            for isubscan=min(data.subscan), max(data.subscan) do begin
               wsubscan = where( data.subscan eq isubscan, nwsubscan)
               toi = data[wsubscan].toi[w1]
               nk_subtract_templates_sub, info, $
                                          toi, $
                                          data[wsubscan].flag[w1], $
                                          data[wsubscan].off_source[w1], $
                                          templates
               data[wsubscan].toi[w1] = toi
            endfor 

         endif else begin       ; entire scan
            
            toi  = data.toi[w1]
            nk_subtract_templates_sub, info, $
                                       toi, $
                                       data.flag[w1], $
                                       data.off_source[w1], $
                                       templates
            data.toi[w1] = toi
         endelse                ; per subscan or on the entire scan
      endfor                    ; loop on kids
   endif                        ; if lambda is present
endfor                          ; loop on lambda

end
