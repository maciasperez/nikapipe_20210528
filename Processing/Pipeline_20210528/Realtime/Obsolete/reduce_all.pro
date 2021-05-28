
;; Script that reduces all observation in a batch mode (semi-automatic)

logbook_file = !nika.soft_dir+"/Pipeline/Realtime/obs_logbook.txt"

pf       = 1
png      = 0
noskydip = 1

;;--------------------------------------------------------------------------------------------
readcol, logbook_file, day_list, scan_list, type_list, comment="#", format='A,I,A'

nscans = n_elements( day_list)
for iscan=0, nscans-1 do begin
   delvarx, param, sn_min, sn_max

   if strupcase( type_list[iscan]) eq "FOCUS" then begin
      focus, scan_list[iscan], day_list[iscan], f1, f2, $
             common_mode_radius=50., $
             noskydip=noskydip, png=png, pf=pf
   endif
   
   if strupcase( type_list[iscan]) eq "POINTING" then begin
      pointing, scan_list[iscan], day_list[iscan], offsets1, offsets2, $
                noskydip=noskydip, png=png, pf=pf, /focal
   endif
   
   if strupcase( type_list[iscan]) eq "OTF_MAP" then begin
      otf_map, scan_list[iscan], day_list[iscan], noskydip=noskydip, pf=pf, png=png
   endif

   if strupcase( type_list[iscan]) eq "SKYDIP" then begin
      skydip, scan_list[iscan], day_list[iscan], kidpar, png=png, pf=pf
   endif

   if strupcase( type_list[iscan]) eq "OTF_GEOMETRY" then begin
      output_kidpar_nickname = "kidpar_"+strtrim(day_list[iscan],2)+"s"+strtrim(scan_list[iscan],2)
      otf_geometry, scan_list[iscan], day_list[iscan], noskydip=noskydip, $
                    pf=pf, output_kidpar_nickname=output_kidpar_nickname, png=png
      otf_map, scan_list[iscan], day_list[iscan], noskydip=noskydip, pf=pf, png=png
   endif

   ;; ;; Comment out until I know how to get the input focus, p2cor and p7cor
   ;; if strupcase( type_list[iscan]) eq "FOCUS_LISS" then begin
   ;;    focus_liss, day_list[iscan], scan_list[iscan], 0.2, p2cor=1e-10, p7cor=1e-10, $
   ;;                png=png, noskydip=noskydip, pf=pf
   ;; endif

endfor

end
