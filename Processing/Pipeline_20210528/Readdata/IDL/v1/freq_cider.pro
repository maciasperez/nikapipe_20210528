function freq_cider, xx, yy, coeff, corot1, sirot1, xc, yc, radius, $
                     xerr, yraw = yraw
; Apply a circle fit method to compute the frequency of the kid
; See fit_cider to get the coefficients
; xerr is an output: it contains the excursion of points away from the
; 1+i*yy vertical axis, normalized by error (increasing with yy)
; xerr can thus be used to flag glitched data points
; yraw is used for the detection of saturation

if radius le 0. then begin
  freq = dblarr( n_elements( xx))
  return, freq
endif
; Do some geometrical transforms (rotation, translation and inversion)
xx2 = -( corot1*(double(xx)-xc)+sirot1*(double(yy)-yc))/radius/2+0.5
yy2 = +(-sirot1*(double(xx)-xc)+corot1*(double(yy)-yc))/radius/2

; take the inverse of the complex 1/(xx2+i*yy2)
; then the imaginary part
; apply the polynomial coefficients
d2 = xx2^2+yy2^2

freq = poly( -yy2 / d2,  coeff)
yraw = -yy2/d2

; Give the real part too, divided by something proportional to the noise
xerr = (xx2/ d2 - 1)/ sqrt(1+ (yy2/d2)^2)

return, freq
end
