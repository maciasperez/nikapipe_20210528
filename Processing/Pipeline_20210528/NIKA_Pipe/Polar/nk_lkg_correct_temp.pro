
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
;        - Nov. 26th, 2017: A.Ritacco
;-

pro nk_lkg_correct_temp, param, info, data, kidpar, grid, $
                    input_polar_maps, lkg_kernel, input_polar_maps_param, lkg_kernel_param, $
                    align=align, gauss_regul=gauss_regul

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
nk_maps2data_toi, param, info, data, kidpar, $
                  input_polar_maps, output_toi, $
                  output_toi_i=output_toi_i, astr=astr
data_copy_lkg.toi = output_toi_i

message, /info, "Reproject input_polar_maps in Nasmyth coordinates..."
;; define grid, compute pix coords in nasmyth, project
param1 = param ; init
param1.map_proj = "NASMYTH"
nk_init_grid, param1, info, grid_in_nas_temp
nk_add_qu_to_grid, param1, grid_in_nas_temp
nk_get_kid_pointing, param1, info, data_copy_lkg, kidpar
nk_get_ipix, param1, info, data_copy_lkg, kidpar, grid_in_nas_temp, astr=astr
nk_projection_4, param1, info, data_copy_lkg, kidpar, grid_in_nas_temp

if keyword_set(align) then begin
   ;; If there's a pointing offset between the current scan and
   ;; the input map and if the source is bright enough to fit its
   ;; position on this single scan, we can realign it and improve the subtraction

   ;; Project current data in Nasmyth coordinates
   grid_data_nasmyth = grid_in_nas_temp ; init
   data1 = data
   nk_get_kid_pointing, param1, info, data1, kidpar ; nasmyth dra ddec
   nk_get_ipix, data1, info, grid_data_nasmyth
   nk_projection_3, param1, info, data1, kidpar, grid_data_nasmyth

   ;; Fit centroids positions to re-align at 2mm where sources are
   ;; usually brighter (or bright enough if it's a planet)
   nk_map_photometry, grid_in_nas_temp.map_i_2mm, grid_in_nas_temp.map_var_i_2mm, grid_in_nas_temp.nhits_2mm, $
                      grid_in_nas_temp.xmap, grid_in_nas_temp.ymap, !nika.fwhm_nom[0], $
                      flux, sigma_flux, sigma_bg, output_fit_par_input, /educated, /noplot
   nk_map_photometry, grid_data_nasmyth.map_i_2mm, grid_data_nasmyth.map_var_i_2mm, grid_data_nasmyth.nhits_2mm, $
                      grid_data_nasmyth.xmap, grid_data_nasmyth.ymap, !nika.fwhm_nom[0], $
                      flux, sigma_flux, sigma_bg, output_fit_par_data, /educated, /noplot
;;   print, "output_fit_par_input[4]-output_fit_par_data[4]: ", output_fit_par_input[4]-output_fit_par_data[4]
;;   print, "output_fit_par_input[5]-output_fit_par_data[5]: ", output_fit_par_input[5]-output_fit_par_data[5]

   ;; Correct the pointing offset and reproject the input map aligned
   ;; on the current scan
   data_copy_lkg.dra  += output_fit_par_data[4] - output_fit_par_input[4]
   data_copy_lkg.ddec += output_fit_par_data[5] - output_fit_par_input[5]

;;    openw, lu, "align_res_"+param.scan+".dat", /get_lun
;;    printf, lu, output_fit_par_data[4] - output_fit_par_input[4], $
;;            output_fit_par_data[5] - output_fit_par_input[5], output_fit_par_data[1]/output_fit_par_input[1]
;;    close, lu
;;    free_lun, lu
   
endif
grid_input_nasmyth = grid_in_nas_temp ; init
nk_get_ipix, data_copy_lkg, info, grid_input_nasmyth
nk_projection_3, param1, info, data_copy_lkg, kidpar, grid_input_nasmyth

if keyword_set(align) then begin
   data_copy_lkg.toi *= output_fit_par_data[1]/output_fit_par_input[1]
   
;;    wind, 1, 1, /free, /large
;;    imr = [0,15]                 ; !nika.flux_uranus[0]]
;;    outplot, file='compare_maps_'+strtrim(param.scan), /png
;;    my_multiplot, 2, 2, pp, pp1, /rev
;;    imview, grid_data_nasmyth.map_i_2mm, position=pp1[0,*], imr=imr
;;    imview, grid_in_nas_temp.map_i_2mm, position=pp1[1,*], /noerase, imr=imr
;;    imview, grid_data_nasmyth.map_i_2mm-grid_in_nas_temp.map_i_2mm, position=pp1[2,*], /noerase
;;    imview, grid_data_nasmyth.map_i_2mm-grid_input_nasmyth.map_i_2mm*output_fit_par_data[1]/output_fit_par_input[1], position=pp1[3,*], /noerase
;;    outplot, /close
endif

