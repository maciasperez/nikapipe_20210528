;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; nk_rta_Test
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;         nk, scan_list, [DECOR=, HEADER=, NOPLOT=, $
;         NOLOGTERM=, MAP_PER_KID=, PROJECTION=, PARAM_USER=, $
;         RESET_MAP=, MAKE_TOI=, MAKE_UNIT_CONV=, $
;         FORCE=, RESO=, S_MAP=, SIMPAR=]
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software. It launches the reduction that computes maps
;        from raw data and treat them in order to produce output results
; 
; INPUT: 
;        The list of scans to be used as a string vector
;        e.g. ['20140221s0024', '20140221s0025', '20140221s0026']
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
;        - June 2nd, 2014: Nicolas Ponthieu
;-
;================================================================================================

pro nk_rta_test, scan, imbfits=imbfits, param = param, ref_det_1mm=ref_det_1mm, ref_det_2mm=ref_det_2mm, $
            diffuse=diffuse,  rf = rf, undersamp = undersamp, fast_fourier = fast_fourier, nasmyth = nasmyth, $
            median = median, sn_min = sn_min, sn_max = sn_max,  one_mm_only = one_mm_only,  two_mm_only = two_mm_only, $
            full_res = full_res, decimate = decimate, educated = educated, holes = holes, nopng=nopng, force=force
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_rta, scan, imbfits=imbifits, param = param, ref_det_1mm=ref_det_1mm, ref_det_2mm=ref_det_2mm, $"
   print, "            diffuse=diffuse,  rf = rf, undersamp = undersamp, fast_fourier = fast_fourier, nasmyth = nasmyth, $"
   print, "            median = median, sn_min = sn_min, sn_max = sn_max,  one_mm_only = one_mm_only,  two_mm_only = two_mm_only, $"
   print, "            full_res = full_res, decimate = decimate, educated = educated, holes = holes, nopng=nopng"
   return
endif

;; Erase all previous windows for convenience
;wd, /a
nopng = 1
;; Init params
if not keyword_set(param) then nk_default_param, param
nk_default_info, info

param.rta = 1
if keyword_set(rf) then param.math = "RF"
if keyword_set(undersamp) then param.undersamp = undersamp
if keyword_set(fast_fourier) then param.fast_fourier = 1
if keyword_set(median) then param.decor_method = "median_simple"
if keyword_set(holes) then param.treat_data_holes = 1
if keyword_set(nopng) then param.plot_png = 0

nk_update_scan_param, scan, param, info

xml = 1 ; default
if keyword_set(imbfits) then xml=0

;;-------------------------------------------------------------------------------------
;; Determine which type of scan and create the "pako_str" scan information structure
if xml ne 0 then begin
   parse_pako, param.scan_num, param.day, pako_str
endif else begin
   imbfits = 1
   nk_find_raw_data_file, param.scan_num, param.day, file, imb_fits_file
   nk_imbfits2pako_str, imb_fits_file, pako_str
endelse

;;-------------------------------------------------------------------------------------
;; Launch the appropriate routine
good_scan = 0
if strupcase( strtrim( pako_str.obs_type, 2)) eq "POINTING" or $
   ( (strupcase( strtrim( pako_str.obs_type, 2)) eq "LISSAJOUS") and (strupcase( strtrim(pako_str.purpose,2)) ne "FOCUS")) then begin
   good_scan = 1
   param.decor_method = "common_mode_band_mask"
   if keyword_set(median) then param.decor_method = "median_simple"
   nk_pointing, scan, pako_str, param=param, online=online, p2cor=p2cor, p7cor=p7cor, $
                nas_offset_x=nas_offset_x, nas_offset_y=nas_offset_y, $
                RF=RF, one_mm_only=one_mm_only, two_mm_only=two_mm_only, imbfits=imbfits, $
                ref_det_1mm=ref_det_1mm, ref_det_2mm=ref_det_2mm, force=force, nasmyth = nasmyth, xml = xml,  $
                sn_min = sn_min, sn_max = sn_max, educated = educated
endif

if (strupcase( strtrim( pako_str.obs_type, 2)) eq "LISSAJOUS" and strupcase( strtrim(pako_str.purpose,2) eq "FOCUS")) then begin
   good_scan = 1
   param.decor_method = "common_mode" ; in case we're very out of focus, the region to mask would be very large
   if keyword_set(median) then param.decor_method = "median_simple"
   nk_focus_liss_new, scan, pako_str, param=param, RF=RF, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
                      educated = educated
endif

if strupcase( strtrim( pako_str.obs_type, 2)) eq "FOCUS" then begin
   good_scan = 1
   nk_focus, scan, pako_str, focus_1mm, focus_2mm, err_focus_1mm, err_focus_2mm, $
             param=param, info=info, $
             ref_det_1mm=ref_det_1mm, ref_det_2mm=ref_det_2mm, $
             RF=RF, force=force, imbfits=imbfits, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
             max6=max6, check=check, radius_far_kids=radius_far_kids, holes = holes
endif

if strupcase( strtrim( pako_str.obs_type, 2)) eq "ONTHEFLYMAP" then begin
   good_scan = 1

   ;; Create mask_source
   nk_init_grid, param, grid
   if not keyword_set(diffuse) then begin
      param.decor_method = "common_mode_band_mask"
      dist = sqrt( grid.xmap^2 + grid.ymap^2)
      w = where( dist lt param.decor_cm_dmin, nw)
      if nw eq 0 then begin
         message, /info, "Mask unvalid"
         return
      endif
      grid.mask_source[w] = 0
   endif

   param.do_plot  = 1
   param.plot_png = 1
   param.plot_ps  = 0
   param.plot_dir = !nika.plot_dir+"/"+param.scan
   spawn, "mkdir -p "+param.plot_dir

;;   decimate = 0
;;   if not keyword_set(decimate) then decimate = 2
   if keyword_set(full_res) then decimate = 0
   if keyword_set(decimate) then param.decimate = decimate
   if keyword_set(educated) then param.educated = 1
   nk, scan, param=param, info=info, grid=grid, xml = xml, sn_min = sn_min, sn_max = sn_max

endif

if strupcase( strtrim( pako_str.obs_type, 2)) eq "DIY" then begin
   good_scan = 1
skydip_test,  scan_num,  day,  kidpar,  param = param,  sav = sav,  help = help,  test = test,  png = png,  ps = ps, RF = RF,   no_acq_flag = no_acq_flag
;   nk_skydip_test, scan, param=param, png=png, ps=ps, xml=xml
endif

if strupcase( strtrim( pako_str.obs_type, 2)) eq "TRACK" then begin
   good_scan = 1
   message, /info, "Do not reduce track"
endif

if good_scan eq 0 then begin
   message, /info, "Unrecognized observation type " + pako_str.obs_type
endif
  
;; time1 = systime( 0, /sec)
;; print, "total CPU time: ", time1-time0
;; stop

end
