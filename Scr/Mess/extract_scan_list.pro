pro extract_scan_list, csvfile, daylist, scanlist, singlesource=singlesource,notrack=notrack

; csvfile = !nika.save_dir+"/Project_winter2014/Scan_Lists/118-13.csv"

print,"reading : ", file_basename(csvfile) 
if not(keyword_set(singlesource)) then begin
;temp = ascii_template(csvfile)
;SAVE, temp, FILENAME=!nika.save_dir+"/Laurence/csv_template.save"
RESTORE, !nika.save_dir+"/Project_winter2014/Scan_Lists/csv_template.save"
endif else begin
;temp = ascii_template(csvfile)
;SAVE, temp, FILENAME=!nika.save_dir+"/Project_winter2014/Scan_Lists/csv_template_single.save"
RESTORE, !nika.save_dir+"/Project_winter2014/Scan_Lists/csv_template_single.save"
endelse

data = read_ascii(csvfile,template=temp)

;; scan name list
names = data.(0)
names = names(WHERE(STRMATCH(names, '</*>') eq 0))

types = data.(4)
if keyword_set(notrack) then begin
   names = names(where(strmatch(types,'track') eq 0))
endif 

nscan = n_elements(names)

; day list
daylist = strarr(nscan)
for i=0,nscan-1 do daylist[i] = (STRJOIN(STRSPLIT(strmid(names[i],0,10), '-',/EXTRACT)))

; only run8 scans
monthlist = strarr(nscan)
for i=0,nscan-1 do monthlist[i] = strmid(daylist[i],4,2)

wrun8 = where(monthlist eq '02')
daylist=daylist(wrun8)

; scan list
scanlist = strmid(names,11)
scanlist = scanlist(wrun8)

; only those for which the IMBfits exists 
; iram30m-antenna-20140126s297-imb.fits

;nscans = n_elements(scanlist) 
;fitsdir = !nika.imb_fits_dir
;for i = 0, nscans-1 do begin
;   filestar = 'iram30m-antenna-'+daylist(i)+'s'+scanlist
;   res = file_search(fitsdir,filestar)
;endfor



return

end
