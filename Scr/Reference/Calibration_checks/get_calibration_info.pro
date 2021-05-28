;+
; AIM: estimation of the absolute calibration from the primary
; calibrator scans of a campaign
;
; INPUT: list of info structure of all calibrator scans, as output
; from e.g.  get_all_scan_result_file.pro
;
; OUTPUT: 
;       -- wselect : index of the selected scans
;       -- calibration_info : structure of info on the absolute calibration
;
;-   
pro get_calibration_info, allscan_info, wselect, calibration_info
  
  
  calibration_info = create_struct( "nika2run", strarr(2), $
                                    "cryorun", 0, $
                                    "kidpar_ref", '', $
                                    "detector_ref", 0, $
                                    "skydip_ok", 1B, $
                                    "problem", 0B, $
                                    "baseline_selection", 0B, $
                                    "uranus_ntot", 0, $
                                    "uranus_nsel", 0, $
                                    "neptune_ntot", 0, $
                                    "neptune_nsel", 0, $
                                    "mwc349_ntot", 0, $
                                    "mwc349_nsel", 0, $
                                    "abs_calib_factors", dblarr(4))
  
  
  ;; remove known outliers
  ;;____________________________________________________________
  outlier_list =  [$
                  '20170223s16', $   ; dark test
                  '20170223s17', $   ; dark test
                  '20171024s171', $  ; focus scan
                  '20171026s235', $  ; focus scan
                  '20171028s313', $  ; RAS from tapas
                  '20180114s73', $   ; TBC
                  '20180116s94', $   ; focus scan
                  '20180118s212', $  ; focus scan
                  '20180119s241', $  ; Tapas comment: 'out of focus'
                  '20180119s242', $  ; Tapas comment: 'out of focus'
                  '20180119s243' $   ; Tapas comment: 'out of focus'                  
                  ]
  out_index = 1
  scan_list_ori = allscan_info.scan
  remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
  allscan_info = allscan_info[out_index]
  nscans = n_elements(allscan_info)
  
  th_flux_1mm_run = dblarr(nscans)
  th_flux_a2_run  = dblarr(nscans)
  th_flux_a1_run  = dblarr(nscans)
  th_flux_a3_run  = dblarr(nscans)

  
  get_nika2_run_info, nika2run_info
  nk_scan2run, allscan_info[0].scan, run
  calibration_info.cryorun = uint(run)
  nk_get_kidpar_ref, allscan_info[0].scan_num, allscan_info[0].day, info, kidpar_file
  calibration_info.kidpar_ref = kidpar_file
  calibration_info.detector_ref = !nika.ref_det[1]
  w=where(nika2run_info.cryorun eq uint(run), n)
  calibration_info.nika2run = nika2run_info[w].nika2run 

  
  
  ;; 
  ;;     scan selection
  ;;
  ;;________________________________________________________
  baseline  = 1
  practical = 0
  ;;
  ;; FIRST TRY: baseline scan selection
  ;;____________________________________________________________
  if baseline gt 0 then begin
     
     calibration_info.baseline_selection = 1
      
     to_use_photocorr = 0
     complement_index = 0
     beamok_index     = 0
     largebeam_index  = 0
     tauok_index      = 0
     hightau_index    = 0
     obsdateok_index  = 0
     afternoon_index  = 0
     fwhm_max         = 0
     nefd_index       = 0
     calibrator_scan_selection, allscan_info, wselect, $
                     to_use_photocorr=to_use_photocorr, complement_index=wout, $
                     beamok_index = beamok_index, largebeam_index = wlargebeam,$
                     tauok_index = tauok_index, hightau_index=whitau3, $
                     osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                     fwhm_max = fwhm_max, nefd_index = nefd_index
     
     ;;
     ;; ABSOLUTE CALIBRATION ON URANUS
     ;;____________________________________________________________
     ;; calib using the selection of Uranus scans
     w = where(strupcase(allscan_info.object) eq 'URANUS', ntot)
     wuranus = where(strupcase(allscan_info[wselect].object) eq 'URANUS', nuranus)
      
     wu = wselect[wuranus]
     calibration_info.uranus_ntot = ntot
     calibration_info.uranus_nsel = nuranus
      
     if nuranus gt 0 then begin   
        for ui=0, nuranus-1 do begin
           i = wu[ui]
           nk_scan2run, scan_list_run[i], run
           th_flux_1mm_run[i]     = !nika.flux_uranus[0]
           th_flux_a2_run[i]      = !nika.flux_uranus[1]
           th_flux_a1_run[i]      = !nika.flux_uranus[0]
           th_flux_a3_run[i]      = !nika.flux_uranus[0]
        endfor
     endif else begin
        ;; CALIBRATION ON NEPTUNE
         w = where(strupcase(allscan_info.object) eq 'NEPTUNE', ntot)
         wneptune = where(strupcase(allscan_info[wselect].object) eq 'NEPTUNE', nneptune)
         
         calibration_info.neptune_ntot  = ntot
         calibration_info.neptune_nsel  = nneptune
         wu = wselect[wneptune]
         
         if nneptune gt 0 then begin   
            for ui=0, nneptune-1 do begin
               i = wu[ui]
               nk_scan2run, scan_list_run[i], run
               th_flux_1mm_run[i]     = !nika.flux_neptune[0]
               th_flux_a2_run[i]      = !nika.flux_neptune[1]
               th_flux_a1_run[i]      = !nika.flux_neptune[0]
               th_flux_a3_run[i]      = !nika.flux_neptune[0]
            endfor
         endif else practical = 1
      endelse
   endif

   ;; SECOND TRY: tweaked scan selection
   ;;____________________________________________________________
   if practical gt 0 then begin
      print, '========================'
      print, ''
      print, '  PRACTICAL SCAN SELECTION '
      print, ''
      print, '========================'
      calibration_info.baseline_selection = 0
      to_use_photocorr = 0
      complement_index = 0
      beamok_index     = 0
      largebeam_index  = 0
      tauok_index      = 0
      hightau_index    = 0
      obsdateok_index  = 0
      afternoon_index  = 0
      fwhm_max         = 0
      nefd_index       = 0
      practical_scan_selection, allscan_info, wselect, $
                      to_use_photocorr=to_use_photocorr, complement_index=wout, $
                      beamok_index = beamok_index, largebeam_index = wlargebeam,$
                      tauok_index = tauok_index, hightau_index=whitau3, $
                      osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                      fwhm_max = fwhm_max, nefd_index = nefd_index
      
      ;;
      ;; ABSOLUTE CALIBRATION ON URANUS
      ;;____________________________________________________________
      ;; calib using the selection of Uranus scans
      w = where(strupcase(allscan_info.object) eq 'URANUS', ntot)
      wuranus = where(strupcase(allscan_info[wselect].object) eq 'URANUS', nuranus)
      
      wu = wselect[wuranus]
      calibration_info.uranus_ntot   = ntot
      calibration_info.uranus_nsel   = nuranus
      
      if nuranus gt 0 then begin   
         for ui=0, nuranus-1 do begin
            i = wu[ui]
            nk_scan2run, scan_list_run[i], run
            th_flux_1mm_run[i]     = !nika.flux_uranus[0]
            th_flux_a2_run[i]      = !nika.flux_uranus[1]
            th_flux_a1_run[i]      = !nika.flux_uranus[0]
            th_flux_a3_run[i]      = !nika.flux_uranus[0]
         endfor
      endif else begin
         ;; CALIBRATION ON NEPTUNE
         w = where(strupcase(allscan_info.object) eq 'NEPTUNE', ntot)
         wneptune = where(strupcase(allscan_info[wselect].object) eq 'NEPTUNE', nneptune)
         
         calibration_info.neptune_ntot   = ntot
         calibration_info.neptune_nsel   = nneptune
         wu = wselect[wneptune]
         
         if nneptune gt 0 then begin   
            for ui=0, nneptune-1 do begin
               i = wu[ui]
               nk_scan2run, scan_list_run[i], run
               th_flux_1mm_run[i]     = !nika.flux_neptune[0]
               th_flux_a2_run[i]      = !nika.flux_neptune[1]
               th_flux_a1_run[i]      = !nika.flux_neptune[0]
               th_flux_a3_run[i]      = !nika.flux_neptune[0]
            endfor
         endif else begin
            calibration_info.problem = 1
            w = where(strupcase(allscan_info.object) eq 'URANUS', ntot)
            if ntot gt 0 then print, 'Uranus scans at [UT]: ', allscan_info[w].ut, ', FWHM_1mm = ', allscan_info[w].result_fwhm_1mm,', FWHM_2mm = ', allscan_info[w].result_fwhm_2, ', atm transmission = ', exp(-1.0d0*(allscan_info[w].result_tau_3)/sin(allscan_info[w].result_elevation_deg*!dtor))
            w = where(strupcase(allscan_info.object) eq 'NEPTUNE', ntot)
            if ntot gt 0 then print, 'Neptune scans at [UT]: ', allscan_info[w].ut, ', FWHM_1mm = ', allscan_info[w].result_fwhm_1mm,', FWHM_2mm = ', allscan_info[w].result_fwhm_2, ', atm transmission = ', exp(-1.0d0*(allscan_info[w].result_tau_3)/sin(allscan_info[w].result_elevation_deg*!dtor))
            print, ''
            print, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            print, strtrim((calibration_info.nika2run)[0],2)+'(cryo run'+strtrim(calibration_info.cryorun,2)+') will not have a proper absolute calibration'
            print, 'Stop to investigate'
            print, 'type .c to continue'
            
            stop
            
         endelse
      endelse
   endif

   if calibration_info.problem lt 1 then begin
      flux_ratio_1   = avg( th_flux_a1_run[wu]/allscan_info[wu].result_flux_i1)
      flux_ratio_2   = avg( th_flux_a2_run[wu]/allscan_info[wu].result_flux_i2)
      flux_ratio_3   = avg( th_flux_a3_run[wu]/allscan_info[wu].result_flux_i3)
      flux_ratio_1mm = avg( th_flux_1mm_run[wu]/allscan_info[wu].result_flux_i_1mm)
      
      correction_coef = [flux_ratio_1, flux_ratio_2, flux_ratio_3, flux_ratio_1mm]
      print,'======================================================'
      print,"Flux correction coefficient A1: "+strtrim(correction_coef[0],2)
      print,"Flux correction coefficient A3: "+strtrim(correction_coef[2],2)
      print,"Flux correction coefficient A1&A3: "+strtrim(correction_coef[3],2)
      print,"Flux correction coefficient A2: "+strtrim(correction_coef[1],2)
      print,'======================================================'
      
      calibration_info.abs_calib_factors = correction_coef
   endif else print, "NO ABSOLUTE CALIBRATION"
  
end
