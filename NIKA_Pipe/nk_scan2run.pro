;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; NAME:
; nk_scan2run
;
; PURPOSE: 
;        Finds to which run the current scan belongs
; 
; INPUT: 
;        - scan: string for the format YYYYMMDDsNUM
; 
; OUTPUT: 
;        - run: string
; 
; KEYWORDS:
;        
; MODIFICATION HISTORY: 
;        - NP, March 2015, from old IDLtools/scan2daynum
;          - FXD March 2021 modify some data to allow an overlap of
;            runs on the same day (to be in agreement with get_nika2_run_info)


pro nk_scan2run, scan, run, status, nika_run = nika_run, silent=silent, n2run = n2run
;-
  
if n_params() lt 1 then begin
   dl_unix, 'nk_scan2run'
   return
endif


status = 0 ; ok by default

; FXD, add the case where the run is known
if keyword_set( nika_run) then run = nika_run  ; given as input
if keyword_set( nika_run) then goto, skip_scan
 
nk_scan2daynum, scan, day, scan_num

!nika.acq_version = 'v1'

;; ;; Temporary fix
;; if defined(!host) then begin
;;    if strupcase(!host) eq "MUSE" then begin
;;       if long(day) ge 20160112 and long(day) lt 20160229 then begin
;;          run = '15'
;;          !nika.raw_acq_dir = "$NIKA_DATA_DIR/Data/NIKA_Run/Raw_data/run15_X"
;;       endif
;;       if long(day) ge 20160301 and long(day) lt 20160630 then begin
;;          run = '16'
;;          !nika.raw_acq_dir = "$NIKA_DATA_DIR/Data/NIKA_Run/Raw_data/run16_X"
;;       endif
;;       if long(day) ge 20160901 then begin
;;          run = '18'
;;          !nika.raw_acq_dir = "$NIKA_DATA_DIR/Data/NIKA_Run/Raw_data/run18_X"
;;       endif
;;       return
;;    endif
;; endif

;; Other machines than MUSE  

