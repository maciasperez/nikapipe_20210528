;; From NP/Nika2Run1/define_geometry_fast.pro
;; Nov. 24th, 2015
;;-----------------------------------------------

pro make_geometry

;; Recompute the kidpar that gave the wrong grid_step (see mails with
;; Laurence and Fred)
;; scan_list = '20151102s'+strtrim([16, 17, 18], 2)
;; black_list = [917, 1289, 1295, 1298, 1379, 1383, $
;;               1402, 1406, 1407, 1410, 1415, 1470, $
;;               1471, 1474, 1484, 1527, $
;;               6,  7,  9,  11,  19,  26,  31,  34,  40,  52,  54,  58,$
;;               62,  88,  108,  114,  119,  123,  131,  132,  138,  144, $
;;               178,  181,  187,  195,  197,  204,  205,  246,  248,  251, $
;;               254,  255,  258,  262,  265,  268,  273,  325,  336,  347, $
;;               348,  351,  356,  358,  406,  411,  419,  420,  430,  437, $
;;               445,  455,  469,  485,  506,  512,  518,  521,  522,  531, $
;;               537,  572,  577,  578,  579,  586,  590,  599,  605,  647, $
;;               654,  657,  662,  663,  665,  667,  671,  685,  725,  734, $
;;               807,  808,  811,  818,  819,  825,  836,  841,  853,  856, $
;;               863,  872,  899,  903,  918,  927,  928,  930,  931,  942, $
;;               974,  986,  990,  1014,  1047,  1612,  1613,  1614,  1615, $
;;               1616,  1617,  1847,  1848,  1853,  1854,  1857,  1861,  1862, $
;;               1863,  1864,  1865,  1866,  2008,  2009,  2010,  2011,  2012, $
;;               2014,  2249,  2252,  2254,  2255,  2256,  2257,  2259,  2260, $
;;               2261,  2262,  2263,  2267,  3949, $
;;               427,  438,  447,  454,  458,  463,  467,  474,  488,  496,  508,  $
;;               516,  527,  538,  542,  566,  574,  645,  679,  692,  813,  820,  821,  $
;;               823,  828,  833,  839,  850,  855,  861,  862,  888,  902,  910,  913,  922,$
;;               924,  937,  965,  970,  976,  977,  980,  984,  1000,  1001,  1045,  1062,  1065,  1066,$
;;               1076,  1080,  1210,  1215,  1218,  1219,  1224,  1228,  1239,  1241,  1246,  1249,  1252, $
;;               1253,  1261,  1262,  1272,  1287,  1320,  1321,  1329,  1331,  1366,  1368,  1375,  1376,  1378,  1381, $
;;               1382,  1389,  1392,  1393,  1397,  1399,  1401,  1403,  1404,  1408,  1411,  1412,  1417,$
;;               1445,  1447,  1449,  1452,  1453,  1457,  1458,  1461,  1466,  1467,  1468,  1473,  1482,  1487,$
;;               1528,  1529,  1531,  1705,  1707,  1708,  1709,  1765,  1766,  2090,  2105,  2106,  2107,  2108,  2109,$
;;               2165,  2166,  2167,  2168,  2169,  2170,  2339,  2340,  2341,  3285]

;; delvarx, black_list
;; ;;---------
;; scan_list = '20151027s'+strtrim([101, 102, 103], 2)
;; skydip_scan = '20151031s4'      ; Xavier's mail, Nov. 19th, 2015
;; 
;;---------
scan_list = '20151106s'+strtrim([211, 213, 215], 2)
skydip_scan = '20151106s171'      ; Xavier's mail, Nov. 19th, 2015
black_list = [ 3526, 1777, 525, 194, 684, 1462, 1481, 2978, 2989, 3126, 3134, 3688]
!nika.plot_dir = '/home/observer/NIKA/Plots/Run13'

;; ;;---------Only 12 h after the begining of run 14 !NIKA2 rules!
;; scan_list = '20151124s'+strtrim([170, 171, 172], 2)
;; skydip_scan = '20151125s7'   
;; 
;; ;;--------- Second useful geometry (less valid KIDs at 2 mm)
;; scan_list = '20151126s'+strtrim([93, 94, 95], 2)
;; skydip_scan = '20151126s98'
;; 
;; ;;---------
;; scan_list = '20151129s'+strtrim([227, 228, 229], 2)
;; skydip_scan = '20151126s98'


ptg_numdet_ref = 830
reso = 8.d0
;el_margin_top    = 0 ; 20 ; 10.d0 ; 5.d0
;el_margin_bottom = 0 ; 20 ; 10.d0 ; 5.d0

ofs_el_1 = -100
ofs_el_2 = 80
ofs_el_min = [     -400, ofs_el_1, ofs_el_2]
ofs_el_max = [ ofs_el_1, ofs_el_2,      400]

iteration  = 1
;; prepare the timeline
process    = 0
;; compute the maps for each KID
maps       = 0
;; Add skydip coeffs at the second iteration
add_skydip = 1

;pro define_geometry_fast, scan_list, skydip_scan, ptg_numdet_ref, $
;                          iteration = iteration, reso=reso, process = process, maps = maps

if not keyword_set(reso) then reso = 8.d0
if not keyword_set(iteration) then iteration = 1
  
nproc = 16

;; Concatenate "scan_list" into "nickname" to name the final kidpar
nscans = n_elements(scan_list)
if nscans eq 1 then begin
   nickname = strtrim(scan_list[0], 2)
