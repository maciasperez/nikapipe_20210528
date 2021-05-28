
; Decorrelates all kids from the off resonance kids

pro qd_decorrel_2, toi_in, f_sampling, freqmin, freqmax, off, toi_out

if n_params() lt 1 then begin
   messge, /info, "Calling sequence:"
   print, "qd_decorrel_2, toi_in, f_sampling, freqmin, freqmax, off, toi_out"
   return
endif

n_off   = n_elements(off)
nsn     = n_elements( toi_in[0,*])
nkids   = n_elements( toi_in[*,0])

;; Init arrays
toi      = toi_in ; do not alter input toi
toi_filt = toi_in*0.0d0
toi_out  = toi_in*0.0d0

;; Remove baselines
for ikid=0, nkids-1 do begin
   baseline = (toi[ikid,nsn-1]-toi[ikid,0])/double(nsn-1)*dindgen(nsn) + toi[ikid,0]
   toi[ikid,*] = toi[ikid,*] - baseline
endfor

;; Main loop
nfreq = n_elements(freqmin)
for i=0, nfreq-1 do begin

   ;; Init filter
   delvarx, filter
   delta_f = (freqmax[i]-freqmin[i])/5.d0 ; hand picked for now
   np_bandpass, toi[0,*], f_sampling, dummy, filter=filter, freqlow=freqmin[i], freqhigh=freqmax[i], delta_f=delta_f
stop

   ;; Filter timelines
   for ikid=0, nkids-1 do begin
      np_bandpass, toi[ikid,*], f_sampling, dummy, filter=filter
      toi_filt[ikid,*] = dummy
   endfor
   
   ;; Derive correlated part
   for ikid=0, nkids-1 do begin
      w = where( off eq ikid, nw)
      if nw eq 0 then begin
         print, ikid
         x = toi_filt[ off,*]
         y = reform( toi_filt[ikid,*], nsn)
         Coeff   = REGRESS( x, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                            /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit ) 
         for j=0, n_off-1 do toi_out[ikid,*] = toi_out[ikid,*] + coeff[j]*x[j,*]
         toi_out[ikid,*] = toi_out[ikid,*] + const
      endif
   endfor
endfor

;;;; Subtract correlated part and the baseline
for ikid=0, nkids-1 do begin
   toi_out[ikid,*] = toi[ikid,*] - toi_out[ikid,*]
endfor


end
