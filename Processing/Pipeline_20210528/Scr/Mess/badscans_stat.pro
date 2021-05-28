pro badscans_stat, daylist, verif=verif, savelists=savelists

;daylist=['20140219','20140220','20140221','20140222','20140223']

ndays = n_elements(daylist)

bigtab = lonarr(1)

;; read ascii file produced from check_all_scans 
for iday = 0, ndays-1 do begin
   
   badscans = ''
   day=daylist[iday]
   
   file_list = FILE_SEARCH(!nika.save_dir+"/Laurence/", "scan_status_"+day+'_*.dat') 
   ;temp = ascii_template(file_list[0])
   ;SAVE, temp, FILENAME=!nika.save_dir+"/Laurence/badscans_template.save"
   RESTORE, !nika.save_dir+"/Laurence/badscans_template.save"
   
   nfiles = n_elements(file_list)
   for ifil = 0, nfiles-1 do begin
      data = read_ascii(file_list[ifil],template=temp)
      wbad = where(data.(1) gt 0, cobad)
      bigtab = [bigtab,(data.(1))(wbad)]
      badscans = [badscans,(data.(0))(wbad)]
      if keyword_set(verif) then begin
         annee=strmid(day,0,4)
         mois = strmid(day,4,2)
         jour=strmid(day,6,2)
         daydir='X10_'+annee+'_'+mois+'_'+jour
         list_data="scan"
         for ii = 0, cobad-1 do begin
            nickname=(data.(0))(wbad(ii))
            scan_num = strmid(nickname,9)
            ;;file_scan = FILE_SEARCH(!nika.raw_acq_dir+'/Run7/raw_X10/'+daydir+'/','X_'+annee+'_'+mois+'_'+jour+'_*_'+strtrim(string(scan_num, format="(I8.4)"),2)+'_*' ) 
            ;;if file_scan ne '' then begin
            ;;   rr = read_nika_brute(file_scan, param_c, kidpar, data0, units, param_d=param_d, $
            ;;                     list_data=list_data, read_type=12, indexdetecteurdebut=indexdetecteurdebut, $
            ;;                     nb_detecteurs_lu=nb_detecteurs_lu, amp_modulation=amp_modulation, silent=1)
            ;;   plot,data0.scan
            ;;   ans=''
            ;;   read,ans
            ;;endif print,"find not found :",'X_'+annee+'_'+mois+'_'+jour+'_*_'+strtrim(string(scan_num,format="(I8.4)"),2)+'_*'
            nika_pipe_default_param, scan_num, day, param0
            nika_pipe_getdata, param0, data0, kidpar
            print,"AVANT RECUP"
            data1=data0
            ;;window,0
            ;;plot,data0.ofs_az,data0.ofs_el,col=0,title="no recup from antenna imbfits"
            nika_find_raw_data_file, scan_num, day, file_scan, imb_fits_file, /silent,/noerror
            if (imb_fits_file ne '') then begin
               nika_pipe_antenna2pointing, data1, imb_fits_file, /selectiveinterpol
               print,"APRES RECUP"
               ;;window,1
               ;;plot,data0.ofs_az,data0.ofs_el,col=0,title="after recup from antenna imbfits"
               ;;oplot,data1.ofs_az,data1.ofs_el,col=250
            endif else print,"ya pas d'imbfits"
            window,0
            plot,data0.ofs_el,col=0,ytitle="el"
            oplot,data1.ofs_el,col=250,linestyle=2
            legendastro,['before antenna2pointing','after antenna2pointing'],col=[0,250],textcolor=[0,250],/bottom,/right,box=0
            window,1
            plot,data0.ofs_az,col=0,ytitle="az"
            oplot,data1.ofs_az,col=250,linestyle=2
            legendastro,['before antenna2pointing','after antenna2pointing'],col=[0,250],textcolor=[0,250],/bottom,/right,box=0

            saveplot,!nika.save_dir+"/Laurence/Antennat2pointing_"+day+"_"+scan_num+"_el"
            plot,data0.ofs_el,col=0,ytitle="el"
            oplot,data1.ofs_el,col=250,linestyle=2
            legendastro,['before antenna2pointing','after antenna2pointing'],col=[0,250],textcolor=[0,250],/bottom,/right,box=0
            end_saveplot

            saveplot,!nika.save_dir+"/Laurence/Antennat2pointing_"+day+"_"+scan_num+"_az"
            plot,data0.ofs_az,col=0,ytitle="az"
            oplot,data1.ofs_az,col=250,linestyle=2
            legendastro,['before antenna2pointing','after antenna2pointing'],col=[0,250],textcolor=[0,250],/bottom,/right,box=0
            end_saveplot

            data1[1700:2200].ofs_az = 0.
            data1[1700:2200].ofs_el = 0.
            
            nika_pipe_inpaintpointing, data1, param0


            stop
         endfor          
      endif
   endfor

   badscans = badscans[1:*]
   nbads = n_elements(badscans)

   if keyword_set(savelists) then begin
      dir = !nika.save_dir+"/Project_winter2014/Badscan_Lists/"
      save_file = "badscans_list_"+day+".dat"
      get_lun,lune
      OPENW, lune, dir+save_file
      for j=0, nbads-1 do  printf,lune,badscans(j)
      free_lun, lune
   endif
     

endfor

bigtab=bigtab[1:*]

;; bad sample stats
hist_plot,bigtab,BINSIZE=10,min=100,max=10000

stop

end
