
;; small routine that retrieves that allows to know if a file was
;; created before another one in the pipeline.
;;
;; NP. Jan 13th, 2016

pro nk_get_file_date, file, date

;; only tested on January for now... others TBC
month_list = ['Jan', 'Feb', 'Mar', 'Apr', 'Jun', 'Jul', $
              'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

month_num = indgen(12) + 1

l = strlen( file)
str = strsplit( file, " ", /extract)
month = str[5]

w = where( strupcase( month_list) eq strupcase( strtrim( month,2)), nw)
if nw eq 0 then begin
   message, /info, "Check the definition of month_list, "+month+" did not match"
   stop
endif
month = month_num[w]

day   = double(str[6])

time = strsplit( str[7], ":", /extract)
hour    = double(time[0])
minutes = double(time[1])

date = minutes + hour*60.d0 + day*24.d0*60.d0 + month*31.d0*24.d0*60.d0

end
