function clusterlens_m2r, m, n, z, cosmo
;+
;  mass param (M_n) to radius param (r_n) of a cluster at z in a given comsology
;-

rho_c_z=rho_crit_z(z,cosmo)
r = (3d/n*m/4d/!dpi/rho_c_z)^(1d/3d)

return, r

end
