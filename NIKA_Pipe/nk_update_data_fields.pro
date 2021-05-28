
;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME:
; nk_update_data_fields
; 
; PURPOSE: 
;        1. Replaces the tag rf_didq by toi in the NIKA data structure
;        2. adds dra and ddec
; 
; INPUT: 
;        - data
; 
; OUTPUT: 
;        - data: data.rf_didq becomre data.toi
; 
; KEYWORDS:
; 
; MODIFICATION HISTORY: 
;        - June 3rd, 2014: (Nicolas Ponthieu -
;          nicolas.ponthieu@obs.ujf-grenoble.fr)
;        - Oct. 2015: included polarization fields for NIKA2, NP
;-
;====================================================================================================

pro nk_update_data_fields, param, info, data, kidpar, katana=katana


if n_params() lt 1 then begin
   message, /info, "calling sequence:"
   print, 'nk_update_data_fields, param, info, data, kidpar, katana=katana'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

tags  = tag_names(data)
ntags = n_elements(tags)
;; w_input_tags = where( strupcase(tags) ne "RF_DIDQ", nw_input_tags)
w_input_tags = where( strupcase(tags) ne "TOI", nw_input_tags)

if nw_input_tags eq 0 then begin
   message, /info, "Wrong fields requested for data, you need at least pointing info in addition to toi/rf_didq"
   message, /info, "Current data tags are: "+tags
   stop
endif else begin

   ;; Deal with polarization and changes in tag names
   w_position = where( strupcase( tags) eq "POSITION", nw_position)
   if nw_position ne 0 then begin
      p = 0
      i = 0
      ;; Now really check if the HWP was rotating correctly
      while p eq 0 and i le n_elements(w_position)-1 do begin
         if max(abs(data.(w_position[i]))) lt 100 then begin
            info.polar =  0
            info.hwp_rot_freq = 0.d0
         endif else begin
            nsn = n_elements(data)
            med = median( data.(w_position[i]))
            w = where( abs(data.(w_position[i])-med) lt 1, nw)
            if float(nw)/nsn lt 0.5 then begin
               if keyword_set(prism) then info.polar = 2 else info.polar = 1
            endif
            nk_get_hwp_rot_freq, data, rot_freq_hz
            info.hwp_rot_freq = rot_freq_hz

            p = 1
         endelse
         i++
      endwhile
   endif

;;    if !db.lvl eq 1 then begin
;;       message, /info, "FORCING THE SCAN TO BE CONSIDERED UNPOLARIZED !!"
;;       info.polar = 0
;;    endif

   
   if param.lab_polar ne 0 then info.polar = param.lab_polar
   
   if info.polar ge 1 then begin
      ;; If the pipeline was not called in a polarized mode from the beginning,
      ;; some fields were not created in read_nika and have to be added here (at
      ;; the expense of memory duplication during the operation).
      ;; NP, Feb. 15th, 2016
      wq = where( strupcase(tags) eq "TOI_Q", nwq)
      if nwq eq 0 then begin
         message, /info, "You could save time and memory by calling nk with '/polar' for this scan "+param.scan
         data_out = data[0]
         data_out = create_struct( data_out, $
                                   "toi_q", data[0].toi*0.d0, $
                                   "toi_u", data[0].toi*0.d0, $
                                   "w8_q", data[0].toi*0.d0, $
                                   "w8_u", data[0].toi*0.d0, $
                                   "cospolar", 0.d0, $
                                   "sinpolar", 0.d0)
         ;; Upgrade to number of elements
         data_out = replicate( data_out, n_elements(data))
         ;; Copy each field of the input data
         tags_out = tag_names(data_out)
         my_match, tags_out, tags, suba, subb
         for i=0, n_elements(suba)-1 do data_out.(suba[i]) = data.(subb[i])
         data = temporary(data_out)
      endif
   endif
   
   if strupcase( strtrim(!nika.run,2)) eq "CRYO" or $
      strupcase( string( !nika.run,2)) eq '5' then data.a_t_utc = data.b_t_utc

endelse

if param.cpu_time then nk_show_cpu_time, param

end
