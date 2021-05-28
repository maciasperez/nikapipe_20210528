;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME:
; nk_check_list_data
; 
; PURPOSE: 
;        Checks the coherence of the list of variables to read in the NIKA raw data.
; 
; INPUT: 
;        NONE
; 
; OUTPUT: 
;        - list_data (keyword)
; 
; KEYWORDS:
;        - LIST_DATA: the list of variables to be put in the data structure
;        - RETARD: a retard between NIKA and telescope data
;        - EXT_PARAMS: extra variables to be put in the data structure
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_getdata.pro 
;        (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;        - Nov. 12th, 2014: add B_T_UTC by default, NP and FXD
;-
;====================================================================================================

pro nk_check_list_data, param, info, list_data=list_data, retard=retard, ext_params=ext_params

;; Init retard
if not keyword_set(retard) then retard = !nika.retard

;; Init list_data
if not keyword_set( list_data) then begin

   ;; put rf_didq back for cross-checks, Sept. 19th, 2016
   list_data = "sample subscan scan El retard "+strtrim(retard,2) + $
               " Az Paral scan_st MJD LST"+$
               " k_flag RF_didq "
   if strupcase(!nika.acq_version) eq "V1" or strupcase(!nika.acq_version) eq "ISA" then begin
      list_data += "ofs_Az ofs_El "
   endif else begin
      list_data += "ofs_X ofs_Y "
   endelse

   if long(!nika.run) ge 13 then begin
      letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
                'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u']
   endif else begin
      letter = ['a', 'b']
   endelse


   for ii = 0, n_elements(letter)-1 do begin
      ll = strupcase(letter[ii])
      list_data += ll+"_masq "
   endfor

   ;; temporary fix, we cannot look for synchro and position on all
   ;; boxes because the string length becomes too large to be passed
   ;; to the C.
   ;; For NIKA2's 1st run, we know it's either O or Q, we limit to
   ;; this
   list_data += 'C_position C_synchro O_position O_synchro Q_position Q_synchro U_position U_synchro'
   
   list_data += " F_tone dF_tone I Q dI dQ"
   list_data += " pI pQ"
   
;;    ;; a_t_utc does not exist for run5
;;    if long(!nika.run) gt 5 then list_data = list_data + " A_t_utc B_t_utc" else list_data=list_data+" B_t_utc"

   if strupcase(!nika.acq_version) eq "V1" then begin
      ;; Add other boxes to check synchronization
      ;; NP, Feb. 5th, 2016
      list_data = list_data + " A_t_utc"
      list_data = list_data + " A_pps"
      list_data = list_data + " A_o_pps"
      for ii = 1, n_elements(letter)-1 do begin
         ll = strupcase(letter[ii])
         list_data += " "+ll+"_t_utc"
         list_data += " "+ll+"_pps"
         list_data += " "+ll+"_o_pps"
      endfor
   endif else begin
      ;; March 2018
      for ii=0, n_elements(letter)-1 do begin
         ll = strupcase(letter[ii])
         ;; list_data += " "+ll+"_HOURS "+ll+"_TIME_PPS"
         list_data += " "+ll+"_time "+ll+"_time_pps"
      endfor
   endelse

   ;; undersampled data if present
   list_data += ' X_tbm'; X_tstill X_t4kinj X_t4k X_tPT1 X_tPT2X_pinj X_pasp X_HP400speed X_l1c X_l2c X_l3c X_l4c'
   
endif


my_list_data = strsplit( list_data, " ", /extract)

;; Make sure that retard is passed once and only once to list_data
w = where( strupcase( my_list_data) eq "RETARD", nw)
if nw eq 0 then list_data = list_data+" retard "+strtrim(retard,2)

;; Make sure that ext_params are passed once and only once to list_data
if keyword_set(ext_params) then begin
   for i=0, n_elements(ext_params)-1 do begin
      w = where( strupcase( my_list_data) eq strupcase( ext_params[i]), nw)
      if nw eq 0 then list_data = list_data+" "+ext_params[i]
   endfor
endif

end
