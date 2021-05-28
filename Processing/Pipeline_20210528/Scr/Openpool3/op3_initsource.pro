; Search source in the catalog
restore,'$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
        'Log_Iram_tel_Run11_v0.save'
; Example : avoid_list = ['20141113s209', '20141113s210']
indscan = nk_select_scan( scan, source, obstype, nscans, avoid = avoid_list)
print, nscans, ' scans found'
if nscans ne 0 then begin
   scanl = scan[indscan].day + 's' + strtrim( scan[indscan].scannum,2)
   print, scanl
   projidlist = strtrim(scan[ indscan[uniq( scan[indscan].projid)]].projid, 2)
   print, 'Projects found: ', projidlist+' '
   projid = projidlist[0]  ; to take something
   scan_list = scanl 
endif else begin
delvarx, scan_list
endelse

