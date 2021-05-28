
pro nika_beam_guess

common ql_maps_common

plot_name = "beam_matrix"

method = "mpfit"                ; "myfit"
beam_guess, map_list_out, xmap, ymap, kidpar, x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_1, theta_1, rebin=rebin_factor, /noplot, verbose=verbose, parinfo=parinfo, $
            method=method                                        ;, /circular
gnaw = where( a_peaks_1 le 0 and kidpar.type ne 2, nn)           ;; preserve OFF information
if nn ne 0 then kidpar[gnaw].type = 5
end
