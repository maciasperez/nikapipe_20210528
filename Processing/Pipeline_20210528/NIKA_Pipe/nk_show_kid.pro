
pro nk_show_kid, numdet, scan = scan

if not keyword_set(scan) then scan = '20141007s129'

scan2daynum, scan, day, scan_num
nk_get_kidpar_ref, scan_num, day, kidpar_file

kidpar = mrdfits(kidpar_file, 1, /silent)
nk_list_kids, kidpar, lambda = 1, valid = w1, nvalid = nw1
nk_list_kids, kidpar, lambda = 2, valid = w2, nvalid = nw2

xra = [-80, 80]
yra = [80, 80]

wind, 1, 1, /large, /free
plot, kidpar[w1].nas_x, kidpar[w1].nas_y, psym = 1, xra = xra, yra = yra, /nodata, /iso
oplot, [0, 0], [0, 0], line = 2
oplot, kidpar[w1].nas_x, kidpar[w1].nas_y, psym = 1, col = 250
oplot, kidpar[w2].nas_x, kidpar[w2].nas_y, psym = 1, col = 70
xyouts, kidpar[w1].nas_x,  kidpar[w1].nas_y, strtrim(kidpar[w1].numdet, 2), col = 250
xyouts, kidpar[w2].nas_x,  kidpar[w2].nas_y, strtrim(kidpar[w2].numdet, 2), col = 70
oplot, [-1, 1]*100, [0, 0], line = 2
oplot, [0, 0], [-1, 1]*100, line = 2
for i = 0, n_elements(numdet)-1 do begin
   w = where( kidpar.numdet eq numdet[i] and kidpar.type eq 1, nw)
   if nw eq 0 then begin
      message, /info, "No valid kid with numdet "+strtrim(numdet[i], 2)
   endif else begin
      oplot,  [kidpar[w].nas_x], [kidpar[w].nas_y], psym = 4, thick = 2, syms = 2
      print, "numdet, nas_x, nas_y: ",  strtrim(numdet[i])+", "+$
             strtrim(kidpar[w].nas_x, 2)+", "+strtrim(kidpar[w].nas_y, 2)
   endelse
endfor

end
