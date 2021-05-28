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
;                         lkgk, input_polar_maps_param, lkgk_param
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
;        - lkgk: the leakage I, Q, U beams
;        - lkgk_param: the param structure that produced lkgk
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
;          - Feb. 2020: N. Ponthieu, cleaner and more modular version of nk_lkg_correct_4.pro
; 	- Sept. 2020 : H. Ajeddig & Ph. Andre made change on the appodisation parameters and corrected the offset in nk_rotates_stokes_maps, IP correction procedure now is performed     

pro nk_lkg_correct_5, param, info, grid, lkgk, input_map_fits_file, $
                      plot=plot, delta_deg=delta_deg, $
                      taper=taper, q_lkg=q_lkg, u_lkg=u_lkg
;-
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_lkg_correct_5'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; 1. retrieve input map
;; 2. Rotate kernel from Nasmyth to Radec
;; 3. Reproject kernel on output radec grid
;; 4. fft...
;; 5. Subtract

;; 1. Retrieve input maps and associated astrometry.
;; Cleaner via the fits file and ensures that the input map actually
;; is in RaDec.
nk_fits2grid, input_map_fits_file, input_polar_maps, header

;; 2. Rotate kernel from Nasmyth to radec
;; Mind the "-" in front of alpha.
delta = 0.d0
if keyword_set(delta_deg) then delta = delta_deg
nk_elparal2alpha, info.elev*!dtor, info.paral*!dtor, alpha, /nas_radec
nk_rotate_stokes_maps, lkgk.map_i_1mm, lkgk.map_q_1mm, lkgk.map_u_1mm, $
                       -alpha*!radeg + delta, $
                       lkg_i_radec, lkg_q_radec, lkg_u_radec


if keyword_set(plot) then begin
   wind, 1, 1, /free, /large
   @nk_lkg_correct_5_aux_plot_0
endif

;; 3. Reproject the kernel on grid (it does not have the same size a priori)
;; message, /info, "reprojecting kernel into current nasmyth grid"
i_kernel = dblarr( grid.nx, grid.ny)
q_kernel = dblarr( grid.nx, grid.ny)
u_kernel = dblarr( grid.nx, grid.ny)
npix = long(grid.nx)*long(grid.ny)
for ipix=0L, npix-1 do begin
   x = grid.xmap[ipix]
   y = grid.ymap[ipix]
   ix_in = floor( (x-lkgk.xmin)/lkgk.map_reso)
   iy_in = floor( (y-lkgk.ymin)/lkgk.map_reso)
   if (ix_in ge 0 and ix_in le (lkgk.nx-1) and $
       iy_in ge 0 and iy_in le (lkgk.ny-1)) then begin
      i_kernel[ipix] = lkg_i_radec[ix_in, iy_in]
      q_kernel[ipix] = lkg_q_radec[ix_in, iy_in]
      u_kernel[ipix] = lkg_u_radec[ix_in, iy_in]
   endif
endfor


;; Apodize maps in real space slightly to help FFt's
mask_xsize_k  = round( 150./grid.map_reso) ; reducing the mask erea ; Ph & H 
mask_ysize_k  = round( 150./grid.map_reso)
apod_length_k = round( 60./grid.map_reso)
poker_make_mask, mask_xsize_k, mask_ysize_k, 1, 0, 0, mask_k, $
                 nx_large=grid.nx, ny_large=grid.ny, apod_length=apod_length_k

if keyword_set(plot) then begin
   dp = {charsize:0.6, $
         charbar:0.6, $
         inside_bar:0, noerase:1, $
         xmap:grid.xmap, $
         ymap:grid.ymap, $
         xrange:[0.,0.], yrange:[0.,0.], $
         nobar:0, $
         coltable:4}
   phi = dindgen(360)*!dtor
   r = !nika.fwhm_nom[0]/2.
;;    wind, 1, 1, /free, /large
;;    @nk_lkg_correct_5_aux_plot_1
endif

;; Init angular power spectra
ipoker, i_kernel, grid.map_reso/60., k, junk, /rem, /bypass
k *= !arcsec2rad/(2*!dpi)       ; into arcsec^-1

