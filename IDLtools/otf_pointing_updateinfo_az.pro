pro otf_pointing_updateinfo_az, index, x, y, flag, x_allinfo_estimate, first_working_index=first_working_index, end_of_scan=end_of_scan, chatty=chatty, debug=debug, mystop=mystop
  
;+
;
; AIM: update the azimuth-type parameter structure (quoted
; x_allinfo_estimate) from the valid sample in the x and y pointing timelines   
;
; INPUTS
; index : x and y index timeline
; x, y  : az, el-type pointing timeline
; flag  : x, y mask 
; 
;  
; INPUT/OUTPUT
; x_allinfo_estimate :  azimuth-type parameter structure for the
; whole scan --> the part corresponding to the given x, y is to be updated 
; {ss_length:0., is_length:0., beg_index:0L, end_index:0L, amplitude:0.}
;
;
; LP, 2014 May 13th
;
;-
  code = "IDLtools/otf_pointing_updateinfo_az >> "
  bava = 0
  if keyword_set(chatty) then bava=1
  bavaz = 0
  if keyword_set(debug) then bavaz=1

  
  nss_fit = n_elements(x_allinfo_estimate)
  
  x_ss_length = x_allinfo_estimate.ss_length
  x_is_length = x_allinfo_estimate.is_length
  x_amplitude = x_allinfo_estimate.amplitude
  x_beg_index = x_allinfo_estimate.beg_index
  x_end_index = x_allinfo_estimate.end_index
  x_beg_index_flag = x_allinfo_estimate.beg_index_flag
  x_end_index_flag = x_allinfo_estimate.end_index_flag

  if nss_fit gt 1 then x_med_ssl = median(x_ss_length) else x_med_ssl = x_ss_length
  if nss_fit gt 1 then x_med_isl = median(x_is_length) else x_med_isl = x_is_length
  if nss_fit gt 1 then x_med_amp = median(x_amplitude) else x_med_amp = x_amplitude
  
  
  
  
  ;; get info
  ;;_________________________________________________________________________________________________________________
  
  otf_pointing_getinfo, index, x, y, flag, x_info_bunch, y_info_bunch, x_allinfo_bunch, y_allinfo_bunch, x_all=1, chatty=chatty, debug=debug 
  
  
  ;; estimating global bunch-related param
  ;;_________________________________________________________________________________________________________________ 
  ;; number of sample in the bunch
  nsp_bunch = n_elements(index)
  
  
  ;; phase
  is_first_scan_to_shift = x_info_bunch.phase
  ;; in short bunch case, phase can be misestimated
  if bavaz gt 0 then print,code,"phase = ",is_first_scan_to_shift
  phase_bis = 0
  if (x_allinfo_bunch[0].beg_index eq 0) then phase_bis = max([2,x_med_ssl - (x_allinfo_bunch[0].end_index+1)])
  if phase_bis gt 2 then is_first_scan_to_shift=phase_bis
  if bavaz gt 0 then print,code," the first subscan starts after nsample = ", is_first_scan_to_shift
  
  ;; number of sample since the scan beginning (to the beginning of the bunch)
  first_work_index = 0
  if keyword_set(first_working_index) then first_work_index = first_working_index
  n_samples_since_beginning = index[0]-first_work_index+1
  if bavaz gt 0 then print,code," n_samples_since_beginning : ", n_samples_since_beginning
  
  ;;stop
  
  ;; plot, index, x, xr=[first_work_index, max(index)], col=0
  ;; oplot,index, flag*10, col=200
  ;; oplot,index[x_allinfo_bunch.BEG_INDEX], x[x_allinfo_bunch.BEG_INDEX], psym=2, col=50
  ;; oplot,index[x_allinfo_bunch.END_INDEX], x[x_allinfo_bunch.END_INDEX], psym=1, col=250
  ;; wplot=where(x_allinfo_estimate.BEG_INDEX-n_samples_since_beginning gt 0, co)
  ;; if co gt 0 then oplot,index[x_allinfo_estimate[wplot].BEG_INDEX-n_samples_since_beginning], x[x_allinfo_estimate[wplot].BEG_INDEX-n_samples_since_beginning], psym=2, col=100
  ;; wplot=where(x_allinfo_estimate.BEG_INDEX-n_samples_since_beginning gt 0, co)
  ;; if co gt 0 then oplot,index[x_allinfo_estimate[wplot].END_INDEX-n_samples_since_beginning], x[x_allinfo_estimate[wplot].END_INDEX-n_samples_since_beginning], psym=1, col=200


  ;; testing availability of new info from the bunch
  ;;______________________________________________________________________________________________________________
  if  (x_info_bunch.AVG_SSL_OK gt -1) then begin 
     
     nss_bunch = n_elements(x_allinfo_bunch)
     
     if keyword_set(mystop) then stop
     
     ;; treating first subscan
     ;;_________________________________________________________________________________________________________________
     i0 = 0
     ;; if the bunch begins in the middle of a subscan -->
     ;; the first beginning is missing --> need to readjust
     ;; using the first ending index
     if (is_first_scan_to_shift gt 0) then begin
        
        i0=1
        tol=100
        i_first_begin_found = where((x_beg_index gt (n_samples_since_beginning+x_allinfo_bunch[1].beg_index-tol)) and (x_beg_index lt (n_samples_since_beginning+x_allinfo_bunch[1].beg_index+tol)),co)              
        if co gt 0 then i_begin_to_readjust = i_first_begin_found[0]-1 else i_begin_to_readjust = 0
        
        ;;readjust the  beg_index if not already measured
        if (x_beg_index_flag[i_begin_to_readjust] gt 0) then begin
           
           
           ;;plot,index, x,xr=[index[0],index[nsp_bunch-1]],/xs
           ;;oplot,index[x_allinfo_bunch.beg_index], x[x_allinfo_bunch.beg_index],col=150,psym=1
           ;;oplot,index[x_allinfo_bunch.end_index], x[x_allinfo_bunch.end_index],col=250,psym=1
           
           ;; get the shift from the first ending index found
           correction = (n_samples_since_beginning+x_allinfo_bunch[0].end_index-1-(x_beg_index[i_begin_to_readjust]+x_med_ssl)) 
           
           ;; improving the correction if enougth samples
           petit_ind = index[x_allinfo_bunch[0].beg_index:x_allinfo_bunch[0].end_index]
           n_first_ss = n_elements(petit_ind)
           if (n_first_ss ge x_med_ssl*0.4) then begin
              ae = x_allinfo_bunch[1].amplitude
              ad = x_amplitude[i_begin_to_readjust]
              petit_ind = index[x_allinfo_bunch[0].beg_index:x_allinfo_bunch[0].end_index]
              petit_x = x[x_allinfo_bunch[0].beg_index:x_allinfo_bunch[0].end_index]
              res = LINFIT(petit_ind, petit_x)
              pente = res[1]
              correction = n_samples_since_beginning-1+x_allinfo_bunch[0].end_index + (ad-ae)/pente - x_beg_index[i_begin_to_readjust]
           endif
           
           for j = i_begin_to_readjust, nss_fit-1 do x_beg_index[j] = x_beg_index[j]+correction  
           ;; correcting the previous IS interval accordingly
           if (x_beg_index[i_begin_to_readjust] - x_end_index[i_begin_to_readjust-1] + 1) gt 0 then begin
              x_is_length[i_begin_to_readjust-1] = x_beg_index[i_begin_to_readjust] - x_end_index[i_begin_to_readjust-1] + 1
           endif ;else begin 
              ;print,"negative is length !"
              ;stop
           ;endelse
           
        endif else begin
           ;; on the contrary, if the previous beginning was
           ;; measured, on can update the previous SS length
           if (x_ss_length[i_begin_to_readjust] eq x_med_ssl) then x_ss_length[i_begin_to_readjust] = (n_samples_since_beginning+x_allinfo_bunch[0].end_index-1) - x_beg_index[i_begin_to_readjust] + 1                                 
        endelse
        
        ;; accounting for the first ending index
        i_match=where((x_end_index gt (n_samples_since_beginning+x_allinfo_bunch[0].end_index-tol)) and (x_end_index lt (n_samples_since_beginning+x_allinfo_bunch[0].end_index+tol)),co)
        if ((co gt 0) and (i_match eq i_begin_to_readjust)) then begin
           correction_end = (n_samples_since_beginning-1+x_allinfo_bunch[0].end_index-x_end_index[i_match]) 
           if bavaz gt 0 then print,code,"shift to ends = ", correction_end
           for j = i_begin_to_readjust, nss_fit-1 do x_end_index[j] = x_end_index[j]+correction_end
            x_end_index_flag[i_begin_to_readjust]=0
        endif     

   
        ;; accounting for the first IS interval
        x_isl = x_allinfo_bunch[0].is_length
        if ((x_isl gt 0.2*x_med_isl) and (x_isl lt 1.8*x_med_isl)) then  x_is_length[i_begin_to_readjust] = x_isl
        
     endif
     
     
     
     ;; treating the remaining of the bunch
     ;;_________________________________________________________________________________________________________________
     if nss_bunch gt 1 then begin
        ;; filling in the index of the subscan beginnings + readjusting
        tol=100
        for i=i0, nss_bunch-1 do begin     
           i_match=where((x_beg_index gt (n_samples_since_beginning+x_allinfo_bunch[i].beg_index-tol)) and (x_beg_index lt (n_samples_since_beginning+x_allinfo_bunch[i].beg_index+tol)),co)
           if bavaz gt 0 then print,code,"for subscan number ",i," matching ? ",co
           if co gt 0 then begin
              correction = (n_samples_since_beginning+x_allinfo_bunch[i].beg_index-1-x_beg_index[i_match]) 
              if bavaz gt 0 then print,code,"shitf to beginnings = ",correction
              for j = i_match[0], nss_fit-1 do x_beg_index[j] = x_beg_index[j]+correction
              x_beg_index_flag[i_match]=0
              i_match_end=where((x_end_index gt (n_samples_since_beginning+x_allinfo_bunch[i].end_index-tol)) and (x_end_index lt (n_samples_since_beginning+x_allinfo_bunch[i].end_index+tol)),co)
              if bavaz gt 0 then print,code,"for subscan number ",i," matching end ? ",co
              if ((co gt 0) and (i_match_end eq i_match)) then begin
                 correction_end = (n_samples_since_beginning+x_allinfo_bunch[i].end_index-1-x_end_index[i_match_end]) 
                 if bavaz gt 0 then print,code,"shift to ends = ", correction_end
                 for j = i_match_end[0], nss_fit-1 do x_end_index[j] = x_end_index[j]+correction_end
                 ;; LP MODIF JUNE
                 if (x_allinfo_bunch[i].END_INDEX_FLAG lt 1) then x_end_index_flag[i_match]=0
              endif
              ;; using new info only if valid
              x_ssl = x_allinfo_bunch[i].ss_length
              if ((x_ssl gt 0.9*x_med_ssl) and (x_ssl lt 1.1*x_med_ssl)) then  x_ss_length[i_match] =  x_ssl
              x_isl = x_allinfo_bunch[i].is_length
              if ((x_isl gt 0.2*x_med_isl) and (x_isl lt 1.8*x_med_isl)) then  x_is_length[i_match] = x_isl
              x_amp = x_allinfo_bunch[i].amplitude
              if ((abs(x_amp) gt 0.9*abs(x_med_amp)) and (abs(x_amp) lt 1.1*abs(x_med_amp))) then  x_amplitude[i_match] = x_amp
           endif
        
        endfor
     
     endif



     ;; adding info if at the end of the scan
     ;;_________________________________________________________________________________________________________________
     if (keyword_set(end_of_scan)) then begin
        
        ;;could have one more (uncomplete) subscan
        if bavaz gt 0 then print,code, 'fin du scan.....'
        med_length = median(x_allinfo_estimate.ss_length+x_allinfo_estimate.is_length)
        if bavaz gt 0 then print,code, 'dernier ibeg trouve : ',n_samples_since_beginning-1+x_allinfo_bunch[nss_bunch-1].beg_index
        if bavaz gt 0 then print,code, 'dernier ibeg first guess : ', x_beg_index[nss_fit-1] 
        ;;print, 'de la place pour un dernier ibeg ?  : ', (x_beg_index[nss_fit-1]+med_length-tol)
        der_beg_index = n_samples_since_beginning-1+x_allinfo_bunch[nss_bunch-1].beg_index
        if (der_beg_index gt (x_beg_index[nss_fit-1]+med_length-tol)) then begin
           
           x_beg_index = [x_beg_index,der_beg_index]
           x_ss_length = [x_ss_length,x_allinfo_bunch[nss_bunch-1].ss_length]
           x_is_length = [x_is_length,x_allinfo_bunch[nss_bunch-1].is_length]
           x_amplitude = [x_amplitude,x_allinfo_bunch[nss_bunch-1].amplitude]
           x_end_index = [x_end_index,x_allinfo_bunch[nss_bunch-1].end_index]
           x_beg_index_flag = [x_beg_index_flag,x_allinfo_bunch[nss_bunch-1].beg_index_flag] 
           x_end_index_flag = [x_end_index_flag,x_allinfo_bunch[nss_bunch-1].end_index_flag]
        endif
        
     endif
     
     ;;   updating pointing az info
     ;;_________________________________________________________________________________________________________________
     x_allinfo_estimate.ss_length = x_ss_length 
     x_allinfo_estimate.is_length = x_is_length
     x_allinfo_estimate.beg_index = x_beg_index
     x_allinfo_estimate.end_index = x_end_index
     x_allinfo_estimate.amplitude = x_amplitude
     x_allinfo_estimate.beg_index_flag = x_beg_index_flag
     x_allinfo_estimate.end_index_flag = x_end_index_flag
     
  endif else if bava gt 0 then print,code,"bunch from ", index[0], " to ", index[nsp_bunch-1],": fail to extract any info "
  
  
  
  
  
     ;;stop
  
end

