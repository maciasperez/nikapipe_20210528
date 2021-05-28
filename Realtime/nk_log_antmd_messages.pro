
pro nk_log_antmd_messages, scan

log_dir = !nika.plot_dir+"/Logbook/Scans/"+scan
spawn, "mkdir -p "+log_dir

year     = strmid( scan, 0, 4)
month    = strmid( scan, 4, 2)
day      = strmid( scan, 6, 2)
scan_num = strmid( scan, 9)

file = !nika.imb_fits_dir+"/iram30m-sync-"+scan+".html"
spawn, "cat "+file, file_line
nfl = n_elements(file_line)

;; there are other messages that we probably do not want to log, keep
;; only:
my_messages = ['scanLoaded', 'scanStarted', 'backOnTrack', 'subscan_tuning', $
               'subscanDone', 'subscanStarted', 'scanDone']


openw, lu, log_dir+"/antmd_messages.dat", /get_lun
printf, lu, "#ANTMd time (UT), message"
for i=nfl-1, 0, -1 do begin
   
   ;; select only info concerning the current scan, info from adjacent
   ;; scans often leaks into these files.
   if strmatch( strupcase(file_line[i]), "*"+year+"-"+month+"-"+day+"."+strtrim(scan_num,2)+"*") then begin

      ;; Get message
      x = strsplit( file_line[i], /extract, ":")
      x = strsplit( x[2], /extra, "</td>", /regex)
      ant_message = strtrim(x[0],2)

      w = where( strupcase( my_messages) eq strupcase(ant_message), nw)
      if nw ne 0 then begin
         ;; Get date
         x = strsplit( file_line[i], /extract, "<td align='left'>", /regex)
         x = strsplit( x[1], /extract, "</td>", /regex)
         x = strsplit( x[0], /extract, "T")
         mday  = x[0]
         mtime = x[1]
         
         ;;print, i, " ", ant_message+", "+strtrim(mday,2)+", "+strtrim(mtime,2)
         printf, lu, strtrim(mtime,2)+", "+strtrim(ant_message,2)
      endif
   endif
endfor
close, lu
free_lun, lu


end
