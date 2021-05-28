
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

pro nk_lkg_correct2, param, info, data, kidpar, grid, $
                    input_polar_maps, lkg_kernel, gauss_regul=gauss_regul, astr=astr, align=align

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " nk_lkg_correct, param, info, data, kidpar, grid, $"
   print, "                 input_polar_maps, lkg_kernel, input_polar_maps_param, lkg_kernel_param"
   return
endif

;; Init
data_copy_lkg = data
   
;; Reproject input (ra-dec) maps in Nasmyth coordinates. For that, build fake timelines.
;; Input polar maps should be over pixelized w.r.t the current pipeline map and
;; because of the potential different resolution, we need to recompute the ipix
;; that matches input_polar_maps.
nk_get_ipix, param, info, data, kidpar, input_polar_maps, astr=astr

;; Only the I timeline is necessary here
nk_maps2data_toi, param, info, data, kidpar, input_polar_maps, output_toi,$
                  output_toi_i=output_toi_i, output_toi_q=output_toi_q, output_toi_u=output_toi_u, astr=astr
data_copy_lkg.toi   = output_toi_i

message, /info, "Reproject input_polar_maps in Nasmyth coordinates..."
;; define grid, compute pix coords in nasmyth, project
param1 = param ; init
param1.map_proj = "NASMYTH"
nk_get_kid_pointing_2, param1, info, data_copy_lkg, kidpar
nk_init_grid, param1, info, grid_in_nas_temp, header=header, astr=astr
nk_add_qu_to_grid, param1, grid_in_nas_temp
nk_get_ipix, param1, info, data_copy_lkg, kidpar, grid_in_nas_temp, astr=astr
nk_projection_4, param1, info, data_copy_lkg, kidpar, grid_in_nas_temp

;; if keyword_set(align) then begin
;;    ;; If there's a pointing offset between the current scan and
;;    ;; the input map and if the source is bright enough to fit its
;;    ;; position on this single scan, we can realign it and improve the subtraction

;;    ;; Project current data in Nasmyth coordinates
;;    grid_data_nasmyth = grid_in_nas_temp ; init
;;    data1 = data
;;    nk_get_kid_pointing, param1, info, data1, kidpar ; nasmyth dra ddec
;;    nk_get_ipix, param1, info, data1, kidpar, grid_data_nasmyth, astr=astr
;;    nk_projection_4, param1, info, data1, kidpar, grid_data_nasmyth

;;    ;; Fit centroids positions to re-align at 2mm where sources are
;;    ;; usually brighter (or bright enough if it's a planet)
;;    nk_map_photometry, grid_in_nas_temp.map_i2, grid_in_nas_temp.map_var_i2, grid_in_nas_temp.nhits_2, $
;;                       grid_in_nas_temp.xmap, grid_in_nas_temp.ymap, !nika.fwhm_nom[0], $
;;                       flux, sigma_flux, sigma_bg, output_fit_par_input, /grid_step, /educated, /noplot
;;    nk_map_photometry, grid_data_nasmyth.map_i2, grid_data_nasmyth.map_var_i2, grid_data_nasmyth.nhits_2, $
;;                       grid_data_nasmyth.xmap, grid_data_nasmyth.ymap, !nika.fwhm_nom[0], $
;;                       flux, sigma_flux, sigma_bg, output_fit_par_data, /grid_step, /educated, /noplot
;;    print, "output_fit_par_input[4]-output_fit_par_data[4]: ", output_fit_par_input[4]-output_fit_par_data[4]
;;    print, "output_fit_par_input[5]-output_fit_par_data[5]: ", output_fit_par_input[5]-output_fit_par_data[5]

;;    ;; Correct the pointing offset and reproject the input map aligned
;;    ;; on the current scan
;;    data_copy_lkg.dra  += output_fit_par_data[4] - output_fit_par_input[4]
;;    data_copy_lkg.ddec += output_fit_par_data[5] - output_fit_par_input[5]
;;    grid_input_nasmyth = grid_in_nas_temp ; init
;;    nk_get_ipix, param1, info, data_copy_lkg, kidpar, grid_input_nasmyth
;;    nk_projection_4, param1, info, data_copy_lkg, kidpar, grid_input_nasmyth

;;    data_copy_lkg.toi *= output_fit_par_data[1]/output_fit_par_input[1]
   
;;    wind, 1, 1, /free, /large
;;    imr = [0,15]                 ; !nika.flux_uranus[0]]
;;    outplot, file='compare_maps_'+strtrim(param.scan), /png
;;    my_multiplot, 2, 2, pp, pp1, /rev
;;    imview, grid_data_nasmyth.map_i_1mm, position=pp1[0,*], imr=imr
;;    imview, grid_in_nas_temp.map_i_1mm, position=pp1[1,*], /noerase, imr=imr
;;    imview, grid_data_nasmyth.map_i_1mm-grid_in_nas_temp.map_i_1mm, position=pp1[2,*], /noerase
;;    imview, grid_data_nasmyth.map_i_1mm-grid_input_nasmyth.map_i_1mm*output_fit_par_data[1]/output_fit_par_input[1], position=pp1[3,*], /noerase
;;    outplot, /close
;; endif

