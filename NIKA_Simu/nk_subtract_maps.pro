;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: nk_subtract_maps
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_subtract_maps, param, info, data, kidpar, map_struct, subtract_maps
; 
; PURPOSE: 
;        Produces timelines from the maps in subtract_maps and subtracts them
;        from data.toi. It helps reduce the signal contribution in the timelines
;        and improve the noise determination in case of iterative map making.
; 
; INPUT: 
;        - ram: the pipeline parameter structure
;        - info: the data info structure
;        - data: the data structure
;        - kidpar: the kid info structure
;        - map_struct: the output maps structure
;        - subtract_maps: a structure containing the maps to be scanned and
;          subtracted from the data.
; 
; OUTPUT: 
;        - data
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug., 22nd, 2014: NP
;-

pro nk_subtract_maps, param, info, data, kidpar, map_struct, subtract_maps

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_subtract_maps, param, info, data, kidpar, map_struct, subtract_maps"
   return
endif
  
;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

;; Compute ipix with the input map parameters
dd = {dra:data[0].dra, ddec:data[0].ddec, ipix:data[0].ipix} ; to preserve data.ipix
dd = replicate( dd, n_elements(data))
dd.dra = data.dra
dd.ddec = data.ddec
dd.ipix = data.ipix

nk_get_ipix, dd, info, subtract_maps.xmin, subtract_maps.ymin, subtract_maps.nx, subtract_maps.ny, subtract_maps.map_reso

for lambda=1, 2 do begin
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
   if nw1 ne 0 then begin
      ipix = dd.ipix[w1]
      
      if lambda eq 1 then begin
         map = subtract_maps.map_I_1mm
         if tag_exist( subtract_maps, "map_q_1mm") then begin
            map_q = subtract_maps.map_q_1mm
            map_u = subtract_maps.map_u_1mm
         endif
      endif else begin
         map = subtract_maps.map_I_2mm
         if tag_exist( subtract_maps, "map_q_2mm") then begin
            map_q = subtract_maps.map_q_2mm
            map_u = subtract_maps.map_u_2mm
         endif
      endelse
      
      ;; Scan maps to produce TOI's
      nk_map2toi_3, param, info, map, ipix, toi, $
                    map_q=map_q, map_u=map_u, toi_q=toi_q, toi_u=toi_u
      
      ;; Subtract from data TOI's
      data.toi[w1] -= toi
      if info.polar ne 0 then data.toi[w1] -= ( (data.cospolar##(dblarr(nw1)+1))*toi_q + (data.sinpolar##(dblarr(nw1)+1))*toi_u)
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param, "nk_subtract_maps"
  
end
