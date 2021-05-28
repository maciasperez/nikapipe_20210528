;+
; SOFTWARE: NIKA pipeline
;
; NAME:
;       nk_parallel
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;         nk, scan_list, param, info
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
;        - 
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
;        - 02/09/2015: creation (J.F. Macias-Perez) based on nk.pro. 
;                      parallel wrapper for nk.pro 
;-

pro nk_parallel,scan_list, param=param, info=info, grid=grid,xml=xml,nproc=nproc,simpar=simpar ;, $
        ;; filing=filing, data=data, kidpar=kidpar, $
        ;; print_status=print_status, preproc=preproc, grid=grid, $
        ;; simpar=simpar, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
        ;; subtract_maps=subtract_maps, no_output_map=no_output_map, prism=prism, $
        ;; parity=parity, force_file=force_file, xml = xml, $
        ;; kill_subscan = kill_subscan, show_maps_only=show_maps_only, results_filing=results_filing, $
        ;; lab=lab, input_polar_maps=input_polar_maps, lkg_kernel=lkg_kernel

;;   if not keyword_set(sn_min_list) then sn_min_list = lonarr( n_elements(scan_list_in))
;;   if not keyword_set(sn_max_list) then sn_max_list = lonarr( n_elements(scan_list_in))

;;   if n_elements(sn_min_list) ne n_elements(sn_max_list) then begin
;;      message, /info, "sn_min_list and sn_max_list must have the same size."
;;      return
;;   endif
;;   if n_elements(sn_min_list) ne n_elements(scan_list_in) then begin
;;      message, /info, "sn_min_list must have the same size as scan_list_in."
;;      return
;;   endif

;; ;; Check if the scans are fine and returns the good scans
;;   if not keyword_set(force_file) then begin
;;      scan_list = scan_list_in

;;      nscans = n_elements(scan_list)
;;      ok_scans = indgen(nscans)
;;      if nscans eq 0 then begin
;;         nk_error, info, "No valid scans were selected"
;;         return
;;      endif
;;      sn_min_list = sn_min_list[ok_scans]
;;      sn_max_list = sn_max_list[ok_scans]
;;   endif else begin
;;      nscans = 1
;;      scan_list = scan_list_in
;;   endelse
  
  if not keyword_set(param) then nk_default_param,   param
  if not keyword_set(grid)  then nk_init_grid, param, info, grid
  if keyword_set(lab) then param.lab = 1

  if param.plot_png and param.plot_ps then param.plot_png = 0

  if strlen( param.plot_dir)    eq 0 then param.plot_dir    = param.project_dir+"/Plots"
  spawn, "mkdir -p "+param.project_dir
  spawn, "mkdir -p "+param.plot_dir
  init_grid_done = 0            ; init

;; Sanity checks
  if param.do_checks eq 0 then nk_check_param_grid, param, grid
  if keyword_set(lkg_kernel) then begin
     lkg_reso = abs(lkg_kernel.xmap[1,0]-lkg_kernel.xmap[0,0])
     if lkg_reso ne param.map_reso then begin
        nk_error, info, "lkg maps resolution must be the same as param.map_reso"
        return
     endif
  endif

  nscans = n_elements(scan_list)

  split_for,0, nscans-1, $
            commands=['nk, scan_list[i], param=param, info=info,grid=grid,xml=xml,simpar=simpar'], $
            varnames=['scan_list'], nsplit = nproc,struct2pass1=param, struct2pass2=info, struct2pass3=grid,struct2pass4=simpar
  


  return
end
