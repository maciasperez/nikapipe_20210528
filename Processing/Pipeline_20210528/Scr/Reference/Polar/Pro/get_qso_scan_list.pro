
pro get_qso_scan_list, source, scan_list_in, myday_list

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "get_qso_scan_list, source, scan_list_in"
   return
endif

case strupcase(source) of

   '3C273': begin
      myday_list = ['201812'+strtrim([5],2)]
      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R25_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      scan_list_in = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
   end

   '3C279': begin
;;      myday_list = ['201806'+strtrim([12,13,14,15,16,17],2), '-1']
;;      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R19_v0.save"
;;      db_scan = scan
;;      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
;;                 strupcase( db_scan.object) eq source and $
;;                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
;;0.05*!      scan_list_in = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)

      myday_list = ['201812'+strtrim([5],2), '-1']
      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R25_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      scan_list_in = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
   end
   
   '0923+392': begin
      myday_list = ['201806'+strtrim([14,15,16],2), '20180920', '-1']

      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R19_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      scan_list_1 = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)

      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R21_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      scan_list_2 = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)

      scan_list_in = [scan_list_1, scan_list_2]
   end
   '0851+202': begin
      myday_list = ['20180920', '20180921', '20180922', '20180923', '20180924', '-1']
      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R21_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      
      ;; w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
      ;;            strupcase( db_scan.object) eq source and $
      ;;            strupcase( strmid( db_scan.comment,0,3)) NE "FOC" and $
      ;;            strupcase(db_scan.day) NE '20180923', nw)

      scan_list_in = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
   end
   '0355+508': begin
      myday_list = ['20180921', '20180923', '20180924', '-1']
      
      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R21_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      scan_list_in = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
   end
   '3C345': begin
      myday_list = ['20180921'] ; 0922, only two points, impossible to fit
      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R21_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      scan_list_in = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
   end
   '2251+158': begin
      myday_list = ['20180921', '20180922', '-1']
      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R21_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      scan_list_in = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
   end
   '3C147': begin
      myday_list = ['20180921', '20180922', '-1']
      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R21_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      scan_list_in = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
   end
   '2200+420': begin
      myday_list = ['20180922', '20180923', '-1']
      restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R21_v0.save"
      db_scan = scan
      w = where( strupcase( db_scan.obstype) eq "ONTHEFLYMAP" and $
                 strupcase( db_scan.object) eq source and $
                 strupcase( strmid( db_scan.comment,0,3)) NE "FOC", nw)
      scan_list_in = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
   end
   else: begin
      message, /info, "Please define mydaylist for "+source
      stop
   endelse
endcase

;; Remove scans with too high fwhm or bad scans...
black_list_file = !nika.pipeline_dir+"/Scr/Reference/Polar/Data/qso_blacklist.dat"
if file_test(black_list_file) then begin
   readcol, black_list_file, black_list, format='A', comment='#'
   for i=0, n_elements(black_list)-1 do begin
      w = where( scan_list_in ne black_list[i])
      scan_list_in = scan_list_in[w]
   endfor
endif

end
