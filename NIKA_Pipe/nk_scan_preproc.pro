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
;
pro nk_scan_preproc, param, info, data, kidpar, grid=grid, $
                     sn_min=sn_min, sn_max=sn_max, $
                     simpar=simpar, parity=parity,$
                     prism=prism, force_file=force_file, $
                     xml = xml, noerror = noerror, nas_center=nas_center, $
                     list_detector=list_detector, polar=polar, katana=katana, $
                     preproc_copy=preproc_copy, badkid=badkid, nosubtract_hwp=nosubtract_hwp, $
                     astr=astr, header=header
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_scan_preproc'
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
      restore, preproc_data_file, /v
      info   = info_preproc
      kidpar = kidpar_preproc

;;       nk_default_param, param
;;       my_match, tag_names(param_preproc), tag_names(param), suba, subb
;;       for i=0, n_elements(suba)-1 do $
;;          param.(subb[i]) = param_preproc.(suba[i])
;;       param_preproc = param
;;       stop
      
      if tag_exist(info,'CURRENT_SUBSCAN_NUM') eq 0 then begin
         nk_default_info, info_temp
         temp_tags = tag_names(info_temp)
         for i=0, n_elements(temp_tags)-1 do begin
            w = where( tag_names(info) eq temp_tags[i], nw)
            if nw ne 0 then info_temp.(i) = info.(w)
         endfor
         info = info_temp
      endif
      
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
         (param_preproc.fpc_el ne param.fpc_el) or $
         (param.alpha_radec_deg ne 0.) then begin
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

;; for tests
if param.restrict_to_3_subscans then data = data[where( data.subscan ge 3 and data.subscan le 6)]
if param.log then nk_log, info, "----------- Entering nk_scan_preproc"
;; stop, 'Before getting data'
;;===========================================================================
if process eq 1 then begin
;; @ {\tt nk_getdata} reads the raw data and kid parameters, performs low level processing
   nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max,$
               prism=prism, force_file = force_file, $
               xml = xml, noerror = noerror, param_c=param_c, $
               list_detector=list_detector, katana=katana, polar=polar, $
               badkid=badkid, xoff=xoff
   
;; stop, 'Got data'
   if info.status eq 1 then return ; could not read the data

;   save, file='data.save'
   if param.undersamp_preproc ne 0 then begin
      w1 = where( kidpar.type eq 1, nw1)
      info.polar = 0
      for i=0, nw1-1 do begin
         ikid = w1[i]
         b = my_baseline( data.toi[ikid], base=0.01)
         y = data.toi[ikid]-b
         np_bandpass, y, !nika.f_sampling, s_out, freqhigh=2.8, delta_f=0.1, $
                      filter=filter, freq_vector=freq_vector
         s_out += b
         
         ;; power_spec, data.toi[ikid]-my_baseline(data.toi[ikid],bas=0.01), !nika.f_sampling, pw, freq
         ;; power_spec, s_out-my_baseline(s_out,base=0.01), !nika.f_sampling, pw_out
         ;; wind, 1, 1, /f, /large
         ;; my_multiplot, 2, 2, pp, pp1, /rev
         ;; plot, data.toi[ikid], /xs, position=pp[0,0,*]
         ;; plot, s_out, /xs, position=pp[0,1,*], /noerase
         ;; oplot, s_out, col=250
         ;; plot_oo, freq, pw, /xs, position=pp[1,0,*], /noerase
         ;; oplot, freq, pw_out, col=250
         ;; stop

         data.toi[ikid] = smooth( s_out, param.undersamp_preproc)
      endfor
      nsn = n_elements(data)
      index = lindgen(nsn/param.undersamp_preproc) * param.undersamp_preproc
      data = data[index]
      xoff = xoff[*,index]
   endif
   
;; @ Compute individual kid pointing once for all
;; Needed here for simulations
   nk_get_kid_pointing_2, param, info, data, kidpar

