;+
;PURPOSE: Remove a common mode per block of best correlated detectors and
;Delev/DAz systematics
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 4/3/2014: creation (FXD) from cmblock
;-

pro nika_pipe_lissopt, param, data, kidpar, pazel = pazel

  baseline = data.rf_didq*0.d0
  warning1mm = 'no'
  warning2mm = 'no'
  nsn = n_elements( data)

  ;;------- Sanity check
  if strupcase(param.decor.common_mode.per_subscan) ne 'YES' $
     and strupcase(param.decor.common_mode.per_subscan) ne 'NO' then begin

     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"

  endif else begin

     N_pt  = n_elements( data)
     n_kid = n_elements( kidpar)
     
     w1    = where( kidpar.type eq 1, nw1)   ; Number of detector ON
     w_off = where( kidpar.type eq 2, n_off) ; Number of detector OFF
     
     ;;------- Source position from the center (arcsec)
     pos = [-ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 + $
            ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0, $
            ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) - $
            ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])]*3600.0
     
     ;;------- Determine if kids are "on" or "off source"
     w8source = data.rf_didq*0.d0 + 1.d0 ; Set to 0 if "on source"
     for i=0, nw1-1 do begin
        ikid = w1[i]
        nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                              kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                              0., 0., dra, ddec, $
                              nas_x_ref=kidpar[ikid].nas_center_X, nas_y_ref=kidpar[ikid].nas_center_Y
        dist_source = sqrt((ddec - pos[1])^2 + (dra - pos[0])^2) ; Distance from the source
        loc_on = where(dist_source le param.decor.common_mode.d_min, nloc_on)
        if nloc_on ne 0 then w8source[ikid, loc_on] = 0
     endfor

;     if param.decor.common_mode.x_calib eq 'yes' then message,/info,"Atmospheric calibration far from the source"

     if param.decor.common_mode.per_subscan eq 'no' then begin
        ;;------- Build the atmosphere template on the entire scan
        nsmooth = (long(!nika.f_sampling*30) < nsn/2) /2*2+1 ;30 seconds high-pass filter
        ;;print, 'Using nsmooth= ', nsmooth
        index = dindgen( nsn)
        template1 = sin( pazel[0] * index)
        template2 = cos( pazel[0] * index)
        template3 = sin( pazel[1] * index)
        template4 = cos( pazel[1] * index)
        template5 = sin( 2*pazel[0] * index)
        template6 = cos( 2*pazel[0] * index)
        template7 = sin( 2*pazel[1] * index)
        template8 = cos( 2*pazel[1] * index)

        ;; template1 = data.ofs_az
        ;; template2 = data.ofs_el
        ;; AM = 1.d0/ sin( data.el>0.001)  ; AM should give a more linear signal
        ;; template3 = AM - smooth( AM, nsmooth, /edge_trunc) 
; elevation in radians
        ;; template4 = orthofft( template1) ; orthogonal pattern to Daz
        ;; template5 = orthofft( template2) ; orthogonal pattern to Del
; Elevation signal at twice the frequency
        ;; template6 = harmofft( template2, 2, orthoharm = template7)
; Az signal at twice the frequency
        ;; template8 = harmofft( template2, 2, orthoharm = template9)
        lintemp = (index- nsn/2d0)/nsn  ; linear pattern for the gain
        sqrtemp = (lintemp/nsn)^2  ; no smoothing

; sin-cos to remove low frequency noise
        ;; phase = 2*!dpi*dindgen( nsn)/nsn
        ;; template6 = sin( phase)
        ;; template7 = cos( phase)
        ;; template8 = sin( 2*phase)
        ;; template9 = cos( 2*phase)
        ;; template10 = sin( 3*phase)
        ;; template11= cos( 3*phase)
        ;; template12 = sin( 4*phase)
        ;; template13 = cos( 4*phase)

 
        for lambda=1, 2 do begin
; Introduce small changes to avoid pointing error problems
  
           arr = where(kidpar.array eq lambda, narr)
           if narr ne 0 then begin
              rf_didq_a  = data.rf_didq[arr]
              rfa = rf_didq_a
              kidpar_a   = kidpar[arr]
              w8source_a = w8source[arr,*]
              nika_pipe_subtract_common_bloc, param, rf_didq_a, $
                     kidpar_a, w8source_a, temp_atmo, base, war=war
              if war eq 'yes' and lambda eq 1 then warning1mm = 'yes'
              if war eq 'yes' and lambda eq 2 then warning2mm = 'yes'
;              data.rf_didq[arr] = rf_didq_a
                                ; We got our template from the best correlated kids,
                                ; now we decorrelate simultaneously from dAz
                                ; and dEl
;save, file = '$SAVE/temp.save', data, kidpar, base
;stop
              imess = 0
              for ikid=0, narr-1 do begin
                 if kidpar_a[ikid].type eq 1 then begin
                    offsource = where( w8source_a[ikid, *] eq 1 and $
                                       data.ofs_el ne 0, noffsource)
                   if noffsource ne 0 then begin
                      tb = reform( base[ ikid, *])
                      tb1 = reform( base[ ikid, *]) * lintemp
                      stdb = stddev( tb)