case 1 of 
   (long(day) gt 20121101 and long(day) lt 20121127)  : run='5'
   (long(day) gt 20130601 and long(day) lt 20130620)  : run='6'
   (long(day) gt 20131101 and long(day) lt 20131129)  : run='cryo'
   (long(day) gt 20140101 and long(day) lt 20140131)  : run='7'
   (long(day) gt 20140201 and long(day) lt 20140601)  : begin
      run='8'
      !nika.raw_acq_dir = "/home/nika2/NIKA/Data/Run7/raw_X10"
   end
   (long(day) gt 20140201 and long(day) le 20140930)  : run='8'
   (long(day) gt 20140930 and long(day) lt 20141106)  : run='9'
   (long(day) ge 20141106 and long(day) lt 20150123)  : begin
      run='10'
      !nika.raw_acq_dir = "/home/nika2/NIKA/Data/Run10/raw_X9"
   end
   (long(day) ge 20150123 and long(day) lt 20150210)  : run='11'
   (long(day) eq 20150210)  : begin
      ;; Open Pool 3 = Run11, ended on Feb. 10th in the morning, and the polarization run (12)
      ;; started the same day in the evening.
      if scan_num le 157 then begin
         ;; still openpool3
         run = '11'
      endif else begin
         ;; Polarization run
         run = '12'
      endelse
   end
   (long(day) gt 20150210 and long(day) le 20150928) : begin
      run = '12'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/Run12"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 Run 1
   (long(day) gt 20150929 and long(day) le 20151110) : begin
      run = '13'
      
      ;; Need to account for the temporary new "manip" and reset
      ;; raw_acq_dir if needed

      ;; default
      !nika.raw_acq_dir = getenv('NIKA_RAW_ACQ_DIR')

      ;; Specific 1mm configuration
      scan2daynum, scan, day, scan_num

      if long(day) lt 20151027 then $
         !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_X/"      
      

      if long(day) eq 20151027 then begin
         if scan_num ge 120 and scan_num le 134 then begin 
            !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_1mm_v2_X/" 
         endif else $
            !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_X/"      
      endif

      if long(day) gt 20151027 then begin
         if scan_num ge 120 and scan_num le 134 then begin 
            !nika.raw_acq_dir = "/home/nika2/NIKA/Data/raw_X24_1mm/" 
         endif else $
            !nika.raw_acq_dir = "/home/nika2/NIKA/Data/raw_X24/"      
      endif

      if long(day) eq 20151028 then begin
         if scan_num ge 200 then !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_1mm_v2_X" else $
            !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_X"
      endif

      if long(day) eq 20151029 then begin
         if scan_num lt 200 then begin
            !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_1mm_v2_X/"
         endif else begin
            !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_X/"           
         endelse
         
      endif
      if long(day) gt 20151029 then begin
         !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_X/"           
      endif
      if long(day) ge 20151102 then begin
         !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_all_X/"           
      endif

      if long(day) eq 20151104 then begin
         !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_all11_X/"           
      endif

      if long(day) eq 20151105 then $
         !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_all11_X/"           
      
      if long(day) ge 20151106 then $
         !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run13_all_X/"           

      ;; To work on Bambini while not disturbing nika2a
      if defined(!host) then begin
         if strtrim( strupcase(!host),2) eq "BAMBINI" then begin

            ;; default
            !nika.raw_acq_dir = "/home/archeops/NIKA2/Data/raw_X24"

            if long(day) eq 20151027 then begin
               if scan_num ge 120 and scan_num le 134 then begin 
                  !nika.raw_acq_dir = "/home/archeops/NIKA2/Data/raw_X24_1mm/" 
               endif else $
                  !nika.raw_acq_dir = "/home/archeops/NIKA2/Data/raw_X24/"      
            endif
            if long(day) eq 20151028 then begin
               if scan_num ge 200 then !nika.raw_acq_dir = "/home/archeops/NIKA2/Data/raw_X24_1mm/" else $
                  !nika.raw_acq_dir = "/home/archeops/NIKA2/Data/raw_X24/"           
            endif
         endif
      endif

   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 Second Run, End of November 2015
   long(day) ge 20151124 and long(day) lt 20160112 : begin
      run = '14'
                                ; !nika.raw_acq_dir = "/home/nika2/NIKA/Data/run14_X/"
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run14_X/"
                                ;!nika.raw_acq_dir = !nika.raw_data_dir+"/run14_X/"
                                ;!nika.raw_acq_dir = !nika.raw_data_dir+"/run14_X/"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 third Run, Jan-Feb 2016
   long(day) ge 20160112 and long(day) lt 20160229: begin
      run = '15'
                                ;!nika.raw_acq_dir = "/home/nika2/NIKA/Data/run15_X/"
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run15_X/"
                                ;!nika.raw_acq_dir = !nika.raw_data_dir+"/run15_X/"
                                ;!nika.raw_acq_dir = !nika.raw_data_dir+"/run15_X/"
   end
   
   ;;---------------------------------------------------------------------------
   ;; NIKA2 fourth run, March 2016
   long(day) ge 20160301 and long(day) lt 20160630 : begin
      run = '16'
                                ;!nika.raw_acq_dir = "/home/nika2/NIKA/Data/run16_X/"
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run16_X/"
                                ;!nika.raw_acq_dir = !nika.raw_data_dir+"/run16_X/"
                                ;!nika.raw_acq_dir = !nika.raw_data_dir+"/run16_X/"
   end
   ;;---------------------------------------------------------------------------
   ;; NIKA2 fifth run, Sept. 2016 = Run 18 (run 17 never existed :) )
   long(day) ge 20160901 and long(day) le 20161011: begin
      run = '18'
                                ;!nika.raw_acq_dir = "/home/nika2/NIKA/Data/run18_X/"
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run18_X/"
   end
   
   ;;---------------------------------------------------------------------------
   ;; NIKA2 sixth run, Oct.-Nov. 2016 = Run 19
   ;; adjusted to new initialization in nika_lib_init, NP, Oct. 28th, 2016
   long(day) ge 20161025 and long(day) lt 20161201: begin
      run = '19'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run19_X/"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 seventh run, Dec. 6th - Dec. 13th, 2016 = Run 20
   long(day) ge 20161201 and long(day) le 20161213: begin
      run = '20'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run20_X/"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 eighth run, Jan. 24th, 2017 - Jan 31st, 2016 = Run 21
   long(day) ge 20170124 and long(day) le 20170126: begin
      run = '21'
      ;; !nika.raw_acq_dir = !nika.raw_data_dir+"/run21_X/"
      ;; Data were actually still copied into run20_X, not run21_X.
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run20_X/"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 9th run, Feb. 21st-28th, 2017 = Run 22
   long(day) ge 20170217 and long(day) le 20170228: begin
      run = '22'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run22_X/"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 10th run, Apr. 18th - Apr. 25th, 2017 = Run23
   long(day) ge 20170414 and long(day) le 20170425: begin
      run = '23'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run23_X/"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 11th run, Polarization, June 8th (yes, it was a Thursday) - June 13th, 2017 = Run24
   long(day) ge 20170606 and long(day) le 20170613: begin
      run = '24'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run24_X/"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 12th run, 1st science pool, Oct. 24th - Oct. 31st, 2017 = Run25
   long(day) ge 20171016 and long(day) le 20171031:begin
      run = '25'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run25_X/"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 13th run, 2nd technical polarization run
   long(day) ge 20171117 and long(day) le 20171128: begin
      run = '26'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run26_X/"
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 14th run, 2nd science pool, Jan. 13th to 23rd, 2018
   long(day) ge 20180101 and long(day) le 20180123: begin
      run = '27'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run27_X/"
      if long(day) le 20180123 then input_day = day
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 15th run, 3rd science pool : Feb 13th - Feb 20th
   long(day) ge 20180213 and long(day) le 20180220: begin
      run = '28'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run28_X/"
      if long(day) le 20180220 then input_day = day
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 16th run, 3rd technical polarization run
   long(day) ge 20180302 and long(day) le 20180312: begin
      run = '29'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run29_X/"
      !nika.acq_version = 'v2'
      if long(day) le 20180312 then input_day = day

   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 17th run, 4th science pool
   long(day) ge 20180313 and long(day) le 20180331: begin
      run = '30'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run30_X/"
      if long(day) le 20180320 then input_day = day

      ;; back to v1 acquisition for this pool
      !nika.acq_version = 'v1'
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 18th run, 5th science pool
   long(day) ge 20180522 and long(day) le 20180529: begin
      run = '31'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run31_X/"
      if long(day) le 20180530 then input_day = day

      ;; back to v1 acquisition for this pool
      !nika.acq_version = 'v1'
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 19th run, Polarization technical run
   long(day) ge 20180608 and long(day) lt 20180619: begin
      run = '32'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run32_X/"
