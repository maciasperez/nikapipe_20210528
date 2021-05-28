
;;=====================================
;; KATANA: Kid Array Timelines ANAlysis
;;=====================================

pro katana_light, scan_num, day, absurd=absurd, $
                  preproc_file=preproc_file, preproc_index=preproc_index, $
                  input_kidpar_file=input_kidpar_file, ptg_numdet_ref=ptg_numdet_ref, $
                  keep_neg = keep_neg, kidpar_out=kidpar_out, coltable=coltable

common ktn_common, $
   data, data_copy, kidpar, ks, dispmat, kquick, $
   toi, toi_med, w8, time, x_0, y_0, pw, freq, pw_raw, $
   disp, sys_info, pwc, sky_data, info, grid, $
   operations, param_c, param, units, grid_nasmyth, grid_azel, scan


scan = day+"s"+strtrim(scan_num,2)
nk_scan2run, scan, run
!nika.run = run

;; To be sure that !nika.run won't enter any specific case of a run =< 5
!nika.run = !nika.run > 11

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+output_dir
!mamdlib.coltable = 4
;; LP added the line below
if keyword_set(coltable) then !mamdlib.coltable = coltable

ktn_prepare_light, preproc_file, preproc_index, run_widget, $
                   keep_neg=keep_neg, input_kidpar_file=input_kidpar_file


if run_widget eq 1 then ktn_widget_light, preproc_index, ptg_numdet_ref, scan_num, day

message, /info, ""
message, /info, "KATANA_light finished."

kidpar_out = kidpar

end
