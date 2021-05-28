pro nk_make_film, kidpar, param, data, info, pfi, $
                  film, debug = debug, cubout = cubout
                         
; Make a film (started from Pro/Make_film.scr and then nika_pipe_make_film in Modules)
; Need to set min, max 
; Project camera  data on a regular grid to prepare for a film
; k_film_sm is a smoothing duration (resampled to k_film_sm/2)
; k_film_darcsec  is the image pixel in arcseconds
; k_film_size is the size of the image in arcseconds
; All in a structure pfi

  nodef = 0.001
  
; Choose the selection of good kids
case strupcase( pfi.k_choice) of
     'A1': cho = 'A1'
     'A2': cho = 'A2'
     'A3': cho = 'A3'
     '1MM': cho = '1MM'
     '2MM': cho = '2MM'
     'ALL': cho = ['1MM', '2MM', 'A1', 'A3']
     else: begin
        print, 'Not a good choice for k_choice parameters'+pfi.k_choice
        return
     end
  endcase


ncho = n_elements( cho)
for icho = 0, ncho-1 do begin
   case strupcase( cho[ icho]) of
      'A1': indkid = where( kidpar.array eq 1 and kidpar.type eq 1,  nbkid)
      'A2': indkid = where( kidpar.array eq 2 and kidpar.type eq 1,  nbkid)
      'A3': indkid = where( kidpar.array eq 3 and kidpar.type eq 1,  nbkid)
      '1MM': indkid = where( kidpar.lambda le 1.5 and kidpar.type eq 1,  nbkid)
      '2MM': indkid = where( kidpar.lambda gt 1.5 and kidpar.type eq 1,  nbkid)
      else: begin
         print, 'Not a good choice for k_choice parameters'+pfi.k_choice
         return
      end
   endcase
   
   if nbkid lt 1 then begin
      print, 'No valid kids found for '+ cho[ icho]
      print, nbkid
      return
   endif
   
   
   ntoi = n_elements( data.toi[0])
; Smooth the data and resample
   toi = replicate( {sig:fltarr( nbkid), $
                     xx: fltarr(nbkid), yy: fltarr(nbkid)}, ntoi)
   
   FOR jkid = 0, nbkid-1 DO BEGIN
      ikid = indkid[ jkid]
      br = data.toi[ ikid]
      fl = data.flag[ ikid]
      if strtrim( strupcase( info.obs_type), 2) eq 'FOCUS' then begin
         u = where( fl eq 1, nu) ; means on source
         if nu ne 0 then fl[u] = 0
      endif

      badproj = where( fl gt 0 or br eq !undef,  nbadproj)
      goodproj = where( fl eq 0 and br ne !undef,  ngoodproj)
; interpolate on bad data
      if ngoodproj ne 0 then begin
         if nbadproj ne 0 then $
            br[ badproj] = interpol( br[ goodproj],  goodproj, badproj)
         toi.sig[ jkid] = smooth( br, pfi.k_film_sm, /edge_trunc)
;     if pfi.k_film_rmbase then $
;        toi.sig[ jkid] = toi.sig[ jkid]- $
;             smooth( toi.cm[ jkid], pfi.k_film_sm, /edge_trunc) ; else $
;        toi.sig[ jkid] = toi.sig[ jkid]-smooth( br, 121, /edge_trunc)
         toi.xx[ jkid] = smooth( data.dra[ ikid], pfi.k_film_sm, /edge_trunc)
         toi.yy[ jkid] = smooth( data.ddec[ ikid], pfi.k_film_sm, /edge_trunc)
      endif else toi.sig[ jkid] = 0 ;;;!undef
   ENDFOR

   if not pfi.k_notruncate then begin
      step = pfi.k_film_sm/2
      indres = (lindgen( ntoi/ step - 46) + 23) * step  
; forget the first and last seconds (unless user wants everything)
      toi = toi[ indres]
   endif
   ntoi = n_elements( toi)
   nout = 2*nint(pfi.k_film_size / pfi.k_film_darcsec) + 1
   if icho eq 0 then print, ntoi, ' images in the film'
   
   if icho eq 0 then cubout = fltarr( nout, nout, ntoi, ncho)  
   
   
; Loop on final image
   for isatoi = 0,  ntoi- 1 do begin
; if isatoi mod 100 eq 0 then print, isatoi, ntoi
      goodim = where( toi[ isatoi].sig ne 0,  ngoodim)
      if ngoodim ne 0 then begin
         cubout[ *, *, isatoi, icho] = $
