; Run each part independtly with
 khelp = 1   ; Testing or
; khelp = 0   ; running
; .r n2cls_run3
;----------------------------------------------------------------
; ---------------------------- FINAL Scripts for LAM


;-------------------- GOODSNORTH -------------------------
; -----------------
; Part 1
; -----------------

source = 'GOODSNORTH'
mapreso = 2.
mapxsize = 24.*60
mapysize = 24.*60
method_num = '120'
ext = 'imcmcall'
version = 'LA'
scan= nk_get_source_scanlist(source, nscan) ; 468
scanlist = scan.day + 's' + strtrim(scan.scannum,2)
param_modifier = ['split_horver = 1',  $
                  'snr_iter_arr=[ 10, 10, 5, 5]', $
                  'atmb_accelsm=23', 'niter_atm_el_box_modes=1'] ; quick and dirty parameters
iter_min = 0
iter_max = 0
nharm1 = 2
nharm2 = 2
mapra    = 189.22372D0   ;scan[0].ra_deg
mapdec   = 62.238220D0   ;scan[0].dec_deg
silent = 0
k_help = khelp
imcmcall, source, $
          mapra, mapdec, $
          mapxsize, mapysize, mapreso, $
          method_num, ext, version, $
          scanlist, $
          iter_min,  iter_max, $
          nharm1 = nharm1, nharm2 = nharm2, $
          help = k_help, silent= silent, $
          infout = info_all, /pdf, $
          param_modifier = param_modifier, /defilter
; LA is quick and dirty (to evaluate criteria and preprocess the data)

; -----------------
; Part 2
; -----------------
source = 'GOODSNORTH'
method_num = '120'
ext = 'imcmcall'
mapreso = 2.
mapxsize = 24.*60
mapysize = 24.*60
version = 'LD'
scan= nk_get_source_scanlist(source, nscan)
scanlist = scan.day + 's' + strtrim(scan.scannum,2)
iter = 0
root_dir = !nika.save_dir+ext+'/'+source+'/'+strtrim(method_num, 2)
imcmcall_info, root_dir+'/iter'+strtrim(iter,2), $
               source, method_num, ext, 'LA', info_all, scanlist, $
               /chrono  ; Should be the version run in the previous batch
; Selection criteria applied here:
if defined( info_all) then begin
   a = where( info_all.result_tau_3 gt 0.7 or $
           info_all.result_valid_obs_time lt 300., na, compl = good)
   print, na, ' are bad'
   scanlist = info_all[ good].scan ; 395 good scans
endif
param_modifier = ['snr_iter_arr=[ 10, 10, 6, 4, 4]']
iter_min = 0  
iter_max = 4
filt_time1 = 3.                 ; 3 seconds where noise is white
filt_time2 = 3.
mapra    = 189.22372D0   ;scan[0].ra_deg
mapdec   = 62.238220D0   ;scan[0].dec_deg
silent = 0
k_help = khelp
imcmcall, source, $
          mapra, mapdec, $
          mapxsize, mapysize, mapreso, $
          method_num, ext, version, $
          scanlist, $
          iter_min,  iter_max, $
          filt_time1 = filt_time1, filt_time2 = filt_time2, $
          /defilter,  help = k_help, silent= silent, $
          infout = info_all, /pdf, $
          param_modifier = param_modifier
stop


;;; End of GoodsNorth



;-------------------- COSMOS -------------------------
; -----------------
; Part 1
; -----------------
source = 'COSMOS'
mapreso = 2.
mapxsize = 37.*60
mapysize = 45.*60
method_num = '120'
ext = 'imcmcall'
version = 'LA'
scan= nk_get_source_scanlist(source, nscan) ;257 old:223!
scanlist = scan.day + 's' + strtrim(scan.scannum,2)
param_modifier = ['split_horver = 1',  $
                  'snr_iter_arr=[ 10, 10, 5, 5]', $
                  'atmb_accelsm=23', 'niter_atm_el_box_modes=1'] ; quick and dirty parameters
iter_min = 0
iter_max = 0
nharm1 = 2
nharm2 = 2
mapra    = 150.12005  ;scan[0].ra_deg
mapdec   = 2.2417884  ; scan[0].dec_deg
silent = 0
k_help = khelp
imcmcall, source, $
          mapra, mapdec, $
          mapxsize, mapysize, mapreso, $
          method_num, ext, version, $
          scanlist, $
          iter_min,  iter_max, $
          nharm1 = nharm1, nharm2 = nharm2, $
          help = k_help, silent= silent, $
          infout = info_all, /pdf, $
          param_modifier = param_modifier, /defilter
; LA is quick and dirty (to evaluate criteria and preprocess the data)

; -----------------
; Part 2
; -----------------
source = 'COSMOS'
method_num = '120'
ext = 'imcmcall'
mapreso = 2.
mapxsize = 37.*60
mapysize = 45.*60
version = 'LD'
scan= nk_get_source_scanlist(source, nscan) ;257 old:223!
scanlist = scan.day + 's' + strtrim(scan.scannum,2)
iter = 0
root_dir = !nika.save_dir+ext+'/'+source+'/'+strtrim(method_num, 2)
imcmcall_info, root_dir+'/iter'+strtrim(iter,2), $
               source, method_num, ext, 'LA', info_all, scanlist, $
               /chrono ; Should be the version run in the previous batch
if defined( info_all) then begin
   a = where( exp(info_all.result_tau_3/ $
                  sin(info_all.result_elevation_deg*!dtor)) gt 1.9 or $
           info_all.result_valid_obs_time lt 600. or $ ; eliminate one anomalous scan
           info_all.result_valid_obs_time gt 1000. , $ ; eliminate first scan
           na, compl = good) & print, na, ' are bad'
   scanlist = info_all[ good].scan ; 226 out of 257
endif
param_modifier = ['snr_iter_arr=[ 10, 10, 6, 4, 4]']
iter_min = 0
iter_max = 4
filt_time1 = 3.                 ; 3 seconds where noise is white
filt_time2 = 3.
mapra    = 150.12005  ;scan[0].ra_deg
mapdec   = 2.2417884  ; scan[0].dec_deg
silent = 0
k_help = khelp
imcmcall, source, $
          mapra, mapdec, $
          mapxsize, mapysize, mapreso, $
          method_num, ext, version, $
          scanlist, $
          iter_min,  iter_max, $
          filt_time1 = filt_time1, filt_time2 = filt_time2, $
          /defilter, help = k_help, silent= silent, $
          infout = info_all, /pdf, $
          param_modifier = param_modifier

; End of COSMOS !


end
