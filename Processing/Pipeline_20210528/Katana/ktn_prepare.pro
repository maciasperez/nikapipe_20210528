
pro ktn_prepare, file, dat_dir, comments_file, output_dir, $
                 out_png=out_png, out_ps=out_ps, $
                 reso_map=reso_map, absurd=absurd, input_kidpar_file=input_kidpar_file, $
                 fast=fast, preproc_file=preproc_file


common ktn_common

if not keyword_set(reso_map) then reso_map = 8.d0

toi     = data.toi              ; to preserve input raw toi while we update data.toi in the COMMON block
toi_med = data.toi
nkids   = n_elements( toi[*,0])
nsn     = n_elements( toi[0,*])
ind     = lindgen(nsn)

;;Garde que les aller-simples et vire les pointages abherents
if sky_data eq 1 then begin
   t_planet = 1.d0              ; place holder
   w8 = dblarr( nsn) + 1.d0
endif else begin
   t_planet = 4.d0              ; K_RJ

   w4 = where( data.scan_st eq 4, nw4) ; subscan started
   w5 = where( data.scan_st eq 5, nw5) ; subscan done

   w8 = dblarr( nsn)

   ;; Keep only forward scans
   for i=0, nw4-1 do begin
      w = where( w5 gt w4[i], nw)
      if nw ne 0 then begin     ; maybe the last subscan is cut off, then discard
         imin = min(w)
         w8[ w4[i]:w5[imin]] = 1
      endif
   endfor

endelse

w_w8 = where( w8 eq 1, nw, compl=wreject, ncompl=nwreject)
if param.lab eq 1 then begin
   wind, 1, 1, /free, /large
   plot, data.ofs_az, data.ofs_el, xtitle='X offset', ytitle='Y offset'
;;if sky_data eq 1 and nwreject ne 0 then oplot, data[w].ofs_az, data[w].ofs_el, col=250, psym=1
   if nw ne 0 then oplot, data[w_w8].ofs_az, data[w_w8].ofs_el, col=150, psym=1
   legendastro, ['Raw', 'Keep'], textcol=[!p.color, 150], box=0
endif

;; Map in Az,el
xra = minmax(data[w_w8].ofs_az)
yra = minmax(data[w_w8].ofs_el)
param.map_xsize = (xra[1]-xra[0])*1.1
param.map_ysize = (yra[1]-yra[0])*1.1
nk_default_info, info
nk_init_grid, param, info, grid_azel
wkill = where( finite(data.ofs_az) eq 0 or finite(data.ofs_el) eq 0, nwkill)
ix    = (data.ofs_az - grid_azel.xmin)/grid_azel.map_reso
iy    = (data.ofs_el - grid_azel.ymin)/grid_azel.map_reso
if nwkill ne 0 then begin
   ix[wkill] = -1
   iy[wkill] = -1
endif
ipix = double( long(ix) + long(iy)*grid_azel.nx)
w = where( long(ix) lt 0 or long(ix) gt (grid_azel.nx-1) or $
           long(iy) lt 0 or long(iy) gt (grid_azel.ny-1), nw)
if nw ne 0 then ipix[w] = !values.d_nan ; for histogram
data.ipix_azel = ipix
message, /info, "Computing kid maps in azel..."
t0 = systime(0,/sec)
get_bolo_maps_6, data.toi, data.ipix_azel, w8, kidpar, grid_azel, map_list_azel
t1 = systime(0,/sec)
if param.cpu_time eq 1 then print, "get_bolo_maps_6 azel: ", t1-t0
;get_bolo_maps_4, data.toi, data.ipix_azel, w8, kidpar, grid_azel, map_list_azel, map_var_list_azel
;t2 = systime(0,/sec)
;print, "t1-t0", t1-t0
;print, "t2-t1", t2-t1
;stop

;; Map in Nasmyth
xra1  = minmax(data[w_w8].ofs_nasx)
yra1  = minmax(data[w_w8].ofs_nasy)
param.map_xsize = (xra1[1]-xra1[0])*1.1
param.map_ysize = (yra1[1]-yra1[0])*1.1
nk_init_grid, param, info, grid_nasmyth
wkill = where( finite(data.ofs_nasx) eq 0 or finite(data.ofs_nasy) eq 0, nwkill)
ix    = (data.ofs_nasx - grid_nasmyth.xmin)/grid_nasmyth.map_reso
iy    = (data.ofs_nasy - grid_nasmyth.ymin)/grid_nasmyth.map_reso
if nwkill ne 0 then begin
   ix[wkill] = -1
   iy[wkill] = -1
endif
ipix = double( long(ix) + long(iy)*grid_nasmyth.nx)
w = where( long(ix) lt 0 or long(ix) gt (grid_nasmyth.nx-1) or $
           long(iy) lt 0 or long(iy) gt (grid_nasmyth.ny-1), nw)
if nw ne 0 then ipix[w] = !values.d_nan ; for histogram
data.ipix_nasmyth = ipix
t0 = systime(0,/sec)
get_bolo_maps_6, data.toi, data.ipix_nasmyth, w8, kidpar, grid_nasmyth, map_list_nasmyth
t1 = systime(0,/sec)
if param.cpu_time eq 1 then print, "get_bolo_maps_6 Nasmyth: ", t1-t0

valid = where( kidpar.type eq 1, nvalid)
make_ct, nvalid, ct
plot, ind, toi[valid[0],*], yra=minmax(toi[valid,*]), /ys, /xs
for i=0, nvalid-1 do oplot, ind, toi[valid[i],*], col=ct[i]

;;--------------------------------------------------------------------------------------------------------
;; Re-order input for the COMMON
file2nickname, file, nickname, scan, date, matrix, box, sourcename, lambda, ext, file_save, /raw

