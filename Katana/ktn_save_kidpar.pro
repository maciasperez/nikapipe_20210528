

pro ktn_save_kidpar

common ktn_common


w1 = where( kidpar.type eq 1, nw1, compl=wbad, ncompl=nwbad)

w       = where( kidpar.plot_flag eq 1, nw)
w2      = where( kidpar.type      eq 2, nw2)
wdouble = where( kidpar.plot_flag eq 2, nwdouble)
if nw       ne 0 then kidpar[w ].type      = 5
if nw2      ne 0 then kidpar[w2].type      = 2         ; preserve off resonance kids
if nwdouble ne 0 then kidpar[wdouble].type = 4         ; keep record of "double" kids


;; Set to NaN undef values for convenience
w = where( kidpar.type ne 1, nw)
if nw ne 0 then begin
   kidpar[w].NAS_X = !values.d_nan
   kidpar[w].NAS_Y = !values.d_nan
   kidpar[w].NAS_CENTER_X = !values.d_nan
   kidpar[w].NAS_CENTER_Y = !values.d_nan
   kidpar[w].MAGNIF = !values.d_nan
   kidpar[w].CALIB = !values.d_nan
   kidpar[w].CALIB_FIX_FWHM = !values.d_nan
   kidpar[w].ATM_X_CALIB = !values.d_nan
   kidpar[w].FWHM = !values.d_nan
   kidpar[w].FWHM_X = !values.d_nan
   kidpar[w].FWHM_Y = !values.d_nan
   kidpar[w].THETA = !values.d_nan
   kidpar[w].X_PEAK = !values.d_nan
   kidpar[w].Y_PEAK = !values.d_nan
   kidpar[w].X_PEAK_NASMYTH = !values.d_nan
   kidpar[w].Y_PEAK_NASMYTH = !values.d_nan
   kidpar[w].X_PEAK_AZEL = !values.d_nan
   kidpar[w].Y_PEAK_AZEL = !values.d_nan
   kidpar[w].SIGMA_X = !values.d_nan
   kidpar[w].SIGMA_Y = !values.d_nan
   kidpar[w].ELLIPT = !values.d_nan
   kidpar[w].RESPONSE = !values.d_nan
   kidpar[w].SCREEN_RESPONSE = !values.d_nan
   kidpar[w].NOISE = !values.d_nan
   kidpar[w].SENSITIVITY_DECORR = !values.d_nan
   kidpar[w].IN_DECORR_TEMPLATE = 0
   kidpar[w].IDCT_DEF = 0
   kidpar[w].OK = 0
   kidpar[w].PLOT_FLAG = 1
   kidpar[w].C0_SKYDIP = !values.d_nan
   kidpar[w].C1_SKYDIP = !values.d_nan
   kidpar[w].TAU0 = !values.d_nan
   kidpar[w].DF = !values.d_nan
   kidpar[w].A_PEAK = !values.d_nan
   kidpar[w].TAU_skydip = !values.d_nan
endif

;; Compute the grid step with the currently selected pixels and put into kidpar
wplot = where( kidpar.plot_flag eq 0, nwplot)
get_grid_nodes, kidpar[wplot].x_peak_nasmyth, kidpar[wplot].y_peak_nasmyth, $
                xnode, ynode, alpha_opt, delta_opt, name=kidpar[wplot].name, /noplot
kidpar.grid_step = delta_opt

;; nika_write_kidpar, kidpar, sys_info.output_kidpar_fits
nk_write_kidpar, kidpar, sys_info.output_kidpar_fits
;!check_list.status[1] = 1

;; Produce ASCII summary files
scan2daynum, param.scan, day, scan_num
ktn_kidpar2summary, day, kidpar, $
                    sys_info.output_dir+"/allkids_summary.txt", $
                    sys_info.output_dir+"/matrix_summary.txt"
print, "save kid done"

   
end