;; ;; Quicklook
;; wind, 1, 1, /free, /large, title='Nk_scan_reduce / lkg_correction'
;; my_multiplot, 4, 2, pp, pp1, /rev, /full
;; imview, grid_input_nasmyth.map_q_1mm, title='Q radec2nasmyth 1mm',      position=pp1[0,*], imr=[-1,1]*0.1, /nobar
;; imview, grid_input_nasmyth.map_u_1mm, title='U radec2nasmyth 1mm',      position=pp1[1,*], imr=[-1,1]*0.1, /nobar, /noerase
;; imview, grid_input_nasmyth.map_q_2mm, title='Q radec2nasmyth 2mm',      position=pp1[2,*], imr=[-1,1]*0.1, /nobar, /noerase
;; imview, grid_input_nasmyth.map_u_2mm, title='U radec2nasmyth 2mm',      position=pp1[3,*], imr=[-1,1]*0.1, /noerase
;; imview, lkg_kernel.map_q_1mm,   title='Lkg_Kernel Q nasmyth 1mm', position=pp1[4,*], imr=[-1,1]*0.5, /nobar, /noerase
;; imview, lkg_kernel.map_u_1mm,   title='Lkg_Kernel U nasmyth 1mm', position=pp1[5,*], imr=[-1,1]*0.5, /nobar, /noerase
;; imview, lkg_kernel.map_q_2mm,   title='Lkg_Kernel Q nasmyth 2mm', position=pp1[6,*], imr=[-1,1]*0.5, /nobar, /noerase
;; imview, lkg_kernel.map_u_2mm,   title='Lkg_Kernel U nasmyth 2mm', position=pp1[7,*], imr=[-1,1]*0.5, /noerase
;; my_multiplot, /reset
;; stop

;;----------------------------------------------------------------------
;; Start to work in Fourier space

;; Init wave vectors
give_map_k, lkg_kernel.map_reso, lkg_kernel.map_i_2mm*0.d0, map_k

;; Regularisation
d = sqrt( lkg_kernel.xmap^2 + lkg_kernel.ymap^2)
diam = 150.d0
wreg = where( d gt diam/2., nwreg)
if nwreg eq 0 then begin
   nk_error, info, "Wrong d range in wreg definition"
   return
endif

for lambda=1, 2 do begin
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nval=nw1

   if lambda eq 1 then begin
      map_i = grid_input_nasmyth.map_i_1mm
      message, /info, "fix me: kmax is still hardcoded"
      kmax = 0.2
      i_kernel = lkg_kernel.map_i_1mm
      q_kernel = lkg_kernel.map_q_1mm
      u_kernel = lkg_kernel.map_u_1mm
   endif else begin
      map_i = grid_input_nasmyth.map_i_2mm
      message, /info, "fix me: kmax is still hardcoded"
      kmax = 0.08
      i_kernel = lkg_kernel.map_i_2mm
      q_kernel = lkg_kernel.map_q_2mm
      u_kernel = lkg_kernel.map_u_2mm
   endelse

   if keyword_set(gauss_regul) then begin
