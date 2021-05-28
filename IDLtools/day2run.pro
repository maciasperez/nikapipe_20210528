
pro day2run, day, run

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "day2run, day, run"
   return
endif

case 1 of 
   (long(day) gt 20121101 and long(day) lt 20121127)  : run='5'
   (long(day) gt 20130601 and long(day) lt 20130620)  : run='6'
   (long(day) gt 20131101 and long(day) lt 20131129)  : run='cryo'
   (long(day) gt 20140101 and long(day) lt 20140131)  : run='7'
   (long(day) gt 20140201 and long(day) lt 20140601)  : run='8'
   (long(day) gt 20140201 and long(day) le 20140930)  : run='8'
   (long(day) gt 20140930 and long(day) lt 20141106)  : run='9'
   (long(day) ge 20141106 and long(day) lt 20150123)  : run='10'
   ;; There's actually a small overlap between the first polarization
   ;; scans of run 12 on Feb. 10th
   (long(day) ge 20150123 and long(day) lt 20150211)  : run='11'
   (long(day) ge 20150211 and long(day) lt 20150901)  : run='12'
   
   ;; NIKA2
   (long(day) ge 20150901 and long(day) lt 20151130)  : run='13'
   (long(day) ge 20151124 and long(day) lt 20151202)  : run='14'
   ;; place holder values for run15 (to allow lab measurements back in grenoble)
   (long(day) ge 20160111 and long(day) lt 20160301)  : run='15'
   else: message, /info, 'No run is set for that date : '+ strtrim(day, 2)
endcase

end
