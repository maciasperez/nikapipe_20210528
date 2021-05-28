
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; geom_toi2kidmaps_parall
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

pro geom_toi2kidmaps_parall, scan_list, toi_dir, maps_dir, nickname, nproc=nproc, $
                             input_kidpar_file = input_kidpar_file, kids_out = kids_out, $
                             reso=reso, preproc=preproc, zigzag=zigzag, gamma=gamma, $
                             sn_min_list=sn_min_list, sn_max_list=sn_max_list
  
if not keyword_set(reso) then reso = 4.d0 ; 8.d0
  
for i=0, n_elements(scan_list)-1 do begin
   scan = scan_list[i]
   scan2daynum, scan, day, scan_num
   if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 then begin
      message, /info, "copying imbfits file from mrt-lx1"
      spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
   endif
endfor

spawn, "mkdir -p "+maps_dir

;; Retrieve results from geom_prepare_toi_parall
nscans = n_elements(scan_list)
for iscan=0, nscans-1 do begin
   scan = scan_list[iscan]
   nk_scan2run, scan, run       ; update !nika.raw_acq_dir

   ;; Restore kid maps
   file_save = toi_dir+"/beam_map_preproc_toi_"+scan+".save"
   if file_test(file_save) eq 0 then begin
      message, /info, "Could not find "+file_save
      message, /info, "Did you run 'make_geometry_5, /prepare, ...' first ?"
      return
   endif else begin
      restore, file_save, /verb
      
      ;; coadd maps from all the scans of the beammap sequence
      nkids = n_elements(kidpar)
      if iscan eq 0 then begin
         map_list_azel_tot          = map_list_azel*0.d0
         map_list_nasmyth_tot       = map_list_nasmyth*0.d0
         map_list_nhits_azel_tot    = map_list_azel*0.d0
         map_list_nhits_nasmyth_tot = map_list_nasmyth*0.d0
         el_avg_rad                 = el_avg*0.d0
         kidpar_tot                 = kidpar
      endif

      if nkids eq n_elements(kidpar) then begin
         map_list_azel_tot          += map_list_nhits_azel    * map_list_azel
         map_list_nasmyth_tot       += map_list_nhits_nasmyth * map_list_nasmyth
         map_list_nhits_azel_tot    += map_list_nhits_azel
         map_list_nhits_nasmyth_tot += map_list_nhits_nasmyth
      endif else begin
         ;; Sometimes, the valid kids are not all the same in each scan, we
         ;; must check here before coadding wrong kids (NP. Aug 17th, 2016)
         my_match, kidpar.numdet, kidpar_tot.numdet, suba, subb
         nkids = n_elements(suba)
         for i=0, nkids-1 do begin
            if i mod 100 eq 0 then print, "i/nkids: ", i
            ikid = suba[i]
            jkid = subb[i]
;         map_list_azel_tot[   jkid,*,*] += nhits_azel    * map_list_azel[    ikid,*,*]
;         map_list_nasmyth_tot[jkid,*,*] += nhits_nasmyth * map_list_nasmyth[ ikid,*,*]
            map_list_azel_tot[         jkid,*,*] += map_list_nhits_azel[   ikid,*,*] * map_list_azel[    ikid,*,*]
            map_list_nasmyth_tot[      jkid,*,*] += map_list_nhits_nasmyth[ikid,*,*] * map_list_nasmyth[ ikid,*,*]
            map_list_nhits_azel_tot[   jkid,*,*] += map_list_nhits_azel[   ikid,*,*]
            map_list_nhits_nasmyth_tot[jkid,*,*] += map_list_nhits_nasmyth[ikid,*,*]
         endfor
      endelse

;      nhits_azel_tot    += nhits_azel
;      nhits_nasmyth_tot += nhits_nasmyth
      el_avg_rad        += el_avg
   endelse
endfor

;;------------------------------------------------------------------------
;; Finalize the coaddition (normalize to total Nhits)
;; for ikid=0, nkids-1 do begin
;;    w = where( reform(map_list_nhits_azel_tot[ikid,*,*]) ne 0, nw)
;;    if nw ne 0 then begin
;;       map = reform( map_list_azel_tot[ikid,*,*])
;;       map[w] /= (reform(map_list_nhits_azel_tot[ikid,*,*]))[w]
;;       map_list_azel_tot[ikid,*,*] = map
;;    endif else begin
;;       map_list_azel_tot[ikid,*,*] = 0.d0
;;    endelse
;; endfor
w = where( map_list_nhits_azel_tot ne 0, nw)
map_list_azel_tot[w] /= map_list_nhits_azel_tot[w]

;; for ikid=0, nkids-1 do begin
;;    w = where( reform(map_list_nhits_nasmyth_tot[ikid,*,*]) ne 0, nw)
;;    if nw ne 0 then begin
;;       map = reform( map_list_nasmyth_tot[ikid,*,*])
;;       map[w] /= (reform(map_list_nhits_nasmyth_tot[ikid,*,*]))[w]
;;       map_list_nasmyth_tot[ikid,*,*] = map
;;    endif else begin
;;       map_list_nasmyth_tot[ikid,*,*] = 0.d0
;;    endelse
;; endfor
w = where( map_list_nhits_nasmyth_tot ne 0, nw)
map_list_nasmyth_tot[w] /= map_list_nhits_nasmyth_tot[w]

el_avg_rad /= nscans

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
   read, nproc
   nproc = long(nproc)
endif

nkids_per_proc = long( nkids/float(nproc))

for iproc=0, nproc-1 do begin
   if iproc ne (nproc-1) then begin
      kidpar                 = kidpar_tot[                 iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1]
      map_list_azel          = map_list_azel_tot[          iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
      map_list_nasmyth       = map_list_nasmyth_tot[       iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
      map_list_nhits_azel    = map_list_nhits_azel_tot[    iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
      map_list_nhits_nasmyth = map_list_nhits_nasmyth_tot[ iproc*nkids_per_proc: (iproc+1)*nkids_per_proc-1, *, *]
   endif else begin
      kidpar                 = kidpar_tot[                 iproc*nkids_per_proc:*]
      map_list_azel          = map_list_azel_tot[          iproc*nkids_per_proc:*, *, *]
      map_list_nasmyth       = map_list_nasmyth_tot[       iproc*nkids_per_proc:*, *, *]
      map_list_nhits_azel    = map_list_nhits_azel_tot[    iproc*nkids_per_proc:*, *, *]
      map_list_nhits_nasmyth = map_list_nhits_nasmyth_tot[ iproc*nkids_per_proc:*, *, *]
   endelse
   file = maps_dir+"/kid_maps_"+nickname+"_"+strtrim(iproc,2)+".save"
   message, /info, "Saving "+file
   save, file=file, $
         kidpar, map_list_azel, map_list_nasmyth, $
         map_list_nhits_azel, map_list_nhits_nasmyth, $
         el_avg_rad, $          ; nhits_azel, nhits_nasmyth,
         grid_azel, grid_nasmyth
endfor

end
