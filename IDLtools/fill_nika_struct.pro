
;; Leave default parameters untouched, updates the other ones

pro fill_nika_struct, run, day=day
;if run ne !nika.run and !nika.run ne 'dummy' $
;  then message, /info, 'The init run '+ $
;                strtrim( !nika.run, 2)+ $
;                ' does not match the intended run '+ $
;                strtrim( run, 2)+ '. THAT SHOULD BE CHECKED'


if strupcase(run) eq "CRYO" then begin
   !nika.retard       = 9
   !nika.ptg_shift    = -0.87
   !nika.sign_angle   = -1
   
   !nika.lambda = [1.1530479, 1.9986164] ;= 150 et 260 GHz
   
   !nika.flux_uranus  = [97.18, 36.92] ; Dec. 4th, 2013
   !nika.flux_mars    = [195.1, 65.8]
   !nika.run          = run

endif else begin

   if long(run) le 26 then begin

      case run of
         '5': begin
            ;; NP, Dec. 29th (on scan 20121122s222)
            !nika.retard = 2
            !nika.ptg_shift = 0.74
            !nika.sign_angle   = -1
            
            !nika.lambda = [1.2491352, 2.1413747] ;= 140 et 240 GHz
            ;; !nika.fwhm_nom = [12.5, 18.5]        
            
            !nika.flux_uranus  = [51.637, 17.897]
            !nika.flux_mars    = [132.072, 45.448]
            !nika.flux_neptune = [18.926, 6.566]
            !nika.flux_saturn  = [0.d0, 0.d0] ; place holder
            !nika.run          = run
         end

         '6': begin
            ;; Commented out, NP. Nov 22nd, 2013 to match new read_nika_brute retard definition
            ;; !nika.retard       = 25
            !nika.retard       = 0
            !nika.ptg_shift    = 0
            !nika.sign_angle   = -1
            
            !nika.lambda = [1.2491352, 2.1413747] ;= 140 et 240 GHz
            ;; !nika.fwhm_nom = [12.5, 18.5]         
            
            !nika.flux_uranus  = [47.2, 16.4]
            !nika.flux_mars    = [95.3, 32.8]
            !nika.flux_neptune = [19.4, 6.72]
            !nika.flux_saturn  = [1389.98, 480.679]
            !nika.run          = run
         end

         '7': begin
            !nika.run          = run
            
            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.sign_angle   = -1
            
            !nika.lambda = [1.1530479, 1.9986164] ;= 150 et 260 GHz
            ;; !nika.fwhm_nom = [12.5, 18.5]        
            
            ;; Updated with correct values, NP., Jan 15th, 2014
            ;; Updated with correct values, NP., Feb 11th, 2014
            !nika.flux_uranus  = [38.1156, 15.9764] ; [42.06, 15.98]
            !nika.flux_mars    = [478.4, 161.4]
            !nika.flux_neptune = [15.3777, 6.44568] ; [21.03, 7.15]
            !nika.flux_saturn  = [0.d0, 0.d0]
            !nika.flux_ceres   = [1.2, 0.4]
            !nika.flux_pallas  = [0.5, 0.15]
            !nika.flux_vesta   = [0.5, 0.16]
            !nika.flux_lutetia = [1.2, 0.4]
            !nika.flux_3c84    = [10., 15.] ; scan 181 du 25/01 ; [10., 11.] ; Xavier, Mail du 23/01
         end

         '8':begin
            !nika.run          = run
            
            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.sign_angle   = -1
            
            !nika.lambda = [1.1530479, 1.9986164] ;= 150 et 260 GHz
            ;; !nika.fwhm_nom = [12.5, 18.5]        
            
            ;; Run8 values for now (Feb. 11th, Nico)
            !nika.flux_uranus  = [36.4466,15.2768]
            !nika.flux_neptune = [15.1648, 6.35642]
            !nika.flux_mars    = [874.287, 294.920]
            
            ;;run7 values
            !nika.flux_saturn  = [0.d0, 0.d0]
            !nika.flux_ceres   = [1.2, 0.4]
            !nika.flux_pallas  = [0.5, 0.15]
            !nika.flux_vesta   = [0.5, 0.16]
            !nika.flux_lutetia = [1.2, 0.4]
            !nika.flux_3c84    = [10., 15.] ; scan 181 du 25/01 ; [10., 11.] ; Xavier, Mail du 23/01
         end

         '9':begin
            !nika.run          = run
            
            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.sign_angle   = 1
            
            !nika.lambda = [1.1530479, 1.9986164] ;= 150 et 260 GHz
            ;; !nika.fwhm_nom = [12.5, 18.5]        
            
            ;; Mail de Xavier du 5 Oct. 2014
            !nika.flux_uranus  = [43.7135,18.3228]
            !nika.flux_neptune = [16.9918, 7.12225]
            !nika.flux_mars    = [280.937, 94.6699]
            
            ;; No values yet
            !nika.flux_saturn  = [0.d0, 0.d0]
            !nika.flux_ceres   = [0.d0, 0.d0]
            !nika.flux_pallas  = [0.d0, 0.d0]
            !nika.flux_vesta   = [0.d0, 0.d0]
            !nika.flux_lutetia = [0.d0, 0.d0]
            !nika.flux_3c84    = [0.d0, 0.d0]
         end

         '10':begin
            !nika.run          = run
            
            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.sign_angle   = 1
            
            !nika.lambda = [1.1530479, 1.9986164] ;= 150 et 260 GHz
            ;; !nika.fwhm_nom = [12.5, 18.5]        
            
            ;; See http://www.iram.es/IRAMES/mainWiki/ListOfAstroTarget2014N10
            !nika.flux_uranus  = [42.9928,  18.0207]
            !nika.flux_neptune = [16.5436, 6.93438]
            !nika.flux_mars    = [230.772, 77.7652]
            
            
            ;; No values yet
            !nika.flux_saturn  = [0.d0, 0.d0]
            !nika.flux_ceres   = [0.d0, 0.d0]
            !nika.flux_pallas  = [0.d0, 0.d0]
            !nika.flux_vesta   = [0.d0, 0.d0]
            !nika.flux_lutetia = [0.d0, 0.d0]
            !nika.flux_3c84    = [0.d0, 0.d0]
         end

         '11':begin
            !nika.run          = run
            
            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.sign_angle   = 1
            
            !nika.lambda   = [1.1530479, 1.9986164] ;= 150 et 260 GHz
            ;; !nika.fwhm_nom = [12.5, 18.5]        
            
            ;; See http://www.iram.es/IRAMES/mainWiki/ListOfAstroTarget2015N11
            !nika.flux_uranus  = [38.0048, 15.9300]
            !nika.flux_neptune = [15.3072, 6.41612]
            !nika.flux_mars    = [159.587, 53.7744]
            
            
            ;; No values yet
            !nika.flux_saturn  = [0.d0, 0.d0]
            !nika.flux_ceres   = [0.d0, 0.d0]
            !nika.flux_pallas  = [0.d0, 0.d0]
            !nika.flux_vesta   = [0.d0, 0.d0]
            !nika.flux_lutetia = [0.d0, 0.d0]
            !nika.flux_3c84    = [0.d0, 0.d0]
         end

         '12': begin
            !nika.run          = run
            
            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.sign_angle   = 1
            
            !nika.numdet_ref_1mm = 5 ; tbc
            !nika.numdet_ref_2mm = 494
            
            !nika.grid_step = [6.9, 9.54]     ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.lambda   = [1.1530479, 1.9986164] ;= 150 et 260 GHz
            ;; !nika.fwhm_nom = [12.5, 18.5]        
            
            ;; See http://www.iram.es/IRAMES/mainWiki/ListOfAstroTarget2015N11
            !nika.flux_uranus  = [63.74d0, 21.65d0]
            !nika.flux_neptune = [23.38d0, 7.98d0]
            !nika.flux_mars    = [117.08d0, 39.50d0]
            
            !nika.flux_saturn  = [1181.45d0, 400.29d0]
            !nika.flux_jupiter = [5928.86d0, 2004.54d0]
            
            ;; No values yet
            !nika.flux_ceres   = [0.d0, 0.d0]
            !nika.flux_pallas  = [0.d0, 0.d0]
            !nika.flux_vesta   = [0.d0, 0.d0]
            !nika.flux_lutetia = [0.d0, 0.d0]
            !nika.flux_3c84    = [0.d0, 0.d0]
         end

