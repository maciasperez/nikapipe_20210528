
;; ****** DO NOT RUN THIS UNDER VNC, FOR AN UNKNOWN REASON, SPLIT_FOR
;; KILLS THE VNC SERVER ****************
pro compute_kid_beams, nproc, maps_dir, maps_output_dir, kidpars_output_dir, nickname, $
                       noplot=noplot, $
                       kids_out=kids_out, reso=reso, source=source;, input_kidpar_file = input_kidpar_file

  
if not keyword_set(kids_out) then kids_out = 0
if not keyword_set(reso) then reso = 4.d0
if not keyword_set(source) then source = 'Uranus'

spawn, "mkdir -p "+maps_output_dir
spawn, "mkdir -p "+kidpars_output_dir

varnames = ['file_list', 'maps_dir', 'maps_output_dir', $
            "kidpars_output_dir", "kids_out",  "reso", "nickname", $
            "source"]


root_name = "kid_maps_"+nickname
file_list = root_name+"_"+strtrim(indgen(nproc),2)+".save"
   
;; need to refresh nsplit
nsplit = nproc

;; ;;----------------------
;; ;; to debug
;; message, /info, "fix me: restricting to one scan to debug"
;; i=0
;; print, file_list[i]
;; nk_otf_geometry_sub, i, file_list, maps_dir, $
;;                      maps_output_dir, kidpars_output_dir, kids_out,
;;                      nickname, reso=reso, source=source
;; stop
;; ;;----------------------

split_for, 0, nproc-1, $
           commands=['nk_otf_geometry_sub, i, file_list, maps_dir, '+$
                     'maps_output_dir, kidpars_output_dir, kids_out, '+$
                     'nickname, reso=reso, source=source'], $
           varnames = varnames, nsplit=nsplit
;endfor

end
