
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
;-

pro nk_lkg_correct_4, param, info, grid, lkgk, input_map_fits_file, plot=plot, delta_deg=delta_deg

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_lkg_correct_4, param, info, grid, lkgk, input_map_fits_file"
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
;; message, /info, "Reprojecting input maps from radec to nasmyth"
nk_fits2grid, input_map_fits_file, input_polar_maps, header
extast, header, astr

;; 2. Rotate kernel from Nasmyth to radec
delta = 0.d0
if keyword_set(delta_deg) then delta = delta_deg
nk_rotate_stokes_maps, lkgk.map_i_1mm, lkgk.map_q_1mm, lkgk.map_u_1mm, $
                       -info.elev+info.paral + 76.2 -90. + delta, $
                       lkg_i_radec, lkg_q_radec, lkg_u_radec

if keyword_set(plot) then begin
   wind, 1, 1, /free, /large
   dp = {charsize:0.6, $
         charbar:0.6, $
         inside_bar:0, noerase:1, $
         xmap:input_polar_maps.xmap, $
         ymap:input_polar_maps.ymap, $
         xrange:[0.,0.], yrange:[0.,0.], $
         legend_text:strarr(3), legend_charsize:0.6, leg_color:255, $
         coltable:4}
   
   my_multiplot, 3, 3, pp, pp1, /rev, /full, /dry
   
   imr_p = [-1,1]*0.3
   dp.xrange = [-1,1]*40
   dp.yrange = dp.xrange

   phi = dindgen(360)*!dtor
   r = !nika.fwhm_nom[0]/2.
   
   imview, grid.map_i_1mm, dp=dp, title = 'Input I (radec)', position=pp1[0,*], imr=[-1,1]*10
   oplot, r*cos(phi), r*sin(phi), col=255
   imview, grid.map_q_1mm, dp=dp, title='Input Q (radec) (norm)', position=pp1[1,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255
   imview, grid.map_u_1mm, dp=dp, title='Input U (radec) (norm)', position=pp1[2,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255
   
   dp.xmap = lkgk.xmap
   dp.ymap = lkgk.ymap
   dp.legend_text = 'lkg_I_radec'
   imview, lkg_i_radec, dp=dp, title='i_map', position=pp1[3,*], imr=[-1,1]*10
   oplot, r*cos(phi), r*sin(phi), col=255
   legendastro, 'Delta = '+strtrim(delta,2), /bottom, textcol=255

   dp.legend_text = 'lkg_q_radec (norm)'
   imview, lkg_q_radec/max(lkg_i_radec)*max(grid.map_i_1mm), dp=dp, position=pp1[4,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255
   legendastro, 'Delta = '+strtrim(delta,2), /bottom, textcol=255
   
   dp.legend_text = 'lkg_u_radec (norm)'
   imview, lkg_u_radec/max(lkg_i_radec)*max(grid.map_i_1mm), dp=dp, position=pp1[5,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255
   legendastro, 'Delta = '+strtrim(delta,2), /bottom, textcol=255

   nk_fitmap, grid.map_i_1mm, grid.map_var_i_1mm, grid.xmap, grid.ymap, output_fit_par, map_fit=map_fit
   nk_fitmap, lkgk.map_i_1mm, lkgk.map_var_i_1mm, lkgk.xmap, lkgk.ymap, outpar
   print, output_fit_par
   print, outpar
   print, output_fit_par[4]-outpar[4], output_fit_par[5]-outpar[5]

   nx_shift = round( (output_fit_par[4]-outpar[4])/grid.map_reso)
   ny_shift = round( (output_fit_par[5]-outpar[5])/grid.map_reso)
   print, "nx_shift, ny_shift: ", nx_shift, ny_shift
   
   lkg_i_shift = shift( lkg_i_radec/max(lkg_i_radec)*max(grid.map_i_1mm), nx_shift, ny_shift)
   lkg_q_shift = shift( lkg_q_radec/max(lkg_i_radec)*max(grid.map_i_1mm), nx_shift, ny_shift)
   lkg_u_shift = shift( lkg_u_radec/max(lkg_i_radec)*max(grid.map_i_1mm), nx_shift, ny_shift)

   dp.legend_text = 'I diff (norm to max Input I)'
   imview, grid.map_i_1mm - lkg_i_shift, $
           dp=dp, position=pp[0,2,*], imr=[-1,1]*10
   oplot, r*cos(phi), r*sin(phi), col=255
   oplot, [output_fit_par[4]], [output_fit_par[5]], psym=1, col=100

   dp.legend_text = 'Q diff (norm)'
   imview, grid.map_q_1mm - lkg_q_shift, $
           dp=dp, position=pp[1,2,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255
   dp.legend_text = 'U diff (norm)'
   imview, grid.map_u_1mm - lkg_u_shift, $
           dp=dp, position=pp[2,2,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255

   wind, 1, 1, /free, /large
   smin = -3
   smax = 0
   my_multiplot, smax-smin+1, smax-smin+1, pp, pp1, /rev, /full, /dry
   p=0
   for nx_shift=smin, smax do begin
      for ny_shift =smin, smax do begin
         lkg_i_shift = shift( lkg_i_radec/max(lkg_i_radec)*max(grid.map_i_1mm), nx_shift, ny_shift)
         lkg_q_shift = shift( lkg_q_radec/max(lkg_i_radec)*max(grid.map_i_1mm), nx_shift, ny_shift)
         lkg_u_shift = shift( lkg_u_radec/max(lkg_i_radec)*max(grid.map_i_1mm), nx_shift, ny_shift)
         dp.legend_text = ['nx_shift '+strtrim(long(nx_shift),2), $
                           "ny_shift: "+strtrim(long(ny_shift),2)]
         imview, grid.map_i_1mm - lkg_i_shift, $
                 dp=dp, position=pp1[p,*], imr=[-1,1]*10
         oplot, r*cos(phi), r*sin(phi), col=255
         p++
      endfor
   endfor

   stop
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

;; if keyword_set(plot) then begin
;;    wind, 2, 2, /free, /large
;;    my_multiplot, 3, 2, pp, pp1, /rev
;;    dp.legend_text=''
;;    dp.xmap = lkgk.xmap
;;    dp.ymap = lkgk.ymap
;;    imview, lkg_i_radec, dp=dp, title='i_map', position=pp1[0,*], imr=[-1,1]*10
;;    imview, lkg_q_radec/max(lkg_i_radec), dp=dp, title='lkg_q_radec (norm)', position=pp1[1,*] ;, imr=[-1,1]*0.01
;;    imview, lkg_u_radec/max(lkg_i_radec), dp=dp, title='lkg_u_radec (norm)', position=pp1[2,*] ;, imr=[-1,1]*0.01
;;    
;;    dp.xmap = grid.xmap
;;    dp.ymap = grid.ymap
;;    imview, i_kernel, dp=dp, title='I_kernel (reproj on grid)', position=pp1[3,*], imr=[-1,1]*10
;;    imview, q_kernel, dp=dp, title='Q_kernel (reproj on grid)', position=pp1[4,*]
;;    imview, u_kernel, dp=dp, title='U_kernel (reproj on grid)', position=pp1[5,*]
;;    stop
;; endif

;; Apodize maps in real space slightly to help FFt's
mask = dblarr(grid.nx,grid.ny) + 1.d0
poker_make_mask, grid.nx, grid.ny, 1., 0., 0., $
                 mask, apod_length=grid.nx/4

;; Taper limits
k_max = 0.12
k_edge = 0.08

if keyword_set(plot) then begin
   wind, 1, 1, /free, /large
   my_multiplot, 4, 3, pp, pp1, /rev
   imview, i_kernel, position=pp[0,0,*], /noerase
   imview, q_kernel, position=pp[1,0,*], /noerase, imr=[-1,1]*0.3
   imview, u_kernel, position=pp[2,0,*], /noerase, imr=[-1,1]*0.3
   imview, mask,     position=pp[3,0,*], /noerase, title='Real space mask'
   imview, shift( abs( fft( i_kernel, /double)), grid.nx/2, grid.ny/2), position=pp[0,1,*], /noerase, imr=imr_i_kernel
   legendastro, 'fft(i_kernel)', textcol=255
   imview, shift( abs( fft( q_kernel, /double)), grid.nx/2, grid.ny/2), position=pp[1,1,*], /noerase, imr=imr_q_kernel
   legendastro, 'fft(q_kernel)', textcol=255
   imview, shift( abs( fft( u_kernel, /double)), grid.nx/2, grid.ny/2), position=pp[2,1,*], /noerase, imr=imr_u_kernel
   legendastro, 'fft(u_kernel)', textcol=255
   imview, shift( abs( fft( i_kernel*mask, /double)), grid.nx/2, grid.ny/2), position=pp[0,2,*], /noerase, imr=imr_i_kernel
   legendastro, 'fft(i_kernel*mask)', textcol=255
   imview, shift( abs( fft( q_kernel*mask, /double)), grid.nx/2, grid.ny/2), position=pp[1,2,*], /noerase, imr=imr_q_kernel
   legendastro, 'fft(q_kernel*mask)', textcol=255
   imview, shift( abs( fft( u_kernel*mask, /double)), grid.nx/2, grid.ny/2), position=pp[2,2,*], /noerase, imr=imr_u_kernel
   legendastro, 'fft(u_kernel*mask)', textcol=255

   ipoker, i_kernel, grid.map_reso/60., k, pk_i_kernel, /rem, /bypass
   ipoker, q_kernel, grid.map_reso/60., k, pk_q_kernel, /rem, /bypass
   ipoker, u_kernel, grid.map_reso/60., k, pk_u_kernel, /rem, /bypass
   
   ipoker, mask*i_kernel, grid.map_reso/60., k, pk_i_kernel_apod, /rem, /bypass
   ipoker, mask*q_kernel, grid.map_reso/60., k, pk_q_kernel_apod, /rem, /bypass
   ipoker, mask*u_kernel, grid.map_reso/60., k, pk_u_kernel_apod, /rem, /bypass

   k *= !arcsec2rad/(2*!dpi)    ; into arcsec^-1
   ;; sigma_k = 1.d0/sqrt(4*!dpi*(!nika.fwhm_nom[0]*!fwhm2sigma)^2)

   wind, 2, 2, /free, /large
   my_multiplot, 1, 4, pp, pp1, /rev
   plot, k, pk_i_kernel, position=pp1[0,*], xtitle='k', ytitle='P(k)'
   oplot, k, pk_i_kernel_apod, col=70
   
   w = where( pk_i_kernel gt max(pk_i_kernel)/20.)
   oplot, k[w], pk_i_kernel[w], psym=8, syms=0.5
   fit = linfit( k[w]^2, alog(pk_i_kernel[w]))
   oplot, k, exp(fit[0])*exp(fit[1]*k^2), col=250
   legendastro, ['I_kernel', 'I_kernel_apod'], col=[!p.color,70]

   plot, k, pk_q_kernel, position=pp1[1,*], /noerase, xtitle='k', ytitle='P(k)'
   oplot, k, pk_q_kernel_apod, col=70
   legendastro, ['Q_kernel', 'Q_kernel_apod'], col=[!p.color,70]
   
   plot, k, pk_u_kernel, position=pp1[2,*], /noerase, xtitle='k', ytitle='P(k)'
   oplot, k, pk_u_kernel_apod, col=70
   legendastro, ['U_kernel', 'U_kernel_apod'], col=[!p.color,70]
   
   plot, k, pk_q_kernel/pk_i_kernel, position=pp1[3,*], /noerase, xtitle='k', ytitle='P(k)'
   oplot, k, pk_q_kernel/pk_i_kernel, col=150
   oplot, k, pk_u_kernel/pk_i_kernel, col=200

;; taper
   nk = n_elements(k)
   taper = dblarr(nk) + 1.d0
   apod = (k_max-k_edge)
   wk = where( k ge k_edge and k le k_max, nwk)
   taper[wk] = (k_max-k[wk])/apod - 1.0d0/(2.0d0*!dpi)*sin(2.0d0*!dpi*(k_max-k[wk])/apod)
   taper[where(k ge k_max)] = 0.d0
   oplot, k, taper*0.5, col=250
   stop
endif

i_kernel *= mask
q_kernel *= mask
u_kernel *= mask

;; Derive Fourier kernels
fft_ik = fft( i_kernel, /double)
fft_qk = fft( q_kernel, /double)
fft_uk = fft( u_kernel, /double)

;; Define taper in Fourier space
give_map_k, grid.map_reso, i_kernel, map_k
k_edge_eff = max( map_k[where(map_k le k_edge)])
k_max_eff  = min( map_k[where(map_k ge k_max)])
wk = where( map_k ge k_edge_eff and map_k le k_max_eff)
k_taper = map_k*0.d0
apod = k_max_eff-k_edge_eff
w = where( map_k le k_edge_eff)
k_taper[w] = 1.d0
k_taper[wk] = (k_max_eff-map_k[wk])/apod - 1.0d0/(2.0d0*!dpi)*sin(2.0d0*!dpi*(k_max_eff-map_k[wk])/apod)
if keyword_set(plot) then begin
   wind, 1, 1, /f
   imview, shift(k_taper,grid.nx/2,grid.ny/2), title='Fourier taper'
   stop
endif

;; Apply taper
w = where( abs(fft_ik) gt 0)
fft_qk *= k_taper
fft_uk *= k_taper

;; Derive convolution/deconvolution kernels
fft_q_kernel = fft_qk*0.        ; init
fft_u_kernel = fft_uk*0.        ; init
fft_q_kernel[w] = fft_qk[w]/fft_ik[w]
fft_u_kernel[w] = fft_uk[w]/fft_ik[w]

;; Derive leakage terms
fft_i = fft( input_polar_maps.map_i_1mm*mask, /double)
q_lkg = double( fft( fft_i*fft_q_kernel, /double, /inv))
u_lkg = double( fft( fft_i*fft_u_kernel, /double, /inv))

if keyword_set(plot) then begin
   dp.xrange = [-1,1]*100
   dp.yrange = dp.xrange
   wind, 1, 1, /free, /large
   my_multiplot, 3, 3, pp, pp1, /rev, gap_y=0.02

   imr_i = [-1,1]*1
   imr_p = [-1,1]*0.5

   dp.legend_text = 'Input I (radec)'
   imview, grid.map_i_1mm, dp=dp, position=pp1[0,*], imr=imr_i
   dp.legend_text = 'Input Q (radec) (norm)'
   oplot, r*cos(phi), r*sin(phi), col=255

   imview, grid.map_q_1mm, dp=dp, $
           imrange=imr_p, position=pp1[1,*]
   dp.legend_text = 'Input U (radec) (norm)'
   oplot, r*cos(phi), r*sin(phi), col=255
   imview, grid.map_u_1mm, dp=dp, $
           imrange=imr_p, position=pp1[2,*]
   oplot, r*cos(phi), r*sin(phi), col=255

   dp.legend_text = 'fft(fft_i)!u-1!n'
   imview, double( fft( fft_i, /double, /inv)), dp=dp, position=pp1[3,*], imr=imr_i

   dp.legend_text = 'Q_lkg'
   imview, q_lkg, dp=dp, title='q_lkg', position=pp1[4,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255
   dp.legend_text = 'U_lkg'
   imview, u_lkg, dp=dp, title='u_lkg', position=pp1[5,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255

   dp.legend_text = 'grid.map_q - q_lkg'
   imview, grid.map_q_1mm-q_lkg, dp=dp, position=pp1[7,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255
   dp.legend_text = 'grid.map_u - u_lkg'
   imview, grid.map_u_1mm-u_lkg, dp=dp, position=pp1[8,*], imr=imr_p
   oplot, r*cos(phi), r*sin(phi), col=255

   wind, 2, 2, /free, /large
   my_multiplot, 1, 2, pp, pp1, /rev
   plot, grid.map_q_1mm[*,grid.ny/2], /xs, position=pp1[0,*]
   oplot, q_lkg[*,grid.ny/2], col=250
   legendastro, ['Q in', 'Q lkg'], line=0, col=[!p.color, 250]
   plot, grid.map_u_1mm[*,grid.ny/2], /xs, position=pp1[1,*], /noerase
   oplot, u_lkg[*,grid.ny/2], col=250
   legendastro, ['U in', 'U lkg'], line=0, col=[!p.color, 250]

   stop
endif

;; Apply the leakage correction
grid.map_q1    -= q_lkg
grid.map_q3    -= q_lkg
grid.map_q_1mm -= q_lkg

grid.map_u1    -= u_lkg
grid.map_u3    -= u_lkg
grid.map_u_1mm -= u_lkg

if param.cpu_time then nk_show_cpu_time, param

end
