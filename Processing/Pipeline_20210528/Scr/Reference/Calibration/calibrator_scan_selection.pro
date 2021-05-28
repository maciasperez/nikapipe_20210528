pro calibrator_scan_selection, info_all, index, selected_scan_list = selected_scan_list, $
                               to_use_photocorr=to_use_photocorr, complement_index=complement_index, $
                               beamok_index = beamok_index, largebeam_index = largebeam_index,$
                               tauok_index = tauok_index, hightau_index=hightau_index, $
                               osbdateok_index=obsdateok_index, afternoon_index=afternoon_index, $
                               nefd_index=nefd_index, $
                               weak_fwhm_max=weak_fwhm_max, $
                               strong_fwhm_max = strong_fwhm_max
                                  

  

  if keyword_set(to_use_photocorr) then begin
     ;; AGGRESSIVE 1/3 bis (sept 2018)
     ;; FWHM selection cut 
     ;;planet_fwhm_max  = [13.0, 18.3, 13.0]
     planet_fwhm_max  = [12.5, 18.0, 12.5]
     fwhm_max         = [20.0, 20.0, 20.0] 
     fwhm_min = [10.0, 16.0, 10.0]
     ;; observation date cut
     daytime_range = ''
     ;;daytime_range_planet = ['16:00', '19:00']
     daytime_range_planet = ''
     ;; opacity cut
     tau3max    = 0.5 ;; 0.7
     obstau3max = 0.7 ;; 1.1
     elevation_min = 20.0d0
     elevation_max = 90.0d0
  
  endif else begin
        
;;   FWHM selection cut
     
     night_planet_fwhm_max  = [11.9, 17.9, 11.9] ;; mild thresholds during the night
     night_planet_fwhm_max  = [12.0, 17.9, 12.0] ;; LP changed on November 2020
     day_planet_fwhm_max    = [11.6, 17.6, 11.6] ;; more restrictive during the afternoon
     day_planet_fwhm_max    = [11.7, 17.7, 11.7] ;; LP changed on November 2020
     
     ;;fwhm_max         = [20.0, 20.0, 20.0] ;; in general, FWHMs cannot be measured
     night_fwhm_max   = [12., 17.8, 12.] ;; mild thresholds during the night
     day_fwhm_max     = [11.7, 17.7, 11.7] ;; more restrictive during the afternoon

     if keyword_set(weak_fwhm_max) then night_fwhm_max = weak_fwhm_max
     if keyword_set(strong_fwhm_max) then day_fwhm_max = strong_fwhm_max

     
     fwhm_min         = [10.0, 16.0, 10.0]
     
;;   observation date cut
     ;;daytime_range  = ['09:00', '22:00']  ;; to be discarded
;;     daytime_range  = [['9:00', '10:00'], ['15:00',  '22:00']] ;;  to be discarded
     ;;daytime_range  = [['9:00', '10:00'], ['15:00',  '21:30']] ;;  to be discarded
     daytime_range  = [['9:00', '10:00'], ['15:00',  '22:00']] ;;  to be discarded
     ;;daytime_range  = ''

     ;;daytime_range_planet = '' ;; selected from beam
     daytime_range_planet = [['9:00', '10:00'], ['15:00',  '22:00']] ;;  to be discarded
     
;;   opacity cut
     ;;tau3max    = 0.5 
     ;;obstau3max = 0.7 
     atm_transmission = 0.35 ;;0.4  ;;  tau/sinel ~ 1
     ;; May 2021: LP changed from 0.35 to 0.4
     atm_transmission = 0.4 
     
     elevation_min     = 20d0
     elevation_max     = 90d0
     ;elevation_min      = 25d0
     ;elevation_max      = 75d0
     
  endelse

