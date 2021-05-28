
;+
; PURPOSE:
;   calculate the deflection field by a spherical cluster of NFW
;   density profile
; VERSION:
;   2013, May 17th: LP extracted the deflexion routine
;  first created by LP in 2013, May 7th 
;-


;angsize=10.
;pixsize=0.03
;nx=angsize/pixsize
;x=dblarr(nx+1,nx+1)
;vecy=(dindgen(nx+1)*pixsize - 0.5*angsize)*!dpi/180d0/60d0
;y=(dblarr(nx+1)+1d0)#vecy
;x=transpose(y)
 
pro nfw_deflexion, x, y, m200, c200, z_cluster, params, dx, dy, doplot=doplot

;+
; AIM: calculating either: 
;  - the deflexion due to a cluster in a given direction
;  - or the deflection map produced by a cluster
; in the ideal case of an isolated cluster with a NFW density profile 
;
; REF: Eq.~6 in Dodelson 0402314
;
; INPUTS: 
;    x, y: direction scalar or array (set the output dimension)
;    m200 (in solar mass), c200 (no unit), z_cluster (redchift): cluster params
;    params: structure of cosmo params
;
; OUTPUTS:
;    dx, dy: deflection field in x, y directions 
;
; DEPENDENCIES:
;  rho_crit_z, flat_ang_dist, clusterlens_grandf
;
; HISTORY:
;    2013, May 17th: LP, extracted from Labtools/LP/
;    2013, May 7th : LP, first creation 
;- 

; ref: pdg 2008
;-------------------
; critical density today:
; NB: rho_0 = rho_crit_0/h^2:
rho_0 = 2.77536627e11 ; h^2 M_sum / Mpc^3
; speed of light
c=299792.458 ; km/s
; ref: e.g. planck 2013 cosmo paper
; redshift to the last scattering surface  
z_cmb=1090.

; input format: only for scalar or square map 
testok=1
nx=n_elements(x)
ny=n_elements(y)
if (nx ne ny) then testok=0

; concentration parameter checking
if (c200 le -1.0) then testok=0

;;
;; START CALCULATING
;;_____________________________________
if testok then begin
   nn=nx
   ;rho_c_z = 3d*hubble_z(z_cluster,params)^2/8d/!dpi/G
   ;more precise: directly from the value of rho_c today
   rho_c_z = rho_crit_z(z_cluster,params)
   r200 = (3d0/200d0*m200/4d0/!dpi/rho_c_z)^(1d/3d)
   ;8piG=3H0^2/rho_crit_0
   huitpig=3d4/rho_0
   D_lens = flat_ang_dist(z_cluster,params)
   ; 1 - chi_S/chi_L
   K=1d0 - (z_cluster+1d0)*D_lens/(z_cmb+1d0)/flat_ang_dist(z_cmb,params)
   fc200 = 1d/(alog(c200+1d) - c200/(c200+1d))
   d0 = -0.5*huitpig/!dpi/c^2*m200*fc200*c200/r200*K
   if (nn eq 1) then begin
      theta=sqrt(x^2+y^2)
      rrs = D_lens*theta*c200/r200
      dd = d0*clusterlens_grandf(rrs)
      dx = dd*x/theta
      dy = dd*y/theta
   endif else begin
      print,"calculating dmap"
      theta=sqrt(x^2+y^2)
      ;dispim_bar, theta, /aspect,/nocont
      rrs = theta*D_lens*c200/r200 
      ;dispim_bar, rrs, /aspect,/nocont
      dd = d0*clusterlens_grandf(rrs)
      dx = dd*x/theta
      dy = dd*y/theta
      if keyword_set(doplot) then dispim_bar, sqrt(dy^2+dx^2)*180.*60./!dpi, /aspect,/nocont,crange=[0.,1.], title="deflection amplitude"
   endelse
;;
;; NOT OK
;;_____________________________________
endif else begin
   print,"unvalid x or/and y format"
   dx=-1
   dy=-1
endelse

return
end