;;========================================================================================
;;===================================== NIKA2  ===========================================
;;========================================================================================
         '13':begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.sign_angle   = 1

            !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015
            ;; !nika.fwhm_nom = [12.5, 18.5]           ; place holder, run12 values, Sept. 29th, 2015

;;   !nika.flux_uranus  = [44.01,  18.44]
;;   !nika.flux_neptune = [17.16,   7.19]
;;   !nika.flux_mars    = [117.08, 39.50]

            ;; HA's values, June 6th, 2017
            !nika.flux_uranus = [45.590000, 17.650000, 45.590000]
            !nika.flux_neptune = [17.090000, 7.1800000, 17.090000]
            !nika.flux_mars = [146.19000, 48.300000, 146.19000]

            ;; No values yet
            !nika.flux_saturn  = [1181.45, 400.29] ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_ceres   = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_pallas  = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_vesta   = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_lutetia = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_3c84    = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
         end

         '14':begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.sign_angle   = 1

            !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015
            ;; !nika.fwhm_nom = [12.5, 18.5]           ; place holder, run12 values, Sept. 29th, 2015

;;   !nika.flux_uranus  = [44.01,  18.44]
;;   !nika.flux_neptune = [17.16,   7.19]
;;   !nika.flux_mars    = [117.08, 39.50]

            ;; HA's values, June 6th, 2017
            !nika.flux_uranus = [44.440000, 17.210000, 44.440000]
            !nika.flux_neptune = [16.640000, 6.9900000, 16.640000]
            !nika.flux_mars = [175.88000, 58.140000, 175.88000]


            ;; No values yet
            !nika.flux_saturn  = [1181.45, 400.29] ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_ceres   = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_pallas  = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_vesta   = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_lutetia = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_3c84    = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
         end

         '15':begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.sign_angle   = 1

            !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015
            ;; !nika.fwhm_nom = [12.5, 18.5]           ; place holder, run12 values, Sept. 29th, 2015

