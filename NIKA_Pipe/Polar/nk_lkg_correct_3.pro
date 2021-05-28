
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_lkg_correct
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_lkg_correct, param, info, data, kidpar, grid, input_polar_maps,
;                         lkg_kernel, input_polar_maps_param, lkg_kernel_param
; 
; PURPOSE: 
;        Estimates the leakage of I into Q and U and subtracts it from
;data.toi_q and data.toi_u
; 
; INPUT: 
;        - param, info, data, kidpar, grid
;        - input_polar_maps: estimate of I, Q and U maps
;        - input_polar_maps_param: the parameter structure that produced
;          input_polar_maps
;        - lkg_kernel: the leakage I, Q, U beams
;        - lkg_kernel_param: the param structure that produced lkg_kernel
; 
; OUTPUT: 
;        - data.toi_q and data.toi_u are modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug. 13th, 2015: N. Ponthieu and A. Ritacco
;-

pro nk_lkg_correct_3, param, info, data, kidpar, grid, input_map_fits_file, $
                      lkg_kernel, gauss_regul=gauss_regul, astr=astr, align=align

if n_params() lt 1 then begin
   message, /info, "Calling sequence: TBD"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; 1. Define a Nasmyth grid large enough for both the data and the kernel
;; 2. Reproject input maps on this grid
;; 3. Reproject the lkg kernel on this grid
;; 4. Now that input maps and kernel have the same resolution and
;; size, we can work in Fourier space and derive the Q,U leakage maps
;; 5. Scan these Q and U maps to derive leakage Q,U-TOIs in Nasmyth coordinates
;; 6. Rotate these Q,U-TOIs in radec
;; 7. Subtract them from the current data.toi_q and data.toi_u
;;--------------------------------------------------------------------------------------------


;; 1. Init a grid in Nasmyth coordinates, large enough to accept the
;; rotated input maps and the current data + zero padding
message, /info, "Initializing Nasmyth grid"
azel2nasm, data.el, data.ofs_az, data.ofs_el, ofs_x, ofs_y
xmin = min(ofs_x) - 6.5/2.*60*1.3
xmax = max(ofs_x) + 6.5/2.*60*1.3
ymin = min(ofs_y) - 6.5/2.*60*1.3
ymax = max(ofs_y) + 6.5/2.*60*1.3
param_nas = param
param_nas.map_proj = "nasmyth"
param_nas.map_xsize = xmax-xmin
param_nas.map_ysize = ymax-ymin
param_nas.map_reso = 2 < param.map_reso
nk_init_grid, param_nas, info, grid_input_nasmyth
nk_add_qu_to_grid, param_nas, grid_input_nasmyth

;; 2. Reproject input (ra-dec) intensity map in Nasmyth coordinates. For that, build fake timelines.
;; Input polar maps should be over pixelized w.r.t the current pipeline map and
;; because of the potential different resolution, we need to recompute the ipix
;; that matches input_polar_maps.
;;
;; Retrieve input maps and associated astrometry.
;; Cleaner via the fits file and ensures that the input map actually
;; is in RaDec.
message, /info, "Reprojecting input maps from radec to nasmyth"
;nk_fits2grid, input_map_fits_file, input_polar_maps, header
nk_fits2grid, input_map_fits_file, input_polar_maps, header
;hamza
;nk_fits2grid, input_map_fits_file, grid, header, input_polar_maps
extast, header, astr
nk_maps2data_toi, param, info, data, kidpar, input_polar_maps, $
                  output_toi_i=output_toi_i, astr=astr
;; Only the I timeline is necessary here
input_data     = data
input_data.toi = output_toi_i
nk_get_kid_pointing_2, param_nas, info, input_data, kidpar
nk_get_ipix, param_nas, info, input_data, kidpar, grid_input_nasmyth
nk_projection_4, param_nas, info, input_data, kidpar, grid_input_nasmyth

;; 3. Reproject the kernel on grid_input_nasmyth
message, /info, "reprojecting kernel into current nasmyth grid"
nk_init_grid, param_nas, info, kernel
nk_add_qu_to_grid, param_nas, kernel
npix_nas = long(n_elements(kernel.xmap))
for ipix=0L, npix_nas-1 do begin
   x = kernel.xmap[ipix]
   y = kernel.ymap[ipix]
   ix_in = floor( (x-lkg_kernel.xmin)/lkg_kernel.map_reso)
   iy_in = floor( (y-lkg_kernel.ymin)/lkg_kernel.map_reso)
   if (ix_in ge 0 and ix_in le (lkg_kernel.nx-1) and $
       iy_in ge 0 and iy_in le (lkg_kernel.ny-1)) then begin
      kernel.map_i_1mm[ipix] = lkg_kernel.map_i_1mm[ix_in, iy_in]
      kernel.map_q_1mm[ipix] = lkg_kernel.map_q_1mm[ix_in, iy_in]
      kernel.map_u_1mm[ipix] = lkg_kernel.map_u_1mm[ix_in, iy_in]
   endif
endfor

;; wind, 1, 1, /free, /large
;; my_multiplot, 2, 3, pp, pp1
;; imview, lkg_kernel.map_i_1mm, position=pp1[0,*], title='(in) Lkg_kernel.map_i_1mm'
;; imview, kernel.map_i_1mm, position=pp1[1,*], title='(out) kernel.map_i_1mm', /noerase
;; imview, lkg_kernel.map_q_1mm, position=pp1[2,*], title='(in) Lkg_kernel.map_q_1mm', /noerase
;; imview, kernel.map_q_1mm, position=pp1[3,*], title='(out) kernel.map_q_1mm', /noerase
;; imview, lkg_kernel.map_u_1mm, position=pp1[4,*], title='(in) Lkg_kernel.map_u_1mm', /noerase
;; imview, kernel.map_u_1mm, position=pp1[5,*], title='(out) kernel.map_u_1mm', /noerase

