;+
;PURPOSE: Provide a default analysis parameter structure
;
;INPUT: none
;
;OUTPUT: The parameter structure
;
;KEYWORDS:
;
;LAST EDITION: 
;   24/09/2013: creation (adam@lpsc.in2p3.fr)
;   30/09/2013: add profile and photometry parameters
;   06/07/2015: add local_bg option
;-

pro nika_anapipe_default_param, anapar


  ;;------- The plot of the flux maps
  flux_map = {apply: 'yes',$                       ;Plot of the flux maps
              fov:0.0,$                            ;FOV, if you chage to non zero it will be used
              noise_max:2.0,$                      ;We plot up to noise_max x min(noise_map)
              range1mm:[0.0,0.0],$                 ;1mm map range, if you chage to non zero it will be used
              range2mm:[0.0,0.0],$                 ;2mm map range, if you chage to non zero it will be used
              conts1mm:dblarr(100)+!values.f_nan,$ ;Give non NaN values that are used as contours
              conts2mm:dblarr(100)+!values.f_nan,$ ;Give non NaN values that are used as contours
              unit:'mJy/beam',$                    ;Map units: 'Jy/beam' or 'mJy/beam' or 'MJy/sr'
              beam:{a:12.5,b:18.5},$               ;Main beam size for Jy/beam->MJy/sr conversion
              beam_factor:{a:1.5, b:1.4},$         ;Beam total/main beam for Jy/beam->MJy/sr conversion
              type:'abs_coord',$                   ;'abs_coord' or 'offset' 
              col_conts:0,$                        ;Contour color
              thick_conts:1.5,$                    ;Contour thickness
              relob:{a:0.0,b:0.0}}                 ;Map smmothing for plot

  ;;------- The plot of the noise maps
  noise_map = {apply: 'yes',$                       ;Plot of the stddev maps
               fov:0.0,$                            ;FOV, if you chage to non zero it will be used
               range1mm:[0.0,0.0],$                 ;1mm map range, if you chage to non zero it will be used
               range2mm:[0.0,0.0],$                 ;2mm map range, if you chage to non zero it will be used
               conts1mm:dblarr(100)+!values.f_nan,$ ;Give non NaN values that are used as contours
               conts2mm:dblarr(100)+!values.f_nan,$ ;Give non NaN values that are used as contours
               unit:'mJy/beam',$                    ;Map units: 'Jy/beam' or 'mJy/beam' or 'MJy/sr'
               beam:{a:12.5,b:18.5},$               ;Main beam size for Jy/beam->MJy/sr conversion
               beam_factor:{a:1.5, b:1.4},$         ;Beam total/main beam for Jy/beam->MJy/sr conversion
               type:'abs_coord',$                   ;'abs_coord' or 'offset' 
               col_conts:0,$                        ;Contour color
               thick_conts:1.5,$                    ;Contour thickness
               relob:{a:0.0,b:0.0}}                 ;Map smmothing for plot
  
  ;;------- The plot of the time maps
  time_map = {apply: 'yes',$       ;Plot of the time per pixel maps
              fov:0.0,$            ;FOV, if you chage to non zero it will be used
              range1mm:[0.0,0.0],$ ;1mm map range, if you chage to non zero it will be used
              range2mm:[0.0,0.0],$ ;2mm map range, if you chage to non zero it will be used
              type:'abs_coord',$   ;'abs_coord' or 'offset' 
              relob:{a:0.0,b:0.0}} ;Map smmothing for plot

  ;;------- The plot of the SNR maps
  snr_map = {apply: 'yes',$                       ;Plot of the SNR maps
             fov:0.0,$                            ;FOV, if you chage to non zero it will be used
             range1mm:[0.0,0.0],$                 ;1mm map range, if you chage to non zero it will be used
             range2mm:[0.0,0.0],$                 ;2mm map range, if you chage to non zero it will be used
             conts1mm:dblarr(100)+!values.f_nan,$ ;Give non NaN values that are used as contours
             conts2mm:dblarr(100)+!values.f_nan,$ ;Give non NaN values that are used as contours
             beam:{a:12.5,b:18.5},$               ;Main beam size for Jy/beam->MJy/sr conversion
             type:'abs_coord',$                   ;'abs_coord' or 'offset' 
             col_conts_n:255,$                    ;Contour color
             col_conts_p:0,$                      ;Contour color
             thick_conts:1.5,$                    ;Contour thickness
             relob:{a:0.0,b:0.0}}                 ;Map smmothing for plot (assumes correlation free noise)

  ;;------- The beam study
  beam = {apply: 'no',$                ;Go to the module beam
          make_products:'no',$         ;Compute and save beam pattern profile in a FITS file 
          dispersion:'no',$            ;Compute the results for all scans
          range_disp:[90.0,110.0], $   ;Range for beam volume dispersion estimates
          per_kid:'no',$               ;Compute the results for all KIDs
          fsl:'no',$                   ;Plots that shows the far side lobe
          fov:0.0,$                    ;Plots that shows the far side lobe
          range_fsl1mm:[-1e-3, 1e-3],$ ;Range for far side lobe map saturated
          range_fsl2mm:[-1e-3, 1e-3],$ ;Range for far side lobe map saturated
          oplot:'no',$                 ;Overplot the profile of a given triple beam, default is iram beam patern
          beam1:{A:10.5,B:16.0},$      ;Main beam FWHM overplotted
          beam2:{A:125.0,B:175.0},$    ;Second beam FWHM overplotted
          beam3:{A:180.0,B:280.0},$    ;Third beam FWHM overplotted
          amp1:{A:0.975,B:1.0},$       ;Main beam amplitude overplotted
          amp2:{A:0.005,B:0.0015},$    ;Secondary beam amplitude overplotted
          amp3:{A:0.001,B:0.00055},$   ;Third beam amplitude overplotted
          flux:{A:1.0,B:1.0},$         ;Flux of the injected source (in case of simu)
          model_ratio:'no'}            ;Plot the measured/injected beam ratio profile
  
  ;;------- The profile
  profile = {apply:'no',$                               ;Compute profiles
             method:'default',$                         ;Either 'default', 'coord' or 'offset'
             nb_prof:1,$                                ;Number of profiles requiered (up to 5)
             coord:replicate({ra:[0.0,0.0,0.0], $       ;Center profiles R.A. coordinates
                              dec:[0.0,0.0,0.0]}, 10),$ ;Center profiles Dec. coordinates
             offset:dblarr(10,2),$                      ;Center profile offsets
             yr1mm:dblarr(10,2),$                       ;Y range 1mm
             yr2mm:dblarr(10,2),$                       ;Y range 2mm
             xr:dblarr(10,2),$                          ;X range
             nb_pt:100,$                                ;Number of points in the profile
             save_fits:'no'}                            ;Save the profile as fits file
  
  ;;------- The point source photometry study
  ps_photo = {apply: 'no',$                              ;Compute point source fluxes
              nb_source:1,$                              ;number of source for which we do photometry
              method:'default',$                         ;Either 'default', 'coord' or 'offset'
              per_scan:'no',$                            ;Do this for all indiv. scans
              coord:replicate({ra:[0.0,0.0,0.0], $       ;Center source R.A. coordinates
                               dec:[0.0,0.0,0.0]}, 50),$ ;Center source Dec. coordinates
              offset:dblarr(50,2),$                      ;Center source offsets ([dx,dy])
              allow_shift:'no',$                         ;Allow the source position to change within the fit
              local_bg:'no', $                           ;'yes' to define the baground within 3 FWHM
              search_box:[!values.f_nan,!values.f_nan],$ ;Box size allowed for the source location.
              ;;                                          If set to a number, the source location is
              ;;                                          fitted within the box centered on the given coordinates
              beam:{A:12.5,B:18.5}} ;Force beam to this value. If 0 then beam size is free param and then it fits it
  
  ;;------- Aperture photometry study
  dif_photo = {apply: 'no',$
               nb_source:1,$                              ;number of source for which we do photometry
               method:'default',$                         ;Either 'default', 'coord' or 'offset'
               per_scan:'no',$                            ;Do this for all indiv. scans
               coord:replicate({ra:[0.0,0.0,0.0], $       ;Center source R.A. coordinates
                                dec:[0.0,0.0,0.0]}, 10),$ ;Center source Dec. coordinates
               offset:dblarr(10,2),$                      ;Center source offsets ([dx,dy])
               r0:dblarr(10)+!values.f_nan,$              ;radius up to which we give the flux 
               r1:dblarr(10)+!values.f_nan,$              ;zero level corrected from mean(map) between r0 and r1.
               ;;                                         Not donne if NaN (default)
               beam_cor:{A:1.5,B:1.4},$ ;Total beam/main beam
               beam:{A:12.5,B:18.5}}    ;Assumed beam

  ;;------- Map per detector
  mapperkid = {apply: 'no',$         ;Do you want to compute a map per detector?
               range1mm:[0.0,0.0],$  ;give the range of the 1mm map (zero = free range)
               range2mm:[0.0,0.0],$  ;give the range of the 2mm map (zero = free range)
               relob:{a:0.0,b:0.0},$ ;give the arcsec fwhm used to smooth the maps
               unit:'Jy/beam',$      ;Map units: 'Jy/beam' or 'mJy/beam' or 'MJy/sr'
               allbar:'no'}          ;'no' is one unit bar for all kids and 'yes' is one bar per map
  
  ;;------- Map per scan
  mapperscan = {apply: 'no',$         ;Do you want to compute a map per scan?
                range1mm:[0.0,0.0],$  ;give the range of the 1mm map (zero = free range)
                range2mm:[0.0,0.0],$  ;give the range of the 2mm map (zero = free range)
                relob:{a:0.0,b:0.0},$ ;give the arcsec fwhm used to smooth the maps
                allbar:'no'}          ;'no' is one unit bar for all scan and 'yes' is one bar per scan
  
  ;;------- color ratio study
  spectrum = {apply: 'no',$                     ;Compute color ratio between the two bands
              beam:{a:12.5,b:18.5},$            ;FWHM of the beams
              reso:20.0,$                       ;Resolution of the spectrum map
              fov:0.0,$                         ;FOV, if you chage to non zero it will be used
              range:[0.0,0.0],$                 ;map range, if you chage to non zero it will be used
              snr_cut1mm:2.0,$                  ;Cut the map where snr less than this at 1mm
              snr_cut2mm:2.0,$                  ;Cut the map where snr less than this at 2mm
              conts:dblarr(100)+!values.f_nan,$ ;Give non NaN values that are used as contours
              beam_factor:{a:1.5, b:1.4},$      ;Beam total/main beam for Jy/beam->MJy/sr conversion
              type:'abs_coord',$                ;'abs_coord' or 'offset' 
              col_conts:0,$                     ;Contour color
              thick_conts:1.5}                  ;Contour thickness

  ;;------- The noise study
  noise_meas = {apply: 'no',$
                per_kid:'no',$                           ;Do the noise study per KID
                dist_nfwhm:1.5,$                         ;Do the noise study per KID
                beam:{a:12.5,b:18.5},$                   ;Beam FWHM
                vs_tau:'no',$                            ;Measure sigma versus tau
                spec:'no', $                             ;Compute noise power spectrum
                noise_spec1:[1.0,1.0],$                  ;Noise Pk = noise_spec1+noise_spec2^noise_spec3
                noise_spec2:[0.0,0.0],$                  ;for the two bands
                noise_spec3:[0.0,0.0],$                  ;
                noise_Nmc:3,$                            ;Noise number of MC realization
                noise_NJK:1,$                            ;Noise number of MC realization
                JK:{fov:0.0,$                            ;Flag away from N * FWHM/2
                    noise_max:2.0,$                      ;We plot up to noise_max x min(noise_map)
                    range1mm:[0.0,0.0],$                 ;1mm map range, if you chage to non zero it will be used
                    range2mm:[0.0,0.0],$                 ;2mm map range, if you chage to non zero it will be used
                    conts1mm:dblarr(100)+!values.f_nan,$ ;Give non NaN values that are used as contours
                    conts2mm:dblarr(100)+!values.f_nan,$ ;Give non NaN values that are used as contours
                    unit:'mJy/beam',$                    ;Map units: 'Jy/beam' or 'mJy/beam' or 'MJy/sr'
                    beam:{a:12.5,b:18.5},$               ;Main beam size for Jy/beam->MJy/sr conversion
                    beam_factor:{a:1.5, b:1.4},$         ;Beam total/main beam for Jy/beam->MJy/sr conversion
                    type:'abs_coord',$                   ;'abs_coord' or 'offset' 
                    col_conts:0,$                        ;Contour color
                    thick_conts:1.5,$                    ;Contour thickness
                    relob:{a:0.0,b:0.0}}}                ;Map smmothing for plot

  ;;------- Search point source in a dusty map using Mexican Hat like filter
  search_ps = {apply:'no',$
               fwhm1:{a:8.5,b:12.5},$  ;Inner hat FWHM (also for Fourier)
               fwhm2:{a:37.5,b:55.5},$ ;Outer hat FWHM
               type:'abs_coord',$      ;'abs_coord' or 'offset' 
               fov:0.0,$               ;FOV, if you chage to non zero it will be used
               range1mm:[0.0,0.0],$    ;1mm map range, if you chage to non zero it will be used
               range2mm:[0.0,0.0],$    ;2mm map range, if you chage to non zero it will be used
               nsigma:4.0}             ;Number of sigma for flagging sources

  ;;------- Comupte the transfer function with spectra
  trans_func_spec = {apply:'no', $
                     map_in:{a:'',b:''}, $     ;Input simulation maps
                     map_noise:{a:'',b:''}, $  ;Noise only  maps
                     map_signal:{a:'',b:''}, $ ;Signal + noise map
                     mask:'no', $              ;Apply a mask of unsampled regions
                     beam:{a:12.5,b:18.5},$    ;Main beam size for Jy/beam->MJy/sr conversion
                     NIKA_FOV:{a:1.8,b:1.8}}   ;NIKA field of view
  
  ;;------- Comupte the transfer as a profile
  trans_func_prof = {apply:'no', $
                     map_in:{a:'',b:''}, $                   ;Input simulation maps
                     method:'offset', $                      ;Either 'coord' or 'offset'
                     coord:{ra:[0.0,0.0,0.0], $              ;Center profiles R.A. coordinates
                            dec:[0.0,0.0,0.0]}, $            ;Center profiles Dec. coordinates
                     offset:dblarr(2), $                     ;Center profile offsets
                     xr:[!values.f_nan, !values.f_nan], $    ;Range for the plot
                     yr1mm:[!values.f_nan, !values.f_nan], $ ;
                     yr2mm:[!values.f_nan, !values.f_nan], $ ;
                     nb_pt:100, $                            ;Number of points in the profile
                     make_fits:'no'}

  ;;------- Correct the zero level by hand
  cor_zerolevel = {a:0.0, $
                   b:0.0}
  
  ;;=============================================
  ;;------- Create the structure
  anapar = {flux_map:flux_map,$
            noise_map:noise_map,$
            time_map:time_map,$
            snr_map:snr_map,$
            profile:profile,$
            beam:beam,$
            ps_photo:ps_photo,$
            dif_photo:dif_photo,$
            mapperkid:mapperkid,$
            mapperscan:mapperscan,$
            spectrum:spectrum,$
            noise_meas:noise_meas,$
            search_ps:search_ps,$
            trans_func_spec:trans_func_spec,$
            trans_func_prof:trans_func_prof,$
            cor_zerolevel:cor_zerolevel}
  
  return
end
