
;+
pro reduce_quasars, source, scan_list, project_dir, keep_results=keep_results, reset_preproc=reset_preproc, $
                    projection=projection, lkg_corr=lkg_corr, lkg_dir=lkg_dir, $
                    no_opacity_corr=no_opacity_corr, cf=cf, tau225=tau225, reso=reso, $
                    no_avg=no_avg, hwp_harmonics_only=hwp_harmonics_only, force_subtract_hwp_per_subscan=force_subtract_hwp_per_subscan
;-

if n_params() lt 1 then begin
   dl_unix, 'reduce_quasars'
   return
endif

nscans = n_elements(scan_list)
in_param_file = 'param.save'
ncpu_max = 24

method_num = 15 ; 611 ; 35
source_init_param_2, source, 0, param, !nika.plot_dir+"/Polar", method_num=method_num

if keyword_set(cf) then param.math = "CF"

if keyword_set(no_opacity_corr) then param.do_opacity_correction = 0
if keyword_set(tau225) then param.force_opacity_225 = 1

if keyword_set(reso) then param.map_reso = reso

;; copy again to make sure
param.flag_sat   = 1
param.flag_ovlap = 1
param.flag_oor   = 1
if keyword_set(no_opacity_corr) then param.do_opacity_correction = 0
if keyword_set(tau225) then param.force_opacity_225 = 1
param.do_plot = 0               ; save time
param.one_mm_only  = 1
param.preproc_copy = 1          ; save time
param.polar = 1                 ; save time and memory

param.do_aperture_photometry = 1

param.do_plot = 1
param.plot_png = 1

;; Update locally
param.qu_iterative_mm                = 0
param.improve_lockin                 = 1
param.decor_qu                       = 0
if keyword_set(force_subtract_hwp_per_subscan) then param.force_subtract_hwp_per_subscan = 1 else param.force_subtract_hwp_per_subscan=0
if keyword_set(hwp_harmonics_only)             then param.hwp_harmonics_only             = 0
param.polar_n_template_harmonics     = 7
param.mask_default_radius            = 30.

if keyword_set(projection) then param.map_proj = projection
param.map_xsize = 20*60.
param.map_ysize = 20*60.

if keyword_set(reset_preproc) then begin
   for iscan=0, nscans-1 do spawn, "rm -f "+param.preproc_dir+"/*"+scan_list[iscan]+"*.save"
   message, /info, "reset preproc done"
endif

if strupcase(source) eq "CRAB" then begin
   param.map_xsize = 15*60.
   param.map_ysize = 15*60.
   param.polar_lockin_freqhigh = 6.d0
endif
if strupcase(source) eq "OMC-1" then begin
   param.map_xsize = 15*60.
   param.map_ysize = 15*60.
   param.polar_lockin_freqhigh = 6.d0
endif
if strupcase(source) eq "DR21OH" then begin
   param.map_xsize = 15*60.
   param.map_ysize = 15*60.
   param.polar_lockin_freqhigh = 6.d0
endif

param.project_dir = project_dir
save_cmd = 'save, file=in_param_file, param'
delvarx, lkg_kernel
case ( keyword_set(lkg_corr) + keyword_set(lkg_dir)) of
   0: print, ""
   1: begin
      message, /info, "Please set lkg_corr and lkg_dir together"
      help, lkg_corr
      help, lkg_dir
   end
   2: begin
      restore, lkg_dir+'/results.save'
      lkg_kernel = grid1
      delvarx, info1, kidpar1, param1
      save_cmd += ', lkg_kernel'
   end
   else: begin
      message, /info, "keyword_set(lkg_corr) + keyword_set(lkg_dir) has a weird value."
      stop
   end
endcase

junk = execute( save_cmd)

;; Unless specified, I do process the scan
if not keyword_set(keep_results) then begin
   for iscan=0, nscans-1 do spawn, "rm -rf "+param.project_dir+"/v_1/"+scan_list[iscan]
endif
            
;; process only new scans
tbp = intarr(nscans)
for iscan=0, nscans-1 do begin
   if file_test( param.project_dir+"/v_1/"+scan_list[iscan]+"/results.save") ne 1 then tbp[iscan] = 1
endfor
nscans_tbp = long(total(tbp))
print, "nscans_tbp: ", nscans_tbp

if nscans_tbp ne 0 then begin
   scan_list_tbp = scan_list[ where(tbp eq 1)]
   
   if nscans_tbp le ncpu_max then begin
      rest = 0
      my_scan_list = scan_list_tbp
      my_nscans = nscans_tbp
      ncpu_eff = my_nscans
   endif else begin
      nscans_per_proc = long( nscans_tbp/ncpu_max)
      my_nscans = nscans_per_proc * ncpu_max
      rest = nscans_tbp - my_nscans
      my_scan_list = scan_list_tbp[0:my_nscans-1]
      ncpu_eff = ncpu_max
   endelse



;; ;;-------------------------------------------------------
;;      ;; quick test on a single scan
;;    message, /info, "fix me: remove this one scan test"
;;   ;   i=n_elements(my_scan_list)/2
;;      restore, in_param_file
;;      param.do_plot = 1
;;                                 ;   param.improve_lockin = 0
;;      param.mydebug = 1
;;      save, param, file=in_param_file
;;      ;; i = 0
;;      ;; ;; my_scan_list = '20200228s75'
;;      ;; ;; my_scan_list = '20181210s150' ; Hamza's scan of DR21 that fails
;;      ;; my_scan_list = my_scan_list[24]
;;      my_scan_list = '20201112s58' ; bad polar maps
;;      ;my_scan_list = '20201111s64'
;;      ;my_scan_list = '20201111s66'
;;      i=0
;;      np_nk_polangle_sub, i, my_scan_list, in_param_file
;;      stop
;;      ;;-------------------------------------------------------
         
   split_for, 0, my_nscans-1, nsplit=ncpu_eff, $
              commands=['np_nk_polangle_sub, i, my_scan_list, in_param_file'], $
              varnames=['my_scan_list', 'in_param_file']
   if rest ne 0 then begin
      my_scan_list = scan_list_tbp[my_nscans:*]
      split_for, 0, rest-1, nsplit=rest, $
                 commands=['np_nk_polangle_sub, i, my_scan_list, in_param_file'], $
                 varnames=['my_scan_list', 'in_param_file']
   endif
endif

;; Combine all scans and write fits
if strupcase(param.map_proj) eq "RADEC" and not keyword_set(no_avg) then nk_average_scans, param, scan_list


end
