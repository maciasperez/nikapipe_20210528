
if param.edge_source_interpol eq 0 then begin &$
   txt = 'polynomial_on_residual and edge_source_interpol must be set together' &$
   nk_error, info, txt &$
;;      return
   stop
endif

;; backup off_source info and flag for projection
toi1       = data.toi
flag       = data.flag
off_source = data.off_source

;; To prevent problems with interpolation/extrapolations on the edges
data.flag       = 0
data.off_source = 1

delvarx, w8_in
if defined(snr_toi) then w8_in = 1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2)

;; Apply to "data" so that the polynomial subtraction is well
;; accounted for in nk_w8 later on.
nk_polynomial_subtraction, param, info, data, kidpar, w8_in=w8_in

;; Add polynomials to out_temp_data
out_temp_data.toi += (toi1 - data.toi)

;; Restore backup values
data.flag      = flag
data.off_source = off_source

;; Save memory
delvarx, toi1, flag, off_source
