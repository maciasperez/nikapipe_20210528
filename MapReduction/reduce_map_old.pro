
;; launch define_ql_maps_common first

common ql_maps_common

online = 1 ; 0 ; 

png = 0 & ps = 0

dir = !home+'/Desktop/bidon'
spawn, "mkdir "+dir
el_source_ref = 0 ; place holder

ground = 1
dat_dir = "/Data/NIKA/Calib_sept_2012"
save_dir = !home+"/Projects/NIKA/Save_calib_Sept_2012"
file = "A_2012_09_11_15h40m03_0009_T.fits" ; 2mm
file = "A_2012_09_11_17h26m40_0004_T.fits" ; 1mm
rebin_factor = 3
reso_map = 8

;;------------------------------------------
l = strlen(file)
nickname = strmid( file, 0, l-5)

read_nika_fits, dat_dir+"/"+file, pars, regpar, regpar_a, regpar_b, kidpar, data,  units,  $
                header_pars = hpar1,  header_reg = hpar2,  k_pf = k_pf, /a_only

;; discard first 100 samples as usual
data = data[100:*]

toi = -data.rf_didq
nsn = n_elements( toi[0,*])
ind = lindgen(nsn)

;;Garde que les aller-simples et vire les pointages abherents
w8  = dblarr( nsn) + 1.d0

;; x and y have been interverted
x_0 = data.ofs_y ; data.ofs_x
y_0 = data.ofs_x ; data.ofs_y

vmax = 1 ; 4
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

w = where( w8 eq 1, nw)
wind, 1, 1, /f
plot, x_0, y_0, xtitle='X offset', ytitle='Y offset'
oplot, x_0[w], y_0[w], col=250, psym=1
legendastro, ['Raw', 'Keep'], col=[!p.color, 250], line=0

xra = minmax(x_0[w])
yra = minmax(y_0[w])

;; Build TOI arrays and make peaks positive
nkids = n_elements( toi[*,0])

valid = where( kidpar.type eq 1, nvalid)
make_ct, nvalid, ct
plot, ind, toi[valid[0],*], yra=minmax(toi[valid,*]), /ys
for i=0, nvalid-1 do oplot, ind, toi[valid[i],*], col=ct[i]

width  = 201
clean_data, toi, kidpar, toi_med, "median", width=width
nx = round( (max(xra)-min(xra))/reso_map)
ny = round( (max(yra)-min(yra))/reso_map)
xmin = min(xra)-reso_map/2.
ymin = min(yra)-reso_map/2.
xymaps, nx, ny, xmin, ymin, reso_map, xmap, ymap
get_bolo_maps, toi_med, x_0, y_0, reso_map, xmap, ymap, kidpar, map_list_ref_ab, w8=w8

matrix_display, map_list_ref_ab, kidpar, rebin_factor=rebin_factor

;; Select bolos to discard manually
get_flags, nickname, save_dir, map_list_ref_ab, kidpar;, /reset

matrix = 'A'
wa = indgen(nkids)
init_common_variables, w=wa, matrix=matrix


;; Reduce map
if online eq 1 then begin
   print, "matrix A, launching reduce_map_widget"
   reduce_map_widget
   stop
endif else begin
   restore, save_dir+'/coeff_kidpar_'+nickname+'.save'
endelse

remove_string

fp_summary_6, /circ, png=png, ps=ps, ground=ground, alpha_guess=alpha_fp, delta_guess=delta_fp

;; ;; Check that names match columns and line numbers ? answer = NO
;; xx = x_peaks_1[w1]-xc0
;; yy = y_peaks_1[w1]-yc0
;; get_x0y0, xx, yy, xc0, yc0
;; plot, xx, yy, psym=1, syms=2, /iso
;; for i=0, n_elements(w1)-1 do xyouts, xx[i], yy[i], kidpar[w1[i]].name





end


;; ; Flag multiple image detectors
;; ;; kidpar_out = kidpar ; init
;; ;; print, ""
;; ;; print, "flag multiple beam detectors"
;; ;; matrix_display, map_list_ref, kidpar, ibol_start=ibol_start, $
;; ;;                 rebin_factor=rebin_factor, nlines=nlines, ncol=ncol, $
;; ;;                 /nolabel, /select, bolo_out=bolo_out   
;; ;; kidpar_out[bolo_out].type = 6
;; ;; 
;; ;; kidpar = kidpar_out
;; ;; save, file='kidpar.save', kidpar
;; ;; stop
;; ;; restore, 'kidpar.save'
;; 
;; print, where(kidpar.type eq 6)
;; coeff = double( identity( nkids))
;; 
;; k_max = max( where( kidpar.type ne 0))
;; px = long( sqrt(k_max)+1)
;; py = px
;; my_multiplot, px, py, plot_position, gap_x=1e-6, gap_y=1e-6, xmargin=0.01, ymargin=0.01
;; x_cross = double( [!undef]) ; init
;; y_cross = double( [!undef])
;; 
;; print, "Launch master_widget"
;; stop
;; master_widget
;; 
;; 
;; apply_coeff, map_list_ref, coeff, kidpar, map_list_out
;; show_matrix, map_list_out
;; 
;; beam_guess, map_list_out, xmap, ymap, kidpar, x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
;;             beam_list_1, theta_1, rebin=rebin_factor, /mpfit, /circular, /noplot
;; show_matrix, beam_list_1, wind=2
;; 
;; ;;IDL> print, xra, yra
;; ;;      -131.81459       17.758905
;; ;;      -176.52046       22.241974
;; 
;; 
;; w1 = where( kidpar.type eq 1, nw1)
;; w3 = where( kidpar.type eq 3, nw3)
;; ra = [-150, 100]
;; wind, 1, 1, /free, xs=900, ys=800
;; outplot, file='FP_'+nickname, png=png, ps=ps
;; plot,  x_peaks_1[w1], y_peaks_1[w1], psym=1, /iso, title=nickname, xra=ra, yra=ra, xtitle='mm', ytitle='mm'
;; oplot, x_peaks_1[w3], y_peaks_1[w3], psym=1, col=250
;; legendastro, ['MonoBeam', 'Combined Beams'], col=[!p.color, 250], psym=[1,1], chars=1.5, syms=[2,2], textcol=[!p.color, 250]
;; if strupcase(box) eq 'A' then lambda = 2 else lambda =1
;; legendastro, [strtrim(lambda,2)+" mm"], chars=1.5, /right
;; outplot, /close, /pre
;; 
;; w = where( kidpar.type eq 1 or kidpar.type eq 3)
;; fwhm = sqrt( sigma_x_1*sigma_y_1)/!fwhm2sigma
;; outplot, file='Histo_fwhm_'+nickname, png=png, ps=ps
;; n_histwork, fwhm[w], bin=1, /fit, xhist, yhist, gpar, title='FWHM (mm)', min=0, max=100
;; legendastro, [strtrim(lambda,2)+" mm"], chars=1.5
;; outplot, /close, /pre
;; 
;; outplot, file='FWHM_summary_'+nickname, png=png, ps=ps
;; matrix_plot, x_peaks_1[w], y_peaks_1[w], fwhm[w], xra=ra, yra=ra, zra=gpar[1]+[-2,2]*gpar[2], title='FWHM (mm)'
;; legendastro, [strtrim(lambda,2)+" mm"], chars=1.5
;; outplot, /close, /pre

;; end


end
