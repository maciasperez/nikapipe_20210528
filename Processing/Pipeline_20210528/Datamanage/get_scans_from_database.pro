pro get_scans_from_database, projid, source, day_list,scan_num_list, info=info

  databasepath = !nika.soft_dir+'/Pipeline/Datamanage/Logbook/'
  if !nika.run eq 10 then databasefile = 'Log_Iram_tel_Run10_v0.save'
  restore, databasepath+databasefile

  if source eq 'all' then begin 
    lscans = where(strmatch(strtrim(scan.projid,2),projid)  and strtrim(scan.object,2) ne 'track',nlscans)
  endif else begin
    lscans = where(strmatch(strtrim(scan.projid,2),projid) and strmatch(strtrim(scan.object,2),source) and strtrim(scan.obstype,2) ne 'track',nlscans)
  endelse
  if nlscans gt 0 then begin
     info = scan[lscans]
     day_list = strmid(scan[lscans].date,0,10)
     for iscan=0,nlscans-1 do day_list[iscan] = str_replace(day_list[iscan],'-','')
     for iscan=0,nlscans-1 do day_list[iscan] = str_replace(day_list[iscan],'-','')
     scan_num_list = scan[lscans].scannum
  endif else begin

  endelse

  return
end