;; 4. Now that input maps and kernel have the same resolution and
;; size, we can work in Fourier space and derive the Q,U leakage maps

;; Regularisation
d = sqrt( lkg_kernel.xmap^2 + lkg_kernel.ymap^2)
diam = 200.d0
wreg = where( d gt diam/2., nwreg)
if nwreg eq 0 then begin
   nk_error, info, "Wrong d range in wreg definition"
   return
endif

if keyword_set(gauss_regul) then begin
   fft_ik = fft( kernel.map_i_1mm, /double)
   fft_qk = fft( kernel.map_q_1mm, /double)
   fft_uk = fft( kernel.map_u_1mm, /double)
endif else begin
   kernel.map_i_1mm[wreg] = 0.d0
   kernel.map_q_1mm[wreg] = 0.d0
   kernel.map_u_1mm[wreg] = 0.d0

   ;; Zero padd signal intensity too
   grid_input_nasmyth.map_i_1mm[wreg] = 0.d0
   
   ;; Derive kernels
   fft_ik = fft( kernel.map_i_1mm, /double)
   fft_qk = fft( kernel.map_q_1mm, /double)
   fft_uk = fft( kernel.map_u_1mm, /double)
endelse

w = where( fft_ik ne 0)
fft_q_kernel = fft_qk*0. ; init
fft_u_kernel = fft_uk*0. ; init
fft_q_kernel[w] = fft_qk[w]/fft_ik[w]
fft_u_kernel[w] = fft_uk[w]/fft_ik[w]

;; Derive leakage terms
fft_i = fft( grid_input_nasmyth.map_i_1mm, /double)
q_lkg = double( fft( fft_i*fft_q_kernel, /double, /inv))
u_lkg = double( fft( fft_i*fft_u_kernel, /double, /inv))
;;;Hamza added this to this script
;; Apply the leakage correction
grid_input_nasmyth.map_q1    -= q_lkg
grid_input_nasmyth.map_q3    -= q_lkg
grid_input_nasmyth.map_q_1mm -= q_lkg

grid_input_nasmyth.map_u1    -= u_lkg
grid_input_nasmyth.map_u3    -= u_lkg
grid_input_nasmyth.map_u_1mm -= u_lkg

;; wind, 1, 1, /free, /large
;; !mamdlib.coltable = 4
;; xra = kernel.nx/2 + [-1,1]*50./kernel.map_reso
;; yra = kernel.ny/2 + [-1,1]*50./kernel.map_reso
;; my_multiplot, 3, 3, pp, pp1, /rev
;; imview, kernel.map_i_1mm, xra=xra, yra=yra, /inside, position=pp1[0,*], title='kernel I', imr=imr_i
;; imview, kernel.map_q_1mm, xra=xra, yra=yra, /inside, position=pp1[1,*], title='kernel Q', /noerase, imr=imr_q
;; imview, kernel.map_u_1mm, xra=xra, yra=yra, /inside, position=pp1[2,*], title='kernel U', /noerase, imr=imr_u
;; imview, double(fft(fft_i,/double,/inverse)), xra=xra, yra=yra, /inside, position=pp1[3,*], title=' fft_i^-1', /noerase, imr=imr_i
;; imview, q_lkg, xra=xra, yra=yra, /inside, position=pp1[4,*], title='Q lkg', /noerase, imr=imr_q
;; imview, u_lkg, xra=xra, yra=yra, /inside, position=pp1[5,*], title='U lkg', /noerase, imr=imr_u
;; imview, kernel.map_i_1mm - double(fft(fft_i,/double,/inverse)), xra=xra, yra=yra, /inside, position=pp1[6,*], /noerase, title='kernel I', imr=imr_i
;; imview, kernel.map_q_1mm - q_lkg, xra=xra, yra=yra, /inside, position=pp1[7,*], title='kernel Q - Qlkg', /noerase, imr=imr_q
;; imview, kernel.map_u_1mm - u_lkg, xra=xra, yra=yra, /inside, position=pp1[8,*], title='kernel U - Ulkg', /noerase, imr=imr_u
;; stop

;; 5. Read these correction templates and subtract from TOI
nk_list_kids, kidpar, lambda=1, valid=w1, nval=nw1
nk_map2toi_3, param_nas, info, grid_input_nasmyth.map_i_1mm, input_data.ipix[w1], toi_i, $
              map_q=q_lkg, map_u=u_lkg, toi_q=toi_q, toi_u=toi_u

;; 6. Rotate leakage polarization from Nasmyth to Radec
;; alpha = -alpha_nasmyth(data.el) + data.paral - !dpi/4.
;;
;; to match nk_nasmyth2sky_polar_2, Dec. 2018:
;alpha = alpha_nasmyth(data.el) - data.paral + !dpi/4.
nk_elparal2alpha, data.el*!dtor, data.paral*!dtor, alpha, /nas_radec
;; wind, 1, 1, /free
;; !p.multi=[0,1,2]
;; plot, data.el*!radeg, /xs, /ys
;; plot, data.paral*!radeg, /xs, /ys
;; !p.multi=0

cos2alpha = cos(2*alpha)##(dblarr(nw1)+1)
sin2alpha = sin(2*alpha)##(dblarr(nw1)+1)
toi_q1 = cos2alpha*toi_q - sin2alpha*toi_u
toi_u  = sin2alpha*toi_q + cos2alpha*toi_u
toi_q  = toi_q1

data.toi_q[w1,*] -= toi_q
data.toi_u[w1,*] -= toi_u

if param.cpu_time then nk_show_cpu_time, param

end
