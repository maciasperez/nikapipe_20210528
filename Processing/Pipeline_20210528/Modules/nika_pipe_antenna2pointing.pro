pro nika_pipe_antenna2pointing, dat, file, originalversion=originalversion, outflag=outflag, nodecroche=nodecroche
; Replaces the dat pointing info (Az, El) with what is in the antenna imbfits
; file
;
; outflag = 0 ----> original nika pointing
; outflag = 1 ----> interpolated pointing from the ELVIN's antenna imbfits   
;



; Read the file
; Loop on the extensions
iext = 0
nmax = 60000L ; max sample length of a scan
longoff   = dblarr( nmax)
scan      = dblarr( nmax)
subscan   = dblarr( nmax)
elevation = dblarr( nmax)
latoff    = longoff
mjdarr    = longoff
ndeb = 0
nend = 0
ss_val = 1
repeat begin
   readin = mrdfits(file, iext, hdr, status=status, /silent)
   extna = sxpar( hdr, 'EXTNAME')
   if strtrim( strupcase(extna), 2) eq strupcase('IMBF-ANTENNA') then begin
      nread = n_elements( readin)
      nend  = ndeb+nread-1
      longoff[   ndeb:nend] = readin.longoff
      latoff[    ndeb:nend] = readin.latoff
      mjdarr[    ndeb:nend] = readin.mjd
      scan[      ndeb:nend] = sxpar( hdr, 'SCANNUM')
      subscan[   ndeb:nend] = ss_val
      elevation[ ndeb:nend] = readin.celevatio
      ndeb = nend+1
      ss_val +=  1
   endif
   iext = iext + 1
endrep until status lt 0

if (nend gt 0) then begin 

   longoff   = longoff[0:nend]*!radeg*3600
   latoff    = latoff[ 0:nend]*!radeg*3600
   scan      = scan[0:nend]
   subscan   = subscan[0:nend]
   elevation = elevation[0:nend]
   mjdarr = (mjdarr[0:nend]-long(mjdarr[0]))*86400D0 ; modify to have seconds

;; In case some files are merged, if we do not truncate here, the
;; "other" scan without its imbfits will have crazy pointing (0,0 ?)
;; => truncate here
   tmax = mjdarr[nend-1]
   w    = where( dat.a_t_utc le tmax)
   dat  = dat[w]
   


;; initialising the flag
nika_bilan = dat.mjd*0L


   if keyword_set(originalversion) then begin
; Interpolate into the data toi                                                                                                 
      
      dat.ofs_az  =       interpol(longoff,   mjdarr, dat.a_t_utc)
      dat.ofs_el  =       interpol(latoff,    mjdarr, dat.a_t_utc)
      dat.el      =       interpol(elevation, mjdarr, dat.a_t_utc)
      dat.subscan = long( interpol(subscan,   mjdarr, dat.a_t_utc))       
      dat.scan    = long( interpol(scan,      mjdarr, dat.a_t_utc)) 
      nika_bilan = dat.mjd*0L +1L
      
   endif else begin
      
;; LP SECONDE VERSION FROM NOW ON
;;-------------------------------------------------------------
      
