
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_update_mask_source
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_update_mask_source, param, info, data, kidpar, grid, subtract_maps
; 
; PURPOSE: 
;        Update mask source depending on input subtract_maps and
;        decorrelation options.
; 
; INPUT: 
;        - param, info, data, kidpar, subtract_maps
; 
; OUTPUT: 
;        - grid.mask_source_1mm, grid.mask_source_2mm
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 2019, NP

pro nk_update_mask_source, param, info, data, kidpar, grid, subtract_maps
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_update_mask_source'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

dd = sqrt( subtract_maps.xmap^2 + subtract_maps.ymap^2)

grid.zero_level_mask = subtract_maps.zero_level_mask

;; 1mm
w = where( subtract_maps.iter_mask_1mm gt 0., nw)
;; if no input mask is provided, derive it from the data
if nw eq 0 then begin
   if param.log eq 1 then nk_log, info, "deriving mask on the fly at 1mm"
   if param.sub_thres_sn gt 0.d0 then begin
      map_sn = dblarr(subtract_maps.nx, subtract_maps.ny)
      w = where( subtract_maps.nhits_1mm ne 0)
      map_sn[w] = subtract_maps.map_i_1mm[w]/sqrt( subtract_maps.map_var_i_1mm[w])
      if param.no_signal_threshold eq 1 then begin
         w = where( map_sn gt param.sub_thres_sn and $
                    dd le param.iter_mask_radius, nw)
      endif else begin
         w = where( map_sn gt param.sub_thres_sn and $
                    dd le param.iter_mask_radius and $
                    subtract_maps.map_i_1mm gt 0.d0, nw)
      endelse
   endif
endif else begin
   if param.log eq 1 then nk_log, info, "Taking subtract_maps.iter_mask_1mm"
endelse

if nw ne 0 then begin
   my_mask     = subtract_maps.map_i_1mm*0.d0
   my_mask[w] = 1.d0
   grid.mask_source_1mm = 1-my_mask
endif else begin
   if param.log eq 1 then nk_log, info, "No pixel to mask at 1mm"
endelse

;; 2mm
w = where( subtract_maps.iter_mask_2mm gt 0., nw)
;; if no input mask is provided, derive it from the data
if nw eq 0 then begin
   if param.log eq 1 then nk_log, info, "deriving mask on the fly at 2mm"
   if param.sub_thres_sn gt 0.d0 then begin
      map_sn = dblarr(subtract_maps.nx, subtract_maps.ny)
      w = where( subtract_maps.nhits_2 ne 0)
      map_sn[w] = subtract_maps.map_i2[w]/sqrt( subtract_maps.map_var_i2[w])
      if param.no_signal_threshold eq 1 then begin
         w = where( map_sn gt param.sub_thres_sn and $
                    dd le param.iter_mask_radius, nw)
      endif else begin
         w = where( map_sn gt param.sub_thres_sn and $
                    dd le param.iter_mask_radius and $
                    subtract_maps.map_i2 gt 0.d0, nw)
      endelse
   endif
endif else begin
   if param.log eq 1 then nk_log, info, "Taking subtract_maps.iter_mask_2mm"
endelse

if nw ne 0 then begin
   my_mask     = subtract_maps.map_i2*0.d0
   my_mask[w] = 1.d0
   grid.mask_source_2mm = 1-my_mask
endif else begin
   if param.log eq 1 then nk_log, info, "No pixel to mask at 2mm"
endelse

if param.cpu_time then nk_show_cpu_time, param
end
