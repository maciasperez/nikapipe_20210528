pro fit_cider, xx, yy, di, dq, ndeg, $
               coeff, corot, sirot, xc, yc, radius, $
               weight = weight, status=status
; Fit a circle to the data and then transform the data to the imaginary part
; of a complex. Fit, dI, dQ images on that line. Find the frequency as a
; polynomial of that imaginary part. 

; Fit a circle to the data (version 2 is robust versus weakly dispersed data
; that don't look like a circle)
circlefit2, double(xx), double(yy), xc, yc, radius, weight = weight ;, /verb

if radius le 0. then begin
  status = 1
  return
endif

; Do some geometrical transforms (rotation, translation and inversion)
rot1 = atan(yc, xc) ; find rotation angle
corot = cos( rot1)
sirot = sin( rot1)
xx2 = -( corot*(xx-xc)+sirot*(yy-yc))/radius/2+0.5D0
yy2 = +(-sirot*(xx-xc)+corot*(yy-yc))/radius/2

; take the inverse of the complex
;c2 = complex( xx2, yy2)
;c3 = 1/c2
;yy3 = imaginary( c3)
dd2 = xx2^2+yy2^2
yy3 = -yy2 / dd2

; Transform di, dq along the same line (but differentially)
di2 = -( corot*double(di)+sirot*double(dq))/radius/2
dq2 = +(-sirot*double(di)+corot*double(dq))/radius/2
;; dc2 = complex( di2, dq2)
;; dc3 = -dc2/c2^2
;; dq3 = imaginary( dc3)
dq3 = (2*xx2*yy2 * di2 - (xx2^2-yy2^2) * dq2) / dd2^2

; Fit a polynomial
; The error is linked to the distance to the anticenter
ddc = sqrt(xc^2+yc^2)
xxac = xc*(ddc+radius)/ddc
yyac = yc*(ddc+radius)/ddc
measerr = 1./sqrt( (xx-xxac)^2+(yy-yyac)^2)
; FXD May 2021, one adaptation (to match Concerto case)
bad = where( di*dq eq 0, nbad)
if nbad ne 0 then measerr[bad] = 1D20
res = poly_fit( yy3,  1.D0/dq3, ndeg, $
                measure_err = measerr,  status = status)

; Integrate res First coeff with 1, 2nd with 1/2...
coeff = [0., [res[*] / (indgen(ndeg+1)+1)]]


end