;; At this stage, if the scan is polarized, toi_q and toi_u exist but
;; are all zero. There's no need to deglitch them and waste a
;; significant amount of time => force a temporary info to polar=0
   info1 = info
   info1.polar = 0

   if param.deal_with_glitches_and_jumps eq 1 then nk_deal_with_glitches_and_jumps, param, info, data, kidpar

;;   ;; @ {\tt nk_deglitch} suppresses and interpolates cosmic rays
;;   if param.fast_deglitch eq 1 then begin
;;      nk_deglitch_fast, param, info1, data, kidpar
;;   endif else begin
;;      ;; if k_find_jumps == 1, raw data have already been deglitched,
;;      ;; no need to redo it here.
;;      if param.k_find_jumps eq 0 then nk_deglitch, param, info1, data, kidpar
;;   endelse

   if param.no_deglitch eq 0 then begin
      ;; @ {\tt nk_deglitch} suppresses and interpolates cosmic rays
      if param.fast_deglitch eq 1 then begin
         nk_deglitch_fast, param, info1, data, kidpar
      endif else begin
         ;; if k_find_jumps == 1, raw data have already been deglitched,
         ;; no need to redo it here.
         if param.k_find_jumps eq 0 then nk_deglitch, param, info1, data, kidpar
      endelse
   endif
   
;;   if param.jump_remove eq 1 then nk_remove_jumps, param, info, data, kidpar

;; ---------------------------------------------------------------------------
;; Moved here NP. Oct 1st, 2020
;; Then up here thanks to Laurence, Nov. 10th, 2020

;; Calibrate
;; @ {\tt nk_calibration_2} derives opacity correction and applies
;; @^ point source absolute calibration to the timelines. They will
;; @^ therefore be in Jy for the rest of the processing.
   if param.bypass_calib eq 0 then nk_calibration_2, param, info, data, kidpar, simpar=simpar 
;;-----------------------------------------------------------------------------

;;--------------------------
;; log scan angle
   w1 = where( kidpar.type eq 1, nw1)
;;   ikid = w1[0]
;; That is not always working as sometimes this kid is flagged
;;   ikid = where( kidpar.numdet eq !nika.ref_det[0])
                                ; Take the closest valid kid FXD Jan 2021
   aux = min((kidpar[ w1].numdet - !nika.ref_det[0])^2,imin)
   ikid = w1[ imin]
   middle_subscan = round( (min(data.subscan)+max(data.subscan))/2.)
   w = where( data.flag[ikid] eq 0 and data.subscan eq middle_subscan)
   fit = linfit( data[w].dra[ikid], data[w].ddec[ikid])
   scan_angle = atan( fit[1])*!radeg

   nsn = n_elements(data)
   nsubscans = data[nsn-1].subscan - data[0].subscan + 1
   
   ;; Determine a center of rotation that is close enough from0 to
   ;; avoid problems of translations
   xc = avg(data.dra[ikid])
   yc = avg(data.ddec[ikid])
;;    wind, 1, 1, /free, /large
;;    my_multiplot, 2, 1, pp, pp1, /rev
;;    plot, data.dra[ikid]-xc, data.ddec[ikid]-yc, /iso, position=pp1[0,*], /noerase
;;    w = where( data.flag[ikid] eq 0, nw)
;;    if nw ne 0 then oplot, data[w].dra[ikid]-xc, data[w].ddec[ikid]-yc, psym=3, col=250
;;    legendastro, 'scan angle '+strtrim(scan_angle,2)
;;    
;;    x = (data.dra[ikid]-xc)*cos(scan_angle*!dtor) + (data.ddec[ikid]-yc)*sin(scan_angle*!dtor)
;;    y = (data.dra[ikid]-xc)*sin(scan_angle*!dtor) - (data.ddec[ikid]-yc)*cos(scan_angle*!dtor)
;;    plot, x, y, /xs, /ys, position=pp1[1,*], /noerase
;;    if nw ne 0 then oplot, x[w], y[w], psym=1, col=250, syms=0.5
;; ;;;;;;;;;;   if nsubscans gt 1 then info.SUBSCAN_STEP = (max(y)-min(y))/(nsubscans-1)

   ang_res = [-1.d0]
   ll_res  = [-1.d0]
   ll_res1 = [-1.d0]
   yavg = [-1.0]
   for isub=(min(data.subscan)>2), max(data.subscan)-1 do begin
      w = where( data.subscan eq isub and data.flag[ikid] eq 0, nw)
