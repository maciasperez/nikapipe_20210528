
;; Subtract a signal described by a sum of harmonics of the HWP rotation
;; frequency. The amplitudes of these harmonics may valy linearly with time.
;;
;; NP.

;; fit one by one for now...
;; output the last fit for the record (optional)
;;-----------------------------------------------------------------------------------

pro nika_pipe_hwp_rm, param, kidpar, data, amplitudes, fit=fit


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_pipe_hwp_rm, param, kidpar, data, amplitudes, fit=fit"
   return
endif

nkids = n_elements( kidpar)
nsn   = n_elements( data)

ncoeff = 2 + 4*param.polar.n_template_harmonics

amplitudes = dblarr( nkids, ncoeff)

t = dindgen(nsn)/!nika.f_sampling

temp = dblarr( ncoeff, nsn)
temp[0,*] = 1.0d0
temp[1,*] = t
for i=0, param.polar.n_template_harmonics-1 do begin
   temp[ 2 + i*4,     *] =   cos( (i+1)*data.c_position)
   temp[ 2 + i*4 + 1, *] = t*cos( (i+1)*data.c_position)
   temp[ 2 + i*4 + 2, *] =   sin( (i+1)*data.c_position)
   temp[ 2 + i*4 + 3, *] = t*sin( (i+1)*data.c_position)
endfor

ata   = matrix_multiply( temp, temp, /btranspose)
atam1 = invert(ata)

for ikid=0, nkids-1 do begin

   ;; std_err = dblarr(nsn) + stddev( toi[i,*])
   ;; multifit, toi[i,*], std_err, temp, ampl, fit
   
   ;; do not use multifit directly, too many samples to cope with std_err
   ;; explicit simpler version of multifit here


   ;; Loop only on valid kids to save time
   if kidpar[ikid].type eq 1 then begin

      atd = matrix_multiply( data.rf_didq[ikid], temp, /btranspose)

      ampl = atam1##atd
      amplitudes[ikid,*] = ampl
      fit  = reform( temp##ampl)
      data.rf_didq[ikid] -= fit
   endif
endfor

end
