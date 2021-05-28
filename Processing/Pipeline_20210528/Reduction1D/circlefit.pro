PRO circlefit, xx, yy, xc, yc, radius,  avgdist,  $
               weight = weight, verbose = verbose, zzmin=zzmin
; Given coordinates (xx,yy) of  a set of 2D points, find the best circle
; going through the points, parametrized by the center coordinates and the
; radius. avgdist is the average distance between the data and the circle.
; A weight can be given
; Solution has been given by Aurélien Bideaud after web searching
; From R. Bullock
; FXD Feb. Bug corrected


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

;; If the circle is too large, approximate by a straight line
if keyword_set(zzmin) then begin
   if zzstd lt zzmin then begin
      mx = median(xx)
      my = median(yy)
      fit = linfit( xx-mx, yy-my, /double)
;      x1 = xx[0]
;      y1 = yy[0]

      w = where( abs(xx-mx) ge 2*stddev(xx), nw)
      if nw eq 0 then begin
         message, /info, "No at 2sigma from the median"
         stop
      endif
      x1 = xx[w[0]]
      y1 = yy[w[0]]

      c1 = -1.d0/fit[1]
      radius = 1.d3
      xc = x1 - radius/sqrt(1.d0+c1^2)
      yc = y1 -c1*(x1-xc)

      avgdist = sqrt( avg( (yy-(yc+c1*(xx-xc)))^2))

;;       wind, 1, 1, /free
;;       plot, xx, yy, /xs, psym=1, thick=2
;;       oplot, xx, fit[0] + my + fit[1]*(xx-mx), col=250
;;       oplot, xx, yc + c1*(xx-xc), col=150
;; 
;; stop

;; 
;;       atam1 = dblarr(2,2)
;;       atnm1d = dblarr(2)
;;       n = n_elements(xx)
;;       determinant     = n*total(xx^2, /double)-total(xx,/double)^2
;;       atam1[0,0] = total(xx^2,/double)
;;       atam1[1,0] = -total(xx,/double)
;;       atam1[0,1] = atam1[1,0]
;;       atam1[1,1] = n
;;       atam1 = atam1/determinant
;;       atnm1d[0] = total(yy,/double)
;;       atnm1d[1] = total(xx*yy,/double)
;;       fit = atam1##atnm1d
;;       print, "my fit: ", fit

;      radius = 1.d3
;      xm = xx[0]
;      ym = yy[0]
;      xc = xm + radius
;      yc = ym

;;      
;;      plot, xx, yy, psym=1
;;      oplot, [xm], [ym], psym=1, col=250, thick=2
;;      oplot, xx, fit[0] + fit[1]*xx, col=70
;;stop

      return
   endif
endif

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

IF keyword_set( verbose) THEN BEGIN
   print, [S02, S11, S20] * zzstd^2
   print, [S12, S21, S30, S03] * zzstd^3
   print, [xoffc, yoffc] * zzstd
   print, total(/double, ww *      ( ( xn - xoffc)^2 + (yn - yoffc)^2 - radiusn^2))
   print, total(/double, ww * xn * ( ( xn - xoffc)^2 + (yn - yoffc)^2 - radiusn^2))
   print, total(/double, ww * yn * ( ( xn - xoffc)^2 + (yn - yoffc)^2 - radiusn^2))
   print, xoffc * S20 + yoffc * S11 - 0.5 * (S30 + S12)
   print, xoffc * S11 + yoffc * S02 - 0.5 * (S03 + S21)
ENDIF

RETURN
END

