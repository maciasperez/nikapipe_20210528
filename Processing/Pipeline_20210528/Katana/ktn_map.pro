
;;pro ktn_map, param, data, kidpar, maps, xmap=xmap, ymap=ymap

;;------------------------------------------------------------------------------------
;; ;; Old version, commented out Dec. 17h, 2014, NP
;; 
;; data_copy = data ; preserve input structure before calibration, noise w8 etc...
;;   
;; ;; Calibration
;; nika_pipe_opacity, param, data, kidpar, /noskydip
;; 
;; nika_pipe_calib_2,   param, data, kidpar, /noskydip
;; 
;; ;; Timeline noise weights
;; nika_pipe_noisew8, param, data, kidpar
;; 
;; ;; Projection
;; wplot = where( kidpar.plot_flag eq 0, nwplot)
;; w11 = where( kidpar.array eq 1, nw11)
;; w12 = where( kidpar.array eq 2, nw12)
;; one_mm_only = 0
;; two_mm_only = 0
;; if nw11 eq 0 then two_mm_only = 1
;; if nw12 eq 0 then one_mm_only = 1
;; nika_pipe_map_2, param, data, kidpar, maps, kidlist=wplot, xmap=xmap, ymap=ymap, $
;;                one_mm_only=one_mm_only, two_mm_only=two_mm_only
;; 
;; ;; restore input structure
;; data = data_copy
;;------------------------------------------------------------------------------------

pro ktn_map, param, info, data, kidpar, grid_tot, xmap=xmap, ymap=ymap

;; preserve input structure before calibration, noise w8 etc...
data_temp = data

;; Project on a finer map than individual kids
nk_default_param, param1
nk_init_grid, param1, info, grid_tot

;; Compute individual kid pointing
nk_get_kid_pointing, param, info, data, kidpar

;; Compute data.ipix
nk_get_ipix, data, info, grid_tot

;; Apply (at least relative) calibration
nk_apply_calib, param, info, data, kidpar

;; Compute inverse variance weights for TOIs
nk_w8, param, info, data, kidpar

;; Keep only foward scans
;; Allers simples
w4 = where( data.scan_st eq 4, nw4)         ; & print, nw
w5 = where( data.scan_st eq 5, nw5)         ; & print, nw
nsn = n_elements(data)
w8 = dblarr(nsn)
for i=0, nw4-1 do begin
   w = where( w5 gt w4[i], nw)
   if nw ne 0 then begin        ; maybe the last subscan is cut off, then discard
      imin = min(w)
      w8[ w4[i]:w5[imin]] = 1
   endif
endfor
ww = where( w8 eq 0, nww)
if nww ne 0 then nk_add_flag, data, 11, ww

;; Project
info1 = info
info1.polar = 0 ; force for this quicklook
nk_projection_3, param, info1, data, kidpar, grid_tot
;stop

;; Restore current data
data = temporary(data_temp)

end
