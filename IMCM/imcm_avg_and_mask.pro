
;+
pro imcm_avg_and_mask, input_txt_file, scan_list_file, iter
;-

if n_params() lt 1 then begin
   dl_unix, 'imcm_avg_and_mask'
   return
endif

;; Get input parameters
@read_imcm_input_txt_file
param.project_dir = dir_basename+"/iter"+strtrim(iter,2)
; A forgotten setup FXD March 2021
param.imcm_iter = iter

;; Get list of scans
readcol, scan_list_file, scan_list, format='A', comment='#', /silent
nscans = n_elements(scan_list)

;; Do some useful bookkeeping for the next iteration 
if param.method_num eq 120 then begin
   nk_write_info2csv, root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+'/iter'+strtrim(iter,2), $
                      param.version, scan_list, infall, source
endif                           ; must be done before averaging the scans if split_horver=3

;; Average scans
if defined(output_fits_second_header_file) then begin
   nk_average_scans, param, scan_list, grid, $
                     output_fits_file=param.project_dir+"/map_2ndHeader.fits", $
                     tau_w8=tau_w8, /noplot, /results2, dmm_grid_tot=dmm_grid_tot
endif
nk_average_scans, param, scan_list, grid, $
                  output_fits_file=param.project_dir+"/map.fits", $
                  tau_w8=tau_w8, /noplot, info = info, dmm_grid_tot=dmm_grid_tot

;Write info
nk_info2csv, info, param.project_dir+'/info_'+source+'_v'+ $
             strtrim(param.version, 2)+'.csv'

;; Generate subtract maps for the next iteration if needed w/o SNR
;; based masks
if defined(no_mask) eq 0 then no_mask=0

if no_mask eq 1 then begin
   nk_fits2grid, param.project_dir+"/map.fits", subtract_maps
   nk_fits2grid, param.project_dir+"/map_JK.fits", map_jk
   subtract_maps.iter_mask_1mm = 0.d0
   subtract_maps.iter_mask_2mm = 0.d0
   map_jk.iter_mask_1mm = 0.d0
   map_jk.iter_mask_2mm = 0.d0
   if keyword_set( param.split_horver) then begin
      nk_fits2grid, param.project_dir+"/map_HOR.fits",map_hor
      nk_fits2grid, param.project_dir+"/map_VER.fits",map_ver
      map_hor.iter_mask_1mm = 0.d0
      map_hor.iter_mask_2mm = 0.d0
      map_ver.iter_mask_1mm = 0.d0
      map_ver.iter_mask_2mm = 0.d0
   endif
endif else begin

   if defined(force_mask_fits_file) then begin
      ;; to impose an external mask
      nk_fits2grid, param.project_dir+"/map.fits", subtract_maps
      mask = mrdfits( force_mask_fits_file, /silent)
      subtract_maps.iter_mask_1mm = mask ; same mask at 1 and 2mm to test start
      subtract_maps.iter_mask_2mm = mask ; same mask at 1 and 2mm to test start
      nk_fits2grid, param.project_dir+"/map_JK.fits", map_jk
      mask = mrdfits( force_mask_fits_file, /silent)
      map_jk.iter_mask_1mm = mask ; same mask at 1 and 2mm to test start
      map_jk.iter_mask_2mm = mask ; same mask at 1 and 2mm to test start
   endif else begin

      ;; Derive the masks from the data
      imcm_make_mask, param.project_dir+"/map.fits", $
                      param.project_dir+"/map_JK.fits", subtract_maps, $
                      snr_thres_1mm=snr_thres_1mm, $
                      snr_thres_2mm=snr_thres_2mm, $
                      snr_thres_q=snr_thres_q, snr_thres_u=snr_thres_u, /noplot, $
                      radius=radius_iter_mask, sz=sz, $
                      title_in='iter '+strtrim(iter,2), $
                      same_mask_at_1_and_2mm=same_mask_at_1_and_2mm, $
                      param=param
      nk_fits2grid, param.project_dir+"/map_JK.fits", map_jk
      map_jk.iter_mask_1mm = subtract_maps.iter_mask_1mm
      map_jk.iter_mask_2mm = subtract_maps.iter_mask_2mm

   endelse