;;   !nika.flux_uranus  = [39.1377, 16.4049]
;;   !nika.flux_neptune = [15.4503, 6.47609]
;;   !nika.flux_mars    = [274.113, 92.4645]

            ;; HA's values, June 6th, 2017
            !nika.flux_uranus = [40.620000, 15.730000, 40.620000]
            !nika.flux_neptune = [15.760000, 6.6200000, 15.760000]
            !nika.flux_mars = [319.71000, 105.62000, 319.71000]


            !nika.flux_mercury = [1723.05, 576.886]

            ;; No values yet
            !nika.flux_saturn  = [1181.45, 400.29] ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_ceres   = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_pallas  = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_vesta   = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_lutetia = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015
            !nika.flux_3c84    = [0.d0, 0.d0]      ; place holder, run12 values, Sept. 29th, 2015

            nu = !const.c/(!nika.lambda*1e-3)/1.0d9
            !nika.flux_mwc349  = 1.69d0*(nu/227.)^0.26
         end

         '16':begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
;;    !nika.zigzag       = [-22.953526, -11.020320, -22.799646] ; march 11th, 2016

;;   !nika.zigzag = [23.7, 12.3, 23.88] ; Apr. 17th, 2016 (see
;;   check_zigzag_2.pro, test case on a single scan

;;    Apr. 18th, 2016 (see
;;    check_zigzag_2.pro)
            ;; average value on 24 scans:
;;   !nika.zigzag = [23.75, 11.77, 23.46]*1d-3

            ;; Aug. 11th, 2016
            ;; !nika.zigzag = [23.75, 11.77, 23.46]*1d-3
            ;; !nika.zigzag = 12.9*1d-3
            !nika.zigzag = [23.75, 11.77, 23.46]*1d-3
            
            !nika.sign_angle   = 1
            
            !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015
            ;; !nika.fwhm_nom = [12.5, 18.5]           ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5]   ; place holder, run12 values, Sept. 29th, 2015
            
