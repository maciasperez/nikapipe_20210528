pro fit_polyder, IDa, QDa, dIDa, dQDa, ndeg, coeff, status=status


; ndeg ; maximal sum of degrees in I and Q
ndeg1=ndeg+1  ; size of coeff array
ij= lindgen( ndeg1, ndeg1)
ij1D= reform( ij, ndeg1*ndeg1)
ii= ij mod ndeg1
jj= ij/ndeg1
ipj= ii+jj
ntermpoly= 2^ndeg1  ; number of terms in polynomial
term= dblarr(ndeg1, ndeg1)  ; coefficients of each monome
kreg=1
aux= polyder( IDa, QDa, term*0, auxi, auxq, k_regress=kreg)

; Deduce derivative
dfnorm= dIDa^2+ dQDa^2
dfdida= dIDa/ dfnorm
dfdqda= dQDa/ dfnorm
thr= avg( dfnorm)/1E5
; weigh the data with dfnorm (clipped)

cores= regress(  kreg, [dfdida, dfdqda], const= const, $
                 measure_errors = 1/sqrt((dfnorm>thr)), status= status, /double)
good= where(ipj le ndeg and ipj ne 0 and (ii ne 1 or jj ne 0), ngood)
t10=(where( ii eq 1 and jj eq 0))[0]
termfit= dblarr(ndeg1, ndeg1)
termfit[ good]= cores

; Fix the 3 missing terms
termfit[ t10]= const
t01= where( ii eq 0 and jj eq 1)
termfit[ t01]= termfit[ t01]+const

freqfit= polyder( IDa, QDa, termfit)
;termfit[0]= - avg( freqfit)  ; force the average at zero (not really needed)
termfit[0]= -freqfit[0]  ; force the first term to zero (not really needed)
coeff= termfit

end
