
;+
;
; SOFTWARE: 
;        General astro tools
;
; NAME: 
;        polangle_conv_coord
;
; CATEGORY: 
;        general
;
; CALLING SEQUENCE:
;
; 
; PURPOSE: 
;        Convert the polarization angle in equatorial IAU convention to Galactic
;        WMAP/Planck/Healpix convention
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 5th, 2018: NP
;-

pro polangle_conv_coord, source_ra_deg, source_dec_deg, polangle_deg_equ_iau, polangle_deg_gal, $
                         plot=plot

;; convert coordinates from radec to galactic:
euler, source_ra_deg, source_dec_deg, source_lon, source_lat, 1

;; init
lon_lat = dblarr(1,2)

;; Vector in Gal coord
lon_lat[0,*] = [source_lon, source_lat]
OM0_gal = ll2uv( lon_lat)

;; Vector in Equ coord
lon_lat[0,*] = [source_ra_deg, source_dec_deg]
OM0_equ  = ll2uv( lon_lat)

;; Derive standard spherical coordinates
lb2thetaphi, source_lon,    source_lat,     theta_gal, phi_gal
lb2thetaphi, source_ra_deg, source_dec_deg, theta_equ, phi_equ

;; Derive unit vectors tangent coordinate vectors
ephi_gal   = [-sin(phi_gal), cos(phi_gal), 0.d0]
etheta_gal = crossp( OM0_gal, ephi_gal)

ephi_equ   = [-sin(phi_equ), cos(phi_equ), 0.d0]
etheta_equ = crossp( OM0_equ, ephi_equ)

;; ** warning: I have to switch the sign of the rot angle in rot_axis ***
;; ** due to the internal convention clockwise when looking from the center to
;; the surrounding sphere rather than counter-clockwise as defined by IAU) **
phi = source_ra_deg*!dtor
ephi = [-sin(phi), cos(phi), 0.d0]
rot_axis, OM0_equ, -polangle_deg_equ_iau, R, v=ephi
pol_vec_equ = R##etheta_equ

;; 2. make v1 in Equ coord that makes the measured polar. angle w.r.t etheta
epsilon = 0.01                  ; compared to unitary coordinates sphere
OM1_equ = OM0_equ + epsilon*pol_vec_equ

;; 4. rotate M0, M1 in gal coord using euler.pro
lon_lat_m1_equ = uv2ll(OM1_equ)
euler, lon_lat_m1_equ[0], lon_lat_m1_equ[1], l_m1_gal, b_m1_gal, 1

;; 5. derive M0M1 and compute angle of M1M2 w.r.t etheta_gal
lon_lat[0,*] = [l_m1_gal, b_m1_gal]
OM1_gal = ll2uv( lon_lat)
M0M1 = OM1_gal - OM0_gal

;; Angle compared to etheta_gal
x = -total( M0M1 * ephi_gal)
y =  total( M0M1 * etheta_gal)
;; yes it is atan(x,y) in Healpix/WMAP/Planck convention, not atan(y,x)
polangle_deg_gal = atan( x, y)*!radeg

;; draw a curve
if keyword_set(plot) then begin
   alpha_eq = dindgen(180)
   alpha_gal = dblarr(180)
   for i=0, n_elements(alpha_eq)-1 do begin
      rot_axis, OM0_equ, -alpha_eq[i], R, v=ephi
      pol_vec_equ = R##etheta_equ
      OM1_equ = OM0_equ + epsilon*pol_vec_equ
      lon_lat_m1_equ = uv2ll(OM1_equ)
      euler, lon_lat_m1_equ[0], lon_lat_m1_equ[1], l_m1_gal, b_m1_gal, 1
      lon_lat[0,*] = [l_m1_gal, b_m1_gal]
      OM1_gal = ll2uv( lon_lat)
      M0M1 = OM1_gal - OM0_gal
      x = -total( M0M1 * ephi_gal)
      y =  total( M0M1 * etheta_gal)
      alpha_gal[i] = atan( x, y)*!radeg
   endfor

   wind, 1, 1, /free
   plot, alpha_eq, alpha_gal, /xs, /ys, $
         xtitle='Equatorial IAU convention', ytitle='Galactic Planck convention'
   legendastro, ['R. A.: '+string(source_ra_deg,form='(F7.2)'), $
                 'Dec  : '+string(source_dec_deg,form='(F7.2)')], /right
endif

end
