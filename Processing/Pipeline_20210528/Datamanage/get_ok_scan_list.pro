;+
;  Discard bad scans in a scan list 
;  then update the scan_num_list 
;  selection criteria : 
;  (1) OTF or Lissajous scan
;  (2) the IMBFits exists
;  (3) the IMBfits is not corrupted
;  (4) no pointing data missing
;  (5) >= 50% of the samples are ok 
;
;-

pro get_ok_scan_list, day_list, scan_num_list, output_dir=output_dir


;;------- The list is valid?
  nscan = n_elements(day_list)
  if nscan ne n_elements(scan_num_list) then message,'The number of day must be equal to the number of scan_num'
  
  ;;####### historic
  keepinfo = 0
  if keyword_set(output_dir) then begin
     keepinfo=1
    scaninfo=strarr(nscan,3)
    ;; col1 : scan name
    ;; col2 : mask (0=bad, 1=ok)
    ;; col3 : info :
    ;;           0=allgreen
    ;;           1=bad sample ratio > 50%
    ;;           2=missing data
    ;;           3=imbfits or raw_data files problem
    
    scaninfo_file = output_dir+'/scans_list_info.txt'
    if (file_test(scaninfo_file) eq 1) then begin 
       print,"default scan status file already exists...."
       scaninfo_file = output_dir+'scans_list_info_'+strtrim(string(round(randomn(1)*100000.)),2)+'.txt'
       print,"the scan status file will be ",scaninfo_file
    endif
  endif

  ;;####### Get list of imb_fits and also check scans exists and overwrite scanlist and daylist
  new_scan_num_list=[0]
  new_day_list=['']
  for iscan=0, nscan-1 do begin
     status=3
     if (keepinfo gt 0) then scaninfo[iscan,0]=strtrim(string(day_list[iscan]),2)+'_'+strtrim(string(scan_num_list[iscan]),2)
     nika_find_raw_data_file, scan_num_list[iscan], day_list[iscan], file_scan, imb_fits_file, /silent,/noerror
     if ((file_scan ne '') and (imb_fits_file ne '')) then begin
        status-=1
                                ;imb_fits=[imb_fits,imb_fits_file]
        ;; if all ok, start checking at flags 
        ;;-----------------------------------
        nika_pipe_default_param, scan_num_list[iscan], day_list[iscan], param0
        nika_pipe_getdata, param0, data0, kidpar
        scan_toi = data0.scan
        scan_num = max(scan_toi,wdebut)
        nsp = n_elements(scan_toi)
        if wdebut lt nsp-1 then wmiss = where(scan_toi(wdebut:*) ne scan_num_list[iscan],cobad2)
        ;; keeping only scans w/o missing data
        if ((cobad2 lt 1) and (wdebut lt nsp-1)) then begin
           status-=1
           
           w0 = where(data0.scan_valid(0,*) gt 0,cobad0)
           w1 = where(data0.scan_valid(1,*) gt 0,cobad1)
           nbad = max([cobad0,cobad1])
           nsp = n_elements(data0.scan_valid(0,*))
           percent_bad = nbad*100./nsp        
           
           ;; keeping only scans with more than 50% valid samples 
           if (percent_bad le 50.) then begin
              status-=1
              new_scan_num_list=[new_scan_num_list,scan_num_list[iscan]]
              new_day_list=[new_day_list,day_list[iscan]]
              if (keepinfo gt 0) then scaninfo[iscan,1] = 1
           endif else print, "Too much (>50%) bad samples for scan "+ (scan_num_list[iscan])+ " for day "+ (day_list[iscan])
        endif else print, "MISSING DATA for scan "+ (scan_num_list[iscan])+ " for day "+ (day_list[iscan])
     endif else print, "NO FILES for scan "+ (scan_num_list[iscan])+ " for day "+ (day_list[iscan])
     print,"STATUS for  scan "+ (scan_num_list[iscan])+ " for day "+ (day_list[iscan])," = ",status
     if (keepinfo gt 0) then scaninfo[iscan,2] = status
  endfor
  
  ;;------- If no file availlable, error
  nscan = n_elements(new_scan_num_list)
  if nscan le 1 then message, 'No file for any of the requested scans'
  
  ;;------- Select the initialization
  ;imb_fits = imb_fits[1:*]
  scan_num_list = new_scan_num_list[1:*]
  day_list = new_day_list[1:*]
  nscan = n_elements(scan_num_list)

  if (keepinfo gt 0) then begin
     get_lun,lune
     OPENW, lune, scaninfo_file
     for j=0, nscan-1 do  printf,lune,transpose(scaninfo(j,*))
     free_lun, lune
  endif


return

end
