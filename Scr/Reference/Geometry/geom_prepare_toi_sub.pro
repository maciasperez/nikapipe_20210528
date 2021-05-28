
pro geom_prepare_toi_sub, iscan, scan_list, toi_dir, maps_dir, nickname, nproc=nproc, $
                          noplot=noplot, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
                          zigzag=zigzag, kids_out=kids_out, reso=reso, $
                          input_kidpar_file=input_kidpar_file, gamma=gamma, plot_dir=plot_dir, $
                          multiscans=multiscans, decor_method=decor_method, $
                          no_opacity_correction=no_opacity_correction, $
                          lockin_freqhigh=lockin_freqhigh, decor_cm_dmin=decor_cm_dmin, $
                          mask_default_radius=mask_default_radius
                          

if keyword_set(kids_out) and not keyword_set(input_kidpar_file) then begin
   message, /info, "I need input_kidpar_file to derive a first pointing and know where the source is"
   message, /info, "to perform a common_kids_out decorrelation"
   return
endif

if keyword_set(sn_min_list) then sn_min = sn_min_list[iscan]
if keyword_set(sn_max_list) then sn_max = sn_max_list[iscan]

scan = scan_list[iscan]
file_save = toi_dir+"/beam_map_preproc_toi_"+scan+".save"
;; if file_test(file_save) ne 1 then begin
geom_prepare_toi, scan, kidpar, $
                  map_list_azel, map_list_nasmyth, $ ; nhits_azel, nhits_nasmyth, $
                  grid_azel, grid_nasmyth, param, maps_dir, nickname, nproc=nproc, $
                  reso=reso, decor_method=decor_method, $
                  kid_step=kid_step, $
                  noplot=noplot, gamma=gamma, $
                  input_kidpar_file=input_kidpar_file, kids_out=kids_out, el_avg=el_avg_rad, $
                  zigzag=zigzag, sn_min=sn_min, sn_max=sn_max, map_list_nhits_azel=map_list_nhits_azel, $
                  map_list_nhits_nasmyth=map_list_nhits_nasmyth, plot_dir=plot_dir, multiscans=multiscans, $
                  toi_dir=toi_dir, no_opacity_correction=no_opacity_correction, $
                  lockin_freqhigh=lockin_freqhigh, decor_cm_dmin=decor_cm_dmin, mask_default_radius=mask_default_radius

;;endif


end