;;      if long(day) le 20180619 then input_day = day
      input_day = ( (day > 20180611) < 20180620)
      !nika.acq_version = 'v2'
   end

   ;; NIKA2 PIMP run, July 2018

   ;;---------------------------------------------------------------------------
   ;; NIKA2 short dichroic and polarization synchronization run
   ;; NIKA2 20th run
   long(day) ge 20180904 and long(day) le 20180906: begin
      run = '33'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run33_X"
      run = '34'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run34_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20180906 then input_day = day

      ;; For total power and polarization data
      !nika.acq_version = 'v2'
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 old dichroic re-check and polarization tech run, Sept. 2018
   ;; NIKA2 21st run
   long(day) ge 20180918 and long(day) le 20180925: begin
      run = '35'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run35_X"

      ;; When we have Herve Aussel's calibrator fluxes
      input_day = day

      ;; For total power and polarization data
      !nika.acq_version = 'v2'
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 old dichroic re-check and polarization tech run, Sept. 2018
   ;; NIKA2 22nd run
   long(day) ge 20181001 and long(day) le 20181009: begin
      run = '36'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run36_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20181009 then input_day = day

      ;; For total power and polarization data
      !nika.acq_version = 'v2'
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 science pool
   ;; NIKA2 23rd run
   long(day) ge 20181029 and long(day) le 20181118: begin
      run = '37'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run37_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20181106 then input_day = day

      ;; For total power and polarization data
      !nika.acq_version = 'v1'
   end

   ;;---------------------------------------------------------------------------
   ;; NIKA2 science pool
   ;; NIKA2 24th run
   long(day) ge 20181119 and long(day) le 20181127: begin
      run = '38'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run38_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20181128 then input_day = day

      ;; For total power and polarization data
      !nika.acq_version = 'v1'
   end
   
   ;; NIKA2 25th run: Polar test run
   long(day) ge 20181203 and long(day) le 20181211: begin
      run = '39'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run39_ABOB_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20181211 then input_day = day

      ;; For total power and polarization data
      ;; V3 starting Dec. 4th, 2018
      !nika.acq_version = 'v3'
   end

   ;; SCIENCE POOL
   ;; NIKA2 26th run
   long(day) ge 20190114 and long(day) le 20190122 : begin
      run = '40'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run40_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20190122 then input_day = day
      
      !nika.acq_version = 'v1'

