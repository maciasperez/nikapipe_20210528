pro check_all_scans,day
  
; day = '20140219'
;lesjours=['20140220','20140221','20140222','20140223','20140224'] 
;lesjours=['20140224','20140225'] 
lesjours=['20140225','20140226'] 
;for i=0,1 do begin check_all_scans,lesjours[i]

  annee=strmid(day,0,4)
  mois = strmid(day,4,2)
  jour=strmid(day,6,2)
  daydir='X10_'+annee+'_'+mois+'_'+jour
  
  alltype = ['L','O']
  
  for ity = 0,1 do begin
     
     scantype = alltype[ity]
     
     print,"==================="
     print,''
     print,"CHECKING ALL "+scantype+" SCANS"
     
     files='X_'+annee+'_'+mois+'_'+jour+'_*_'+scantype+'*'
     file_list = FILE_SEARCH(!nika.raw_acq_dir+'/Run7/raw_X10/'+daydir+'/',files ) 
     wtilde = where(STRPOS(file_list, '~') gt -1, compl=wok)
     file_list = file_list(wok)

;file2nickname, file_list, nickname
;scan_list = 
;nika_find_raw_data_file, scan_list[iscan], day, file_scan, imb_fits_file, /silent, /noerror
     
     nscans = n_elements(file_list)
     
;list_data = "subscan scan el RF_didq"
     list_data = "scan"
     
     badsamtab = strarr(nscans,3)
     
     for i=0, nscans-1 do begin
        print,"-----> checking scan ", i+1, " over ", nscans
        
        file_scan=file_list[i]
        rr = read_nika_brute(file_scan, param_c, kidpar, data0, units, param_d=param_d, $
                             list_data=list_data, read_type=12, indexdetecteurdebut=indexdetecteurdebut, $
                             nb_detecteurs_lu=nb_detecteurs_lu, amp_modulation=amp_modulation, silent=1)
        scantab = data0.scan
        nsam = n_elements(scantab)
        scan_num = max(scantab,wdebut)
        if wdebut gt 200 then print, "scan : ",file_basename(file_scan)," : late start after ",wdebut," samples"
        if wdebut lt nsam-1 then begin
           scantab = scantab(wdebut:*)
           w=where(scantab ne scan_num,cobad)
           if (cobad gt 0) then  print, "scan : ",file_basename(file_scan)," : there are bad samples"
           badsamtab[i,1]=strtrim(string(cobad),2)
        endif else  badsamtab[i,1]=strtrim(string(nsam),2)
        badsamtab[i,0]=day+'_'+strtrim(string(long(scan_num)),2)
        badsamtab[i,2]=strtrim(string(wdebut),2)
        
     endfor
     
     
     dir = !nika.save_dir+"/Laurence/"
     save_file = "scan_status_"+day+'_'+scantype+".dat"
     get_lun,lune
     OPENW, lune, dir+save_file
     printf,lune,"| nickname | n_badsamples | begin_sample | "
     for j=0, nscans-1 do  printf,lune,transpose(badsamtab(j,*))
     free_lun, lune
     
  endfor
 
  
end
