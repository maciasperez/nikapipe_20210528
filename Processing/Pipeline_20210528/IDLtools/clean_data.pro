
pro clean_data, toi, kidpar, toi_out, method, subscan, w8_out, $
                width=width, templates=templates, $
                fmin=fmin, fmax=fmax, wkid=wkid

toi_out = toi

if not keyword_set(wkid) then wkid = indgen(n_elements( toi[*,0]))

toi_out = toi
nbol    = n_elements( wkid) ; n_elements( toi[*,0])
nsn     = n_elements( toi[0,*])
t       = dindgen( nsn)
w8_out  = dblarr( nsn) + 1.0d0

case strupcase(method) of
   "MEDIAN":begin
      for i=0, nbol-1 do begin
         ibol = wkid[i]
         toi_out[ibol,*] = toi_out[ibol,*] - median( reform(toi[ibol,*]), width)
      endfor
   end

   "DECORR":begin
      if not keyword_set(templates) then begin
         message, /info, "You should provide templates"
         stop
      endif else begin
         for i=0, nbol-1 do begin
            ibol = wkid[i]
            y = reform( toi[ibol,*])
            coeff = regress( templates, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                             /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)
            toi_out[ibol,*] = toi[ibol,*] - reform(yfit)
         endfor
      endelse
   end

   "BASELINE":begin
      deg = 1
      baseline_sub, toi, subscan, kidpar, width, deg, toi_out, w8_out
   end

   "FOURIER":begin
      for i=0, nbol-1 do begin
         ibol = wkid[i]
         y = reform( toi[ibol,*])
         baseline = my_baseline(y)
         y = y - baseline
         np_bandpass, y, !nika.f_sampling, yout, filter=filter, freqlow=fmin, freqhigh=fmax, delta_f=delta_f
         toi_out[ibol,*] = yout
      endfor
   end

   "NONE":begin
   end

endcase
end
