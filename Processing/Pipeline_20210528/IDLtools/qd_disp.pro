pro qd_disp, map_list, kidpar, bololist, map, $
             xmap=xmap, ymap=ymap, rebin_factor=rebin_factor, $
             px=px, py=py, nobar=nobar

if n_params() lt 1 then begin
   message, /info, "calling sequence:"
   print, "qd_disp, map_list, kidpar, bololist, map, rebin_factor=rebin_factor, $"
   print, "xmap=xmap, ymap=ymap, px=px, py=py, nobar=nobar"
   return
endif

if not keyword_set(rebin_factor) then rebin_factor=4

nx = n_elements( map_list[0,*,0])
ny = n_elements( map_list[0,0,*])

nbol = n_elements(bololist)
my_multiplot, 1, 1, ntot=nbol, pp, pp1
for i=0, nbol-1 do begin
   ibol = bololist[i]
   map = reform( map_list[ibol,*,*], nx, ny)
   imview, map, xmap=xmap, ymap=ymap, nobar=nobar, $
           legend_text=strtrim(ibol,2)+"/"+strtrim(kidpar[ibol].name,2), $
           position=pp1[i,*], /noerase, udgrade=rebin_factor
endfor
my_multiplot, /reset

end
