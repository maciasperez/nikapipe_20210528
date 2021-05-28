

common ktn_common, $
   data, kidpar, ks, kquick, $
   toi, toi_med, w8, time, x_0, y_0, pw, freq, pw_raw, $
   disp, sys_info, $
   operations, param_c, param, units

;; Generate input sky, data etc...
nika_sim_polar_data, param, data_in, kidpar, ps, test_toi, $
                     maps_S0_in, maps_S1_in, maps_S2_in, $
                     xmap_in, ymap_in
;; Init data
data = data_in

;; Patch f_sampling untils the correct one is in "data"
!nika.f_sampling = ps.gen.nu_sampling

;; Check number of harmonics and subtract the template to the data
stop
ktn_polar_widget


;; ;; Template subtraction
;; if ps.gen.add_template ne 0 then begin
;;    param.polar.n_template_harmonics = ps.template.n_harmonics
;;    nika_pipe_hwp_rm, param, kidpar, data, fit
;;    test_toi.template_fit = fit
;; endif

end
