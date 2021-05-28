
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_interpol_high_snr
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_interpol_high_snr, param, info, data, kidpar, grid, subtract_maps
; 
; PURPOSE: 
;        interpolate tois over high snr regions and fill with
;constrained white noise
; 
; INPUT: 
;        - param, info, data, kidpar, subtract_maps
; 
; OUTPUT: 
;        - data.toi
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - May 2019, NP

pro nk_interpol_high_snr, param, info, data, kidpar, grid, subtract_maps
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_interpol_high_snr'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

w = where( subtract_maps.iter_mask_1mm gt 0., nw)
if nw gt 0 then begin
   if param.log then nk_log, info, "running"
   index = dindgen(n_elements(data))
   t_smooth = 3.d0 ; 2.d0 ; sec
   nsmooth = round( t_smooth*!nika.f_sampling)

   w1 = where(kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin
      nk_map2toi_3, param, info, subtract_maps.iter_mask_1mm, data.ipix[w1], high_snr_loc_toi

      for i=0, nw1-1 do begin
         ikid = w1[i]
         w_on = where( high_snr_loc_toi[i,*] eq 1, nw_on, compl=w_off)

         if nw_on ne 0 then begin
            toi_smooth = smooth( data.toi[ikid], nsmooth, /edge_mirror)
            toi_interp = interpol( toi_smooth[w_off], index[w_off], index);, /spline)

            sigma = stddev( data[w_off].toi[ikid]-toi_smooth[w_off])
            toi_out = data.toi[ikid]
            toi_out[w_on] = toi_interp[w_on] + randomn( seed, nw_on)*sigma 

;;            wind, 1, 1, /free, /large
;;            plot, index[w_off], data[w_off].toi[ikid], /xs, xra=xra
;;            oplot, index, toi_smooth, col=200, thick=2
;;            oplot, index[w_on], data[w_on].toi[ikid], psym=1, col=70
;;            oplot, index, toi_interp, col=150
;;            oplot, index, toi_out, col=250
;;            legendastro, ['Mask', 'toi smooth', 'toi_interp', 'toi_out'], col=[70, 200, 150, 250]
;;            stop

            data[w_on].toi[ikid] = toi_interp[w_on] + randomn( seed, nw_on)*sigma 
         endif
      endfor
   endif
endif

if param.cpu_time then nk_show_cpu_time, param
end
