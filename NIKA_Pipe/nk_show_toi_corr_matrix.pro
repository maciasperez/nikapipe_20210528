

pro nk_show_toi_corr_matrix, param, info, toi, kidpar, ps=ps, png=png, $
                             box=box, subbands=subbands, nickname=nickname, abs=abs, $
                             imrange=imrange, white=white, title=title, ext=ext

plot_file='toi_corr_matrix_'+param.scan+"_Method"+strtrim(param.method_num,2)
if keyword_set(box)      then plot_file += "_boxes"
if keyword_set(subbands) then plot_file += "_subbands"
if keyword_set(nickname) then plot_file += "_"+strtrim(nickname,2)
if keyword_set(ext)      then plot_file += "_"+strtrim(ext,2)
if keyword_set(white)    then col=255 else col=!p.color
if not keyword_set(title) then title=''

;; to have all matrices together
my_multiplot, 1, 1, pp, pp1

if not keyword_set(ps) then begin
   wind, 1, 1, /free, /large
   my_multiplot, 3, 2, pp, pp1, gap_x=0.05, /rev
   noerase = 1
   if keyword_set(png) then outplot, file=plot_file, /png
endif

for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)

;w1 = where( kidpar.type eq 1, nw1)
   m = correlate( toi[w1,*])
   if keyword_set(abs) then m = abs(m)

   if keyword_set(ps) then begin
      noclose = 1
      delvarx, noerase, position
      postscript = plot_file+"_A"+strtrim(iarray,2)+".eps"
   endif else begin
      noerase = 1
      delvarx, postscript, noclose
      position=pp[iarray-1,0,*]
   endelse
   imview, m, noerase=noerase, $
           position=position, $
           title=title+'A'+strtrim(iarray,2), chars=0.6, $
           postscript=postscript, noclose=noclose, imrange=imrange

   if keyword_set(box) then begin
      ;; outline acq boxes
      box0 = kidpar[w1[0]].acqbox
      for i=0, nw1-1 do begin
         if kidpar[w1[i]].acqbox ne box0 then begin
            oplot, [1,1]*i, [0,1d10], col=col
            oplot, [0,1d10], [1,1]*i, col=col
            box0 = kidpar[w1[i]].acqbox
         endif
      endfor
      if keyword_set(ps) then close_imview
      
      array = kidpar[w1].acqbox
      b = array[UNIQ(array, SORT(array))]
      nb = n_elements(b)
      make_ct, nb, ct
      if keyword_set(ps) then begin
         outplot, file='FOV_AcqBox_A'+strtrim(iarray,2), ps=ps
         delvarx, noerase, position
      endif else begin
         noerase = 1
         position=pp[iarray-1,1,*]
      endelse
      plot, kidpar[w1].nas_x, kidpar[w1].nas_y, /iso, psym=3, $
            title='Acq. boxes', position=position, noerase=noerase, /nodata
      for i=0, nb-1 do begin
         w = where( kidpar[w1].acqbox eq b[i], nw)
         if nw ne 0 then oplot, kidpar[w1[w]].nas_x, kidpar[w1[w]].nas_y, psym=8, syms=0.5, col=ct[i]
      endfor
      if keyword_set(ps) then outplot, /close, /verb
   endif

   if keyword_set(subbands) then begin
      ;; outline subbands
      subband = kidpar[w1].numdet/80 ; int division on purpose
      b = subband[ uniq( subband, sort(subband))]
      b0 = subband[0]
      for i=0, nw1-1 do begin
         if subband[i] ne b0 then begin
            oplot, [1,1]*i, [0,1d10], col=col
            oplot, [0,1d10], [1,1]*i, col=col
            b0 = subband[i]
         endif
      endfor
      if keyword_set(ps) then close_imview
      
      nb = n_elements(b)
      make_ct, nb, ct
      if keyword_set(ps) then begin
         outplot, file='FOV_Subbands_A'+strtrim(iarray,2), ps=ps
         delvarx, noerase, position
      endif else begin
         noerase = 1
         position=pp[iarray-1,1,*]
      endelse
      plot, kidpar[w1].nas_x, kidpar[w1].nas_y, /iso, psym=3, $
            position=position, noerase=noerase, $
            title='Sub bands', /nodata
      for i=0, nb-1 do begin
         w = where( kidpar.type eq 1 and kidpar.numdet/80 eq b[i], nw)
         if nw ne 0 then oplot, [kidpar[w].nas_x], [kidpar[w].nas_y], psym=8, syms=0.5, col=ct[i]
      endfor
      if keyword_set(ps) then outplot, /close, /verb
   endif
endfor
if keyword_set(png) then outplot, /close, /verb

end
