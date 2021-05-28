pro scanflag_stat, daylist, savelists=savelists, plotsaving=plotsaving,readfromfile=readfromfile, include_badscans=include_badscans, havealook=havealook
  
; daylist = ['20140219','20140220','20140221','20140222','20140223','20140224','20140225']
; readfromfile = !nika.save_dir+"/Project_winter2014/Badscan_Lists/flagstat_*.dat"   
; scanflag_stat, daylist, savelists=0, plotsaving=0,readfromfile=readfromfile, include_badscans=0, havealook=1


  ndays = n_elements(daylist)
  
  onyva = 1
  
  if keyword_set(readfromfile) then begin
     allfile_list = file_search(readfromfile)
     nf = n_elements(allfile_list)
     if (nf ge ndays) then begin
        file_list = strarr(ndays)
        for i=0, ndays-1 do file_list[i]=allfile_list[WHERE(STRMATCH(allfile_list, '*'+daylist[i]+'.dat') EQ 1)] 
     endif else begin
        print,"missing files: check the daylist or rerun w/o setting readfromfile..."
        onyva=0
     endelse
     
     if (onyva gt 0) then begin
        bigtab = lonarr(1)
        ;temp=ascii_template(file_list[0])
        ;save,temp,filename=!nika.save_dir+"/Project_winter2014/Badscan_Lists/flagstat_template.save"
        restore,filename=!nika.save_dir+"/Project_winter2014/Badscan_Lists/flagstat_template.save"
        for j=0, ndays-1 do begin
           ff = read_ascii(file_list[j],template=temp)
           scan_list = ff.(0)
           frac_bs = ff.(1)
           bigtab = [bigtab,frac_bs]

           
           if keyword_set(havealook) then begin
              wbad = where(frac_bs gt 50.,cobad)
              if (cobad gt 0) then begin
                 for jj = 0, cobad-1 do begin
                    scanname = scan_list[wbad(jj)]
                    print,"Le scan sans donnee manquante num "+scanname," a ",frac_bs[wbad(jj)],"% de samples flaggues..."
                    day = strmid(scanname,0,8)
                    scan_num = strmid(scanname,9)
                    nika_pipe_default_param, scan_num, day, param0
                    nika_pipe_getdata, param0, data0, kidpar
                    scanvalid = data0.scan_valid
                    plot,data0.scan,ytitle='scan num',xtitle='samples',col=0
                    oplot,scanvalid[0,*]*long(scan_num)/2.,col=250
                    oplot,scanvalid[1,*]*long(scan_num)/2.2,col=200
                    stop
                    ans=''
                    read,ans
                 endfor
              endif else print,"pas de scan avec plus de 50% des samples flaggues ce jour-ci :) "
           endif

        endfor
        bigtab=bigtab[1:*]
        nscans = n_elements(bigtab)

        hist_plot,bigtab,BINSIZE=1,min=0,max=100,col=0
        legendastro, ['Run8 scan number = '+strtrim(string(nscans),2)], col=[0], textcolor=[0], box=0,/right
        
        if keyword_set(plotsaving) then begin
           plotfile = !nika.save_dir+'/Laurence/plots/flagstat_'+strtrim(string(ndays),2)+'days'
           if keyword_set(include_badscans) then plotfile = !nika.save_dir+'/Laurence/plots/flagstat_includingbadscans_'+strtrim(string(ndays),2)+'days'
           saveplot,plotfile
           hist_plot,bigtab,BINSIZE=1,min=0,max=100
           legendastro, ['Run8 scan number = '+strtrim(string(nscans),2)], col=[0], textcolor=[0], box=0,/right
           end_saveplot
        endif

        
        hist = histogram(bigtab,binsize=1, min=0,max=100)
        nb = n_elements(hist)
        deplacement = findgen(nb) 
        cumul=dblarr(nb)
        for i = 0,nb-1 do cumul(i) = total(hist[0:i])/nscans 
        invcumul = dblarr(nb)
        for i = 0,nb-1 do invcumul(i) = (nscans-total(hist[0:i]))/nscans 

        plot,invcumul,col=0,ytitle='scan fraction',xtitle='fraction of discarded samples',/ylog,yr=[0.005,1],/ys,/xs
        oplot,(lonarr(nb)+1d)*0.1,col=80,linestyle=2
        oplot,(lonarr(nb)+1d)*0.05,col=80,linestyle=2
        oplot,(lonarr(nb)+1d)*0.03,col=80,linestyle=2
        oplot,(lonarr(nb)+1d)*0.01,col=80,linestyle=2
        xyouts,80, 0.11, strtrim('10%',2), col=80
        xyouts,80, 0.06, strtrim('5%',2), col=80
        xyouts,80, 0.04, strtrim('3%',2), col=80
        xyouts,80, 0.01, strtrim('1%',2), col=80

        if keyword_set(plotsaving) then begin
           plotfile = !nika.save_dir+'/Laurence/plots/flagstat_cumulative_'+strtrim(string(ndays),2)+'days'
           if keyword_set(include_badscans) then plotfile = !nika.save_dir+'/Laurence/plots/flagstat_cumulative_includingbadscans_'+strtrim(string(ndays),2)+'days'
           saveplot,plotfile
           plot,invcumul,col=0,ytitle='scan fraction',xtitle='fraction of discarded samples',/ylog,yr=[0.005,1],/ys,/xs
           oplot,(lonarr(nb)+1d)*0.1,col=80,linestyle=2
           oplot,(lonarr(nb)+1d)*0.05,col=80,linestyle=2
           oplot,(lonarr(nb)+1d)*0.03,col=80,linestyle=2
           oplot,(lonarr(nb)+1d)*0.01,col=80,linestyle=2
           xyouts,90, 0.11, strtrim('10%',2), col=80
           xyouts,90, 0.055, strtrim('5%',2), col=80
           xyouts,90, 0.032, strtrim('3%',2), col=80
           xyouts,90, 0.0105, strtrim('1%',2), col=80
           end_saveplot
        endif
        
     endif
     
     
  endif else begin
     
