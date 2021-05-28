
pro prepare_reduce_map, file, dat_dir, comments_file, output_dir, $
                        out_png=out_png, out_ps=out_ps, sky_data=sky_data, $
                        reso_map=reso_map, absurd=absurd


common bt_maps_common

if not keyword_set(reso_map) then reso_map = 8.d0

toi     = data.rf_didq ; to preserve input raw toi while we update data.rf_didq in the COMMON block
toi_med = data.rf_didq
nkids   = n_elements( toi[*,0])
nsn     = n_elements( toi[0,*])
ind     = lindgen(nsn)

x_0 = data.ofs_az
y_0 = data.ofs_el

;;Garde que les aller-simples et vire les pointages abherents
if keyword_set(sky_data) then begin
   t_planet = 1.d0              ; place holder
   w8 = dblarr( nsn) + 1.d0
endif else begin
   t_planet = 4.d0              ; K_RJ
   w8 = dblarr( nsn)

   ;; Allers simples
   w4 = where( data.scan_st eq 4, nw) & print, nw
   w5 = where( data.scan_st eq 5, nw) & print, nw
   for i=0, nw-1 do w8[w4[i]:w5[i]] = 1

   vmax = 1.5 ; 4 ; 1                     ; 4
   v = sqrt( (x_0 - shift(x_0,1))^2 + (y_0-shift(y_0,1))^2)
   index = indgen( nsn)
   wind, 1, 1, /f
   plot, index, v
   oplot, index, v, col=150

   w = where( v gt vmax, nw)
   if nw ne 0 then w8[w]   = 0.
   if nw ne 0 then w8[(w-1)>0] = 0.
   if nw ne 0 then w8[(w+1)<(nsn-1)] = 0.
   if nw ne 0 then oplot, index[w], v[w], psym=1, col=150
endelse

w = where( w8 eq 1, nw)

;; Map in Az,el
xra = minmax(x_0[w])
yra = minmax(y_0[w])
xyra2xymaps, xra, yra, reso_map, xmap, ymap
get_bolo_maps, data.rf_didq, x_0, y_0, reso_map, xmap, ymap, kidpar, map_list_azel, w8=w8

;; Map in Nasmyth
alpha = !dpi/2.d0 - data.el
x_1   = cos(-alpha)*data.ofs_az - sin(-alpha)*data.ofs_el
y_1   = sin(-alpha)*data.ofs_az + cos(-alpha)*data.ofs_el
xra1  = minmax(x_1[w])
yra1  = minmax(y_1[w])
xyra2xymaps, xra1, yra1, reso_map, xmap1, ymap1
get_bolo_maps, data.rf_didq, x_1, y_1, reso_map, xmap1, ymap1, kidpar, map_list_nasmyth, w8=w8

wind, 1, 1, /f
plot, x_0, y_0, xtitle='X offset', ytitle='Y offset'
if not keyword_set(sky_data) then begin
   oplot, x_0[w], y_0[w], col=250, psym=1
   legendastro, ['Raw', 'Keep'], col=[!p.color, 250], line=0
endif

valid = where( kidpar.type eq 1, nvalid)
make_ct, nvalid, ct
plot, ind, toi[valid[0],*], yra=minmax(toi[valid,*]), /ys, /xs
for i=0, nvalid-1 do oplot, ind, toi[valid[i],*], col=ct[i]

;;--------------------------------------------------------------------------------------------------------
;; Re-order input for the COMMON
file2nickname, file, nickname, scan, date, matrix, box, source, lambda, ext, file_save, /raw

my_multiplot, 1, 1, ntot=nkids, plot_position, plot_position1, /full, xmargin=1e-10, ymargin=1e-10, /dry