;; ;; Quicklook
;; wind, 1, 1, /free, /large, title='Nk_scan_reduce / lkg_correction'
;; my_multiplot, 2, 2, pp, pp1, /rev, /full
;; imview, grid_in_nas_temp.map_q_1mm, title='Q radec2nasmyth 1mm', position=pp1[0,*], imr=[-1,1]*0.1, /nobar
;; imview, grid_in_nas_temp.map_u_1mm, title='U radec2nasmyth 1mm', position=pp1[1,*], imr=[-1,1]*0.1, /nobar, /noerase
;; imview, lkg_kernel.map_q_1mm,   title='Lkg_Kernel Q nasmyth 1mm', position=pp1[2,*], imr=[-1,1]*0.5, /nobar, /noerase
;; imview, lkg_kernel.map_u_1mm,   title='Lkg_Kernel U nasmyth 1mm', position=pp1[3,*], imr=[-1,1]*0.5, /nobar, /noerase
;; my_multiplot, /reset
;; stop

;;----------------------------------------------------------------------
grid_input_nasmyth = grid_in_nas_temp ; AR to be fixed

;; Start to work in Fourier space
;; Init wave vectors
give_map_k, lkg_kernel.map_reso, lkg_kernel.map_i_1mm*0.d0, map_k

;; ;; Regularisation
d = sqrt( lkg_kernel.xmap^2 + lkg_kernel.ymap^2)
diam = 200.d0
wreg = where( d gt diam/2., nwreg)
if nwreg eq 0 then begin
   nk_error, info, "Wrong d range in wreg definition"
   return
endif

lambda = 1
nk_list_kids, kidpar, lambda=lambda, valid=w1, nval=nw1
map_i = grid_input_nasmyth.map_i_1mm
i_kernel = lkg_kernel.map_i_1mm
q_kernel = lkg_kernel.map_q_1mm
u_kernel = lkg_kernel.map_u_1mm
if keyword_set(gauss_regul) then begin
   fft_ik = fft( i_kernel, /double)
   fft_qk = fft( q_kernel, /double)
   fft_uk = fft( u_kernel, /double)
endif else begin
   i_kernel[wreg] = 0.d0
   q_kernel[wreg] = 0.d0
   u_kernel[wreg] = 0.d0

   ;; Zero padd signal intensity too
   map_i[wreg] = 0.d0
   
   ;; Derive kernels
   fft_ik = fft( i_kernel, /double)
   fft_qk = fft( q_kernel, /double)
   fft_uk = fft( u_kernel, /double)
endelse

w = where( fft_ik ne 0)
fft_q_kernel = fft_qk*0. ; init
fft_u_kernel = fft_uk*0. ; init
fft_q_kernel[w] = fft_qk[w]/fft_ik[w]
fft_u_kernel[w] = fft_uk[w]/fft_ik[w]

;   ;; Fourier transform the Intensity map
;   message, /info, "fix me: apodization of I"
;   g = exp(-(grid_input_nasmyth.xmap^2+grid_input_nasmyth.ymap^2)/(2.*150.^2))
;   map_i = map_i*g
;   stop