;      message, /info, "not implemented yet"
;      save, file='all.save'
;      message, /info, "save everything and return"
;      return

      sigma_q = 15.             ; arcsec
      sigma_i = 30.             ; arcsec
      gi = exp(-(grid.xmap^2+grid.ymap^2)/(2.*sigma_i^2))
      gq = exp(-(grid.xmap^2+grid.ymap^2)/(2.*sigma_q^2))
      gu = gq

      give_map_k, 1, lkg_kernel.map_i_1mm, map_k

      fft_i  = fft( lkg_kernel.map_i_1mm, /double)
      fft_ig = fft( lkg_kernel.map_i_1mm*gi, /double)
      fft_qg = fft( lkg_kernel.map_q_1mm*gq, /double)
      fft_ug = fft( lkg_kernel.map_u_1mm*gu, /double)

      sigma = 1.d0/0.1
      beam_k = exp(-map_k^2*sigma^2/2.)
      q_lkg = double( fft( fft_i*beam_k*fft_qg/fft_ig, /double, /inverse))
      q_lkg /= 0.55 ; from empirical fit
      u_lkg = double( fft( fft_i*beam_k*fft_ug/fft_ig, /double, /inverse))
      u_lkg /= 0.55 ; from empirical fit
      
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
      kernel_q = fft_qk*0. + 1.d0 ; init
      kernel_u = fft_uk*0. + 1.d0 ; init
      w = where( map_k le kmax, nw, compl=wbigk, ncompl=nwbigk)
      if nw eq 0 then begin
         nk_error, info, "Incompatible minmax(map_k)=["+strtrim(min(map_k),2)+", "+strtrim(max(map_k),2)+"] and kmax="+strtrim(kmax,2)
         return
      endif
      kernel_q[w] = fft_qk[w]/fft_ik[w]
      kernel_u[w] = fft_uk[w]/fft_ik[w]

      ;; Fourier transform the Intensity map
      fft_i = fft( map_i, /double)
      if nwbigk ne 0 then fft_i[wbigk] = 0.d0

      ;; Derive leakage terms
      q_lkg = double( fft( fft_i*kernel_q, /double, /inv))
      u_lkg = double( fft( fft_i*kernel_u, /double, /inv))
   endelse
   
   if param.do_plot ne 0 then begin
      if lambda eq 1 then begin
         ;; Compare this derived corrections to signal maps
         imr_q = [-1,1]*0.1
         imr_u = [-1,1]*0.1
         wind, 1, 1, /free, /large, title='Nk_scan_reduce / lkg_correction'
         my_multiplot, 4, 2, pp, pp1, /rev, /full
         if param.plot_png eq 1 then outplot, file='Radec2nasmyth_vs_lkg_correction_'+strtrim(param.scan,2), /png
         imview, grid_input_nasmyth.map_q_1mm, title='Q radec2nasmyth 1mm', position=pp1[0,*], imr=imr_q, /nobar
         imview, grid_input_nasmyth.map_u_1mm, title='U radec2nasmyth 1mm', position=pp1[1,*], imr=imr_u, /nobar, /noerase
         imview, grid_input_nasmyth.map_q_2mm, title='Q radec2nasmyth 2mm', position=pp1[2,*], imr=imr_q, /nobar, /noerase
         imview, grid_input_nasmyth.map_u_2mm, title='U radec2nasmyth 2mm', position=pp1[3,*], imr=imr_u, /nobar, /noerase
         imview, q_lkg, title='Q leakage nasmyth 1mm',      position=pp1[4,*], imr=imr_q, /nobar, /noerase
         imview, u_lkg, title='U leakage nasmyth 1mm',      position=pp1[5,*], imr=imr_u, /nobar, /noerase
      endif else begin
         imview, q_lkg, title='Q leakage nasmyth 2mm',      position=pp1[6,*], imr=imr_q, /nobar, /noerase
         imview, u_lkg, title='U leakage nasmyth 2mm',      position=pp1[7,*], imr=imr_u, /nobar, /noerase
         if param.plot_png eq 1 then outplot, /close
         my_multiplot, /reset
      endelse
   endif

   ;; Read these correction templates and subtract from TOI
   nk_map2toi_3, param1, info1, map_i, data_copy_lkg.ipix[w1], toi_i, $
                 map_q=q_lkg, map_u=u_lkg, toi_q=toi_q, toi_u=toi_u
   
   ;; Rotate polarization back from Nasmyth to RA-Dec
   alpha = alpha_nasmyth(data.el) - data.paral
   toi_q1 = ( cos(2*alpha)##(dblarr(nw1)+1))*toi_q - (sin(2*alpha)##(dblarr(nw1)+1))*toi_u
   toi_u  = ( sin(2*alpha)##(dblarr(nw1)+1))*toi_q + (cos(2*alpha)##(dblarr(nw1)+1))*toi_u
   toi_q  = toi_q1
   
   data.toi_q[w1] -= toi_q
   data.toi_u[w1] -= toi_u
   
endfor

;; restore nominal ipix for the rest of the pipeline, according to "grid"
;; conventions, not input_polar_maps
nk_get_ipix, param, info, data, kidpar, grid, astr=astr

end
