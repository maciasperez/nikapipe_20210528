;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_scan_preproc
;
; CATEGORY:
; low level TOI processing
;
; CALLING SEQUENCE:
;         nk_scan_preproc, param, info, data, kidpar, grid, $
;                     sn_min=sn_min, sn_max=sn_max, $
;                     simpar=simpar, parity=parity,$
;                     prism=prism, force_file=force_file, $
;                     xml = xml, noerror = noerror, nas_center=nas_center, $
;                     list_detector=list_detector, polar=polar, katana=katana, $
;                     preproc_copy=preproc_copy, badkid=badkid, nosubtract_hwp=nosubtract_hwp
; 
; PURPOSE: 
;        low level processing of the data. Everything that goes after the raw
;data extraction in nk_getdata and that is not decorrelation or projection dependent.
; 
; INPUT: 
;        - param, info, data, kidpar, grid
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
;        - NP
;-

pro nk_scan_preproc, param, info, data, kidpar, grid=grid, $
                     sn_min=sn_min, sn_max=sn_max, $
                     simpar=simpar, parity=parity,$
                     prism=prism, force_file=force_file, $
                     xml = xml, noerror = noerror, nas_center=nas_center, $
                     list_detector=list_detector, polar=polar, katana=katana, $
                     preproc_copy=preproc_copy, badkid=badkid, nosubtract_hwp=nosubtract_hwp, $
                     astr=astr, header=header

if n_params() lt 1 then begin
;; --------- GDL modifications
   ;; message, info, "Calling sequence:"
   message, /info, "Calling sequence: "
   print, "nk_scan_preproc, param, info, data, kidpar, grid=grid, $"
   print, "                 sn_min=sn_min, sn_max=sn_max, $"
   print, "                 simpar=simpar, parity=parity,$"
   print, "                 prism=prism, force_file=force_file, $"
   print, "                 xml = xml, noerror = noerror, nas_center=nas_center, $"
   print, "                 list_detector=list_detector, polar=polar, katana=katana, $"
   print, "                 preproc_copy=preproc_copy, badkid=badkid, nosubtract_hwp=nosubtract_hwp, $"
   print, "                 astr=astr, header=header"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; default
process = 1

if keyword_set(preproc_copy) then begin
   preproc_data_file = param.preproc_dir+"/data_"+strtrim(param.scan,2)+".save"
   if file_test(preproc_data_file) then begin
      process = 0
      message, /info, "param.preproc_copy = 1 => restoring "+preproc_data_file+"..."
      restore, preproc_data_file
      info   = info_preproc
      kidpar = kidpar_preproc

      if param.one_mm_only eq 1 then begin
         w = where( kidpar.array eq 2, nw)
         if nw ne 0 then kidpar[w].type = 3
      endif
      if param.two_mm_only eq 1 then begin
         w = where( kidpar.array ne 2, nw)
         if nw ne 0 then kidpar[w].type = 3
      endif

      ;; If I call nk with /preproc_copy and the file was e.g. at
      ;; 47Hz, !nika.f_sampling is badly initialized in
      ;; nika_init_struct... make sure I have no problem here:
      !nika.f_sampling = info.f_sampling
      
      ;; param  = param_preproc
      ;; I keep the input param structure because some options may be
      ;; changed (in particular the filtering parameters...)
      ;; If new parameters such as deglitching options must be tested,
      ;; the preprocessing must be redone.

      ;; Check if we need to recompute the pointing: this happens if
      ;; the file was preprocessed e.g. in radec and is now projected
      ;; in RaDec
      if (strupcase(param_preproc.map_proj) ne strupcase(param.map_proj)) or $
         (param_preproc.fpc_az ne param.fpc_az) or $
         (param_preproc.fpc_el ne param.fpc_el) then begin
         message, /info, "Recomputing the pointing:"
         message, /info, "param_preproc.map_proj = "+param_preproc.map_proj
         message, /info, "param.map_proj = "+param.map_proj
         nk_get_kid_pointing_2, param, info, data, kidpar
         ;; stop
      endif
      
      ;; Make sure the error file is updated correctly and not kept as
      ;; it was during the first pre-processing call
      info.error_report_file = param.project_dir+"/error_report_"+param.scan+".dat"
   endif
endif

;;===========================================================================
if process eq 1 then begin
;; @ {\tt nk_getdata} reads the raw data and kid parameters, performs low level processing
   nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max,$
               prism=prism, force_file = force_file, $
               xml = xml, noerror = noerror, param_c=param_c, $
               list_detector=list_detector, katana=katana, polar=polar, $
               badkid=badkid

   if info.status eq 1 then return ; could not read the data

   if param.decimate ne 0 then begin
      index = lindgen(n_elements(data))
      w = where( index mod param.decimate eq 0)
      data = data[w]
   endif

;; @ Compute individual kid pointing once for all
;; Needed here for simulations
   nk_get_kid_pointing_2, param, info, data, kidpar

