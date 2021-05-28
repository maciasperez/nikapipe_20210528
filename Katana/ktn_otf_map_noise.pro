
PRO ktn_otf_map_noise, show_map=show_map
  common ktn_common

w1 = where( kidpar.type eq 1, nw1, compl=wbad, ncompl=nwbad)

print, "Combine all kids in a single map..."
;; Combine kids on a map with finer resolution
;; Striped down version of nk.pro
data1 = data
param1 = param
param1.do_opacity_correction=0
param1.map_center_ra  = !values.d_nan
param1.map_center_dec = !values.d_nan
nk_default_info, info1
nk_init_grid, param1, info1, grid_tot
nk_get_kid_pointing, param1, info1, data1, kidpar
nk_apply_calib, param1, info1, data1, kidpar
nk_deglitch_fast, param1, info1, data1, kidpar
nk_get_ipix, data1, info1, grid_tot
nk_w8, param1, info1, data1, kidpar
nk_projection_3, param1, info1, data1, kidpar, grid_tot
map     = grid_tot.map_i_1mm
map_var = grid_tot.map_var_i_1mm
nhits   = grid_tot.nhits_1mm
xx = grid_tot.xmap[*,0]
yy = grid_tot.ymap[0,*]

;; Derive a mask for decorrelation
mask = map*0.d0 + 1
w = where( map_var ne 0, nw)
if nw eq 0 then message, "No pixel with non zero variance."
map_sn = map*0.d0
map_sn[w] = map[w]/sqrt(map_var[w])
w = where( map_sn gt 5, nw)
mask[w] = 0.d0

;; Enlarge the mask a bit for safety
;; m = filter_image( mask, fwhm=1)
;; mask = long( m gt 0.99)
if param.lab ne 0 then begin
   kernel = [1.d0, 1.d0]
   mask1 = mask                 ; local copy
   nx = n_elements(mask[*,0])
   ny = n_elements(mask[0,*])
   for ix=0, nx-1 do begin
      mask1[ix,*]    = convol( reform(mask[ix,*]), kernel)/total(kernel)
      mask1[ix,0]    = mask[ix,0]            ; restore edge
      mask1[ix,ny-1] = mask[ix,ny-1]         ; restore edge
   endfor
   mask = long(mask1 eq 1)
endif

grid_tot.mask_source = mask
nk_mask_source, param1, info1, data1, kidpar, grid_tot
index = dindgen( n_elements(data1))
nsn = n_elements(data1)
for i=0, nw1-1 do begin
   ikid = w1[i]

   w = where( data1.off_source[ikid] eq 1, nw)

   ;; force the first/last index to be good anyway to avoid bad
   ;; interpolation/extrapolation on the edges of the subscans
   if w[0] ne 0 then w = [0, w]
   if w[nw-1] ne (nsn-1) then w = [w, nsn-1]
   r = interpol( data_copy[w].toi[ikid], index[w], index) ; work on original data in Hz
   data1.toi[ikid] = r                                    ; reuse data1.toi
endfor

;; Fill kidpar with noise params
data2 = data                    ; keep a copy
data  = data1
ktn_noise_estim
kidpar.noise_raw_source_interp_1Hz = kidpar.noise_1Hz
kidpar.noise_raw_source_interp_2Hz = kidpar.noise_2Hz
kidpar.noise_raw_source_interp_10Hz = kidpar.noise_10Hz
data = data2                    ; restore copy

;; Decorrelate
param1.decor_method = 'common_mode_kids_out'
nk_deglitch, param1, info1, data1, kidpar
nk_clean_data, param1, info1, data1, kidpar, out_temp_data=out_temp_data
stop

if keyword_set(show_map) then begin
   nk_w8, param1, info1, data1, kidpar
   nk_projection_3, param1, info1, data1, kidpar, grid_tot
   nefd_source = 1
   nefd_center = 1
   if max(grid_tot.map_var_i_1mm) gt 0 then begin
      nk_map_photometry, grid_tot.map_i_1mm, grid_tot.map_var_i_1mm, grid_tot.nhits_1mm, $
                         grid_tot.xmap, grid_tot.ymap, !nika.fwhm_nom[0], $
                         flux_1mm, sigma_flux_1mm, $
                         sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                         bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                         info=info1,$
                         /educated, title='1mm', param=param, noplot=noplot, image_only=image_only, $
                         NEFD_source=nefd_source, nefd_center=nefd_center
   endif
   if max(grid_tot.map_var_i_2mm) gt 0 then begin
      nefd_source = 1
      nefd_center = 1
      nk_map_photometry, grid_tot.map_i_2mm, grid_tot.map_var_i_2mm, grid_tot.nhits_2mm, $
                         grid_tot.xmap, grid_tot.ymap, !nika.fwhm_nom[0], $
                         flux_2mm, sigma_flux_2mm, $
                         sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
                         bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
                         info=info1, $
                         /educated, title='2mm', param=param, noplot=noplot, image_only=image_only, $
                         NEFD_source=nefd_source, nefd_center=nefd_center
   endif
   ;stop
endif

data2 = data                    ; keep a copy
data  = data1
ktn_noise_estim
kidpar.noise_source_interp_and_decorr_1Hz  = kidpar.noise_1Hz
kidpar.noise_source_interp_and_decorr_2Hz  = kidpar.noise_2Hz
kidpar.noise_source_interp_and_decorr_10Hz = kidpar.noise_10Hz
data = data2                    ; restore copy

end