;; All information relevant to scan number, matrix characteristics
sys_info = create_struct( "file", file, $
                          "output_kidpar_fits", '', $
                          "nickname", nickname, $
                          "scan", scan, $
                          "date", date, $
                          "matrix", matrix, $
                          "box", box, $
                          "lambda", lambda, $
                          "ext", ext, $
                          "t_planet", T_planet, $
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
                          "png", 1, $
                          "ps", 0)

;; All information and parameters relevant to displays
disp = create_struct( "rebin_factor", 1, $
                      "nkids", nkids, $
                      "nsn", nsn, $
                      "nasmyth", 0, $
                      "reso_map", reso_map, $
                      "plot_position", plot_position, $
                      "plot_position1", plot_position1, $
                      "coeff", double( identity(nkids)), $
                      "xmap", xmap, $
                      "ymap", ymap, $
                      "textcol", 255, $
                      "x_cross", !undef+dblarr( nkids*3), $     ; should be large enough
                      "y_cross", !undef+dblarr( nkids*3), $     ; should be large enough
                      "map_list", map_list_azel, $
                      "map_list_nasmyth", map_list_nasmyth, $
                      "xmap_nasmyth", xmap1, $
                      "ymap_nasmyth", ymap1, $
                      "beam_list", map_list_azel*0.d0, $
                      "t_planet", 4.d0, $ ; K_RJ
                      "freq_min", 0.d0, $
                      "freq_max", !nika.f_sampling/2., $
                      "time_min", 0, $
                      "time_max", 1d6, $
                      "screening_tmin", 0.d0, $
                      "screening_tmax", 0.d0, $
                      "do_decorr_filter", 0, $
                      "xsize_matrix", 0, $
                      "ysize_matrix", 0, $
                      "smooth_decorr_display", 0, $ ; nicer but slower if set to 1
                      "window", 0, $      ; current graphic window
                      "decorr_window", 0, $
                      "ikid", 0, $           ; kid currently displayed
                      "check_list", 0, $
                      "beam_scale", 0.5 * 0.5/!fwhm2sigma) ; 0.2/fwhm pour l'avoir en FWHM, 0.5 pour le Rayon et pas le diametre 

;; To keep track of what must be done
operations = create_struct( "beam_guess_done", 0, $
                            "nodes_fit", 0, $
                            "decorr", 0, $
                            "numdet_ref_set", 0)


;; extract relevant information from kidpar
time = dindgen( disp.nsn)/!nika.f_sampling/60.
;obj1 = Obj_New( 'cgoverplot', time, reform( toi[0,*])) ; to init

kidpar_ext = create_struct( "x_peak", 0.d0, $
                            "y_peak", 0.d0, $
                            "x_peak_nasmyth", 0.d0, $
                            "y_peak_nasmyth", 0.d0, $
                            "x_peak_azel", 0.d0, $
                            "y_peak_azel", 0.d0, $
;                            "a_peak", 0.d0, $
                            "sigma_x", 0.d0, $
                            "sigma_y", 0.d0, $
;                            "fwhm", 0.d0, $
                            "ellipt", 0.d0, $
                            "response", 0.d0, $
                            "screen_response", 0.d0, $
                            "noise", 0.d0, $
                            "sensitivity_decorr", 0.d0, $
;                            "theta", 0.d0, $
                            "color", 0L, $
                            "in_decorr_template", 0, $ ; 1 means yes
                            "idct_def", 0, $ ; keep record of the default kids for the decorrelation template
                            "ok", -1, $
                            "plot_flag", 0);, $ ; 0 means OK
;                            "cgplot_obj_toi", obj1, $
;                            "cgplot_obj_pw", obj1)

upgrade_struct, kidpar, kidpar_ext, junk
kidpar = junk


w1 = where( kidpar.type eq 1, compl=unvalid_kids, ncompl=n_unval)
if n_unval ne 0 then kidpar[unvalid_kids].plot_flag = 1

wplot = where( kidpar.plot_flag eq 0, nwplot)
;cgzplot, time, reform(toi[wplot[0],*])
;stop
 ; init ?
