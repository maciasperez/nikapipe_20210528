
pro nika_pipe_simu_polar_maps, ps, maps_S0, maps_S1, maps_S2

npix    = long(ps.sky.nx)*long(ps.sky.ny)
maps_s0 = dblarr( npix, 2)
maps_s1 = dblarr( npix, 2)
maps_s2 = dblarr( npix, 2)

sigma_1mm = ps.instr.fwhm_1mm/60.*!fwhm2sigma*!arcmin2rad
sigma_2mm = ps.instr.fwhm_2mm/60.*!fwhm2sigma*!arcmin2rad

res_arcmin = ps.sky.reso_map/60.

;; Same seed to have the same signal for the two bands
seed_in = long( randomu( seed, 1)*1e8)

cls2map, [0,1], [0,1], ps.sky.nx, ps.sky.ny, res_arcmin, junk, cu_t, map_k, index=ps.sky.diffuse_index

beam_1mm = exp(-map_k*(map_k+1.d0)*sigma_1mm^2/2.d0)
beam_2mm = exp(-map_k*(map_k+1.d0)*sigma_2mm^2/2.d0)

cu2maps, cu_t, res_arcmin, map_t1mm, beam_t=beam_1mm, seed_tt=seed_in
cu2maps, cu_t, res_arcmin, map_t2mm, beam_t=beam_2mm, seed_tt=seed_in

;; 1mm
maps_s0[*,0] = map_t1mm
maps_s1[*,0] = map_t1mm * ps.sky.pol_deg * cos( 2.d0*ps.sky.alpha_pol)
maps_s2[*,0] = map_t1mm * ps.sky.pol_deg * sin( 2.d0*ps.sky.alpha_pol)

;; 2mm
maps_s0[*,1] = map_t2mm
maps_s1[*,1] = map_t2mm * ps.sky.pol_deg * cos( 2.d0*ps.sky.alpha_pol)
maps_s2[*,1] = map_t2mm * ps.sky.pol_deg * sin( 2.d0*ps.sky.alpha_pol)

end

