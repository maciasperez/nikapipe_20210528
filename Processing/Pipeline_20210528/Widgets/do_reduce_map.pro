;; pro do_reduce_map, file=file

common bt_maps_common, $
   data, kidpar, ks, kquick, $
   toi, toi_med, w8, time, x_0, y_0, pw, freq, pw_raw, $
   disp, $              ; xmap, ymap, plot_position, wplot
   sys_info, $
   operations, param_c, units


bt_analyse_data, file=file
bt_plot_fp_pos
bt_reduce_map_widget
kid_selector_widget

end

