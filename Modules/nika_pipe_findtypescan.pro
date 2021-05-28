;+
;PURPOSE: Find out which scan is used 
;
;INPUT: The param and data structure.
;
;OUTPUT: The type of scan: lissajous, otf_azimuth, otf_elevation,
;        otf_diagonal, cross, focus
;
;LAST EDITION: - 07/01/2014 creation (adam@lpsc.in2p3.fr)
;-

function nika_pipe_findtypescan, param, data, silent=silent
  ;;------- Compute useful things
  N_pt = n_elements(data)
  nsubscan = max(data.subscan)
  type_scan = 'unknown'         ;for now, but might not change if the scan is weird
  
  x = data.ofs_az               ;scan position
  y = data.ofs_el               ;
  
  vx = deriv(x)*!nika.f_sampling                       ;scan speed (arcsec/sec)
  vy = deriv(y)*!nika.f_sampling                       ;
  vx_mean = mean(abs(vx[N_pt/2-N_pt/3:N_pt/2+N_pt/3])) ;Representative part of the scan
  vy_mean = mean(abs(vy[N_pt/2-N_pt/3:N_pt/2+N_pt/3]))
  if not keyword_set(silent) then $
     message,/info,'Mean velocity along -- Azimuth: '+strtrim(vx_mean,2)+$
             '  -- Elevation: '+strtrim(vy_mean,2)+'  [arcsec/sec]'  
  
  ;;------- Look if IMB_FITS are present
  if param.imb_fits_file ne '' then antenna = mrdfits(param.imb_fits_file, 0, head, status=status,/silent) else status=-1

  ;;------- If no IMB_FITS on se demerde
  if status eq -1 then begin
     message, /info, 'I tried to get the scan type from IMB_FITS files but they are not provided. I will therefore guess the scan type myself' 
     
     if (vy_mean/vx_mean ge 5.0) then type_scan = 'otf_elevation'
     if (vx_mean/vy_mean ge 5.0) then type_scan = 'otf_azimuth' 
     if (vx_mean/vy_mean le 5 and vy_mean/vx_mean le 5 and nsubscan eq 1) then type_scan = 'lissajous'
     if (vx_mean/vy_mean lt 5.0 and vy_mean/vx_mean lt 5.0 and nsubscan gt 1) then type_scan = 'otf_diagonal' 
  endif
  
  ;;------- Si il y a les IMB_FITS on s'en sert
  if status ne -1 then begin
     IMBFITS_scan = sxpar(head,'OBSTYPE')
     ;;------- Dans le cas OTF on devine si azimuth ou elevation
     if IMBFITS_scan eq 'onTheFlyMap' then begin
        if (vy_mean/vx_mean ge 5.0) then type_scan = 'otf_elevation' ;Considered azimuth for v_az > 5 v_el
        if (vx_mean/vy_mean ge 5.0) then type_scan = 'otf_azimuth'   ;Considered azimuth for v_az < 5 v_el
        if (vx_mean/vy_mean lt 5.0 and vy_mean/vx_mean lt 5.0) then type_scan = 'otf_diagonal'
     endif
     ;;------- Sinon on prend l'IMB_FITS
     if IMBFITS_scan ne 'onTheFlyMap' then type_scan = strlowcase(IMBFITS_scan) 
  endif

  if not keyword_set( silent) then message, /info, 'Scan type found is '+type_scan

  return, type_scan
end
