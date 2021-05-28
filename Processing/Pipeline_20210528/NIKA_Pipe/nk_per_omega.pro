;+
; SOFTWARE: NIKA pipeline
;
; NAME:
;       nk_per_omega
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;    nk, scan_list_in, param=param, info=info, $
;        filing=filing, data=data, kidpar=kidpar, $
;        print_status=print_status, grid=grid, $
;        simpar=simpar, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
;        subtract_maps=subtract_maps, no_output_map=no_output_map, prism=prism, $
;        parity=parity, force_file=force_file, xml = xml, $
;        kill_subscan = kill_subscan, show_maps_only=show_maps_only, results_filing=results_filing, $
;        lab=lab, input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel, nas_center=nas_center, $
;        list_detector=list_detector, xguess=xguess, yguess=yguess, polar=polar, $
;        raw_acq_dir=raw_acq_dir, header=header, astr=astr
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software. It launches the reduction of each scan of scan_list
;        and averages the output maps into the final one using inverse
;        variance noise weighting.
; 
; INPUT: 
;        - scan_list : e.g. ['20140221s0024', '20140221s0025', '20140221s0026']
;        - param: the pipeline parameters
;        - info: must be passed in input to allow for mask_source
; 
; OUTPUT: 
;        - info
; 
; KEYWORDS:
;        - filing: if set, we run the pipeline in a mode where it processes only
;          files for which a companion with prefix UP_ exists.
;        - polar: set to make the intensity I and polarization Q,U maps
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 17/06/2014: creation (Nicolas Ponthieu, Remi Adam, Alessia Ritacco). The NIKA offline reduction (mainly
;        nika_pipe_launch.pro and nika_anapipe_launch.pro) are put
;        together in this software
;-

pro nk_per_omega, scan_list_in, param=param, info=info, $
                  filing=filing, data=data, kidpar=kidpar, $
                  print_status=print_status, grid=grid, $
                  simpar=simpar, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
                  subtract_maps=subtract_maps, no_output_map=no_output_map, prism=prism, $
                  parity=parity, force_file=force_file, xml = xml, $
                  kill_subscan = kill_subscan, show_maps_only=show_maps_only, results_filing=results_filing, $
                  lab=lab, input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel, nas_center=nas_center, $
                  list_detector=list_detector, xguess=xguess, yguess=yguess, polar=polar, $
                  raw_acq_dir=raw_acq_dir, header=header, astr=astr

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk, scan_list_in, param=param, info=info, $"
   print, "        filing=filing, data=data, kidpar=kidpar, $"
   print, "        print_status=print_status, grid=grid, $"
   print, "        simpar=simpar, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $"
   print, "        subtract_maps=subtract_maps, no_output_map=no_output_map, prism=prism, $"
   print, "        parity=parity, force_file=force_file, xml = xml, $"
   print, "        kill_subscan = kill_subscan, show_maps_only=show_maps_only, results_filing=results_filing, $"
   print, "        lab=lab, input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel, nas_center=nas_center, $"
   print, "        list_detector=list_detector, xguess=xguess, yguess=yguess, polar=polar, $"
   print, "        raw_acq_dir=raw_acq_dir, header=header, astr=astr"
   return
endif

xml=0                           ; FXD  to be fixed
if not keyword_set(sn_min_list) then sn_min_list = lonarr( n_elements(scan_list_in))
if not keyword_set(sn_max_list) then sn_max_list = lonarr( n_elements(scan_list_in))

if n_elements(sn_min_list) ne n_elements(sn_max_list) then begin
   message, /info, "sn_min_list and sn_max_list must have the same size."
   return
endif
if n_elements(sn_min_list) ne n_elements(scan_list_in) then begin
   message, /info, "sn_min_list must have the same size as scan_list_in."
   return
endif

;; Check if the scans are fine and returns the good scans
if not keyword_set(force_file) then begin
   scan_list = scan_list_in
   nscans = n_elements(scan_list)
   ok_scans = indgen(nscans)
   if nscans eq 0 then begin
      nk_error, info, "No valid scans were selected"
      return
   endif
   sn_min_list = sn_min_list[ok_scans]
   sn_max_list = sn_max_list[ok_scans]
endif else begin
   nscans = 1
   scan_list = scan_list_in
endelse

;; @ nk_default_param, nk_default_info and nk_init_grid create
;; @^ param, info and grid if they have not been passed in input
if not keyword_set(param) then nk_default_param,   param
if not keyword_set(info)  then nk_default_info, info
;;if not keyword_set(grid)  then nk_init_grid, param, info, grid, header=header

nk_check_param, param, info

