;+
;
; SOFTWARE:
;
; NAME:
; nk_data_conventions
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;        nk_data_conventions, param, info, data, kidpar, param_c
; 
; PURPOSE: 
;        computes PF data if requested, parallactic angle and deals with numdet
;        conventions in kidpar.
; 
; INPUT:
;      - param, info, data, kidpar, param_c
; 
; OUTPUT: 
;     - data and kidpar are modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 2nd, 2014: Nicolas Ponthieu
;
;-
;================================================================================================

pro nk_data_conventions, param, info, data, kidpar, param_c, param_d, xoff=xoff

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;;------- Convert f_tone and df_tone to Hz
;; if tag_exist( data, 'f_tone')  then data.f_tone  *= 1d3
;; if tag_exist( data, 'df_tone') then data.df_tone *= 1d3
;; tag_exist is VERY slow when used on a large structure such as data
;; NP, Oct. 10th, 2015
tags = tag_names(data)
w = where( strupcase(tags) eq "F_TONE", nw)
if nw ne 0 then data.f_tone  *= 1d3
w = where( strupcase(tags) eq "DF_TONE", nw)
if nw ne 0 then data.df_tone  *= 1d3

;; Added, NP, Aug. 4th 2016
;;---------------------------------------
;; message, /info, "fix me"
;; w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
;; data1 = data
;; nk_iq2rf_didq, param, data, kidpar
;; for i=0, nw1-1 do begin
;;    ikid = w1[i]
;;    fit = linfit((shift(data1.toi[0],-49))[200:800], -data[200:800].toi[0])
;;    if abs(fit[1]-1.d0) ge 0.02 then print, ikid
;; endfor
;; stop
;;-----------------------------

if strupcase(param.math) eq "RF" then begin
   if param.alain_rf eq 0 then begin
      nk_iq2rf_didq, param, data, kidpar
   endif else begin
      ;; Keep alain's raw rf_didq
      w1 = where(kidpar.type eq 1, nw1)
      if nw1 gt 0 then data.toi[w1] = shift(data.toi[w1], 0, -49)
   endelse
endif

;;------- Replace RFdIdQ by the polynom if requested
if strupcase(param.math) eq "PF" or strupcase(param.math) eq "CF"  then begin
   !nika.pf_ndeg = 3

   if long(!nika.run) le 12 then begin
      if tag_exist( param_c, "AF_MOD")  then !nika.freqnorm1 = double( param_c.AF_MOD)*1000.d0 else !nika.freqnorm1 = 0.d0
      if tag_exist( param_c, "A_F_MOD") then !nika.freqnorm1 = double( param_c.A_F_MOD)        else !nika.freqnorm1 = 0.d0
      if tag_exist( param_c, "BF_MOD")  then !nika.freqnorm2 = double( param_c.BF_MOD)*1000.d0 else !nika.freqnorm2 = 0.d0
      if tag_exist( param_c, "B_F_MOD") then !nika.freqnorm2 = double( param_c.B_F_MOD)        else !nika.freqnorm2 = 0.d0
      freqnorm_vec = [!nika.freqnorm1, !nika.freqnorm2]
   endif else begin
;; Martino's email, Oct. 5th, 2015
;; Boites A, B, C, D = matrice 2mm
;; Boites E -> L = premiere matrice 1mm
;; Boites M -> T = premiere matrice 1mm
;; and array=2 for the 2mm, array=1 and 3 for the two 1mm matrices
;; Freqnorm_vec must be in this order because in nika_conviq2pf, this array is
;; refered to by kidpar.array-1.
      !nika.freqnorm1 = 0.d0
      !nika.freqnorm2 = 0.d0
      !nika.freqnorm3 = 0.d0
      if strupcase(!nika.acq_version) eq "V1" then begin
         if tag_exist( param_c, "E_F_MOD") then !nika.freqnorm1 = double( param_c.E_F_MOD)
         if tag_exist( param_c, "A_F_MOD") then !nika.freqnorm2 = double( param_c.A_F_MOD)
         if tag_exist( param_c, "M_F_MOD") then !nika.freqnorm3 = double( param_c.M_F_MOD)
      endif else begin
         if tag_exist( param_c, "ARRAY1_MODULFREQ") then !nika.freqnorm1 = double( param_c.ARRAY1_MODULFREQ)
         if tag_exist( param_c, "ARRAY2_MODULFREQ") then !nika.freqnorm2 = double( param_c.ARRAY2_MODULFREQ)
         if tag_exist( param_c, "ARRAY3_MODULFREQ") then !nika.freqnorm3 = double( param_c.ARRAY3_MODULFREQ)
      endelse      
      freqnorm_vec = [!nika.freqnorm1, !nika.freqnorm2, !nika.freqnorm3]
   endelse

   w = where( strupcase(tags) eq "I", nw)
   if nw ne 0 then begin
      if !nika.pf_ndeg gt 0 and !nika.freqnorm1 gt 0. then begin
         if strupcase(param.math) eq "PF"  then begin
                                ; could use nk_ version but I do not
                                ; want to break anything FXD
            nika_conviq2pf, data, kidpar, dapf, !nika.pf_ndeg, freqnorm_vec
         endif else begin
            nk_conviq2pf, data, kidpar, dapf, !nika.pf_ndeg+1, $
                          freqnorm_vec, /cfmethod, $
                          verbose = (param.silent eq 0), $
                          xcirc, ycirc, radcirc, xoff, cfraw = cfraw, $
                          k_deglitch = param.cf_deglitch
            if param.k_rts then $
               nk_flag_rts_kid, kidpar, xoff, verbose = (param.silent eq 0)
            if param.flag_sat then $
               nk_sat_cf, data, kidpar, cfraw, $
                    satur_level = param.flag_sat_val, silent = param.silent
         endelse
      endif else begin
         nk_error, info, "Not enough information to compute PF timelines"
         if param.silent eq 0 then message, /info, info.error_message
         return
      endelse
   endif else begin
      nk_error, info, "Not enough information to compute PF timelines"
      if param.silent eq 0 then message, /info, info.error_message
      return
   endelse      

;;   if strupcase(!nika.acq_version) eq "V3" then data.toi = dapf else data.toi = -dapf ;The flux is positive
;; NP, May 16th, 2020: restore sign for V2 ?
   if strupcase(!nika.acq_version) eq "V1" then data.toi = -dapf else data.toi=dapf

endif

;; RFdIdQ is set positive
data.toi  *= -1

; Recompute (if needed) df_tone (this routine must be placed after df_tone is
; back to Hz and toi is back to the usual sign
; print, "param.do_opacity_correction: ", param.do_opacity_correction

;;;; WRONG FXD Feb 2018
;;;; if param.do_opacity_correction eq 1 then nk_get_df_tone, param, info, data, kidpar, param_d
if param.do_opacity_correction ge 1 then nk_get_df_tone, param, info, data, kidpar, param_d

;; Compute a more accurate parallactic angle
;;if param.debug eq 0 then data.paral = parallactic_angle( data.az, data.el)
data.paral = parallactic_angle( data.az, data.el)

if param.cpu_time then nk_show_cpu_time, param

end
