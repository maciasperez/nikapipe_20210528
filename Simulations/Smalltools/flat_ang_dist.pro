function flat_ang_dist, z, params
;+
; PURPOSE: calculate the angular dsitance in flat universe 
;-
c=299792.458 ; km/s (PDG 2008)

nint=1000.*z 
zprim = (dindgen(nint+1)/double(nint))*z

gdoml = omegalambda(params.omb, params.omc, params.mnu, params.H0)
;hz = sqrt((params.omb+params.omc+0.0006)*1d4*(z+1d)^3 + gdoml*params.H0^2)

I = int_tabulated(zprim, 1d/sqrt((params.omb+params.omc+(params.mnu/93.04))*1d4*(zprim+1d)^3 + gdoml*params.H0^2))

Dang = c/(1+z)*I

return, dang
end