;;   !nika.flux_uranus  = [36.4466, 15.2768]
;;   !nika.flux_neptune = [15.2350, 6.38585]
;;   !nika.flux_mars    = [721.117, 242.987]

            ;; HA's values, June 6th, 2017
            !nika.flux_uranus = [38.270000, 14.820000, 38.270000]
            !nika.flux_neptune = [15.550000, 6.5300000, 15.550000]
            !nika.flux_mars = [666.46000, 218.49000, 666.46000]



            !nika.flux_mercury = [426.495, 142.793]

            ;; No values yet
            !nika.flux_saturn  = [0.d0, 0.d0]
            !nika.flux_ceres   = [0.d0, 0.d0]
            !nika.flux_pallas  = [0.d0, 0.d0]
            !nika.flux_vesta   = [0.d0, 0.d0]
            !nika.flux_lutetia = [0.d0, 0.d0]
            !nika.flux_3c84    = [0.d0, 0.d0]

            nu = !const.c/(!nika.lambda*1e-3)/1.0d9
            !nika.flux_mwc349  = 1.69d0*(nu/227.)^0.26
         end

;; Sept-oct 2016
         '18':begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0

            ;; Oct. 4th, 2016, based on scan 20160925s334
            !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
            
            !nika.sign_angle   = 1
            
            ;; !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.grid_step = [9.8, 13.3, 9.7] ; see Nika2Run1/check_grid_step + Xav;   http://www.iram.fr/wiki/nika2/index.php/April_19,_2017,_FXD,_KID_position_mapping_and_Field_distortion_for_Run9
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015
            ;; !nika.fwhm_nom = [12.5, 18.5]           ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5]   ; place holder, run12 values, Sept. 29th, 2015
            
;;    !nika.flux_uranus  = [43.96, 18.42]
;;    !nika.flux_neptune = [17.143, 7.185]
;;    !nika.flux_mars    = [586.4, 197.6]

            ;; HA's values, June 6th, 2017
            !nika.flux_uranus = [46.090000, 17.850000, 46.090000]
            !nika.flux_neptune = [17.240000, 7.2400000, 17.240000]
            !nika.flux_mars = [439.23000, 146.24000, 439.23000]


            !nika.flux_mercury = [595.5, 200.1]
            !nika.flux_venus   = [2591.6, 867.7]

            ;; No values yet

            !nika.flux_ceres   = [0.d0, 0.d0]
            !nika.flux_pallas  = [0.d0, 0.d0]
            !nika.flux_vesta   = [0.d0, 0.d0]
            !nika.flux_lutetia = [0.d0, 0.d0]
            !nika.flux_3c84    = [0.d0, 0.d0]

            nu = !const.c/(!nika.lambda*1e-3)/1.0d9
            !nika.flux_mwc349  = 1.69d0*(nu/227.)^0.26
         end

         '19':begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0

            ;; Oct. 4th, 2016, based on scan 20160925s334
            !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
            
            !nika.sign_angle   = 1
            
            ;; !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.grid_step = [9.8, 13.3, 9.7] ; see Nika2Run1/check_grid_step + Xav;   http://www.iram.fr/wiki/nika2/index.php/April_19,_2017,_FXD,_KID_position_mapping_and_Field_distortion_for_Run9
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015
            ;; !nika.fwhm_nom = [12.5, 18.5]           ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5]   ; place holder, run12 values, Sept. 29th, 2015
            
;;    !nika.flux_uranus  = [43.96, 18.42]
;;    !nika.flux_neptune = [17.143, 7.185]
;;    !nika.flux_mars    = [586.4, 197.6]

            ;; HA's values, June 6th, 2017
            !nika.flux_uranus = [46.090000, 17.850000, 46.090000]
            !nika.flux_neptune = [17.240000, 7.2400000, 17.240000]
            !nika.flux_mars = [439.23000, 146.24000, 439.23000]


            !nika.flux_mercury = [595.5, 200.1]
            !nika.flux_venus   = [2591.6, 867.7]

            ;; No values yet

            !nika.flux_ceres   = [0.d0, 0.d0]
            !nika.flux_pallas  = [0.d0, 0.d0]
            !nika.flux_vesta   = [0.d0, 0.d0]
            !nika.flux_lutetia = [0.d0, 0.d0]
            !nika.flux_3c84    = [0.d0, 0.d0]

            nu = !const.c/(!nika.lambda*1e-3)/1.0d9
            !nika.flux_mwc349  = 1.69d0*(nu/227.)^0.26
         end

