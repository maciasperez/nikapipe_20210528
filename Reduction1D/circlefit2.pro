PRO circlefit2, xx, yy, xc, yc, radius,  avgdist, avgdist2,  $
               weight = weight, verbose = verbose
; Given coordinates (xx,yy) of  a set of 2D points, find the best circle
; going through the points, parametrized by the center coordinates and the
; radius. avgdist is the average distance between the data and the circle.
; A weight can be given
; Solution has been given by Aurélien Bideaud after web searching
; From R. Bullock
; FXD Feb. Bug corrected
; Introduce a linear fit as a comparison for dispersion
; Choose a center far away to make a pseudo-fitting circle in case of linear fit


npoint = n_elements( xx)
; should be at least 3

if keyword_set( weight) then ww = double( weight) $
  else ww = replicate(1.D0,  npoint)

; normalize weight
ww = ww / total( /double,  ww) * npoint

; Compute average of xx and yy
;xxmean = mean(xx)
;yymean = mean(yy)
xxmean = total( ww * xx, /double) / npoint
yymean = total( ww * yy, /double) / npoint

; compute the std dev
;xxstd = stddev( xx)
;yystd = stddev( yy)
xxstd = total( ww * (xx - xxmean)^2,  /double) / npoint
yystd = total( ww * (yy - yymean)^2,  /double) / npoint
zzstd = sqrt(xxstd^2 + yystd^2)

; Center and normalize the coordinates
xn = double(xx - xxmean) / zzstd
yn = double(yy - yymean) / zzstd

; Compute moments
S11 = total(/double, ww * xn * yn)
S20 = total(/double, ww * xn * xn)
S02 = total(/double, ww * yn * yn)
S12 = total(/double, ww * xn * yn * yn)
S21 = total(/double, ww * xn * xn * yn)
S30 = total(/double, ww * xn * xn * xn)
S03 = total(/double, ww * yn * yn * yn)

; Useful quantity
Denom = 2 * (S11 * S11 - S20 * S02)

; Center offsets
xoffc = (S11 * (S03 + S21) - S02 * (S30 + S12)) / Denom
yoffc = (S11 * (S30 + S12) - S20 * (S03 + S21)) / Denom

; Normalized radius
radiusn = sqrt( xoffc^2 + yoffc^2 + (S20 + S02) / npoint)

xc = xxmean + xoffc * zzstd
yc = yymean + yoffc * zzstd

radius = radiusn * zzstd

avgdist = sqrt( total( ww * $
   ( sqrt((xx - xc)^2 + (yy-yc)^2) - radius)^2,  /double) / (npoint-3) )

;; IF keyword_set( verbose) THEN BEGIN
;;   print, [S02, S11, S20] * zzstd^2
;;   print, [S12, S21, S30, S03] * zzstd^3
;;   print, [xoffc, yoffc] * zzstd
;;   print, total(/double, ww *      ( ( xn - xoffc)^2 + (yn - yoffc)^2 - radiusn^2))
;;   print, total(/double, ww * xn * ( ( xn - xoffc)^2 + (yn - yoffc)^2 - radiusn^2))
;;   print, total(/double, ww * yn * ( ( xn - xoffc)^2 + (yn - yoffc)^2 - radiusn^2))
;;   print, xoffc * S20 + yoffc * S11 - 0.5 * (S30 + S12)
;;   print, xoffc * S11 + yoffc * S02 - 0.5 * (S03 + S21)
;; ENDIF

; My dispersion
; Distance to center
mc = sqrt((xx-xc)^2+(yy-yc)^2)
; distance of point to circle
am = abs(mc+radius) < abs(mc-radius)
avgdist2 = sqrt( total( ww* $
                        am^2) / (npoint-3))


; Linear fit
; if dispersion is close to the radius then transform the linear fit into a
; pseudo-circle; done
; Should do something if slope is very large; done
; should use a least-square fit with equal weight to x and y; done
; 1000 found by trial and error
if radius lt 1000*avgdist then begin
   fitexy, xx, yy, cst, slo, $
           x_sig = 1./sqrt(ww>1D-30),  y_sig = 1./sqrt(ww>1D-30)
   if abs(slo) gt 1. then begin
      fitexy, yy, xx, cst, slo, $
              x_sig = 1./sqrt(ww>1D-30),  y_sig = 1./sqrt(ww>1D-30)
      dd = 5000*avgdist
      radiuslin = sqrt(1+1/slo^2)*abs(dd)
      xclin = xxmean-dd/slo
      yclin = yymean+dd
      if xclin^2+yclin^2 lt radiuslin^2 then begin
         dd = -5000*avgdist
         radiuslin = sqrt(1+1/slo^2)*abs(dd)
         xclin = xxmean-dd/slo
         yclin = yymean+dd
      endif
   endif else begin
      dd = 5000*avgdist
      radiuslin = sqrt(1+1/slo^2)*abs(dd)
;   radiuslin = sqrt(1+1/res[1]^2)*abs(dd)
      xclin = xxmean+dd
      yclin = yymean-dd/slo
;   yclin = yymean-dd/res[1]
      if xclin^2+yclin^2 lt radiuslin^2 then begin
         dd = -5000*avgdist
         radiuslin = sqrt(1+1/slo^2)*abs(dd)
         xclin = xxmean+dd
         yclin = yymean-dd/slo
      endif
   endelse
   
   mc = sqrt((xx-xclin)^2+(yy-yclin)^2)
; distance of point to circle
   am = abs(mc+radiuslin) < abs(mc-radiuslin)
   avgdist2 = sqrt( total( ww* $
                           am^2) / (npoint-3))
; Choose not to change avgdist
endif

if avgdist2 lt avgdist then begin
   ; keep the linear fit at the end
   radius = radiuslin
   xc = xclin
   yc = yclin
   IF keyword_set( verbose) THEN print, 'linear fit taken', radius/ avgdist
endif

RETURN
END

