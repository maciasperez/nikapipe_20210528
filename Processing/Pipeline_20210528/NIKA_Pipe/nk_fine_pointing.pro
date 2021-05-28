
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_fine_pointing
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_fine_pointing, param, info, data, kidpar
; 
; PURPOSE: 
;        Apply fine pointing corrections to data.ofs_az and data.ofs_el
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the nika data structure
;        - kidpar: the kids strucutre
; 
; OUTPUT: 
;        - data.ofs_az, data.ofs_el
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov. 12th, 2014: FXD & NP (extracted from nk_get_kid_pointing)
;        - Sept. 22nd, 2015: FXD & NP corrected bug on azprec definition in
;          the case of info.systemof eq "PROJECTION"
;-
;===============================================================================================

pro nk_fine_pointing, param, info, data, kidpar
  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if param.fine_pointing ne 0 then begin

   nkids = n_elements(kidpar)

   elprec = data.antyoffset*!radeg*3600.
   azprec = data.antxoffset*!radeg*3600.*cos(data.el)
   if strupcase(info.systemof) eq "PROJECTION" and long(!nika.run) ge 11 then begin
      azprec = data.antxoffset*!radeg*3600.d0
   endif

;;     message, /info, "fix me:"
;;     wind, 1, 1, /free
;;     !p.multi=0
;;     plot, data.ofs_az, data.ofs_el, /iso, title=info.systemof+", "+param.scan
;;     oplot, azprec, elprec, col=150
;;     stop

   ;; If difference too large, then keep the commanded pointing
   w = where( abs(azprec-data.ofs_az) gt 4., nw)
   if nw ne 0 then azprec[w] = data[w].ofs_az
   data.ofs_az = azprec

   ;; ditto
   w = where( abs(elprec-data.ofs_el) gt 4., nw)
   if nw ne 0 then elprec[w] = data[w].ofs_el
   data.ofs_el = elprec

   ;; Try to add finer corrections
   traz = data.anttrackaz*!radeg*3600.*cos(data.el)
   trel = data.anttrackel*!radeg*3600.
   gd = where( sqrt(traz^2+trel^2) le 10. $
               and data.mjd ne 0 and data.antxoffset ne 0, ngd)
   case param.fine_pointing of 
      ;; if 1, then do nothing more than apply azprec and elprec
      1: if param.silent eq 0 then message, /info, 'Param.Fine_Pointing case of '+strtrim(param.fine_pointing, 2)

      ;; if more thant 2, then add extrac corrections
      2: begin
         if param.silent eq 0 then message, /info, 'Param.Fine_Pointing case of '+strtrim(param.fine_pointing, 2)
         ;; Add traz and trel
         data[gd].ofs_az = data[gd].ofs_az + traz[gd]
         data[gd].ofs_el = data[gd].ofs_el + trel[gd]
      end
      3: begin
         if param.silent eq 0 then message, /info, 'Param.Fine_Pointing case of '+strtrim(param.fine_pointing, 2)
         ;; Remove traz and trel
         data[gd].ofs_az = data[gd].ofs_az - traz[gd]
         data[gd].ofs_el = data[gd].ofs_el - trel[gd]
      end
      4: begin
         if param.silent eq 0 then message, /info, 'Param.Fine_Pointing case of '+strtrim(param.fine_pointing, 2)
         ;; Add traz remove trel
         data[gd].ofs_az = data[gd].ofs_az + traz[gd]
         data[gd].ofs_el = data[gd].ofs_el - trel[gd]
      end
      5: begin
         if param.silent eq 0 then message, /info, 'Param.Fine_Pointing case of '+strtrim(param.fine_pointing, 2)
         ;; Remove traz and add trel
         data[gd].ofs_az = data[gd].ofs_az - traz[gd]
         data[gd].ofs_el = data[gd].ofs_el + trel[gd]
      end
      else: if param.silent eq 0 then message, /info, 'This param.fine_pointing case not built yet'+strtrim(param.fine_pointing, 2)
   endcase

;; Commented out to avoid duplication of "data" and then save memory.
;; NP, Feb. 15th, 2016
;;   rm_fields = ['antxoffset', 'antyoffset', 'anttrackaz', 'anttrackel']
;;   nk_shrink_data, param, info, data, kidpar, rm_fields=rm_fields
endif

if param.cpu_time then nk_show_cpu_time, param, "nk_fine_pointing"
   
   
end
