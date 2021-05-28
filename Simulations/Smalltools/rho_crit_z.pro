function rho_crit_z, z, params
;+
; aim: 
;      calcule rho_c(z) en M_sun / Mpc^3
; inputs:
;      z
;      params : structure contenant les params cosmo 
; NB: pas pris en compte la radiation
; NB: flat Universe. 
;
;-

; pdg 2008
rho_c_0 = 2.77536627e11 ; h^2 M_sum / Mpc^3

gdoml = omegalambda(params.omb, params.omc, params.mnu, params.H0)
rho_c_z = rho_c_0*((params.omb+params.omc+(params.mnu/93.04))*(z+1d)^3 + gdoml*params.H0^2*1d-4)

return, rho_c_z
end
