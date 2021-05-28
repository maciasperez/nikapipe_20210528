
;; Process TOIs before projection

pro beam_maps_toi_proc, scan_list, maps_dir, nickname, nproc=nproc, $
                        input_kidpar_file = input_kidpar_file, kids_out = kids_out, $
                        reso=reso, preproc=preproc, zigzag=zigzag, gamma=gamma

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

nscans = n_elements(scan_list)
for iscan=0, nscans-1 do begin
   scan = scan_list[iscan]
   root_name = "otf_geometry_toi_"+scan

   nk_scan2run, scan, run       ; update !nika.raw_acq_dir
   if keyword_set(kids_out) then begin
      file_save = maps_dir+'/bcast_data_'+strtrim(scan,2)+'.save'
   endif else begin
      file_save = maps_dir+'/bcast_data_'+strtrim(scan,2)+'_kidsout.save'
   endelse
   otf_geometry_bcast_data, scan, iscan, kidpar, $
                            map_list_azel, map_list_nasmyth, nhits_azel, nhits_nasmyth, $
                            grid_azel, grid_nasmyth, param, $
                            reso=reso, $
                            kid_step=kid_step, $
                            discard_outlyers=discard_outlyers, $
                            force_file=force_file, noplot=noplot, $
                            input_kidpar_file=input_kidpar_file, kids_out=kids_out, el_avg=el_avg, $
                            zigzag=zigzag, gamma=gamma
;   save, kidpar, $
;         map_list_azel, map_list_nasmyth, nhits_azel, nhits_nasmyth, $
;         grid_azel, grid_nasmyth, el_avg, file=file_save

   ;; coadd maps from all the scans of the beammap sequence
   message, /info, "coadding..."
   nkids = n_elements(kidpar)
   if iscan eq 0 then begin
      map_list_azel_tot    = map_list_azel*0.d0
      nhits_azel_tot       = nhits_azel*0.d0
      map_list_nasmyth_tot = map_list_nasmyth*0.d0
      nhits_nasmyth_tot    = nhits_nasmyth*0.d0
      el_avg_rad           = 0.d0
   endif
   for ikid=0, nkids-1 do begin
      map_list_azel_tot[   ikid,*,*] += nhits_azel    *map_list_azel[    ikid,*,*]
      map_list_nasmyth_tot[ikid,*,*] += nhits_nasmyth *map_list_nasmyth[ ikid,*,*]
      el_avg_rad += el_avg
   endfor
   nhits_azel_tot    += nhits_azel
   nhits_nasmyth_tot += nhits_nasmyth
endfor

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
;; message, /info, "fix me"
;; ;; nproc = 52
;; ;; stop
;; nproc = 20                      ; other numbers do not exit very well with split_for... (sic!)

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
