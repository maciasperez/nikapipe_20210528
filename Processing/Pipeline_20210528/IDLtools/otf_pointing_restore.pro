pro otf_pointing_restore, x, y, flag, x_restored, y_restored, outflag_restored, first_subscan_beg_index, last_subscan_end_index, ind_beg_scan=ind_beg_scan, ind_end_scan=ind_end_scan,reiter=reiter, chatty=chatty, debug=debug, plot=plot


;+
; INPUTS
;
;   x: azimuth-like (fast) coordinate of the OTF scan
;   y: elevation-like (slow) coordinate of the OTF scan  
;   flag : binary flag (0 = valid sample, 1 = unvalid)  
;  
; OUTPUTS
;   x_restored
;   y_restored 
;
; LP, 2014, May
;-

  code = "IDLtools/otf_pointing_restore >> "
  bav = 0
  if keyword_set(chatty) then bav = 1
  bavard = 0
  if keyword_set(debug) then bavard = 1
  x_restored = -1

  nsn = n_elements(x)
  myflag = flag
  w_ok = where(myflag lt 1, n_valid_ok, compl=w_nok, ncompl=n_valid_nok)

  ;; if all samples are valid, nothing to be restored.... 
  if (n_valid_nok gt 0) then begin

  ;; I.   reconstruction from parameter estimate into interval of good samples
  ;;----------------------------------------------------------------------------
     
  ;; nb: le scan ne commence pas par une zone inter-subscans
  ;; (=RESTRICTION)
  ;; flag_scan = 0 : on subscan
  ;; flag_scan = 1 : entre 2 subscans (critere "speedflag")
  ;; flag_scan = 3 : zone a ajouter pour l'elevation
  ;; flag_scan = 2 : zone a enlever pour l'azymuth 
  otf_pointing_flag_subscan, x[w_ok], y[w_ok], flag_scan, idebs, ifins_az, ifins_el
  ibeg_fit = w_ok[idebs[0]]              ;; first start of a subscan
  ;;iend_fit = w_ok[ifins_az[nfins-1]]     ;; last end of a subscan
  iend_scan = w_ok[n_valid_ok-1]
  if keyword_set(ind_end_scan) then iend_scan=ind_end_scan
  iend_fit = iend_scan
  ndebs = n_elements(idebs)

  ;; initialising outputs first detected subscan's beginning
  ;; index and last detected subscan's ending index
  first_subscan_beg_index = ibeg_fit 
  last_subscan_end_index  = iend_scan
  waz = where(ifins_az gt idebs[0], caz)
  wel = where(ifins_el gt idebs[0], cel)
  tab=0
  if caz gt 0 then tab = ifins_az[waz]
  if cel gt 0 then tab = [tab, ifins_el[wel]]
  if ((caz gt 0) or (cel gt 0)) then last_subscan_end_index  = max([w_ok[tab]]) 
      

  index = lindgen(nsn)
  if keyword_set(plot) then begin
     plot,index[w_ok[0]:w_ok[n_valid_ok-1]], x[w_ok[0]:w_ok[n_valid_ok-1]],col=0,xr=[1000,3000],yr=[-210,210]
     oplot, index[w_ok],flag_scan*10,col=250 ;,psym=2
     oplot,index[w_ok], x[w_ok],col=150,psym=3
     oplot,index, myflag*100.,col=50
  endif
  
  
  if n_valid_ok gt 1000 and iend_fit gt ibeg_fit then begin
         
     ;; first coarse estimate of median parameters (phase, median
     ;; scan length, median inter-scan interval length, ...)
     ;;_________________________________________________________________________________
     t = lindgen(iend_fit-ibeg_fit+1)
     flag_fit = lonarr(nsn)+1L
     flag_fit[ibeg_fit:iend_fit]=0L
     w_fit = where(flag_fit eq 0, nsp_fit)
     otf_pointing_getinfo, t, x[w_fit], y[w_fit], myflag[w_fit], x_info, y_info, chatty=chatty
    
     ;;x_info = {avg_ssl_ok:0., avg_isl_ok:0., phase:0L, amplitude:0.}
     ;;y_info = {avg_ssl_ok:0., avg_isl_ok:0., phase:0L, amplitude:0., delta:0.}
     
     ;; by construct, x_info.phase and y_info.phase should be null
     

     ;; first guess on the parameters structure that defines the scan
     ;;--------------------------------------------------------------------------------------------------
     ;; number of subscans within the valid interval 
     ;; (starting at the beginning of a subscan and endind at the
     ;; end of a subscan)
     med_length = round(x_info.avg_ssl_ok+x_info.avg_isl_ok-1)
     nss_fit = ceil( (nsp_fit+x_info.phase)/float(med_length) ) 
     ;;nss_fit = round( ((nsp_fit+x_info.phase-x_info.avg_ssl_ok)/med_length
     ;;)) + 1 ; note that the last "is" is lost     
     if nss_fit lt 1 then begin
        message, /info, 'Not enough points to reconstruct pointing'
        return
     endif
     otf_pointing_init, nss_fit, x_info, y_info, x_allinfo_estimate, y_allinfo_estimate
     
     ;; initializing output flag timeline
     ;;_____________________________________________________________________________
     outflag_restored = lonarr(nsn)
     ;; all unvalid sample set to 5 as a start
     outflag_restored[w_nok] = 5  
     


     ;; extract info from valid sample
     ;;_____________________________________________________________________________
     
     flag_holes = deriv(myflag[w_fit])
     
     idebs_bunch = [w_fit[0]] ;; nb w_fit[0] = beginning of the first subscan
     ifins_bunch = [w_fit[nsp_fit-1]] 

     idebs_hole = where(flag_holes gt 0 and shift(flag_holes,1) eq 0, n_holes)
     ifins_hole = where(flag_holes lt 0 and shift(flag_holes,-1) eq 0, n_holes)
     
     if (n_holes gt 0) then idebs_bunch = [idebs_bunch,w_fit[ifins_hole]+1] 
     if (n_holes gt 0) then ifins_bunch = [w_fit[idebs_hole]-1,ifins_bunch] 
     n_bunch = n_elements(idebs_bunch)
     
     ;; START LOOPING ON VALID BUNCH OF SAMPLE
     ;;----------------------------------------------------------------
     ;; otf pointing is very sensitive to the params: try and use
     ;; as many samples as possible to estimate the params
     
     
     for ibunch = 0, n_bunch-1 do begin
        
        ;; TEST ON BUNCH LENGTH
        ;;----------------------------------------------------------------
        ;; discard too short bunches
        nsp_bunch = ifins_bunch[ibunch]-idebs_bunch[ibunch]+1
        ;;if nsp_bunch gt med_length then begin
        
        if bav gt 0 then print,code, "bunch from ",idebs_bunch[ibunch],", to ", ifins_bunch[ibunch]

        ;; begins and ends of the bunch
        otf_pointing_flag_subscan, x[idebs_bunch[ibunch]:ifins_bunch[ibunch]], y[idebs_bunch[ibunch]:ifins_bunch[ibunch]], flag_scan, ib_bunch, ie_az_bunch
        nb_bunch = n_elements(ib_bunch)
        ne_bunch = n_elements(ie_bunch)
        ;; by construct, the first bunch begins at a subscan beginning
        if (ibunch eq 0) then ib_bunch=[0,ib_bunch]             
        ;; no subscan end may be found
        if (ne_bunch eq 0) then ie_az_bunch = nsp_bunch-1
        
        ;; bunch should be long enough to estimate params
        ;; (should have found at least a new subscan beginning)
        ;;if  ((nb_bunch ge 1) or (ne_bunch ge 1))  then begin 
        if  (nb_bunch ge 1)  then begin 
           
           ibeg_bunch = idebs_bunch[ibunch]
           ;;if (ib_bunch[0] lt ie_az_bunch[0]) then ibeg_bunch = idebs_bunch[ibunch]+ib_bunch[0] ;; do not start within an IS (=restriction)
           iend_bunch = ifins_bunch[ibunch]
           
                                 
           ;; START EXTRACTING INFO 
           ;;----------------------------------------------------------------
           t = lindgen(iend_bunch-ibeg_bunch+1)
           flag_bunch = lonarr(nsn)+1L
           flag_bunch[ibeg_bunch:iend_bunch]=0L
           w_bunch = where(flag_bunch eq 0, nsp_bunch)
  

           lastbunch=0
           if (ibunch eq n_bunch-1) then lastbunch=1
           otf_pointing_updateinfo_az, index[w_bunch], x[w_bunch], y[w_bunch], myflag[w_bunch], x_allinfo_estimate, first_working_index=index[w_fit[0]], end_of_scan=lastbunch, chatty=chatty, debug=debug
           otf_pointing_updateinfo_el, index[w_bunch], x[w_bunch], y[w_bunch], myflag[w_bunch], y_allinfo_estimate, first_working_index=index[w_fit[0]], end_of_scan=lastbunch, chatty=chatty, debug=debug
               
           
        endif else if bav gt 0 then print,code, "bunch ", ibunch, ": not enough info --> not used"
        
     
        ;;print, x_allinfo_estimate.beg_index
        
     endfor
     
     ;; END OF THE LOOP ON VALID BUNCH OF SAMPLE
     ;;----------------------------------------------------------------
     
     
     ;;-------------------------------- azimuth ----------------------------------------
     t = lindgen(iend_fit-ibeg_fit+1)
     x_restored_w_fit = otf_pointing_x(t, x_allinfo_estimate, chatty=chatty, debug=debug)
     x_restored = x
     x_restored[w_fit] = x_restored_w_fit
          
     ;;-------------------------------- elevation ----------------------------------------
     y_restored_w_fit = otf_pointing_y(t, y_allinfo_estimate, chatty=chatty, debug=debug)
     y_restored = y
     y_restored[w_fit] = y_restored_w_fit

     
     ;; ADD HERE THE FLAGGING
    
     ;; pour chaque trou, compter tous les idebs et ifins inclus dans
     ;; le trou
     ;;----------------------------
     iextrem      = [x_allinfo_estimate.beg_index,x_allinfo_estimate.end_index]
     iextrem_flag = [x_allinfo_estimate.beg_index_flag,x_allinfo_estimate.end_index_flag]
     rangeur = SORT( iextrem)
     iextrem      = iextrem[rangeur]
     iextrem_flag = iextrem_flag[rangeur]  
  
     for i_hole = 0, n_holes-1 do begin
        if bavard gt 0 then print,code, "begin hole at ",w_fit[idebs_hole[i_hole]]
        if bavard gt 0 then print,code, "end hole at ",w_fit[ifins_hole[i_hole]] 
        nsp_hole =  ifins_hole[i_hole] - idebs_hole[i_hole] + 1
        iextrem_miss = where(iextrem gt idebs_hole[i_hole] and iextrem lt ifins_hole[i_hole], n_miss)
        outflag_restored[ w_fit[idebs_hole[i_hole]] : w_fit[ifins_hole[i_hole]]] = replicate(n_miss,nsp_hole) 
        ;;----------------------------
        ;; + verifier que les idebs, ou iends du bord du trou ont ete vus
        ;; (tant qu'un extremum n'a pas ete vu, on ajoute)       
        justeavant = idebs_hole[i_hole]
        ;;print,"justeavant = ",w_fit[justeavant]
        while iextrem_flag(max(where(iextrem lt justeavant))) gt 0 do begin
           outflag_restored[  w_fit[idebs_hole[i_hole]] :  w_fit[ifins_hole[i_hole]]]+=1
           justeavant = iextrem[max(where(iextrem lt justeavant))]
           print,w_fit[justeavant]
        endwhile
        ;; initiated from the sample index at the end of the hole
        justeapres = ifins_hole[i_hole]
        if justeapres lt max(iextrem) then begin
           while iextrem_flag(min(where(iextrem gt justeapres))) gt 0 do begin
              outflag_restored[  w_fit[idebs_hole[i_hole]] :  w_fit[ifins_hole[i_hole]]]+=1
              justeapres = iextrem[min(where(iextrem gt justeapres))]
              if (justeapres ge max(iextrem)) then break
           endwhile 
        endif
     endfor
     

     if keyword_set(plot) then begin
        w_vu = where(iextrem_flag lt 1)
        plot,index,x, col=0, yr=[-210,210],xr=[1000,10000] 
        oplot,index,x_restored, col=50 
        oplot,index[w_fit],x[w_fit], col=100
        oplot,index[w_fit[iextrem]], x[w_fit[iextrem]], col=250, psym=1
        oplot,index[w_fit[iextrem[w_vu]]], x[w_fit[iextrem[w_vu]]], col=150, psym=1
        oplot,index,outflag_restored*50., col=200
     endif

     ;;stop



     ;;
     ;;
     ;;
     ;;       RE-ITERATING IF GLOBAL SCAN PARAMETERS CHANGE
     ;; 
     ;;___________________________________________________________________________________________

     ;; if ((n_bunch gt 1) and keyword_set(reiter)) then begin
        
     ;;    ;;       re-estimate the global scan parameter
     ;;    otf_pointing_getinfo, t, x_restored[w_fit], y_restored[w_fit], myflag[w_fit], x_info_restored, y_info_restored, chatty=chatty
        
     ;;    med_length_2 = (x_info_restored.avg_ssl_ok+x_info_restored.avg_isl_ok)
     ;;    nss_fit = round( ((nsp_fit+x_info_restored.phase-x_info_restored.avg_ssl_ok)/med_length_2 )) + 1 ; note that the last "is" is lost
     
     ;;    x_med_ssl_2 = round(x_info_restored.avg_ssl_ok)
     ;;    x_med_isl_2 = round(x_info_restored.avg_isl_ok)
     ;;    x_med_amp_2 = x_info_restored.amplitude/2.
        
     ;;    y_med_ssl_2 = round(y_info_restored.avg_ssl_ok)
     ;;    y_med_isl_2 = round(y_info_restored.avg_isl_ok)
     ;;    y_ampli0_2 = y_info_restored.amplitude
     ;;    y_med_step_2 = y_info_restored.delta

     ;;    if ((x_med_ssl_2 ne x_med_ssl) or (x_med_isl_2 ne x_med_isl) or (x_med_amp_2 ne x_med_amp)) then begin

     ;;       ;; REITERATING THE RESTORATION
     ;;       if bav gt 0 then print,code, "REITERATING THE RESTORATION"
                
   
     ;;       x_ss_length = replicate(x_med_ssl_2,nss_fit)
     ;;       x_is_length = replicate(x_med_isl_2,nss_fit)
     ;;       x_is_length[nss_fit-1] = 0 
     ;;       x_beg_index = lindgen(nss_fit)*(med_length_2-1)
     ;;       x_end_index = x_beg_index+x_med_ssl_2-1
     ;;       x_amplitude = replicate(x_med_amp_2,nss_fit)
     ;;       i_pair = 2.*lindgen(ceil(nss_fit/2.))
     ;;       x_amplitude[i_pair] = -1.* x_amplitude[i_pair]
     ;;       ;; the most important info is beg_index: flagging measured beg_index
     ;;       ;; (not to change them afterwards) 
     ;;       x_beg_index_flag = lonarr(nss_fit)+1L
     ;;       x_end_index_flag = lonarr(nss_fit)+1L
                    
     ;;       y_ss_length = replicate(y_med_ssl_2,nss_fit)
     ;;       y_is_length = replicate(y_med_isl_2,nss_fit)
     ;;       y_is_length[nss_fit-1] = 0 
     ;;       y_beg_index = lindgen(nss_fit)*(med_length_2-1)
     ;;       y_end_index = y_beg_index+y_med_ssl_2-1
     ;;       y_amplitude = y_ampli0_2+lindgen(nss_fit)*y_med_step_2
     ;;       ;; the most important info is beg_index: flagging measured beg_index
     ;;       ;; (not to change them afterwards) 
     ;;       y_beg_index_flag = lonarr(nss_fit)+1L

           
     ;;       x_allinfo_estimate = replicate({ss_length:0., is_length:0., beg_index:0L, end_index:0L, beg_index_flag:0, end_index_flag:0, amplitude:0.},nss_fit)
     ;;       x_allinfo_estimate.ss_length = x_ss_length 
     ;;       x_allinfo_estimate.is_length = x_is_length
     ;;       x_allinfo_estimate.beg_index = x_beg_index
     ;;       x_allinfo_estimate.end_index = x_end_index
     ;;       x_allinfo_estimate.amplitude = x_amplitude
     ;;       x_allinfo_estimate.beg_index_flag = x_beg_index_flag
     ;;       x_allinfo_estimate.end_index_flag = x_end_index_flag

     ;;       y_allinfo_estimate = replicate({ss_length:0., is_length:0., beg_index:0L, end_index:0L, amplitude:0.},nss_fit)
     ;;       y_allinfo_estimate.ss_length = y_ss_length 
     ;;       y_allinfo_estimate.is_length = y_is_length
     ;;       y_allinfo_estimate.beg_index = y_beg_index
     ;;       y_allinfo_estimate.end_index = y_end_index
     ;;       y_allinfo_estimate.amplitude = y_amplitude
     ;;       y_allinfo_estimate.beg_index_flag = y_beg_index_flag


           
     ;;       ;;stop

     ;;       ;; START LOOPING ON VALID BUNCH OF SAMPLE
     ;;       ;;----------------------------------------------------------------
     ;;       ;; otf pointing is very sensitive to the params: try and use
     ;;       ;; as many samples as possible to estimate the params
 
     ;;       for ibunch = 0, n_bunch-1 do begin
              
     ;;          ;; TEST ON BUNCH LENGTH
     ;;          ;;----------------------------------------------------------------
     ;;          ;; discard too short bunches
     ;;          nsp_bunch = ifins_bunch[ibunch]-idebs_bunch[ibunch]+1
     ;;          ;;if nsp_bunch gt med_length then begin
              
     ;;          if bav gt 0 then print,code, "bunch from ",idebs_bunch[ibunch],", to ", ifins_bunch[ibunch]
              
     ;;          ;; begins and ends of the bunch
     ;;          otf_pointing_flag_subscan, x[idebs_bunch[ibunch]:ifins_bunch[ibunch]], y[idebs_bunch[ibunch]:ifins_bunch[ibunch]], flag_scan,ib_bunch, ie_az_bunch
     ;;          nb_bunch = n_elements(ib_bunch)
     ;;          ne_bunch = n_elements(ie_az_bunch)
     ;;          ;; by construct, the first bunch begins at a subscan beginning
     ;;          if (ibunch eq 0) then ib_bunch=[0,ib_bunch]             
     ;;          ;; no subscan end may be found
     ;;          if (ne_bunch eq 0) then ie_az_bunch = nsp_bunch-1
              
     ;;          ;; bunch should be long enought to estimate params
     ;;          ;; (should have found at least a new subscan beginning)
     ;;          if  (nb_bunch ge 1)  then begin 
                 
     ;;             ibeg_bunch = idebs_bunch[ibunch]
     ;;             ;;if (ib_bunch[0] lt ie_az_bunch[0]) then ibeg_bunch = idebs_bunch[ibunch]+ib_bunch[0] ;; do not start within an IS (=restriction)
     ;;             iend_bunch = ifins_bunch[ibunch]
                 
                 
     ;;             ;; START EXTRACTING INFO 
     ;;             ;;----------------------------------------------------------------
     ;;             t = lindgen(iend_bunch-ibeg_bunch+1)
     ;;             flag_bunch = lonarr(nsn)+1L
     ;;             flag_bunch[ibeg_bunch:iend_bunch]=0L
     ;;             w_bunch = where(flag_bunch eq 0, nsp_bunch)
                 
                 
     ;;             lastbunch=0
     ;;             if (ibunch eq n_bunch-1) then lastbunch=1
     ;;             otf_pointing_updateinfo_az, index[w_bunch], x[w_bunch], y[w_bunch], myflag[w_bunch], x_allinfo_estimate, first_working_index=index[w_fit[0]], end_of_scan=lastbunch, chatty=chatty, debug=debug
     ;;             otf_pointing_updateinfo_el, index[w_bunch], x[w_bunch], y[w_bunch], myflag[w_bunch], y_allinfo_estimate, first_working_index=index[w_fit[0]], end_of_scan=lastbunch, chatty=chatty, debug=debug
               
     ;;          endif else if bav gt 0 then print,code, "bunch ", ibunch, ": not enough info --> not used"
              
              
     ;;          ;;print, x_allinfo_estimate.beg_index
              
     ;;       endfor
              
     ;;       ;;-------------------------------- azimuth ----------------------------------------
     ;;       t = lindgen(iend_fit-ibeg_fit+1)
     ;;       x_restored_w_fit = otf_pointing_x(t, x_allinfo_estimate, chatty=chatty, debug=debug)
     ;;       x_restored = x
     ;;       x_restored[w_fit] = x_restored_w_fit
           
     ;;       ;;-------------------------------- elevation ----------------------------------------
     ;;       y_restored_w_fit = otf_pointing_y(t, yallinfo, chatty=chatty, debug=debug)
     ;;       y_restored = y
     ;;       y_restored[w_fit] = y_restored_w_fit

     ;;       ;;stop
           
     ;;    endif

        
     ;; endif
     
     
     ;;
     ;;
     ;;
     ;;      completing info at the beginning and end of the scan
     ;;
     ;;
     ;;____________________________________________________________________________________
     
     ;; In case of a hole at the beginning of the scan valid
     ;; interval : complete the param structure 
     ;;----------------------------------------------------------------------------------
     ibeg_scan = w_ok[0]
     if keyword_set(ind_beg_scan) then ibeg_scan=ind_beg_scan
     if (ibeg_fit gt ibeg_scan) then begin
        
        if bav gt 0 then print,code, "INFO TO PROPAGATE TO THE BEGINNING OF THE SCAN" 

        ;; reminder : ibeg_fit  = first beginning index seen
        ;; reminder : ibeg_scan = first sample ok
        ;; reminder : if \ind_beg_scan, ibeg_scan can be even smaller

        ;; testing for holes at the beginning of the scan (not yet
        ;; restored)
        if (total(myflag[ibeg_scan:ibeg_fit]) gt 0) then begin
           
           ;; interval to be treated (increase by a subscan to include
           ;; the first beginning of w_fit)
           flag_beg = lonarr(nsn)+1L
           flag_beg[ibeg_scan:ibeg_fit+x_allinfo_estimate[1].beg_index-1]=0L
           w = where(flag_beg eq 0, nsp_beg)
           
           flag_restored = myflag
           flag_restored[w_fit] = 0L
           ;; w_holes_w = where(flag_restored[w] gt 0, nw_holes)
           ;; w_holes = w[w_holes_w]
           
           
           ;; re-estimating averaged scan param from restored pointing
           otf_pointing_getinfo, index[w_fit], x_restored[w_fit], y_restored[w_fit], flag_restored[w_fit], x_info_restored, y_info_restored,showplot=plot, model=1, chatty=chatty
           ;; NB: on a ajoute un subscan --> signe de l'amplitude a changer 

           ;; guessing scan params per subscan, filling the structure backward 
           med_length = round((x_info_restored.avg_ssl_ok+x_info_restored.avg_isl_ok-1))
           nss_beg = ceil( nsp_beg/float(med_length) )
           ;; NB: on a ajoute un ou plusieurs subscans --> signe de
           ;; l'amplitude peut changer 
           x_info_restored.amplitude = (-1.)^(nss_beg-1)*x_info_restored.amplitude
           otf_pointing_init, nss_beg, x_info_restored, y_info_restored, x_allinfo_beg, y_allinfo_beg, /backward, nsample=nsp_beg
           

           ;; stop
           ;; plot, index, x, xr=[ibeg_scan, ibeg_scan+nsp_beg], col=0
           ;; ;oplot,index,x_restored, col=100
           ;; oplot,index, flag_beg*10, col=200
           ;; oplot,index[ibeg_scan+x_allinfo_beg.BEG_INDEX], x[ibeg_scan+x_allinfo_beg.BEG_INDEX], psym=2, col=50
           ;; oplot,index[ibeg_scan+x_allinfo_beg.END_INDEX], x[ibeg_scan+x_allinfo_beg.END_INDEX], psym=1, col=250
           ;; oplot,index[ibeg_fit+x_allinfo_estimate.BEG_INDEX], x[ibeg_fit+x_allinfo_estimate.BEG_INDEX], psym=2, col=100
           ;; oplot,index[ibeg_fit+x_allinfo_estimate.END_INDEX], x[ibeg_fit+x_allinfo_estimate.END_INDEX], psym=1, col=200
           
           
           ;; UPDATE according to valid data not yet used in the w_fit
           ;; interval (if any)          
           ibeg_bunch = w_ok[0]
           if (ibeg_bunch lt ibeg_fit) then begin
              ;iend_bunch = ibeg_fit+x_allinfo_estimate[1].beg_index-1
              iend_bunch = ibeg_fit+x_allinfo_estimate[0].end_index
              if bav gt 0 then print,code, "first bunch from ",ibeg_bunch,", to ", iend_bunch

              otf_pointing_flag_subscan, x[ibeg_bunch:iend_bunch], y[ibeg_bunch:iend_bunch], flag_scan_beg

              ;; plot, index, x, xr=[ibeg_scan, ibeg_scan+nsp_beg], col=0
              ;; oplot,index, flag_beg*10, col=200
              ;; oplot,index[ibeg_bunch:iend_bunch], flag_scan_beg*10, col=100
              
              t = lindgen(iend_bunch-ibeg_bunch+1)
              flag_bunch = lonarr(nsn)+1L
              flag_bunch[ibeg_bunch:iend_bunch]=0L
              w_bunch = where(flag_bunch eq 0, nsp_bunch)
              
              ;;otf_pointing_updateinfo_az, index[w_bunch],x[w_bunch], y[w_bunch], myflag[w_bunch], x_allinfo_beg, first_working_index=index[w_bunch[0]],chatty=chatty, debug=debug, mystop=0
              ;;otf_pointing_updateinfo_el, index[w_bunch], x[w_bunch], y[w_bunch], myflag[w_bunch], y_allinfo_beg, first_working_index=index[w_bunch[0]], chatty=chatty, debug=debug
              
              otf_pointing_updateinfo_az, index[w_bunch],x[w_bunch], y[w_bunch], myflag[w_bunch], x_allinfo_beg, first_working_index=index[ibeg_scan],chatty=chatty, debug=debug, mystop=0

              otf_pointing_updateinfo_el, index[w_bunch], x[w_bunch], y[w_bunch], myflag[w_bunch], y_allinfo_beg, first_working_index=index[ibeg_scan], chatty=chatty, debug=debug


              ;; check the first subscan at the beginning of the bunch           
              ;; i_first_beg_az = x_allinfo_beg[0].BEG_INDEX
              ;; if (i_first_beg_az lt 0) then begin
              ;;    for j=0,nss_beg-1 do x_allinfo_beg[j].BEG_INDEX -= i_first_beg_az
              ;;    for j=0,nss_beg-1 do x_allinfo_beg[j].END_INDEX -= i_first_beg_az
              ;;    x_allinfo_beg[0].ss_length =  x_allinfo_beg[0].END_INDEX + 1 
              ;;    endif
              ;; i_first_beg_el = y_allinfo_beg[0].BEG_INDEX
              ;; if (i_first_beg_el lt 0) then begin
              ;;    y_allinfo_beg[0].END_INDEX = y_allinfo_beg[0].END_INDEX - y_allinfo_beg[0].BEG_INDEX 
              ;;    y_allinfo_beg[0].BEG_INDEX = 0
              ;;    y_allinfo_beg[0].ss_length =  y_allinfo_beg[0].END_INDEX + 1 
              ;; endif

           endif
           

            ;;stop
           ;; window,1
           ;; plot, index, x, xr=[ibeg_scan, ibeg_scan+nsp_beg], col=0
           ;; oplot,index, flag_beg*10, col=200
           ;; oplot,index[ibeg_scan+x_allinfo_beg.BEG_INDEX], x[ibeg_scan+x_allinfo_beg.BEG_INDEX], psym=2, col=50
           ;; oplot,index[ibeg_scan+x_allinfo_beg.END_INDEX], x[ibeg_scan+x_allinfo_beg.END_INDEX], psym=1, col=250
           ;; ;; oplot,index[ibeg_fit+x_allinfo_estimate.BEG_INDEX], x[ibeg_fit+x_allinfo_estimate.BEG_INDEX], psym=2, col=100
           ;; ;; oplot,index[ibeg_fit+x_allinfo_estimate.END_INDEX], x[ibeg_fit+x_allinfo_estimate.END_INDEX], psym=1, col=200
           ;; window,2
           ;; plot, index, y, xr=[ibeg_scan, ibeg_scan+nsp_beg], col=0
           ;; oplot,index, flag_beg*10, col=200
           ;; oplot,index[ibeg_scan+y_allinfo_beg.BEG_INDEX], y[ibeg_scan+y_allinfo_beg.BEG_INDEX], psym=2, col=50
           ;; oplot,index[ibeg_scan+y_allinfo_beg.END_INDEX], y[ibeg_scan+y_allinfo_beg.END_INDEX], psym=1, col=250

           ;; check the first subscan at the beginning of the bunch           
           i_first_beg_az = x_allinfo_beg[0].BEG_INDEX
            if (i_first_beg_az lt 0) then begin
               x_allinfo_beg[0].BEG_INDEX = 0 
               pente = (x_allinfo_beg[1].amplitude - x_allinfo_beg[0].amplitude)/ x_allinfo_beg[0].ss_length 
               x_allinfo_beg[0].ss_length =  x_allinfo_beg[0].END_INDEX + 1
               x_allinfo_beg[0].amplitude =  x_allinfo_beg[0].amplitude + pente*abs(i_first_beg_az)
            endif
           i_first_beg_el = y_allinfo_beg[0].BEG_INDEX
           if (i_first_beg_el lt 0) then begin
              y_allinfo_beg[0].BEG_INDEX = 0
              y_allinfo_beg[0].ss_length =  y_allinfo_beg[0].END_INDEX + 1 
           endif
           ;; checking for an inter-subscan interval at the beginning
           ;; of the scan 
           if (i_first_beg_az gt 0 ) then begin
              x_allinfo_beg[0].BEG_INDEX = 0
              for j=0,nss_beg-1 do x_allinfo_beg[j].END_INDEX -= i_first_beg_az
              ;;i_first_beg_az = x_allinfo_beg[0].BEG_INDEX
           endif 
           if (i_first_beg_el gt 0) then begin 
              y_allinfo_beg[0].BEG_INDEX = 0
              for j=0,nss_beg-1 do y_allinfo_beg[j].END_INDEX -= i_first_beg_el 
              ;;i_first_beg_el = y_allinfo_beg[0].BEG_INDEX
           endif


           ;;-------------------------------- azimuth
           ;;                                 ----------------------------------------
           
           ;; cf : iend_bunch = ibeg_fit+x_allinfo_estimate[0].end_index
           

           ;; t_az = lindgen(ibeg_fit + x_allinfo_estimate[0].end_index - ibeg_scan - i_first_beg_az + 1)
           ;; x_restored_w_beg = otf_pointing_x(t_az, x_allinfo_beg, chatty=chatty, debug=debug)
           ;; x_restored0 = x_restored  ;; for plotting
           ;; x_restored[ibeg_scan+i_first_beg_az:ibeg_fit] = x_restored_w_beg[0:(ibeg_fit-ibeg_scan-i_first_beg_az)]
           ;; ;; if it begins with an IS interval
           ;; if i_first_beg_az gt 0 then x_restored[ibeg_scan:ibeg_scan+i_first_beg_az-1] = replicate( x_restored[w[i_first_beg_az]],i_first_beg_az)
           
           t_az = lindgen(ibeg_fit + x_allinfo_estimate[0].end_index - ibeg_scan + 1)
           x_restored_w_beg = otf_pointing_x(t_az, x_allinfo_beg, chatty=chatty, debug=debug)
           x_restored0 = x_restored  ;; for plotting
           x_restored[ibeg_scan:ibeg_fit] = x_restored_w_beg[0:(ibeg_fit-ibeg_scan)]
           ;; if it begins with an IS interval
           if i_first_beg_az gt 0 then x_restored[ibeg_scan:ibeg_scan+i_first_beg_az-1] = replicate( x_restored[w[i_first_beg_az]],i_first_beg_az)
           
           ;;-------------------------------- elevation
           ;;                                 ----------------------------------------
           ;; t_el = lindgen(ibeg_fit + x_allinfo_estimate[0].end_index - ibeg_scan - i_first_beg_el + 1)
           ;; y_restored_w_beg = otf_pointing_y(t_el, y_allinfo_beg, chatty=chatty, debug=debug)
           ;; y_restored0 = y_restored 
           ;; ;; on va pas jusqu'a ibeg_fit pour que le raccord se
           ;; ;; fasse dans l'intervalle IS
           ;; y_restored[ibeg_scan+i_first_beg_el:ibeg_fit-5] =
           ;; y_restored_w_beg[0:(ibeg_fit-ibeg_scan-i_first_beg_el-5)]

           t_el = lindgen(ibeg_fit + x_allinfo_estimate[0].end_index - ibeg_scan + 1)
           y_restored_w_beg = otf_pointing_y(t_el, y_allinfo_beg, chatty=chatty, debug=debug)
           y_restored0 = y_restored 
           y_restored[ibeg_scan:ibeg_fit-5] = y_restored_w_beg[0:(ibeg_fit-ibeg_scan-5)]
           ;; if it begins with an IS interval
           if i_first_beg_el gt 0 then y_restored[ibeg_scan:ibeg_scan+i_first_beg_el-1] = replicate( y_restored[w[i_first_beg_el]],i_first_beg_el)
           y_restored[ibeg_fit-5:ibeg_fit-1] = replicate( y_restored0[ibeg_fit],5)
        
           ;; stop
          
           ;; index = lindgen(nsn)
           ;; window,1
           ;; plot,index[ibeg_scan:5000], x[ibeg_scan:5000],col=0,xr=[ibeg_scan,2000],/xs,yr=[-210,210] 
           ;; oplot,index[ibeg_scan:5000], x_restored0[ibeg_scan:5000],col=180
           ;; oplot,index[ibeg_scan:5000], x_restored[ibeg_scan:5000],col=250
           ;; window,2
           ;; plot,index[ibeg_scan:3000], y[ibeg_scan:3000],col=0,xr=[ibeg_scan,2000],/xs
           ;; oplot,index[ibeg_scan:5000], y_restored0[ibeg_scan:5000],col=180
           ;; oplot,index[ibeg_scan:5000], y_restored[ibeg_scan:5000],col=250


           

        endif
     endif

     
     
     ;; In case of a hole at the end of the scan valid
     ;; interval : complete the param structure 
     ;;------------------------------------------------------------------------------------
     iend_scan = w_ok[n_valid_ok-1]
     if keyword_set(ind_end_scan) then iend_scan=ind_end_scan
     if (iend_fit lt iend_scan) then print, code, "INFO TO PROPAGATE TO THE END OF THE SCAN" 
     
    


    

  endif else begin
     print,code,  "NOT ENOUGH GOOD SAMPLE IN THE SCAN TO ATTEMPT A RECONSTRUCTION"
     x_restored = -1
     y_restore = -1
  endelse
     
  endif else print,code,  "NO UNVALID SAMPLE IN THE SCAN: NO RESTORATION NEEDED"
     
     
     
end
