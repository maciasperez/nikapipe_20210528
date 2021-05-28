
;; take out filtering options that may be misleading. Apply them in clear in the
;; main calling script instead

pro qd_decorrel_3, toi_in, templates, toi_out,  verbose = verbose

if n_params() lt 1 then begin
   messge, /info, "Calling sequence:"
   print, "qd_decorrel_3, toi_in, templates, toi_out"
   return
endif

n_temp  = n_elements( templates[*,0])
nsn     = n_elements( toi_in[0,*])
nkids   = n_elements( toi_in[*,0])

;; Init arrays
toi_out  = toi_in*0.0d0

for ikid=0, nkids-1 do begin
   if keyword_set(verbose) then percent_status, ikid, nkids, 10

   ;; Derive correlated part
   y = reform( toi_in[ikid,*], nsn)
   Coeff = REGRESS( templates, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                    /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit) 
   ;for j=0, n_temp-1 do toi_out[ikid,*] = toi_out[ikid,*] + coeff[j]*templates[j,*]
   ;toi_out[ikid,*] = toi_out[ikid,*] + const

   ;; Subtract
   ;toi_out[ikid,*] = toi_in[ikid,*] - toi_out[ikid,*]

   toi_out[ikid, *] =  toi_in[ikid, *] - reform(yfit)

endfor


end