;; Dec. 2016
         '20':begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0

            ;; Oct. 4th, 2016, based on scan 20160925s334
            !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
            
            !nika.sign_angle   = 1
            
;   !nika.grid_step = [9.3, 11.1, 9.7]      ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.grid_step = [9.8, 13.3, 9.7] ; see Nika2Run1/check_grid_step + Xav;   http://www.iram.fr/wiki/nika2/index.php/April_19,_2017,_FXD,_KID_position_mapping_and_Field_distortion_for_Run9
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015
            ;; !nika.fwhm_nom = [12.5, 18.5]           ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5]   ; place holder, run12 values, Sept. 29th, 2015

            ;; http://www.iram.es/IRAMES/mainWiki/ListOfAstroTargetNika2Run7
            ;; fluxes from GILDAS as of Dec. 7th
;;   !nika.flux_uranus  = [42.28d0, 17.721d0]
;;   !nika.flux_neptune = [16.101d0, 6.7149d0]
;;   !nika.flux_mars    = [320.7d0, 108.1d0]

            ;; HA's values, June 6th, 2017
            !nika.flux_uranus = [44.140000, 17.090000, 44.140000]
            !nika.flux_neptune = [16.460000, 6.9100000, 16.460000]
            !nika.flux_mars = [311.78000, 103.98000, 311.78000]



            !nika.flux_mercury = [643.d0, 215.d0]
            !nika.flux_venus   = [5281.d0, 1768.d0]

            ;; No values yet
            !nika.flux_ceres   = [0.d0, 0.d0]
            !nika.flux_pallas  = [0.d0, 0.d0]
            !nika.flux_vesta   = [0.d0, 0.d0]
            !nika.flux_lutetia = [0.d0, 0.d0]
            !nika.flux_3c84    = [0.d0, 0.d0]

            nu = !const.c/(!nika.lambda*1e-3)/1.0d9
            !nika.flux_mwc349  = 1.69d0*(nu/227.)^0.26
         end

;; Jan 2017: values from Dec. 16 for now (NP, Jan. 23rd 2017)
         '21': begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0

            ;; Oct. 4th, 2016, based on scan 20160925s334
            !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
            
            !nika.sign_angle   = 1
            
            ;; !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.grid_step = [9.8, 13.3, 9.7] ; see Nika2Run1/check_grid_step + Xav;   http://www.iram.fr/wiki/nika2/index.php/April_19,_2017,_FXD,_KID_position_mapping_and_Field_distortion_for_Run9

            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015
            ;; !nika.fwhm_nom = [12.5, 18.5]           ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5]   ; place holder, run12 values, Sept. 29th, 2015

            ;; http://www.iram.es/IRAMES/mainWiki/ListOfAstroTargetNika2Run7
            ;; fluxes from GILDAS as of Dec. 7th
;;   !nika.flux_uranus  = [42.28d0, 17.721d0]
;;   !nika.flux_neptune = [16.101d0, 6.7149d0]
;;   !nika.flux_mars    = [320.7d0, 108.1d0]

            ;; HA's values, June 6th, 2017
            !nika.flux_uranus = [41.820000, 16.190000, 41.820000]
            !nika.flux_neptune = [15.920000, 6.6800000, 15.920000]
            !nika.flux_mars = [239.37000, 79.540000, 239.37000]


            !nika.flux_mercury = [643.d0, 215.d0]
            !nika.flux_venus   = [5281.d0, 1768.d0]

            ;; No values yet
            !nika.flux_ceres   = [0.d0, 0.d0]
            !nika.flux_pallas  = [0.d0, 0.d0]
            !nika.flux_vesta   = [0.d0, 0.d0]
            !nika.flux_lutetia = [0.d0, 0.d0]
            !nika.flux_3c84    = [0.d0, 0.d0]

            nu = !const.c/(!nika.lambda*1e-3)/1.0d9
            !nika.flux_mwc349  = 1.69d0*(nu/227.)^0.26
         end

