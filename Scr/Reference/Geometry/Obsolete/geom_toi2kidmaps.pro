
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; geom_toi2kidmaps
;
; CATEGORY:
;
; CALLING SEQUENCE:
; 
; PURPOSE:
; Processes raw TOIs to produce individual kid maps
; 
; INPUT: 
;
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - July 2016, NP: from IDLtools/nk_otf_geometry_bcast_data.pro
;          that was a subroutine of make_geometry_4.
;-
;================================================================================================

pro geom_toi2kidmaps, scan_list, maps_dir, nickname, nproc=nproc, $
                      input_kidpar_file = input_kidpar_file, kids_out = kids_out, $
                      reso=reso, preproc=preproc, zigzag=zigzag, gamma=gamma, $
                      sn_min_list=sn_min_list, sn_max_list=sn_max_list

if not keyword_set(reso) then reso = 8.d0
  
for i=0, n_elements(scan_list)-1 do begin
   scan = scan_list[i]
   scan2daynum, scan, day, scan_num
;;    if file_test(!nika.xml_dir+"/iram30m-scan-"+scan+".xml") eq 0 then begin
;;       message, /info, "copying xml file from mrt-lx1"
;;       spawn, "scp t22@150.214.224.59:/ncsServer/mrt/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/iram*xml $XML_DIR/."
;;    endif
   if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 then begin
      message, /info, "copying imbfits file from mrt-lx1"
      spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
   endif
endfor

spawn, "mkdir -p "+maps_dir

;;------------------------------------------------------------------------
;; Produce maps per kids from each scan and combines them
nscans = n_elements(scan_list)
for iscan=0, nscans-1 do begin
   scan = scan_list[iscan]
   root_name = "otf_geometry_toi_"+scan

   nk_scan2run, scan, run       ; update !nika.raw_acq_dir

   if keyword_set(sn_min_list) then sn_min = sn_min_list[iscan]
   if keyword_set(sn_max_list) then sn_max = sn_max_list[iscan]
   
;   file_save = "beam_map_preproc_toi_"+scan+".save"
;   if file_test(file_save) and keyword_set(preproc) then begin
;      message, /info, "scan "+scan+" has already been processed for the beam map sequence"
;      message, /info, "Restoring it..."
;      restore, file_save
;   endif else begin
      message, /info, "Processing raw data..."
      geom_prepare_toi, scan, kidpar, $
                        map_list_azel, map_list_nasmyth, nhits_azel, nhits_nasmyth, $
                        grid_azel, grid_nasmyth, param, $
                        reso=reso, $
                        kid_step=kid_step, $
                        discard_outlyers=discard_outlyers, $
                        force_file=force_file, noplot=noplot, $
                        input_kidpar_file=input_kidpar_file, kids_out=kids_out, el_avg=el_avg, $
                        zigzag=zigzag, gamma=gamma, sn_min=sn_min, sn_max=sn_max

;      save, file=file_save, scan, iscan, kidpar, $
;            map_list_azel, map_list_nasmyth, nhits_azel, nhits_nasmyth, $
;            grid_azel, grid_nasmyth, param, el_avg
;   endelse
   
   ;; coadd maps from all the scans of the beammap sequence
   message, /info, "coadding..."
   nkids = n_elements(kidpar)
   if iscan eq 0 then begin
      map_list_azel_tot    = map_list_azel*0.d0
      map_list_nasmyth_tot = map_list_nasmyth*0.d0
      nhits_azel_tot       = nhits_azel*0.d0
      nhits_nasmyth_tot    = nhits_nasmyth*0.d0
      el_avg_rad           = el_avg*0.d0
   endif

   for ikid=0, nkids-1 do begin
      map_list_azel_tot[   ikid,*,*] += nhits_azel    * map_list_azel[    ikid,*,*]
      map_list_nasmyth_tot[ikid,*,*] += nhits_nasmyth * map_list_nasmyth[ ikid,*,*]
   endfor
   nhits_azel_tot    += nhits_azel
   nhits_nasmyth_tot += nhits_nasmyth
   el_avg_rad        += el_avg

endfor

;;------------------------------------------------------------------------
;; Finalize the coaddition (normalize to total Nhits)
w = where( nhits_azel_tot ne 0, nw)
for ikid=0, nkids-1 do begin
   map = reform( map_list_azel_tot[ikid,*,*])
   map[w] /= nhits_azel_tot[w]
   map_list_azel_tot[ikid,*,*] = map
endfor
w = where( nhits_nasmyth_tot ne 0, nw)
for ikid=0, nkids-1 do begin
   map = reform( map_list_nasmyth_tot[ikid,*,*])
   map[w] /= nhits_nasmyth_tot[w]
   map_list_nasmyth_tot[ikid,*,*] = map
endfor
el_avg_rad /= nscans
nhits_nasmyth = nhits_nasmyth_tot
nhits_azel    = nhits_azel_tot

if not keyword_set(nproc) then begin
;; Split the data into nproc .save files (leave at least 10 cpu for
;; acquisition ?
   nproc_max = (!cpu.hw_ncpu-10)>1
   cpu_time = dblarr( nproc_max)
   for iproc=0, nproc_max-1 do begin
      r = nkids - (iproc+1)*(nkids/(iproc+1))
      cpu_time[iproc] = nkids/(iproc+1) + r
      print, "nprocs, nperproc, r: ", iproc+1, nkids/(iproc+1), r, cpu_time[iproc]
   endfor
   w = where( cpu_time eq min(cpu_time), nw)
   nproc = w[0] + 1
   print, "nproc: ", nproc
   wind, 1, 1, /free, /large
   !p.multi=[0,1,2]
   plot, cpu_time
   plot, cpu_time, yra=[0, 200], /ys
   !p.multi=0
   print, "choose nproc"
   stop
endif

kidpar_tot = kidpar
nkids_per_proc = long( nkids/float(nproc))
;kidpar.beam_map_subindex = iscan
for iproc=0, nproc-1 do begin
   if iproc ne (nproc-1) then begin
      kidpar           = kidpar_tot[           iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1]
      map_list_azel    = map_list_azel_tot[    iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
      map_list_nasmyth = map_list_nasmyth_tot[ iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
   endif else begin
      kidpar           = kidpar_tot[           iproc*nkids_per_proc:*]
      map_list_azel    = map_list_azel_tot[    iproc*nkids_per_proc:*, *, *]
      map_list_nasmyth = map_list_nasmyth_tot[ iproc*nkids_per_proc:*, *, *]
   endelse
   file = maps_dir+"/kid_maps_"+nickname+"_"+strtrim(iproc,2)+".save"
   print, file
   save, file=file, $
         kidpar, map_list_azel, map_list_nasmyth, $
         el_avg_rad, nhits_azel, nhits_nasmyth, grid_azel, grid_nasmyth
endfor

end
