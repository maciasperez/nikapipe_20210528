
pro ktn_prepare_light, preproc_file, preproc_index, run_widget, keep_neg = keep_neg, input_kidpar_file = input_kidpar_file

common ktn_common

if not keyword_set(reso_map) then reso_map = 8.d0

run_widget = 1

restore, preproc_file
if keyword_set(input_kidpar_file) then begin
   kidpar_ref = mrdfits( input_kidpar_file, 1)

   ;; Flag out all kids here, the good ones will be given by kidpar_ref
   kidpar.plot_flag = 1
   
   ;; Copy type and plot_flag info from the ref. kidpar
   for i = 0, n_elements(kidpar)-1 do begin
      ;; w = where( kidpar_ref.numdet eq kidpar[i].numdet, nw)
      w = where( kidpar_ref.numdet eq kidpar[i].numdet and kidpar_ref.scan eq scan, nw)
      if nw ne 0 then begin
         kidpar[i].type      = kidpar_ref[w].type
         kidpar[i].plot_flag = kidpar_ref[w].plot_flag
         ;kidpar[i] = kidpar[w]
      endif
   endfor

   ;; Check if it's worth looking at the maps or if all the
   ;; kids have already been flagged out
   w1 = where(kidpar.type eq 1 and kidpar.plot_flag eq 0, nw1)
   if nw1 eq 0 then begin
      output_kidpar_file = 'kidpar_'+scan+'_test_'+strtrim(preproc_index,  2)+'.fits'
      message, /info, "No kid left to look at, saving "+output_kidpar_file
      run_widget = 0
      nk_write_kidpar, kidpar, output_kidpar_file
      return
   endif

endif

nkids = n_elements(kidpar)

;;------------------------------------------------------------------------
;; Deal with maps and display parameters in various widget tabs


;; nx1 = 60 ; 75 ; 50; 100
;; ny1 = round( float(grid_azel.ny)/grid_azel.nx *nx1)
;; ;; NP, Oct. 10th, 2015, force to 10x10 maps per tab for simplicity.
;; n_plot_x = 10
;; n_plot_y = 10
;; xsize_matrix = n_plot_x * nx1
;; ysize_matrix = n_plot_y * ny1

nx1 = 100
ny1 = round( float(grid_azel.ny)/grid_azel.nx *nx1)
;; NP, Oct. 10th, 2015, force to 10x10 maps per tab for simplicity.
n_plot_x = 8;8; 7 ; 10
n_plot_y = 5;6; 7 ; 10
xsize_matrix = n_plot_x * nx1
ysize_matrix = n_plot_y * ny1


;; distribute kid maps across the graphics window
nkids_max_per_tab = n_plot_x*n_plot_y

ntabs = 1
while ntabs*nkids_max_per_tab lt nkids do ntabs++

plot_position  = dblarr( n_plot_x, n_plot_y, 4)
plot_position1 = dblarr( n_plot_x*n_plot_y, 4)
for ix=0, n_plot_x-1 do begin
   for iy=0, n_plot_y-1 do begin
      plot_position[ix,iy,*] = [double(ix*nx1)/xsize_matrix,     double(iy*ny1)/ysize_matrix, $
                                double((ix+1)*nx1)/xsize_matrix, double((iy+1)*ny1)/ysize_matrix]
      plot_position1[ix+iy*n_plot_x,*] = plot_position[ix,iy,*]
   endfor
endfor

;;-----------------------------------------------------------------------------
;; All information relevant to scan number, matrix characteristics
if keyword_set(fast) then beam_fit_method = 'GAUSS2D' else beam_fit_method = "nika"
;if param.lab ne 0 then beam_fit_method='MPFIT' ; to be immune to the string holding the calibration planet

sys_info = create_struct( "output_kidpar_fits", 'kidpar_'+scan+'_test_'+strtrim(preproc_index,2)+'.fits', $
                          "outlyers", 0, $
                          "nickname", 'bidon', $
                          "scan", "dummy", $
                          "lambda", 32, $
                          "nu_noise_ref", 5.d0, $
                          "t_planet", 1.d0, $
                          "pos_planet", [0.d0, 0.d0], $
                          "avg_noise", 0.d0, $
                          "sigma_noise", 0.d0, $
                          "avg_response", 0.d0, $
                          "sigma_response", 0.d0, $
                          "avg_sensitivity_decorr", 0.d0, $
                          "sigma_sensitivity_decorr", 0.d0, $
                          "output_dir", ".", $
                          "plot_dir", ".", $
                          "beam_fit_method", beam_fit_method, $
                          "png", 1, $
                          "ps", 0)

