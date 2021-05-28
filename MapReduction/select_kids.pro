
;; On a strong source scan, compute individual maps to determine the information
;; structure kidpar that in turn can be upgraded in otf_geometry
;;===============================================================================

;;pro select_kids, scan_num, day, info=info

;;pro select_kids_per_matrix, file_list, ifile, scan_num, day, info, x1=x1, x2=x2

;pro select_kids_per_matrix, scan_num, day, lambda_in

common ql_maps_common, x_0, y_0, nsn, w8, reso_map, toi, toi_med, kidpar, map_list_ref, rebin_factor, $
   xmap, ymap, coeff, plot_position, plot_position1, kid_plot_position, map_list_out, $
   map_list_out_0, x_cross, y_cross, nkids, nx, ny, $
   x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, beam_list_1, theta_1, xra, yra, ibol, ibol_ref, jbol, $
   bolo_list, x_peak_list, y_peak_list, a_peak_list, mat_m1, nickname, map_list_ref_ab, xra_plot, yra_plot, $
   lambda, box, el_source_ref, output_fits_file, ground, w1, w3, w13, nw1, nw3, nw13, alpha_fp, delta_fp, verbose, $
   plot_dir, plot_name, save_dir, textcol, keep, beam_guess_done, fwhm, ellipt, np, plateau, wplot, wplot_init, $
   png, ps, electronics, current_pix, fwhm_min, fwhm_max, no_block, checklist, ext, scan_num_string, day, scan_num, $
   numdet_ref, ilambda, do_beam_guess, plot_nodes_fit, plot_beams, plot_beams_stat, my_screen_size


;; because of this damn common...
scan_num = scan_num_in
day      = day_in


no_block  = 1
checklist = 1


;;--------------------------------------------------------------------------------------
get_config, scan_num, day, scan_config

if not keyword_set(info) then begin

   source_flux_units = 'Jy/Beam'
   nsn_ft_max = 2L^13
   info = create_struct( "rebin_factor", 2, $
                         "reso_map", 5, $
                         "median_width", 201)
endif
;;--------------------------------------------------------------------------------------

nika_find_data_file, scan_num, day, file_list
nfiles = n_elements( file_list)

;; pickup the correct file corresponding to lambda_in
for i=0, nfiles-1 do begin
   file2nickname, file_list[i], nickname, scan_num_string, date, matrix, box, source, lambda_out, ext, file_save
   if lambda_out eq lambda_in then file = file_list[i]
endfor

;; recompute correct nickname, box etc... that were screwed up in the previous
;; search loop
file2nickname, file, nickname, scan_num_string, date, matrix, box, source, lambda_out, ext, file_save
print, "file = ", file

save_dir = "."
plot_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir "+plot_dir

rebin_factor = info.rebin_factor
reso_map     = info.reso_map
png = 0 & ps = 0

;; Get data
print, "Reading data..."
restore, !nika.save_dir+"/"+file_save, /verb

;; Quicklook to check everything's fine
nsn   = n_elements( toi[0,*])
nkids = n_elements( toi[*,0])
make_ct, nkids, ct
wind, 1, 1, /free, xs=1200
!p.multi=[0,2,1]
plot, toi[0,*], yra = minmax( toi[1,*])
for i=0, nkids-1 do oplot, toi[i,*], col=ct[i]
plot, x_0, y_0, xtitle='X_0', ytitle='Y_0', title=file
!p.multi = 0

;; Quick median filter to get planet position
clean_data, toi, kidpar, toi_med, "median", width=info.median_width

;; Nasmyth coordinates + initial guess on matrix orientation to make pixel to
;; grid node association easier
alpha = !dpi/2. - data.el ; initial guess done in widget, nodes_fit
x_1 = cos(-alpha)*x_0 - sin(-alpha)*y_0
y_1 = sin(-alpha)*x_0 + cos(-alpha)*y_0
x_0 = x_1
y_0 = y_1

xra = minmax(x_0)
yra = minmax(y_0)



;;toi_med_copy = toi_med
;;
;;stop
;;
;;toi_med = toi_med_copy
;;;toi_med = shift( toi_med, 0, 3) ; undo nika_fits2toi
;;toi_med = shift( toi_med, 0, 2) ; better at 1 and 2mm ?!

xyra2xymaps, xra, yra, reso_map, xmap, ymap, nx, ny, xmin, ymin, xgrid, ygrid
get_bolo_maps, toi_med,  x_0, y_0, reso_map, xmap, ymap, kidpar, map_list_ref_ab, w8=w8
;;qd_disp, map_list_ref_ab,kidpar,  4, xmap=xmap, ymap=ymap

;; closer look and select kids
init_common_variables, matrix=matrix
reduce_map_widget
;my_widget


end