; NIKA raw data MJD 
; (contrairement a dat.a_t_utc qui est defini partout, 
; nika_mjd repere les echantillons manquants) 
      nika_wok=where(dat.mjd gt 0,nok,compl=nika_wnok,ncompl=nwnok)
      ;nika_mjd = ((dat[nika_wok].mjd) - long((dat[0].mjd)))*86400D0
      
      nika_flag = dat.mjd*0L
      if nwnok ne 0 then nika_flag(nika_wnok)=1
      
      ; on agrandit un peu la zone flagguee autour des endroits a pb
      nika_flat = deriv(nika_flag)
      nsn = n_elements(nika_flat)
      nika_flat[0:10] = 0 ; zone tampon au debut
      nika_flat[nsn-11:nsn-1] = 0 ; zone tampon a la fin
      nika_flag[0:10] = 0         ; zone tampon au debut
      nika_flag[nsn-11:nsn-1] = 0 ; zone tampon a la fin
      nika_wevents = where(abs(nika_flat) gt 0.1, nevents)
      if (nevents gt 0) then begin
         for ievents = 0, nevents-1 do begin
            ;; passage ok(=0) -> not ok(=1) : on enleve 100 samples
            ;; AVANT le pb
            if (nika_flat[nika_wevents[ievents]] gt 0.) then nika_flag[nika_wevents[ievents]-100:nika_wevents[ievents]] = 1
            ;; passage nok(=1) -> ok(=0) : on enleve 100 samples
            ;; APRES le pb
            if (nika_flat[nika_wevents[ievents]] lt 0.) then nika_flag[(nika_wevents[ievents]):(nika_wevents[ievents]+100)] = 1
         endfor
      endif

            
      nika_nsn = n_elements(dat.mjd)
      index = lindgen(nika_nsn)
      

      ;; restoration uniquement si données manquantes : 
      if (total(nika_flag) gt 0) then begin 
         

;; on commence par recuperer le pointage dans l'antenna
;; imbfits, la ou il est ok
;;;-------------------------------------------------------
         
