;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_maps2data_toi
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_maps2data_toi, param, info, data, kidpar, subtract_maps, subtract_maps
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
;        - subtract_maps: the output maps structure
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

pro nk_maps2data_toi, param, info, data, kidpar, subtract_maps, output_toi, $
                      output_toi_i=output_toi_i, $
                      output_toi_q=output_toi_q, $
                      output_toi_u=output_toi_u, $
                      output_toi_var_i=output_toi_var_i, $
                      output_toi_var_q=output_toi_var_q, $
                      output_toi_var_u=output_toi_var_u, astr=astr
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_maps2data_toi'
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

nk_get_ipix, param, info, dd, kidpar, subtract_maps, astr=astr

output_toi       = data.toi*0.d0
output_toi_i     = data.toi*0.d0
if info.polar ne 0 then begin
   output_toi_q     = data.toi_q*0.d0
   output_toi_u     = data.toi_u*0.d0
endif

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
;      nk_map2toi_3, param, info, map, ipix, toi_i, $
;                    map_q=map_q, map_u=map_u, toi_q=toi_q, toi_u=toi_u
      nk_map2toi_3, param, info, map, ipix, toi_i
      if defined(map_q) then begin
         nk_map2toi_3, param, info, map_q, ipix, toi_q
         nk_map2toi_3, param, info, map_u, ipix, toi_u
      endif

;;       message, /info, "fix me: filter out I timeline to avoid pixel effects aliasing into Q and U"
;; ;      i=0
;; ;      ikid = w1[i]
;; ;      power_spec, toi_i[ikid,*], !nika.f_sampling, pw, freq
;; ;      wind, 1, 1, /free
;; ;      plot_oo, freq, pw, /xs
;;       delvarx, filter
;;       for i=0, nw1-1 do begin
;;          np_bandpass, reform( toi_i[i,*]), !nika.f_sampling, junk, $
;;                       freqlow=0.d0, freqhigh=7.d0, $
;;                       delta_f=0.2, filter=filter
;;          toi_i[i,*] = junk
;;       endfor
;;       ;;--------------
      
      ;; Account for polarization
      if info.polar ne 0 then begin
         output_toi_q[w1,*] = toi_q
         output_toi_u[w1,*] = toi_u
      endif
      
      ;; Final timelines: toi contains polarization (to allow this
      ;; routine to be called during iterative map making), so toi_i
      ;; is specifically polarization free
      output_toi_i[w1,*] = toi_i

      ;; pol_sign place holder for A2, no big deal
      pol_sign = dblarr(nw1) + 1
      w13 = where( kidpar[w1].array eq 3, nw13)
      if nw13 ne 0 then pol_sign[w13] = -1.d0

      if info.polar ne 0 then begin
         ;; output_toi[w1,*] = toi_i + (data.cospolar##(dblarr(nw1)+1))*toi_q + (data.sinpolar##(dblarr(nw1)+1))*toi_u
         output_toi[w1,*] = toi_i + (data.cospolar##pol_sign)*toi_q + (data.sinpolar##pol_sign)*toi_u
      endif else begin
         output_toi[w1,*]  = toi_i
      endelse
      
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param, "nk_maps2data_toi"
  
end
