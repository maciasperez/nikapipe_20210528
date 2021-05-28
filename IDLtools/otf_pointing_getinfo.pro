;+
;
; PURPOSE : 
; Extract as much info as possible from a given pointing with holes
; 
; OUTPUTS PARAMETER STRUCTURES:
;   1) 2 different kind of structures :
;       ---> x,y_info = global parameters
;       ---> x,y_allinfo = parameter describing each subscan
;   2) the global parameter structures     
;       ---> x_info : azimuth-like parameter 
;       ---> y_info : elevation-like parameter
;   3) the individual parameter structures
;      ---> x_allinfo is estimated if the "x_all" keyword is set 
;      ---> y_allinfo is estimated if the "y_all" keyword is set 
;
; LP, May 2014
;
;-




pro otf_pointing_getinfo, t, x, y, flag, x_info, y_info, x_allinfo, y_allinfo, x_all=x_all, y_all=y_all,showplot=showplot, model=model, chatty=chatty, debug=debug


nsp = n_elements(t)

if total( flag) ne 0 then begin
   w_ok  = where( flag eq 0, nw_ok)
endif else begin
   w_ok = lindgen( nsp)
   nw_ok = nsp
endelse

code = "IDLtools/otf_pointing_getinfo >> "
bava = 0
if keyword_set(chatty) then bava=1
bavaz = 0
if keyword_set(debug) then bavaz=1


if ((nw_ok gt 1000) or keyword_set(x_all) or keyword_set(y_all)) then begin


