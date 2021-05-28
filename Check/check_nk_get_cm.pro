

nk_init, '20140219s205', param, info, /force
nk_getdata, param, info, data, kidpar


wsample = indgen(8000-2000)+2000
nk_get_cm, param, info, data, kidpar, wsample, common_mode

wind, 1, 1, /free, /large
!p.multi=[0,1,2]
for lambda=1, 2 do begin
   nk_list_kids, kidpar, valid=w1, nvalid=nw1, lambda=lambda
   make_ct, nw1, ct
   plot, data.toi[w1[0]], xra=[0, 14000], /xs, title=strtrim(lambda,2)+"mm"
   for i=0, nw1-1 do begin
      oplot, data.toi[w1[i]], col=ct[i]
   endfor
   oplot, wsample, common_mode[lambda-1,*], col=0, thick=2
endfor
!p.multi=0

end
