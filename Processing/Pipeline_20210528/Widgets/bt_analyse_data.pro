
pro bt_analyse_data, file=file

common bt_maps_common

if keyword_set(file) then begin
   full_file = file
endif else begin

   full_file = dialog_pickfile( path=!nika.raw_acq_dir)

   if full_file eq '' then begin
      ;; e.g. if cancel was clicked
      message, /info, ""
      message, /info, "file was not selected"
      message, /info, "relaunch do_reduce_map in the IDL x11 window"
      goto, exit
   endif

endelse

;; retrieve file and directory information
file     = file_basename( full_file)
dat_dir  = file_dirname( full_file)
file_dir = file_basename( dat_dir)

l = strlen(file)
if strmid( file, l-5) eq ".fits" then begin
   nickname = strmid( file, 0, l-5)
endif else begin
   nickname = file
endelse

;; Create output directory
output_dir = !nika.raw_acq_dir+"/IDL_output/"+file_dir+"/"+nickname
spawn, "mkdir -p "+output_dir

;; Create or open comments file
comments_file = output_dir+"/"+nickname+".txt"

;; To save result plot
out_png = 1
out_ps  = 0

sky_data = 0

;;------------------------------------------------------------
;; Launch the map analysis
list_data = "sample ofs_Az ofs_El RF_didq scan_st El"
if file eq "Z_2012_11_22_21h52m17_0222_Uranus_o" then begin
   sky_data = 1
   list_data = list_data+" retard "+strtrim(!nika.retard,2)
endif

read_type = 12 ; valid and off kids
rr = read_nika_brute( dat_dir+"/"+file, param_c, kidpar, data, units, $
                      indexdetecteurdebut=indexdetecteurdebut, nb_detecteurs_lu=nb_detecteurs_lu, $
                      read_type=read_type, list_data=list_data)
print, "total sample read_nika_brute: ", rr

data.rf_didq = -data.rf_didq ; to have positive peaks

;; bt_reduce_map, file, dat_dir, comments_file, output_dir, $
;;                out_png=out_png, out_ps=out_ps, sky_data=sky_data

;; June 24th, 2013
prepare_reduce_map, file, dat_dir, comments_file, output_dir, $
                    out_png=out_png, out_ps=out_ps, sky_data=sky_data

exit:
end