endif else begin
   nickname = strmid(scan_list[0], 0, 9)
   for iscan = 0, n_elements(scan_list)-2 do begin
      l = strlen(scan_list[iscan])
      nickname += strmid( scan_list[iscan], 9, l-9)+"_"
   endfor
   l = strlen(scan_list[iscan])
   nickname +=  strmid( scan_list[iscan],  9,  l-9)
endelse

keep_neg = 0

beam_maps_dir      = !nika.plot_dir+'/Beam_maps_reso_'+strtrim(reso, 2)
toi_dir            = beam_maps_dir+"/TOIs"
maps_output_dir    = beam_maps_dir+"/Maps"
kidpars_output_dir = beam_maps_dir+"/Kidpars"

if iteration eq 1 then begin

   if process eq 1 then $
      beam_maps_toi_proc, scan_list, toi_dir, nproc, input_kidpar_file = input_kidpar_file

   ;; DO NOT RUN compute_kid_maps_2 UNDER VNC (split_fot crashes it)
   if maps eq 1 then $
      compute_kid_maps_2, scan_list, nproc, toi_dir, maps_output_dir, kidpars_output_dir,   $
                          noplot = noplot,  $
                          input_kidpar_file = input_kidpar_file, reso = reso
   
   ;; Merge the kidpars from the 16 processess for each scan
   version = 0
   nostop  = 0
   raw     = 1
   merge_sub_kidpars, scan_list, kidpars_output_dir, nproc, nostop=nostop, version=version, raw=raw
   
   ;; Merge the complete kidpars of each scan
   kidpar_list = "kidpar_"+scan_list+"_noskydip.fits"
   merge_scan_kidpars, scan_list, kidpar_list, nickname, $
                       ptg_numdet_ref=ptg_numdet_ref, nostop=nostop, $
                       version=version, ofs_el_min=ofs_el_min, ofs_el_max=ofs_el_max, black_list=black_list

   message, /info, "Now check you're under VNC or X2GO to run the widgets"
   message, /info, "If yes, press .c, otherwise reconnect and relaunch."
   stop
   
   ;; Now kill remaining "doubles"
   kid_selection, scan_list, maps_output_dir, kidpars_output_dir, $
                  iter = iter, keep_neg = keep_neg, $
                  input_kidpar_file = 'kidpar_'+nickname+'_noskydip.fits'
stop
   ;; Merge the new improved kidpars (this time, not /raw !)
   version = 1
   nostop = 1
   merge_sub_kidpars, scan_list, kidpars_output_dir, nproc, nostop=nostop, version=version

   ;; Merge the complete kidpars of each scan
   kidpar_list = "kidpar_"+scan_list+"_noskydip_v"+strtrim(version, 2)+".fits"
   merge_scan_kidpars, scan_list, kidpar_list, nickname, ptg_numdet_ref = ptg_numdet_ref, nostop = nostop, version = version, $
                        ofs_el_min=ofs_el_min, ofs_el_max=ofs_el_max, black_list=black_list
endif

stop
if iteration eq 2 then begin

   delvarx, param, info, kidpar, data, input_kidpar_file, noplot
   input_kidpar_file = "kidpar_"+nickname+"_noskydip_v1.fits"

   ;; Add skydip coeffs
   if add_skydip eq 1 then begin
      scan2daynum, skydip_scan, dd, ss
      nk_default_param, param
      nk_default_info, info
      nk_skydip_4, ss, dd, param, info, kidpar, data, $
                   input_kidpar_file = "kidpar_"+nickname+"_noskydip.fits"
      nk_write_kidpar, kidpar, !nika.off_proc_dir+"/kidpar_"+nickname+"_WithC0C1.fits"
   endif
   
   input_kidpar_file = !nika.off_proc_dir+"/kidpar_"+nickname+"_WithC0C1.fits"
   if file_test(input_kidpar_file) eq 0 then begin
      message, /info, "You need to add skydip coeffs for the second iteration"
      message, /info, "Make sure about skydip_scan, set add_skydip to 1 and relaunch."
      return
   endif
    
   toi_dir            = beam_maps_dir+"/TOIs_kidsout"
   maps_output_dir    = beam_maps_dir+"/Maps_kidsout"
   kidpars_output_dir = beam_maps_dir+"/Kidpars_kidsout"

   if process eq 1 then $
      beam_maps_toi_proc, scan_list, toi_dir, nproc, input_kidpar_file = input_kidpar_file, /kids_out
   
   ;; DO NOT RUN compute_kid_maps_2 UNDER VNC (split_fot crashes it)
   if maps eq 1 then $
      compute_kid_maps_2, scan_list, nproc, toi_dir, maps_output_dir, kidpars_output_dir,   $
                          noplot = noplot,  $
                          input_kidpar_file = input_kidpar_file, reso = reso, /kids_out

   ;; Merge the kidpars from the 16 processess for each scan
   version = 2
   merge_sub_kidpars, scan_list, kidpars_output_dir, nproc, /nostop, version=version, /raw

   ;; Merge the complete kidpars of each scan
   kidpar_list = "kidpar_"+scan_list+"_noskydip_v"+strtrim(version,  2)+".fits"
   merge_scan_kidpars, scan_list, kidpar_list, nickname, ptg_numdet_ref = ptg_numdet_ref, nostop = nostop, version = version
   spawn, "mv kidpar_"+nickname+"_noskydip_v2.fits kidpar_"+nickname+"_v2.fits"

endif

end
