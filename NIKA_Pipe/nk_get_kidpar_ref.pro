
;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; NAME:
; nk_get_kidpar_ref
;
; PURPOSE: 
;        This reads the correct focal plane geometry relevant to a given scan
; 
; INPUT: 
;        - scan_num: The list of scan number to be used as an int vector
;        e.g. [24, 25, 26]
;        - day: The list of corresponding days to be used as an int vector
;        e.g. [20140221, 20140221, 20140221]
; 
; OUTPUT: 
;        - kidpar_file: the list of KID parameter file to be used for
;          all scans
; 
; KEYWORDS:
;        /noread: do not read the kidpar fits file
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from get_kidpar_ref.pro 
;        (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;        - 23/03/2018: FXD add the corr_file feature

pro nk_get_kidpar_ref, scan_num, day, info, kidpar_file, $
                       corr_file = corr_file, $
                       scan=scan, kidpar = kidpar, noread = noread
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_get_kidpar_ref'
   return
endif

if keyword_set(scan) then scan2daynum, scan, day, scan_num

nscan = n_elements(scan_num)
if nscan ne n_elements(day) then message, 'The given number of scans is not equal to the number of days'

kidpar_file = strarr(nscan)
corr_file = kidpar_file

for iscan = 0, nscan-1 do begin
   myday = long( day[iscan])
   myscan_num = scan_num[iscan]
   ;; Init to empty string for lab measurements
   file = ''
   cfile = ''
   
   ;;===================================================================================
   ;; Run5
   if myday lt 20121120 then begin
      file = !nika.off_proc_dir+"/Kidpar_avg_20121115_v3.fits"
      !nika.numdet_ref_1mm = -1
      !nika.numdet_ref_2mm = 453
   endif
   if myday ge 20121120 and myday le 20121126 then begin
      file = !nika.off_proc_dir+"/Kidpar_avg_20121120_v3.fits"
      !nika.numdet_ref_1mm = 8
      !nika.numdet_ref_2mm = 414
   endif
   
   ;;===================================================================================
   ;; Run6
   if myday ge 20130601 and myday le 20130629 then begin
      file = !nika.off_proc_dir+"/kidpar_ref_434pixref_bestscans_v4.fits"
      !nika.numdet_ref_1mm = 28
      !nika.numdet_ref_2mm = 434
   endif

   ;;===================================================================================
   ;; RunCryo                                                                                                          
   if myday ge 20131111 and myday le 20131116 then begin
      file = !nika.off_proc_dir+"/kidpar_ref_runcryo.fits"
      !nika.numdet_ref_1mm = 261
      !nika.numdet_ref_2mm = 569
   endif
   
   ;;===================================================================================
   ;; Run7
   if myday eq 20140120 then begin
      file = !nika.off_proc_dir+"/kidpar_20140120s205_v4.fits"
      !nika.numdet_ref_1mm = 32
      !nika.numdet_ref_2mm = 430
   endif
   if myday eq 20140121 then begin
      if myscan_num le 242 then begin
         ;; the exact limit of 242 will have to be confirmed.
         ;; kid validity must be the same as before but the focus was
         ;; different, so positions may have varied.
         file =  !nika.off_proc_dir+"/kidpar_20140120s205_v7.fits"
         !nika.numdet_ref_1mm = 32
         !nika.numdet_ref_2mm = 430
      endif else begin
         file =  !nika.off_proc_dir+"/kidpar_20140121s243_v7.fits"
         !nika.numdet_ref_1mm = 32
         !nika.numdet_ref_2mm = 430
      endelse
   endif
   if myday eq 20140122 then begin
      if myscan_num lt 89 then begin
         file =  !nika.off_proc_dir+"/kidpar_20140122s19_v7.fits"
         !nika.numdet_ref_1mm = 32
         !nika.numdet_ref_2mm = 430
      endif else begin
         file = !nika.off_proc_dir+"/kidpar_20140123s140_v7.fits"
         !nika.numdet_ref_1mm = 5
         !nika.numdet_ref_2mm = 494
      endelse
   endif
   if myday ge 20140123 then begin
      file = !nika.off_proc_dir+"/kidpar_20140123s140_v7.fits"
      !nika.numdet_ref_1mm = 5
      !nika.numdet_ref_2mm = 494
   endif

   ;;===================================================================================
   ;; Run8
   if myday ge 20140214 then begin
      ;; file = !nika.off_proc_dir+"/kidpar_20140219s205_v1.fits"
      file = !nika.off_proc_dir+"/kidpar_20140219s205_v2.fits"
      !nika.numdet_ref_1mm = 5
      !nika.numdet_ref_2mm = 494
   endif

   ;;===================================================================================
   ;; Run9
   if myday ge 20141007 and myday lt 20141012 then begin
      file = !nika.off_proc_dir+"/kidpar_20141010s182_v1.fits"
;;      ;----------------
;;      message, /info, "fix me:"
;;      file = "kidpar_2beams.fits"
;;      stop
;;      ;----------------
      
      !nika.numdet_ref_1mm = 32
      !nika.numdet_ref_2mm = 430
   endif
   if myday ge 20141012 and myday lt 20141107 then begin
      file = !nika.off_proc_dir+"/kidpar_20141013s32_v1.fits"
      !nika.numdet_ref_1mm = 32
      !nika.numdet_ref_2mm = 430
   endif      

   ;;===================================================================================
   ;; Run10
   if myday ge 20141107 and myday lt 20150123 then begin
      ;; early tests with the geometry derived during run9, recentered on det 494
      ;; file = !nika.off_proc_dir+"/kidpar_20141107s181.fits"
      ;; !nika.numdet_ref_1mm = 18
      ;; !nika.numdet_ref_2mm = 494

      ;; 1st clean geometry of Run10, no skydip coeffs yet
      ;; file = !nika.off_proc_dir+"/kidpar_20141109s198.fits"

                                ; Tuesday Nov. 18th, after df_tone reading was corrected by alain and Andrea
      ;; same offsets as kidpar_20141109s198.fits
      ;; file = !nika.off_proc_dir+"/kidpar_20141109s198_v5.fits"

      ;; Tuesday, April 28th, Xavier's estimation of df_tone and opacity
      ;; FR + NP
      file = !nika.off_proc_dir+"/kidpar_20141109s198_v7.fits"

      !nika.numdet_ref_1mm = 5
      !nika.numdet_ref_2mm = 494
   endif

   ;;===================================================================================
   ;; Run11 (open pool 3) and Run12 (Polarization run)
   if myday ge 20150123 then begin
      if myday lt 20150210 then myrun = 11
      if myday eq 20150210 then begin
         if myscan_num le 157 then begin
            ;; still openpool3
            myrun = 11
         endif else begin
            ;; Polarization run
            myrun = 12
         endelse
      endif
      if myday gt 20150210 then myrun=12
      
      if myrun eq 11 then begin
         ;; with nasmyth offsets to 0 for early alignements
                                ;file = !nika.off_proc_dir+"/kidpar_20150123s128_noSkydip.fits"
         
         ;; with nasmyth offsets to -4.4 18 to be centered on ref det 494
         ;;file = !nika.off_proc_dir+"/kidpar_20150123s137_noSkydip.fits"
         ;;file = !nika.off_proc_dir+"/kidpar_20150123s137.fits"
         
         ;; With Xavier's skydip coeffs and the absolute calibration recomputed
;;         if sqrt( info.nasmyth_offset_x^2 + info.nasmyth_offset_y^2) lt 1 then begin
;;            file = !nika.off_proc_dir+"/kidpar_20150123s128_v7.fits"
;;         endif else begin
         file = !nika.off_proc_dir+"/kidpar_20150123s137_v7.fits"
         file = !nika.off_proc_dir+"/kidpar_20150123s137_v8.fits"

;;         endelse
         
      endif
      if myrun eq 12 then begin
         ;;file = !nika.off_proc_dir+"/kidpar_20150211s205.fits"
         ;;file = !nika.off_proc_dir+"/kidpar_20150213s159_v1.fits"
         ;; file = !nika.off_proc_dir+"/kidpar_20150213s159_v2.fits"

         ;; Improved version, Sept. 9th, 2015, FXD and NP.
         file = !nika.off_proc_dir+"/kidpar_20150213s159_v4.fits"

         ;; added as place holder on June 11th, 2017 ! (NP)
         !nika.ref_det = [5, 494, 0]
         !nika.numdet_ref_1mm = 5
         !nika.numdet_ref_2mm = 94
      endif
   endif
   
   
   ;;=========================================================================================
   ;;====================================== NIKA2 ============================================
   ;;=========================================================================================
   if myday ge 20150901 then begin
      file = !nika.off_proc_dir+"/kidpar_20151015s154_155_156_noskydip_v3_NewConv.fits"
      !nika.ref_det = [2022, 830, 3057]
      !nika.numdet_ref_1mm = 2022
      !nika.numdet_ref_2mm = 830

      if myday ge 20151024 and myday le 20151026 then begin   
         ;; Improved absolute calibration based on Uranus 20151031s229
         file = !nika.off_proc_dir+"/kidpar_20151027s101_102_103_noskydip_v5_NewConv.fits"
         !nika.ref_det = [2022, 830, -1]
         !nika.numdet_ref_1mm = 2022
         !nika.numdet_ref_2mm = 830
      endif
      
      if myday eq 20151027 then begin         
         if myscan_num ge 120 and myscan_num le 134 then begin
            file = !nika.off_proc_dir+"/kidpar_20151027s126_127_128_v_flo_skydip_recal_NewConv.fits"
            !nika.ref_det = [485, -1, 1527]
            !nika.numdet_ref_1mm = 485
            !nika.numdet_ref_2mm = -1
         endif else begin
                                ; Improved absolute calibration based on Uranus 20151031s229
            file = !nika.off_proc_dir+"/kidpar_20151027s101_102_103_noskydip_v5_NewConv.fits"
            !nika.ref_det = [2022, 830, -1]
            !nika.numdet_ref_1mm = 2022
            !nika.numdet_ref_2mm = 830
         endelse
      endif

      if myday eq 20151028 then begin         
         if myscan_num ge 200 then begin
            file = !nika.off_proc_dir+"/kidpar_20151027s126_127_128_v_flo_skydip_recal_NewConv.fits"
            !nika.ref_det = [485, -1, 1527]
            !nika.numdet_ref_1mm = 485
            !nika.numdet_ref_2mm = -1
         endif else begin
                                ; Improved absolute calibration based on Uranus 20151031s229
            file = !nika.off_proc_dir+"/kidpar_20151027s101_102_103_noskydip_v5_NewConv.fits"
            !nika.ref_det = [2022, 830, -1]
            !nika.numdet_ref_1mm = 2022
            !nika.numdet_ref_2mm = 830
         endelse
      endif

      if myday eq 20151029 then begin         
         if myscan_num lt 200 then begin
            file = !nika.off_proc_dir+"/kidpar_20151027s126_127_128_v_flo_skydip_recal_NewConv.fits"
            !nika.ref_det = [485, -1, 1527]
            !nika.numdet_ref_1mm = 485
            !nika.numdet_ref_2mm = -1
         endif else begin
                                ; Improved absolute calibration based on Uranus 20151031s229
            file = !nika.off_proc_dir+"/kidpar_20151027s101_102_103_noskydip_v5_NewConv.fits"
            !nika.ref_det = [2022, 830, -1]
            !nika.numdet_ref_1mm = 2022
            !nika.numdet_ref_2mm = 830
         endelse
      endif
      
      if myday gt 20151029 and myday le 20151101 then begin         
                                ; Improved absolute calibration based on Uranus 20151031s229
         file = !nika.off_proc_dir+"/kidpar_20151027s101_102_103_noskydip_v5_NewConv.fits"
         !nika.ref_det = [2022, 830, -1]
         !nika.numdet_ref_1mm = 2022
         !nika.numdet_ref_2mm = 830
      endif
      
      if myday ge 20151102 then begin         
;;            file = !nika.off_proc_dir+"/kidpar_20151027s101_102_103_v4.fits"
;;            !nika.ref_det = [2022, 830, -1]
;;            !nika.numdet_ref_1mm = 2022
;;            !nika.numdet_ref_2mm = 830
;;
;;            file =  !nika.off_proc_dir+"/kidpar_20151102s16_17_18_noskydip.fits"
;;            ;; Not very satisfactory skydip coefficients included (FXD) tau too high
;;            file =  !nika.off_proc_dir+"/kidpar_20151102s16_17_18_v1.fits"
;;
;;            ;; New geometry, allowing negative calibration to
;;            ;; compensate the wrong sign in acquisition.
;;            ;; No skydip coeffs yet, NP. Oct. 3rd, 2015
;;            file = !nika.off_proc_dir+"/kidpar_20151102s16_17_18_noskydip_v2.fits"
         
         file = !nika.off_proc_dir+"/kidpar_20151102s16_17_18_noskydip_v4_NewConv.fits"
         !nika.ref_det =  [2022,  830,  2728]
         !nika.numdet_ref_1mm = 2022
         !nika.numdet_ref_2mm = 830
      endif
      
      if myday ge 20151106 and myday le 20151123 then begin
         ;;This geometry is good for a 13 e-boards configuration
         file = !nika.off_proc_dir+"/kidpar_20151106s211_213_215_v_flo_skydip_recal_NewConv.fits"
         !nika.ref_det =  [2022, 830, 3125]
         !nika.numdet_ref_1mm = 2022
         !nika.numdet_ref_2mm = 830
      endif

      ;; Run14
      if myday ge 20151124 and myday le 20160111 then begin
         file = !nika.off_proc_dir+"/kidpar_20151129s227_228_229_v_flo_skydip_recal_NewConv.fits"
         !nika.ref_det =  [3930, 830, 2583]
         !nika.numdet_ref_1mm = 2022
         !nika.numdet_ref_2mm = 830
      endif

      ;;----------------------------------------------------------------------------------------------------
      ;; Run15 (quick fix until we get a geometry)
      if myday ge 20160112 and myday le 20160116 then begin
         ;; file = !nika.off_proc_dir+"/kidpar_20160114s170_168_169_noskydip_v1bis.fits" ; no c0 c1 yet
         ;; !nika.ref_det =  [3133, 491, 6024]

         file = !nika.off_proc_dir+"/kidpar_20160116s216_217_218_noskydip_v1_NewConv.fits"
         !nika.ref_det =  [3640, 951, 7144]
         !nika.numdet_ref_1mm = 3133
         !nika.numdet_ref_2mm = 491
      endif
      
      if myday ge 20160117 and myday lt 20160118 then begin ;;Offset nasmyth: 23 -27 
         file = !nika.off_proc_dir+"/kidpar_20160116s216_217_218_noskydip_v1_NewConv.fits"
         !nika.ref_det =  [3640, 951, 7144]
         !nika.numdet_ref_1mm = 3640
         !nika.numdet_ref_2mm = 951
      endif

      if myday ge 20160118 and myday lt 20160119 then begin ;;Offset nasmyth: 33 -7
         file = !nika.off_proc_dir+"/kidpar_20160117s182_183_184_noskydip_v1_NewConv.fits"
         !nika.ref_det =  [3538, 860, 6485] 
         !nika.numdet_ref_1mm = 3538
         !nika.numdet_ref_2mm = 860
      endif 

      if myday ge 20160119 and myday le 20160121 then begin
         if scan_num le 74 then begin
            ;;Offset nasmyth shoul be 33 -7
            file = !nika.off_proc_dir+"/kidpar_20160118s117_118_119_noskydip_v1_NewConv.fits"
         endif else begin
            ;; offset nasmyth should be 0 0
            file = !nika.off_proc_dir+"/kidpar_20160118s117_118_119_noskydip_v1_newoffsets_NewConv.fits"
         endelse
         !nika.ref_det =  [3538, 860, 6485]
         !nika.numdet_ref_1mm = 3538
         !nika.numdet_ref_2mm = 860
      endif

      ;;----------------------------------------------------------------------------------------------------
      ;; NIKA2 Run4 = Run16
      if myday ge 20160121 and myday lt 20160922 then begin
         ;; offset nasmyth should be 0 0
                                ;file = !nika.off_proc_dir+"/kidpar_20160118s117_118_119_noskydip_v1_newoffsets.fits"
                                ;file = !nika.off_proc_dir+"/kidpar_20160122s80_81_82_noskydip_v1.fits"
                                ;file = !nika.off_proc_dir+"/kidpar_20160122s80_81_82_withskydip.fits"

                                ;file = !nika.off_proc_dir+"/kidpar_20160303s89_90_91_withskydip.fits"
         file = !nika.off_proc_dir+"/kidpar_20160127s202_203_204_3C84_MWC349.fits"

;;           message, /info, "fix me:"
;;           file = "kidpar_20160313s177_178_179_v2.fits"
;;           stop


         !nika.ref_det =  [3538, 860, 6485]
         !nika.numdet_ref_1mm = 3538
         !nika.numdet_ref_2mm = 860          
      endif

      ;;----------------------------------------------------------------------------------------------------
      ;; NIKA2 Run5 = Run18 (Run17 never happened)
      if myday ge 20160922 and myday lt 20161206 then begin
         
         config = 2
         if myday lt 20161006 then config = 1
         if myday eq 20161006 then begin
            if scan_num lt 199 then config=1 else config=2
         endif
         if myday ge 20161007 and myday lt 20161009 then config=2
         if myday eq 20161009 then begin
            if scan_num le 159 then config=2 else config=3
         endif
         if myday ge 20161010 then config = 3

         if config eq 1 then begin
            ;; 2nd approx geom on Neptune, box T is back and box Q has
            ;; been changed by hand to be placed correctly in Array3
            ;; until it is fixed in the param.ini
            file = !nika.off_proc_dir+"/kidpar_20160925s468_469_470_v0_WithCoeffSkydipRun4Array13_NewConv.fits"
            !nika.ref_det = [3538, -1, 6485]
         endif
         if config eq 2 then begin
            ;; file = !nika.off_proc_dir+"/kidpar_20161006s199_v0.fits"
            ;; file = !nika.off_proc_dir+"/kidpar_20161006s199_v0_ref3289.fits"
            file = !nika.off_proc_dir+"/kidpar_20161006s199_v0_ref3137_NewConv.fits"
            
            ;; modified ref_det to 863 and 6026, NP. Oct. 8th, 2016
            !nika.ref_det =  [3137, 823, 6026]
            !nika.numdet_ref_1mm = 3137
         endif
         if config eq 3 then begin
                                ;file = !nika.off_proc_dir+"/kidpar_20161010s19_v0.fits"
                                ;file = !nika.off_proc_dir+"/kidpar_20161010s19_v2_FR_rescale_calib.fits"
            file = !nika.off_proc_dir+"/kidpar_20161010s37_v3_skd8_match_calib_NP_recal_FR_NewConv.fits"
;; modified ref_det to 863 and 6026, NP. Oct. 8th, 2016
            ;; !nika.ref_det =  [3137, 823, 6026]
            ;; !nika.numdet_ref_1mm = 3137  ; is not alive
                                ; 30/10/2016 correction done
            ;; !nika.ref_det =  [3138, 823, 6026]
            ;;  !nika.numdet_ref_1mm = 3138
                                ; 1/11/2016 3138 has disappeared use 3136
            !nika.ref_det =  [3136, 823, 6026]
            !nika.numdet_ref_1mm = 3136
         endif
      endif

      ;; N2R7 = Run20, Dec. 6th to 13th 2016
      if myday ge 20161206 and myday le 20161214 then begin
         file = !nika.off_proc_dir+"/kidpar_20161010s37_v3_skd8_match_calib_NP_recal_FR_NewConv.fits"
         !nika.ref_det =  [3136, 823, 6026]
         !nika.numdet_ref_1mm = 3136
      endif

      ;; N2R8 = Run21, Jan. 24th to 31st 2017
      if myday ge 20170124 and myday le 20170126 then begin
         ;; kidpar produced using a single beammap of N2R8:
         ;; NB: C0, C1 coeff from a single skydip observed in good
         ;; weather condition: not expected to be accurate
         file = !nika.off_proc_dir+"/kidpar_20170125s223_v2_sk_20170124s189_NewConv.fits"
         !nika.ref_det =  [3136, 823, 6026]
         !nika.numdet_ref_1mm = 3136
      endif

      ;; N2R9 = Run22, Feb. 21st - 28th, 2017
      if myday ge 20170221 and myday le 20170228 then begin
         ;; kidpar produced using a single beammap of N2R8:
         ;; NB: C0, C1 coeff from a single skydip observed in good
         ;; weather condition: not expected to be accurate
         file = !nika.off_proc_dir+"/kidpar_20170125s223_v2_sk_20170124s189.fits"
         file = !nika.off_proc_dir+"/kidpar_skydip_n2r9_skd0.fits"
         ;; Early calibration
         file = !nika.off_proc_dir+"/kidpar_skydip_n2r9_skd1.fits"
         ;; skd1 resscaled by JFL's fluxes per array (Feb. 24th, 15h15)
         ;; file = !nika.off_proc_dir+"/kidpar_skydip_n2r9_skd2.fits"
         ;; file = '/mnt/data/NIKA2Team/NP/Plots/kidpar_N2R9.fits'
         ;; skd1 resscaled by JFL's fluxes per array
                                ;file = !nika.off_proc_dir+"/kidpar_skydip_n2r9_skd2.fits"
;;          file = "/mnt/data/NIKA2Team/NP/Plots/kidpar_N2R9.fits"
         
         ;; Using three "best" geometries to derive the
         ;; offsets and FXD's best C0-C1 coeffs, absolute
         ;; calibration on one scan of Uranus. NP, March. 16th, 2017.
         ;;file = !nika.off_proc_dir+"/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits"
                                ; FXD, March 2018, In order to produce
                                ; that cfile (which is linked to the
                                ; file above) use Scr/Reference/Photometry/
                                ;   make_pointing_corr_n2r9.pro
         cfile = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
                 'Log_Iram_corr_N2R9_v1.csv'


          ;; Baseline kidpar, 2018, June 27
          file = !nika.off_proc_dir+"/kidpar_N2R9_baseline_v1.fits"
          ;; Updated baseline kidpar, 2018, Oct 3rd
          file = !nika.off_proc_dir+"/kidpar_N2R9_baseline_v2.fits"
          ;; Updated baseline kidpar, 2020, Mar 6th
          file = !nika.off_proc_dir+"/kidpar_N2R9_baseline.fits"
          
          !nika.ref_det = [3136,823,6026]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

      ;; N2R10 = Run23, Apr. 18-25 2017
      ;; Same config as Run9
      if myday ge 20170414 and myday le 20170425 then begin
         ;; file = !nika.off_proc_dir+"/kidpar_best3files_FXDC0C1_GaussPhot.fits"
         ;;file = !nika.off_proc_dir+"/kidpar_n2r10_calib_NewConv.fits"
         ;;file = !nika.off_proc_dir+"/avg_kidpar_run10_BC_recal.fits"
         ;; Aug. 18th, 2017: new skydip coeffs from Xavier after
         ;; selection of the correct skydips:
         file = !nika.off_proc_dir+"/avg_kidpar_run10_BC_FXD_skd_recal.fits"
         !nika.ref_det = [3136,823,6026]
         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

      ;; N2R11 = Run24, June 8-13, 2017 POLAR
      ;; Same config as Run10
      if myday ge 20170606 and myday le 20170613 then begin
         file = !nika.off_proc_dir+"/kidpar_n2r10_calib_NewConv.fits"
         file = !nika.off_proc_dir+"/avg_kidpar_run10_BC_recal.fits"
         ;; 1st version with skydip coeffs (HWP is present hence
         ;; different C0 and C1 from those of last run)
         file = !nika.off_proc_dir+"/avg_kidpar_run10_BC_recal_skydip20170609.fits"
         !nika.ref_det = [3136, 823, 6026]
         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

      ;; N2R12 = Run25, Oct. 24th-31st, 1st science pool
      if myday ge 20171016 and myday le 20171031 then begin
         ;; 1st version for this run : all offsets come from
         ;; "avg_kidpar_run10_BC_recal_skydip20170609"
         ;; but the numdets have changed for the 2mm (e.g. 823 => 824)
         ;; No skydip coeffs yet, Friday Oct. 20th, 2017
         ;; file = !nika.off_proc_dir+"/kidpar_N2R12_v0.fits"
         ;; match observer branch
         ;; file = !nika.off_proc_dir+'/kidpar_20171025s42_v2_LP.fits'
         ;; First calib+skydip coefficients.
         ;; file = !nika.off_proc_dir+'/kidpar_20171022s158_v0_LP_skd_calUranus.fits'
         ;; FXD with Juan, better 2mm opacities
         ;;file = !nika.off_proc_dir+'/kidpar_20171022s158_v0_LP_skd_calUranusv2.fits'
         file = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_calUranus.fits'

         ;; Final kidpar from Laurence
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_calUranus.fits"

         ;; With correct Uranus flux, bug fixed, NP. Nov. 13th
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_calUranus_RecalNP.fits"

         ;; After discarding KIDs far from their designed position
         ;; (from FXD selection)
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_calUranus_RecalNP_md.fits"

         ;; recalibration using Uranus scans without any telescope
         ;; gain-elevation correction, LP, Nov. 16
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
         cfile = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
                 'Log_Iram_corr_N2R12_v0.csv'
         
         ;; analysis using 'COMMON_MODE_KIDS_OUT' decorrelation
         ;; method, LP, 14 December          
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"
                                ; FXD, March 2018, In order to produce
                                ; that cfile (which is linked to the
                                ; file above) use Scr/Reference/Photometry/
                                ;   make_pointing_corr_n2r12.pro
         cfile = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
                 'Log_Iram_corr_N2R12_v1.csv'

          ;; Baseline kidpar, 2018, June 27
          file = !nika.off_proc_dir+"/kidpar_N2R12_baseline_v1.fits"
          ;; Updated Baseline kidpar, 2018, Oct. 3rd
          file = !nika.off_proc_dir+"/kidpar_N2R12_baseline_v2.fits"
          ;; Updated baseline kidpar, 2020, Mar 6th
          file = !nika.off_proc_dir+"/kidpar_N2R12_baseline.fits"
          ;; Updated baseline kidpar, 2020, April
          file = !nika.off_proc_dir+"/kidpar_N2R12_baseline_LP.fits"
          
          !nika.ref_det = [3138,824,6027]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

      ;; N2R13 = Run26, Nov. 17th - Nov. 28th, 2nd pol. tech time, 1st
      ;;                            polarization comissioning run
      if myday ge 20171117 and myday le 20171128 then begin
         ;; Start with the kidpar from last run
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
         !nika.ref_det = [3138,824,6027]

         ;; Kidpar derived for this run, 2 skydips accounted for and
         ;; recalibrated using all the scans on Mars so far (but the
         ;; beammaps)
         file = !nika.off_proc_dir+"/kidpar_20171120s91_v2_SkdMarsRecal.fits"
         ;; changing ref_det for A1
         !nika.ref_det = [3137,824,6027]
         
         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

       ;; N2R14 = Run27, Jan. 13th - Jan. 23rd, 2018: 2nd science pool
       if myday ge 20180101 and myday le 20180123 then begin
          ;; file =
          ;; !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"
          ;;file =
          ;;!nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
          ;; Baseline kidpar, 2018, June 27
          file = !nika.off_proc_dir+"/kidpar_N2R14_baseline_v1.fits"
          ;; Updated Baseline kidpar, 2018, Oct. 3rd
          file = !nika.off_proc_dir+"/kidpar_N2R14_baseline_v2.fits"
          ;; Updated baseline kidpar, 2020, Mar 6th
          file = !nika.off_proc_dir+"/kidpar_N2R14_baseline.fits"
          ;; Updated baseline kidpar, 2020, April 30th
          file = !nika.off_proc_dir+"/kidpar_N2R14_baseline_LP.fits"
          
          !nika.ref_det = [3137,824,6027]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

      ;; N2R15 = Run28, Feb. 13th - Feb. 20th: 3rd science pool
      ;; Init with R14 values as usual
      if myday ge 20180213 and myday le 20180220 then begin
         ;;file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"
         ;; new kidpar by Bilal using baseline calibration
         ;;file = !nika.off_proc_dir+"/kidpar_20180219s170_v2_skd_BL.fits"
         file = !nika.off_proc_dir+"/kidpar_N2R15_baseline.fits"
         ;; updated with last version of the baseline kidpar
         file = !nika.off_proc_dir+"/kidpar_N2R15_baseline_JFMP.fits"
         !nika.ref_det = [3137,824,6027]
         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

      ;; N2R16 = Run29, Mar. 2nd - Mar. 13th (morning): 3rd
      ;;                           polarization tech run.
      ;; Init with R15 values as usual
      if myday ge 20180302 and myday le 20180312 then begin
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"
         ;; file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
         !nika.ref_det = [3137,824,6027]
         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

      ;; N2R17 = Run30, Mar. 13th-Mar20th
      ;; 4th science pool
      if myday ge 20180313 and myday le 20180330 then begin
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"
         ;; file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
         !nika.ref_det = [3137,824,6027]
         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

;;      ;; N2R18 = Run31, May. 22nd-29th
;;      ;; 5th science pool
;;      if myday ge 20180522 then begin
;;         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"
;;         ;; file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
;;         !nika.ref_det = [3137,824,6027]
;;         !nika.numdet_ref_1mm = !nika.ref_det[0]
;;         !nika.numdet_ref_2mm = !nika.ref_det[1]
;;      endif

      ;; N2R18 = Run31, May. 22nd-29th
      ;; 5th science pool
      if myday ge 20180522 and myday le 20180529 then begin
         file = !nika.off_proc_dir+"/kidpar_N2R18_baseline_JFMP.fits"
         ;;file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"
         ;; file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
         !nika.ref_det = [3137,824,6027]
         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

      ;; N2R19 = Run32, June. 08 to 19 2018
      ;; Polarization tech run
      if myday ge 20180608 and myday le 20180619 then begin
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"
         ;; file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
         !nika.ref_det = [3137,824,6027]
         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

      ;; N2R20 = Run33-34, Sept. 2018
      ;; short dichroic and polarization technical run
      if myday ge 20180904 and myday le 20180906 then begin
         file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"

         !nika.ref_det = [3137,824,6027]
         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

       ;; N2R21 = Run35, Sept. 2018
       ;; old dichroic recheck and polarization technical run
       if myday ge 20180918 and myday le 20180925 then begin
          file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_kids_out.fits"
          ;; file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
          !nika.ref_det = [3137,824,6027]
          
          ;; Copied all information on 1mm pixels from the ref kidpar,
          ;; updated those on the 2mm pixels with the new beammap
          file = !nika.off_proc_dir+"/kidpar_20180919s9_v0_merged_kidpar_20171025s41_v2_LP_skd_kids_out.fits"
          !nika.ref_det = [3137,823,6026]

         !nika.numdet_ref_1mm = !nika.ref_det[0]
         !nika.numdet_ref_2mm = !nika.ref_det[1]
      endif

       ;; N2R22 = Run36, 2nd-9th Oct. 2018 science pool
       if myday ge 20181001 and myday le 20181009 then begin
          ;; Copied all information on 1mm pixels from the ref kidpar,
          ;; updated those on the 2mm pixels with the new beammap
          file = !nika.off_proc_dir+"/kidpar_20180919s9_v0_merged_kidpar_20171025s41_v2_LP_skd_kids_out.fits"
          !nika.ref_det = [3137,823,6026]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       ;; N2R23 = Run37, Oct. 30th - Nov. 6th science pool
       if myday ge 20181029 and myday le 20181118 then begin
          ;; Copied all information on 1mm pixels from the ref kidpar,
          ;; updated those on the 2mm pixels with the new beammap
          ;;file = !nika.off_proc_dir+"/kidpar_20180919s9_v0_merged_kidpar_20171025s41_v2_LP_skd_kids_out.fits"
          ;; BL&LP : update using candidate reference kidpar made by
          ;; BL, abs. calib. checked by LP
          ;; file = !nika.off_proc_dir+"/kidpar_N2R23_ref_baseline_BL.fits"
          file = !nika.off_proc_dir+"/kidpar_N2R23_baseline_JFMP.fits"

          !nika.ref_det = [3137,823,6026]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       ;; N2R24 = Run38, Nov. 20th - Nov. 27th science pool
       if myday ge 20181119 and myday le 20181127 then begin
          ;; Copied all information on 1mm pixels from the ref kidpar,
          ;; updated those on the 2mm pixels with the new beammap
          ;;file =
          ;;!nika.off_proc_dir+"/kidpar_20180919s9_v0_merged_kidpar_20171025s41_v2_LP_skd_kids_out.fits"

          ;; BL&LP : update using candidate reference kidpar made by BL
          ;;file = !nika.off_proc_dir+"/kidpar_N2R24_ref_baseline_BL.fits"
          file = !nika.off_proc_dir+"/kidpar_N2R24_baseline_hybrid.fits"
          
          !nika.ref_det = [3137,823,6026]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       ;; N2R25 = Run39, Dec. 4th - Dec. 11th 2018: Polarization
       if myday ge 20181203 and myday le 20181211 then begin
          ;; Same kidpar as for the previous run
          ;; BL&LP : update using candidate reference kidpar made by BL
          ;; file = !nika.off_proc_dir+"/kidpar_N2R23_ref_baseline_BL.fits"
          file = !nika.off_proc_dir+"/kidpar_N2R25_ref_baseline.fits"
          
          !nika.ref_det = [3137,823,6177]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       ;; N2R26 = Run40, Jan. 15th-22nd : Total power pool
       if myday ge 20190114 and myday le 20190122 then begin
          ;; BL&LP : update using candidate reference kidpar made by BL
          ;;file = !nika.off_proc_dir+"/kidpar_N2R26_ref_baseline_BL.fits"
          file = !nika.off_proc_dir+"/kidpar_N2R26_baseline_JFMP.fits"

          !nika.ref_det = [3137,823,6177]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       ;; N2R27 = Run41, Jan. 29th-Feb. 6th, 2019: total power pool
       if myday ge 20190129 and myday le 20190205 then begin
          ;; BL&LP : update using candidate reference kidpar made by BL
          file = !nika.off_proc_dir+"/kidpar_N2R27_ref_baseline_BL.fits"
          !nika.ref_det = [3137,823,6177]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       ;; N2R28 = Run42, Feb. 12th-19th, 2019: total power pool
       if myday ge 20190212  and myday le 20190219 then begin
          ;; BL&LP : update using candidate reference kidpar made by BL
          ;;file = !nika.off_proc_dir+"/kidpar_N2R28_ref_baseline_BL.fits"
          file = !nika.off_proc_dir+"/kidpar_N2R28_baseline_JFMP.fits"
          !nika.ref_det = [3137,823,6177]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       ;; N2R29 = Run43, Mar. 05th-12th, 2019: total power pool
       if myday ge 20190305  and myday le 20190312 then begin
          ;; BL&LP : update using candidate reference kidpar made by BL
          ;;file = !nika.off_proc_dir+"/kidpar_N2R29_ref_baseline_BL.fits"
          file = !nika.off_proc_dir+"/kidpar_N2R29_baseline_JFMP.fits"

          !nika.ref_det = [3137,823,6177]
          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       ;; N2R30 = Run44, Mar. 19th-26th, 2019: total power pool
       if myday ge 20190319 and myday le 20190321 then begin
          ;; BL&LP : update using candidate reference kidpar made by BL
            ;;file = !nika.off_proc_dir+"/kidpar_N2R29_ref_baseline_BL.fits"
            file = !nika.off_proc_dir+"/kidpar_N2R30_baseline_JFMP.fits"

            !nika.ref_det = [3137,823,6177]
            !nika.numdet_ref_1mm = !nika.ref_det[0]
            !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif
       if myday eq 20190322 then begin

          oldparam = 0
          newparam = 0

          if scan_num lt 75 then oldparam=1
          if scan_num ge 75 and scan_num  lt 81 then newparam=1
          if scan_num ge 81 and scan_num  lt 95 then oldparam=1
          if scan_num ge 95 and scan_num  lt 107 then newparam=1
          if scan_num ge 107 and scan_num lt 130 then oldparam=1
          if scan_num ge 130 and scan_num lt 148 then newparam=1
          if scan_num ge 148 and scan_num lt 161 then oldparam=1
          if scan_num ge 161 and scan_num lt 183 then newparam=1
          if scan_num ge 183 then oldparam=1
          
          if oldparam then begin
            file = !nika.off_proc_dir+"/kidpar_N2R30_baseline_JFMP.fits"
            ;;file = !nika.off_proc_dir+"/kidpar_N2R30_ref_baseline_BL.fits"
            !nika.ref_det = [3137,823,6177]
            !nika.numdet_ref_1mm = !nika.ref_det[0]
            !nika.numdet_ref_2mm = !nika.ref_det[1]
          endif
          
          if  newparam  then begin
            file = !nika.off_proc_dir+"/kidpar_20190322s161_v0_bis.fits"
            !nika.ref_det = [3283,823,6726]
            !nika.numdet_ref_1mm = !nika.ref_det[0]
            !nika.numdet_ref_2mm = !nika.ref_det[1]  
         endif
          
       endif
       
       if myday ge 20190323 and myday le 20190326 then begin
          ;; BL&LP : update using candidate reference kidpar made by BL
          file = !nika.off_proc_dir+"/kidpar_N2R29_ref_baseline_BL.fits"
          ;; LP: updated (2021, Jan, 27)
          file = !nika.off_proc_dir+"/kidpar_N2R30_baseline_JFMP.fits"
            !nika.ref_det = [3137,823,6177]
            !nika.numdet_ref_1mm = !nika.ref_det[0]
            !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       if myday ge 20190516 and myday le 20190924 then begin
          ;; BL&LP : update using candidate reference kidpar made by BL
          ;; file = !nika.off_proc_dir+"/kidpar_20190322s161_v0_bis.fits"

          ;; NP: correct rotation center, force it to the ref pixel
          ;; 823, Oct. 6th 2019
          ;; Calibration still to be checked, awaiting for correct
          ;; beammap at 2mm in particular.
          file = !nika.off_proc_dir+"/kidpar_20190322s161_v0_bis_RotCenter_NP.fits"
          !nika.ref_det = [3137,823,6177]
       endif

       ;; N2R34 and N2R35
       if myday ge 20191007 and myday le 20191027 then begin
          ;; remplace with the latest sweep of Sept. 2019
          ;; Not fully calibrated yet, no opacity coeffs
          ;;file = !nika.off_proc_dir+"/kidpar_20190923s8_v0.fits"
            ; LP geometry May 2020
;;          file = !nika.off_proc_dir+"/kidpar_20191016s15_v2_LP.fits"
; FXD, May 5,2020, baseline calibration for N2R34 and N2R35
          file = !nika.off_proc_dir+"/kidpar_N2R34_baseline.fits"
          
          ;; LP, add a test on param
          if isa(param, 'STRUCT') then if param.scanamnika ne 0 then begin
             message, /info, "fix me: test HR's kidpar"
             file = "/home/ponthieu/NIKA/Soft/Processing/Labtools/NP/Ref/kidpar_N2R33_ref_baseline.fits"
             stop
          endif
          
          !nika.ref_det = [3132,819,6022]

          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif

       ;; N2R36 and N2R37
        if myday ge 20191028 and myday le 20191204 then begin
           ;; Not fully calibrated yet, no opacity coeffs
           ;;file = !nika.off_proc_dir+"/kidpar_20190923s8_v0.fits"
           ;; fully calibrated but using scans from 20191029 only
           file = !nika.off_proc_dir+"/kidpar_N2R34_ref_baseline_skd4.fits"
           ;; LP: updated 2021, jan 27
           ;;file = !nika.off_proc_dir+"/kidpar_N2R36_baseline_LP_v2.fits"
           
          !nika.ref_det = [3132,819,6022]

          !nika.numdet_ref_1mm = !nika.ref_det[0]
          !nika.numdet_ref_2mm = !nika.ref_det[1]
       endif
       
        ;; N2R38, cryo run 50
        if myday ge 20191209 and myday le 20191217 then begin
           ;; Not fully calibrated yet, no opacity coeffs
           ;;file = !nika.off_proc_dir+"/kidpar_20190923s8_v0.fits"
           ;; fully calibrated but using scans from 20191029 only
           file = !nika.off_proc_dir+"/kidpar_N2R34_ref_baseline_skd4.fits"
           !nika.ref_det = [3132,819,6022]
           
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;; n2r39, cryo run 51
        if myday ge 20200114 and myday le 20200121 then begin 
           ;; Not fully calibrated yet, no opacity coeffs
           ;;file = !nika.off_proc_dir+"/kidpar_20200114s292_v0.fits"
           file = !nika.off_proc_dir+"/kidpar_N2R39_baseline_JFMP.fits"
           !nika.ref_det = [3132,819,6022]
           
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;; n2r40, cryo run 52
        if myday ge 20200128 and myday le 20200204 then begin 
           ;; Not fully calibrated yet, no opacity coeffs
           ;;file = !nika.off_proc_dir+"/kidpar_20200114s292_v0.fits"
           ;;file = !nika.off_proc_dir+"/kidpar_N2R40_baseline.fits"
           file = !nika.off_proc_dir+"/kidpar_N2R40_baseline_JFMP.fits"
           !nika.ref_det = [3132,819,6022]
           
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;; n2r41, cryo run 53
        if myday ge 20200211 and myday le 20200218 then begin
           ;; Not fully calibrated yet, no opacity coeffs
           ;;file = !nika.off_proc_dir+"/kidpar_20200114s292_v0.fits"
           ;; LP update with FXD calibrated kidpar (16/02/2020)
           ;; file = !nika.off_proc_dir+"/kidpar_N2R41_ref_baseline_v0.fits"

           ;; First calibration_baseline result, with opacity included (FXD, LP)
           ;;file = !nika.off_proc_dir+'/kidpar_N2R41_ref_baseline_v0.fits'
           file = !nika.off_proc_dir+"/kidpar_N2R41_baseline_JFMP.fits"
           !nika.ref_det = [3132,819,6022]
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;; n2r42: polarization commissioning
        if myday ge 20200221 and myday le 20200303 then begin
           ;; First calibration_baseline result, with opacity included (FXD, LP)
;;           file = !nika.off_proc_dir+'/kidpar_N2R41_ref_baseline_v0.fits'
           file = !nika.off_proc_dir+"/kidpar_N2R41_baseline_JFMP.fits"
           !nika.ref_det = [3132,819,6022]
           
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;;N2R43, cryo55
        if myday ge 20200310 and myday le 20200317 then begin
           file = !nika.off_proc_dir+"/kidpar_N2R41_baseline_JFMP.fits"
           !nika.ref_det = [3132,819,6022]
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif


        ;; n2r45: cryo run 57, NIKA2 1st&2nd Summer Semester Pools
        if myday ge 20201020 and myday le 20201103 then begin
           ;; NP Oct. 23rd, 2020: to start before we have reduced the 1st beammap with the
           ;; new sweep.
           if (myday eq '20201023' and scan_num le 103) then begin
              file = !nika.off_proc_dir+"/kidpar_N2R41_baseline_JFMP.fits"
              !nika.ref_det = [3132,819,6022]
           endif else if (myday lt '20201028' or (myday eq '20201028' and scan_num lt 42)) then begin
              ;; OLD POINTING MODEL
              ;; 1st beammap on Venus after the new sweep
              ;; Not calibrated yet
              ;; file = !nika.off_proc_dir+"/kidpar_20201023s23_LP_v0.fits"
              ;; Very few valid kids for A3 near the center for this
              ;; beammap...
              ;; 6176 is a place holder for no (Oct. 23rd)
              ;; 1st beammap good beammap on Uranus (tau225 of about
              ;; 0.15, el>40)x
              ;; Not calibrated yet
              ;; Old pointing model
              ;;file = !nika.off_proc_dir+"/kidpar_20201023s116_v2_LP.fits"
              ;; LP, 20201125, candidate baseline kidpar (part1/2 have
              ;; the same absolute calibration, different Nasmyth centers)
              file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_part1_LP.fits"
              ;; LP: updated on 2021 January 27 (using pipeline rev 25766)
              file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_25766_part1.fits"
              ;; LP: updated on 2021 May 28 (using pipeline rev 26049)
              file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_26049_part1.fits"
              !nika.ref_det = [3131,818,6017]
           endif else begin
              ;; NEW POINTING MODEL
              ;;file = !nika.off_proc_dir+"/kidpar_20201101s297_v2_LP.fits"
              ;; LP tested on Nov. 2020
              ;; change the nasmyth rotation center in previous kidpar
              ;;file = !nika.off_proc_dir+"/kidpar_20201023s116_v2_LP_new_nas_center.fits"
              ;;change_rotation_center,!nika.off_proc_dir+"/kidpar_20201023s116_v2_LP.fits",
              ;;file, [0.19209880, 0.10200832]
              ;; LP, 20201125, candidate baseline kidpar (part1/2 have
              ;; the same absolute calibration, different Nasmyth centers)
              ;;file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_part2_LP.fits"
              ;; LP: updated on 2021 January 27 (using pipeline rev 25766)
              file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_25766_part2.fits"
              ;; LP: updated on 2021 May 28 (using pipeline rev 26049)
              file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_26049_part2.fits"
              !nika.ref_det = [3131,818,6017]
           endelse
           
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;; N2R46, cryo run 58,  Polarization tech run
        if ((myday ge 20201108 and myday lt 20201117) or (myday eq 20201117 and scan_num le 121)) then begin
           ;; Restart from last week's kidpar and the new pointing model
           file = !nika.off_proc_dir+"/kidpar_N2R46_baseline.fits" 
           !nika.ref_det = [3131,818,6017]
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;; N2R47, cryo run 59,  Third Summer Semester NIKA2 Science Pool
        if ((myday ge 20201118 and myday le 20201124) or (myday eq 20201117 and scan_num ge 160)) then begin
           ;; LP, 20201125, Placeholder from N2R45
           file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_part2_LP.fits"
           ;; LP: updated on 2021 January 27 (using pipeline rev 25766)
           file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_25766_part2.fits"
           ;; First baseline calibration
           ;; LP, May 28, 2021
           file = !nika.off_proc_dir+"/kidpar_N2R47_baseline_26116.fits"
           !nika.ref_det = [3131,818,6017]
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;; N2R48, cryo run 60,  December 9th to 15th, 2020
        if myday ge 20201208 and myday le 20201215 then begin
           ;; Placeholder from N2R45
           file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_part2_LP.fits"
           ;; LP: updated on 2021 January 27 (using pipeline rev 25766)
           file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_25766_part2.fits"
           !nika.ref_det = [3131,818,6017]
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;; N2R49, cryo run 61, Jan. 2021
        if myday ge 20210112 and myday le 20210126 then begin
           ;; Restart with the latest kidpar (NP, Jan. 11th, 2021)
           file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_part2_LP.fits"
           ;; LP: updated on 2021 January 27 (using pipeline rev 25766)
           file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_25766_part2.fits"
           ;; First baseline calibration
           ;; LP, May 28, 2021
           file = !nika.off_proc_dir+"/kidpar_N2R49_baseline_26145.fits"
           !nika.ref_det = [3131,818,6017]
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif
        
        ;; N2R50, cryo run 62, Feb. 2021
        if myday ge 20210208 and myday le 20210223 then begin
           ;; Restart with the latest kidpar (NP, Feb. 07th, 2021)
           file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_25766_part2.fits"
           ;; First baseline calibration
           ;; Note that uranus.txt has not been updated for this run
           ;; LP, May 28, 2021
           file = !nika.off_proc_dir+"/kidpar_N2R50_baseline_26122.fits"
           !nika.ref_det = [3131,818,6017]
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

        ;; N2R51, cryo run 63, Mar. 2021
        if myday ge 20210309 then begin
           ;; Restart with the latest kidpar (NP, Feb. 07th, 2021)
           file = !nika.off_proc_dir+"/kidpar_N2R45_baseline_25766_part2.fits"
           !nika.ref_det = [3131,818,6017]
           !nika.numdet_ref_1mm = !nika.ref_det[0]
           !nika.numdet_ref_2mm = !nika.ref_det[1]
        endif

     endif
   
   
   
   kidpar_file[iscan] = file
   corr_file[iscan] = cfile
endfor

if strlen(file) ne 0 then if not keyword_set( noread) then $
   if file_test( file) then kidpar = mrdfits(file, 1, /silent) else $
      message, /info, 'File '+ file+ ' does not exist'


end