;; Feb. 2017, Run22 = Nika2 Run9
         '22': begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0

            ;; Oct. 4th, 2016, based on scan 20160925s334
            !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
            
            !nika.sign_angle   = 1
            
            ;; !nika.grid_step = [9.3, 11.1, 9.7] ; see Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            !nika.grid_step = [9.8, 13.3, 9.7] ; see Nika2Run1/check_grid_step + Xav;   http://www.iram.fr/wiki/nika2/index.php/April_19,_2017,_FXD,_KID_position_mapping_and_Field_distortion_for_Run9

            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015


            ;; !nika.fwhm_nom = [12.5, 18.5]   ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5] ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_nom   = [11.3, 17.98]         ; JFL's email, Feb. 27th, 2017
            ;; !nika.fwhm_array = [11.35, 17.98, 11.24] ; JFL's email, Feb. 27th, 2017



;;    ;; http://www.iram.es/IRAMES/mainWiki/ListOfAstroTargetNika2Run9
;;    ;; Rough fluxes from Gildas (as for the 24th of February 2017), FXD 21/02/2017
;;    !nika.flux_uranus  = [37.33, 15.65]
;;    !nika.flux_mars    = [169.9, 57.26]
;;    !nika.flux_neptune = [15.24, 6.386]
            !nika.flux_mercury = [405, 135, 405]
            !nika.flux_venus   = [32434, 10859, 32434]

            ;;----------------------
            ;; JFL value's Feb. 2017, 24th
;;   !nika.flux_uranus  = [37.361,16.409,37.993]
;;   !nika.flux_neptune = [15.328,6.788,15.605]
;;   !nika.flux_Mars    = [167.80,57.88,167.80]

            ;; HA's values, June 6th, 2017
            !nika.flux_uranus = [39.080000, 15.130000, 39.080000]
            !nika.flux_neptune = [15.560000, 6.5300000, 15.560000]
            !nika.flux_mars = [174.99000, 57.940000, 174.99000]

            !nika.flux_ceres   = [0.894,0.317,0.913]
            !nika.flux_vesta   = [0.999,0.354,1.020]
            !nika.flux_pallas  = [0.187,0.066,0.191]
            !nika.flux_Lutetia = [0.022,0.008,0.023]
;   Mars,run09,24-02-2017,165.03,56.77,165.96
;   Mars,run09,28-02-2017,160.76,55.12,160.76
            !nika.flux_MWC349  = [1.83,1.31,1.83]
            !nika.flux_CRL618  = [3.06,1.37,3.06]
            !nika.flux_CRL2688 = [3.03,0.83,3.03]
            !nika.flux_NGC7027 = [3.5,3.5,3.5]
            
            nu = !const.c/(!nika.lambda*1e-3)/1.0d9
            !nika.flux_mwc349  = 1.69d0*(nu/227.)^0.26
         end

;; Apr. 2017, Run23 = Nika2 Run10
         '23': begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0

            ;; Oct. 4th, 2016, based on scan 20160925s334
            !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
            
            !nika.sign_angle   = 1
            
;;;   !nika.grid_step = [9.3, 11.1, 9.7]      ; see
;;;   Nika2Run1/check_grid_step + Xavier's email of Dec. 29th, 2015
            
            !nika.grid_step = [9.8, 13.3, 9.7] ; see Nika2Run1/check_grid_step + Xav;   http://www.iram.fr/wiki/nika2/index.php/April_19,_2017,_FXD,_KID_position_mapping_and_Field_distortion_for_Run9
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015


            ;; !nika.fwhm_nom = [12.5, 18.5]   ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5] ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_nom   = [11.3, 17.98]         ; JFL's email, Feb. 27th, 2017
            ;; !nika.fwhm_array = [11.35, 17.98, 11.24] ; JFL's email, Feb. 27th, 2017

            ;; Fluxes as sent by Jean-Francois Lestrade, April 13th, 2017
            !nika.flux_mercury = [1750., 630., 1750.] ; [405, 135, 405]
            !nika.flux_venus   = [1290., 1244., 1290.] ; [32434, 10859, 32434]

            ;;----------------------
            ;; JFL value's Apr. 18th, 2017
