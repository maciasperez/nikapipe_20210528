
pro show_checklist, check_list, init=init

n_items = n_elements(check_list.items)

y_factor = 30
x_factor = 15

if keyword_set(init) then begin
   ys = (n_items+2)*y_factor
   xs = max( strlen(check_list.items))*x_factor
   window, check_list.wind_num, xpos=!screen_size[0]-xs-50, ypos=50, xs=xs, ys=ys, title='Checklist'
endif else begin
   wshet, check_list.wind_num
endelse

loadct, 39
col_items = intarr(n_items) + 250
w = where( check_list.status eq 1, nw)
if nw ne 0 then col_items[w] = 150
;; plot, [0, 1], [0, 1], /nodata, xchars=1e-10, ychars=1e-10, $
;;       xticklen=1e-10, yticklen=1e-10, title='CHECKLIST', xs=4, ys=4
;; legendastro, check_list.items, psym=col_items*0.+8, syms=col_items*0+2, col=col_items, box=0, chars=2

for i=0, n_items-1 do $
   xyouts, x_factor, (n_items+1-i)*y_factor, strtrim(i,2)+". "+check_list.items[i], col=col_items[i], chars=2, /device




end