;;       ;; To deal with changes in configuration, for example
;;       if long(day) le XXX and long(scan_num) ge YYYY then begin
;;          !nika.acq_version = 'v3'
;;       endif
;;       if long(day) ge XXX and long(scan_num) ge XXX then begin
;;          blablabla
;;       endif
      
   end

   ;; NIKA2 27th run: SCIENCE Pool
   long(day) ge 20190129 and long(day) le 20190205:begin
      run = '41'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run41_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20190206 then input_day = day
      
      !nika.acq_version = 'v1'

;;       ;; To deal with changes in configuration, for example
;;       if long(day) le XXX and long(scan_num) ge YYYY then begin
;;          !nika.acq_version = 'v3'
;;       endif
;;       if long(day) ge XXX and long(scan_num) ge XXX then begin
;;          blablabla
;;       endif
      
   end

   ;; NIKA2 28th run: Pool
   long(day) ge 20190212 and long(day) le 20190219:begin
      run = '42'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run42_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20190219 then input_day = day
      
      !nika.acq_version = 'v1'

;;       ;; To deal with changes in configuration, for example
;;       if long(day) le XXX and long(scan_num) ge YYYY then begin
;;          !nika.acq_version = 'v3'
;;       endif
;;       if long(day) ge XXX and long(scan_num) ge XXX then begin
;;          blablabla
;;       endif
      
   end

   ;; NIKA2 29th run: Pool
   long(day) ge 20190305 and long(day) le 20190312:begin
      run = '43'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run43_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20190313 then input_day = day
      
      !nika.acq_version = 'v1'

;;       ;; To deal with changes in configuration, for example
;;       if long(day) le XXX and long(scan_num) ge YYYY then begin
;;          !nika.acq_version = 'v3'
;;       endif
;;       if long(day) ge XXX and long(scan_num) ge XXX then begin
;;          blablabla
;;       endif
      
   end

 
   ;; NIKA2 30th run: Pool
   long(day) ge 20190319 and long(day) le 20190327:begin
      run = '44'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run44_X"

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20190326 then input_day = day

      !nika.acq_version = 'v3'

      if long(day) eq 20190322 and long(scan_num) gt 74 then  !nika.acq_version = 'v1'
      if long(day) gt 20190322 then  !nika.acq_version = 'v1' 
;;       ;; To deal with changes in configuration, for example
;;       if long(day) le XXX and long(scan_num) ge YYYY then begin
;;          !nika.acq_version = 'v3'
;;       endif
;;       if long(day) ge XXX and long(scan_num) ge XXX then begin
;;          blablabla
;;       endif
      
   end  

   
   ;; NIKA2 31st run: Test
   long(day) ge 20190516 and long(day) le 20190517:begin
      run = '45'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run45_X"
      
      ;; When we have Herve Aussel's calibrator
      ;; fluxes
      if long(day) le 20190518 then input_day = day

      !nika.acq_version = 'v3'
      
      ;;       ;; To deal with changes in configuration, for example
      ;;       if long(day) le XXX and long(scan_num) ge YYYY then
      ;;       begin
      ;;          !nika.acq_version = 'v3'
      ;;       endif
      ;;       if long(day) ge XXX and long(scan_num) ge XXX then
      ;;       begin
      ;;          blablabla
      ;;       endif

         end

   ;; NIKA2 32nd run: IRAM summer school students
   long(day) ge 20190906 and long(day) le 20190912:begin
      run = '46'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run46_X"
      
      ;; When we have Herve Aussel's calibrator
      ;; fluxes
      ;;if long(day) le 20190518 then input_day = day

      !nika.acq_version = 'v1'
      
      ;;       ;; To deal with changes in configuration, for example
      ;;       if long(day) le XXX and long(scan_num) ge YYYY then
      ;;       begin
      ;;          !nika.acq_version = 'v3'
      ;;       endif
      ;;       if long(day) ge XXX and long(scan_num) ge XXX then
      ;;       begin
      ;;          blablabla
      ;;       endif

         end

   ;; NIKA2 33rd run : Test v3
   long(day) ge 20190910 and long(day) le 20190924:begin

      run = '47'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run47_X"
      
      ;; When we have Herve Aussel's calibrator fluxes
      ;;if long(day) le 20190326 then input_day = day
      
      !nika.acq_version = 'v3'
      
      ;; if long(day) eq 20190322 and long(scan_num) gt 74 then  !nika.acq_version = 'v1'
      ;; if long(day) gt 20190322 then  !nika.acq_version = 'v1' 