;; At this stage, if the scan is polarized, toi_q and toi_u exist but
;; are all zero. There's no need to deglitch them and waste a
;; significant amount of time => force a temporary info to polar=0
   info1 = info
   info1.polar = 0

   ;; @ {\tt nk_deglitch} suppresses and interpolates cosmic rays
   if param.fast_deglitch eq 1 then begin
      nk_deglitch_fast, param, info1, data, kidpar
   endif else begin
      nk_deglitch, param, info1, data, kidpar
   endelse
   
   if param.jump_remove eq 1 then nk_remove_jumps, param, info, data, kidpar

   ;; @ If {\tt param.preproc_copy}==1, save data, kidpar etc... on
   ;; @^ disk to bypass this low level processing if this scan is reprocessed
   if keyword_set(preproc_copy) then begin
      param_preproc      = param
      kidpar_preproc     = kidpar
      info_preproc       = info
      
      ;; get rid of useless fields to save disk space and reading time
      ;; for future use
      data_tags = tag_names(data)

      if param.restrict_data_to_valid_kids eq 1 then begin
         common_tag_list = ['SAMPLE', 'SUBSCAN', 'EL', 'AZ', $
                            'PARAL', 'OFS_AZ', 'OFS_EL', 'POSITION', $
                            'ELEV_OFFSET', 'NSOTTO', 'SYNCHRO', $
                            'COSPOLAR', 'SINPOLAR', 'SCAN_VALID']
         
         kid_tag_list = ['TOI',  'DRA', 'DDEC', 'F_TONE', 'DF_TONE', $
                         'W8', 'FLAG', 'OFF_SOURCE', 'IPIX', $
                         'TOI_Q', 'TOI_U', 'W8_Q', 'W8_U']
      
         ;; Inint data copy command
         strexc = "data1 = {"
         
         ;; copy all common tags first
         my_match, data_tags, common_tag_list, suba, subb
         common_tag_list = common_tag_list[subb]
         ntags = n_elements(common_tag_list)
         for itag=0, ntags-1 do strexc += common_tag_list[itag]+":data[0]."+common_tag_list[itag]+", "
         
         ;; allocate kid tags with only valid pixels to save disk
         ;; space and I/O time
         w1 = where(kidpar.type eq 1, nw1)
         my_match, data_tags, kid_tag_list, suba, subb
         kid_tag_list = kid_tag_list[subb]
         ntags = n_elements(kid_tag_list)
         for i=0, ntags-2 do strexc += kid_tag_list[i]+":data[0]."+kid_tag_list[i]+"[w1], "
         strexc += kid_tag_list[ntags-1]+":data[0]."+kid_tag_list[ntags-1]+"[w1]}"
         
         junk = execute(strexc)
         nsn = n_elements(data)
         data1 = replicate(data1, nsn)
         
         for itag=0, n_elements(common_tag_list)-1 do begin
            cmd = "data1."+common_tag_list[itag]+" = data."+common_tag_list[itag]
            junk = execute(cmd)
         endfor
         for itag=0, n_elements(kid_tag_list)-1 do begin
            cmd = "data1."+kid_tag_list[itag]+" = data."+kid_tag_list[itag]+"[w1]"
            junk = execute(cmd)
         endfor
         
         kidpar = kidpar[w1]
         kidpar_preproc = kidpar
         
      endif else begin
         tag_list = ['SAMPLE', 'SUBSCAN', 'EL', 'AZ', $
                     'PARAL', 'OFS_AZ', 'OFS_EL', 'POSITION', 'SCAN_VALID', $
                     'TOI', 'ELEV_OFFSET', 'DRA', 'DDEC', 'F_TONE', 'DF_TONE', $
                     'W8', 'FLAG', 'OFF_SOURCE', 'IPIX', 'NSOTTO', 'SYNCHRO', $
                     'COSPOLAR', 'SINPOLAR', 'TOI_Q', 'TOI_U', 'W8_Q', 'W8_U']
         
         ;; Keep only existing tags in data
         my_match, data_tags, tag_list, suba, subb
         tag_list = tag_list[subb]
         ntags = n_elements(tag_list)
         strexc = "data1 = {"
         for itag=0, ntags-2 do strexc += tag_list[itag]+":data[0]."+tag_list[itag]+", "
         strexc += tag_list[ntags-1]+":data[0]."+tag_list[ntags-1]+"}"
         
         junk = execute(strexc)
         nsn = n_elements(data)
         data1 = replicate(data1, nsn)
         for itag=0, ntags-1 do begin
            cmd = "data1."+tag_list[itag]+" = data."+tag_list[itag]
            junk = execute(cmd)
         endfor
      endelse
      data = temporary(data1)
      save, param_preproc, info_preproc, data, kidpar_preproc, $
            file=param.preproc_dir+"/data_"+strtrim(param.scan,2)+".save"
      message, /info, "saved "+param.preproc_dir+"/data_"+strtrim(param.scan,2)+".save"
   endif
endif                            ; process = 1
;;===========================================================================

;; Check how each kid behaves compared to the median mode
;; nk_ks_test, param, info, data, kidpar
;; if param.method_num eq 80 then nk_kid2median_test, param, info, data, kidpar

;; Calibrate
;; @ {\tt nk_calibration_2} derives opacity correction and applies
;; @^ point source absolute calibration to the timelines. They will
;; @^ therefore be in Jy for the rest of the processing.
if param.bypass_calib eq 0 then nk_calibration_2, param, info, data, kidpar, simpar=simpar
   
;; In some simulations, we want to alternately add/subtract the data
;; from one scan. This is done via "parity"
if keyword_set(parity) then data.toi = data.toi*parity

if keyword_set(header) then begin
   extast, header, astr
endif else begin
   nk_param_info2astr, param, info, astr
endelse

;; @ Init the output map structure "grid"
nk_init_grid_2, param, info, grid, header=header

;; @ Compute data.ipix to save time
nk_get_ipix, param, info, data, kidpar, grid, astr=astr

if param.cpu_time then nk_show_cpu_time, param

end
