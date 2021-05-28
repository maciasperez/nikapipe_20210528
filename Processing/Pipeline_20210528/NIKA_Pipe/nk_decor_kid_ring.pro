
pro nk_decor_kid_ring, param, info, kidpar, toi, flag, off_source, elevation, $
                       toi_out, out_temp, snr_toi=snr_toi

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn         = n_elements( toi[0,*])
nkids       = n_elements( toi[*,0])

wjunk = where( (finite(kidpar.noise) eq 0 or kidpar.noise eq 0) and kidpar.type eq 1, nw)
if nw ne 0 then begin
   nk_error, info, "There are NaN's in kidpar.noise", silent=param.silent
   return
endif

;; Compute KID to KID distance
nk_kid2kid_dist, kidpar, kid_dist_matrix

;; Account for kid noise
;; kid_w8 = (kid_dist_matrix ge param.cm_kid_min_dist and $
;;           kid_dist_matrix le param.cm_kid_max_dist)##diag_matrix(1.d0/kidpar.noise)^2
kid_w8 = double( kid_dist_matrix ge param.cm_kid_min_dist and $
                 kid_dist_matrix le param.cm_kid_max_dist)

toi_out  = dblarr(nkids,nsn)
out_temp = dblarr(nkids,nsn)
w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin
;   percent_status, i, nw1, 10
   ikid = w1[i]
   w = where( kid_w8[ikid,*] ne 0, nw)
   if nw ne 0 then begin
      nk_get_median_common_mode, param, info, toi[w,*], flag[w,*], off_source[w,*], kidpar[w], median_common_mode
      fit = linfit( median_common_mode, toi[ikid,*])
      out_temp[ikid,*] = fit[0] + fit[1]*median_common_mode
      toi_out[ ikid,*] = toi[ikid,*] - (fit[0] + fit[1]*median_common_mode)
   endif
endfor

;; wind, 1, 1, /free, /large
;; my_multiplot, 2, 2, pp, pp1, /rev
;; w1 = where( kidpar.type eq 1 and kidpar.array eq 1)
;; ikid = w1[300]
;; ;; ;; matrix_plot, kidpar[w1].nas_x, kidpar[w1].nas_y,
;; ;; kid_dist_matrix[ikid,w1], /iso
;; plot, kidpar[w1].nas_x, kidpar[w1].nas_y, /iso, psym=1, syms=0.5, $
;;       position=pp1[0,*], xra=[-1,1]*250, yra=[-1,1]*250
;; w = where( kid_w8[ikid,*] ne 0, nw)
;; oplot, kidpar[w].nas_x, kidpar[w].nas_y, psym=8, syms=0.5, col=250
;; 
;; make_ct, nw, ct
;; plot, toi[ikid,*], /xs, position=pp1[1,*], /noerase
;; common_mode = dblarr(nsn)
;; for i=0, nw-1 do begin &$
;;    fit = linfit( toi[w[i],*], toi[ikid,*]) &$
;;    oplot, fit[0] + fit[1]*toi[w[i],*], col=ct[i] &$
;;    common_mode += (fit[0] + fit[1]*toi[w[i],*])/nw &$
;; endfor
;; 
;; plot, toi[ikid,*], /xs, position=pp1[2,*], /noerase
;; oplot, common_mode, col=250
;; fit = linfit( common_mode, toi[ikid,*])
;; oplot, fit[0] + fit[1]*common_mode, col=150
;; stop

end