;; All information and parameters relevant to displays
disp = create_struct( "rebin_factor", 1, $
                      "nkids", nkids, $
                      "ishift_min", -2, $ ; for zigzag
                      "ishift_max", 2, $ ; for zigzag
                      "nasmyth", 0, $
                      "current_tab", 0, $
                      "nkids_max_per_tab", nkids_max_per_tab, $
                      "ntabs", ntabs, $
                      "reso_map", grid_azel.map_reso, $
                      "plot_position", plot_position, $
                      "plot_position1", plot_position1, $
                      "coeff", double( identity(nkids)), $
                      "textcol", 255, $
                      "x_cross", !undef+dblarr( nkids*3), $     ; should be large enough
                      "y_cross", !undef+dblarr( nkids*3), $     ; should be large enough
                      "map_list", map_list_azel, $
                      "xmap", grid_azel.xmap, $
                      "ymap", grid_azel.ymap, $
                      "beam_list", map_list_azel*0.d0, $
                      "map_list_nasmyth", map_list_nasmyth, $
                      "xmap_nasmyth", grid_nasmyth.xmap, $
                      "ymap_nasmyth", grid_nasmyth.ymap, $
                      "freq_min", 0.d0, $
                      "freq_max", !nika.f_sampling/2., $
                      "time_min", 0, $
                      "screening_tmin", 0.d0, $
                      "screening_tmax", 0.d0, $
                      "do_decorr_filter", 0, $
                      "xsize_matrix", xsize_matrix, $
                      "ysize_matrix", ysize_matrix, $
                      "smooth_decorr_display", 0, $ ; nicer but slower if set to 1
                      "window", 0, $      ; current graphic window
                      "decorr_window", 0, $
                      "ikid", 0, $           ; kid currently displayed
                      "check_list", 0, $
                      ;;"beam_scale", 0.5 * 0.5/!fwhm2sigma, $ ; 1./fwhm pour l'avoir en FWHM, 0.5 pour le Rayon et pas le diametre 
                      "beam_scale", 0.5, $ ; 0.5 as the radius to have a display diamter of sigma
                      "alpha", 45.d0, $ ; orientation of the grid in Nasmyth coordinates
                      "delta", 10.d0, $ ; spacing between pixels in arcsec
                      "histo_fit", 0) ; 0 by default to avoid failure when too many kids are crapy
                      

;; To keep track of what must be done
operations = create_struct( "beam_guess_done", 1, $
                            "nodes_fit", 0, $
                            "decorr", 0, $
                            "numdet_ref_set", 0, $
                            "grid_nodes", 0)

w1 = where( kidpar.type eq 1, compl=unvalid_kids, ncompl=n_unval)
if n_unval ne 0 then kidpar[unvalid_kids].plot_flag = 1
wplot = where( kidpar.plot_flag eq 0, nwplot)

nx = n_elements( disp.xmap[*,0])
ny = n_elements( disp.xmap[0,*])
xmin = min(disp.xmap) - grid_azel.map_reso/2.
ymin = min(disp.ymap) - grid_azel.map_reso/2.

grid = {nx:nx, ny:ny, xmin:xmin, ymin:ymin, $
        map_reso:grid_azel.map_reso, $
        xmap:disp.xmap, ymap:disp.ymap,$
        mask_source:disp.xmap*0.d0+1.d0, $ ;; no source to be masked by default
        map_i_1mm:  disp.xmap*0.d0, $
        nhits_1mm:  disp.xmap*0.d0, $
        map_w8_1mm: disp.xmap*0.d0, $
        map_i_2mm:  disp.xmap*0.d0, $
        nhits_2mm:  disp.xmap*0.d0, $
        map_w8_2mm: disp.xmap*0.d0}

;; ktn_discard_outlyers, keep_neg = keep_neg

end
