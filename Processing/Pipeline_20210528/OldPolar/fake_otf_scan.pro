
;; hacked from old Diabolo/Simu/IDL/nika_gen_scan.pro
;;
;; All coordinates in arcsec
;; No need to multiply by cosine elevation any more since we've been working in
;;(el,co-el) coordinates since June 2013.
;;-----------------------------------------------------

pro fake_otf_scan, nu_sampling, az_min, az_max, az_speed, n_subscans, el_min, el_step, ofs_az, ofs_el, subscan

;; Assume constant scan speed in az and no time between two subscans for simplicity
t_subscan = (az_max - az_min)/az_speed
nsn_subscan = round( t_subscan*nu_sampling)

;; Size of timelines
nsn     = n_subscans * nsn_subscan
ofs_az  = dblarr( nsn)
ofs_el  = dblarr( nsn)
subscan = intarr( nsn)

for i=0, n_subscans-1 do begin
   az_scan = dindgen(nsn_subscan)/nu_sampling*az_speed + az_min
   if (i mod 2) eq 0 then az_scan = reverse( az_scan)
   ofs_az[ i*nsn_subscan: (i+1)*nsn_subscan-1] = az_scan
   ofs_el[ i*nsn_subscan: (i+1)*nsn_subscan-1] = i*el_step + el_min
   subscan[i*nsn_subscan: (i+1)*nsn_subscan-1] = i
endfor

end
