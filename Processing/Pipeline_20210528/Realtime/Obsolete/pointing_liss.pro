;; Add param to the inputs to add flexibilty (NP)

pro pointing_liss, day, scan_num, maps, bg_rms, png=png, ps=ps, param=param, $
                   xmap=xmap, ymap=ymap, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
                   noskydip=noskydip, RF=RF, lissajous=lissajous, $
                   azel=azel, diffuse=diffuse, $
                   sn_min=sn_min, sn_max=sn_max, $
                   convolve=convolve, educated=educated, focal_plane=focal_plane, $
                   map_t_fit_params=map_t_fit_params, err_map_t_fit_params=err_map_t_fit_params, check=check, $
                   calibrate=calibrate, flux_1mm=flux_1mm, flux_2mm=flux_2mm, no_acq_flag=no_acq_flag, slow=slow, $
                   online=online, imbfits=imbfits, p2cor=p2cor, p7cor=p7cor, force=force, k_noise=k_noise, $
                   antimb = antimb, jump = jump

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

;; Force azel projection to derive pointing corrections
azel = 1
rta_map, day, scan_num, maps, bg_rms, png=png, ps=ps, param=param, $
         xmap=xmap, ymap=ymap, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
         noskydip=noskydip, RF=RF, lissajous=lissajous, $
         azel=azel, diffuse=diffuse, $
         sn_min=sn_min, sn_max=sn_max, $
         convolve=convolve, educated=educated, focal_plane=focal_plane, $
         map_t_fit_params=map_t_fit_params, err_map_t_fit_params=err_map_t_fit_params, check=check, $
         calibrate=calibrate, flux_1mm=flux_1mm, flux_2mm=flux_2mm, no_acq_flag=no_acq_flag, slow=slow, $
         online=online, imbfits=imbfits, p2cor=p2cor, p7cor=p7cor, force=force, k_noise=k_noise, $
         antimb = antimb, jump = jump


end