;;------------------------------------------------------------------------
;; Deal with maps and display parameters in various widget tabs

;; ;; Min size of a kid map (approx to match up to 100 kids per tab in normal circumstances)
;; n_pix_min = 75
;; 
;; ;; Approx size of the tab widget and number of plots per tab
;; udg      = max( round( [float(n_pix_min)/grid_azel.nx, float(n_pix_min)/grid_azel.ny])) > 1
;; nx1      = grid_azel.nx*udg
;; ny1      = grid_azel.ny*udg
;; message, /info, "fix me:"
nx1 = 60 ; 75
ny1 = round( float(grid_azel.ny)/grid_azel.nx *nx1)

;;nx_wind  = long( !screen_size[0]*0.5)
;;ny_wind  = long( !screen_size[1]*0.9)
;;n_plot_x = long(nx_wind/nx1)
;;n_plot_y = long(ny_wind/ny1)

;; NP, Oct. 10th, 2015
n_plot_x = 10
n_plot_y = 10
;ntabs_max = 20
;nkids_max_per_tab = round(nkids/ntabs_max)
;n_plot_y = round( nkids_max_per_tab/float(n_plot_x))
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

sys_info = create_struct( "file", file, $
                          "output_kidpar_fits", '', $
                          "outlyers", 0, $
                          "nickname", nickname, $
                          "scan", scan, $
                          "date", date, $
                          "matrix", matrix, $
                          "box", box, $
                          "lambda", lambda, $
                          "ext", ext, $
                          "nu_noise_ref", 5.d0, $
                          "t_planet", T_planet, $
                          "pos_planet", [0.d0, 0.d0], $
                          "dat_dir", dat_dir, $
                          "avg_noise", 0.d0, $
                          "sigma_noise", 0.d0, $
                          "avg_response", 0.d0, $
                          "sigma_response", 0.d0, $
                          "avg_sensitivity_decorr", 0.d0, $
                          "sigma_sensitivity_decorr", 0.d0, $
                          "comments_file", comments_file, $
                          "output_dir", output_dir, $
                          "plot_dir", output_dir, $
                          "beam_fit_method", beam_fit_method, $
                          "png", 1, $
                          "ps", 0)

;; All information and parameters relevant to displays
disp = create_struct( "rebin_factor", 1, $
                      "nkids", nkids, $
                      "nsn", nsn, $
                      "ishift_min", -2, $ ; for zigzag
                      "ishift_max", 2, $ ; for zigzag
                      "nasmyth", 0, $
                      "current_tab", 0, $
                      "nkids_max_per_tab", nkids_max_per_tab, $
                      "ntabs", ntabs, $
                      "reso_map", reso_map, $
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
;                      "map_var_list_azel", map_var_list_azel, $
;                      "map_var_list_nasmyth", map_var_list_nasmyth, $
                      "freq_min", 0.d0, $
                      "freq_max", !nika.f_sampling/2., $
                      "time_min", 0, $
                      "time_max", nsn/!nika.f_sampling, $
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
operations = create_struct( "beam_guess_done", 0, $
                            "nodes_fit", 0, $
                            "decorr", 0, $
                            "numdet_ref_set", 0, $
                            "grid_nodes", 0)


;; extract relevant information from kidpar
time = dindgen( disp.nsn)/!nika.f_sampling/60.

;; Take types from another kidpar if requested in input
if keyword_set(input_kidpar_file) then begin
   junk = mrdfits( input_kidpar_file, 1)
   kidpar.type = junk.type
endif

w1 = where( kidpar.type eq 1, compl=unvalid_kids, ncompl=n_unval)
if n_unval ne 0 then kidpar[unvalid_kids].plot_flag = 1
wplot = where( kidpar.plot_flag eq 0, nwplot)

;;----------------------------
;; Beam, calibration and noise properties
ktn_beam_calibration, /noplot, absurd=absurd, /no_bolo_maps

;; ;;-------------------------------------------------------------------------
;; ;; By default, take the 10 best kids for the decorrelation template
;; w1 = where( kidpar.type eq 1, nw1)
;; order = sort( kidpar[w1].noise)
;; nkids_in_template = 10 < nw1
;; kidpar.in_decorr_template = 0
;; 
;; if nkids_in_template ne 0 then begin
;;    kidpar[order[0:nkids_in_template-1]].in_decorr_template = 1
;;    kidpar[order[0:nkids_in_template-1]].idct_def = 1
;; endif

;; Polystyren screens are meant to be placed around the end of the scan
; in units of [mn]
disp.screening_tmin = disp.nsn/!nika.f_sampling/60. - 5.
disp.screening_tmax = disp.nsn/!nika.f_sampling/60.

!nika_pr.xrange = [disp.screening_tmin, disp.screening_tmax]
!nika_pr.yrange = minmax( data.toi[w1])

nx = n_elements( disp.xmap[*,0])
ny = n_elements( disp.xmap[0,*])
xmin = min(disp.xmap) - param.map_reso/2.
ymin = min(disp.ymap) - param.map_reso/2.

grid = {nx:nx, ny:ny, xmin:xmin, ymin:ymin, $
        map_reso:param.map_reso, $
        xmap:disp.xmap, ymap:disp.ymap,$
        mask_source:disp.xmap*0.d0+1.d0, $ ;; no source to be masked by default
        map_i_1mm:  disp.xmap*0.d0, $
        nhits_1mm:  disp.xmap*0.d0, $
        map_w8_1mm: disp.xmap*0.d0, $
        map_i_2mm:  disp.xmap*0.d0, $
        nhits_2mm:  disp.xmap*0.d0, $
        map_w8_2mm: disp.xmap*0.d0}


end
