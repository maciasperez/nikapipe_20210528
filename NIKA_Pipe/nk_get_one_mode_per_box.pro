
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_one_mode_per_box
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;
; PURPOSE: 
;       Decorrelates kids from a common mode. This common mode is
;computed from the block of kids specified in kid_corr_block
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - toi, flag, off_source, kid_corr_block
; 
; OUTPUT: 
;        - toi
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 16th, 2018: NP, from nk_decor_sub_corr_block2,
;          adpated to nk_decor_sub_6

pro nk_get_one_mode_per_box, param, info, toi, flag, off_source, kidpar, common_mode_per_box, acq_box_out, $
                             w8_source_in=w8_source_in
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_get_one_mode_per_box'
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkid = n_elements(kidpar)
nsn  = n_elements(toi[0,*])

;; Determine how many boxes have valid kids for the current scan
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kid"
   return
endif
b = kidpar[w1].acqbox
acq_box_out = b[UNIQ(b, SORT(b))]
nboxes = n_elements(acq_box_out)

common_mode_per_box = dblarr( nboxes, nsn) + !values.d_nan
for ibox=0, nboxes-1 do begin
   w1 = where( kidpar.type eq 1 and kidpar.acqbox eq acq_box_out[ibox], nw1)
   if param.debug ge 1 then message, /info, strtrim(nw1,2)+" valid kids in box "+strtrim(ibox,2)+" to compute common mode"
   if keyword_set(w8_source_in) then begin
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], off_source[w1,*], kidpar[w1], cm, $
                       w8_source_in=w8_source_in[w1,*]
   endif else begin
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], off_source[w1,*], kidpar[w1], cm
   endelse
   common_mode_per_box[ibox,*] = cm
;   plot, cm, xra=[3000,5000], /xs
;   legendastro, strtrim(ibox,2)
;   stop
endfor

if param.cpu_time then nk_show_cpu_time, param
  
end
