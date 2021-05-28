;+
;
; SOFTWARE:
;
; NAME: 
; nk_xml2info
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;  nk_xml2info, scan_num, day, pako_str, info
;
; PURPOSE: 
;        Updates pako_str and info with relevant scan information
; 
; INPUT: 
;      - scan_num, day
; 
; OUTPUT: 
;     - pako_str, info
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - NP, Oct. 11th, 2015
;-
;================================================================================================

pro nk_xml2info, scan_num, day, pako_str, info, silent=silent

if n_params() lt 1 then begin
   message,  /info,  "Calling sequence:"
   print,  "nk_xml2info, scan_num, day, pako_str, info"
   return
endif

if info.status eq 1 then begin
   if not keyword_set(silent) then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

parse_pako, scan_num, day, pako_str

info.obs_type   = pako_str.OBS_TYPE
info.systemof   = pako_str.systemoffset

info.focusz = pako_str.focusZ

info.nasmyth_offset_x = pako_str.nas_offset_x
info.nasmyth_offset_y = pako_str.nas_offset_y

info.p2cor = pako_str.p2cor
info.p7cor = pako_str.p7cor

end
