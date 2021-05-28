;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_decor_test
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_handle, param, info, data, kidpar
; 
; PURPOSE: 
;        Decorrelates kids, filters...
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 09th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_decor_test, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor_test, param, info, data, kidpar"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkids = n_elements(kidpar)

;;-------------------------------------------------------------------------------------------
;; Select which decorrelation method must be applied
do_common_mode_subtraction = 0
case strupcase(param.decor_method) of

   ;; 1. No decorrelation
   "NONE": begin
      if param.silent ne 0 then message, /info, "No decorrelation"
   end

   ;; 2. Simple commmon mode
   "COMMON_MODE":begin
      if not param.silent then message, /info, "Decorrelation: simple common mode on the entire scan"
      do_common_mode_subtraction = 1

      ;; keep all valid samples, even on source => modify data.off_source
      data.off_source = 1.d0 ; long( data.flag eq 0)
   end
   
   ;; 3. Common mode with KIDs OFF source
   "COMMON_MODE_KIDS_OUT":begin
      if not param.silent then message, /info, "Decorrelation: common mode with KIDs outside the source"
      do_common_mode_subtraction = 1
   end

   ELSE: begin
      nk_error, info, "Unrecognized decorelation method: "+param.decor_method
      return
   end
endcase

;;-------------------------------------------------------------------------------------------
;; Compute common mode outside of the source and subtract (on each matrix independently)
if do_common_mode_subtraction then begin
         
   if strupcase(param.decor_per_subscan) eq "YES" then begin
      
      for i=(min(data.subscan)>1), max(data.subscan) do begin
         wsample = where( data.subscan eq i, nwsample)
         data_copy = data[wsample]
         nk_get_cm, param, info, data_copy, kidpar, common_mode
         nk_subtract_templates, param, info, data_copy, kidpar, common_mode[0,*], common_mode[1,*]
         data[wsample].toi = data_copy.toi
      endfor
      
   endif else begin             ; on the entire scan then
      nk_get_cm, param, info, data, kidpar, common_mode
      nk_subtract_templates, param, info, data, kidpar, common_mode[0,*], common_mode[1,*]
   endelse

endif

;; decorrelate from elevation templates
if param.decor_elevation then begin
   nsn       = n_elements(data)
   index     = dindgen( nsn)
   templates = dblarr(8,nsn)
   templates[0,*] = sin(      info.liss_freq_az*index)
   templates[1,*] = cos(      info.liss_freq_az*index)
   templates[2,*] = sin(      info.liss_freq_el*index)
   templates[3,*] = cos(      info.liss_freq_el*index)
   templates[4,*] = sin( 2.d0*info.liss_freq_az*index)
   templates[5,*] = cos( 2.d0*info.liss_freq_az*index)
   templates[6,*] = sin( 2.d0*info.liss_freq_el*index)
   templates[7,*] = cos( 2.d0*info.liss_freq_el*index)

   nk_subtract_templates, param, info, data, kidpar, templates, templates
endif


;;-------------------------------------------------------------------------------------------
;; Monitor the atmosphere via the common mode if requested
if param.do_meas_atmo ne 0 then begin
   if defined(common_mode) eq 0 then begin
      nk_error, info, "common_mode has not been computed"
      return
   endif
   nk_measure_atmo, param, info, data, kidpar, common_mode
endif

end
