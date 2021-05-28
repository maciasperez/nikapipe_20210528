
;; Adds fields to kidpar depending on which run we're working on

pro nk_upgrade_kidpar, kidpar

  new_fields = {c0_skydip:0.d0, c1_skydip:0.d0, c2_skydip:0.d0, $
                tau_skydip:0.d0, df:0.d0, $
                x_peak:!values.d_nan, $
                y_peak:!values.d_nan, $
                x_peak_nasmyth:!values.d_nan, $
                y_peak_nasmyth:!values.d_nan, $
                a_peak_nasmyth:!values.d_nan, $
                x_peak_azel:!values.d_nan, $
                y_peak_azel:!values.d_nan, $
                c_az:0.d0, $    ; pointing correction
                c_el:0.d0, $    ; pointing correction
                sigma_x:!values.d_nan, $
                sigma_y:!values.d_nan, $
                ellipt:!values.d_nan, $
                response:!values.d_nan, $
                screen_response:!values.d_nan, $
                noise:!values.d_nan, $
                noise_1Hz:!values.d_nan, $
                noise_2Hz:!values.d_nan, $
                noise_10Hz:!values.d_nan, $
                noise_above_4hz:!values.d_nan, $
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
                rta:0, $
                ofs_el_min:0.d0, $
                ofs_el_max:0.d0, $
                beam_map_subindex:0, $
                peak_snr_azel:0.d0, $
                peak_snr_nasmyth:0.d0, $
                corr2cm:0.d0, $

                std_red:0.d0, $
                std2cm:0.d0, $

                a_hwpss_phi_1:0.d0, $
                b_hwpss_phi_1:0.d0, $
                a_hwpss_phi_2:0.d0, $
                b_hwpss_phi_2:0.d0, $
                a_hwpss_phi_3:0.d0, $
                b_hwpss_phi_3:0.d0, $
                a_hwpss_phi_4:0.d0, $
                b_hwpss_phi_4:0.d0, $

                ;; HWPSS template model amplitudes
                cos1omega:0.d0, $
                dcos1omega_dt:0.d0, $
                sin1omega:0.d0, $
                dsin1omega_dt:0.d0, $

                cos2omega:0.d0, $
                dcos2omega_dt:0.d0, $
                sin2omega:0.d0, $
                dsin2omega_dt:0.d0, $
                
                cos3omega:0.d0, $
                dcos3omega_dt:0.d0, $
                sin3omega:0.d0, $
                dsin3omega_dt:0.d0, $
                
                cos4omega:0.d0, $
                dcos4omega_dt:0.d0, $
                sin4omega:0.d0, $
                dsin4omega_dt:0.d0, $
                
                cos5omega:0.d0, $
                dcos5omega_dt:0.d0, $
                sin5omega:0.d0, $
                dsin5omega_dt:0.d0, $
                
                cos6omega:0.d0, $
                dcos6omega_dt:0.d0, $
                sin6omega:0.d0, $
                dsin6omega_dt:0.d0, $
                
                cos7omega:0.d0, $
                dcos7omega_dt:0.d0, $
                sin7omega:0.d0, $
                dsin7omega_dt:0.d0, $
                
                cos8omega:0.d0, $
                dcos8omega_dt:0.d0, $
                sin8omega:0.d0, $
                dsin8omega_dt:0.d0, $
                
                cos9omega:0.d0, $
                dcos9omega_dt:0.d0, $
                sin9omega:0.d0, $
                dsin9omega_dt:0.d0, $

                scan:''}


upgrade_struct, kidpar, new_fields, kidpar_out
kidpar = kidpar_out

end