;;       ;; To deal with changes in configuration, for example
;;       if long(day) le XXX and long(scan_num) ge YYYY then begin
;;          !nika.acq_version = 'v3'
;;       endif
;;       if long(day) ge XXX and long(scan_num) ge XXX then begin
;;          blablabla
;;       endif
   end
   
   ;; NIKA2 34-35th run : Test v3
   long(day) ge 20191007 and long(day) le 20191023: begin
      run = '48'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run48_X"
      !nika.acq_version = 'v1'

      ;; When we have Herve Aussel's calibrator fluxes
      if long(day) le 20191024 then input_day = day

;;       ;; To deal with changes in configuration, for example
;;       if long(day) le XXX and long(scan_num) ge YYYY then begin
;;          !nika.acq_version = 'v3'
;;       endif
;;       if long(day) ge XXX and long(scan_num) ge XXX then begin
;;          blablabla
;;       endif
      
   end  

   
   ;; NIKA2 36-37th run : Test v3
   long(day) ge 20191028 and long(day) le 20191113: begin
      run = '49'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run49_X"
      !nika.acq_version = 'v1'
      
      ;; When we have Herve Aussel's calibrator
      ;; fluxes
      if long(day) le 20191114 then input_day = day
      
      ;;       ;; To deal with changes in configuration, for example
      ;;       if long(day) le XXX and long(scan_num) ge YYYY then
      ;;       begin
      ;;          !nika.acq_version = 'v3'
      ;;       endif
      ;;       if long(day) ge XXX and long(scan_num) ge XXX then
      ;;       begin
      ;;          blablabla
      ;;       endif

   end


   ;; NIKA2 38th run: science pool
   long(day) ge 20191208 and long(day) le 20191216: begin
      run = '50'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run50_X"
      !nika.acq_version = 'v1'

      ;; When we have Herve Aussel's calibrator
      ;; fluxes
      if long(day) le 20191219 then input_day = day

   end


   ;; NIKA2 39th run: science pool
   ;;;   long(day) ge 20200108 and long(day) le 20200124: begin
   long(day) ge 20200114 and long(day) le 20200121: begin
   ;;;
      run = '51'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run51_X"
      !nika.acq_version = 'v1'

      ;; When we have Herve Aussel's calibrator
      ;; fluxes
      if long(day) le 20200121 then input_day = day
   end
   
   ;; NIKA2 40th run (cryo run 52) : science pool
   long(day) ge 20200128 and long(day) le 20200204: begin
      run = '52'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run52_X"
      !nika.acq_version = 'v1'
      
      ;; When we have Herve Aussel's calibrator
      ;; fluxes
      if long(day) le 20200204 then input_day = day
   end

   ;; NIKA2 41th run : science pool
   long(day) ge 20200211 and long(day) le 20200218: begin
      run = '53'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run53_X"
      !nika.acq_version = 'v3'
      
      ;; When we have Herve Aussel's calibrator
      ;; fluxes
      if long(day) le 20200218 then input_day = day
   end

   ;; NIKA2 42nd run : polarization commissioning
   long(day) ge 20200225 and long(day) le 20200303: begin
      run = '54'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run54_X"
      !nika.acq_version = 'v3'
      
      ;; When we have Herve Aussel's calibrator
      ;; fluxes
      if long(day) le 20200303 then input_day = day
   end

   ; N2R43 55
   long(day) ge 20200310 and long(day) le 20200317: begin
      run = '55'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run55_X"
      !nika.acq_version = 'v3'
      
      ;; When we have Herve Aussel's calibrator
      ;; fluxes
      if long(day) le  20200317 then input_day = day
   end

   ;; N2R44 56 du 6 aout au 6oct
   long(day) ge 20200806 and long(day) le 20201006: begin
      run = '56'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run56_X"
      !nika.acq_version = 'v3'

      if long(day) le 20201006 then input_day = day
   end
   
   ;; NIKA2 45th run : first and second NIKA2 2020 summer pools : cryo run 57
   long(day) ge 20201020 and long(day) le 20201103: begin
      run = '57'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run57_X"
      !nika.acq_version = 'v3'

      if long(day) le 20201103 then input_day = day
   end

   ;; NIKA2 46th run: Polar tech run, cryo run 58
   (long(day) ge 20201109 and long(day) le 20201116) or $
      (long(day) eq 20201117 and scan_num le 121): begin
      run = '58'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run58_X"
      ;; res = get_login_info()
      ;; if res.machine_name eq 'lpsc-nika2c' then $  ; rustine
      ;;    !nika.raw_acq_dir = !nika.raw_data_dir+"/run58_X/run58_X"
      !nika.acq_version = 'v3'
      input_day = day
   end

   long(day) eq 20201117 and scan_num ge 122: begin
      ;; if scan_num le 121 then begin
      ;;    ;; end of the polarization run
      ;;    run = '58'
      ;;    !nika.raw_acq_dir = !nika.raw_data_dir+"/run58_X"
      ;;    !nika.acq_version = 'v3'
      ;;    input_day = day
      ;; endif else begin
         run = '59'
         !nika.raw_acq_dir = !nika.raw_data_dir+"/run59_X"
         !nika.acq_version = 'v3'
         input_day = day
   ;;    endelse
   end
   
   ;; NIKA2 47th run: 3rd 2020 Summer Semester Science Pool, cryo run 59
   long(day) gt 20201117 and long(day) le 20201124 : begin
      run = '59'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run59_X"
      !nika.acq_version = 'v3'
      input_day = day
   end

   ;; NIKA2 48th run, cryo run 60
   long(day) ge 20201208 and long(day) le 20201215: begin
      run = '60'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run60_X"
      !nika.acq_version = 'v3'
      input_day = day
   end

   ;; NIKA2 49th run, cryo run 61
   long(day) ge 20210112 and long(day) le 20210126:begin
      run = '61'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run61_X"
      !nika.acq_version = 'v3'
      input_day = day
   end

   ;; NIKA2 50th run, cryo run 62
   long(day) ge 20210208 and long(day) le 20210223: begin
      run = '62'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run62_X"
      !nika.acq_version = 'v3'
      input_day = day
   end

   ;; NIKA2 51st run, cryo run 63
   long(day) ge 20210309 and long(day) le 20210323: begin
      run = '63'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run63_X"
      !nika.acq_version = 'v3'
      input_day = day
   end
   
   ;; NIKA2 52nd run, cryo run 64
   long(day) ge 20210525 and long(day) le 20210601: begin
      run = '64'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run64_X"
      !nika.acq_version = 'v3'
      input_day = day
   end
   
   ;; Summer cryo run 65
   ;; LP, placeholder, accurate dates TBC 
   long(day) ge 20210602 and long(day) le 20210525: begin
      run = '65'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run65_X"
      !nika.acq_version = 'v3'
      input_day = day
   end
   
   ;; NIKA2 54th run, cryo run 66
   long(day) ge 20210921 and long(day) le 20210925: begin
      run = '66'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run66_X"
      !nika.acq_version = 'v3'
      input_day = day
   end
   
   ;; NIKA2 55th run, cryo run 67, 20211026 - 20211109,
   ;; preparation run on October 17-22                                         
   long(day) ge 20211017 and long(day) le 20211109: begin
      run = '67'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run67_X"
      !nika.acq_version = 'v3'
      input_day = day
   end

   ;; do not set the upper limit until the next run, otherwise IDL
   ;; initialization fails in general
   ;; NIKA2 56th run, cryo run 68, 20211116 - 20211130
   ;; preparation run on October 17-22                                         
   long(day) ge 20211115: begin
      run = '68'
      !nika.raw_acq_dir = !nika.raw_data_dir+"/run68_X"
      !nika.acq_version = 'v3'
      input_day = day
   end

   else: begin
      if not keyword_set(silent) then message, /info, 'No run is set for that date : '+ strtrim(day, 2)
      status = 1
      return
   end

endcase

skip_scan:

;; update !nika accordingly
fill_nika_struct, run, day=input_day

;; This needs to be explicitely set here, otherwise the default
;; !nika.sign_data_position that is set to -1 when we launch IDL is
;; not changed when nk_scan2run is called in a data reduction of old scans.
if long(!nika.run) ge 34 then begin
   !nika.sign_data_position = -1.d0
endif

;; trying
if long(!nika.run) ge 39 then begin
   !nika.sign_data_position = 1.d0
endif

if strupcase(!nika.acq_version) eq "V2" then begin
   !nika.sign_angle = -1
endif

;if strupcase(!nika.acq_version) eq "V3" then begin
;   !nika.sign_angle = -1
;endif

if keyword_set( n2run) then begin
   get_nika2_run_info, n2rstruct
   a = where( n2rstruct.cryorun eq run, na)
   if na eq 1 then n2run = n2rstruct[a[0]].nika2run
endif

  
end
