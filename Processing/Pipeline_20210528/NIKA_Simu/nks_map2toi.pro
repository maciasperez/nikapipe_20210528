;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nks_map2toi
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nks_map2toi, param, simpar, info, data, kidpar
; 
; PURPOSE: 
;        Produces TOI's from an input map and input scanning strategy and kidpar.
; 
; INPUT: 
;        - simpar: the simulation parameter structure
;        - param : the pipeline parameter structure
;        - info: the data info structure
;        - data: the original data taken from a real observation scan or
;          produced by another extra simulation routine from scratch.
;        - kidpar: the original kid structure from a real observation scan or
;          produced by another extra simulation routine from scratch.
; 
; OUTPUT: 
;        - data.toi, data.toi_q, data.toi_u if polarization
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug, 13th, 2014: NP
;-

pro nks_map2toi, param, simpar, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nks_map2toi, param, simpar, info, data, kidpar"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)
if tag_exist( simpar, "map_2mm") then begin
   ;; Compute ipix with the input map parameters
   nk_get_ipix, data, info, simpar.xmin, simpar.ymin,$
                simpar.nx, simpar.ny, simpar.map_reso

   for lambda=1, 2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         ipix = data.ipix[w1]

         if info.polar eq 2 then begin
            ipix1 = data.ipix1[w1]
         endif

         if lambda eq 1 then begin
            map = simpar.map_1mm
            if tag_exist( simpar, "map_q_1mm") then begin
               map_q = simpar.map_q_1mm
               map_u = simpar.map_u_1mm
            endif
         endif else begin
            map = simpar.map_2mm
            if tag_exist( simpar, "map_q_2mm") then begin
            map_q = simpar.map_q_2mm
            map_u = simpar.map_u_2mm
            endif
         endelse
       
         nk_map2toi_3, param, info, map, ipix, toi, $
                       map_q=map_q, map_u=map_u, toi_q=toi_q, toi_u=toi_u
         
         data.toi[w1] += toi
         if simpar.polar then data.toi[w1] += ( (data.cospolar##(dblarr(nw1)+1))*toi_q + (data.sinpolar##(dblarr(nw1)+1))*toi_u)
         if info.polar eq 2 then begin
            nk_map2toi_3, param, info, map, ipix1, toi, $
                          map_q=map_q, map_u=map_u, toi_q=toi_q, toi_u=toi_u
            
            data.toi[w1] += toi
            if simpar.polar then data.toi[w1] += ( (data.cospolar##(dblarr(nw1)+1))*toi_q + (data.sinpolar##(dblarr(nw1)+1))*toi_u)
         endif
      endif
   endfor
endif

;; nk_init_grid, param, grid
;; data.w8=1
;; nk_get_ipix, data, info, grid.xmin, grid.ymin, grid.nx, grid.ny, grid.map_reso
;; nk_get_kid_pointing, param, info, data, kidpar
;; ;; param.do_opacity_correction = 1
;; nk_calibration, param, info, data, kidpar, simpar=simpar
;; info.status=0
;; nk_projection_3, param, info, data, kidpar, grid
;; stop


if param.cpu_time then nk_show_cpu_time, param, "nks_map2toi"

end