; flagging missing antenna data
         ;; using MJD derivative to catch missing samples
         ;; acq rate 8 samples/s : 1 sample -> 0.125 s  
         ;; positive variation = mising sample
         ;; negative variation = getting back in time at subscan's changing
         nsn = n_elements(mjdarr)
         flat = deriv(mjdarr)
         check_var = deriv(subscan) ; variations dues aux changements de subscan
         wpreevents = where(flat gt 0.13,nevents,compl=wsmooth) 
         wsubscan=where((abs(check_var[wsmooth]) gt 1d-3),co )
         if (co gt 0) then flat[wsubscan] = 0.125
        
         wevents = where(flat gt 0.13,nevents,compl=wsmooth) 
         
         variations = deriv(flat)
         
         ;;w=where((abs(check_var[wsmooth]) gt 1d-3),co )
         ;;ibe=0
         ;;if (w[ibe] eq 0) then begin
         ;;   variations[wsmooth[w[ibe]]:wsmooth[w[ibe]]+1] = 0.
         ;;   ibe=1
         ;;endif
         ;;ien = co-1
         ;;if (w[ien] eq nsn-1) then begin
         ;;    variations[wsmooth[w[ien]]-1:wsmooth[w[ien]]] = 0.
         ;;    ien=co-2
         ;;endif
         ;;for i = ibe,ien do  variations[wsmooth[w[i]]-1:wsmooth[w[i]]+1] = 0.
         


         ;; if no missing data are found in the Antenna imbfits:  single block interpolation  
         ;;____________________________________________________________________________________

         if (nevents eq 0) then begin
            print,"Antenna IMBfits ok for all samples ---> single block interpolation"
            ibeg = 0
            iend = n_elements(mjdarr)-1
            
            nika_w = where(dat.a_t_utc le mjdarr[ibeg],co)
            if (co gt 0) then nika_beg = nika_w(co-1) else print,"a_t_utc: late start...."
            nika_w = where(dat.a_t_utc ge mjdarr[iend],co)
            if (co gt 0) then nika_end = nika_w(0) else nika_end = n_elements(dat.a_t_utc)-1
            
            ofs_az  =  interpol(longoff[ibeg:iend],   mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc))
            ofs_el  =  interpol(latoff[ibeg:iend],    mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc))
            el      =  interpol(elevation[ibeg:iend], mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc))
            subsc = long( interpol(subscan[ibeg:iend],   mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc)))
            ssc = long( interpol(scan[ibeg:iend],   mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc)))


            ;titre = file_basename(file)
            ;ss = str_sep(titre,'.fits')
            ;titre = ss[0]
            ;window,6
            ;saveplot,!nika.save_dir+"/Laurence/OTFMAP_pointing_"+titre+"_az"
            ;plot,dat[nika_beg:nika_end].a_t_utc,dat[nika_beg:nika_end].ofs_az,/xs,ytitle="az",xtitle="t_UTC",title=titre,col=0
            ;oplot,mjdarr,longoff, col=250
            ;oplot,mjdarr,longoff*cos(elevation), col=80,linestyle=2
            ;legendastro,['NIKA pointing','Antenna pointing','0.75 x Antenna pointing'],col=[0,250,80],textcolor=[0,250,80], box=0
            
            ;window,7
            ;saveplot,!nika.save_dir+"/Laurence/OTFMAP_pointing_"+titre+"_el"
            ;plot,dat[nika_beg:nika_end].a_t_utc,dat[nika_beg:nika_end].ofs_el,/xs,ytitle="el",xtitle="t_UTC",title=titre,col=0
            ;oplot,mjdarr,latoff, col=250
            ;legendastro,['NIKA pointing','Antenna pointing'],col=[0,250],textcolor=[0,250], box=0

           
            ;; interpolation of the nika data only where data are missing
            ind = index[nika_beg:nika_end]
            nint = n_elements(ind)
            wmiss=where(nika_flag[ind] gt 0,nmiss, compl=wok)
            if (nmiss gt 0) then begin

               if keyword_set(nodecroche) then begin
                  
                  ;; on regarde l'adequation antenna et nika dans
                  ;; les zones tampons (flagguée mais ok)
                  w = where((dat[ind[wmiss]].mjd gt 0),nrecouv)                 
                  delta_az = abs(dat[ind[wmiss[w]]].ofs_az - ofs_az[wmiss[w]])
                  delta_el = abs(dat[ind[wmiss[w]]].ofs_el - ofs_el[wmiss[w]])

                  ;; si c'est > 2. arcsec, on elargit les
                  ;; zones tampon avant et apres les donnees
                  ;; manquantes 
                  if (w[0] eq 0) then begin
                     ;; presence d'une zone tampon avant les donnees manquantes
                     tostop=0
                     while(((delta_az[0] gt 2.) or (delta_el[0] gt 2.) or (delta_az[4] gt 2.) or (delta_el[4] gt 2.)) and (tostop lt 1)) do begin
                        iadd = max([0,wmiss[w[0]]-1])
                        if (iadd eq 0) then tostop=1
                        wmiss = [iadd,wmiss]
                        w = where((dat[ind[wmiss]].mjd gt 0),nrecouv)                 
                        delta_az = abs(dat[ind[wmiss[w]]].ofs_az - ofs_az[wmiss[w]])
                        delta_el = abs(dat[ind[wmiss[w]]].ofs_el - ofs_el[wmiss[w]])
                     endwhile
                  endif
                  if (w[nrecouv-1] eq nmiss-1) then begin
                     ;; presence d'une zone tampon apres les donnees manquantes
                     tostop=0
                     while(((delta_az[nrecouv-1] gt 2) or (delta_el[nrecouv-1] gt 2) or (delta_az[nrecouv-5] gt 2.) or (delta_el[nrecouv-5] gt 2.)) and (tostop lt 1)) do begin
                        iadd = min([nint-1,wmiss[w[nrecouv-1]]+1])
                        if (iadd eq nint-1) then tostop=1
                        wmiss = [wmiss,iadd]
                        print,"on ajoute ",ind[iadd]
                        w = where((dat[ind[wmiss]].mjd gt 0),nrecouv)                 
                        delta_az = abs(dat[ind[wmiss[w]]].ofs_az - ofs_az[wmiss[w]])
                        delta_el = abs(dat[ind[wmiss[w]]].ofs_el - ofs_el[wmiss[w]])
                     endwhile
                  endif

                  wrecouv = wmiss[w]
                  ii = indgen(nika_end-nika_beg+1)
                  window,2
                  plot,ii,dat[ind].ofs_az,col=0,xrange=[ii[wrecouv[0]],ii[wrecouv[nrecouv-1]]], ytitle="ofs_az", title= "antenna2pointing: mitigating discontinuities"
                  oplot,ii,ofs_az,col=250
                  oplot,ii[wrecouv],ofs_az[wrecouv],col=150,psym=2
                  oplot,ii[wrecouv],delta_az,col=50,psym=2
                  legendastro,['nika pointing','antenna imbfits pointing','"safety" zone around hole', 'nika-to-antenna discrepancy'],col=[0,250,150,50],textcolor=[0,250,150,50]
                  window,3
                  plot,ii,dat[ind].ofs_el,col=0,xrange=[ii[wrecouv[0]],ii[wrecouv[nrecouv-1]]],ytitle="ofs_el", title= "antenna2pointing: mitigating discontinuities"
                  oplot,ii,ofs_el,col=250
                  oplot,ii[wrecouv],ofs_el[wrecouv],col=150,psym=2
                  oplot,ii[wrecouv],delta_el,col=50,psym=2
               endif

               
               dat[ind[wmiss]].ofs_az = ofs_az[wmiss]
               dat[ind[wmiss]].ofs_el = ofs_el[wmiss]
               dat[ind[wmiss]].el = el[wmiss]
               dat[ind[wmiss]].subscan = subsc[wmiss]
               dat[ind[wmiss]].scan = ssc[wmiss]
               nika_bilan[ind[wmiss]] = 1
               

            endif
            


         endif else begin
            ;; interpolation by bunch (of good samples) in case of "glitches" in the Antenna IMBfits   
            ;;_______________________________________________________________________________________
            print,"Antenna IMBfits has bad samples ---> interpolation by bunch"
            
            ibunch = 0    ; not used
            ievent = 0   ; index of the current event being avoided
            ibeg = 0      ; begin index
            tostop=0      ; to stop the loop
            repeat begin
               
               ;; IMBFITS indices
               ;; nouvelle fin : le premier echantillon avec une
               ;; variation positive (la derivée augmente = des echantillons ont sautes)
               ;;w_end = where(variations(wevents(ievent:*)) gt 0.01,co)
               w_end = where(variations(wevents(ievent:*)) gt 0.01,co)
               if (co gt 0) then iend = wevents(ievent+w_end(0)) else begin
                  ;; dernier bunch !
                  iend=n_elements(longoff)-1
                  tostop = 1
               endelse
                          
               nbunch = iend-ibeg+1
               
               print,"antenna index_b = ",ibeg
               print,"antenna index_e = ",iend
               print,"antenna time_b = ", mjdarr[ibeg]
               print,"antenna time_e = ", mjdarr[iend]
               

               ;; NIKA indices
               ;;if (ievent gt 0) then begin
               nika_w = where((dat.a_t_utc ge 0.) and (dat.a_t_utc le mjdarr[ibeg]),co)
               if (co gt 0) then nika_beg = nika_w(co-1)
               nika_w = where((dat.a_t_utc ge mjdarr[iend]) or (dat.a_t_utc eq max(dat.a_t_utc)),co)
               if (co gt 0) then nika_end = nika_w(0) else nika_end = n_elements(dat.a_t_utc)-1
               
               ;;endif else begin
               ;;   nika_w = where(nika_mjd le mjdarr[ibeg],co)
               ;;   if (co gt 0) then nika_beg = nika_wok(nika_w(co-1))
               ;;   print,"mjdarr(ibeg) = ",mjdarr[ibeg]
               ;;   nika_w = where(nika_mjd ge mjdarr[iend],co)
               ;;   print,"mjdarr(iend) = ",mjdarr[iend]
               ;;   if (co gt 0) then nika_end = nika_wok(nika_w(0))
               ;;endelse
               ;;nika_end = nika_beg+nbunch-1
               
               print,"nika index_b = ",nika_beg
               print,"nika index_e = ",nika_end
               print,"nika time_b = ", dat[nika_beg].a_t_utc
               print,"nika time_e = ",dat[nika_end].a_t_utc
               
               
               ; re-init
               ofs_az = dblarr(nika_end-nika_beg+1)
               ofs_el = dblarr(nika_end-nika_beg+1)
               el = dblarr(nika_end-nika_beg+1)
               subsc = lonarr(nika_end-nika_beg+1)

               ofs_az   =       interpol(longoff[ibeg:iend],   mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc))
               ofs_el   =       interpol(latoff[ibeg:iend],    mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc))
               el       =       interpol(elevation[ibeg:iend], mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc))
               subsc  = long( interpol(subscan[ibeg:iend],   mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc)))
               ssc  = long( interpol(scan[ibeg:iend],   mjdarr[ibeg:iend], (dat[nika_beg:nika_end].a_t_utc)))
              
               ;ind = index[nika_beg:nika_end]
               ;plot,dat[ind].a_t_utc,dat[ind].ofs_az
                                ;oplot,mjdarr[ibeg:iend],longoff[ibeg:iend],
                                ;col=250, psym=1
               
               ;; interpolation of the nika data only where data are missing
               ind = index[nika_beg:nika_end]
               nint = n_elements(ind)
               wmiss=where(nika_flag[ind] gt 0,nmiss, compl=wok)
               if (nmiss gt 0) then begin

                  if keyword_set(nodecroche) then begin
                     ;; on regarde l'adequation antenna et nika dans
                  ;; les zones tampons (flagguée mais ok)
                  w = where((dat[ind[wmiss]].mjd gt 0),nrecouv)                 
                  delta_az = abs(dat[ind[wmiss[w]]].ofs_az - ofs_az[wmiss[w]])
                  delta_el = abs(dat[ind[wmiss[w]]].ofs_el - ofs_el[wmiss[w]])

                  ;; si c'est > 2. arcsec, on elargit les
                  ;; zones tampon avant et apres les donnees
                  ;; manquantes 
                  if (w[0] eq 0) then begin
                     ;; presence d'une zone tampon avant les donnees manquantes
                     tostop1=0
                     while(((delta_az[0] gt 2.) or (delta_el[0] gt 2.) or (delta_az[4] gt 2.) or (delta_el[4] gt 2.)) and (tostop1 lt 1)) do begin
                        iadd = max([0,wmiss[w[0]]-1])
                        if (iadd eq 0) then tostop1=1
                        wmiss = [iadd,wmiss]
                        print,"on ajoute ",ind[iadd]
                        w = where((dat[ind[wmiss]].mjd gt 0),nrecouv)                 
                        delta_az = abs(dat[ind[wmiss[w]]].ofs_az - ofs_az[wmiss[w]])
                        delta_el = abs(dat[ind[wmiss[w]]].ofs_el - ofs_el[wmiss[w]])
                     endwhile
                  endif
                  if (w[nrecouv-1] eq nmiss-1) then begin
                     ;; presence d'une zone tampon apres les donnees manquantes
                     tostop2=0
                     while(((delta_az[nrecouv-1] gt 2.) or (delta_el[nrecouv-1] gt 2.) or (delta_az[nrecouv-5] gt 2.) or (delta_el[nrecouv-5] gt 2.)) and (tostop2 lt 1)) do begin
                        iadd = min([nint-1,wmiss[w[nrecouv-1]]+1])
                        if (iadd eq nint-1) then tostop2=1
                        wmiss = [wmiss,iadd]
                        print,"on ajoute ",ind[iadd]
                        w = where((dat[ind[wmiss]].mjd gt 0),nrecouv)                 
                        delta_az = abs(dat[ind[wmiss[w]]].ofs_az - ofs_az[wmiss[w]])
                        delta_el = abs(dat[ind[wmiss[w]]].ofs_el - ofs_el[wmiss[w]])
                        print,tostop2
                     endwhile
                  endif
                 
                  wrecouv = wmiss[w]
                  ii = indgen(nika_end-nika_beg+1)
                  window,2
                  plot,ii,dat[ind].ofs_az,col=0,xrange=[ii[wrecouv[0]],ii[wrecouv[nrecouv-1]]], ytitle="ofs_az", title= "antenna2pointing: mitigating discontinuities"
                  oplot,ii,ofs_az,col=250
                  oplot,ii[wrecouv],ofs_az[wrecouv],col=150,psym=2
                  oplot,ii[wrecouv],delta_az,col=50,psym=2
                  legendastro,['nika data','antenna data','antenna data zone tampon','diff'],col=[0,250,150,50], textcolor=[0,250,150,50]
                  window,3
                  plot,ii,dat[ind].ofs_el,col=0,xrange=[ii[wrecouv[0]],ii[wrecouv[nrecouv-1]]], ytitle="ofs_el", title= "antenna2pointing: mitigating discontinuities"
                  oplot,ii,ofs_el,col=250
                  oplot,ii[wrecouv],ofs_el[wrecouv],col=150,psym=2
                  oplot,ii[wrecouv],delta_el,col=50,psym=2

                  endif


                  dat[ind[wmiss]].ofs_az = ofs_az[wmiss]
                  dat[ind[wmiss]].ofs_el = ofs_el[wmiss]
                  dat[ind[wmiss]].el = el[wmiss]
                  dat[ind[wmiss]].subscan = subsc[wmiss]
                  dat[ind[wmiss]].scan = ssc[wmiss]
                  nika_bilan[ind[wmiss]] = 1
               endif
               if tostop le 0 then begin
                  ;; nouveau debut : le premier echantillon apres ibunch avec une
                  ;; variations negative (la derivee re-diminue) 
                  w_beg = where(variations(wevents(ievent+1:*)) le -0.01,co)
                  if (co gt 0) then ibeg = wevents(ievent+1+w_beg(0))
                  ibunch+=1
                  ievent = ievent+1+w_beg(0)
                  print,"ievent = ",ievent
               endif
               
              
