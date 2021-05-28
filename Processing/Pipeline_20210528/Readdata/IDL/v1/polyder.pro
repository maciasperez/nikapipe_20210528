; Function to compute a 2D polynomial and derivatives
function polyder, x, y, coeff, dpdx, dpdy, k_regress= kreg
; x and y are vectors (size nel)
; coeff= fltarr( n, n)  ; n is degree of polyn+1
; output: dpdx is the polyn derivative with x
; if k_regress not 0, then on output is the 2n by nel array used as input for regress

npoly= n_elements( coeff[0,*])-1  ; degree of polynomial
ncosi= npoly+1 ; size of the coeff array
nel= n_elements( x)  ; assumed eq for y


;;; removed multiple instances of the double (i,j) loop when only one is needed
;;; (25/11/2016, HR)

Pol = 0.D0
dpdx = 0.D0
dpdy = 0.D0

ii = rebin(lindgen(ncosi), ncosi, ncosi)
jj = transpose(ii)
coeff_dx = coeff * double(ii)
coeff_dy = coeff * double(jj)

if keyword_set(kreg) then begin
   good = where(ii + jj le npoly and (not (ii le 1 and jj eq 0)), ngood)
   kreg = dblarr(ngood, 2*nel)
   ii_reg = ii(good)
   jj_reg = jj(good)
endif


PolX = 1.D0
Pol_dx = 1.D0
for i = 0, npoly do begin
   PolY = 1.D0
   Pol_dy = 1.D0
   for j = 0, npoly - i do begin
      Pol += coeff(i, j) * PolX * PolY
      dpdx += coeff_dx(i, j) * Pol_dx * PolY
      dpdy += coeff_dy(i, j) * PolX * Pol_dy
      if keyword_set(kreg) then begin
         u = where(ii_reg eq i and jj_reg eq j)
         if (i ne 0 and (not (i eq 1 and j eq 0))) then $
            kreg(u, 0:nel-1) = i * Pol_dx * PolY
         if j ne 0 then kreg(u, nel:*) = j * PolX * Pol_dy
      endif
      PolY *= y
      if j ne 0 then Pol_dy *= y
   endfor
   PolX *= x
   if i ne 0 then Pol_dx *= x
endfor




;;;Pol=dblarr( nel)
;;;PolX=1D0+ dblarr( nel)
;;;for i=0, npoly do begin
;;;  PolY=1D0+ dblarr( nel)
;;;  for j=0, npoly - i do begin
;;;     Pol= Pol+ coeff[ i, j]* PolX * PolY
;;;     PolY= PolY* y
;;;  endfor
;;;  PolX= PolX* x
;;;endfor

;;;dpdx=dblarr( nel)
;;;PolX=1D0+ dblarr( nel)
;;;for i=0, npoly do begin
;;;  PolY=1D0+ dblarr( nel)
;;;  for j=0, npoly - i do begin
;;;     dpdx= dpdx+ i*coeff[ i, j]* PolX * PolY
;;;     PolY= PolY* y
;;;  endfor
;;;  if i ne 0 then PolX= PolX* x
;;;endfor

;;;dpdy=dblarr( nel)
;;;PolX=1D0+ dblarr( nel)
;;;for i=0, npoly do begin
;;;  PolY=1D0+ dblarr( nel)
;;;  for j=0, npoly - i do begin
;;;     dpdy= dpdy+ j*coeff[ i, j]* PolX * PolY
;;;     if j ne 0 then PolY= PolY* y
;;;  endfor
;;;  PolX= PolX* x
;;;endfor


;;;if keyword_set( kreg) then begin
;;;  ij = lindgen( ncosi, ncosi)
;;;  ij1D = reform( ij, ncosi*ncosi)
;;;  ii = ij mod ncosi
;;;  jj= ij/ncosi
;;;  ipj= ii+jj
;;;  good= where(ipj le npoly and ipj ne 0 and (ii ne 1 or jj ne 0), ngood)
;;;  kreg = dblarr( ncosi*ncosi-2-ncosi*npoly/2, 2*nel)  ; should be ngood, 2nel
; convenient format to store a truncated 2D array of i,j times Time
;;;  ct1=0  ; counter
; same as dpdx
;;;  PolX = 1D0+ dblarr( nel)
;;;  for i = 0, npoly do begin
;;;    PolY = 1D0+ dblarr( nel)
;;;    for j = 0, npoly - i do begin
;      kreg[ 0, i, j, *]  = i * PolX * PolY
;;;      if i ne 0 then begin
;;;        if not (i eq 1 and j eq 0) then begin ;  ban the 10 constant term
;;;          u=(where( ii[ good] eq i and jj[ good] eq j))[0]
;;;          kreg[ u, 0:nel-1]  = i * PolX * PolY
;;;          ct1= ct1+1
;;;        endif 
;;;      endif
;;;      PolY = PolY * y
;;;    endfor
;;;    if i ne 0 then PolX = PolX* x
;;;  endfor

; Same as dpdy
;;;  ct2=0
;;;  PolX = 1D0+ dblarr( nel)
;;;  for i = 0, npoly do begin
;;;    PolY = 1D0+ dblarr( nel)
;;;    for j = 0, npoly - i do begin
;;;      if j ne 0 then begin
;;;          u=(where( ii[ good] eq i and jj[ good] eq j))[0]
;;;          kreg[ u, nel:*] =  j* PolX * PolY
;;;          ct2 = ct2+1
;;;        endif 
;;;      if j ne 0 then PolY = PolY* y
;;;    endfor
;;;    PolX = PolX* x
;;; endfor
; Check consistency
;;;  if ct1+1 ne ct2 then message, 'Pb with '+strtrim(ct1+1,2)+ ' NE '+strtrim( ct2, 2)
;;;endif


return, Pol
end

