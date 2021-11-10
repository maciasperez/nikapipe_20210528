
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; nk_rta
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;         nk_rta, scan_list, [DECOR=, HEADER=, NOPLOT=, $
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
; 
; MODIFICATION HISTORY: 
;        - June 2nd, 2014: Nicolas Ponthieu
;================================================================================================

pro nk_rta, scan, imbfits=imbfits, param = param, $
            diffuse=diffuse,  rf = rf, undersamp = undersamp, nasmyth = nasmyth, $
            median = median, sn_min = sn_min, sn_max = sn_max,  one_mm_only = one_mm_only,  two_mm_only = two_mm_only, $
            full_res = full_res, decimate = decimate, educated = educated, holes = holes, nopng=nopng, force=force,  $
            noskydip = noskydip, map_xsize = map_xsize, map_ysize = map_ysize, grid = grid, fwhm_prof=fwhm_prof, outfoc=outfoc, $
            ellipticity=ellipticity, a1_discard=a1_discard, a2_discard=a2_discard, a3_discard=a3_discard, $
            data=data, info=info, kidpar=kidpar, not_educated=not_educated, $
            iconic = iconic,  speed = speed, jump_remove=jump_remove, $
            xyguess=xyguess, radius=radius, nocheck=nocheck, azelguess=azelguess, $
            mask=mask, largemap=largemap, help=help, ps=ps, rmax_keep=rmax_keep, rmin_keep=rmin_keep, $
            lockin_freqhigh=lockin_freqhigh, noscp=noscp, doscp=doscp, zigzag_correction=zigzag_correction, raw_acq_dir=raw_acq_dir, $
            plotting_verbose=plotting_verbose, ref_det=ref_det, $
            subscan_min=subscan_min, subscan_max=subscan_max, p2cor=p2cor, p7cor=p7cor, $
            ptg_az_instruction=ptg_az_instruction, ptg_el_instruction=ptg_el_instruction, log_info=log_info, $
            method=method, rest=rest, all_ptg_instructions=all_ptg_instructions, iterate=iterate, kidfile=kidfile, noplot=noplot, $
            freqlow=freqlow, freqhigh=freqhigh, bandpass=bandpass, bandkill=bandkill, rescp=rescp, reset=reset, $
            proj_azel=proj_azel, rfpipq=rfpipq, list_data_all=list_data_all, polar=polar, commissioning=commissioning, $
            show_surrounding_kids=show_surrounding_kids, max_nsubscans_to_reduce=max_nsubscans_to_reduce, $
            do_not_reduce_skydips=do_not_reduce_skydips
;-

;; data, info and kidpar are outputs only (FXD)

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_rta'
   return
endif

if keyword_set(help) then begin
   ;; LP, Nov 2018, update
   print,"RTA: ********************************************************"
   print,"RTA: Quick help for NIKA2 campaigns"
   print,"RTA "
   print,"RTA: Point-like and extended sources"
   print,"RTA: ---------------------------------"
   print,"RTA  1/ default run: "
   print,"RTA: idl> nk_rta, 'scan'"
   print,"RTA: ---> for OTF scans, the 'COMMON_MODE_KIDS_OUT' decorrelation method is used, with a mask of 60 arcsec radius located at the center of the map"
   print,"RTA "
   print,"RTA  2/ very strong source (e.g. Mars) "
   print,"RTA: idl> nk_rta, 'scan', mask=100"
   print,"RTA: ---> enlarge the default mask to a radius of 100 arcsec (5 x FWHM@2mm)"
   print,"RTA "
   print,"RTA  3/ large map (> 6.5 arcmin)"
   print,"RTA: idl> nk_rta, 'scan', /largemap"
   print,"RTA: ---> enlarge the projected map from the default 300x300 arcsec² value to 600x600 arcsec²"
   print,"RTA: idl> nk_rta, 'scan', map_xsize=800, map_ysize=800"
   print,"RTA: ---> further enlarge the projected map to 800x800 arcsec² in this case"
   ;; LP, Nov 2018, comment out obsolete stuff
   ;;print,"RTA "
   ;;print,"RTA: Focus campaign"
   ;;print,"RTA: --------------------"
   ;;print,"RTA: The Nasmyth offset set in PAKO (ex: offset -100 50 \sys nasmyth) are dealt with using:"
   ;;print,"RTA: idl> nk_rta, 'scan', /nasmyth, /xyguess"
   ;;print,"RTA: For probing outter part of the matrix, the map needs to be enlarged:"
   ;;print,"RTA: idl> nk_rta, 'scan', /nasmyth, /xyguess, /largemap"
   print,"RTA "
   print,"RTA: Other special cases"
   print,"RTA: --------------------"
   print,"RTA: The pipeline parameters can be modified by initializing a default parameter struct."
   print,"RTA: idl> nk_default_param, param"
   print,"RTA: and setting the relevant parameters to new value." 
   print,"RTA: For ex: "
   print,"RTA: idl> param.map_reso = 1 ; [arcsec] increase the map resolution"        
   print,"RTA: idl> param.decor_cm_dmin = 70 ; [arcsec] radius of the mask used in the common_mode_kids_out decorrelation method"
   print,"RTA: idl> nk_rta, 'scan', param=param" 
   print,"RTA: *********************************************************************************"
   if n_params() lt 1 then return
endif


nk_scan2run, scan, run
!nika.run = run

scan2daynum, scan, day, scan_num
;; Sometimes the imbfits takes time to be complete and the user may
;; launch nk_rta before it's completed, hence scp'ing an incomplete
;; file and crashing the data reduction.
;; To re-scp the file conveniently, we've added the /rescp keyword.
if keyword_set(rescp) then begin
   spawn, "rm -f "+!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits"
   spawn, "rm -f "+!nika.imb_fits_dir+"/iram30m-sync-"+scan+".html"
   spawn, "rm -f "+!nika.imb_fits_dir+"/iram30m-scan-"+scan+".xml"
endif

if not keyword_set(noscp) then begin
   if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 then begin
      message, /info, "copying imbfits file from mrt-lx1"
      spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."

      ; Checking the scp did work
      if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 $
      then begin
         message, /info, 'No imbfits file, must quit'
         return
      endif
   endif
   if file_test(!nika.imb_fits_dir+"/iram30m-sync-"+scan+".html") eq 0 then begin
      message, /info, "copying the antenna messages html file from mrt-lx1"
      spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/log/*sync*html $IMB_FITS_DIR/."
   endif
   if file_test(!nika.xml_dir+"/iram30m-scan-"+scan+".xml") eq 0 then begin
      message, /info, "copying the xml file from mrt-lx1"
      spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/*"+strtrim(scan_num,2)+"/*.xml $XML_DIR/."
   endif
endif


;; Beammaps may be too long and too cpu consuming on nika2a during
;; polarization observations to be reduced during real time observations,
;; set this keyword to 1 to skip it.
if keyword_set(max_nsubscans_to_reduce) then begin
   imb_fits_file = !nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits"
   if file_test(imb_fits_file) eq 0 then begin
      message, /info, "Did not find the antennaIMBfits for scan "+scan
      return
   endif
   nk_imbfits2info, imb_fits_file, info
   if long(info.n_obs gt max_nsubscans_to_reduce) then begin
      for i=0, 5 do message, /info, "*********************************************"
      message, /info, "You have explicitely requested not to reduce maps with more than "+$
               strtrim( long(max_nsubscans_to_reduce),2)+" subscans."
      message, /info, "This scan "+scan+" has "+strtrim( long(info.n_obs),2)+" subscans, hence I quit."
      for i=0, 5 do message, /info, "*********************************************"
      return
   endif
endif

;; Init params
if not keyword_set(info)  then nk_default_info, info

if not keyword_set(param) then begin
   nk_default_param, param
;;; ATTENTION JUAN MODIFICATIONS BECAUSE OF PROBLEMS WITH REF PIXEL
   param.alain_rf  = 1
   param.math = "RF"
   if run eq '24' then param.polar = 1
   if run eq '26' then param.polar = 1
   
   param.fast_deglitch = 1 ; to save time, and there are very few glitches in NIKA2 anyway

   if keyword_set(noplot) then param.do_plot = 0
   param.rta                  = 1
   param.interpol_common_mode = 1 ; to be more tolerant in real time quicklook
   param.do_aperture_photometry = 0
   param.do_meas_atmo = 0       ; to be safe for now

   if keyword_set(one_mm_only) then param.one_mm_only = 1
   if keyword_set(two_mm_only) then param.two_mm_only = 1

   ;; message, /info, "fix me:"
;;   param.flag_sat   = 1
;;   param.flag_oor   = 1
;;   param.flag_ovlap = 1
    param.flag_sat   = 0         ; 0           ; to be more tolerant
    param.flag_oor   = 0
    param.flag_ovlap = 0
 
   param.flag_uncorr_kid      =  0 ; make sure to save time   param.new_deglitch = 0
   param.map_xsize = 600
   param.map_ysize = 600     
   param.imbfits_ptg_restore = 1

   ;;----------
   ;; This new method seems more robust for RTA
   ;; NP, Dec. 10th, 2016
   ;; param.decor_method = 'common_mode_kids_out' ; 'common_mode' ;
   param.decor_method = 'raw_median'
   ;;-----------

;   param.decor_cm_dmin = 60. ; to be conservative with focus measures
   param.plot_dir = !nika.plot_dir+"/Logbook/Scans/"+scan
   spawn, "mkdir -p "+param.plot_dir

   ;; Back to 4, FXD+NP, Nov. 10th, 2021 because 6 gives too high
   ;; values for high taus
   param.do_opacity_correction = 4 ; 6
;; ;;-------------------------------
;; ;; Force for now, because no skydip coeffs yet and to save time in get_df_tone...
;;    param.do_opacity_correction = 1
;;    param.force_opacity_225 = 1
;; ;   rf = 1
;; ;;-------------------------------

   if keyword_set(freqlow)  then param.freqlow = freqlow
   if keyword_set(freqhigh) then param.freqhigh = freqhigh
   if keyword_set(bandpass) then param.bandpass = 1
   if keyword_set(bandkill) then param.bandkill = 1
   
   if keyword_set(kidfile)       then begin
      param.force_kidpar = 1
      param.file_kidpar = kidfile
      param.do_opacity_correction=6  ; the kidfile should have skydip parameters
   endif
   if keyword_set(nopng)             then param.plot_png = 0 else param.plot_png = 1
   if keyword_set(ps)                then param.plot_ps = 1
   if keyword_set(nocheck)           then param.check_flags=0 else param.check_flags = 1
   if keyword_set(lockin_freqhigh)   then param.polar_lockin_freqhigh = lockin_freqhigh
   if keyword_set(zigzag_correction) then param.zigzag_correction = 1
   if keyword_set( iconic)           then param.iconic = 1  ;;;else param.iconic = 0
   if keyword_set(rf)                then param.math = "RF"
   if keyword_set(undersamp)         then param.undersamp = undersamp
   if keyword_set(median)            then begin
      param.decor_method = "median_simple"
      param.median_simple_Nwidth = 3 ; 6 ; a bit larger than the default to be more tolerant to out of focus obs.
   endif
   if keyword_set(method)            then param.decor_method = method
   if keyword_set(holes)             then param.treat_data_holes = 1
   if keyword_set(noskydip)          then param.do_opacity_correction = 0
   if keyword_set(map_xsize)         then param.map_xsize = map_xsize
   if keyword_set(map_ysize)         then param.map_ysize = map_ysize
   if keyword_set(a1_discard)        then param.a1_discard = 1
   if keyword_set(a2_discard)        then param.a2_discard = 1
   if keyword_set(a3_discard)        then param.a3_discard = 1
   if keyword_set(rmax_keep)         then param.rmax_keep = rmax_keep
   if keyword_set(rmin_keep)         then param.rmin_keep = rmin_keep
   if keyword_set(not_educated)      then param.educated = 0
   if keyword_set(proj_azel)         then param.map_proj = "azel"
   if keyword_set(rfpipq)            then param.do_rfpipq = 1
   if keyword_set(list_data_all)     then param.list_data_all = 1
   if keyword_set(educated)          then param.educated = 1
   if keyword_set(polar)             then param.polar = 1
   if keyword_set(commissioning)     then param.commissioning_plot=1
endif

;; force here for convenience
; param.polar = 1

if strupcase(!nika.acq_version) eq "V2" then begin
   param.new_pol_synchro = 1
endif

;; Erase all previous windows for convenience
wd, /a
!nika.plot_window = -1


if not keyword_set(reset) and file_test( !nika.plot_dir+"/v_1/"+scan+"/results.save") then return


;; Bright point source processing
;; LP, 2016/01
;;--------------------------------
if keyword_set(mask) then begin
   ;; same results as using the radius keyword
   ;; I added it because radius seems not propagated to every routines
   ;; [TBC]
   rayon = 60.
   radius = rayon
   if mask gt 1. then rayon=mask
   param.decor_method = 'COMMON_MODE_KIDS_OUT'    
   param.decor_cm_dmin = rayon  
   param.map_reso = 2
endif

;; Large map processing
;; LP, 2016/01
;;--------------------------------
;; useful for @focusOTF, for probing the outter part of the matrix
;; for map larger than 10 arcmin, use the keywords map_xsize, map_ysize
if keyword_set(largemap) then begin
   param.map_xsize = 1200    
   param.map_ysize = 1200     
   param.map_reso  = 2.0d0
   if largemap eq 2 then begin
       param.map_xsize = 4000    
       param.map_ysize = 4000     
       param.map_reso  = 5.d0
   endif
endif

if param.check_flags eq 1 then nk_log_antmd_messages, scan
nk_update_param_info, scan, param, info, katana=katana, silent=silent, raw_acq_dir=raw_acq_dir

;; Determine which type of scan and create the "pako_str" scan information structure
nk_imbfits2pako_str, param.file_imb_fits, pako_str
junk = mrdfits( param.file_imb_fits, 0, header, /silent)
nsubscans = sxpar( header, "n_obs")
if strupcase(pako_str.obs_type) eq "LISSAJOUS" and nsubscans gt 1 then pako_str.purpose = "focus"

;;-------------------------------------------------------------------------------------
;; Launch the appropriate routine
;; POINTING CROSS (@nkpoint b) and POINTING LISS (@nkpoint l)   
good_scan = 0
if strupcase( strtrim( pako_str.obs_type, 2)) eq "POINTING" or $
   ( (strupcase( strtrim( pako_str.obs_type, 2)) eq "LISSAJOUS") and $
     (strupcase( strtrim(pako_str.purpose,2)) ne "FOCUS")) then begin

   good_scan = 1

   ;; flag out the end of the subscan that is not killed due to
   ;; missing message subscandone.
   if long(!nika.run) eq 15 and strupcase( strtrim( pako_str.obs_type, 2)) eq "LISSAJOUS" then begin
      param.flag_n_seconds_subscan_end   = 2.5d0
   endif

;;   if (not keyword_set(ref_det)) and (!nika.run eq 33 or !nika.run eq 34 or !nika.run eq 35) then begin
;;      ;; A2 seems lost for this two day test run
;;      ref_det = !nika.ref_det[0]
;;   endif
;   print, "ref_det: ", ref_det
;   stop
;   print, "param.polar, info.polar: ", param.polar, info.polar
;   info.polar=1
   nk_pointing_3, scan, pako_str, param, info, $
                  online=online, p2cor=p2cor, p7cor=p7cor, nas_offset_x=nas_offset_x, nas_offset_y=nas_offset_y, $
                  ref_det=ref_det, obs_type = obs_type, $
                  nasmyth = nasmyth, sn_min = sn_min, sn_max = sn_max, $
                  fwhm_prof=fwhm_prof, outfoc=outfoc, ellipticity=ellipticity, $
                  data=data, kidpar=kidpar, xyguess=xyguess, radius=radius, azelguess=azelguess, grid=grid, $
                  raw_acq_dir=raw_acq_dir, plotting_verbose=plotting_verbose, rest=rest, all_ptg_instructions=all_ptg_instructions, $
                  show_surrounding_kids=show_surrounding_kids

endif

;; @focusliss, @focuslissold
if strupcase( strtrim( pako_str.obs_type, 2)) eq "LISSAJOUS" and strupcase( strtrim(pako_str.purpose,2)) eq "FOCUS" then begin
   good_scan = 1
;   param.decor_method = "common_mode" ; in case we're very out of focus, the region to mask would be very large
;   param.decor_method = 'raw_median'
   
   param.plot_dir = !nika.plot_dir+"/Logbook/Scans/"+scan
   spawn, "mkdir -p "+param.plot_dir
   param.map_proj = "azel" ; added NP, Jan 2016
   if keyword_set(nasmyth) then param.map_proj = "nasmyth"
   nk_focus_liss, scan, param=param, educated = param.educated, nopng=nopng, jump_remove=jump_remove, $
                  data=data, info=info, kidpar=kidpar, xyguess=xyguess, radius=radius, azelguess=azelguess
endif

;; @focustrack ?
if strupcase( strtrim( pako_str.obs_type, 2)) eq "FOCUS" then begin
   good_scan = 1
   nk_focus, scan, param=param
;, info=info, $
;             
;             RF=RF, force=force, imbfits=imbfits, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
;             max6=max6, check=check, radius_far_kids=radius_far_kids, holes = holes
endif

;; @nkotf 
if strupcase( strtrim( pako_str.obs_type, 2)) eq "ONTHEFLYMAP" then begin
   good_scan = 1

   message, /info, param.decor_method
;;    ;; Create mask_source
;;    if not keyword_set(diffuse) then begin
;;       param.decor_method = "common_mode_kids_out"
;;    endif
;   nk_init_grid, param, info, grid
;   param.polar=1
;   info.polar=1
   nk_init_grid_2, param, info, grid
   message, /info, param.decor_method
;   stop
   plot_output_dir = !nika.plot_dir+"/Logbook/Scans/"+scan
   spawn, "mkdir -p "+plot_output_dir
   param.plot_dir = plot_output_dir

   if keyword_set(full_res) then decimate = 0
   if keyword_set(decimate) then param.decimate = decimate
   if keyword_set(educated) then param.educated = 1
;   if keyword_set(one_mm_only) then param.one_mm_only = 1
;   if keyword_set(two_mm_only) then param.two_mm_only = 1

   if keyword_set(nasmyth) then begin
      param.map_proj = "nasmyth"
      !mamdlib.coltable = 3
   endif
      
   if keyword_set(jump_remove) then param.jump_remove=1

   if not keyword_set(radius) then radius = 60 ; 50
   if keyword_set(xyguess) then begin
      nk_default_mask, param, info, grid, radius=radius, $
                       xcenter=info.NASMYTH_OFFSET_X, $
                       ycenter=info.NASMYTH_OFFSET_Y
      ;; already defined l.317, redoundant.
      param.decor_method = 'common_mode_kids_out'
      param.map_proj = "NASMYTH"
;      !mamdlib.coltable = 3
      xguess = info.NASMYTH_OFFSET_X
      yguess = info.NASMYTH_OFFSET_Y

      if param.rmax_keep lt 1000 or param.rmin_keep gt 0 then begin
         param.x_center_keep = xguess
         param.y_center_keep = yguess
      endif
      
      param.educated = 0 ; 1
   endif   
   if keyword_set(azelguess) then begin
      nk_default_mask, param, info, grid, radius=radius
      param.map_proj = "azel"
      param.decor_method = 'common_mode_kids_out'
      xguess = 0.d0
      yguess = 0.d0
      param.educated = 1
   endif

   ;; 
   if keyword_set(mask) then begin
      nk_default_mask, param, info, grid
   endif

   if keyword_set(subscan_min) then param.subscan_min = subscan_min
   if keyword_set(subscan_max) then param.subscan_max = subscan_max

   ;; Force filing to 1 to avoif reprocessing all scans when building
   ;; the logbook with nk_log_iram_tel.pro (NP, June 8th, 2017)
   filing = 1
   if keyword_set(reset) then filing=0
;   param.polar = 1
;   info.polar = 1
   nk, scan, param=param, info=info, grid=grid, kidpar=kidpar, $
       xml = xml, sn_min = sn_min, sn_max = sn_max, data=data, filing = filing, xguess=xguess, yguess=yguess, $
       raw_acq_dir=raw_acq_dir, polar=param.polar

   ;; Fit the position of the source, define a mask and re-reduce the
   ;; scan with common_mode_kids_out.
   if keyword_set(iterate) then begin
      nk_default_mask, param, info, grid, radius=30, xcenter=info.result_off_x_2, ycenter=info.result_off_y_2
      param.decor_method = 'common_mode_kids_out'
      nk, scan, param=param, info=info, grid=grid, kidpar=kidpar, $
          xml = xml, sn_min = sn_min, sn_max = sn_max, data=data, filing = filing, xguess=xguess, yguess=yguess, $
          raw_acq_dir=raw_acq_dir, polar=param.polar
   endif
   
   if param.do_plot eq 1 and param.plot_png eq 1 then png, plot_output_dir+"/plot_"+scan+".png"

   if info.status ne 0 then begin
      message, /info, 'Could not find data for that scan'
      return
   endif

   if info.polar eq 1 then begin
      fmt = '(F6.4)'
      fmt_err = '(F8.6)'
      message, /info, "Pol. deg 1: "+$
               string(info.result_pol_deg_1,form=fmt)+" +- "+$
               string(info.result_err_pol_deg_1, form=fmt_err)
      message, /info, "Pol. deg 3: "+$
               string(info.result_pol_deg_3,form=fmt)+" +- "+$
               string(info.result_err_pol_deg_3, form=fmt_err)
      message, /info, "Pol. deg 1mm: "+$
               string(info.result_pol_deg_1mm,form=fmt)+" +- "+$
               string(info.result_err_pol_deg_1mm, form=fmt_err)
   endif
   
   ;; Get useful information for the logbook
   nk_get_log_info, param, info, data, log_info
   log_info.scan_type = pako_str.obs_type
   log_info.source    = pako_str.source
   if info.polar ne 0 then  log_info.scan_type = info.obs_type+'_polar'

   log_info.ut = info.ut
   log_info.az = info.azimuth_deg
   log_info.el = info.result_elevation_deg

   ;; Create a html page with plots from this scan
   save, file=plot_output_dir+"/log_info.save", log_info
   nk_logbook_sub, param.scan_num, param.day
endif

;; @skydip
if strupcase( strtrim( pako_str.obs_type, 2)) eq "DIY" and $
   not keyword_set(do_not_reduce_skydips) then begin
   good_scan = 1
   param.do_opacity_correction = 4 ; 1
;   param.flag_n_seconds_subscan = 0.d0
   
   scan2daynum, scan, day, scan_num
   param.plot_dir = !nika.plot_dir+"/Logbook/Scans/"+scan
   spawn, "mkdir "+param.plot_dir
   ;; nk_skydip_4, scan_num, day, param, info, kidpar, data, raw_acq_dir=raw_acq_dir
   ;; Switching to nk_skydip_5, Feb. 18th, 2017 (FXD+NP)

   nk_skydip_5, scan_num, day, param, info, kidpar, data, dred, raw_acq_dir=raw_acq_dir, kidout=kidout

   if info.status ne 1 then begin
      w1 = where(kidpar.type eq 1 and kidpar.lambda lt 1.5, nw1)
      print, "median C0 at 1mm = ",median(kidpar[w1].c0_skydip)
      print, "median C1 at 1mm = ",median(kidpar[w1].c1_skydip)
      w2 = where(kidpar.type eq 1 and kidpar.lambda gt 1.5, nw2)
      print, "median C0 at 2mm = ",median(kidpar[w2].c0_skydip)
      print, "median C1 at 2mm = ",median(kidpar[w2].c1_skydip)
   endif

   ;; Save results for future use in the global reduction of all
   ;; skydips
   output_dir = !nika.plot_dir+"/Run"+strtrim(!nika.run,2)+"/"+scan
   spawn, "mkdir -p "+output_dir
   save, param, info, kidpar, kidout, dred, file=output_dir+"/results.save"

   ;; Save plots for the logbook
   w = where( !nika.plot_window[0] gt 0, nw)
   if nw ne 0 then begin
      for iw=0, nw-1 do begin
         wset, !nika.plot_window[iw]
         png, param.plot_dir+"/monitor_"+strtrim(iw,2)+".png"
      endfor
   endif
   
endif

if strupcase( strtrim( pako_str.obs_type, 2)) eq "TRACK" then begin
   good_scan = 1
   message, /info, "Track scan, I pass."
endif

if good_scan eq 0 then begin
   message, /info, "Unrecognized observation type " + pako_str.obs_type
endif
  
;time1 = systime( 0, /sec)
close, /all  ; remove a nagging bug if a session of rta is too long: message iswas "all units are used" 
my_multiplot, /reset
!p.multi=0

;; Update logbook
nk_logbook, param.day
;; Rsync the logbook

if keyword_set(doScp) or (!host eq 'nika2a') then $
   spawn, "rsync -avuzq $NIKA_PLOT_DIR/Logbook t22@mrt-lx1.iram.es:./samuel/. 2> /dev/null"

end
