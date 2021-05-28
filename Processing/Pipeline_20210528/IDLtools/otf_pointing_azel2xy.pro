pro otf_pointing_azel2xy, ofs_az, ofs_el, flag, projection, x, y, angle, signe, scan_type=scan_type

;+
;  INPUTS
;       ofs_az : data.ofs_az
;       ofs_el : data.ofs_el
;        flag  : data.flag[w1[0]]
;  projection  : "SYSTEMOF" read in the IMBFits
;
; OUTPUTS
;       x : fastest coordinate ("dents de scie")
;       y : slowest coordinate ("steps")
;   angle : rotation angle to "straighten" the pointing (that may be
;           provided to PAKO by the observer)        
;-



  ;;stop

  ;;  looking for the fastest coordinate
  ;;___________________________________________________________________________________________
  w_ok = where(flag lt 1, nok)
  vx = deriv(ofs_az)*!nika.f_sampling ;scan speed (arcsec/sec)
  vy = deriv(ofs_el)*!nika.f_sampling  
  vx_mean=mean(abs(vx[w_ok]))
  vy_mean=mean(abs(vy[w_ok]))

  signe=1.
  
  ;; defining an OTF scan "type" as in "nika_pipe_findtypescan"
type_scan = ''
  if strupcase(projection) eq "HORIZONTALTRUE" then begin
     ;; azel scan
     ;;------------------------------------------------------------------------
     if (vy_mean/vx_mean ge 5.0) then begin
        type_scan = 'otf_elevation' ;Considered azimuth for v_az > 5 v_el
        angle = !dpi/2.
     endif else if (vx_mean/vy_mean ge 5.0) then begin
        type_scan = 'otf_azimuth' ;Considered azimuth for v_az < 5 v_el
        angle = 0.
     endif else print,"this OTF scan is weird...."
  endif

  if strupcase(projection) eq "PROJECTION" then begin
     ;; ra-dec scan
     ;;------------------------------------------------------------------------
     type_scan = 'otf_diagonal'      ; e.g. OTF scan in ra-dec with possibly a rotation angle
     if (vx_mean gt vy_mean) then begin
        ;; rot angle initiated to 0. Could be in [0, pi/4[
        a_min = 0.
        a_max = !dpi/4.
 
     endif else begin
        ;; rot angle initiated to !dpi/4 Could be in [pi/4, !dpi/2]
        a_min =  !dpi/4.
        a_max =  !dpi/2.
     endelse

     angle=5.*!dtor
     y = signe*sin(angle)*ofs_az + cos(angle)*ofs_el
     vy_ = deriv(y)*!nika.f_sampling  
     vy_mean_=mean(abs(vy_[w_ok]))
     signe = (vy_mean - vy_mean_)/abs(vy_mean - vy_mean_)*signe


  endif
     

  ;;
  ;;  In case of OTF scan in ra-dec, fitting a rotation angle
  ;;___________________________________________________________________________________________
  if type_scan eq 'otf_diagonal' then begin  
     min = a_min
     max = a_max
     angle = otf_pointing_fit_angle(ofs_az, ofs_el, flag, signe=signe, min=min, max=max, check=1, showme=showme)    
  endif else angle = 0.


  ;;
  ;;  Rotating 
  ;;___________________________________________________________________________________________
  ;; clockwise rotation
  x = cos(angle)*ofs_az - signe*sin(angle)*ofs_el
  y = signe*sin(angle)*ofs_az + cos(angle)*ofs_el


  if keyword_set(scan_type) then scan_type=type_scan



end
