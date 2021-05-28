function hubble_z, z, params
;+
; aim: 
;      calcule H(z) en km/s/Mpc
; inputs:
;      z
;      params : structure contenant les params cosmo 
; NB: pas pris en compte la radiation
; NB: flat Universe. 
;-

gdoml = omegalambda(params.omb, params.omc, params.mnu, params.H0)
hz = sqrt((params.omb+params.omc+(params.mnu/93.04))*1d4*(z+1d)^3 + gdoml*params.H0^2)

return, hz
end