;; estimating scan parameters on valid samples
   

   ;;
   ;;     beginnings and ends of subscan (SS)
   ;;
   ;;_________________________________________________________________________________________________________________
   ;; flag_intersubscan = 0 : on subscan
   ;; flag_intersubscan = 1 : entre 2 subscans (critere "speedflag")
   ;; flag_intersubscan = 3 : zone a ajouter pour l'elevation
   ;; (sauf si le pointage est un modele )
   ;; flag_intersubscan = 2 : zone a enlever pour l'azymuth 

   if (keyword_set(model) and bava gt 0 ) then print,code, "POINTING IS A MODEL"
   otf_pointing_flag_subscan, x[w_ok], y[w_ok], flag_intersubscan, idebs_ok, ifins_az_ok, ifins_el_ok, model=model       
   w_off = where(flag_intersubscan gt 0, compl=w_on)
   w_speedflag = where((flag_intersubscan gt 0) and (flag_intersubscan lt 3)) ; 1 ou 2

   ;;ifins_az_ok = where((flag_intersubscan gt 1) and (shift(flag_intersubscan,-1) eq 1),nfins_az)
   ;;idebs_ok = where((flag_intersubscan eq 1) and (shift(flag_intersubscan,-1) eq 0) and (shift(flag_intersubscan,-2) eq 0) and (shift(flag_intersubscan,-3) eq 0),ndebs)
  
   ;; le dernier element n'est pas un debut
   ndebs     =  n_elements(idebs_ok)
   nfins_az  =  n_elements(ifins_az_ok)
   nfins_el  =  n_elements(ifins_el_ok)
   wder = where(idebs_ok eq nsp-1,co)
   if co gt 0 then if ndebs gt 1 then begin
      idebs_ok = idebs_ok[0:ndebs-2] 
      ndebs-=1
   endif else ndebs=0 



   if keyword_set(showplot) then begin
      window,0
      plot,t,y,col=0,xr=[min(t[w_ok]),max(t[w_ok])],/xs,yr=[min(y[w_ok]),max(y[w_ok])]
      oplot,t[w_ok[w_on]], y[w_ok[w_on]],col=150,psym=3
      oplot,t[w_ok[w_speedflag]], y[w_ok[w_speedflag]],col=250,psym=1
                                ;oplot,t[w_ok[w_on]], deriv(w_ok[w_on]),col=200
      oplot,t[w_ok], flag_intersubscan*10.,col=200
      window,1
      plot,t,x,col=0,yr=[-210,210],xr=[min(t[w_ok]),max(t[w_ok])],/xs,/ys
      oplot,t[w_ok[w_on]], x[w_ok[w_on]],col=150,psym=3
      oplot,t[w_ok[w_speedflag]], x[w_ok[w_speedflag]],col=250,psym=3
      oplot,t[w_ok], flag_intersubscan*10.,col=200


            
      ;plot,t,y,col=0,xr=[2200, 2300],/xs, yr=[-50,-20]
      ;oplot,t, flag_intersubscan*10.-50,col=200
      ;oplot,t, x/10.-10,col=100
      ;oplot,t[ifins_el_ok], y[ifins_el_ok],col=250,psym=1
      
   endif


   
   ;;
   ;;       checking avail. info in the scan 
   ;; 
   ;;_________________________________________________________________________________________________________________
   ;; at least a subscan beginning should be measured ;; get info
   if (ndebs gt 0) then begin

      idebs = w_ok[idebs_ok] > 0 ; FXD to solve weird cases where it can be negtaive
      if (nfins_el le 0) then ifins_el = w_ok[nw_ok-1] else ifins_el = w_ok[ifins_el_ok]
      if (nfins_az le 0) then ifins_az = w_ok[nw_ok-1] else ifins_az = w_ok[ifins_az_ok]
      nfins_az = n_elements(ifins_az)
      nfins_el = n_elements(ifins_el)
      nfins    = min([nfins_el,nfins_az])


      ;;
      ;;      initialising subscan param tables
      ;; 
      ;;_________________________________________________________________________________________________________________
      nss_vu     = min([ndebs,nfins])
      nss_vu_az  = min([ndebs,nfins_az])
      nss_vu_el  = min([ndebs,nfins_el])
      
      ss_length_el  = fltarr(nss_vu_el)
      ss_length_az  = fltarr(nss_vu_az)
      a_el          = fltarr(nss_vu_el)
      a_az          = fltarr(nss_vu_az)
      is_length_el  = fltarr(nss_vu_el)
      is_length_az  = fltarr(nss_vu_az)
      idebs_az_flag = intarr(nss_vu_az)+1
      ifins_az_flag = intarr(nss_vu_az)+1
      idebs_el_flag = intarr(nss_vu_el)+1
      

      ;; print,"idebs......................."
      ;; print,idebs
      ;; print,"ifins_az........................."
      ;; print,ifins_az
      ;; print,"x[idebs]..........................;"
      ;; print,x[idebs]
      ;; print,"x[ifins_az]..........................;"
      ;; print,x[ifins_az]
      ;;stop
     
      ;;
      ;;      filling-in azimuth subscan lengths
      ;; 
      ;;_________________________________________________________________________________________________________________
      ;; nb de debuts de subscan (meme partiel) 
      ndebs0=ndebs
      if idebs[0] gt ifins_az[0] then begin
         ;; subscans lengths
         ;; on rate le premier debut de subscan
         ;;--------------------------------------------------
         ss_length_az[0] = ifins_az[0]+1 
         idebs_az_flag[0] = 1
         ifins_az_flag[0] = 0
         a_az[0] = x[w_ok[0]]
         ndebs0=ndebs+1
         ie = 1
         ib = 0
      endif else begin
         ;; subscans lengths
         ;; on commence au debut d'un subscan 
         ;;--------------------------------------------------
         ss_length_az[0] = ifins_az[0] - idebs[0] + 1
         idebs_az_flag[0] = 0 
         ifins_az_flag[0] = 0
         a_az[0] = x[idebs[0]]
         ie = 1
         ib = 1
      endelse
      
      if (nss_vu_az gt 1) then begin
         for i=1, nss_vu_az-1 do begin
            if (ifins_az[ie] gt idebs[ib]) then begin
               ;; cas normal 
               ideb=max(idebs[where(idebs lt ifins_az[ie])],ib) ;; in case a deb was lost
               ss_length_az[i] = ifins_az[ie] - idebs[ib] + 1 
               idebs_az_flag[i] = 0
               ifins_az_flag[i] = 0
               a_az[i] = x[idebs[ib]]
                                ;flag_ss_ok[i] = 0
               ib+=1
               ie+=1
            endif else begin
               ;; on rate un debut : on passe
            ;   flag_ss_ok[i] = 1
               ie+=1
            endelse
         endfor 
         ;; NB: on a deja fait +1 sur ie et ib
      endif ;;else begin
      ;;ie+=1
      ;;ib+=1
      ;;endelse
      
      ;; ACCOUNTING FOR THE END OF SCAN (CAN BE A PARTIAL SUBSCAN)
      ;; AMELIORATION ? mieux si on complète avec la valeur mediane ????

      if (ie le nfins_az-1) and (ib le ndebs-1) then begin
         ss_length_az = [ss_length_az[0:nss_vu_az-1],ifins_az[ie] - idebs[ib] + 1]
         ifins_az_flag = [ifins_az_flag[0:nss_vu_az-1],0]
      endif else if (ib le ndebs-1) then begin
         ss_length_az = [ss_length_az[0:nss_vu_az-1], w_ok[nw_ok-1] - idebs[ib] + 1] 
      endif else if (idebs[ib-1] gt ifins_az[nfins_az-1] ) then ss_length_az = [ss_length_az[0:nss_vu_az-1], w_ok[nw_ok-1] - idebs[ib-1] + 1]

      if (ib le ndebs-1) then begin
         a_az = [a_az[0:nss_vu_az-1], x[idebs[ib]]]
         idebs_az_flag = [idebs_az_flag[0:nss_vu_az-1],0]
      endif else begin
         a_az = [a_az[0:nss_vu_az-1], x[w_ok[nw_ok-1]]]
         idebs_az_flag = [idebs_az_flag[0:nss_vu_az-1],1]
      endelse
      



      
      ;;
      ;;      filling-in elevation subscan lengths
      ;; 
      ;;_________________________________________________________________________________________________________________
      ;; print,"idebs......................."
      ;; print,idebs
      ;; print,"ifins_el........................."
      ;; print,ifins_el
      ;; print,"y[idebs]..........................;"
      ;; print,y[idebs]
      ;; print,"y[ifins_el]..........................;"
      ;; print,y[ifins_el]
      
      ;; nb (reel) de debuts de subscan (meme partiel) 
      ndebs0=ndebs
      if idebs[0] gt ifins_az[0] then begin
         ;; subscans lengths
         ;; on rate le premier debut de subscan
         ;;--------------------------------------------------
         ss_length_el[0] = ifins_el[0]+1 
         a_el[0] = median(y[w_ok[0]:ifins_el[0]])
         ndebs0=ndebs+1
         ie = 1
         ib = 0
      endif else begin
         ;; subscans lengths
         ;; on commence au debut d'un subscan 
         ;;--------------------------------------------------
         ss_length_el[0] = ifins_el[0] - idebs[0] + 1
         a_el[0] = median(y[idebs[0]:ifins_el[0]]) 
         idebs_el_flag[0] = 0
         ie = 1
         ib = 1
      endelse
      
      if (nss_vu_el gt 1) then begin
         for i=1, nss_vu_el-1 do begin
            if (ifins_el[ie] gt idebs[ib]) then begin
               ;; cas normal 
               ideb=max(idebs[where(idebs lt ifins_el[ie])],ib) ;; in case a deb was lost
               ss_length_el[i] = ifins_el[ie] - idebs[ib] + 1 
               a_el[i] = median(y[idebs[ib]:ifins_el[ie]])
               idebs_el_flag[i] = 0
               ib+=1
               ie+=1
            ;endif else if (ifins_el[ie] gt idebs[ib+1]) then begin
            ;   ;; on rate une fin
            ;   ideb=max(idebs[where(idebs lt ifins_el[ie])],ib)
            ;   ss_length_el[i] = ifins_el[ie] - idebs[ib] + 1 
            ;   ss_length_az[i] = ifins_az[ie] - idebs[ib] + 1 
            ;   a_az[i] = x[idebs[ib]]
            ;   a_el[i] = median(y[idebs[ib]:ifins_el[ie]])
            ;   flag_ss_ok[i] = 2
            ;   ib+=1
            ;   ie+=1
            endif else begin
               ;; on rate un debut : on passe
               ie+=1
            endelse
         endfor 
         ;; NB: on a deja fait +1 sur ie et ib
      endif 
      
      ;; ACCOUNTING FOR THE END OF SCAN (CAN BE A PARTIAL SUBSCAN)
      ;; AMELIORATION ? mieux si on complète avec la valeur mediane ????

      ;;stop
      
      if (ie le nfins_el-1) and (ib le ndebs-1) then ss_length_el = [ss_length_el[0:nss_vu_el-1],ifins_el[ie] - idebs[ib] + 1] else if (ib le ndebs-1) then ss_length_el = [ss_length_el[0:nss_vu_el-1], w_ok[nw_ok-1] - idebs[ib] + 1] else if (idebs[ib-1] gt ifins_el[nfins_el-1] ) then ss_length_el = [ss_length_el[0:nss_vu_el-1], w_ok[nw_ok-1] - idebs[ib-1] + 1]
              
      if (ie le nfins_el-1) and (ib le ndebs0-1) then a_el = [a_el[0:nss_vu_el-1],median(y[ idebs[ib] : ifins_el[ie]])] else if (ib le ndebs-1) then a_el = [a_el[0:nss_vu_el-1], median(y[idebs[ib]:w_ok[nw_ok-1]])] else a_el = [a_el[0:nss_vu_el-1], median(y[idebs[ib-1]:w_ok[nw_ok-1]])]
     
      if (ib le ndebs-1) then idebs_el_flag = [idebs_el_flag[0:nss_vu_el-1],0] 

      
      ;;
      ;;      filling-in azimuth inter-subscan (IS) interval lengths
      ;; 
      ;;_________________________________________________________________________________________________________________
      
      if idebs[0] gt ifins_az[0] then begin 
         ;; inter-subscans interval lengths
         ;; on commence par un intervalle entre-subscans
         ;;--------------------------------------------------
         is_length_az[0] = idebs[0] - ifins_az[0] + 1
         ie = 1
         ib = 1
      endif else begin
         ;; inter-subscans interval lengths
         ;; on rate (partiellement ?) le premier intervalle
         ;; entre-scans
         ;;--------------------------------------------------
         is_length_az[0] = idebs[0]+1
         ie = 0
         ib = 1
         ;; on saute le premier IS
         ;is_length_el[0] = idebs[1] - ifins_el[0] + 1
         ;is_length_az[0] = idebs[1] - ifins_az[0] + 1
      endelse
      
      if (nss_vu_az gt 1) then begin
         for i=1, nss_vu_az-1 do begin
            ;;if ((idebs[ib] gt ifins_el[ie]) and ((idebs[ib] lt
            ;;ifins_el[ie+1]))) then begin
            if (idebs[ib] gt ifins_az[ie]) then begin
               ifin=max(ifins_az[where(ifins_az lt idebs[ib])],ie)
               ;; cas normal
               is_length_az[i] = idebs[ib] - ifins_az[ie] + 1 
               ib+=1
               ie+=1
            endif else if (idebs[ib] gt ifins_az[ie+1]) then begin
               ;; on rate un debut
               ifin=max(ifins_az[where(ifins_az lt idebs[ib])],ie)
               is_length_az[i] = idebs[ib] - ifins_az[ie] + 1 
               ib+=1
               ie+=1
            endif else begin
               ;; on rate une fin : on passe
               ib+=1
            endelse
         endfor 
      endif else begin
         ib+=1
         ie+=1
      endelse
      if (ib le ndebs-1) and (ie le nfins_az-1) then begin
         if idebs[ib] - ifins_az[ie] + 1 gt 0 then begin
            is_length_az = [is_length_az[0:nss_vu_az-1],idebs[ib] - ifins_az[ie] + 1] 
         endif else print, "denier is negatif"
      endif

      
      ;;
      ;;      filling-in elevation inter-subscan (IS) interval lengths
      ;; 
      ;;________________________________________________________________________________________________________________
      if idebs[0] gt ifins_el[0] then begin 
         ;; inter-subscans interval lengths
         ;; on commence par un intervalle entre-scans
         ;;--------------------------------------------------
         is_length_el[0] = idebs[0] - ifins_el[0] + 1
         ie = 1
         ib = 1
      endif else begin
         ;; inter-subscans interval lengths
         ;; on rate (partiellement ?) le premier intervalle
         ;; entre-scans
         ;;--------------------------------------------------
         is_length_el[0] = idebs[0]+1
         ie = 0
         ib = 1
         ;; on saute le premier IS
         ;is_length_el[0] = idebs[1] - ifins_el[0] + 1
         ;is_length_az[0] = idebs[1] - ifins_az[0] + 1
      endelse
      
      if (nss_vu_el gt 1) then begin
         for i=1, nss_vu_el-1 do begin
            ;;if ((idebs[ib] gt ifins_el[ie]) and ((idebs[ib] lt
            ;;ifins_el[ie+1]))) then begin
            if (idebs[ib] gt ifins_el[ie]) then begin
               ifin=max(ifins_el[where(ifins_el lt idebs[ib])],ie)
               ;; cas normal
               is_length_el[i] = idebs[ib] - ifins_el[ie] + 1 
               ib+=1
               ie+=1
            endif else if (idebs[ib] gt ifins_el[ie+1]) then begin
               ;; on rate un debut
               ifin=max(ifins_el[where(ifins_el lt idebs[ib])],ie)
               is_length_el[i] = idebs[ib] - ifins_el[ie] + 1 
               ib+=1
               ie+=1
            endif else begin
               ;; on rate une fin : on passe
               ib+=1
            endelse
         endfor 
      endif else begin
         ib+=1
         ie+=1
      endelse
      if (ib le ndebs-1) and (ie le nfins_el-1) then is_length_el = [is_length_el[0:nss_vu_el-1],idebs[ib] - ifins_el[ie] + 1] 
     

      ;stop
      
      
      ;;
      ;;      estimated averaged quantities
      ;; 
      ;;____________________________________________________________________________________________________________

      
      avg_ssl_az = median(ss_length_az)
      n_ssl_az = n_elements(ss_length_az)
      if (n_ssl_az ge 3) then avg_ssl_az = median(ss_length_az[1:n_ssl_az-2])
      w_tokeep=where((ss_length_az lt 1.1*avg_ssl_az) and (ss_length_az gt 0.9*avg_ssl_az) ,n_tokeep)
      if n_tokeep gt 0 then avg_ssl_az = mean(ss_length_az[w_tokeep])

      
      avg_isl_az = median(is_length_az)
      w_tokeep = where((is_length_az lt 1.8*avg_isl_az) and (ss_length_az gt 0.2*avg_isl_az) ,n_tokeep)
      avg_isl_az = mean(is_length_az[w_tokeep])
      
            
      avg_ssl_el = median(ss_length_el)
      n_ssl_el = n_elements(ss_length_el)
      if (n_ssl_el ge 3) then avg_ssl_el = median(ss_length_el[1:n_ssl_el-2])
      w_tokeep=where((ss_length_el lt 1.1*avg_ssl_el) and (ss_length_el gt 0.9*avg_ssl_el) ,n_tokeep)
      if n_tokeep gt 0 then avg_ssl_el = mean(ss_length_el[w_tokeep])
      
      
      avg_isl_el = median(is_length_el)
      w_tokeep = where((is_length_el lt 1.8*avg_isl_el) and (ss_length_el gt 0.2*avg_isl_el) ,n_tokeep)
      avg_isl_el = mean(is_length_el[w_tokeep])
      
      
      ;; averaged amplitude
      ampli_az = shift(a_az,-1)-a_az
      avg_a_az = median(abs(ampli_az)) 
      n_amp = n_elements(ampli_az)
      if (n_amp ge 3) then avg_a_az = median(abs(ampli_az[1:n_amp-2])) 
      w_tokeep = where((abs(ampli_az) lt 1.1*avg_a_az) and (abs(ampli_az) gt 0.9*avg_a_az) ,n_tokeep)

      if n_tokeep gt 0 then ampli0_az = ampli_az[0]/abs(ampli_az[0])*mean(abs(ampli_az[w_tokeep])) else ampli0_az = ampli_az[0]/abs(ampli_az[0])*avg_a_az
      
      
      ampli0_el = a_el[0]
       
       ;; averaged delta elevation amplitude
      delta_el = shift(a_el,-1)-a_el
      avg_d_el = median(delta_el)
      n_marche = n_elements(delta_el)
      if (n_marche ge 3) then avg_d_el = median(delta_el[1:n_marche-2])
      w_tokeep = where((delta_el lt 1.1*avg_d_el) and (delta_el gt 0.9*avg_d_el) ,n_tokeep)
      if n_tokeep gt 0 then avg_d_el = mean(delta_el[w_tokeep]) 
      


      ;;
      ;;     homogeneising the subscan param tables
      ;; 
      ;;____________________________________________________________________________________________________________
      ;; if the first subscan beginning is missing: the first subscan
      ;; begins at the scan beginning 
      idebs_az = idebs
      idebs_el = idebs
      if idebs_az[0] gt ifins_az[0] then begin
         idebs_az = [0,idebs_az]  
         phase_az = floor(avg_ssl_az) - (ifins_az[0]+1)
      endif else begin 
         ;; else the first is-interval is discarded
         if (n_elements(is_length_az) gt 1) then is_length_az = is_length_az[1:*] else is_length_az = 0
         phase_az = 0
      endelse 
      if idebs_el[0] gt ifins_el[0] then begin
         idebs_el = [0,idebs_el]  
         phase_el = floor(avg_ssl_el) - (ifins_el[0]+1)
      endif else begin 
         ;; else the first is-interval is discarded
         if (n_elements(is_length_el) gt 1) then is_length_el = is_length_el[1:*] else is_length_el = 0
         ;;phase = idebs[0]
         phase_el = 0
      endelse      
      ;; if the last subscan end index is missing: the last subscan
      ;; ends at the scan end
      if (n_elements(idebs_az) gt n_elements(ifins_az)) then begin
         ifins_az = [ifins_az,nsp-1] 
         ifins_az_flag = [ifins_az_flag,1] 
      endif
      if (n_elements(idebs_el) gt n_elements(ifins_el)) then ifins_el = [ifins_el,nsp-1] 

      ;; just in case, should not happen
      if (n_elements(idebs_az) gt n_elements(idebs_az_flag)) then idebs_az_flag = [idebs_az_flag,1] 
      if (n_elements(idebs_el) gt n_elements(idebs_el_flag)) then idebs_el_flag = [idebs_el_flag,1] 


      nss_ok_az = n_elements(ss_length_az)
      ;; if the last IS interval is missing, set to zero
      if n_elements(is_length_az) eq nss_ok_az-1 then is_length_az=[is_length_az,0]
      nss_ok_el = n_elements(ss_length_el)
      if n_elements(is_length_el) eq nss_ok_el-1 then is_length_el=[is_length_el,0]
      
      
      if n_elements(is_length_az) ne n_elements(ss_length_az) then if bava gt 0 then print,code, "az: inter-subscan and subscan numbers are different ! "
      if n_elements(is_length_el) ne n_elements(ss_length_el) then if bava gt 0 then print,code, "el: inter-subscan and subscan numbers are different ! "
      
      
      
      ;;
      ;;    filling in param structures (outputs)
      ;; 
      ;;____________________________________________________________________________________________________________
      x_info = {avg_ssl_ok:0., avg_isl_ok:0., phase:0L, amplitude:0.}
      y_info = {avg_ssl_ok:0., avg_isl_ok:0., phase:0L, amplitude:0., delta:0.}
      
      
      x_info.avg_ssl_ok = avg_ssl_az
      y_info.avg_ssl_ok = avg_ssl_el
      x_info.avg_isl_ok = avg_isl_az
      y_info.avg_isl_ok = avg_isl_el
      
      x_info.phase = phase_az
      y_info.phase = phase_el
      
      x_info.amplitude = ampli0_az
      y_info.amplitude = ampli0_el
      y_info.delta = avg_d_el

      xallinfo=0
      if keyword_set(x_all) then begin
      xallinfo = replicate({ss_length:0., is_length:0., beg_index:0L, end_index:0L, beg_index_flag:0, end_index_flag:0, amplitude:0.},nss_ok_az)
         xallinfo.ss_length = ss_length_az
         xallinfo.is_length = is_length_az[0:nss_ok_az-1]
         xallinfo.beg_index = idebs_az>0
         xallinfo.end_index = ifins_az
         xallinfo.beg_index_flag = idebs_az_flag[0:nss_ok_az-1]
         xallinfo.end_index_flag = ifins_az_flag[0:nss_ok_az-1]
         xallinfo.amplitude = a_az[0:nss_ok_az-1]
      endif
      x_allinfo = xallinfo
      
      yallinfo=0
      if keyword_set(y_all) then begin
         yallinfo = replicate({ss_length:0., is_length:0., beg_index:0L, end_index:0L, beg_index_flag:0, amplitude:0.},nss_ok_el)
         yallinfo.ss_length = ss_length_el
         yallinfo.is_length = is_length_el[0:nss_ok_el-1]
         yallinfo.beg_index = idebs_el>0
         yallinfo.end_index = ifins_el
         yallinfo.amplitude = a_el[0:nss_ok_el-1]
         yallinfo.beg_index_flag = idebs_el_flag
      endif
      y_allinfo=yallinfo
      



      ;;stop
      



   endif else begin
      ;; ndebs = 0 
      ;; too short a sample bunch
      if bava gt 0 then print,code, "not enought good samples"
      xallinfo=0
      if keyword_set(x_all) then begin
         xallinfo = {ss_length:0., is_length:0., beg_index:0L, end_index:0L, beg_index_flag:0, end_index_flag:0, amplitude:0.}
         xallinfo.ss_length      = -1
         xallinfo.is_length      = -1
         xallinfo.beg_index      = -1 
         xallinfo.beg_index_flag = -1
         xallinfo.end_index      = -1
         xallinfo.end_index_flag = -1
         xallinfo.amplitude      = -1
      endif
      x_allinfo=xallinfo
      yallinfo=0
      if keyword_set(y_all) then begin
         yallinfo = {ss_length:0., is_length:0., beg_index:0L, end_index:0L, beg_index_flag:0, amplitude:0.}
         yallinfo.ss_length      = -1
         yallinfo.is_length      = -1
         yallinfo.beg_index      = -1
         yallinfo.end_index      = -1 
         yallinfo.beg_index_flag = -1
         yallinfo.amplitude      = -1
      endif
      y_allinfo=yallinfo

      y_info = {avg_ssl_ok:0., avg_isl_ok:0., phase:0L, amplitude:0.,delta:0.}
      y_info.avg_ssl_ok =-1
      y_info.avg_isl_ok =-1
      y_info.phase      =-1
      y_info.amplitude  =-1
      y_info.delta      =-1
      x_info = {avg_ssl_ok:0., avg_isl_ok:0., phase:0L, amplitude:0.}
      x_info.avg_ssl_ok =-1
      x_info.avg_isl_ok =-1
      x_info.phase      =-1
      x_info.amplitude  =-1
      
   endelse
   
endif else begin
   ;; pathological cases
   if bava gt 0 then print, code, "pathological cases"
   
   y_info = {avg_ssl_ok:0., avg_isl_ok:0., phase:0L, amplitude:0.,delta:0.}
   y_info.avg_ssl_ok=-1
   y_info.avg_isl_ok=-1
   y_info.phase=-1
   y_info.amplitude=-1
   y_info.delta=-1
   x_info = {avg_ssl_ok:0., avg_isl_ok:0., phase:0L, amplitude:0.}
   x_info.avg_ssl_ok=-1
   x_info.avg_isl_ok=-1
   x_info.phase=-1
   x_info.amplitude=-1
   
endelse


end
