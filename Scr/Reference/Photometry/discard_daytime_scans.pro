;
; Aim: output the index of the scans acquired during "night-time" 
;
; Input: array of scan dates
; Output: array of index of night-time scans
;
; Default night-time is from 21:00 to 9:00. However it can be
; redefined using 'night_begin' and 'night_end' keywords
;
; example :
; discard_daytime_scans, scan.date, index, night_beg='20:00', night_end='11:00'
;
; LP, 2018, April
;-

function extract_date, indate
  date = strmid(indate, 11, 5)
  return, date
end


pro discard_daytime_scans, date, index, night_begin = night_begin, night_end=night_end

  if keyword_set(night_begin) then nbeg = night_begin else nbeg = '21:00'
  if keyword_set(night_end) then nend= night_end else nend = '09:00'

  minuit = '00:00'
  ;; if the night-time does not include midnight
  if nbeg lt nend then begin
     print,'midnight in daytime'
     minuit = nbeg
     nbeg = '24:00'
  endif
     
     
  rdate = extract_date(date)
  w=where((rdate ge nbeg and rdate le '23:59') or (rdate ge minuit and rdate le nend), nnight)

  if nnight le 0 then print, 'no scans during night-time'

  index = w
  
end
