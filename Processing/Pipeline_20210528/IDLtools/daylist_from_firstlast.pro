;+
; AIM: output a list of days from the input of the first and last days
; of the list
;
; LP, 2020
;-

function daylist_from_firstlast, firstday, lastday

  year = strmid(firstday, 0, 4)
  checkyear = strmid(lastday, 0, 4)
  if year ne checkyear then print, 'TO BE CHECKED: POOL DURING XMASS BREAK ?!'
  
  firstmonth = strmid(firstday, 4, 2)
  lastmonth = strmid(lastday, 4, 2)
  day1 = uint(strmid(firstday, 6, strlen(firstday)-6))
  day2 = uint(strmid(lastday, 6, strlen(lastday)-6))
  if firstmonth eq lastmonth then begin
     ndays = day2-day1+1
     daylist = year+firstmonth+strtrim(string(day1+indgen(ndays), format='(I03.2)'),2)
  endif else begin
     ndays1 = 31-day1+1
     daylist = [year+firstmonth+strtrim(string(day1+indgen(ndays1), format='(I03.2)'),2), $
                year+lastmonth+strtrim(string(indgen(day2)+1, format='(I03.2)'),2)]
     
  endelse
  
  return, daylist
end
