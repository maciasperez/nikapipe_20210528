pro otf_pointing_updateinfo_el, index, x, y, flag, y_allinfo_estimate, first_working_index=first_working_index, end_of_scan=end_of_scan, chatty=chatty, debug=debug
  
;+
;
; AIM: update the elevation-type parameter structure (quoted
; y_allinfo_estimate) from the valid sample in the x and y pointing timelines   
;
; INPUTS
; index : x and y index timeline
; x, y  : az, el-type pointing timeline
; flag  : x, y mask 
; 
;  
; INPUT/OUTPUT
; y_allinfo_estimate :  elevation-type parameter structure for the
; whole scan --> the part corresponding to the given x, y is to be updated 
; {ss_length:0., is_length:0., beg_index:0L, end_index:0L, amplitude:0.}
;
;
; LP, 2014 May 14th
;
;-
  
  code = "IDLtools/otf_pointing_updateinfo_el >> "
  bava = 0
  if keyword_set(chatty) then bava=1
  bavaz = 0
  if keyword_set(debug) then bavaz=1
  


  nss_fit = n_elements(y_allinfo_estimate)
  
  y_ss_length = y_allinfo_estimate.ss_length
  y_is_length = y_allinfo_estimate.is_length
  y_amplitude = y_allinfo_estimate.amplitude
  y_beg_index = y_allinfo_estimate.beg_index
  y_end_index = y_allinfo_estimate.end_index
  y_beg_index_flag = y_allinfo_estimate.beg_index_flag  
  y_delta_amp = shift(y_allinfo_estimate.amplitude,-1)-y_allinfo_estimate.amplitude


  if nss_fit gt 1 then y_med_ssl = median(y_ss_length) else y_med_ssl = y_ss_length
  if nss_fit gt 1 then y_med_isl = median(y_is_length) else y_med_isl = y_is_length
  if nss_fit gt 1 then y_med_amp = median(y_amplitude) else y_med_amp = y_amplitude
  y_ampli0 = y_amplitude[0]
  if nss_fit gt 1 then y_med_step = median(y_delta_amp) else y_med_step = y_delta_amp 
  if nss_fit gt 1 then y_delta_amp[nss_fit-1] = y_med_step 

  wstop = where( y_allinfo_estimate.is_length lt 0, costop)
  if costop gt 0 then stop  
  
  ;; get info
  ;;_________________________________________________________________________________________________________________
  
  otf_pointing_getinfo, index, x, y, flag, x_info_bunch, y_info_bunch, x_allinfo_bunch, y_allinfo_bunch, y_all=1, chatty=chatty, debug=debug
  
 
  

  ;; estimating global bunch-related param
  ;;_________________________________________________________________________________________________________________ 
  ;; number of sample
  nsp_bunch = n_elements(index)
  
  ;; phase
  is_first_scan_to_shift = y_info_bunch.phase 
  ;; in short bunch case, phase can be misestimated
  if bavaz gt 0 then print,code,"phase = ",is_first_scan_to_shift
  phase_bis = 0
  if (y_allinfo_bunch[0].beg_index eq 0) then phase_bis = max([2,y_med_ssl - (y_allinfo_bunch[0].end_index+1)])
  if phase_bis gt 2 then is_first_scan_to_shift=phase_bis
  if bavaz gt 0 then print,code," est-ce qu'on commence au debut d'un subscan ? ", is_first_scan_to_shift
  
  
  ;; number of sample to the beginning of the bunch
  first_work_index = 0
  if keyword_set(first_working_index) then first_work_index = first_working_index 
  n_samples_since_beginning = index[0]-first_work_index+1
  if bavaz gt 0 then print,code," n_samples_since_beginning : ", n_samples_since_beginning
  
  
  ;;  testing availability of new info from the bunch
  ;;_______________________________________________________________________________________________________________
  if  (y_info_bunch.AVG_SSL_OK gt -1) then begin 
     
     
     ;; number of subscan in the bunch : 
     nss_bunch = n_elements(y_allinfo_bunch)
          
     
     i0 = 0
     ampli0 = y_info_bunch.amplitude

     ;; treating first subscan
     ;;_________________________________________________________________________________________________________________
     ;; if the bunch begins in the middle of a subscan -->
     ;; the first beginning is missing --> need to readjust
     ;; using the first ending index
     if (is_first_scan_to_shift gt 0) then begin
        
        i0=1
        tol=100
        i_first_begin_found = where((y_beg_index gt (n_samples_since_beginning+y_allinfo_bunch[1].beg_index-tol)) and (y_beg_index lt (n_samples_since_beginning+y_allinfo_bunch[1].beg_index+tol)),co)              
        if co gt 0 then i_begin_to_readjust = i_first_begin_found[0]-1 else i_begin_to_readjust = 0
        
        ;;readjust the  beg_index if not already measured
        if (y_beg_index_flag[i_begin_to_readjust] gt 0) then begin
           
           
           ;; plot,index,y,xr=[index[0],index[nsp_bunch-1]],/xs,/ys
           ;; oplot,index[y_allinfo_bunch.beg_index], y[y_allinfo_bunch.beg_index],col=150,psym=1
           ;; oplot,index[y_allinfo_bunch.end_index], y[y_allinfo_bunch.end_index],col=250,psym=1
           
           ;; get the shift from the first ending index found
           correction = (n_samples_since_beginning+y_allinfo_bunch[0].end_index-1-(y_beg_index[i_begin_to_readjust]+y_med_ssl))
          
           for j = i_begin_to_readjust, nss_fit-1 do y_beg_index[j] = y_beg_index[j]+correction  
           ;; correcting the previous IS interval accordingly
           if (y_is_length[i_begin_to_readjust-1] + correction) ge 0 then  y_is_length[i_begin_to_readjust-1] +=correction
           
            ;; accounting for the first SS amplitude
           n_first_ss = y_allinfo_bunch[0].end_index - y_allinfo_bunch[0].beg_index
           if (n_first_ss ge y_med_ssl*0.3) then y_amplitude[i_begin_to_readjust] = mean(y[y_allinfo_bunch[0].beg_index:y_allinfo_bunch[0].end_index])
          
        endif else begin
           ;; on the contrary, if the previous beginning was
           ;; measured, on can update the previous SS length and amplitude
           y_ss_length[i_begin_to_readjust] = (n_samples_since_beginning+y_allinfo_bunch[0].end_index-1) - y_beg_index[i_begin_to_readjust] + 1    
           ;; accounting for the first SS amplitude
           n_first_ss = y_allinfo_bunch[0].end_index - y_allinfo_bunch[0].beg_index
           if (n_first_ss ge y_ss_length[i_begin_to_readjust]*0.5) then y_amplitude[i_begin_to_readjust] = mean(y[y_allinfo_bunch[0].beg_index:y_allinfo_bunch[0].end_index])
           
        endelse
        
        ;; accounting for the first ending index
        i_match=where((y_end_index gt (n_samples_since_beginning+y_allinfo_bunch[0].end_index-tol)) and (y_end_index lt (n_samples_since_beginning+y_allinfo_bunch[0].end_index+tol)),co)
        if ((co gt 0) and (i_match eq i_begin_to_readjust)) then begin
           correction_end = (n_samples_since_beginning-1+y_allinfo_bunch[0].end_index-y_end_index[i_match]) 
           if bavaz gt 0 then print,code,"shift to ends = ", correction_end
           for j = i_begin_to_readjust, nss_fit-1 do y_end_index[j] = y_end_index[j]+correction_end
        endif 
        
        ;; accounting for the first IS interval
        y_isl = y_allinfo_bunch[0].is_length
        if ((y_isl gt 0.2*y_med_isl) and (y_isl lt 1.8*y_med_isl)) then  y_is_length[i_begin_to_readjust] = y_isl
        
       
        ampli0 = y_amplitude[i_begin_to_readjust]
        
     endif
     
     
     ;; treating the remaining of the bunch
     ;;_________________________________________________________________________________________________________________
     if nss_bunch gt 1 then begin
        ;; filling in the index of the subscan beginnings + readjusting
        tol=100
        for i=i0, nss_bunch-1 do begin     
           i_match=where((y_beg_index gt (n_samples_since_beginning+y_allinfo_bunch[i].beg_index-tol)) and (y_beg_index lt (n_samples_since_beginning+y_allinfo_bunch[i].beg_index+tol)),co)
           if bavaz gt 0 then print,code,"for subscan number ",i," matching ? ",co
           if co gt 0 then begin
              correction = (n_samples_since_beginning-1+y_allinfo_bunch[i].beg_index-y_beg_index[i_match]) 
              if bavaz gt 0 then print,code,"shift to beginnings = ",correction
              for j = i_match[0], nss_fit-1 do y_beg_index[j] = y_beg_index[j]+correction
              y_beg_index_flag[i_match]=0
              i_match_end=where((y_end_index gt (n_samples_since_beginning+y_allinfo_bunch[i].end_index-tol)) and (y_end_index lt (n_samples_since_beginning+y_allinfo_bunch[i].end_index+tol)),co)
              if bavaz gt 0 then print,code,"for subscan number ",i," matching end ? ",co
              if ((co gt 0) and (i_match_end eq i_match)) then begin
                 correction_end = (n_samples_since_beginning-1+y_allinfo_bunch[i].end_index-y_end_index[i_match_end]) 
                 if bavaz gt 0 then print,code,"shift to ends = ", correction_end
                 for j = i_match_end[0], nss_fit-1 do y_end_index[j] = y_end_index[j]+correction_end
              endif
              ;; using new info only if valid
              y_ssl = y_allinfo_bunch[i].ss_length
              if ((y_ssl gt 0.9*y_med_ssl) and (y_ssl lt 1.1*y_med_ssl)) then  y_ss_length[i_match] =  y_ssl else  y_ss_length[i_match] = y_med_ssl  
              y_isl = y_allinfo_bunch[i].is_length
              if ((y_isl gt 0.2*y_med_isl) and (y_isl lt 1.8*y_med_isl)) then  y_is_length[i_match] = y_isl else  y_is_length[i_match] = y_med_isl
              y_ampli = y_allinfo_bunch[i].amplitude
              if ((y_ampli le 0.9*y_med_amp) or (y_ampli ge 1.1*y_med_amp)) then y_ampli =  ampli0 + i*y_med_step
              y_amplitude[i_match[0]:nss_fit-1] = y_ampli + lindgen(nss_fit-i_match[0])*y_med_step
              
           endif
           
           endfor
       
     endif

     
     ;; adding info if at the end of the scan
     ;;_________________________________________________________________________________________________________________
     if (keyword_set(end_of_scan)) then begin
        
        ;;could have one more (uncomplete) subscan
        if bavaz gt 0 then print,code, 'fin du scan.....'
        med_length = median(y_allinfo_estimate.ss_length+y_allinfo_estimate.is_length)
        if bavaz gt 0 then print,code, 'dernier ibeg trouve : ',n_samples_since_beginning-1+y_allinfo_bunch[nss_bunch-1].beg_index
        if bavaz gt 0 then print,code, 'dernier ibeg first guess : ', y_beg_index[nss_fit-1] 
        ;;print, 'de la place pour un dernier ibeg ?  : ', (x_beg_index[nss_fit-1]+med_length-tol)
        der_beg_index = n_samples_since_beginning-1+y_allinfo_bunch[nss_bunch-1].beg_index
        if (der_beg_index gt (y_beg_index[nss_fit-1]+med_length-tol)) then begin
           
           y_beg_index = [y_beg_index,der_beg_index]
           y_ss_length = [y_ss_length,y_allinfo_bunch[nss_bunch-1].ss_length]
           y_is_length = [y_is_length,y_allinfo_bunch[nss_bunch-1].is_length]
           y_amplitude = [y_amplitude,y_allinfo_bunch[nss_bunch-1].amplitude]
           y_end_index = [y_end_index,y_allinfo_bunch[nss_bunch-1].end_index]
           y_beg_index_flag = [y_beg_index_flag,y_allinfo_bunch[nss_bunch-1].beg_index_flag]
        endif
        
     endif

    

     ;;   updating pointing el info
     ;;_________________________________________________________________________________________________________________
   
     y_allinfo_estimate.ss_length = y_ss_length 
     y_allinfo_estimate.is_length = y_is_length
     y_allinfo_estimate.beg_index = y_beg_index
     y_allinfo_estimate.end_index = y_end_index
     y_allinfo_estimate.amplitude = y_amplitude
     y_allinfo_estimate.beg_index_flag = y_beg_index_flag

     
     endif else if bava gt 0 then print,code, "bunch from ", index[0], " to ", index[nsp_bunch-1],": fail to extract any info "


    
  wstop = where( y_allinfo_estimate.is_length lt 0, costop)
  if costop gt 0 then stop  
     
     ;;stop
     
  end
  
