;+
;  GOAL: selection of the scans used for calibration
;
;  copy of calib_scan_selection, written in January 2019
;
;  --> select the best scans within the limit of very mild selection
;  criteria in case no scan met the usual selections
;
;  LP, April 2020
;-
pro lastchance_scan_selection, info_all, index, selected_scan_list = selected_scan_list, $
                              to_use_photocorr=to_use_photocorr, complement_index=complement_index, $
                              beamok_index = beamok_index, largebeam_index = largebeam_index,$
                              tauok_index = tauok_index, hightau_index=hightau_index, $
                              osbdateok_index=obsdateok_index, afternoon_index=afternoon_index, $
                              fwhm_max=fwhm_max, planet_fwhm_max = planet_fwhm_max, nefd_index=nefd_index
                             
  
  
  
  ;; first case : using a photometric correction
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
     
;; SECOND CASE: THE USUAL ONE
;;   ------------------------------------------------------------------------------
;;   FWHM selection cut
     
     ;; baseline:
     ;;planet_fwhm_max  = [12.5, 18.0, 12.5]
     ;; jan 2019: more restrictive criterion on Planet FWHM
     ;;planet_fwhm_max  = [11.9, 17.9, 11.9]
     if keyword_set(planet_fwhm_max) then planet_fwhm_max = planet_fwhm_max else $
        planet_fwhm_max  = [12.5, 18.0, 12.5]
     
     ;; baseline
     ;;fwhm_max         = [20.0, 20.0, 20.0] ;; in general, FWHMs cannot be measured
     ;;jan 2019: more restrictive criterion on secondary calibrator FWHM
     if keyword_set(fwhm_max) then fwhm_max = fwhm_max else $
        fwhm_max         = [12.2, 17.9, 12.2]
     
     fwhm_min         = [10.0, 16.0, 10.0]
     
;;   observation date cut
     ;; jan 2019: accept all the scans whenever the obs date 
     ;;daytime_range  = [['9:00', '10:00'], ['15:00',  '22:00']] ;;  to be discarded
     daytime_range  = ''

     daytime_range_planet = '' ;; selected from beam
     
     
