
;; This script computes the NEFD of each array by integrating the
;; noise over a list of scans and fitting the noise curve as a
;; function of sqrt(obs_time)
;;
;; It uses results of reduce_source.pro.
;;===================================================================

;; This "project_dir" must match the one defined in reduce_source.pro
project_dir = !nika.plot_dir+"/HFLS3_common_mode_kids_out_kidpar_ref"

source = file_basename( project_dir[isource])
spawn, "ls "+project_dir[isource]+"/v_1", scan_list
nscans = n_elements(scan_list)
   
restore, project_dir[isource]+"/v_1/"+scan_list[0]+"/results.save"

;; Traditionnal plot
param1.educated = 1
param1.do_aperture_photometry = 0
nk_average_scans, param1, scan_list, output_maps, info=info, /cumul, /center_nefd_only, $
                  flux_cumul=flux_cumul, sigma_flux_cumul=sigma_flux_cumul, $
                  flux_center_cumul=flux_center_cumul, sigma_flux_center_cumul=sigma_flux_center_cumul, $
                  time_center_cumul=time_center_cumul
nefd_plot, time_center_cumul, sigma_flux_center_cumul, source, ps=ps, file='NEFD_'+source, png=png

;;   ;; With /parity
;;   if (nscans mod 2) eq 0 then scan_list1 = scan_list else scan_list1 = scan_list[0:nscans-2]
;;   nk_average_scans, param1, scan_list1, output_maps, info=info, /cumul, /center_nefd_only, $
;;                     flux_cumul=flux_cumul, sigma_flux_cumul=sigma_flux_cumul, $
;;                     flux_center_cumul=flux_center_cumul, sigma_flux_center_cumul=sigma_flux_center_cumul, $
;;                     time_center_cumul=time_center_cumul, /parity
;;   nefd_plot, time_center_cumul, sigma_flux_center_cumul, source, ps=ps, file='NEFD_'+source+"_parity"

end
