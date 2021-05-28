
;; ****** DO NOT RUN THIS UNDER VNC, FOR AN UNKNOWN REASON, SPLIT_FOR
;; KILLS THE VNC SERVER ****************
pro compute_kid_maps_2, scan_list, nproc, toi_dir, maps_output_dir, kidpars_output_dir, nickname, $
                        noplot=noplot, $
                        input_kidpar_file = input_kidpar_file,  kids_out =  kids_out, $
                        reso = reso, source=source
  
if not keyword_set(kids_out) then kids_out = 0
if not keyword_set(reso) then reso = 4.d0
if not keyword_set(source) then source = 'Uranus'

spawn, "mkdir -p "+maps_output_dir
spawn, "mkdir -p "+kidpars_output_dir

varnames = ['file_list', 'toi_dir', 'maps_output_dir', $
            "kidpars_output_dir", "kids_out",  "reso", "nickname", $
            "source"]


;for iscan = 0, n_elements(scan_list) -1 do begin
;   scan =  scan_list[iscan]
;   root_name = "otf_geometry_toi_"+scan
;; file_list = root_name+"_"+string(indgen(nproc),format='(I3.3)')+".save"
root_name = "kid_maps"
file_list = root_name+"_"+strtrim(indgen(nproc),2)+".save"
   
   ;; need to refresh nsplit
   nsplit = nproc

;; ;;----------------------
;; ;; to debug
;; message, /info, "fix me: "
;; i=0
;; otf_geometry_sub, i, file_list, toi_dir, $
;;                      maps_output_dir, kidpars_output_dir, kids_out, reso=reso
;; stop
;; ;;----------------------

   split_for, 0, nproc-1, $
              commands=['otf_geometry_sub, i, file_list, toi_dir, '+$
                        'maps_output_dir, kidpars_output_dir, kids_out, '+$
                        'nickname, reso=reso, source=source'], $
              varnames = varnames, nsplit=nsplit
;endfor

end
