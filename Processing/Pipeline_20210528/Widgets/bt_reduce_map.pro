
pro bt_reduce_map, file=file, png=png, ps=ps, one_mm_only=one_mm_only, two_mm_only=two_mm_only

common bt_maps_common, $
   data, kidpar, ks, kquick, $
   toi, toi_med, w8, time, x_0, y_0, pw, freq, pw_raw, $
   disp, sys_info, $
   operations, param_c, units


if not keyword_set(file) then begin

   file = dialog_pickfile( path=!nika.raw_acq_dir)

   if file eq '' then begin
      ;; e.g. if cancel was clicked
      message, /info, ""
      message, /info, "file was not selected, relanch to restart."
      goto, exit
   endif

endif

;; Get first information about the data
file2nickname, file, nickname, scan, date, matrix, box, source, lambda, ext, file_save, /raw

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+date
spawn, "mkdir -p "+output_dir

;; Init param to be used in pipeline modules
day      = strmid( date, 0, 4)+strmid( date, 5, 2)+strmid( date, 8, 2)
scan_num = 0 ; place holder
nika_pipe_default_param, scan_num, day, param
param.output_dir           = output_dir
param.map.size_ra          = 400.
param.map.size_dec         = 400.
param.map.reso             = 4. ; 8.
param.decor.method         = 'median_simple'
param.decor.iq_plane.apply = 'no'

;; Erase the default kidpar to make sure this code creates one from scratch
param.kid_file.a  = ''
param.kid_file.b  = ''
param.config_file = ''

;; Get data
nika_pipe_getdata, param, data, kidpar, /nocut, force_file=file, $
                   tau_force=tau_force, one_mm_only=one_mm_only, two_mm_only=two_mm_only

;; No calibration yet
;; nika_pipe_calib, param, data, kidpar

;; Deglitch
nika_pipe_deglitch, param, data, kidpar

;; Data cleaning
nika_pipe_decor, param, data, kidpar

;; retrieve file and directory information
file     = file_basename( param.data_file)
dat_dir  = file_dirname( param.data_file)

l = strlen(file)
if strmid( file, l-5) eq ".fits" then begin
   nickname = strmid( file, 0, l-5)
endif else begin
   nickname = file
endelse

;; Create or open comments file
comments_file = param.output_dir+"/"+nickname+".txt"

;;-------------------------------------------------------------------------------
;; Launch the map analysis and pixel selection
prepare_reduce_map, file, dat_dir, comments_file, param.output_dir, $
                    out_png=png, out_ps=ps, sky_data=sky_data, reso_map=reso_map
bt_plot_fp_pos

if keyword_set(one_mm_only) then sys_info.nickname = sys_info.nickname+"_1mm"
if keyword_set(two_mm_only) then sys_info.nickname = sys_info.nickname+"_2mm"

bt_reduce_map_widget, no_block = no_block, /check_list

;; Useful optional output
output_kidpar_fits = sys_info.output_kidpar_fits

message, /info, ""
message, /info, "bt_reduce_map FINISHED."


exit:
end


