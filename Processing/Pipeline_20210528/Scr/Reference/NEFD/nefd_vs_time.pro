

pro nefd_vs_time, project_dir, nmc=nmc
  
;; Derive error bars via MC
t0 = systime(0,/sec)
if not keyword_set(nmc) then nmc = 10

spawn, "ls "+project_dir+"/v_1/*/results.save", scan_list
scan_list = file_basename( file_dirname(scan_list))

nscans = n_elements(scan_list)
sigma_res = dblarr(4,nscans,nmc)

;; restore one "param1" to init nk_average_scans
restore, project_dir+"/v_1/"+scan_list[0]+"/results.save"

;; Main loop
for imc=0, nmc-1 do begin
   percent_status, imc, nmc, 10
   order = sort( randomu( seed, nscans))
   scan_list = scan_list[order]
   
   param1.educated = 1
   param1.do_aperture_photometry = 0
   nk_average_scans, param1, scan_list, output_maps, info=info, /cumul, /center_nefd_only, $
                     flux_cumul=flux_cumul, sigma_flux_cumul=sigma_flux_cumul, $
                     flux_center_cumul=flux_center_cumul, sigma_flux_center_cumul=sigma_flux_center_cumul, $
                     time_center_cumul=time_center_cumul, sum_one_over_sigma_flux_center_sq=sum_one_over_sigma_flux_center_sq
   
   sigma_res[0,*,imc] = sigma_flux_center_cumul[*,0]
   sigma_res[1,*,imc] = sigma_flux_center_cumul[*,3]
   sigma_res[2,*,imc] = sigma_flux_center_cumul[*,6]
   sigma_res[3,*,imc] = sigma_flux_center_cumul[*,9]

   if imc eq 0 then begin
      ;; Quick old plot
      nefd_plot, time_center_cumul, $
                 sigma_flux_center_cumul, $
                 nefd_list, sum_one_over_sigma_flux_center_sq=sum_one_over_sigma_flux_center_sq
   endif
endfor

;; Save results for nefd_plot_2:
param = param1
save, sigma_flux_center_cumul, time_center_cumul, sigma_res, param, file=project_dir+'/nefd_sigma_res.save'

t1 = systime(0,/sec)

end
