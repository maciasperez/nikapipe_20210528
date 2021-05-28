pro otf_pointing_flag_subscan, az, el , flag_intersubscan, beg_index, end_az_index, end_el_index, model=model, scantype=scantype

;; routine inspiree de nika_pipe_speedflag
;; az et el doivent etre sans trou
;; flag_intersubscan = 0 : on subscan
;; flag_intersubscan = 1 : entre 2 subscans (critere "speedflag")
;; flag_intersubscan = 3 : zone a ajouter pour l'elevation
;; flag_intersubscan = 2 : zone a enlever pour l'azimuth 

;; if /otf_diagonal, skiping all that rely on the specific shape
;; (triangle or steps) of az, el  


  ;; testing the scan type
  ;;==============================================================
  ;; default scan type = OTF_AZIMUTH
  scant = 'otf_azimuth'
  if keyword_set(scantype) then scant = scantype

  if (strupcase(scant) eq 'OTF_ELEVATION') then begin
     temp = az
     az=el
     el=temp
     scant = 'otf_azimuth'
  endif

  ;; flag from scan speed
  ;;==============================================================
  nsn = n_elements(az)
  var_el = deriv(el)
  var_az = deriv(az)
  
  v = sqrt( var_el^2 + var_az^2)*!nika.f_sampling
  med  =  median( v)
  w_speedflag    =  where(abs(v) gt 1.5*med or abs(v) lt 0.5*med,  nflag,  comp = cflag)

  flag_intersubscan = intarr(nsn)
  flag_intersubscan[w_speedflag] = 1

  ;;index = lindgen(nsn)
  ;;plot,index, az,col=0, yr=[-210,210]
  ;;oplot,index[w_speedflag],az[w_speedflag],col=250,psym=2

  
  ;; enlarge elevation interval (to include the turn-up)
  ;;==============================================================
  ;; on doit elargir un peu l'intervalle pour l'elevation (pour couper
  ;; la remontée)
  if (not(keyword_set(model)) and strupcase(scant) eq 'OTF_AZIMUTH') then begin
     ;; may be more precise if the lower threshold is decreased a bit (0.1 -> 0.02)
     w_change = where((abs(var_el) gt 0.1) and ((shift(abs(var_el),1) lt 1e-3) xor (shift(abs(var_el),2) lt 1e-3)), nstep)
     
     for i=0, nstep-1 do begin
        recup = w_change[i]
        while (flag_intersubscan[recup] eq 0) do begin     
           flag_intersubscan[recup]=3
        recup +=1
        IF (recup eq nsn-1) THEN BREAK
     endwhile
        
     endfor
  endif
  
  ;;stop
  
  ;;w3 = where(flag_intersubscan gt 2, n3)
  ;;oplot,index[w3],az[w3],col=150,psym=2


  ;; on gomme les trous dans l'intersubscan (arrivent si une
  ;; des coordonnees est stabilisee avant l'autre)  
  ;;==============================================================
  if (strupcase(scant) eq 'OTF_AZIMUTH') then begin
     w_change = where((abs(var_az) lt 0.01) and ((shift(abs(var_az),1) gt 0.1) xor (shift(abs(var_az),2) gt 0.1)), nstep) ; debut de l'inter-subscan (decale de 1 sample)
     for i=0, nstep-1 do begin
        recup = w_change[i]
        count=0
        repeat begin
           if (flag_intersubscan[recup] eq 0) then flag_intersubscan[recup]=1
           recup -=1
           count +=1
        endrep until (count ge 5 or recup le 0 or flag_intersubscan[recup] gt 1)
     endfor
  endif ;else begin
     ;; finding isolated zeros (max 5) 
     ;; ok but time demanding
     ;;iter=0
     ;;repeat begin 
     ;;   ts_flag = ts_smooth(flag_intersubscan,11) 
     ;;   w_islets = where((flag_intersubscan eq 0) and (ts_flag ge 6./11.) , n_islets)
     ;;   if (n_islets gt 0) then flag_intersubscan[w_islets] = 1
     ;;   iter+=1
     ;;endrep until (iter ge 4 or n_islets le 0)
     ;; 110*********1
     ff = flag_intersubscan
     for i=0,4 do begin
        w_islets = where(ff eq 0 and shift(ff,1) eq 1 and  shift(ff,2) eq 1 and shift(ff,-10) eq 1, n_islets)
        if (n_islets gt 0) then ff[w_islets] = 1
     endfor
     flag_intersubscan[10: nsn-10] = ff[10: nsn-10]
     for i=0,4 do begin
        w_islets = where(ff eq 0 and shift(ff,1) eq 1 and  shift(ff,2) eq 1 and shift(ff,-5) eq 1, n_islets)
        if (n_islets gt 0) then ff[w_islets] = 1
     endfor
     flag_intersubscan[5: nsn-5] = ff[5: nsn-5]
  ;endelse
  

  ;;w1bis = where(flag_intersubscan eq 1, n1)
  ;;oplot,index[w1bis],az[w1bis],col=200,psym=2
  
  if (strupcase(scant) eq 'OTF_AZIMUTH') then begin
     ;; on doit diminuer un peu l'intervalle pour l'azimuth      
     for i=0, nstep-1 do begin
        if w_change[i] gt 2 then begin
           recup = w_change[i]-2 
           while (flag_intersubscan[recup] eq 1) do begin     
              flag_intersubscan[recup]=2
              recup -=1
              IF (recup le 0) THEN BREAK
           endwhile
        endif
     endfor
     
     ;;w2 = where(flag_intersubscan eq 2, n2)
     ;;oplot,index[w2],az[w2],col=50,psym=2
     
  endif

  ;;stop

  ;;plot,t,az,xr=[750,850],yr=[150,250],/xs
  ;;oplot,t,flag_intersubscan*10+200,col=250
  ;;oplot,t,el+300,col=150
  ;;oplot,t[w_change],az[w_change],col=50,psym=2
  
  ;; jumps due to holes should not be flagged
  ;;===================================================
  ;;for i=0,3 do begin
     ;;w_jump = where(flag_intersubscan eq 1 and shift(flag_intersubscan,1) eq 0, n_jump)
     ;; if the scan begins within an inter-subscan interval --> spurious
     ;; first jump to be discarded
     ;;if (n_jump gt 0 and w_jump[0] eq 0) then begin
     ;;   if n_jump gt 1 then w_jump=w_jump[1:*]
     ;;   n_jump-=1
     ;;endif
     ;;if (n_jump gt 0) then flag_intersubscan[w_jump] = 0
  ;;endfor
  ;; 0***100 
  ff = flag_intersubscan
  for i=0,3 do begin
     w_islets = where(ff eq 1 and shift(ff,-1) eq 0 and  shift(ff,-2) eq 0 and shift(ff,4) eq 0, n_islets)
     if (n_islets gt 0) then ff[w_islets] = 0
  endfor
  flag_intersubscan[4: nsn-4] = ff[4: nsn-4]

  ;; the same for at the beginning and at the end
  flag_intersubscan[0] = flag_intersubscan[1]
  flag_intersubscan[nsn-1] = flag_intersubscan[nsn-2]


  ;;plot,t,az,xr=[17000,18500],yr=[-210,210],/xs
  ;;oplot,t,flag_intersubscan*10,col=250
  

 
  ;; looking for "111000**0" pattern in the flag
  ;;------------------------------------------
  beg_index = where((flag_intersubscan eq 1) and (shift(flag_intersubscan,-1) eq 0) and (shift(flag_intersubscan,-2) eq 0) and (shift(flag_intersubscan,-3) eq 0) and (shift(flag_intersubscan,-6) eq 0) and (shift(flag_intersubscan,1) eq 1) and (shift(flag_intersubscan,2) eq 1),ndebs)
  
  if keyword_set(model) then begin
     beg_index = where((flag_intersubscan eq 1) and (shift(flag_intersubscan,-1) eq 0) and (shift(flag_intersubscan,-15) eq 0) and (shift(flag_intersubscan,-2) eq 0),ndebs)
  endif
  
  ;; prevent finishing with a begin index
  if beg_index[ndebs-1] eq nsn-1 then beg_index = beg_index[0:ndebs-2]

  ;; looking for "0**000(1+)(1+)(1+)" pattern in the flag
  ;;------------------------------------------
  end_el_index = where((flag_intersubscan ge 1) and (shift(flag_intersubscan,-1) ge 1) and (shift(flag_intersubscan,-2) ge 1) and (shift(flag_intersubscan,1) eq 0) and (shift(flag_intersubscan,2) eq 0) and (shift(flag_intersubscan,3) eq 0) and (shift(flag_intersubscan,6) eq 0),nfins_el)
  ;; prevent begining with a (spurious) end index
  if end_el_index[0] eq 0 then end_el_index = end_el_index[1:nfins_el-1]
  
  if (strupcase(scant) eq 'OTF_AZIMUTH') then begin
  ;;   end_el_index = where((flag_intersubscan gt 1) and (shift(flag_intersubscan,1) eq 0),nfins_el) 
     end_az_index = where((flag_intersubscan gt 1) and (shift(flag_intersubscan,-1) eq 1),nfins) 
  endif else begin
  ;;   end_el_index = where((flag_intersubscan ge 1) and (shift(flag_intersubscan,-1) ge 1) and (shift(flag_intersubscan,-2) ge 1) and (shift(flag_intersubscan,1) eq 0) and (shift(flag_intersubscan,2) eq 0) and (shift(flag_intersubscan,3) eq 0) and (shift(flag_intersubscan,6) eq 0),nfins_el)
     end_az_index = end_el_index
  endelse
  
  ;;stop


  
end 