;for ikid=0, disp.nkids-1 do kidpar[ikid].cgplot_obj_toi = Obj_New( 'cgoverplot', time, reform( toi_med[ikid,*]))
;;cgzplot, time, toi[wplot[0],*], oplots=kidpar[wplot].cgplot_obj_toi
;stop

;;----------------------------
;; Beam properties
bt_nika_beam_guess, absurd=absurd
bt_beam_stats

;; update kidpar.nas_x and nas_y here to avoid calling otf_geometry at the end
;; of iram_reduce_map
kidpar.nas_x = kidpar.x_peak_nasmyth
kidpar.nas_y = kidpar.y_peak_nasmyth


;;---------------------------------------------------------------------------
;; Look for the two most quiet minutes for noise estimation and
;; decorrelation
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then message, "No valid kid ?!"
ikid = w1[0] ; take the first one for this quick estimation
nsn = n_elements( data)
n_2mn = 2*60.*!nika.f_sampling
nsn_noise = 2L^round( alog(n_2mn)/alog(2))
nkids_noise = 5 < nw1
nu_noise_ref = 5. ;; Hz
rms = 1e10
ixp = 0
while (ixp+nsn_noise-1) lt nsn do begin
   d = reform( data[ixp:ixp+nsn_noise-1].rf_didq[ikid])
   if stddev(d) lt rms then begin
      disp.time_min = ixp/!nika.f_sampling/60                ; minutes
      disp.time_max = (ixp+nsn_noise-1)/!nika.f_sampling/60. ; minutes
   endif
   ixp += nsn_noise
endwhile

;;-------------------------------------------------------------------------
;; First estimate of response and noise properties
w = where( time ge disp.time_min and time le disp.time_max, nw)
power_spec, dindgen(nw), !nika.f_sampling, pw, freq
pw_raw     = dblarr( disp.nkids, n_elements(freq))
for ikid=0, disp.nkids-1 do begin
   percent_status, ikid, disp.nkids, 10, title='First noise/response estimation', /bar
   if kidpar[ikid].type eq 1 then begin
      power_spec, toi_med[ikid,w]-my_baseline( toi_med[ikid,w]), !nika.f_sampling, pw1, freq
      pw_raw[ikid,*] = reform(pw1)

      kidpar[ikid].noise        = avg( pw_raw[ikid,*])                                 ; Hz/sqrt(Hz)
      kidpar[ikid].response     = 1000.*sys_info.t_planet/kidpar[ikid].a_peak          ; mK/Hz
      kidpar[ikid].sensitivity_decorr = kidpar[ikid].noise* kidpar[ikid].response      ; Hz/sqrt(Hz) x mK/Hz = mK/sqrt(Hz)

   endif
endfor

;;-------------------------------------------------------------------------
;; By default, take the 10 best kids for the decorrelation template
junk = dblarr(disp.nkids) + 1e10
for ikid=0, disp.nkids-1 do begin
   if kidpar[ikid].type eq 1 then begin
      w = where( time ge disp.time_min and time le disp.time_max, nw)
      junk[ikid] = stddev( data[w].rf_didq[ikid])
   endif
endfor
order = sort( junk)
nkids_in_template = 10 < nw1
kidpar.in_decorr_template = 0
if nkids_in_template ne 0 then begin
   kidpar[order[0:nkids_in_template-1]].in_decorr_template = 1
   kidpar[order[0:nkids_in_template-1]].idct_def = 1
endif

;; Screens are meant to be placed around the end of the scan
; in units of [mn]
disp.screening_tmin = disp.nsn/!nika.f_sampling/60. - 5.
disp.screening_tmax = disp.nsn/!nika.f_sampling/60.

!nika_pr.xrange = [disp.screening_tmin, disp.screening_tmax]
!nika_pr.yrange = minmax( data.rf_didq[w1])


;;-------------------------------------------------------------------------------------------------
;; bt_plot_fp_pos


end