; tri_surf gives negative rebounces , No see below
            tri_surf(  toi[ isatoi].sig[ goodim],  /linear, $
;           min_curve_surf(  toi[ isatoi].sig[ goodim],  $
                       (toi[ isatoi].xx[ goodim] - pfi.k_cx),  $
                       (toi[ isatoi].yy[ goodim] - pfi.k_cy),  $
                       gs = [pfi.k_film_darcsec,  pfi.k_film_darcsec], $
                       bound = 1. * [-1,  -1, +1, +1] * pfi.k_film_size, $
                       missing = nodef)
;if isatoi mod 5 eq 0 then plot,xoff*3600,yoff*3600,psym=4,  xrang = pfi.k_film_size * [-.5, .5], yrang = pfi.k_film_size * [-.5, .5],  title = strtrim(ipl, 2)
;ipl = ipl + 1
;if ipl mod 45 eq 44 then begin
; @continue_plot
;endif
      endif
      
   endfor
                                ; sample loop
   
endfor
                                ; icho loop

a = minmax10( cubout)
mintv = a[0] 
maxtv = a[1]
if keyword_set( pfi.k_gif_min) then mintv = pfi.k_gif_min
if keyword_set( pfi.k_gif_max) then maxtv = pfi.k_gif_max

   nx = nout
   ny = nout
   if ncho ne 1 then begin
      nx = nout*2
      ny = nout*2
   endif
   
if keyword_set( debug) then begin
  prepare_jpgout, 20, ct = 3, xsiz = nx, ysiz = ny, /norever; square window
   wshet, 20
   loadct, 39
   erase
   nostop = 0 
   if not pfi.k_notruncate then istep = 10 else istep = 1
   FOR isatoi = 0, ntoi-1, istep DO begin
      print, isatoi, ntoi
      for icho = 0, ncho-1 do $
         tvsclu, cubout[ * , * , isatoi, icho], icho, $;/adj, $
              min = mintv,  max = maxtv, /prof;, /self_minmax
      cont_plot,  nostop = nostop
   endfor
endif

tagn = tag_names( data)
u = where( strmatch( tagn, 'MJD'), nu)
if nu ne 0 then fsampling = 1D0/median( deriv( data.mjd))/86400. else $; Hz
 fsampling = 0.1 ; default
IF pfi.k_gif_animated eq 1 THEN BEGIN
  filegif = $
     pfi.k_gif_dir+'KidCartoon_' + pfi.k_source +  '_' + $
     strmid( pfi.k_file, 0, 28) +'_'+ strupcase( pfi.k_choice)+ '.gif' 
  print, 'writing gif file : ', filegif
  prepare_jpgout, 29, ct = 3, xsiz = nx, ysiz = ny, /norever; square window
  if keyword_set( pfi.k_gif_accel) then $
     accel = float( pfi.k_gif_accel) else accel = 1.
  delay_time = step/ fsampling * 100 / accel
; in 1/100th of seconds : Here do it at nominal speed
;  mintv = 1.D-10                ; min( cubout)
  FOR  isatoi = 0, ntoi- 1 DO  BEGIN
     for icho = 0, ncho-1 do begin
       ima = reform(cubout[ * , * , isatoi, icho])
       edge = where( sobel( ima eq nodef) ne 0.0, nedge)
       if nedge ne 0 then ima[ edge] = maxtv/3.
       tvsclu, ima, icho, min = mintv, max = maxtv
    endfor
    write_gif, filegif, tvrd(), $
                  delay_time = delay_time, /multiple, REPEAT_count = 0
   ENDFOR
   write_gif, filegif, /close
 ENDIF
IF pfi.k_gif_animated eq 2 THEN BEGIN
  filemp4 = $
     pfi.k_gif_dir+'KidCartoon_' + pfi.k_source +  '_' + $
     strmid( pfi.k_file, 0, 28) +'_'+ strupcase( pfi.k_choice)+ '.mp4' 
  print, 'writing mp4 file : ', filemp4
  prepare_jpgout, 29, ct = 3, xsiz = nx, ysiz = ny, /norever; square window
;  delay_time = step/ fsampling
  oVid = IDLffVideoWrite(filemp4, FORMAT='mp4')
  fps = fsampling
  vidStream = oVid.AddVideoStream(nx, ny, fps)

  FOR  isatoi = 0, ntoi- 1 DO  BEGIN
     for icho = 0, ncho-1 do begin
        ima = reform(cubout[ * , * , isatoi, icho])
        edge = where( sobel( ima eq nodef) ne 0.0, nedge)
        if nedge ne 0 then ima[ edge] = maxtv/3.
        tvsclu, ima, icho, min = mintv, max = maxtv
     endfor
     !NULL = oVid.Put(vidStream, tvrd(true = 1)) 
  ENDFOR
  oVid.Cleanup
ENDIF

return
end
