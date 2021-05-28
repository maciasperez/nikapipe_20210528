
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_subtract_maps_from_toi
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_subtract_maps_from_toi, param, info, data, kidpar, grid, subtract_maps
; 
; PURPOSE: 
;        scans subtract_maps and subtract from data.toi, data.toi_q, data.toi_u
; 
; INPUT: 
;        - param, info, data, kidpar, subtract_maps
; 
; OUTPUT: 
;        - data.toi, data.toi_q, data.toi_u
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 2019, NP

pro nk_subtract_maps_from_toi, param, info, data, kidpar, grid, subtract_maps, $
                               toi_i_1mm=toi_i_1mm, toi_i_2mm=toi_i_2mm, Q=Q, U=U
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_subtract_maps_from_toi'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

istokes = 1
if keyword_set(Q) then istokes=2
if keyword_set(U) then istokes=3

;; see nk_update_mask_source for details on the definition of data.off_source
w = where( subtract_maps.iter_mask_1mm gt 0., nw)
if nw gt 0 then begin
   w1 = where(kidpar.type eq 1 and (kidpar.array eq 1 or kidpar.array eq 3), nw1)
   if nw1 ne 0 then begin

      if param.subtract_ignore_mask_radius gt 0.d0 then begin
         subtract_w8_mask = double( sqrt( grid.xmap^2+grid.ymap^2) le param.subtract_ignore_mask_radius)
      endif else begin
         subtract_w8_mask = 1.d0-grid.mask_source_1mm
      endelse

      case istokes of
         1: begin
            if param.subtract_pos_signal_only eq 1 then begin
               nk_map2toi_3, param, info, param.subtract_frac*(subtract_maps.map_i_1mm > 0.d0)*subtract_w8_mask, data.ipix[w1], toi_i_1mm
            endif else begin
               nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_i_1mm * subtract_w8_mask, data.ipix[w1], toi_i_1mm
            endelse
            if param.log then nk_log, info, "subtracting subtract_maps.map_i_1mm from data.toi"
            data.toi[w1] -= toi_i_1mm
         end

         2:begin
            nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_q_1mm * subtract_w8_mask, data.ipix[w1], toi_q_1mm
            if param.log then nk_log, info, "subtracting subtract_maps.map_q_1mm from data.toi"
            data.toi_q[w1] -= toi_q_1mm
         end

         3:begin
            nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_u_1mm * subtract_w8_mask, data.ipix[w1], toi_u_1mm
            if param.log then nk_log, info, "subtracting subtract_maps.map_u_1mm from data.toi"
            data.toi_u[w1] -= toi_u_1mm
         end
      endcase
      
;;      if info.polar and param.qu_iterative_mm then begin
;;         w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
;;         if nw1 ne 0 then begin
;;            nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_q_1mm*subtract_w8_mask, data.ipix[w1], toi_q_1mm
;;            nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_u_1mm*subtract_w8_mask, data.ipix[w1], toi_u_1mm
;;            c = data.cospolar##(dblarr(nw1)+1.d0)
;;            s = data.sinpolar##(dblarr(nw1)+1.d0)
;;            data.toi[w1] -= (c*toi_q_1mm + s*toi_u_1mm)
;;         endif
;;         w1 = where( kidpar.type eq 1 and kidpar.array eq 3, nw1)
;;         if nw1 ne 0 then begin
;;            nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_q_1mm*subtract_w8_mask, data.ipix[w1], toi_q_1mm
;;            nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_u_1mm*subtract_w8_mask, data.ipix[w1], toi_u_1mm
;;            ;; Change pol_sign for array3 (transmission vs reflection)
;;            c = -data.cospolar##(dblarr(nw1)+1.d0)
;;            s = -data.sinpolar##(dblarr(nw1)+1.d0)
;;            data.toi[w1] -= (c*toi_q_1mm + s*toi_u_1mm)
;;         endif
;;      endif
   endif
endif

;; 2mm
w = where( subtract_maps.iter_mask_2mm gt 0., nw)
if nw gt 0 then begin
   w1 = where(kidpar.type eq 1 and kidpar.array eq 2, nw1)
   if nw1 ne 0 then begin

      if param.subtract_ignore_mask_radius gt 0.d0 then begin
         subtract_w8_mask = double( sqrt( grid.xmap^2+grid.ymap^2) le param.subtract_ignore_mask_radius)
      endif else begin
         subtract_w8_mask = 1.d0-grid.mask_source_2mm
      endelse

      case istokes of
         1: begin
            if param.subtract_pos_signal_only eq 1 then begin
               nk_map2toi_3, param, info, param.subtract_frac*(subtract_maps.map_i2 > 0.d0)*subtract_w8_mask, data.ipix[w1], toi_i_2mm
            endif else begin
               nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_i2*subtract_w8_mask, data.ipix[w1], toi_i_2mm
            endelse
            if param.log then nk_log, info, "subtracting subtract_maps.map_i2 from data.toi"
            data.toi[w1] -= toi_i_2mm
         end

         2: begin
            nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_q2 * subtract_w8_mask, data.ipix[w1], toi_q_2mm
            if param.log then nk_log, info, "subtracting subtract_maps.map_q2 from data.toi_q"
            data.toi_q[w1] -= toi_q_2mm
         end
         3: begin
            nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_u2 * subtract_w8_mask, data.ipix[w1], toi_u_2mm
            if param.log then nk_log, info, "subtracting subtract_maps.map_u2 from data.toi_u"
            data.toi_u[w1] -= toi_u_2mm
         end
      endcase

      ;; if info.polar and param.qu_iterative_mm then begin
      ;;    nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_q_2mm*subtract_w8_mask, data.ipix[w1], toi_q_2mm
      ;;    nk_map2toi_3, param, info, param.subtract_frac*subtract_maps.map_u_2mm*subtract_w8_mask, data.ipix[w1], toi_u_2mm
      ;;    c = data.cospolar##(dblarr(nw1)+1.d0)
      ;;    s = data.sinpolar##(dblarr(nw1)+1.d0)
      ;;    data.toi[w1] -= (c*toi_q_2mm + s*toi_u_2mm)
      ;; endif
   endif
endif

if param.cpu_time then nk_show_cpu_time, param
end