;endrep until ievent ge nevents
            endrep until tostop gt 0

         endelse
         
;;; inpainting par fit des donnees non-reconstruites dans l'antenna-imbfits
;;;--------------------------------------------------------------------------
;nika_wnok_fin = where(nika_flag gt 0), ntofit)
;if (ntofit ne 0) then begin
;   nika_pipe_addflag, dat, 9, wsample=nika_wnok_fin
;   
;endif 
         
         outflag = nika_bilan

         print,"TOTAL NUMBER OF INTERPOLATED SAMPLES = ",total(nika_bilan)

      endif else begin
         print, "no missing nika data: no recovery needed..."
         ;; test du subscan pour les OTF
         scan_valid = dat.scan_valid
         w_valid = where((scan_valid[0,*] eq 0) and (scan_valid[1,*] eq 0), n_valid)
         if max(dat[w_valid].subscan) gt 1 then begin 
            wstart = where(dat.scan_st eq 4,co4)
            wend = where(dat.scan_st eq 5,co5)
            subscan_length = wend-wstart
            mlength = mean(subscan_length)
            wpb = where(subscan_length lt mlength*0.75 or subscan_length gt mlength*1.25,npb)
            if (npb gt 0) then dat.subscan = long( interpol(subscan,   mjdarr, dat.a_t_utc))
         endif
      endelse
   endelse
   
endif else print,"corrupted IMBFits file...."



; Final computation of correct parallactic angle
; Must be checked on a map but compatible with raw data values within 1/2 deg.
dat.paral = parallactic_angle( dat.az, dat.el)

return
end