endelse

if keyword_set(radius_iter_mask) then begin
   w = where( sqrt( subtract_maps.xmap^2 + subtract_maps.ymap^2) $
              gt radius_iter_mask, nw)
   if nw ne 0 then begin
      subtract_maps.iter_mask_1mm[w] = 0.d0
      subtract_maps.iter_mask_2mm[w] = 0.d0
      map_jk.iter_mask_1mm[w] = 0.d0
      map_jk.iter_mask_2mm[w] = 0.d0
   endif
endif

subtract_maps.map_i_2mm     = subtract_maps.map_i2
subtract_maps.map_var_i_2mm = subtract_maps.map_var_i2
subtract_maps.nhits_2mm     = subtract_maps.nhits_2
map_jk.map_i_2mm     = map_jk.map_i2
map_jk.map_var_i_2mm = map_jk.map_var_i2
map_jk.nhits_2mm     = map_jk.nhits_2
if keyword_set( param.split_horver) then begin
   map_hor.map_i_2mm = map_hor.map_i2
   map_hor.map_var_i_2mm = map_hor.map_var_i2
   map_hor.nhits_2mm = map_hor.nhits_2
   map_ver.map_i_2mm = map_ver.map_i2
   map_ver.map_var_i_2mm = map_ver.map_var_i2
   map_ver.nhits_2mm = map_ver.nhits_2
endif

;; If requested, define a mask to limit the derivation of snr_toi to
;; regions where the number of hits is larger than a threshold. This
;; way, map edges in particular do not appear a large SNR regions of
;; the map in snr_toi.
If defined(snr_mask_hits_threshold) then begin
   whits = where( subtract_maps.nhits_1mm ne 0, nwhits)
   subtract_maps.snr_mask_1mm = double( subtract_maps.nhits_1mm $
                                        ge snr_mask_hits_threshold* $
                                        median( subtract_maps.nhits_1mm[whits]))
   map_jk.snr_mask_1mm = double( subtract_maps.nhits_1mm $
                                        ge snr_mask_hits_threshold* $
                                        median( subtract_maps.nhits_1mm[whits]))
   whits = where( subtract_maps.nhits_2mm ne 0, nwhits)
   subtract_maps.snr_mask_2mm = double( subtract_maps.nhits_2mm $
                                        ge snr_mask_hits_threshold* $
                                        median( subtract_maps.nhits_2mm[whits]))
   map_jk.snr_mask_2mm = double( subtract_maps.nhits_2mm $
                                        ge snr_mask_hits_threshold* $
                                        median( subtract_maps.nhits_2mm[whits]))
endif else begin
   subtract_maps.snr_mask_1mm = 1.d0
   subtract_maps.snr_mask_2mm = 1.d0
   map_jk.snr_mask_1mm = 1.d0
   map_jk.snr_mask_2mm = 1.d0
endelse

if defined(dmm_grid_tot) then begin
   save, subtract_maps, dmm_grid_tot, file=dir_basename+"/subtract_maps_"+strtrim(iter,2)+".save"
endif else begin
   save, subtract_maps, file=dir_basename+"/subtract_maps_"+strtrim(iter,2)+".save"
endelse
message, /info, "Saved "+dir_basename+"/subtract_maps_"+strtrim(iter,2)+".save"
if keyword_set( param.split_horver) then begin
   save, map_jk, file=dir_basename+"/map_JK_"+strtrim(iter,2)+".save"
   message, /info, "Saved "+dir_basename+"/map_JK_"+strtrim(iter,2)+".save"
   save, map_hor, file=dir_basename+"/map_HOR_"+strtrim(iter,2)+".save"
   save, map_ver, file=dir_basename+"/map_VER_"+strtrim(iter,2)+".save"
   message, /info, "Saved "+dir_basename+"/map_HOR_"+strtrim(iter,2)+".save"
   message, /info, "Saved "+dir_basename+"/map_VER_"+strtrim(iter,2)+".save"
endif
end
