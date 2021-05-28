;; From NP/Nika2Run1/np_make_geometry.pro
;; Jan 13th, 2015
;;-----------------------------------------------

pro make_geometry_3, scan_list, nproc=nproc, black_list=black_list, $
                     process=process, beams=beams, merge=merge, select=select, $
                     preproc=preproc, $
                     finalize=finalize, $
                     nostop=nostop, reso=reso, $
                     skydip_scan=skydip_scan, iteration=iteration, add_skydip=add_skydip, $
                     ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject, source=source


if not keyword_set(reso) then reso     = 8.d0
keep_neg = 0

if not keyword_set(source)    then source = 'Uranus'
if not keyword_set(iteration) then iteration  = 1
if not keyword_set(reso)      then reso = 8.d0
  
if not keyword_set(nproc) then nproc = 16

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

beam_maps_dir      = !nika.plot_dir+'/NP/Beam_maps_reso_'+strtrim(reso, 2)
toi_dir            = beam_maps_dir+"/TOIs"
beams_output_dir    = beam_maps_dir+"/Beams"
kidpars_output_dir = beam_maps_dir+"/Kidpars"

if iteration eq 1 then begin
   
   if keyword_set(process) then begin
      beam_maps_toi_proc, scan_list, toi_dir, nickname, nproc=nproc, $
                          input_kidpar_file = input_kidpar_file, reso=reso, $
                          preproc=preproc
      return
   endif
   
   if keyword_set(beams) then begin
      compute_kid_beams, nproc, toi_dir, beams_output_dir, kidpars_output_dir, nickname, $
                         noplot = noplot,  source=source, $
                         input_kidpar_file = input_kidpar_file, reso = reso
      return
   endif
   
   ;; Merge the sub kidpars
   if keyword_set(merge) then begin
      version = 0
      raw     = 1
      merge_sub_kidpars, kidpars_output_dir, nproc, nickname, nostop=nostop, version=version, raw=raw, $
                         ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject
      return
   endif

   ;; Now kill remaining "doubles"
   if keyword_set(select) then begin
      message, /info, "Now check you're under VNC or X2GO to run the widgets"
      message, /info, "If yes, press .c, otherwise reconnect and relaunch."
      stop
      kid_selection_2, scan_list, beams_output_dir, kidpars_output_dir, nickname, $
                       iter = iter, keep_neg = keep_neg, $
                       input_kidpar_file="kidpar_"+nickname+"_noskydip.fits", $
                       ofs_el_min=ofs_el_min, ofs_el_max=ofs_el_max, black_list=black_list, $
                       ptg_numdet_ref=ptg_numdet_ref
      return
   endif

   ;; Finalize Nasmyth to Azel rotation center, check ptg_numdet_ref
   if keyword_set(finalize) then begin
      version = 1
      scan = scan_list[0]
      select2kidpar, "kidpar_select_"+strtrim(scan,2)+".fits", ptg_numdet_ref, kidpar, version, nickname
      return
   endif
      
endif

if iteration eq 2 then begin
   message, /info, "Not updated yet"
;;   
;;   delvarx, param, info, kidpar, data, input_kidpar_file, noplot
;;   input_kidpar_file = "kidpar_"+nickname+"_noskydip_v1.fits"
;;   

   print, "chec toi_dir, kidpar names..."
   stop

   ;; Add skydip coeffs
   if keyword_set(add_skydip) then begin
      scan2daynum, skydip_scan, dd, ss
      nk_default_param, param
      nk_default_info, info
      nk_skydip_4, ss, dd, param, info, kidpar, data, $
                   input_kidpar_file = input_kidpar_file
      nk_write_kidpar, kidpar, "kidpar_"+nickname+"_WithC0C1.fits"
      stop
   endif

   if keyword_set(process) then begin
      beam_maps_toi_proc, scan_list, toi_dir, nickname, nproc=nproc, $
                          input_kidpar_file = input_kidpar_file, reso=reso, $
                          preproc=preproc
      return
   endif
   
   if keyword_set(beams) then begin
      compute_kid_beams, nproc, toi_dir, beams_output_dir, kidpars_output_dir, nickname, $
                         noplot = noplot,  source=source, $
                         input_kidpar_file = input_kidpar_file, reso = reso
      return
   endif
   
   ;; Merge the sub kidpars
   if keyword_set(merge) then begin
      version = 0
      raw     = 1
      merge_sub_kidpars, kidpars_output_dir, nproc, nickname, nostop=nostop, version=version, raw=raw, $
                         ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject
      return
   endif

   ;; Now kill remaining "doubles"
   if keyword_set(select) then begin
      message, /info, "Now check you're under VNC or X2GO to run the widgets"
      message, /info, "If yes, press .c, otherwise reconnect and relaunch."
      stop
      kid_selection_2, scan_list, beams_output_dir, kidpars_output_dir, nickname, $
                       iter = iter, keep_neg = keep_neg, $
                       input_kidpar_file="kidpar_"+nickname+"_noskydip.fits", $
                       ofs_el_min=ofs_el_min, ofs_el_max=ofs_el_max, black_list=black_list, $
                       ptg_numdet_ref=ptg_numdet_ref
      return
   endif

   ;; Finalize Nasmyth to Azel rotation center, check ptg_numdet_ref
   if keyword_set(finalize) then begin
      version = 1
      scan = scan_list[0]
      select2kidpar, "kidpar_select_"+strtrim(scan,2)+".fits", ptg_numdet_ref, kidpar, version, nickname
      return
   endif
      
endif

end