;;   !nika.flux_uranus  = [36.00, 15.92, 36.66]
;;   !nika.flux_neptune = [15.61, 6.98, 15.91]
;;   !nika.flux_Mars    = [124.10, 42.73, 121.22] ; [167.80,57.88,167.80]

            ;; HA's values, June 6th 2017
            !nika.flux_uranus = [37.960000, 14.700000, 37.960000]
            !nika.flux_neptune = [15.890000, 6.6700000, 15.890000]
            !nika.flux_mars = [123.61000, 40.610000, 123.61000]



            !nika.flux_ceres   = [0.742, 0.259, 0.742] ; [0.894,0.317,0.913]
            !nika.flux_vesta   = [0.496, 0.178, 0.496] ; [0.999,0.354,1.020]
            !nika.flux_pallas  = [0.202, 0.071, 0.202] ; [0.187,0.066,0.191]
            !nika.flux_Lutetia = [0.0112, 0.0039, 0.0112] ; [0.022,0.008,0.023]
            !nika.flux_MWC349  = [2.2, 1.6, 2.2]
            !nika.flux_CRL618  = [2.93, 1.36, 2.93]
            !nika.flux_CRL2688 = [3.03, 0.83, 3.03]
            !nika.flux_NGC7027 = [3.61, 4.42, 3.61]
            
            nu = !const.c/(!nika.lambda*1e-3)/1.0d9
            !nika.flux_mwc349  = 1.69d0*(nu/227.)^0.26
         end

;; June 2017, Run24 = NIKA2 Run 11
         '24': begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0

            !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
            
            !nika.sign_angle   = 1
            !nika.grid_step = [9.8, 13.3, 9.7] ; see Nika2Run1/check_grid_step + Xav;   http://www.iram.fr/wiki/nika2/index.php/April_19,_2017,_FXD,_KID_position_mapping_and_Field_distortion_for_Run9
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015

            ;; !nika.fwhm_nom = [12.5, 18.5]   ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5] ; place holder, run12 values, Sept. 29th, 2015

            ;; Herve Aussel's values, June 2nd, 2017
            !nika.flux_uranus  = [39.49, 15.29, 39.49]
            !nika.flux_neptune = [16.73, 7.02, 16.73]
            !nika.flux_Mars    = [102.08, 33.68, 102.08]
         end

;; Oct. 2017, Run25 = NIKA2 Run12
         '25': begin
            !nika.run          = run

            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0

            !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
            
            !nika.sign_angle   = 1
            !nika.grid_step = [9.8, 13.3, 9.7] ; see Nika2Run1/check_grid_step + Xav;   http://www.iram.fr/wiki/nika2/index.php/April_19,_2017,_FXD,_KID_position_mapping_and_Field_distortion_for_Run9
            !nika.lambda   = [1.1530479, 1.9986164] ; Confirmed by Xavier's email, Oct. 4th, 2015

            ;; !nika.fwhm_nom = [12.5, 18.5]   ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5] ; place holder, run12 values, Sept. 29th, 2015

            ;; HA's values, Oct, 2017
            !nika.flux_uranus  = [46.46, 17.99, 46.46]
            !nika.flux_neptune = [17.34, 7.28, 17.34]
            !nika.flux_Mars    = [115.38, 37.86, 115.38]
         end

;; Nov. 2017, Run26 = NIKA2 Run13 (polarization)
         '26': begin
            !nika.run          = run
            !nika.retard       = 0.d0
            !nika.ptg_shift    = 0d0
            !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
            
            !nika.sign_angle   = 1
            !nika.grid_step = [9.8, 13.3, 9.7]
            !nika.lambda   = [1.1530479, 1.9986164]

            ;; !nika.fwhm_nom = [12.5, 18.5]   ; place holder, run12 values, Sept. 29th, 2015
            ;; !nika.fwhm_array = [12.5, 18.5, 12.5] ; place holder, run12 values, Sept. 29th, 2015

            ;; HA's values, Nov. 2017
            !nika.flux_uranus  = [45.51, 17.62, 45.51]
            !nika.flux_neptune = [16.80, 7.05, 16.80]
            !nika.flux_Mars    = [138.06, 45.58, 138.06]
         end

      endcase

   endif else begin

      if long(run) ge 27 then begin
         
         !nika.run          = run
         !nika.retard       = 0.d0
         !nika.ptg_shift    = 0d0
         !nika.zigzag = [14.d0, 14.d0, 14.d0]*1d-3
         
         !nika.sign_angle   = 1
         !nika.grid_step = [9.8, 13.3, 9.7]
         !nika.lambda   = [1.1530479, 1.9986164]
         
         ;; !nika.fwhm_nom = [12.5, 18.5]      ; place holder, run12 values, Sept. 29th, 2015
         ;; !nika.fwhm_array = [12.5, 18.5, 12.5] ; place holder, run12 values, Sept. 29th, 2015
         