; This is done to take into account some non-linearity.
                      if stdb ne 0 then tb2 = (tb/stdb)^2 else $
                         tb2 = sqrtemp
; change from this template        tb2 = reform( base[ ikid, *]) * sqrtemp
                      tb = tb-smooth( tb, nsmooth, /edge_trun)
                      tb1 = tb1-smooth( tb1, nsmooth, /edge_trun)
                      tb2 = tb2-smooth( tb2, nsmooth, /edge_trun)
                      yy = reform( rfa[ ikid, *])
                      zz = yy  ; will interpolate where the source is
                      onsource = where( w8source_a[ ikid, *] ne 0, nonsource)
                      if nonsource ne 0 then $
                         zz[ onsource] = interpol( yy[ offsource], $
                                                   offsource, onsource)
                      yy = yy-smooth( zz,  nsmooth, /edge_trun)
                      status = 2
                      coeff = regress( transpose([ $
                              [template1[ offsource]], $
                              [template2[ offsource]], $
                              [template3[ offsource]], $
                              [template4[ offsource]], $
                              [template5[ offsource]], $
                              [template6[ offsource]], $
                              [template7[ offsource]], $
                              [template8[ offsource]], $
                              [tb[ offsource]], $
                              [tb1[ offsource]],  $
                              [tb2[ offsource]] $
                                                 ]), $
                                       yy[offsource], const = co, $
                                     status = status)
                      
                      basenew = coeff[0]*template1 + $
                                coeff[1]*template2 + $
                                coeff[2]*template3 + $
                                coeff[3]*template4 + $
                                coeff[4]*template5 + $
                                coeff[5]*template6 + $
                                coeff[6]*template7 + $
                                coeff[7]*template8 + $
                                coeff[8]*tb + $
                                coeff[9]*tb1 + $
                                coeff[10]*tb2 + co
                      rfcnew =  reform( yy) - basenew
                      rfcold =  reform( data.rf_didq[ arr[ikid]]) - $
                                base[ ikid, *]
                    ; 1st case should happen at all time...
                      stdnew = stddev( rfcnew[ offsource])
                      stdold = stddev( rfcold[ offsource])
                      if stdnew le stdold and $
                      status eq 0 then $
                            data.rf_didq[ arr[ikid]] = rfcnew else begin
                               data.rf_didq[ arr[ikid]] = rfcold
                               if stdnew gt 1.3*stdold then begin
                                  if imess eq 0 then message, /info, $
         'New decorr not working for '+ string( kidpar[ arr[ ikid]].name)
                                  imess = imess+1
                               endif
                            endelse 
                   endif
                endif
              endfor
              baseline[arr,*] = base
              if imess ne 0 then message, /info, $
         'New decorr not working for a total of '+strtrim( imess, 2)+' det'
           endif
        endfor

     endif else begin

        ;;------- Build the atmosphere template subscan by subscan
        for lambda=1, 2 do begin
           arr = where( kidpar.array eq lambda, narr)
           if narr ne 0 then begin
              for isubscan=1, max(data.subscan) do begin
                 wsubscan   = where( data.subscan eq isubscan, nwsubscan)
                 if nwsubscan gt 0 then begin
                    rf_didq_a  = data[wsubscan].rf_didq[arr]
                    w8source_a = w8source[arr,*]
                    w8source_a = w8source_a[*,wsubscan] ; need to proceed in two steps to extract w8source_a
                    nika_pipe_subtract_common_bloc,param,rf_didq_a,kidpar[arr],w8source_a,temp_atmo,base,war=war
                    if war eq 'yes' and lambda eq 1 then warning1mm = 'yes'
                    if war eq 'yes' and lambda eq 2 then warning2mm = 'yes'
                    data[wsubscan].rf_didq[arr] = rf_didq_a
                    for ii=0, narr-1 do baseline[arr[ii],wsubscan] = base[ii,*]
                 endif
              endfor
           endif
        endfor

     endelse
  endelse


  ;;------- Warning because the common mode used has been interpolated
  if warning1mm eq 'yes' then begin
     message, /info, '-----------------------------------------------'
     message, /info, '-------------- IMPORTANT WARNING --------------'
     message, /info, '-----------------------------------------------'
     message, /info, 'The 1mm bloc common mode has been interpolated at some point. You should increase the minimum number of KIDs used for the common mode (param.decor.common_mode.nbloc_min) or reduce the considered flagged area around the source (param.decor.common_mode.d_min)'
     message, /info, '-----------------------------------------------'
  endif

  if warning2mm eq 'yes' then begin
     message, /info, '-----------------------------------------------'
     message, /info, '-------------- IMPORTANT WARNING --------------'
     message, /info, '-----------------------------------------------'
     message, /info, 'The 2mm bloc common mode has been interpolated at some point. You should increase the minimum number of KIDs used for the common mode (param.decor.common_mode.nbloc_min) or reduce the considered flagged area around the source (param.decor.common_mode.d_min)'
     message, /info, '-----------------------------------------------'
  endif
  
  return
end
