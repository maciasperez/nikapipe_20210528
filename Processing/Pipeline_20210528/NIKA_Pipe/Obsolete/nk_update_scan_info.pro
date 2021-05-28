
;+
;
; SOFTWARE:
;
; NAME:
; nk_update_scan_info
;
; CATEGORY: general
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Updates info parameters with relevan scan information
; 
; INPUT: 
;      - scan: e.g '20140219s205'
; 
; OUTPUT: 
;     - param and info are updated
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 13th, 2014: Nicolas Ponthieu
;-
;================================================================================================

pro nk_update_scan_info, param, info, focus_liss_new, xml = xml

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

message, /info, "Obsolete, use nk_update_param_info instead."
stop


;;info.status   = 0
;;info.scan     = param.scan
;;info.day      = param.day
;;info.scan_num = param.scan_num
;;
;;focus_liss_new = 0 ; default
;;if param.lab eq 0 and param.make_imbfits eq 0 then begin
;;
;;   if keyword_set(xml) then begin
;;      parse_pako, param.scan_num, param.day, pako_str
;;
;;      info.obs_type    = pako_str.OBS_TYPE
;;      info.proj_type   = pako_str.systemoffset
;;
;;      info.focusz = pako_str.focusZ
;;
;;      info.nasmyth_offset_x = pako_str.nas_offset_x
;;      info.nasmyth_offset_y = pako_str.nas_offset_y
;;
;;      info.p2cor = pako_str.p2cor
;;      info.p7cor = pako_str.p7cor
;;
;;      if strupcase( strtrim( pako_str.obs_type, 2)) eq "LISSAJOUS" and $
;;         strupcase( strtrim(pako_str.purpose,2)) eq "FOCUS" then focus_liss_new = 1
;;
;;   endif else begin
;;      if file_test( param.file_imb_fits) then begin 
;;      ;; Retrieve info from IMBfits
;;         ant1 = mrdfits( param.file_imb_fits, 1, head_ant1, /silent)
;;         ant2 = mrdfits( param.file_imb_fits, 2, head_ant2, /silent)
;;         
;;         info.tau225      = sxpar( head_ant1, 'TIPTAUZ')
;;         info.pressure    = sxpar( head_ant1, 'PRESSURE')
;;         info.temperature = sxpar( head_ant1, 'TAMBIENT')
;;         info.humidity    = sxpar( head_ant1, 'HUMIDITY')
;;         info.wind_speed  = sxpar( head_ant1, 'WINDVEL')
;;         
;;         info.obs_type    = sxpar( head_ant2, 'OBSTYPE')
;;         info.proj_type   = sxpar( head_ant2, "systemof")
;;         
;;         info.longobj     = sxpar( head_ant1, "longobj") ; degrees
;;         info.latobj      = sxpar( head_ant1, "latobj")  ; degrees
;;         
;;         info.focusx = sxpar( head_ant1, "FOCUSX")
;;         info.focusy = sxpar( head_ant1, "FOCUSY")
;;         info.focusz = sxpar( head_ant1, "FOCUSZ")
;;         
;;         info.nasmyth_offset_x = ant1.(1)*!radeg*3600
;;         info.nasmyth_offset_y = ant1.(2)*!radeg*3600
;;         
;;         info.p2cor = sxpar( head_ant1, "P2COR")*!radeg*3600
;;         info.p7cor = sxpar( head_ant1, "P7COR")*!radeg*3600
;;      endif else begin
;;         message, /info, 'No antenna imbfits!'
;;      endelse
;;      
;;   endelse
;;
;;endif

end