if keyword_set(taper) then begin
   k_max  = 0.125 ;0.25 ; reducing to a factor of 2 
   k_edge = 0.09  ;0.18 
   nk = n_elements(k)
   taper = dblarr(nk) + 1.d0
   apod = (k_max-k_edge)
   wk = where( k ge k_edge and k le k_max, nwk)
   taper[wk] = (k_max-k[wk])/apod - 1.0d0/(2.0d0*!dpi)*sin(2.0d0*!dpi*(k_max-k[wk])/apod)
   taper[where(k ge k_max)] = 0.d0
   
   give_map_k, grid.map_reso, i_kernel, map_k
   k_edge_eff = max( map_k[where(map_k le k_edge)])
   k_max_eff  = min( map_k[where(map_k ge k_max)])
   wk = where( map_k ge k_edge_eff and map_k le k_max_eff)
   k_taper = map_k*0.d0
   apod = k_max_eff-k_edge_eff
   w = where( map_k le k_edge_eff)
   k_taper[w] = 1.d0
   k_taper[wk] = (k_max_eff-map_k[wk])/apod - 1.0d0/(2.0d0*!dpi)*sin(2.0d0*!dpi*(k_max_eff-map_k[wk])/apod)
endif

if keyword_set(plot) then begin
   wind, 1, 1, /free, /large
   @nk_lkg_correct_5_aux_plot_2
endif
;stop
; to save all data structures to test leakage correction 
;save, 'kernel_189_data_183.xdr',/all
;stop ; here instead of applying mask for both map and leakage we just applied to the leakage 
;; Apply apodizing mask
i_kernel *= mask_k
q_kernel *= mask_k
u_kernel *= mask_k

;; Derive Fourier kernels
fft_ik = fft( i_kernel, /double)
fft_qk = fft( q_kernel, /double)
fft_uk = fft( u_kernel, /double)

;; Apply taper
if defined(taper) then begin
   w = where( abs(fft_ik) gt 0)
   fft_qk *= k_taper
   fft_uk *= k_taper
endif

;; Derive convolution/deconvolution kernels
fft_q_kernel = fft_qk*0.        ; init
fft_u_kernel = fft_uk*0.        ; init
fft_q_kernel[w] = fft_qk[w]/fft_ik[w]
fft_u_kernel[w] = fft_uk[w]/fft_ik[w]
;; Derive leakage terms
fft_i = fft( input_polar_maps.map_i_1mm, /double)
fft_q = fft( input_polar_maps.map_q_1mm, /double)
fft_u = fft( input_polar_maps.map_u_1mm, /double)

q_lkg = double( fft( fft_i*fft_q_kernel, /double, /inv))
u_lkg = double( fft( fft_i*fft_u_kernel, /double, /inv))
;stop
if keyword_set(plot) then begin
   input_q1    = grid.map_q1
   input_q3    = grid.map_q3
   input_q_1mm = grid.map_q_1mm
   input_u1    = grid.map_u1
   input_u3    = grid.map_u3
   input_u_1mm = grid.map_u_1mm

   nk_grid2info, grid, info_b4, /noplot
endif
;stop
;; Apply the leakage correction
grid.map_q1    = input_polar_maps.map_q1 - q_lkg
grid.map_q3    = input_polar_maps.map_q3 - q_lkg
grid.map_q_1mm = input_polar_maps.map_q_1mm - q_lkg

grid.map_i_1mm = input_polar_maps.map_i_1mm 

grid.map_u1    = input_polar_maps.map_u1 - u_lkg
grid.map_u3    = input_polar_maps.map_u3 - u_lkg
grid.map_u_1mm = input_polar_maps.map_u_1mm - u_lkg
;stop
;H & Ph saving IU and IQ in grid 
grid.iu_lkg_1    = u_lkg
grid.iq_lkg_1    = q_lkg

if keyword_set(plot) then begin
   wind, 1, 1, /free, /large
   outplot, file='lkg_corr_'+param.scan, /png
   @nk_lkg_correct_5_aux_plot_3
   outplot, /close, /verb
endif

if param.cpu_time then nk_show_cpu_time, param

end