fft_i = fft( map_i, /double)

;; Derive leakage terms
q_lkg = double( fft( fft_i*fft_q_kernel, /double, /inv))
u_lkg = double( fft( fft_i*fft_u_kernel, /double, /inv))

if param.do_plot ne 0 then begin
   if param.plot_ps eq 0 then wind, 1, 1, /free, /xlarge
   my_multiplot, 3, 1, pp, pp1
   outplot, file=param.plot_dir+"/iqu_leakage_1mm", ps=param.plot_ps, png=param.plot_png
   imview, map_i, xmap=grid_input_nasmyth.xmap, ymap=grid_input_nasmyth.xmap, position=pp1[0,*], title='I '+strtrim(lambda,2), imr=[-1,1]*3 
   imview, filter_image(q_lkg,fwhm=3), xmap=grid_input_nasmyth.xmap, ymap=grid_input_nasmyth.xmap, position=pp1[1,*], title='Q leakage', /noerase
   imview, filter_image(u_lkg, fwhm=3), xmap=grid_input_nasmyth.xmap, ymap=grid_input_nasmyth.xmap, position=pp1[2,*], title='U leakage', /noerase
   outplot, /close
endif
;; Read these correction templates and subtract from TOI
nk_map2toi_3, param1, info, map_i, data_copy_lkg.ipix[w1], toi_i, $
              map_q=q_lkg, map_u=u_lkg, toi_q=toi_q, toi_u=toi_u

;; Rotate polarization back from Nasmyth to RA-Dec
;; data_prova = data
;; data_prova.toi_q = data.toi_q*0.d0
;; data_prova.toi_u = data.toi_u*0.d0   
alpha = -alpha_nasmyth(data.el) + data.paral - !dpi/4.
toi_q1 = (cos(2*alpha)##(dblarr(nw1)+1))*toi_q -(sin(2*alpha)##(dblarr(nw1)+1))*toi_u
toi_u  = (sin(2*alpha)##(dblarr(nw1)+1))*toi_q +(cos(2*alpha)##(dblarr(nw1)+1))*toi_u
toi_q  = toi_q1

;; data_prova.toi_u[w1,*]  = toi_u
;; data_prova.toi_q[w1,*]  = toi_q
;; nk_init_grid, param, info, grid_in_radec_temp, header=header, astr=astr
;; nk_add_qu_to_grid, param, grid_in_radec_temp
;; nk_get_kid_pointing, param, info, data_prova, kidpar
;; nk_get_ipix, param, info, data_prova, kidpar, grid_in_radec_temp, astr=astr
;; nk_projection_4, param, info, data_prova, kidpar, grid_in_radec_temp

;; ;; Quick look
;; my_multiplot, 2, 2, pp, pp1
;; imview, filter_image(grid_in_radec_temp.map_q_1mm, fwhm=3), xmap=grid_in_radec_temp.xmap, ymap=grid_in_radec_temp.xmap, $
;;         position=pp1[0,*], title='Q leakage2radec'
;; imview, filter_image(grid_in_radec_temp.map_u_1mm, fwhm=3), xmap=grid_in_radec_temp.xmap, ymap=grid_in_radec_temp.xmap, $
;;         position=pp1[1,*], title='U leakage2radec', /noerase
;; imview, filter_image(input_polar_maps.map_q_1mm, fwhm=3), xmap=grid_in_radec_temp.xmap, ymap=grid_in_radec_temp.xmap, $
;;         position=pp1[2,*], title='Q input radec map', /noerase
;; imview, filter_image(input_polar_maps.map_u_1mm, fwhm=3), xmap=grid_in_radec_temp.xmap, ymap=grid_in_radec_temp.xmap, $
;;         position=pp1[3,*], title='U input_radec map', /noerase
;; stop
data.toi_q[w1,*] -= toi_q
data.toi_u[w1,*] -= toi_u

;; restore nominal ipix for the rest of the pipeline, according to "grid"
;; conventions, not input_polar_maps
nk_get_ipix, param, info, data, kidpar, grid, astr=astr

end
