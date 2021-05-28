;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; NAME:
; nk_getdata
;
; PURPOSE: 
;        Read the raw data
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
; 
; OUTPUT: 
;        - data: the data structure
;        - kidpar: the KID parameter structure
; 
; KEYWORDS:
;        - LIST_DATA: the list of variables to be put in the data structure
;        - RETARD: a retard between NIKA and telescope data
;        - EXT_PARAMS: extra variables to be put in the data structure
;        - ONE_MM_ONLY: set this keyword if you only want the 1mm channel
;        - TWO_MM_ONLY: set this keyword if you only want the 2mm channel
;        - FORCE_FILE:Use this keyword to force the list of scans used
;        instead of checking if they are valid
;        - RF: set this keyword if you want to use RF_dIdQ instead of
;          the polynom
;        - NOERROR: set this keyword to bypass errors
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_getdata.pro 
;        (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;        - 25/10/2018, notruncate option for debug purpose only
;          (seeing tunings)
;
;-
;====================================================================================================

pro nk_getdata, param, info, data, kidpar, $
                LIST_DATA=LIST_DATA, $
                RETARD=RETARD, $
                EXT_PARAMS=EXT_PARAMS, $
                FORCE_FILE=FORCE_FILE, $
                RF=RF, $
                NOERROR=NOERROR, $
                sn_min=sn_min, sn_max=sn_max, $
                scan=scan, prism=prism, lab_polar=lab_polar, xml = xml, $
                param_c = param_c, in_param=in_param, read_type=read_type, $
                list_detector=list_detector, katana=katana, polar=polar, $
                badkid=badkid, noplot=noplot, pipq=pipq, notruncate = notruncate, $
                xoff=xoff

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_getdata'
   return
endif

pp=-1
;; to give quick access to the data
if keyword_set(scan) then begin
   if keyword_set(in_param) then param=in_param else nk_default_param, param
   nk_default_info, info
   param.scan = scan
   param.do_opacity_correction = 0
   nk_scan2run, param.scan, run

   ;; Retrieve general information from the Antenna IMBfits file, determine the
   ;; kidpar that should be used and inits directories for temporary products.
   ;; nk_update_scan_info, param, info, focus_liss_new, xml = xml
   nk_update_param_info, param.scan, param, info, xml=xml, katana=katana
endif

if keyword_set(noplot) then param.do_plot = 0

if keyword_set(force_file) then begin
   if defined(param) eq 0 then nk_default_param, param
   if defined(info)  eq 0 then nk_default_info, info
endif

;;if param.cpu_time then param.cpu_t0 = systime( 0, /sec)
cpu_t0_getdata = systime(0, /sec)

;;========== List what we want to read
ext_params = ['antxoffset', 'antyoffset', 'anttrackAz', 'anttrackEl']
nk_check_list_data, param, info, LIST_DATA=LIST_DATA, RETARD=RETARD, EXT_PARAMS=EXT_PARAMS

if param.lab ne 0 then begin
   info.obs_type = "ONTHEFLYMAP"
   param.do_opacity_correction = 0
endif

;; Determine which raw data file must be read.
;; Allow FORCE_FILE for laboratory files with no correct day and scan_num
if keyword_set(FORCE_FILE) then begin
   if keyword_set(RF) then param.math = "RF"
   param.data_file = force_file
endif else begin
   nk_scan2run, param.scan, run
   if info.status eq 1 then begin
      if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
      return
   endif
endelse

;; if !nika.run eq 13 then param.math = "RF"

cpu_t0 = systime(0, /sec)
if param.renew_df gt 0 then param_d = 1 else param_d = 0

;; Read kids chosen by the input kidpar or all of them by default
if keyword_set(katana) then begin
   delvarx, list_detector
endif else begin
   if strupcase(!nika.acq_version) ne "V3" then begin
      nk_param2list_detector, param, info, list_detector=list_detector
   endif
endelse

;; Read raw data file
param1 = param
nk_cpu_time, param1, /get

t0 = systime(0,/sec)
;if strupcase(!nika.acq_version) eq "V2" then list_data = 'all'
print, "param.data_file: "+param.data_file

rr = read_nika_brute(param.data_file, param_c, kidpar, data, units, param_d=param_d, $
                     list_data=list_data, list_detector=list_detector, $
                     read_type=param.read_type, /silent, amp_modulation=amp_modulation, $
                     polar=polar, katana=katana, dataU=dataU)
info.f_sampling = !nika.f_sampling
info.acq_version = strupcase(!nika.acq_version)

;iarray = 2
;nk_plot_kid_vs_median, param, info, data, kidpar, iarray, comment="after read_nika_brute"

;; Checking if the external calibrator is ON
data_tags = tag_names(data)
w = where( strupcase(data_tags) eq "PQ", nw)
if nw ne 0 then begin
   if max(data.pq) ne min(data.pq) then begin
      param.do_rfpipq = 1
      info.pipq = 1
   endif
endif

;; Scan duration, before we cut any of the data
if long(!nika.run) gt 12 then info.result_scan_time = n_elements(data)/!nika.f_sampling

if rr le 0 then begin
   nk_error, info, "No useful data"
   return
endif

if param.cpu_time then nk_show_cpu_time, param1, force='read_nika_brute'
t1 = systime(0,/sec)
;print, "t1-t0: ", t1-t0

;; Init numdet (necessary for update_kidpar)
if tag_exist( kidpar, "raw_num") then kidpar.numdet = kidpar.raw_num

;; Moved up here, NP, Sept. 30th (cleaner e.g. in prevision for nk_check_flags)
;; If a kidpar is passed to nk_getdata via param.file_kidpar, then it replaces the current
;; one given by read_nika_brute
nk_update_kidpar, param, info, kidpar, param_c

;iarray = 2
;nk_plot_kid_vs_median, param, info, data, kidpar, iarray, comment="after update kidpar", /ks

if param.subscan_min ne 0 then begin
   w = where( data.subscan ge param.subscan_min, nw)
   if nw eq 0 then begin
      nk_error, info, "No subscan has a larger index than the requested param.subscan_min: "+strtrim(param.subscan_min,2)
      return
   endif
   data = data[w]
endif
if param.subscan_max ne 0 then begin
   w = where( data.subscan le param.subscan_max, nw)
   if nw eq 0 then begin
      nk_error, info, "No subscan has a lower index than the requested param.subscan_max: "+strtrim(param.subscan_max,2)
      return
   endif
   data = data[w]
endif

nsn = n_elements(data)

w1 = where( kidpar.type eq 1, nw1)

;; Init the summary plot window
if param.rta eq 1 then begin
   wind, 1, 1, /free, /large, iconic=param.iconic
   !nika.plot_window[0] = !d.window
endif

;; Deal with pps time and synchronization
nk_deal_with_pps_time, param, info, data, kidpar

;; Interpret Alain's tuning and acquisition flags
nk_translate_acq_flags, param, info, data, kidpar

;iarray = 2
;nk_plot_kid_vs_median, param, info, data, kidpar, iarray, comment="after translate_acq_flags"
   if strtrim(info.obs_type, 2) eq 'DIY' then param.skydip = 1 ; FXD forgotten?

;; Check tuning flags and Elvin messages
if param.check_flags eq 1 then begin
   nsn = n_elements(data)
   message, /info, "nsn = "+strtrim(nsn,2)
   message, /info, "data.scan[nsn/2]: "+strtrim(data[nsn/2].scan,2)
   message, /info, "minmax(data.subscan): "+strtrim(min(data.subscan),2)+" "+strtrim(max(data.subscan),2)
   if param.skydip eq 1 then fields = ['el'] else fields=['ofs_az', 'ofs_el']
   w1 = where(kidpar.type eq 1)
   if !nika.ref_det[0] ne -1 then ikid=where(kidpar.numdet eq !nika.ref_det[0]) else ikid = w1[0]

; temporary comment, NP, April 18th
;   if param.scanamnika ne 0 then log_messages=0 else log_messages=1
   
   nk_check_flags, param, info, data, kidpar, ikid, $
                   fields=fields, file=param.plot_dir+"/messages.dat", $
                   log_messages=log_messages, ext='raw', $
                   plot_name=param.plot_dir+"/check_flags_raw_"+param.scan
   if param.pause ne 0 then begin
      message, /info, "Pause to look at flags and messages, press .c to go on."
      stop
   endif
endif

;iarray = 2
;nk_plot_kid_vs_median, param, info, data, kidpar, iarray, comment="after check_flags"

bypass_speed_flag = 0
if strupcase(!nika.acq_version) eq "V2" or $
   strupcase(!nika.acq_version) eq "V3" then begin

   data.toi *= -1d0
   param.speed_tol = 10.
   bypass_speed_flag = 0 ; 1 ; temporary
   param.nhits_min_bg_var_map = 1

   data.ofs_az *= !radeg*3600.d0*60.
   data.ofs_el *= !radeg*3600.d0*60.
   data.el *= !dtor
   data.az *= !dtor
   data.ofs_az *= cos(data.el)

   data.antxoffset *= !radeg*3600*cos(data.el)
   data.antyoffset *= !radeg*3600

;   message, /info, "replacing ofs_az (ofs_x) by antxoffset etc..."
   data.ofs_az = data.antxoffset
   data.ofs_el = data.antyoffset

   ;; Basic fix waiting for the problem to be solved directly in the acquisition
   w4 = where( data.scan_st eq 4, nw4)
   if nw4 eq 0 then begin
      nk_error, info, "No subscan_started message"
      return
   endif

   data.subscan = 0
   index = lindgen(n_elements(data))
   for i=0, nw4-1 do begin
      w = where( index ge w4[i])
      data[w].subscan += 1
   endfor
   
   ;; Until Sept. 22nd, 2018, param.imbfits_ptg_restore was forced to
   ;; zero, because at some point it used to overwrite subscans later
   ;; on... ?
   ;; It seems that this issue has been fixed somewhere in the
   ;; acquisition, and we can safely put it back to its default value
   ;; and then allow pointing recovery with antennaimbfits (NP).
   ;; ;; param.imbfits_ptg_restore = 0
;;==========================================================================================
endif

;; print, '1'
;; for iarray=1, 3 do print, "A"+strtrim(iarray,2)+": "+strtrim(n_elements( where( kidpar.type eq 1 and kidpar.array eq iarray)),2)
;; stop

;; NP, June 22nd, 2015 (post Run11 and 12) (corrected nk_get_kid_pointing accordingly):
;; Turn (az,el) offsets into (co-el, el) offsets if necessary.
;; Note that this will be overwritten in nk_otf_antenna2pointing if it is
;; called.
;; This is done *only* to undo what Alain does by default in his code.
if strupcase(info.systemof) eq "PROJECTION" and long(!nika.run) ge 11 then data.ofs_az = data.ofs_az/cos(data.el)

nsn = n_elements(data)
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif
if rr lt 10 then begin
   message, /info, 'Not enough data in raw NIKA data file exiting '+ $
            strtrim( rr,  2)
   info.status = 1
   return
endif
if max(data.subscan) lt 1 then begin
   message, /info, "********************************************************"
   message, /info, 'No subscans in raw NIKA data file, exiting '+ $
            strtrim( long(max(data.subscan)),  2)
   message, /info, "Minmax(data.subscan): "+strtrim(min(data.subscan),2)+", "+strtrim(max(data.subscan),2)
   help, data
   message, /info, "********************************************************"
   info.status = 1
   return
endif

if param.no_polar ne 0 and info.polar ne 0 then begin
   nk_error, info, "this is a polarized scan and param.no_polar == 1"
   return
endif

if param.lab_polar ne 0 then info.polar = param.lab_polar

;; Deal with polarisation fields, replace rf_didq by toi, adds dra, ddec etc...
nk_update_data_fields, param, info, data, kidpar, katana=katana

nsn = n_elements(data)

;; Compute the HWP instantaneous angle
;; quick fix for lab_polar
;if info.polar ne 0 and param.lab_polar eq 0 then nk_get_hwp_angle, param, info,data
if info.polar ne 0 then begin
   if param.new_pol_synchro eq 0 then begin
      nk_get_hwp_angle, param, info, data, hwp_motor_position
   endif else begin
      nk_get_hwp_angle_2, param, info, data, hwp_motor_position
   endelse
endif

;; Oct. 7th, 2014
;; Until Alain fixes acquisition
if param.day eq 20141007 then data.toi = -data.toi

;; ;; If a kidpar is passed to nk_getdata via param.file_kidpar, then it replaces the current
;; ;; one given by read_nika_brute
;; nk_update_kidpar, param, info, kidpar, param_c

if param.one_mm_only eq 1 then begin
   w = where( kidpar.array eq 2, nw)
   if nw ne 0 then kidpar[w].type = 3
endif
if param.two_mm_only eq 1 then begin
   w = where( kidpar.array ne 2, nw)
   if nw ne 0 then kidpar[w].type = 3
endif

;; print, '3'
;; for iarray=1, 3 do print, "A"+strtrim(iarray,2)+": "+strtrim(n_elements( where( kidpar.type eq 1 and kidpar.array eq iarray)),2)
;; stop

;; to select kids close or far from an arbitrary position in the
;; Nasmyth plane
d_nas = sqrt( (kidpar.nas_x-param.x_center_keep)^2 + (kidpar.nas_y-param.y_center_keep)^2)
w = where( d_nas ge param.rmin_keep and d_nas le param.rmax_keep, nw, compl=compl, ncompl=ncompl)
if nw eq 0 then begin
   txt = "no kid found between "+strtrim(param.rmin_keep,2)+" and "+strtrim(param.rmax_keep,2)
   nk_error, info, txt
   return
endif
if ncompl ne 0 then kidpar[compl].type = 3


;; Acquisition flags from the raw data: tells about tunings etc... via k_flag
;if strtrim(info.obs_type, 2) eq 'DIY' then $
;   nk_acqflag2pipeflag, param, info, data, kidpar
;w_type3 = where(min(data.flag, dimension=2) gt 0 and kidpar.type ne 2, c_type3) ;;;& print, c_type3

; FXD: before doing anything, exclude all data outside valide subscans
; Apr 2020, necessary for nk_acqflag2pipeflag to work
wv = where( data.subscan ge 1, nwv)
stscan = where( data.subscan eq 1, nstscan) ; stricter as the end of the
                                ; previous scan can be at the
                                ; beginning with subscan=27 for example

if nwv eq 0 then begin
   txt = 'no sample with subscan ge 1'
   message, /info, txt
   nk_error, info, txt
   return
endif
if nstscan eq 0 then begin
   txt = 'no sample with subscan eq 1, i.e. no tuning; very strange'
   message, /info, txt
   nk_error, info, txt
   return
endif
if not keyword_set( notruncate) then data = temporary( data[stscan[0]:wv[nwv-1]])

;; if strtrim(info.obs_type, 2) eq 'DIY' and !nika.run eq '58' then $
;;    message, /info, "fix me: ignore acqflag in skydips for the moment FXD Nov 2020" else $
   nk_acqflag2pipeflag, param, info, data, kidpar

;; Flag nan values on some scans
;nk_nan_flag, param, info, data, kidpar
nk_nan_and_zero_flag, param, info, data, kidpar

;stop, '2.0.2'
;; Flag from scan status
nk_flag_scanst, param, info, data, kidpar

;; for iarray=1, 3 do print, "A"+strtrim(iarray,2)+": "+strtrim(n_elements( where( kidpar.type eq 1 and kidpar.array eq iarray)),2)
;;stop

;; nk_tuningflag seems obsolete, using nk_tuningflag_skydip from now
;; on: Aug 4th, 2016 (NP), rev > 12149
;; had to come back to old version, the test on byte = 8 crashes for
;; scans that are not skydips and discards the entire scan
if param.skydip eq 1 then begin
   nk_tuningflag_skydip, param, info, data, kidpar
endif else begin
   nk_tuningflag, param, info, data, kidpar
endelse
; stop,'2.0.3'

;; Dilution flags
nk_tdilflag, param, info, data, kidpar

;; Take all samples when acquiring data in the lab
if param.lab ne 0 then data.scan_valid=0

;; Moved up to match new acquisition version, NP. March 12th, 2018
;; ;; Deal with pps time and synchronization
;; nk_deal_with_pps_time, param, info, data, kidpar

;; Restrict to "valid" section of the scan
ndata = n_elements( data)
avg_valid = avg( data.scan_valid, 0)
;;;wv = where( avg_valid eq 0 and data.subscan ge 1, nwv)
wv = where( avg_valid eq 0, nwv)
if nwv eq 0 then begin
   txt = 'no sample with scan_valid[0] or scan_valid[1] eq 0'
   message, /info, txt
   nk_error, info, txt
   return
endif

;; Sept. 23rd, 2018
;; data = temporary( data[wv])
if not keyword_set( notruncate) then begin
   ; don't do it if not necessary
   if nwv ne ndata then data = temporary( data[wv[0]:wv[nwv-1]])
endif

;; Improve pointing reconstruction if needed or requested
if strupcase(!nika.acq_version) ne "ISA" then begin
   if long(!nika.run) eq 8 or param.imbfits_ptg_restore ge 1 then begin
      nk_restore_pointing_2, param, info, data, kidpar
   endif
   if not keyword_set( notruncate) then data = data[where(data.subscan ge 1)]
endif

;;;;-----------------------------
;;message, /info, "FIX ME"
;;message, /info, "Uncomment the shift section (Nov. 26th to debug GRB run5)"
;;;; Shift subscans to solve IRAM synchronization problems but do not
;;;; wrap around the final subscan to the first one.
;;nshift = long( !nika.subscan_delay_sec*!nika.f_sampling)
;;if nshift ne 0 then begin
;;   nsn    = n_elements(data)
;;   data[nshift:*].subscan = (shift( data.subscan, nshift))[nshift:*]
;;endif
;;;;-----------------------------
;stop, '2.1'

;stop, '2.2'
;; Flag out some fraction of subscans if requested due to pointing
;; uncertainties or delays in tuning and messages
;; NP, Jan. 18th, 2016
nsn = n_elements(data)
; FXD: Sept 2016, this comment is useful to debug rampaging tunings
; JFMP, MC, Oct 2016, need to check this, not workin
;message, /info, 'Data shrunk from '+ strtrim( ndata, 2)+ $
;         ' to '+ strtrim( nsn, 2)+' after removing tuning periods' 


;;-------------------------------------
;; Commented out Sept. 18, 2018: moved the plot to the 1st call to
;; nk_check_flags, this section is then useless ?
;; if param.rta eq 1 then begin
;;    ikid_list = where( kidpar.numdet eq !nika.ref_det[0] or $
;;                       kidpar.numdet eq !nika.ref_det[1] or $
;;                       kidpar.numdet eq !nika.ref_det[2])
;;    plot_name = param.plot_dir+"/check_flags_end_"+param.scan
;;    nk_check_flags, param, info, data, kidpar, ikid_list, plot_name=plot_name
;; endif
;;-------------------------------------

;; Cut out the beginning and/or end of scan if requested
;; Do it here, before optimizing for Fourier transforms when it changes de
;; factor the min and max samplenumbers.
nsn = n_elements(data)
my_sn_min = 0
my_sn_max = nsn-1
if keyword_set(sn_min) then my_sn_min = sn_min
if keyword_set(sn_max) then my_sn_max = sn_max
;; Test on my_sn_min and my_sn_max to avoid the following line if possible (it's very slow)
if my_sn_min ne 0 or my_sn_max ne (nsn-1) then begin
   if not keyword_set( notruncate) then $
      data = data[(my_sn_min>0):(my_sn_max<(nsn-1))]
   nsn = n_elements(data)
endif

;; Apply fine pointing corrections if requested
nk_fine_pointing, param, info, data, kidpar
;w_type3 = where(min(data.flag, dimension=2) gt 0 and kidpar.type ne 2, c_type3) & print, c_type3
;stop, '4'
;; print, '7'
;; for iarray=1, 3 do print, "A"+strtrim(iarray,2)+": "+strtrim(n_elements( where( kidpar.type eq 1 and kidpar.array eq iarray)),2)
;; stop

;; Deal with external calibrator pipq here before nk_cut_scans
if param.do_rfpipq eq 1 then nk_pipq_cal_fact, param, info, data, kidpar, pipq

;; Flag out anomalous speed behaviour (intersubscans, approaching slew in
;; Lissajous...)
;; Discard slews if it's a "otf" scan and if param is set accordingly.
; Do not discard data in case of DIY
if bypass_speed_flag eq 0 then begin
   if param.focus_liss_new eq 0 and strtrim(info.obs_type, 2) ne 'DIY' then begin
      if param.lab eq 1 then begin
         nk_speed_flag, param, info, data, kidpar, $
                        first_subscan_beg_index=first_subscan_beg_index, $
                        last_subscan_end_index=last_subscan_end_index
      endif else begin
         nk_speed_flag_2, param, info, data, kidpar, $
                          first_subscan_beg_index=first_subscan_beg_index, $
                          last_subscan_end_index=last_subscan_end_index, $
                          pipq=pipq
      endelse
      if not keyword_set( notruncate) then $
         nk_cut_scans, param, info, data, kidpar, pipq=pipq
      nsn = n_elements(data)    ; update after nk_cut_scans
   endif
endif

;; wind, 1, 1, /free, /xlarge
;; iarray = 1
;; w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;; make_ct, nw1, ct
;; xra = [0,1]*100 + nsn/2
;; yra = [0,2000] ; minmax(data.toi[w1])
;; for i=0, nw1-1 do begin &$
;;    ikid = w1[i] &$
;;    if i eq 0 then plot, data.toi[ikid], yra=yra, /ys, /xs, xra=xra &$
;;    oplot, data.toi[ikid], col=ct[i] &$
;;    endfor
;; 
;;    plot, xra, yra, /xs, /ys, /nodata
;;    make_ct, 8, ct
;;    for ibox=4, 11 do begin &$
;;       w1 = where( kidpar.type eq 1 and kidpar.acqbox eq ibox and kidpar.array eq iarray, nw1) &$
;;       if nw1 ne 0 then begin &$
;;          ikid = w1[0] &$
;;          oplot, data.toi[ikid], col=ct[ibox-4] &$
;;       endif &$
;;    endfor
;; 
;; stop,  'after nk_cut_scans'

if keyword_set(katana) then param.do_opacity_correction = 0
;w_type3 = where(min(data.flag, dimension=2) gt 0 and kidpar.type ne 2, c_type3) & print, c_type3

;save, file='bidon.save'
;;stop, '5'
nk_data_conventions, param, info, data, kidpar, param_c, param_d, xoff=xoff

;w_type3 = where(min(data.flag, dimension=2) gt 0 and kidpar.type ne
;2, c_type3) & print, c_type3
;stop, '6'

;; print, '8'
;; for iarray=1, 3 do print, "A"+strtrim(iarray,2)+": "+strtrim(n_elements( where( kidpar.type eq 1 and kidpar.array eq iarray)),2)
;; stop

;; message, /info, "fix me:"
;; w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
;; make_ct, nw1, ct
;; plot, data.toi[w1[0]], yra=minmax(data.toi[w1]), /ys
;; for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
;; stop

kidpar.f_tone = data[0].f_tone

;; The first and last 49 points are not well computed if we are in RF
;; => cut them out
;; if strupcase(param.math) eq "RF" then data = temporary( data[48:nsn-1-50])
if strupcase(param.math) eq "RF" then if not keyword_set( notruncate) then begin
   data = temporary( data[49:nsn-1-51])
   if defined(pipq) then pipq = pipq[*,49:nsn-1-51]
endif

;; message, /info, "fix me: return"
;; return

;; Flag out off resonance kids
if param.skydip eq 0 then begin
   ;; nk_acqflag2pipeflag deals with tunings via k_flag that is read from the
   ;; raw data.
   ;; Here, nk_outofres will look at the data to discard further ill behaving kids.
   nk_outofres, param, info, data, kidpar, verb =(param.silent eq 0), badkid=badkid
   w_type3 = where(min(data.flag, dimension=2) gt 0 and kidpar.type ne 2, c_type3);;; & print, c_type3
   if c_type3 gt 0 then kidpar[w_type3].type = 3
endif

;iarray = 2
;nk_plot_kid_vs_median, param, info, data, kidpar, iarray, comment="after outofres"

;; Resample the pointing with retard etc... (TBC)
nk_low_level_proc, param, info, data, kidpar, amp_modulation

;iarray = 2
;nk_plot_kid_vs_median, param, info, data, kidpar, iarray, comment="after low_level_proc", /stop

;; print, '9'
;; for iarray=1, 3 do print, "A"+strtrim(iarray,2)+": "+strtrim(n_elements( where( kidpar.type eq 1 and kidpar.array eq iarray)),2)
;; stop

;; FXD 22/2/2018: reinstate the common glitch and jump flagging
; just an option (use only for offline processing)

;; wind, 1, 1, /free, /large
;; my_multiplot, 3, 2, pp, pp1, /rev
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    make_ct, nw1, ct
;;    plot, data.toi[w1[0]], /xs, yra=array2range(data.toi[w1]), /ys, $
;;          position=pp[iarray-1,0,*], /noerase
;;    for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
;; endfor
;; 
if keyword_set( param.k_find_jumps) then nk_find_jumps, param, info, data, kidpar   

;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    make_ct, nw1, ct
;;    plot, data.toi[w1[0]], /xs, yra=array2range(data.toi[w1]), /ys, $
;;          position=pp[iarray-1,1,*], /noerase
;;    for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
;; endfor
;; stop
;; 
;; Update kidpar but preserve "off" information
nkids = n_elements(kidpar)
;;;for ikid=0, nkids-1 do begin
;;;   if min(data.flag[ikid]) gt 0 and kidpar[ikid].type ne 2 then begin
;;;      kidpar[ikid].type = 3
;      print, "ikid: ", ikid
;      stop
;;;   endif
;;;endfor
;;; HR 23/11/2016 to remove unnecessary loop on detectors

;;-----------
;;; message, /info, "fix me: uncomment next two lines (k_flags new def)"
w_type3 = where(min(data.flag, dimension=2) gt 0 and kidpar.type ne 2, c_type3) ;;; & print, c_type3
if c_type3 gt 0 then kidpar[w_type3].type = 3

w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   message, /info, "No kid has type=1. They may all have been considered to saturate."
   message, /info, "if not true, then set param.flag_sat, param.flag_oor, param.flag_ovlap to 0 and relaunch"
   nk_error, info, "No kid has type=1. They may all have been considered to saturate, or out-of-resonance or overlapping..."
   return
endif

;; there will be filtering if we do polarization, so optimize this
if info.polar eq 1 then param.fourier_opt_sample = 1

if param.fourier_opt_sample and (not keyword_set(notruncate)) then begin
   ;;Ensure that data has a convenient number of samples for FFT's
   nsn     = n_elements(data)
   nsn_max = test_primenumber(nsn)
   data    = temporary( data[0:nsn_max-1])
   if defined(pipq) then pipq = pipq[*,0:nsn_max-1]
   if defined(xoff) then xoff = xoff[*,0:nsn_max-1]
endif
;; stop, 'after fourier'
;; Deal with holes in Run9 data
if param.treat_data_holes ne 0 then nk_remove_data_holes, param, info, data, kidpar

info.elev  = median(data.el*!radeg)
info.paral = median(data.paral*!radeg)
info.lst   = median(data.lst)

;; Monitor number of valid kids per box
letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', $
          'q', 'r', 's', 't', 'u']
;;for ibox=0, n_elements(letter)-1 do begin
;;for iii=0, n_elements(letter)-1 do begin
for ibox=min(kidpar.acqbox), max(kidpar.acqbox) do begin
   ;; make sure the index is right independtly of acqbox starting from
   ;; 0 or 1. NP, Nov. 6th, 2020
   wbox = where( kidpar.acqbox eq ibox+1, nwbox)
   w1   = where( kidpar.acqbox eq ibox+1 and kidpar.type eq 1, nw1)
;;   w = where( strupcase(tag_names(info)) eq 'FRAC_VALID_KIDS_BOX_'+strupcase(letter[ibox-1]), nw)
   w = where( strupcase(tag_names(info)) eq 'FRAC_VALID_KIDS_BOX_'+strupcase(letter[ibox-min(kidpar.acqbox)]), nw)
   if nw ne 0 then info.(w) = float(nw1)/nwbox
endfor

;; fraction of kids valid per array
for iarray=1, 3 do begin
   warray = where( kidpar.array eq iarray and kidpar.type ne 2, nwarray)
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   frac = float(nw1)/nwarray*100
   w = where( strupcase(tag_names(info)) eq "FRAC_VALID_KIDS_ARRAY_"+strtrim(iarray,2), nw)
   if nw ne 0 then info.(w) = frac
endfor

;; Put the monitoring here to have it each time and ASAP in Real time
if (param.rta or param.show_monitoring) and param.do_plot then begin
;;    nk_monitoring_plots, param, info, data, kidpar, $
;;                         ikid=where(kidpar.numdet eq !nika.ref_det[0]), $
;;                         hwp_motor_position=hwp_motor_position, pipq=pipq

   nk_monitoring_plots_2, param, info, data, kidpar, $
                          ikid=where(kidpar.numdet eq !nika.ref_det[0]), $
                          hwp_motor_position=hwp_motor_position, pipq=pipq
;;    if param.do_rfpipq eq 1 then begin
;;       data.toi *= pipq
;;       nk_monitoring_plots, param, info, data, kidpar, $
;;                            ikid=where(kidpar.numdet eq !nika.ref_det[0]), $
;;                            hwp_motor_position=hwp_motor_position, pipq=pipq
;;    endif
endif

if param.switch_rf_didq_sign eq 1 then data.toi = -data.toi

;; Gather info for the final .fits
info.nsubscans = max(data.subscan)-min(data.subscan) + 1
info.az_source = median( data.az)
info.el_source = median( data.el)

if param.cpu_time then begin
   param.cpu_t0 = cpu_t0_getdata
   nk_show_cpu_time, param
endif

end