;;______________________________________________________________________________________________
     
  nperiod0 = n_elements(daytime_range[0,*])
  
  daytime_min = 0.0
  daytime_max = 0.0
  if daytime_range[0] ne ''  then begin
     daytime_min = fltarr(nperiod0)
     daytime_max = fltarr(nperiod0)
     daytime_min[0] = float((STRSPLIT(daytime_range[0], ':', /EXTRACT))[0])+float((STRSPLIT(daytime_range[0], ':', /EXTRACT))[1])/60.
     daytime_max[0] = float((STRSPLIT(daytime_range[1], ':', /EXTRACT))[0])+float((STRSPLIT(daytime_range[1], ':', /EXTRACT))[1])/60.
     if nperiod0 gt 1 then begin
        for i=1, nperiod0-1 do begin
           daytime_min[i] = float((STRSPLIT(daytime_range[0, i], ':', /EXTRACT))[0])+float((STRSPLIT(daytime_range[0, i], ':', /EXTRACT))[1])/60.
           daytime_max[i] = float((STRSPLIT(daytime_range[1, i], ':', /EXTRACT))[0])+float((STRSPLIT(daytime_range[1, i], ':', /EXTRACT))[1])/60.
        endfor
     endif
  endif

  nperiod_planet = n_elements(daytime_range_planet[0,*])
  
  daytime_min_planet = 0.0
  daytime_max_planet = 0.0
  if daytime_range_planet[0] ne ''  then begin
     daytime_min_planet = fltarr(nperiod_planet)
     daytime_max_planet = fltarr(nperiod_planet)
     daytime_min_planet[0] = float((STRSPLIT(daytime_range_planet[0], ':', /EXTRACT))[0])+float((STRSPLIT(daytime_range_planet[0], ':', /EXTRACT))[1])/60.
     daytime_max_planet[0] = float((STRSPLIT(daytime_range_planet[1], ':', /EXTRACT))[0])+float((STRSPLIT(daytime_range_planet[1], ':', /EXTRACT))[1])/60.
     if nperiod_planet gt 1 then begin
        for i=1, nperiod_planet-1 do begin
           daytime_min_planet[i] = float((STRSPLIT(daytime_range_planet[0, i], ':', /EXTRACT))[0])+float((STRSPLIT(daytime_range_planet[0, i], ':', /EXTRACT))[1])/60.
           daytime_max_planet[i] = float((STRSPLIT(daytime_range_planet[1, i], ':', /EXTRACT))[0])+float((STRSPLIT(daytime_range_planet[1, i], ':', /EXTRACT))[1])/60.
        endfor
     endif
  endif

  nperiod = max([nperiod0, nperiod_planet])
  
  
  nscans = n_elements(info_all)
  
  un = replicate(1.0, nscans)
  tab_fwhm_max_0 = un##night_fwhm_max 
  tab_fwhm_min   = un##fwhm_min
  tab_fwhm_max_1 = un##day_fwhm_max 
    
  wplanets = where(strupcase(info_all.object) eq 'URANUS' or $
                   strupcase(info_all.object) eq 'MARS' or $
                   strupcase(info_all.object) eq 'NEPTUNE' or $
                   strupcase(info_all.object) eq 'SATURN', nplanets, compl=wothers, ncompl=nothers)
  
  if nplanets gt 0 then begin
     tab_fwhm_max_0(*, wplanets) = replicate(1.0, nplanets)##night_planet_fwhm_max
     tab_fwhm_max_1(*, wplanets) = replicate(1.0, nplanets)##day_planet_fwhm_max
  endif
  
  tab_daytime_max = fltarr(nperiod, nscans)
  tab_daytime_min = fltarr(nperiod, nscans)
  for i0 = 0, nperiod0-1 do begin
     tab_daytime_max(i0, *) = un##daytime_max[i0]
     tab_daytime_min(i0, *) = un##daytime_min[i0]
  endfor
  if nplanets gt 0 then begin
     for ip = 0, nperiod_planet-1 do begin
        tab_daytime_max(ip, wplanets) = replicate(1.0, nplanets)##daytime_max_planet[ip]
        tab_daytime_min(ip, wplanets) = replicate(1.0, nplanets)##daytime_min_planet[ip]
     endfor
  endif
  ;; 2 periodes max
  if nperiod0 lt nperiod_planet then begin
     tab_daytime_max(1, wothers) = replicate(1.0, nothers)##daytime_max[0]
     tab_daytime_min(1, wothers) = replicate(1.0, nothers)##daytime_min[0]
  endif
  if nperiod_planet lt nperiod0 then begin
     tab_daytime_max(1, wplanets) = replicate(1.0, nplanets)##daytime_max_planet[0]
     tab_daytime_min(1, wplanets) = replicate(1.0, nplanets)##daytime_min_planet[0]
  endif
  ;;stop
  
  ut_float    = fltarr(nscans)
  ut          = strmid(info_all.ut, 0, 5)
  for i = 0, nscans-1 do ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.

  ;; May 2021 : changed from selection on tau_3 to selection on tau_1mm
  ;; night
  wtokeep_0 = where( info_all.result_fwhm_1 le tab_fwhm_max_0(0, *) and $
                     info_all.result_fwhm_2 le tab_fwhm_max_0(1, *) and $
                     info_all.result_fwhm_3 le tab_fwhm_max_0(2, *) and $
                     info_all.result_fwhm_1 gt tab_fwhm_min(0, *) and $
                     info_all.result_fwhm_2 gt tab_fwhm_min(1, *) and $
                     info_all.result_fwhm_3 gt tab_fwhm_min(2, *) and $
                     (ut_float[*] lt tab_daytime_min[0, *] or $
                      ut_float[*] gt tab_daytime_max[0, *]) and $
                     exp(-1.0d0*info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission and $
                     info_all.result_elevation_deg gt elevation_min and $
                     info_all.result_elevation_deg lt elevation_max, $
                     compl=wout_0, nscans_0, ncompl=nout_0)

  ;; day
  nscans_1 = 0
  if nout_0 gt 0 then wtokeep_1 = where( info_all[wout_0].result_fwhm_1 le tab_fwhm_max_1(0, wout_0) and $
                                         info_all[wout_0].result_fwhm_2 le tab_fwhm_max_1(1, wout_0) and $
                                         info_all[wout_0].result_fwhm_3 le tab_fwhm_max_1(2, wout_0) and $
                                         info_all[wout_0].result_fwhm_1 gt tab_fwhm_min(0, wout_0) and $
                                         info_all[wout_0].result_fwhm_2 gt tab_fwhm_min(1, wout_0) and $
                                         info_all[wout_0].result_fwhm_3 gt tab_fwhm_min(2, wout_0) and $
                                         exp(-1.0d0*info_all[wout_0].result_tau_1mm/sin(info_all[wout_0].result_elevation_deg*!dtor)) ge atm_transmission and $
                                         info_all[wout_0].result_elevation_deg gt elevation_min and $
                                         info_all[wout_0].result_elevation_deg lt elevation_max, $
                                         compl=wout_1, nscans_1, ncompl=nout_1)

  
  if nperiod eq 2 then begin
     ;; night
     wtokeep_0 = where( info_all.result_fwhm_1 le tab_fwhm_max_0(0, *) and $
                        info_all.result_fwhm_2 le tab_fwhm_max_0(1, *) and $
                        info_all.result_fwhm_3 le tab_fwhm_max_0(2, *) and $
                        info_all.result_fwhm_1 gt tab_fwhm_min(0, *) and $
                        info_all.result_fwhm_2 gt tab_fwhm_min(1, *) and $
                        info_all.result_fwhm_3 gt tab_fwhm_min(2, *) and $
                        (ut_float[*] lt tab_daytime_min[0, *] or $
                         ut_float[*] gt tab_daytime_max[1, *] or $
                         (ut_float[*] lt tab_daytime_min[1, *] and ut_float[*] gt tab_daytime_max[0, *])) and $
                        exp(-1.0d0*info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission and $
                        info_all.result_elevation_deg gt elevation_min and $
                        info_all.result_elevation_deg lt elevation_max, $
                        compl=wout_0, nscans_0, ncompl=nout_0)
     ;; day
     nscans_1 = 0
     if nout_0 gt 0 then wtokeep_1 = where( info_all[wout_0].result_fwhm_1 le tab_fwhm_max_1(0, wout_0) and $
                                            info_all[wout_0].result_fwhm_2 le tab_fwhm_max_1(1, wout_0) and $
                                            info_all[wout_0].result_fwhm_3 le tab_fwhm_max_1(2, wout_0) and $
                                            info_all[wout_0].result_fwhm_1 gt tab_fwhm_min(0, wout_0) and $
                                            info_all[wout_0].result_fwhm_2 gt tab_fwhm_min(1, wout_0) and $
                                            info_all[wout_0].result_fwhm_3 gt tab_fwhm_min(2, wout_0) and $
                                            exp(-1.0d0*info_all[wout_0].result_tau_1mm/sin(info_all[wout_0].result_elevation_deg*!dtor)) ge atm_transmission and $
                                            info_all[wout_0].result_elevation_deg gt elevation_min and $
                                            info_all[wout_0].result_elevation_deg lt elevation_max, $
                                            compl=wout_1, nscans_1, ncompl=nout_1)
     
  endif

  if nscans_0 gt 0 then begin
     wtokeep = wtokeep_0
     if nscans_1 gt 0 then wtokeep = [wtokeep, wout_0[wtokeep_1]]
  endif else begin
     if nscans_1 gt 0 then wtokeep = [wout_0[wtokeep_1]] else wtokeep = -1
  endelse
  if nscans_1 gt 0 then wout = wout_0[wout_1] else wout=wout_0

  ;;stop
  nefd_index = where( $
               (ut_float[*] lt tab_daytime_min[0, *] or $
                ut_float[*] gt tab_daytime_max[0, *]) and $
               exp(-1.0d0*info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission and $
               info_all.result_elevation_deg gt elevation_min and $
               info_all.result_elevation_deg lt elevation_max , $
               nefd_nscans)
  
  if nperiod eq 2 then begin
     nefd_index = where( $
                  (ut_float[*] lt tab_daytime_min[0, *] or $
                   ut_float[*] gt tab_daytime_max[1, *] or $
                   (ut_float[*] lt tab_daytime_min[1, *] and ut_float[*] gt tab_daytime_max[0, *])) and $
                  exp(-1.0d0*info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission and $
                  info_all.result_elevation_deg gt elevation_min and $
                  info_all.result_elevation_deg lt elevation_max, $
                  nefd_nscans)
  endif
  
  
  beamok_index = where((info_all.result_fwhm_1 le tab_fwhm_max_0(0, *) and $
                        info_all.result_fwhm_2 le tab_fwhm_max_0(1, *) and $
                        info_all.result_fwhm_3 le tab_fwhm_max_0(2, *) and $
                        info_all.result_fwhm_1 gt tab_fwhm_min(0, *) and $
                        info_all.result_fwhm_2 gt tab_fwhm_min(1, *) and $
                        info_all.result_fwhm_3 gt tab_fwhm_min(2, *) and $
                        (ut_float[*] lt tab_daytime_min[0, *] or $
                         ut_float[*] gt tab_daytime_max[0, *])) or $
                       (info_all.result_fwhm_1 le tab_fwhm_max_1(0, *) and $
                        info_all.result_fwhm_2 le tab_fwhm_max_1(1, *) and $
                        info_all.result_fwhm_3 le tab_fwhm_max_1(2, *) and $
                        info_all.result_fwhm_1 gt tab_fwhm_min(0, *) and $
                        info_all.result_fwhm_2 gt tab_fwhm_min(1, *) and $
                        info_all.result_fwhm_3 gt tab_fwhm_min(2, *)), $
                       compl=largebeam_index, nscans_beamok, ncompl=nlargebeam)
  
  if nperiod eq 2 then begin
     beamok_index = where((info_all.result_fwhm_1 le tab_fwhm_max_0(0, *) and $
                           info_all.result_fwhm_2 le tab_fwhm_max_0(1, *) and $
                           info_all.result_fwhm_3 le tab_fwhm_max_0(2, *) and $
                           info_all.result_fwhm_1 gt tab_fwhm_min(0, *) and $
                           info_all.result_fwhm_2 gt tab_fwhm_min(1, *) and $
                           info_all.result_fwhm_3 gt tab_fwhm_min(2, *) and $
                           (ut_float[*] lt tab_daytime_min[0, *] or $
                            ut_float[*] gt tab_daytime_max[1, *] or $
                            (ut_float[*] lt tab_daytime_min[1, *] and ut_float[*] gt tab_daytime_max[0, *]))) or $
                          (info_all.result_fwhm_1 le tab_fwhm_max_1(0, *) and $
                           info_all.result_fwhm_2 le tab_fwhm_max_1(1, *) and $
                           info_all.result_fwhm_3 le tab_fwhm_max_1(2, *) and $
                           info_all.result_fwhm_1 gt tab_fwhm_min(0, *) and $
                           info_all.result_fwhm_2 gt tab_fwhm_min(1, *) and $
                           info_all.result_fwhm_3 gt tab_fwhm_min(2, *)), $
                          compl=largebeam_index, nscans_beamok, ncompl=nlargebeam)
     
  endif
  
  obsdateok_index = where( ut_float[*] lt tab_daytime_min[0, *] or $
                           ut_float[*] gt tab_daytime_max[0, *] , $
                           compl=afternoon_index, nscans_night, ncompl=ndaytime)
  if nperiod eq 2 then begin
     obsdateok_index = where( ut_float[*] lt tab_daytime_min[0, *] or $
                              ut_float[*] gt tab_daytime_max[1, *] or $
                              (ut_float[*] lt tab_daytime_min[1, *] and ut_float[*] gt tab_daytime_max[0,*]),$
                              compl=afternoon_index, nscans_night, ncompl=ndaytime)
  endif
  
  
  tauok_index = where(exp(-1.0d0*info_all.result_tau_1mm/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission, $
                      compl=hightau_index, nscans_hitau3, ncompl=nhitau3)
  

  
  index = wtokeep
  complement_index = wout

   
end
