

pro show_kidpar, kidpar_file, symsize=symsize, charsize=charsize, kidpar=kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "show_kidpar, kidpar_file, symsize=symsize, charsize=charsize"
   return
endif


kidpar = mrdfits(kidpar_file, 1)

w = where(kidpar.type eq 1, nw)
if nw eq 0 then begin
   message, /info, "No valid kids in kidpar"
   return
endif

xra = [-250,250]
yra = [-250,250]

wind, 1, 1, /free, /large
my_multiplot, 3, 2, pp, pp1, /rev, xmargin=0.1, gap_x=0.05, gap_y=0.05, ymargin=0.1
for iarray = 1, 3 do begin
   w = where( kidpar.type eq 1 and kidpar.array eq iarray, nw)

   if nw ne 0 then begin
      ;; kid offsets
      delvarx, xtitle, ytitle, title
      if iarray eq 1 then ytitle='Nasmyth offsets y'
      plot, [kidpar[w].nas_x], [kidpar[w].nas_y], psym = 1, /iso, $
            symsize=symsize, $
            xtitle=xtitle, ytitle=ytitle, position=pp[iarray-1,0,*], /noerase, $
            xra=xra, yra=yra, /xs, /ys, charsize=charsize
      legendastro, 'A'+strtrim(iarray, 2), box = 0, charsize=charsize
      legendastro, 'Nkids '+strtrim(nw, 2), box = 0, /right, charsize=charsize
      if iarray eq 1 then xyouts, min(xra), max(yra)+0.02*(yra[1]-yra[0]), strtrim( file_basename( kidpar_file), 2)

      ;; Acq boxes
      boxes = kidpar[w].acqbox
      boxes = boxes[UNIQ(boxes, SORT(boxes))]
      make_ct, n_elements(boxes), ct
      
      delvarx, ytitle
      xtitle='Nasmyth offset x'
      if iarray eq 1 then ytitle='Nasmyth offsets y'
      plot, [kidpar[w].nas_x], [kidpar[w].nas_y], psym = 1, /iso, $
            symsize=symsize, $
            xtitle=xtitle, ytitle=ytitle, position=pp[iarray-1,1,*], /noerase, $
            xra=xra, yra=yra, /xs, /ys, charsize=charsize
      legendastro, 'A'+strtrim(iarray, 2), box = 0, charsize=charsize
      legendastro, strtrim( boxes, 2), box=0, textcol=ct, /right, charsize=charsize
      if iarray eq 1 then xyouts, min(xra), max(yra)+0.02*(yra[1]-yra[0]), "Acquisition boxes"
      for ibox=0, n_elements(boxes)-1 do begin
         ww = where( kidpar.type eq 1 and kidpar.array eq iarray and $
                     kidpar.acqbox eq boxes[ibox], nww)
         if nww ne 0 then oplot, [kidpar[ww].nas_x], [kidpar[ww].nas_y], psym=1, symsize=symsize, col=ct[ibox]
      endfor
   endif
endfor
my_multiplot, /reset


end
