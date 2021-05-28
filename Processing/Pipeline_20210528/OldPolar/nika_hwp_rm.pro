

; fit one by one for now...

pro nika_hwp_rm, toi, t, omega_deg, n_harmonics, fit, toi_out

nkids = n_elements( toi[*,0])
nsn   = n_elements(t)
omega = omega_deg*!dtor

ncoeff = 2 + 4*n_harmonics

temp = dblarr( ncoeff, nsn)
temp[0,*] = 1.0d0
temp[1,*] = t
for i=0, n_harmonics-1 do begin
   temp[ 2+i*4,     *] =   cos( (i+1)*omega)
   temp[ 2+i*4 + 1, *] = t*cos( (i+1)*omega)
   temp[ 2+i*4 + 2, *] =   sin( (i+1)*omega)
   temp[ 2+i*4 + 3, *] = t*sin( (i+1)*omega)
endfor

xra = [0,3]
toi_out = toi*0.0d0

for i=0, nkids-1 do begin
   ;; std_err = dblarr(nsn) + stddev( toi[i,*])
   ;; multifit, toi[i,*], std_err, temp, ampl, fit
   
   ;; do not use multifit directly, too many samples to cope with std_err
   ;; explicit simpler version of multifit here
   data = reform( toi[i,*])
   sigma = stddev( data)

   ata = matrix_multiply( temp, temp, /btranspose)
   atd = matrix_multiply( data, temp, /btranspose)

   covar = invert(ata)

   ampl = covar##atd
   fit  = reform( temp##ampl)

   toi_out[i,*] = toi[i,*] - fit
endfor

end