;;   opacity cut
     ;;tau3max    = 0.5
     ;;obstau3max = 0.7
     ;;tau3max    = 0.7
     ;;obstau3max = 1.0
     ;;exp[-tau/sin(el)] = 0.5
     atm_transmission = 0.4
     
     elevation_min     = 20d0
     elevation_max     = 90d0
     ;;elevation_min      = 25d0
     ;;elevation_max      = 75d0
     
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
  tab_fwhm_max = un##fwhm_max 
  tab_fwhm_min = un##fwhm_min
  wplanets = where(strupcase(info_all.object) eq 'URANUS' or $
                   strupcase(info_all.object) eq 'MARS' or $
                   strupcase(info_all.object) eq 'NEPTUNE' or $
                   strupcase(info_all.object) eq 'SATURN', nplanets, compl=wothers, ncompl=nothers)
  if nplanets gt 0 then tab_fwhm_max(*, wplanets) = replicate(1.0, nplanets)##planet_fwhm_max
  
  
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


  ;; PERFORM THE SELECTION
  
  wtokeep = where( info_all.result_fwhm_1 le tab_fwhm_max(0, *) and $
                   info_all.result_fwhm_2 le tab_fwhm_max(1, *) and $
                   info_all.result_fwhm_3 le tab_fwhm_max(2, *) and $
                   info_all.result_fwhm_1 gt tab_fwhm_min(0, *) and $
                   info_all.result_fwhm_2 gt tab_fwhm_min(1, *) and $
                   info_all.result_fwhm_3 gt tab_fwhm_min(2, *) and $
                   (ut_float[*] lt tab_daytime_min[0, *] or $
                    ut_float[*] gt tab_daytime_max[0, *]) and $
                   exp(-1.0d0*info_all.result_tau_3/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission and $
                   info_all.result_elevation_deg gt elevation_min and $
                   info_all.result_elevation_deg lt elevation_max, $
                   compl=wout, nscans, ncompl=nout)

  ;; KEEP ONLY THE ONES WITH THE MIMINUM FWHM + up to 12.2
  if nscans gt 0 then begin
     min_fwhm_1mm = min(info_all[wtokeep].result_fwhm_1mm, imin)
     w=where(info_all[wtokeep].result_fwhm_1mm lt max([(min_fwhm_1mm+0.1), 12.2]), n, compl=wreout, ncompl=nreout)
     wtokeep = wtokeep[w]
     if nreout gt 0 then wout = [wout, wtokeep[wreout]]
  endif
  

  if nperiod eq 2 then begin
     wtokeep = where( info_all.result_fwhm_1 le tab_fwhm_max(0, *) and $
                      info_all.result_fwhm_2 le tab_fwhm_max(1, *) and $
                      info_all.result_fwhm_3 le tab_fwhm_max(2, *) and $
                      info_all.result_fwhm_1 gt tab_fwhm_min(0, *) and $
                      info_all.result_fwhm_2 gt tab_fwhm_min(1, *) and $
                      info_all.result_fwhm_3 gt tab_fwhm_min(2, *) and $
                      (ut_float[*] lt tab_daytime_min[0, *] or $
                       ut_float[*] gt tab_daytime_max[1, *] or $
                       (ut_float[*] lt tab_daytime_min[1, *] and ut_float[*] gt tab_daytime_max[0, *])) and $
                      exp(-1.0d0*info_all.result_tau_3/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission and $
                      info_all.result_elevation_deg gt elevation_min and $
                      info_all.result_elevation_deg lt elevation_max, $
                      compl=wout, nscans, ncompl=nout)

     if nscans gt 0 then begin
        min_fwhm_1mm = min(info_all[wtokeep].result_fwhm_1mm, imin)
        w=where(info_all[wtokeep].result_fwhm_1mm lt max([(min_fwhm_1mm+0.1), 12.2]), n, compl=wreout, ncompl=nreout)
        wtokeep = wtokeep[w]
        if nreout gt 0 then wout = [wout, wtokeep[wreout]]
     endif
  endif
   
  nefd_index = where( $
               (ut_float[*] lt tab_daytime_min[0, *] or $
                ut_float[*] gt tab_daytime_max[0, *]) and $
               exp(-1.0d0*info_all.result_tau_3/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission and $
               info_all.result_elevation_deg gt elevation_min and $
               info_all.result_elevation_deg lt elevation_max , $
               nefd_nscans)
  
  if nperiod eq 2 then begin
     nefd_index = where( $
                  (ut_float[*] lt tab_daytime_min[0, *] or $
                   ut_float[*] gt tab_daytime_max[1, *] or $
                   (ut_float[*] lt tab_daytime_min[1, *] and ut_float[*] gt tab_daytime_max[0, *])) and $
                  exp(-1.0d0*info_all.result_tau_3/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission and $
                  info_all.result_elevation_deg gt elevation_min and $
                  info_all.result_elevation_deg lt elevation_max, $
                  nefd_nscans)
  endif
  
  
  beamok_index = where(info_all.result_fwhm_1 le tab_fwhm_max(0, *) and $
                       info_all.result_fwhm_2 le tab_fwhm_max(1, *) and $
                       info_all.result_fwhm_3 le tab_fwhm_max(2, *) and $
                       info_all.result_fwhm_1 gt tab_fwhm_min(0, *) and $
                       info_all.result_fwhm_2 gt tab_fwhm_min(1, *) and $
                       info_all.result_fwhm_3 gt tab_fwhm_min(2, *), $
                       compl=largebeam_index, nscans_beamok, ncompl=nlargebeam)
  
  
  obsdateok_index = where( ut_float[*] lt tab_daytime_min[0, *] or $
                           ut_float[*] gt tab_daytime_max[0, *] , $
                           compl=afternoon_index, nscans_night, ncompl=ndaytime)
  if nperiod eq 2 then begin
     obsdateok_index = where( ut_float[*] lt tab_daytime_min[0, *] or $
                              ut_float[*] gt tab_daytime_max[1, *] or $
                              (ut_float[*] lt tab_daytime_min[1, *] and ut_float[*] gt tab_daytime_max[0,*]),$
                              compl=afternoon_index, nscans_night, ncompl=ndaytime)
  endif
  
  
  tauok_index = where(exp(-1.0d0*info_all.result_tau_3/sin(info_all.result_elevation_deg*!dtor)) ge atm_transmission,$
                      compl=hightau_index, nscans_hitau3, ncompl=nhitau3)
  


  index = wtokeep
  complement_index = wout

  


  
   
end
