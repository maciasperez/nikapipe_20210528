;+
;
; SOFTWARE: 
;           NIKA Simulations Pipeline
; 
; PURPOSE: 
;           Add sky noise to the simulated data.
; INPUT: 
;           Parameters of the sky.
; OUTPUT: 
;           The simulated sky noise.
; KEYWORDS:
;           seed, disk_convolve
; EXAMPLE:
;
; MODIFICATION HISTORY: 
;           24/05/2015: Alessia Ritacco (ritacco@lpsc.in2p3.fr) 
;           creation from nika_sky_noise_2.pro (Remi ADAM - adam@lpsc.in2p3.fr)
;
;-


pro nk_sky_noise, t, deltax, deltay, cloud_vx, cloud_vy, alpha_atm, sx, sky_noise_toi, $
                      seed=seed, disk_convolve=disk_convolve


nkid      = n_elements(deltax)
ntime     = n_elements(t)
tmax      = max(t)
nu_sample = 1.0d0/(t[1]-t[0])
x_max     = tmax * cloud_vx
y_max     = tmax * cloud_vy
nx        = long( 1.5*x_max/sx)
ny        = nx

sky_noise_toi = dblarr(nkid,ntime)

;; Generate atmosphere
if not keyword_set(seed) then seed = long( randomu( s, 1)*1e8)
;; Smooth the atmospheric map by a disk of 30m
DT30m = 30.0d0 ; telescope diameter [m]

if keyword_set(disk_convolve) then rdisk_convolve = DT30m/sx else rdisk_convolve=0.d0

; Xavier's Diabolo/Pipeline/Iram2010_red/Simu : 
nks_atm_map, nx, ny, alpha_atm, seed, map, rdisk_convolve = rdisk_convolve

;; Generate atmosphere TOI
cloud_x_start = sx*nx/4.
cloud_y_start = sx*ny/4.
cloud_x       = cloud_vx*dindgen( ntime)/nu_sample
cloud_y       = cloud_vy*dindgen( ntime)/nu_sample

;x = cloud_x_start + cloud_x ; in meters
;y = cloud_y_start + cloud_y

;; Interpolate leads to smoother (hence more realistic) differences between
;; pixels then the pure pixelized values of the above solution
for it=0L, ntime-1 do begin
   ;; detcoord, fp, fpc, az_fpc[it]/60., el_fpc[it]/60., xoff_deg, yoff_deg, 'nasmyth', out_coord_type, elev=elev, /k_cosel
   ;; deltax = tan( xoff_deg*!dtor) * cloud_h * cos( elev*!dtor) ; in meters
   ;; deltay = tan( yoff_deg*!dtor) * cloud_h

   x = cloud_x_start + deltax + cloud_x[it] ; in meters
   y = cloud_y_start + deltay + cloud_y[it]

   ;sky_noise_toi[*,it] = interpolate( map, x/sx, y/sx, missing = !undef, cubic = -0.5)
   sky_noise_toi[*,it] = interpolate( map, x/sx, y/sx, cubic = -0.5)
endfor

end
