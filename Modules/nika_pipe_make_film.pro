pro nika_pipe_make_film, toin, film, pfi, debug = debug, cubout = cubout
                         
; Make a film (started from Pro/Make_film.scr)
; Need to set min, max 
; Project camera  data on a regular grid to prepare for a film
; k_film_sm is a smoothing duration (resampled to k_film_sm/2)
; k_film_darcsec  is the image pixel in arcseconds
; k_film_size is the size of the image in arcseconds
; All in a structure pfi
toi = toin
nbkid = n_elements( toi[0].br)
ntoi = n_elements( toi)
; Smooth the data and resample
FOR ikid = 0, nbkid-1 DO BEGIN
  br = toin.br[ ikid]
  fl = toin.fl[ ikid]
  badproj = where( fl gt 0 or br eq !undef,  nbadproj)
  goodproj = where( fl eq 0 and br ne !undef,  ngoodproj)
; interpolate on bad data
  if ngoodproj ne 0 then begin
     if nbadproj ne 0 then $
        br[ badproj] = interpol( br[ goodproj],  goodproj, badproj)
     toi.br[ ikid] = smooth( br, pfi.k_film_sm, /edge_trunc)
     if pfi.k_film_rmbase then $
        toi.br[ ikid] = toi.br[ ikid]- $
             smooth( toi.cm[ ikid], pfi.k_film_sm, /edge_trunc) else $
        toi.br[ ikid] = toi.br[ ikid]-smooth( br, 121, /edge_trunc)
     toi.xx[ ikid] = smooth( toin.xx[ ikid], pfi.k_film_sm, /edge_trunc)
     toi.yy[ ikid] = smooth( toin.yy[ ikid], pfi.k_film_sm, /edge_trunc)
  endif else toi.br[ ikid] = 0 ;;;!undef
ENDFOR
step = pfi.k_film_sm/2
indres = (lindgen( ntoi/ step - 2) + 1) * step  
; forget the first and last samples
toi = toi[ indres]
ntoi = n_elements( toi)
;toi = toi[0:ntoi-10]
;ntoi = n_elements( toi)
nout = 2*nint(pfi.k_film_size / pfi.k_film_darcsec) + 1
print, ntoi, ' images in the film'

cubout = fltarr( nout, nout, ntoi)  


; Loop on final image
for isatoi = 0,  ntoi- 1 do begin
; if isatoi mod 100 eq 0 then print, isatoi, ntoi
   goodim = where( toi[ isatoi].br ne 0,  ngoodim)
      if ngoodim ne 0 then begin
         cubout[ *, *, isatoi] = $
; tri_surf gives negative rebounces , No see below
           tri_surf(  toi[ isatoi].br[ goodim], $; /linear, $
;           min_curve_surf(  toi[ isatoi].br[ goodim],  $
                        (toi[ isatoi].xx[ goodim] - pfi.k_cx) * 3600* $
                       cos( toi[ isatoi].yy[ goodim]/!radeg),  $
                       (toi[ isatoi].yy[ goodim] - pfi.k_cy) * 3600,  $
                       gs = [pfi.k_film_darcsec,  pfi.k_film_darcsec], $
                       bound = 1. * [-1,  -1, +1, +1] * pfi.k_film_size)
;                       missing = 0.,  $
;if isatoi mod 5 eq 0 then plot,xoff*3600,yoff*3600,psym=4,  xrang = pfi.k_film_size * [-.5, .5], yrang = pfi.k_film_size * [-.5, .5],  title = strtrim(ipl, 2)
;ipl = ipl + 1
;if ipl mod 45 eq 44 then begin
; @continue_plot
;endif
      endif
endfor

; try to remove a median along time for each pixel
; this is producing rebounces. do not do it
;; medca = median( cubout, dim = 3)
;; for isatoi = 0,  ntoi-1 do $
;;    cubout[*, *, isatoi] = cubout[*, *, isatoi] - medca

;; ; Try to remove a median avg of each map
;;for isatoi = 0,  ntoi-1 do $
;;    cubout[*, *, isatoi] = cubout[*, *, isatoi] - median( cubout[*, *, isatoi])

if keyword_set( debug) then begin
   wshet, 20
   loadct, 39
   erase
   mapmin = min(cubout)
   mapmax = max(cubout)/3
   nostop = 0
   FOR isatoi = 0, ntoi-1, 10 DO begin
      print, isatoi, ntoi
      tvsclu, cubout[ * , * , isatoi], /adj, min = mapmin,  max = mapmax ;, /self_minmax
      @continue_plot.pro
   endfor
endif

tvsclu,mean( cubout, dim = 3), /adj, /erase
;;cuptr = ptr_new( cubout,/no_copy)
;;slicer3, cuptr,data_names = ['cubout']

;; xinteranimate, set = [nout, nout, ntoi], /showload
;; FOR isatoi = 0, ntoi- 1 DO $
;;   xinteranimate, frame = isatoi, image = cuboutA[ * , * ,isatoi]
;; xinteranimate, /keep_pixmaps

;stop
fsampling = 1D0/median( deriv( toin.mjd))/86400. ; Hz
help, fsampling
IF keyword_set( pfi.k_gif_animated) THEN BEGIN
  filegif = $
     pfi.k_gif_dir+'KidCartoon_' + pfi.k_source +  '_' + $
     strmid( pfi.k_file, 0, 28) + '.gif' 
  print, 'writing gif file : ', filegif
;  prepare_jpgout, 29, ct = 15, xsiz = nout, ysiz = nout ; square window
  prepare_jpgout, 29, ct = 3, xsiz = nout, ysiz = nout, /norever; square window
  if keyword_set( pfi.k_gif_accel) then $
     accel = float( pfi.k_gif_accel) else accel = 1.
  delay_time = step/ fsampling * 100 / accel
; in 1/100th of seconds : Here do it at nominal speed
;  mintv = 1.D-10                ; min( cubout)
  maxtv = max( cubout)/2
  mintv = maxtv/10
;     a = minmax10( cubout)
;     mintv = a[0] 
;     maxtv = a[1]
    if keyword_set( pfi.k_gif_min) then mintv = pfi.k_gif_min
    if keyword_set( pfi.k_gif_max) then maxtv = pfi.k_gif_max
    FOR  isatoi = 0, ntoi- 1 DO  BEGIN 
       ima = reform(cubout[ * , * , isatoi])
       edge = where( sobel( ima eq 0.) ne 0., nedge)
       if nedge ne 0 then ima[ edge] = maxtv/3
       tvsclu,ima, min = mintv, max = maxtv
       write_gif, filegif, tvrd(), $
                  delay_time = delay_time, /multiple, REPEAT_count = 0
    ENDFOR
    write_gif, filegif, /close
 ENDIF



return
end
