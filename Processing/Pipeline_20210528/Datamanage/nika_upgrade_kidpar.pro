
;; Adds fields to kidpar depending on which run we're working on

pro nika_upgrade_kidpar, kidpar

;; if !nika.run eq '3' then begin
;;    message, /info, "not coded yet"
;;    stop
;; endif
;; 
;; ;;----------------------------------------------------------------------------------------------------
;; if !nika.run eq '4' then begin
;;    message, /info, "not coded yet"
;;    stop
;; endif
;; 
new_fields = {c0_skydip:0.d0, c1_skydip:0.d0, tau_skydip:0.d0, df:0.d0, $
              x_peak:!values.d_nan, $
              y_peak:!values.d_nan, $
              x_peak_nasmyth:!values.d_nan, $
              y_peak_nasmyth:!values.d_nan, $
              x_peak_azel:!values.d_nan, $
              y_peak_azel:!values.d_nan, $
              c_az:0.d0, $      ; pointing correction
              c_el:0.d0, $      ; pointing correction
              sigma_x:!values.d_nan, $
              sigma_y:!values.d_nan, $
              ellipt:!values.d_nan, $
              response:!values.d_nan, $
              screen_response:!values.d_nan, $
              noise:!values.d_nan, $
              noise_1Hz:!values.d_nan, $
              noise_2Hz:!values.d_nan, $
              noise_10Hz:!values.d_nan, $
              noise_raw_source_interp_1Hz:!values.d_nan, $
              noise_raw_source_interp_2Hz:!values.d_nan, $
              noise_raw_source_interp_10Hz:!values.d_nan, $
              noise_source_interp_and_decorr_1Hz:!values.d_nan, $
              noise_source_interp_and_decorr_2Hz:!values.d_nan, $
              noise_source_interp_and_decorr_10Hz:!values.d_nan, $
              sensitivity_decorr:!values.d_nan, $
              color:0L, $
              in_decorr_template:0, $
              idct_def:0, $
              ok:-1, $
              plot_flag:0, $
              grid_step:0.d0, $
              flux:0.d0, $
              f_tone:0.d0, $
              rta:0}

upgrade_struct, kidpar, new_fields, kidpar_out
kidpar = kidpar_out

end