if keyword_set(polar) then param.polar = 1
if strupcase(param.map_proj) eq "NASMYTH" then !mamdlib.coltable = 3
if keyword_set(lab) then param.lab = 1
if param.latex_pdf eq 1 then param.plot_ps = 1
if param.plot_png and param.plot_ps then param.plot_png = 0
if strlen( param.plot_dir) eq 0 then param.plot_dir = param.project_dir+"/Plots"


;; @ Creates the necessary directories for output products and plots
spawn, "mkdir -p "+param.project_dir
spawn, "mkdir -p "+param.project_dir+"/UP_files"
spawn, "mkdir -p "+param.project_dir+"/Plots"
spawn, "mkdir -p "+param.plot_dir
spawn, "mkdir -p "+param.preproc_dir

;; Sanity checks
if keyword_set(lkg_kernel) then begin
   lkg_reso = abs(lkg_kernel.xmap[1,0]-lkg_kernel.xmap[0,0])
   if lkg_reso ne param.map_reso then begin
      nk_error, info, "lkg maps resolution must be the same as param.map_reso"
      return
   endif
endif

;;---------------------------------------------------------------------------------
;; Main loop
random_string = strtrim( long( abs( randomu( seed, 1)*1e8)),2)
error_report_file = param.project_dir+"/error_report_"+random_string+".dat"

for iscan=0, nscans-1 do begin

   ;; Moved nk_check_filing up here for convenience, NP, Dec. 21st, 2015.
   ;; @ nk_check_filing checks if the file has already been processed or not.
   process_file = 1
   if keyword_set(filing) then nk_check_filing, param, scan_list[iscan], process_file

   info.status = 0

   if process_file ne 0 then begin

      param.iscan = iscan
      info.error_report_file = error_report_file
      
      ;; @ nk_update_param_info retrieves scan information such as map_center_ra and dec from the
      ;; @^ first scan of the list, even if the current scan will not be
      ;; @^ processed.
      nk_update_param_info, scan_list[iscan], param, info, xml=xml, katana=katana, raw_acq_dir=raw_acq_dir
      param.cpu_date0             = systime(0, /sec)
      param.cpu_time_summary_file = param.output_dir+"/cpu_time_summary_file.dat"
      param.cpu_date_file         = param.output_dir+"/cpu_date.dat"
      spawn, "rm -f "+param.cpu_time_summary_file
      spawn, "rm -f "+param.cpu_date_file      
      info.error_report_file = error_report_file
      if keyword_set(show_maps_only) then param.do_plot=0

      ;; @ nk_scan_preproc performs all operations on data that are not projection nor cleaning
      ;; @^ dependent (and a few other ones actually for parallel data reading)
      nk_scan_preproc, param, info, data, kidpar, grid=grid, $
                       preproc_copy=param.preproc_copy, $
                       sn_min=sn_min_list[iscan], sn_max=sn_max_list[iscan], $
                       simpar=simpar, parity=parity, $
                       prism=prism, force_file=force_file, xml=xml, nas_center=nas_center, $
                       list_detector=list_detector, polar=param.polar, katana=katana, badkid=badkid, $
                       astr=astr, header=header

      if info.status eq 1 then goto, ciao

      if param.kid_monitor eq 1 then $
         kid_monitor, param.scan, data=data, kidpar=kidpar, $
                      output_kidpar_dir=!nika.plot_dir+"/KidMonitor", $
                      badkid=badkid

      ;; Ignore polarization and build one map per fixed position of
      ;; the HWP
      array = data.position
      omega = array[UNIQ(array, SORT(array))]
      nomega = n_elements(omega)
      for iomega=0, nomega-1 do begin
         w = where( data.position eq omega[iomega], nw)
         data1 = data[w]

         nk_scan_reduce, param, info, data1, kidpar, grid, $
                         subtract_maps=subtract_maps, input_polar_maps=input_polar_maps, $
                         lkg_kernel=lkg_kernel, simpar=simpar

         ;; Global map
         nk_projection_4, param, info, data1, kidpar, grid
         file = !nika.plot_dir+"/grid_omega_"+scan_list[iscan]+"_"+strtrim(iomega,2)+".save"
         save, param, info, kidpar, grid, file=file
         message, /info, "saved "+file
         
         ;; map per kid
         wk = where( kidpar.numdet eq 824)
         w8_junk=0
         get_bolo_maps_6, data1.toi, data1.ipix[wk], w8_junk, kidpar, grid, map_list, nhits
         file = !nika.plot_dir+"/kid_map_list_"+scan_list[iscan]+"_"+strtrim(iomega,2)+".save"
         save, map_list, file=file
         message, /info, "saved "+file
         
      endfor
      
      if param.delete_all_windows_at_end ne 0 then begin
         wait, 0.3
         wd, /all
      endif
      close, /all               ; remove a nagging bug if a session of rta is too long: message iswas "all units are used" 
   endif
   
   ciao:
endfor


end
