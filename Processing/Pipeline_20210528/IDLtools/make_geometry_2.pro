;; From NP/Nika2Run1/np_make_geometry.pro
;; Jan 13th, 2015
;;-----------------------------------------------

pro make_geometry_2, scan_list, black_list=black_list, process=process, maps=maps, $
                     ofs_el_1=ofs_el_1, ofs_el_2=ofs_el_2, nostop=nostop, new=new, $
                     skydip_scan=skydip_scan, iteration=iteration, add_skydip=add_skydip, $
                     ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject, source=source


;;ptg_numdet_ref = 3133 ; 830
reso = 8.d0

if not keyword_set(source)   then source = 'Uranus'
if not keyword_set(ofs_el_1) then ofs_el_1 = -100
if not keyword_set(ofs_el_2) then ofs_el_2 =  80
ofs_el_min = [     -400, ofs_el_1, ofs_el_2]
ofs_el_max = [ ofs_el_1, ofs_el_2,      400]

if not keyword_set(iteration) then iteration  = 1
;; prepare the timeline
if keyword_set(process) then process=1 else process=0
;; compute the maps for each KID
if keyword_set(maps) then maps=1 else maps=0
;; Add skydip coeffs at the second iteration
if not keyword_set(add_skydip) then add_skydip = 0

if not keyword_set(reso) then reso = 8.d0
if not keyword_set(iteration) then iteration = 1
  
nproc = 16

;; Concatenate "scan_list" into "nickname" to name the final kidpar
nscans = n_elements(scan_list)
if nscans eq 1 then begin
   nickname = strtrim(scan_list[0], 2)
endif else begin
   nickname = strmid(scan_list[0], 0, 9)
   for iscan = 0, n_elements(scan_list)-2 do begin
      l = strlen(scan_list[iscan])
      nickname += strmid( scan_list[iscan], 9, l-9)+"_"
   endfor
   l = strlen(scan_list[iscan])
   nickname +=  strmid( scan_list[iscan],  9,  l-9)
endelse

keep_neg = 0

beam_maps_dir      = !nika.plot_dir+'/NP/Beam_maps_reso_'+strtrim(reso, 2)
toi_dir            = beam_maps_dir+"/TOIs"
maps_output_dir    = beam_maps_dir+"/Maps"
kidpars_output_dir = beam_maps_dir+"/Kidpars"

if iteration eq 1 then begin
   
   if process eq 1 then begin
      beam_maps_toi_proc, scan_list, toi_dir, nproc, nickname, input_kidpar_file = input_kidpar_file
      return
   endif
   
   ;; DO NOT RUN compute_kid_maps_2 UNDER VNC (split_for crashes it)
   if maps eq 1 then begin
      compute_kid_maps_2, scan_list, nproc, toi_dir, maps_output_dir, kidpars_output_dir, nickname, $
                          noplot = noplot,  source=source, $
                          input_kidpar_file = input_kidpar_file, reso = reso
      return
   endif
   
   ;; Merge the kidpars from the 16 processess for each scan
   version = 0
   raw     = 1
   ;; merge_sub_kidpars, scan_list, kidpars_output_dir, nproc, nostop=nostop, version=version, raw=raw
   merge_sub_kidpars, kidpars_output_dir, nproc, nickname, nostop=nostop, version=version, raw=raw, $
                      ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject
   
;;    ;; Merge the complete kidpars of each scan
;;    kidpar_list = "kidpar_"+scan_list+"_noskydip.fits"
;;    merge_scan_kidpars, scan_list, kidpar_list, nickname, $
;;                        ptg_numdet_ref=ptg_numdet_ref, nostop=nostop, $
;;                        version=version, ofs_el_min=ofs_el_min, ofs_el_max=ofs_el_max, black_list=black_list, $
;;                        dist_reject=dist_reject

   ;; Now kill remaining "doubles"
   message, /info, "Now check you're under VNC or X2GO to run the widgets"
   message, /info, "If yes, press .c, otherwise reconnect and relaunch."
   stop
   version = 1
   kid_selection_2, scan_list, maps_output_dir, kidpars_output_dir, nickname, $
                    iter = iter, keep_neg = keep_neg, version=version, $
                    input_kidpar_file="kidpar_"+nickname+"_noskydip.fits", $
                    ofs_el_min=ofs_el_min, ofs_el_max=ofs_el_max, black_list=black_list, $
                    ptg_numdet_ref=ptg_numdet_ref
      
endif

if iteration eq 2 then begin

   delvarx, param, info, kidpar, data, input_kidpar_file, noplot
   input_kidpar_file = "kidpar_"+nickname+"_noskydip_v1.fits"
   
   ;; Add skydip coeffs
   if add_skydip eq 1 then begin
      scan2daynum, skydip_scan, dd, ss
      nk_default_param, param
      nk_default_info, info
      nk_skydip_4, ss, dd, param, info, kidpar, data, $
                   input_kidpar_file = input_kidpar_file
      nk_write_kidpar, kidpar, "kidpar_"+nickname+"_WithC0C1.fits"
      stop
   endif
   
   input_kidpar_file = "kidpar_"+nickname+"_WithC0C1.fits"
   if file_test(input_kidpar_file) eq 0 then begin
      message, /info, "You need to add skydip coeffs for the second iteration"
      message, /info, "Make sure about skydip_scan, set add_skydip to 1 and relaunch."
      return
   endif
    
   toi_dir            = beam_maps_dir+"/TOIs_kidsout"
   maps_output_dir    = beam_maps_dir+"/Maps_kidsout"
   kidpars_output_dir = beam_maps_dir+"/Kidpars_kidsout"

   if process eq 1 then $
      beam_maps_toi_proc, scan_list, toi_dir, nproc, input_kidpar_file = input_kidpar_file, /kids_out
   
   ;; DO NOT RUN compute_kid_maps_2 UNDER VNC (split_fot crashes it)
   if maps eq 1 then $
      compute_kid_maps_2, scan_list, nproc, toi_dir, maps_output_dir, kidpars_output_dir,   $
                          noplot = noplot,  $
                          input_kidpar_file = input_kidpar_file, reso = reso, /kids_out

   message, /info, "Now check you're under VNC or X2GO to run the widgets"
   message, /info, "If yes, press .c, otherwise reconnect and relaunch."
   stop

   message, /info, "fix me: version number"
   version=3
   stop
   kid_selection_2, scan_list, maps_output_dir, kidpars_output_dir, nickname, $
                    iter = iter, keep_neg = keep_neg, version=version, $
                    input_kidpar_file=input_kidpar_file, $
                    ofs_el_min=ofs_el_min, ofs_el_max=ofs_el_max, black_list=black_list, $
                    ptg_numdet_ref=ptg_numdet_ref
      
   
endif

end