;      fit = linfit( data[w].dra[ikid]-xc, data[w].ddec[ikid]-yc)
;      subscan_angle = atan( fit[1])*!radeg
      subscan_angle = scan_angle
      ;; prevent round off and sign errors with the atan
;;      if abs( subscan_angle) gt 89.5 then subscan_angle = 90.
      ang_res = [ang_res, subscan_angle]
      x = (data[w].dra[ikid]-xc)*cos(atan(fit[1])) + (data[w].ddec[ikid]-yc)*sin(atan(fit[1]))
      y = (data[w].dra[ikid]-xc)*sin(atan(fit[1])) - (data[w].ddec[ikid]-yc)*cos(atan(fit[1]))
      ll_res = [ll_res, max(x)-min(x)]
      ll_res1 = [ll_res1, sqrt( (data[w[0]].dra[ikid]-data[w[nw-1]].dra[ikid])^2 + (data[w[0]].ddec[ikid]-data[w[nw-1]].ddec[ikid])^2)]
;      oplot, x, y, psym=8, col=70, syms=0.5
      yavg = [yavg, avg(y)]
   endfor

   ang_res = ang_res[1:*]
   ll_res  = ll_res[ 1:*]
   ll_res1 = ll_res1[1:*]
   yavg    = yavg[   1:*]
   if nsubscans gt 1 then info.SUBSCAN_STEP = abs( median( yavg-shift(yavg,1)))
   info.scan_angle     = median(ang_res) ; scan_angle
   info.SUBSCAN_ARCSEC = median(ll_res)
;;stop, 'nk_scan_preproc subscan_step debug'
   ;; wind, 1, 1, /free, /large
   ;; my_multiplot, 1, 2, pp, pp1, /rev
   ;; plot, ang_res, position=pp1[0,*], /noerase, title='Ang per subscan', psym=-8, /ys, /xs
   ;; plot, ll_res, position=pp1[1,*], /noerase, title='Subscan length', /xs, /ys
   ;; oplot, ll_res, col=70
   ;; oplot, ll_res1, col=150
   ;; legendastro, ['max(x)-min(x)', 'Pythagore[wsubscan]'], textcol=[70,150]
   ;; print, median(ll_res), median(ll_res1), median(ang_res)

