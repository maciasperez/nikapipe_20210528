
;; Displays kid maps as obtained from get_bolo_maps.pro

pro matrix_display, map_list, kidpar=kidpar, ibol_start=ibol_start, $
                    rebin_factor=rebin_factor, name=name, nlines=nlines, $
                    ncol=ncol, sub=sub, title=title, nolabel=nolabel, $
                    select=select, bolo_out=bolo_out, num_disp=num_disp, percent_saturation=percent_saturation, $
                    charsize=charsize

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "matrix_display, map_list, kidpar=kidpar, ibol_start=ibol_start, $"
   print, "                rebin_factor=rebin_factor, name=name, nlines=nlines, $"
   print, "                ncol=ncol, sub=sub, title=title, nolabel=nolabel, $"
   print, "                select=select, bolo_out=bolo_out, num_disp=num_disp"
   return
endif

if not keyword_set(kidpar) then begin
   kidpar = {type:1,name:'',numdet:0}
   nkids = n_elements( map_list[*,0,0])
   kidpar = replicate( kidpar, nkids)
   kidpar.numdet = lindgen( nkids)
endif

s = size( map_list)
nbol = s[1]
nx = s[2]
ny = s[3]

if not keyword_set(sub) then sub=lindgen(nbol)
map_list1 = map_list[sub,*,*]
kidpar1   = kidpar[sub]
bololist  = (lindgen(nbol))[sub]
nbol1     = n_elements( sub)

my_multiplot, n_plot_x, n_plot_y, ntot=nbol1, /dry

if not keyword_set(ncol)       then ncol = n_plot_x
if not keyword_set(nlines)     then nlines = n_plot_y
if not keyword_set(ibol_start) then ibol_start = 0

x_size_max = 0.8*!screen_size[0]
y_size_max = 0.8*!screen_size[1]
if not keyword_set(rebin_factor) then begin
   rebin_factor = long( x_size_max/(ncol*nx)) > 1
endif
nx_max = min( [x_size_max/ncol, y_size_max/nlines])
;nx_disp = (nx*rebin_factor) < nx_max
;ny_disp = (ny*rebin_factor) < nx_max
nx_disp = long(nx*rebin_factor) < nx_max
ny_disp = long(ny*rebin_factor) < nx_max

;; Discard Nan values not to screw up tvscl
w = where( finite( map_list1) ne 1, nw)
if nw ne 0 then map_list1[w] = 0.d0

if keyword_set(percent_saturation) then begin
   for ibol=0, nbol1-1 do begin
      mmax = max( abs(map_list1[ibol,*,*]))*percent_saturation/100.
      map_list1[ibol,*,*] = (map_list1[ibol,*,*]>(-mmax)) < mmax
   endfor
endif

wind, 1, 1, /free, xs=ncol*nx_disp, ys=nlines*ny_disp, title=title
for ibol=0, nbol1-1 do begin
   tvscl, congrid( reform( map_list1[ibol,*,*], nx, ny), nx_disp, ny_disp), ibol
   j = ibol/ncol
   i = ibol-j*ncol
   
   ;;my_string = strtrim( bololist[ibol]+ibol_start,2)
   my_string = strtrim( kidpar[ibol].numdet,2)
   decode_flag, kidpar1[ibol].type, meaning
   my_string = my_string+" "+meaning
   if keyword_set(name)     then my_string = my_string+"/"+kidpar1[ibol].name
   if keyword_set(num_disp) then my_string = strtrim( ibol,2)
   if keyword_set(nolabel)  then my_string = ''

   xyouts, i*nx_disp + nx_disp*0.1, (nlines-j)*ny_disp - 0.9*ny_disp, my_string, col=255, /dev, chars=charsize
endfor

if keyword_set(select) then begin
   coor_cursor, x, y, /device
   ix = long( float(x)/nx_disp)
   iy = long( float(nlines*ny_disp-y)/ny_disp)
   bolo_out = ix + iy*ncol
   print, "ix, iy, ibol:" , bolo_out
   print, ""
   print, strtrim( bolo_out,2)+", "
endif

end
