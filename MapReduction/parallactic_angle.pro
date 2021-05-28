function parallactic_angle, az, el, sitelat = sitelat
; Compute the parallactic angle 
; All angles in radians
; Default sitelat is for Pico Veleta
; source adapted from http://www.petermeadows.com/html/parallactic.html
; FXD March 2014

if keyword_set( sitelat) then slat = sitelat else $
; deg-->rad geodetic latitude north for Pico Veleta
     slat = 37.0684132670517D0/180D0*!dpi 

;; Adopting the usual convention about azimuth reference (not that of
;; IRAM!)
return, atan( cos( slat) * sin( -az), $
              sin( slat) * cos( el) - cos( slat) * sin( el) * cos( -az) )

end
