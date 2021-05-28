
;; Compare measured fluxes on a list of calibrators to their expected
;; value
;; hacked from Labtools/NP/Dev/redo_secondary_calibrators_n2r4.pro
;;------------------------------------------------------------------------

pro make_calibrator_maps, input_kidpar_file, output_maps_dir, reset=reset, nobeammaps=nobeammaps, $
                          catch_up=catch_up, serial=serial, $
                          nscans_max=nscans_max, $
                          png=png, ps=ps, method=method, $
                          all_scan_list=all_scan_list, source_list=source_list, dry=dry, $
                          day_min=day_min, average=average, no_tel_gain=no_tel_gain, $
                          polynomial=polynomial

run = 'N2R9'

if not keyword_set(nscans_max) then nscans_max = -1
if not keyword_set(day_min) then day_min = 0

;; Update with the relevant data base file
db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v0.save"

;; Define output directory name as a function of the kidpar version
if not keyword_set(input_kidpar_file) then input_kidpar_file = !nika.off_proc_dir+"/kidpar_skydip_n2r9_skd1.fits"

;; set reset to 1 to recompute everything from scratch
if not keyword_set(reset) then reset = 0

;; discard Mars for now because of its multiple entries in the csv
;; file
source_list = ['Uranus', $
               'Neptune', $
               'BODY Ceres', $
               'BODY Vesta', $
               'MWC349', $
               'CRL2688', $
               'NGC7027', $
               'Pluto']

;source_list = ['BODY Ceres', $
;               'BODY Vesta']

nsources = n_elements(source_list)
if not keyword_set(method) then method = "common_mode_kids_out"

;;==========================================================================================
nk_default_param, param
if keyword_set(no_tel_gain) then param.do_tel_gain_corr = 0
if keyword_set(polynomial)  then param.polynomial = polynomial
param.give_scan_quality = 1
param.map_xsize = 800.d0
param.map_ysize = 800.d0
param.map_reso = 2.d0
param.plot_ps = 1
param.plot_png = 0
param.flag_uncorr_kid = 1 ; 0 ; 1
param.force_kidpar = 1
param.file_kidpar = input_kidpar_file
param.decor_cm_dmin = 60.d0
param.decor_method = method

;; Determine the complete list of scans that may be processed
restore, db_file
db_scan = scan
nscans_tot = 0
for isource=0, nsources-1 do begin
   source = source_list[isource]
   paramfile = "param_"+str_replace(source," ", "_")+".save"

   case strupcase(source) of
      "URANUS":     param.map_proj = "azel"
      "NEPTUNE":    param.map_proj = "azel"
      "MARS":       param.map_proj = "azel"
      "BODY CERES": param.map_proj = "azel"
      "BODY VESTA": param.map_proj = "azel"
      else: param.map_proj = "radec"
   endcase
   
   ;; Scan_list
   if keyword_set(nobeammaps) then begin
      w = where( strupcase( db_scan.object) eq strupcase( source) and $
                 db_scan.obstype eq "onTheFlyMap" and db_scan.n_obs lt 99 and $
                 strmid(db_scan.comment,0,5) ne "focus" and $
                 long( db_scan.day) ge day_min, nw)
   endif else begin
      w = where( strupcase( db_scan.object) eq strupcase( source) and $
                 db_scan.obstype eq "onTheFlyMap" and $
                 strmid(db_scan.comment,0,5) ne "focus" and $
                 long( db_scan.day) ge day_min, nw)
   endelse

   if nw ne 0 then begin
      ;; Need to account for the blank in e.g. "BODY Ceres"...
      source_dir = output_maps_dir+"/"+method+"/"+str_replace(source," ", "_")
      spawn, "mkdir -p source_dir"
      ;; Defined one parameter file per source with proper output directory
      param.project_dir = source_dir
      save, param, file=paramfile
      ;; list of scans
      source_scan_list = strtrim(db_scan[w].day,2)+"s"+strtrim(db_scan[w].scannum,2)
      if nscans_max gt 0 then source_scan_list = source_scan_list[0:nscans_max-1]
      nn = n_elements(source_scan_list)
      if nscans_tot eq 0 then begin
         param_file_list_tot = strarr(nn) + paramfile
         scan_list_tot       = source_scan_list
         source_dir_list = strarr(nn) + source_dir
      endif else begin
         scan_list_tot       = [scan_list_tot, source_scan_list]
         param_file_list_tot = [param_file_list_tot, strarr(nn) + paramfile]
         source_dir_list = [source_dir_list, strarr(nn) + source_dir]
      endelse
      nscans_tot = n_elements(scan_list_tot)
   endif
endfor

;; Deal with already processed files
for isource=0, nsources-1 do begin
   source = source_list[isource]
   source_dir = output_maps_dir+"/"+method+"/"+str_replace(source," ", "_")
   if keyword_set(reset) then begin
      spawn, "rm -f "+source_dir+"/error*dat"
      spawn, "rm -f "+source_dir+"/UP_files/*dat"
      spawn, "rm -rf "+source_dir+"/v_1/*"
   endif
   if keyword_set(catch_up) then begin
      spawn, "rm -f "+source_dir+"/UP_files/*dat"
   endif
endfor

keep = lonarr(nscans_tot)
for iscan=0, nscans_tot-1 do begin
   scan = scan_list_tot[iscan]
   bp_file = source_dir_list[iscan]+"/UP_files/BP_"+scan+".dat"
   ok_file = source_dir_list[iscan]+"/UP_files/OK_"+scan+".dat"
   if (file_test(ok_file) eq 0) and (file_test(bp_file) eq 0) then keep[iscan]=1 else keep[iscan]=0
endfor

wkeep = where( keep eq 1, nwkeep)
if nwkeep eq 0 then begin
   message, /info, "All scans have already been processed"
endif else begin
   scan_list       = scan_list_tot[       wkeep]
   param_file_list = param_file_list_tot[ wkeep]
   nscans = n_elements(scan_list)
   print, "Number of scans remaining to process: ", nscans

   if keyword_set(serial) or nscans eq 1 then begin
      for iscan=0, nscans-1 do nk_ps2, iscan, scan_list, param_file_list
   endif else begin
      ;; Optimize job distribution
      if not keyword_set(ncpu_max) then ncpu_max = 16 ; to leave space for the acquisition
      optimize_nproc, nscans, ncpu_max, nproc
      split_for, 0, nscans-1, nsplit = nproc, $
                 commands=['nk_ps2, i, scan_list, param_file_list'], $
                 varnames=['scan_list', 'param_file_list']
   endelse

   ;; Compute the final combined map of each source
   array = param_file_list_tot
   b = array[UNIQ(array, SORT(array))]
   for ifile=0, n_elements(b)-1 do begin
      w = where( param_file_list_tot eq b[ifile], nw)
      restore, param_file_list_tot[w[0]]
      scan_list = scan_list_tot[w]
      nk_average_scans, param, scan_list
   endfor
endelse


end