;;--------------------------
;; stop,'Just before preproc_copy'
   ;; @ If {\tt param.preproc_copy}==1, save data, kidpar etc... on
   ;; @^ disk to bypass this low level processing if this scan is reprocessed
   if keyword_set(preproc_copy) then begin

      ;; get rid of useless fields to save disk space and reading time
      ;; for future use
      data_tags = tag_names(data)
      param_preproc      = param
      kidpar_preproc     = kidpar
      info_preproc       = info
      
      if param.restrict_data_to_valid_kids eq 1 then begin
         common_tag_list = ['SAMPLE', 'SUBSCAN', 'EL', 'AZ', 'SCAN_ST', $
                            'PARAL', 'OFS_AZ', 'OFS_EL', 'POSITION', $
                            'ELEV_OFFSET', 'NSOTTO', 'SYNCHRO', $
                            'COSPOLAR', 'SINPOLAR', 'SCAN_VALID']
         
         kid_tag_list = ['TOI',  'DRA', 'DDEC', 'F_TONE', 'DF_TONE', $
                         'W8', 'FLAG', 'OFF_SOURCE', 'IPIX', $
                         'TOI_Q', 'TOI_U', 'W8_Q', 'W8_U']
         
         ;; Init data copy command
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
         ;; for i=0, ntags-2 do strexc += kid_tag_list[i]+":data[0]."+kid_tag_list[i]+"[w1], "
         ;; strexc += kid_tag_list[ntags-1]+":data[0]."+kid_tag_list[ntags-1]+"[w1]}"
         
         ;; Adding xoff, FXD&NP, Apr. 20th, 2021
         ;; Init like any other TOI
         for i=0, ntags-1 do strexc += kid_tag_list[i]+":data[0]."+kid_tag_list[i]+"[w1], "
         strexc += "xoff:data[0].toi[w1]}"

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
         if defined(xoff) then begin
            ;; pass xoff. It is already shifted by -1 to be centered
            ;; on 0
            data1.xoff = xoff[w1,*]
         endif
         
         kidpar = kidpar[w1]
         kidpar_preproc = kidpar
         
      endif else begin
         tag_list = ['SAMPLE', 'SUBSCAN', 'EL', 'AZ', $
                     'PARAL', 'OFS_AZ', 'OFS_EL', 'POSITION', 'SCAN_VALID', $
                     'TOI', 'ELEV_OFFSET', 'DRA', 'DDEC', 'F_TONE', 'DF_TONE', $
                     'W8', 'FLAG', 'OFF_SOURCE', 'IPIX', 'NSOTTO', 'SYNCHRO', $
                     'COSPOLAR', 'SINPOLAR', 'TOI_Q', 'TOI_U', 'W8_Q', 'W8_U', 'SCAN_ST']
         
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
   endif                        ; preproc_copy
   
endif                            ; process = 1
;;=======================================================================================

;; Check how each kid behaves compared to the median mode
;; nk_ks_test, param, info, data, kidpar
if param.do_kid2median_test then nk_kid2median_test, param, info, data, kidpar

;; if param.method_num eq 80 then nk_kid2median_test, param, info, data, kidpar

;; ;;----------------------- Moved up in the preproc section, NP. Oct
;; ;;                        1st, 2020 ---------------------
;; ;; Calibrate
;; ;; @ {\tt nk_calibration_2} derives opacity correction and applies
;; ;; @^ point source absolute calibration to the timelines. They will
;; ;; @^ therefore be in Jy for the rest of the processing.
;; if param.bypass_calib eq 0 then nk_calibration_2, param, info, data, kidpar, simpar=simpar
;; ;;------------------------------------------------------------------
;; stop, 'nk_Scan_preproc after preproc_copy'

;; In some simulations, we want to alternately add/subtract the data
;; from one scan. This is done via "parity"
if keyword_set(parity) then data.toi = data.toi*parity
if defined(parity) then message, /info, "parity = "+strtrim(parity,2)

if keyword_set(header) then begin
   extast, header, astr
   nk_astr2param, astr, param
endif else begin
   nk_param_info2astr, param, info, astr
endelse

;; @ Init the output map structure "grid"
;; LP+FK modif Feb. 5, 2020
if keyword_set(grid) then begin
   message, /info, 'THE GRID ALREADY EXISTS => I keep it and not run nk_init_grid_2, .., astr=astr'
;;   nk_init_grid_2, param, info, grid_mock, header=header
endif else begin
   nk_init_grid_2, param, info, grid, astr=astr
endelse

;; @ Compute data.ipix to save time
nk_get_ipix, param, info, data, kidpar, grid, astr=astr

w1 = where( kidpar.type eq 1, nw1)
nn = n_elements( data.ipix[w1])
winf = where( finite( data.ipix[w1]) ne 1, nwinf)
if nwinf eq nn then begin
   txt = "All ipix values are infinite"
   nk_error, info, txt
   return
endif
wpos = where( data.ipix[w1] ge 0, nwpos)
nn   = n_elements( data.ipix[w1])

if nwinf eq nn or nwpos eq 0 then begin
   nk_error, info, 'All ipix values are -1 or infinite'
   return
endif

if param.cpu_time then nk_show_cpu_time, param

end
