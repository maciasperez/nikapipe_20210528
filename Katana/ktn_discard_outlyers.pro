

pro ktn_discard_outlyers, fwhm_min=fwhm_min, fwhm_max=fwhm_max, $
                          a_peak_min=a_peak_min, a_peak_max=a_peak_max, $
                          ellipt_max=ellipt_max, $
                          noise_max=noise_max, keep_neg = keep_neg, $
                          nas_x_min = nas_x_min, nas_x_max = nas_x_max, nas_y_min = nas_y_min, $
                          nas_y_max = nas_y_max, az_min = az_min, az_max = az_max, el_min = el_min, el_max = el_max, $
                          snr_min=snr_min
                          
common ktn_common


nk_kidpar_outlyers, kidpar, wtest, w_discard, fwhm_min=fwhm_min, fwhm_max=fwhm_max, $
                    a_peak_min=a_peak_min, a_peak_max=a_peak_max, $
                    ellipt_max=ellipt_max, $
                    noise_max=noise_max, keep_neg = keep_neg, $
                    nas_x_min = nas_x_min, nas_x_max = nas_x_max, nas_y_min = nas_y_min, $
                    nas_y_max = nas_y_max, az_min = az_min, az_max = az_max, el_min = el_min, el_max = el_max, $
                    snr_min=snr_min

nw_discard = n_elements(w_discard)
if nw_discard ne 0 then kidpar[w_discard].plot_flag = 1

end