;; test per day
;;-------------------------------
     for iday = 0, ndays-1 do begin
        
        bigtab = lonarr(1)
        
        scanlist = ''
        day=daylist[iday]
        ;; read ascii file produced from check_all_scans 
        ;;------------------------------------------------
        file_list = FILE_SEARCH(!nika.save_dir+"/Laurence/", "scan_status_"+day+'_*.dat') 
                                ;temp = ascii_template(file_list[0])
                                ;SAVE, temp, FILENAME=!nika.save_dir+"/Laurence/badscans_template.save"
        RESTORE, !nika.save_dir+"/Laurence/badscans_template.save"
        nfiles = n_elements(file_list)
        
        ;; scans lissajous et scan OTF
        ;;------------------------------------------------
        for ifil = 0, nfiles-1 do begin
           scaninfo = read_ascii(file_list[ifil],template=temp)
           ;; select scans w/o missing pointig data 
           ;;---------------------------------------
           wgood = where(scaninfo.(1) eq 0, cogood)
           for j = 0,cogood-1 do begin
              scanname = (scaninfo.(0))(wgood(j))
              day = strmid(scanname,0,8)
              scan_num = strmid(scanname,9)
              ;; check that the IMBfits exists
              ;;---------------------------------------
              nika_find_raw_data_file, scan_num, day, file, imb_fits_file, xml_file, /noerror, /silent
              if file ne "" and imb_fits_File ne "" then begin
                 ;; if all ok, start doing flags stats
                 ;;-----------------------------------
                 nika_pipe_default_param, scan_num, day, param
                 nika_pipe_getdata, param, data, kidpar
                 help,data.scan_valid,/str
                 w0 = where(data.scan_valid(0,*) gt 0,cobad0)
                 w1 = where(data.scan_valid(1,*) gt 0,cobad1)
                 nbad = max([cobad0,cobad1])
                 nsp = n_elements(data.scan_valid(0,*))
                 percent_bad = nbad*100./nsp
                 bigtab = [bigtab,percent_bad]
                 scanlist = [scanlist,scanname]
              endif else print,"no imbfits found for scan ", scanname," ---> skiping..."
              
           endfor
        endfor
        
        bigtab = bigtab[1:*]
        scanlist = scanlist[1:*]
        nsc = n_elements(bigtab)
        
        if keyword_set(savelists) then begin
           dir = !nika.save_dir+"/Project_winter2014/Badscan_Lists/"
           save_file = "flagstat_"+day+".dat"
           get_lun,lune
           OPENW, lune, dir+save_file
           for j=0, nsc-1 do  printf,lune,scanlist(j),bigtab(j)
           free_lun, lune
        endif
        
        hist_plot,bigtab,BINSIZE=0.5,min=0,max=100
        
        saveplot,!nika.save_dir+'/Laurence/plots/flagstat_'+day
        hist_plot,bigtab,BINSIZE=0.5,min=0,max=100
        end_saveplot
        
     endfor
     
     
  endelse
  
     
  stop
     
  
end
