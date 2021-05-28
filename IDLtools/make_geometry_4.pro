;; From NP/Nika2Run1/np_make_geometry.pro
;; Jan 13th, 2015
;;-----------------------------------------------

pro make_geometry_4, scan_list, nproc=nproc, black_list=black_list, $
                     process=process, beams=beams, merge=merge, select=select, $
                     preproc=preproc, $
                     finalize=finalize, $
                     nostop=nostop, reso=reso, $
                     skydip_scan=skydip_scan, iteration=iteration, $
                     ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject, source=source, $
                     input_kidpar_file=input_kidpar_file, png=png, ps=ps, no_add_skydip=no_add_skydip

if not keyword_set(reso) then reso     = 8.d0
keep_neg = 0

if not keyword_set(source)    then source = 'Uranus'
if not keyword_set(iteration) then iteration  = 1
if not keyword_set(reso)      then reso = 8.d0
if not keyword_set(nproc) then nproc = 16
if not keyword_set(dist_reject) then dist_reject=20

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

; beam_maps_dir = !nika.plot_dir+'/Beam_maps_reso_'+strtrim(reso, 2)
beam_maps_dir = '/home/observer/NIKA/Plots/Run16/Geometries/Beam_maps_reso_'+strtrim(reso, 2)

if iteration eq 1 then begin
   maps_dir           = beam_maps_dir+"/Maps"
   beams_output_dir   = beam_maps_dir+"/Beams"
   kidpars_output_dir = beam_maps_dir+"/Kidpars"
   if keyword_set(input_kidpar_file) then kidpar_file = input_kidpar_file
   version = 0
   add_skydip = 0
endif else begin
   ;; iteration = 2
   version = 2
   if keyword_set(no_add_skydip) then add_skydip = 0 else add_skydip = 1
   if not keyword_set(input_kidpar_file) then begin
      message, /info, "You must provide input_kidpar_file for the second iteration"
      return
   endif
   kidpar_file = input_kidpar_file
   
   kids_out = 1
   maps_dir            = beam_maps_dir+"/Maps_kids_out"
   beams_output_dir   = beam_maps_dir+"/Beams_kids_out"
   kidpars_output_dir = beam_maps_dir+"/Kidpars_kids_out"
   spawn, "mkdir -p "+maps_dir
   spawn, "mkdir -p "+beams_output_dir
   spawn, "mkdir -p "+kidpars_output_dir
endelse
plot_dir = beam_maps_dir+"/Plots"

;; clean TOIs and projects maps per kids
if keyword_set(process) then begin
   if add_skydip eq 1 then begin
      ;; Add skydip coeffs
      if not keyword_set(skydip_scan) then begin
         message, /info, "you requested add_skydip, you must pass skydip_scan as a keyword"
         return
      endif
      scan2daynum, skydip_scan, dd, ss
      nk_default_param, param
      nk_default_info, info
      nk_skydip_4, ss, dd, param, info, kidpar, data, $
                   input_kidpar_file = input_kidpar_file
      kidpar_file = "kidpar_"+nickname+"_WithC0C1.fits"
      nk_write_kidpar, kidpar, kidpar_file
   endif

   beam_maps_toi_proc, scan_list, maps_dir, nickname, nproc=nproc, $
                       input_kidpar_file = kidpar_file, reso=reso, $
                       preproc=preproc, kids_out=kids_out
   return
endif

;; Fit beam parameters on kid maps
if keyword_set(beams) then begin
   compute_kid_beams, nproc, maps_dir, beams_output_dir, kidpars_output_dir, nickname, $
                      noplot = noplot,  source=source, $
                      input_kidpar_file = kidpar_file, reso = reso
   return
endif

;; Merge the sub kidpars
if keyword_set(merge) then begin
   merge_sub_kidpars, kidpars_output_dir, nproc, nickname, nostop=nostop, version=version, $
                      ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject, png=png, ps=ps, plot_dir=plot_dir
   return
endif

;; Now kill remaining "doubles"
if keyword_set(select) then begin
   message, /info, "Now check you're under VNC or X2GO to run the widgets"
   message, /info, "If yes, press .c, otherwise reconnect and relaunch."
   stop
   kid_selection_2, scan_list, beams_output_dir, kidpars_output_dir, nickname, $
                    iter = iter, keep_neg = keep_neg, $
                    input_kidpar_file="kidpar_"+nickname+"_noskydip_v"+strtrim(version, 2)+".fits", $
                    ofs_el_min=ofs_el_min, ofs_el_max=ofs_el_max, black_list=black_list, $
                    ptg_numdet_ref=ptg_numdet_ref
   return
endif

;; Finalize Nasmyth to Azel rotation center, check ptg_numdet_ref
if keyword_set(finalize) then begin
   scan = scan_list[0]
   select2kidpar, "kidpar_select_"+strtrim(scan,2)+".fits", ptg_numdet_ref, kidpar, version, nickname, skydip=add_skydip, nostop=nostop
   return
endif

end