;; Place holders
;; These values will be overwritten when the scan is passed to the pipeline
;; to have more accurate fluxes per day
         !nika.flux_uranus  = [41.73, 16.16, 41.73]
         !nika.flux_neptune = [15.84, 6.65, 15.84]
         !nika.flux_Mars    = [216.07, 71.28, 216.07]
         
         if keyword_set(day) then begin
            readcol, !nika.pipeline_dir+"/IDLtools/uranus.txt", input_day, flux_2mm, flux_1mm, comment="#", /silent, format='A,D,D'
;;             w = where( long(input_day) eq long(day), nw)
;;             if nw eq 0 then begin
;;                message, /info, "/day is set but does not match the ascii input file uranus.txt"
;;                print, day   ;; FXD April 2020 stop
;;             endif else begin
;;                !nika.flux_uranus = [flux_1mm[w], flux_2mm[w], flux_1mm[w]]
;;             endelse
;;             
;;             readcol, !nika.pipeline_dir+"/IDLtools/mars.txt", input_day, flux_2mm, flux_1mm, comment="#", /silent, format='A,D,D'
;;             w = where( long(input_day) eq long(day), nw)
;;             if nw eq 0 then begin
;;                message, /info, "/day is set but does not match the ascii input file mars.txt"
;;                ;;stop
;;             endif else begin
;;                !nika.flux_mars = [flux_1mm[w], flux_2mm[w], flux_1mm[w]]
;;             endelse
;;             
;;             readcol, !nika.pipeline_dir+"/IDLtools/neptune.txt", input_day, flux_2mm, flux_1mm, comment="#", /silent, format='A,D,D'
;;             w = where( long(input_day) eq long(day), nw)
;;             if nw eq 0 then begin
;;                message, /info, "/day is set but does not match the ascii input file neptune.txt"
;;                ;;stop
;;             endif else begin
;;                !nika.flux_neptune = [flux_1mm[w], flux_2mm[w], flux_1mm[w]]
;;             endelse

;            planets = ['uranus', 'mars', 'neptune']
            planets = ['uranus']
            for iplanet=0, n_elements(planets)-1 do begin
               readcol, !nika.pipeline_dir+"/IDLtools/"+planets[iplanet]+".txt", $
                        input_day, flux_2mm, flux_1mm, comment="#", /silent, format='D,D,D'
               ;; day_diff = abs( long(input_day)-long(day))

               y = float( strmid( strtrim( long( input_day),2),0,4))
               m = float( strmid( strtrim( long( input_day),2),4,2))
               d = float( strmid( strtrim( long( input_day),2),6,2))

               yy = float( strmid( strtrim( long( day),2),0,4))
               mm = float( strmid( strtrim( long( day),2),4,2))
               dd = float( strmid( strtrim( long( day),2),6,2))

               ;; approx, no need to account to odd/even months at this stage
               day_diff = (yy-y)*365. + (mm-m)*30 + dd-d

               w = where( day_diff eq min(day_diff))
               ;; check i'm not too far from a reference pool
               if day_diff[w[0]] gt 60 then begin
                  message, /info, "The day of the current observation is "+strtrim(day_diff[w],2)+" away"
                  message, /info, "from the closest calibration ref day in "+!nika.pipeline_dir+"/IDLtools/"+planets[iplanet]+".txt"
                  message, /info, "The abs. calibration is therefore insecure."
               endif
               junk = execute( "!nika.flux_"+planets[iplanet]+" = [flux_1mm[w[0]], flux_2mm[w[0]], flux_1mm[w[0]]]")
            endfor

         endif
      endif else begin
         message, /info, "Run "+run+" has is not defined in fill_nika_struct.pro"
         stop
      endelse
   endelse
endelse

;; Force for all NIKA2 runs for now
;; Helene and Nico, Oct. 2020:
!nika.zigzag = double( [11., 11., 11.]*1d-3)


end
