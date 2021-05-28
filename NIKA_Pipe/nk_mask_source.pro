;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_mask_source
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;         nk_mask_source, param, info, data, kidpar
; 
; PURPOSE: 
;        updates data.off_source to monitor which samples are on or off source
;        for each kid.
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the nika data structure
;        - kidpar: the kids structure
;        - grid: map and mask related information
; 
; OUTPUT: 
;        - data.off_source
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Apr 24th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)

pro nk_mask_source, param, info, data, kidpar, grid
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_mask_source'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

;; Correct input mask if requested the decorrelation method does not use the
;; mask. Otherwise, the mask in the output fits is misleading
if strupcase(param.decor_method) eq "COMMON_MODE" then begin
   if param.log eq 1 then nk_log, info, "data.off_source and grid.mask_source_Xmm forced to 1 because param.decor_method = COMMON_MODE"
   grid.mask_source_1mm = 1.d0
   grid.mask_source_2mm = 1.d0
   data.off_source = 1
endif else begin
   if param.log eq 1 then nk_log, info, "updating data.off_source with grid.mask_source_Xmm"
   for iarray=1, 3 do begin
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;      message, /info, "iarray = "+strtrim(iarray,2)+", nw1 = "+strtrim(nw1,2)
      ipix = data.ipix[w1]
      if iarray eq 2 then begin
         mask = grid.mask_source_2mm
      endif else begin
         mask = grid.mask_source_1mm
      endelse

      ;; In case the input mask is in azel coordinates and we are
      ;; currently working in radec projection
      if param.rotate_azel_mask_to_radec eq 1 then begin
         nk_shear_rotate, mask, grid.nx, grid.ny, -info.paral, junk
         ;; shear_rotate modifies the exact values of pixels due to
         ;; interpolation of neighbor pixels
         mask = junk gt 0.5
      endif
      
      nk_map2toi_3, param, info, mask, ipix, toi, $
                    map_q=map_q, map_u=map_u, toi_q=toi_q, toi_u=toi_u, $
                    toi_init_val=1.d0
      data.off_source[w1] = toi
   endfor
;   message, /info, "for loop done"
endelse

;message, /info, "here"
if param.cpu_time then nk_show_cpu_time, param

;message, /info, "wtf ?"
end
