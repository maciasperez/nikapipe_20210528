pro focal_plane_match, dirin, kidparin, dirout, kidparout, $
                   inter = inter, noplot = noplot, $
                   nostop = nostop,  plotname = k_plotname
; Try to match focal plane of kidpar with the design of kids.
; Automatic processing with the 3 arrayswere written
;   Improve the interactive finding by using a set of parameters obtained
;   previously (either a previous run or a different iteration)
; Routine made out of FXD/N2R9/FP_auto1.scr script
;-------------------------------------------------
kidpar_dir = !nika.soft_dir+'/Kidpars/'  ; don't change that
; dirout= Local non-svn directory
; inter = 0                      ; default 0,  interactive or not (1 is costly)
; noplot = 0                      ; default 0,  1= no jpg are saved
outkid = 1                      ; 0 no output kid file, 1 save kid file
;;nostop                       ; 1 goes smoothly, 0 stops at each plot
dirguess = !nika.soft_dir+'/Kidpars/'   ; directory where an initial fit parameter file is ; don't change it

kpfname = dirin+'/'+kidparin

k_order = 1  ; order of the polynomial, 1 is secure, 3 is more experimental
savematch = 1 ; save the design matching

; Output kidpar
newkfname = dirout+ '/'+ kidparout

if keyword_set( k_plotname) then plotname = k_plotname else $
   plotname = kidparout

;----------------------------------------------------------------
; Program (should not be changed)
;----------------------------------------------------------------

if not file_test( kpfname) then message, kpfname+ ' does not exist'
kidpar = mrdfits( kpfname, 1, h)
kipfmt = {Match_NAME: '', $        ;   STRING    '1_0-1'
          NINFEED: -1, $
          Match_nas_x: 0., $
          Match_nas_y: 0., $
          Match_nx: 0, $
          Match_ny: 0, $
          Match_x: 0., $
          Match_y: 0., $
          Feed: 1}
   
upgrade_struct, kidpar, kipfmt, kidout
;kidout = kidpar
kidout.type = 10  ; default: 10 signals that a kid is not where it should be

ctall = 39                      ; Rainbow + white
prepare_jpgout, 15, /icon, /noreverse, $
                ct = ctall, xsize = 900, ysize = 900
prepare_jpgout, 16, /icon, /noreverse, $
                ct = ctall, xsize = 900, ysize = 900
prepare_jpgout, 17, /icon, /noreverse, $
                ct = ctall, xsize = 600, ysize = 600
for narr = 1, 3 do begin
   if narr eq 1 then begin
      fileout = 'NIKA2_1mm_MS_Design.save'
      fna = 'ar1'               ; extension of filenames
      fileguess = 'Focal_plane_'+fna+'_N2R9v3_result.save'
      gname = 'Array 1 - 1 mm'  ; graphical title
      signx = -1 
      signy = -1
      alp = -76.2/!radeg
      dmax = 3.    ; arcsec (threshold above which a Kid is excluded) take 12/4
      radius_det = 8.          ; big enough to fill the holes in the middle 
; another better explanation is distance_between_detectors*sqrt(2)/2 + 1 arcsec      
   endif
   if narr eq 3 then begin
      fileout = 'NIKA2_1mm_MS_Design.save'
      fna = 'ar3'               ; extension of filenames
      fileguess = 'Focal_plane_'+fna+'_N2R9v3_result.save'
      gname = 'Array 3 - 1 mm'  ; graphical title
      signx = +1                ; 
      signy = -1
      alp = -76.2/!radeg
      dmax = 3.              ; arcsec (threshold above which a Kid is excluded)
      radius_det = 8.          ; big enough to fill the holes in the middle
   endif
   if narr eq 2 then begin
      fileout = 'NIKA2_2mm_v2_MS_Design.save'  ; new design
      fna = 'ar2'               ; extension of filenames
      fileguess = 'Focal_plane_'+fna+'_N2R9v3_result.save'
      gname = 'Array 2 - 2 mm'  ; graphical title
      signx = +1   
      signy = -1
      alp = -78/!radeg
      dmax = 4.              ; arcsec (threshold above which a Kid is excluded)
                                ; take 4. to avoid too much field distortion 
      radius_det = 12.          ; big enough to fill the holes in the middle
   endif
   dlim = 5.                   ; accept match if distance is less than 5 arcsec


; Should now involve a previous guess of the parameters
   restore, file = dirguess+'/'+fileguess ;, /verb
; degree, pp, qq, kp, indch, kida, indich
   ppguess = pp
   qqguess = qq
   delvarx, kp, indch, kida, indich

   restore, file = kidpar_dir + fileout ;, /verb
; Put distances in mm
   kp.x = kp.x/1000D0
   kp.y = kp.y/1000D0
   !p.multi = 0
   wshet, 15
   plot, psym = 8, symsize = 0.3, kp.nx, kp.ny, /iso
   gk = where( kp.ninfeed gt 0, ngk) 
   oplot, psym = 4, symsize = 1, col = 100, kp[gk].nx, kp[gk].ny

;----------------------------------------------------------------
; Try now with kidpar

   uu = where( kidpar.type eq 1 and kidpar.array eq narr, nuu)
   print, '; ', nuu, ' kids in array ', narr
   kida = kidpar[uu]
   wshet, 15
   plot, psym = 8, symsize = 0.6, kida.nas_x, kida.nas_y, /iso, xsty = 2, ysty = 2

;-------------------------------------------------------------------
; Method is just to guess the shift then go into the non-linear routine
;---------------------------
   
   xguess = compute_poly2d( kp.x, kp.y, ppguess)
   yguess = compute_poly2d( kp.x, kp.y, qqguess)
   match2d, kida.nas_x, kida.nas_y, xguess, yguess, idguessa, idguessb
   ddguess = sqrt((kida.nas_x-xguess[idguessb])^2 + $
                  (kida.nas_y-yguess[idguessb])^2)
   
   indgg = where( ddguess le dlim and $
                  kp.ninfeed ge 0 and kp.x gt -500, nindgg)
   
   xrange = [-300, +300.] 
   yrange = [-300, +300.]
; These two plots are a diagnosis. This is not used in the computation.
   wshet, 15
   plot, psym = 8, symsize = 0.7, xguess[gk], yguess[gk], $
         /iso, xsty = 1, ysty = 1, $
         xrange = xrange, yrange = yrange ; do x and y symmetry
   
   wshet, 16
   plot, psym = 8, symsize = 0.3, kida.nas_x, kida.nas_y, $
         /iso, xsty = 1, ysty = 1, $
         xrange = xrange,  yrange = yrange
   oplot, psym = 4, thick = 2, col = 100, xguess[ idguessb[ indgg]], $
          yguess[ idguessb[ indgg]]

;Make a grid of shift in x and y and look for best match of the center
   shstep = 2.  ; step in arcseconds
   nsh = 11
   xsh = (-nsh/2+findgen(nsh))*shstep  ; in arcseconds
   ysh = xsh  ;square grid
   msh = intarr(nsh, nsh)  ; output number of matches
   xosh = fltarr(nsh, nsh) ; output x shift
   yosh = xosh             ; output y shift
   for ish = 0, nsh-1 do begin
      for jsh = 0, nsh-1 do begin
         match2d, kida.nas_x, kida.nas_y, $
                  xguess[gk]+xsh[ish], yguess[gk]+ysh[jsh], ida, idb
         dd = sqrt((kida.nas_x-xguess[gk[ idb]])^2 + $
                   (kida.nas_y-yguess[gk[ idb]])^2)
         igd = where( dd le dmax, ngd)
         msh[ ish, jsh] = ngd
         xosh[ ish, jsh] = xsh[ ish]
         yosh[ ish, jsh] = ysh[ ish]
      endfor
   endfor
; A bit long in cpu but ok (my old pc)
   aux = max(msh, imax)
   xshbest = xosh[ imax]
   yshbest = yosh[ imax]
   print, 'Best shift is : ', xshbest,  yshbest, ' arcseconds'
; Best match is thus:
        match2d, kida.nas_x, kida.nas_y, $
                  xguess[gk]+xshbest, yguess[gk]+yshbest, ida, idb
         dd = sqrt((kida.nas_x-xguess[gk[ idb]])^2 + $
                   (kida.nas_y-yguess[gk[ idb]])^2)
         igd = where( dd le dmax, ngd)
         indich = igd
         indch = gk[ idb[ igd]]
   gdall = where( kp.ninfeed ge 0 and kp.x gt -500, ngdall)
   gd = where( kp.ninfeed ge 0 and kp.x gt -500, ngd)
   nch = n_elements( indich)

;----------------------------

; Iterate start here 
   fplane, dlim, gk, ngk, gdall, ngdall, gd, ngd, $
           kida, indich, kp, indch, nch, degree, $
           pp, qq, xg, yg, ida, idb, dd, nostop = nostop
   degree = 1                   ; good to repeat
   fplane, dlim, gk, ngk, gdall, ngdall, gd, ngd, $
           kida, indich, kp, indch, nch, degree, $
           pp, qq, xg, yg, ida, idb, dd, nostop = nostop
   if k_order gt 1 then begin 
      degree = 2
      fplane, dlim, gk, ngk, gdall, ngdall, gd, ngd, $
              kida, indich, kp, indch, nch, degree, $
              pp, qq, xg, yg, ida, idb, dd, nostop = nostop
   endif
   if k_order gt 2 then begin
      degree = 3
      fplane, dlim, gk, ngk, gdall, ngdall, gd, ngd, $
              kida, indich, kp, indch, nch, degree, $
              pp, qq, xg, yg, ida, idb, dd, nostop = nostop
   endif
; Make different plots
   xg = compute_poly2d( kp.x, kp.y, pp)
   yg = compute_poly2d( kp.x, kp.y, qq)
   match2d, kida.nas_x, kida.nas_y, xg, yg, ida, idb
   dd = sqrt((kida[ ida].nas_x-xg)^2 + (kida[ ida].nas_y-yg)^2)

   indgood = where( dd le dmax and kp.ninfeed ge 0 and kp.x gt -500, nindgood)
   print, '; ', nindgood, ' pixels within ', dmax, $
          ' arcsec of their nominal position'
   print, ';  from a total of ',  ngk, ' and total of known kids of ', nuu
   print, ';   fraction of well-placed kids over total of known kids', $
          nindgood/float( nuu)
   print, ';   fraction of well-placed kids over total kids', $
          nindgood/float( ngk)
   indbad = where( dd gt dmax and kp.ninfeed ge 0 and kp.x gt -500, nindbad)
   print, '; ', nindbad, ' pixels out of ', dmax, $
          ' arcsec of their nominal position'

; Plot good pixels
   wshet, 16
   plot, psym = 8, symsize = 0.4, $
         xg[ gk], yg[ gk], $
         /iso, xsty = 2, ysty = 2, /nodata,  $
         xtitle = 'Nasmyth x [arcsec]',  ytitle = 'Nasmyth y [arcsec]', $
         title = gname+ ' Yellow diamond is observed position'
   oplot, psym = 8, symsize = 0.4, col = 100, xg[ gk], yg[ gk]
   oplot, psym = 8, symsize = 0.8,  xg[ indgood],  yg[ indgood]
   oplot, psym = 4, symsize = 1, col = 200, $
          kida[ ida[ indgood]].nas_x, kida[ ida[ indgood]].nas_y
; Try to plot bad pixels:
   bool = bytarr( n_elements( kida))+1B
   bool[ ida[ indgood]] = 0B 
   badin = where( bool, nbadin)
   print, nbadin, ' badly placed kids (green stars) with name and numdet= '
   print, kida[ badin].name
   print, kida[ badin].numdet
   if nbadin ne 0 then oplot, psym = 2, symsize = 1., col = 150, $
          [kida[ badin].nas_x], [kida[ badin].nas_y]
   if not keyword_set( noplot) then $
      jpgout, !nika.save_dir+'/Focal_plane_'+fna+'_'+plotname+'_goodpix.jpg',/over

; Select the good pixels in the kid par
   kidout[ uu[ ida[ indgood]]].type = 1

; Can remove the glitch in array 1
; find the glitch in array 1
   bad = where( kida[ida[indgood]].frequency*1e-5 gt 2200 and $
                kp[indgood].ninfeed lt 50, nbad)
   print, nbad, ' must be 0',  ' ;   0 NO MORE BAD kids? '
   if nbad ne 0 then begin
      print, bad,  indgood[bad], ida[ indgood[bad]], $
             uu[ida[indgood[bad]]] 
      ukid = uu[ida[indgood[bad]]] 
      kidout[ ukid].type = 10   ; back to bad...
      print, 'Numdet = ', kidout[ ukid].numdet, '; freq [MHz] = ', $
             kidout[ ukid].frequency*1e-5,  ' was blanked (glitch)'
   endif

   wshet, 15
   histo_make, dd[gk], /plot, /stat, /print, $
               min_val = 0.00001, max_val = 20., n_bins = 40, $
               xtitle = 'Distance [arcsec]', ytitle = 'Number of Kids'
   if not keyword_set( noplot) then $
      jpgout, !nika.save_dir+'/Focal_plane_'+fna+'_'+plotname+'_histodd.jpg',/over
   gd = where( kp.ninfeed ge 0 and kp.x gt -500 and dd lt dlim, ngd)
   ;print, ngd, ' are found'
   histo_make, dd[gd], /plot, /stat, /print
   if not keyword_set( noplot) then $
      jpgout, !nika.save_dir+'/Focal_plane_'+fna+'_'+plotname+'_histodd2.jpg',/over

; Find the field distortion
; Draw the field of non-linearity of the mapping with arrow
   ppred = pp[0:1, 0:1]
   qqred = qq[0:1, 0:1]
   ppred[1, 1] = 0. ; Not part of the linear solution
   qqred[1, 1] = 0.
   xgred = compute_poly2d( kp.x, kp.y, ppred)
   ygred = compute_poly2d( kp.x, kp.y, qqred)
   sca = 5.  ; Amplify the field distortion by a factor 5
   xgsca = xg+ (xgred-xg)*sca
   ygsca = yg+ (ygred-yg)*sca

   wshet, 16
 ;  gk1 = gk[ indgen(ngk/2)*2]
   gk1 = gk
   plot, psym = 3, symsize = 1, xg[gk1], yg[gk1], /iso, $
         xsty = 2, ysty = 2, $
         xtitle = 'Nasmyth x [arcsec]',  ytitle = 'Nasmyth y [arcsec]', $
         title = 'Distortion '+gname
   arrow, xg[gk1], yg[gk1], xgsca[gk1], ygsca[gk1], /data, hsize = -0.3
   xyouts, -150, -190, 'Scaled by '+strtrim( nint(sca), 2)
   if not keyword_set( noplot) then $
      jpgout, !nika.save_dir+'/Focal_plane_'+fna+'_'+plotname+'_distortion.jpg',/over
   wshet, 15
   plot, psym = 3, symsize = 1, xgred[gk1], ygred[gk1], /iso, $
         xsty = 2, ysty = 2, $
         xtitle = 'Nasmyth x [arcsec]',  ytitle = 'Nasmyth y [arcsec]', $
         title = 'Distortion '+gname
   arrow, xgred[gk1], ygred[gk1], xgsca[gk1], ygsca[gk1], /data, hsize = 7
   xyouts, -150, -190, 'Scaled by '+strtrim( nint(sca), 2)

; Distribution of the field distortion
   ddis = sqrt( (xg-xgred)^2 + (yg-ygred)^2)
   wshet, 16
   histo_make, ddis[ gdall ], /plot, /stat, /print, $
               xstyle = 2, ystyle = 2, $
               thick = 2, xtitle = 'Distortion [arcsec]', $
               ytitle = 'Number of pixels', title = gname
   if not keyword_set( noplot) then $
      jpgout, !nika.save_dir+'/Focal_plane_'+fna+'_'+plotname+'_distortion2.jpg',/over


; Find linear parameters
   ; center of field
   xcent = compute_poly2d( 0., 0., pp)  ;  = pp[0,0]  GK
   ycent = compute_poly2d( 0., 0., qq)  ;  = qq[0,0]  GK

   ; Scaling
   cx = sqrt( pp[0, 1]^2 + qq[0, 1]^2)
   cy = sqrt( pp[1, 0]^2 + qq[1, 0]^2)

   ; Angle
   beta = !radeg* atan( -signy*qq[0, 1], signx*pp[0, 1])
   betacheck = !radeg* atan( signy*pp[1, 0], signx*qq[1, 0])-180.*(signx+1)/2
; Now clear why the sign of this angle is opposite of alp (has to do
; with signx and signy)

   print, '; Array ', strtrim(narr, 2), ' center in Nasmyth coordinates: ', $
          string( xcent, ycent, format = '(2F8.1)'), ' arcsec'
   print, '; Scaling in x, y, avg ', string( cx, cy,  (cx+cy)/2,  format = '(3F8.2)'), ' arcsec/mm'
   print, '; Rotation of the array (design-->Nasmyth) x, y, avg '
   print, '; ', $
          string( beta,  betacheck, (beta+betacheck)/2, format = '(3F8.1)'), $
          ' degrees'

; Find which kid is near the center in Nasmyth coord: xcent, ycent
   dcent = sqrt( (kida.nas_x-xcent)^2+(kida.nas_y-ycent)^2)
; Find which kid was chosen
   dnas = sqrt( kida.nas_x^2+kida.nas_y^2)
   ucent = where( dcent lt 10., nucent)
   print, 'Kids near the design center'
   print, kida[ ucent].name, kida[ ucent].numdet, dcent[ ucent]
   unas = where( dnas lt 10.,  nunas)
   print,  'Kids near the Nasmyth coordinate center'
   print, kida[ unas].name, kida[ unas].numdet, dnas[ unas]



; Check frequency of kids
   wshet, 15
   plot, kp[indgood].ninfeed, kida[ida[indgood]].frequency*1e-5, $
         xsty = 2, ysty = 2, /ynoz, $
         xtitle = 'Number in feedline', ytitle = 'Kid Freq. [obs MHz]', $
         title = gname,  psym = 4
   nfeed = max( kp[ indgood].feed)
   indfeed = indgen(nfeed)+1
   ;print, nfeed, ' feeds found'
   for i = 1, nfeed do begin
      u = where( kp[indgood].feed eq i, na)
      a = sort( kp[indgood[u]].ninfeed)
      if na gt 1 then oplot, psym = -4, symsize = 0.5, col = 30*i,  $
                             kp[indgood[u[a]]].ninfeed, $
                             kida[ida[indgood[u[a]]]].frequency*1e-5
   endfor
   legendastro, strtrim( indfeed, 2), $
                line=replicate( 0, nfeed), col=30*indfeed, thick=2, box=0, $
                /right, /bottom, charsize=1.5,  charthick=1.5
   if not keyword_set( noplot) then $
      jpgout, !nika.save_dir+'/Focal_plane_'+fna+'_'+plotname+'_frequencies.jpg',/over
   wshet, 16
   gdc0 = where( dd le dmax and kp.ninfeed ge 0 and kp.x gt -500 $
                 and kida[ida].c0_skydip lt 0)
   plot, kp[gdc0].ninfeed, -kida[ida[gdc0]].c0_skydip*1e-6, $
         xsty = 2, ysty = 2, /ynoz, $
         xtitle = 'Number in feedline', ytitle = 'Kid Freq. [c0 MHz]', $
         title = gname,  psym = 4, $
         yrange = minmax( kida[ida[indgood]].frequency*1e-5)
   for i = 1, nfeed do begin
      u = where( kp[gdc0].feed eq i, na)
      a = sort( kp[gdc0[u]].ninfeed)
      if na gt 1 then oplot, psym = -4, symsize = 0.5, col = 30*i,  $
                             kp[gdc0[u[a]]].ninfeed, $
                             -kida[ida[gdc0[u[a]]]].c0_skydip*1e-6
   endfor
   legendastro, strtrim( indfeed, 2), $
                line=replicate( 0, nfeed), col=30*indfeed, thick=2, box=0, $
                /right, /bottom, charsize=1.5,  charthick=1.5
   if not keyword_set( noplot) then $
      jpgout, !nika.save_dir+'/Focal_plane_'+fna+'_'+plotname+'_frequencies2.jpg',/over

   if keyword_set( savematch) then begin
        ; Save the matched positions instead of the measured ones
      kidout[ uu[ ida[ indgood]]].nas_x = xg[ indgood]
      kidout[ uu[ ida[ indgood]]].nas_y = yg[ indgood]
   endif

                                ; Fill in the extended kidpar tagnames
   kidout[ uu[ ida[ indgood]]].Match_NAME = kp[ indgood].name
   kidout[ uu[ ida[ indgood]]].ninfeed = kp[ indgood].ninfeed
   kidout[ uu[ ida[ indgood]]].match_nas_x = xg[ indgood]
   kidout[ uu[ ida[ indgood]]].match_nas_y = yg[ indgood]
   kidout[ uu[ ida[ indgood]]].match_nx = kp[ indgood].nx
   kidout[ uu[ ida[ indgood]]].match_ny = kp[ indgood].ny
   kidout[ uu[ ida[ indgood]]].match_x = kp[ indgood].x
   kidout[ uu[ ida[ indgood]]].match_y = kp[ indgood].y
   kidout[ uu[ ida[ indgood]]].feed = kp[ indgood].feed


; Here compute the area covered by all kids (design value scaled by the
; measured scaling)

   matgk = bytarr(600, 600)
   dgkx = (findgen(600, 600) mod 600)-300.
   dgky = (lindgen(600, 600) / 600)-300.
   for igk = 0, ngk-1 do $
      matgk[ where(( (dgkx - xg[ gk[ igk]])^2 + $
                     (dgky - yg[ gk[ igk]])^2 ) le radius_det^2)] = 1
   wshet, 17
   tvsclu,matgk, minv=0.1, maxv=2.
   if not keyword_set( noplot) then $
      jpgout, !nika.save_dir+'/Focal_plane_'+fna+'_'+plotname+'_fov.jpg',/over
   areagk = total( matgk) ; square arcsec
   diameq = sqrt(areagk*4/!pi)/60. ; arcmin
   print, ';; Array diameter [arcmin] ', diameq

   ddet = sqrt(median( (xg[ gk]-shift(xg[ gk], 1))^2+ $
                       (yg[ gk]-shift(yg[ gk], 1))^2))
   sizdet = sqrt(median( (kp[ gk].x-shift(kp[ gk].x, 1))^2+ $
                         (kp[ gk].y-shift(kp[ gk].y, 1))^2))
   print, ';; Median distance between detectors [arcsec, mm] ', ddet, sizdet
   print, ';;   and in terms of lambda/D(27m) ', $
          ddet/(!nika.lambda[ (narr-1) mod 2]*1E-3/27.*!radeg*3600.)

; assuming D=30m
      cont_plot, nostop = nostop
endfor

fxd_ps
for narr = 1, 3 do begin
   tar = strtrim( narr, 2)
   ar = where( kidout.type eq 1 and kidout.array eq narr, nar)
   !p.multi = [0, 3, 3]
   plot, ar, kidout[ar].ninfeed, psym = -8, symsize = 0.4, $
         title = 'ninfeed, array '+tar, ysty = 0
   plot, ar, kidout[ar].feed, psym = -8, symsize = 0.4, $
         title = 'feed, run '+ plotname, ysty = 0
   plot, ar, kidout[ar].acqbox, psym = -8, symsize = 0.4,  $
         title = 'acqbox', ysty = 0
   plot, kidout[ar].feed, kidout[ar].acqbox, psym = 8,  $
         title = 'acqbox vs feed', ysty = 0, symsize = 0.4
   plot, /iso, kidout[ar].match_nas_x, kidout[ar].nas_x, psym = 8,  $
         title = 'Nas_x, Meas vs Pred.Match', ysty = 0, symsize = 0.4
   plot, /iso, kidout[ar].match_nas_y, kidout[ar].nas_y, psym = 8,  $
         title = 'Nas_y, Meas vs Pred.Match', ysty = 0, symsize = 0.4
   plot, /iso, kidout[ar].match_x, kidout[ar].match_y, psym = -8, $
         title = 'match_y vs match_x', ysty = 0, symsize = 0.4
   plot, /iso, kidout[ar].match_nx, -kidout[ar].match_ny, psym = -8, $
         title = '-match_ny vs match_nx', ysty = 0, symsize = 0.4
endfor

fxd_psout, save = !nika.save_dir+'/Focal_plane_'+fna+'_'+plotname+'_match.pdf',/over, /rotate


if keyword_set( outkid) then $
   mwrfits, kidout, newkfname, /create


return
end



;;;;---------------------------------------------------------------------
;; v3
;;          736 kids in array        1
;;        1       7.3263071       7.3263071       1.4498981
;;          674 are found within            5 arcseconds
;;         1140         674         299         145          22
;;        1       7.3600179       1.0762953       1.0221548
;;          674 are found within            5 arcseconds
;;         1140         674         307         135          24
;;          673 pixels within       3.00000 arcsec of their nominal position
;;  from a total of         1140 and total of known kids of          736
;;   fraction of well-placed kids over total of known kids     0.914402
;;   fraction of well-placed kids over total kids     0.590351
;;          467 pixels out of       3.00000 arcsec of their nominal position
;; n_used        1140.0000 n_defined         1140.0000
;; min         0.041425447 max           36.557062
;; mean          4.9605576 median        1.3976449
;; rms           5.4395484 sigma        0.16117623 drift     -0.0038528453
;; p10          0.45813698 p20          0.68200421 p30          0.87191635
;; p40           1.0688220 p50           1.3976449 p60           7.7957191
;; p70           9.1334028 p80           9.6249409 p90           10.388619
;; skewness        1.3993499 kurtosis        2.9748231
;; n_used        674.00000 n_defined         674.00000
;; min         0.041425447 max           3.9465429
;; mean         0.93880515 median       0.86543640
;; rms          0.52675246 sigma       0.020304815 drift    -0.00017782565
;; p10          0.34911385 p20          0.50407660 p30          0.64254081
;; p40          0.75021529 p50          0.86543638 p60          0.97342759
;; p70           1.0986164 p80           1.2746774 p90           1.6625220
;; skewness        1.1818008 kurtosis        2.3368304
;; n_used        1140.0000 n_defined         1140.0000
;; min        0.0029015972 max           1.5314471
;; mean         0.52119616 median       0.42430889
;; rms          0.41050120 sigma       0.012163332 drift     8.4522166e-08
;; p10         0.060695052 p20          0.11936296 p30          0.20919323
;; p40          0.31373024 p50          0.42430890 p60          0.56954777
;; p70          0.72758543 p80          0.90804088 p90           1.1558294
;; skewness       0.65272224 kurtosis      -0.64262463
;; Array 1 center in Nasmyth coordinates:      2.3    -4.5 arcsec
;; Scaling in x, y, avg     4.89    4.91    4.90 arcsec/mm
;; Rotation of the array (design-->Nasmyth) x, y, avg 
;;     77.3    77.3    77.3 degrees
;; KH097 KI019
;;         3137        3286
;;        8.7997553       9.4484252
;; KH096 KH097
;;         3136        3137
;;        5.9272675       5.7537767
;; Array diameter [arcmin]       6.63586
;; Median distance between detectors [arcsec, mm]        9.8039670      2.00000
;;   and in terms of lambda/D        1.2366608
;;          444 kids in array        2
;;        1       7.0505961       7.0505961       1.6110008
;;          438 are found within            5 arcseconds
;;          616         438           6         172           0
;;        1       7.1601860      0.91700382      0.84349531
;;          438 are found within            5 arcseconds
;;          616         438           2         176           0
;;          437 pixels within       4.00000 arcsec of their nominal position
;;  from a total of          616 and total of known kids of          444
;;   fraction of well-placed kids over total of known kids     0.984234
;;   fraction of well-placed kids over total kids     0.709416
;;          179 pixels out of       4.00000 arcsec of their nominal position
;; n_used        616.00000 n_defined         616.00000
;; min         0.036673656 max           18.612865
;; mean          4.3513812 median       0.88083013
;; rms           5.6908980 sigma        0.22947915 drift    -0.00099398788
;; p10          0.33416271 p20          0.46256539 p30          0.58870488
;; p40          0.72214311 p50          0.88083011 p60           1.1844926
;; p70           2.1528881 p80           12.728418 p90           13.226809
;; skewness       0.97836030 kurtosis      -0.90176286
;; n_used        438.00000 n_defined         438.00000
;; min         0.036673656 max           4.5532418
;; mean         0.77087538 median       0.65990702
;; rms          0.49720376 sigma       0.023784482 drift     8.0717634e-05
;; p10          0.29958346 p20          0.39829171 p30          0.48889151
;; p40          0.56831968 p50          0.65990704 p60          0.76099026
;; p70          0.86791557 p80           1.0438467 p90           1.3839333
;; skewness        2.1387545 kurtosis        8.9637261
;; n_used        616.00000 n_defined         616.00000
;; min        0.0070656301 max           1.9779054
;; mean         0.68338407 median       0.57231604
;; rms          0.53738107 sigma       0.021669296 drift     1.2840239e-19
;; p10         0.087142773 p20          0.14837824 p30          0.28121209
;; p40          0.41687217 p50          0.57231605 p60          0.72775990
;; p70          0.93972880 p80           1.2129332 p90           1.5332417
;; skewness       0.68553354 kurtosis      -0.58036750
;; Array 2 center in Nasmyth coordinates:      9.3    -7.5 arcsec
;; Scaling in x, y, avg     4.84    4.91    4.88 arcsec/mm
;; Rotation of the array (design-->Nasmyth) x, y, avg 
;;    -78.2   -78.3   -78.2 degrees
;; KD165        1474       166.58194
;; KC017         823       0.0000000
;; Array diameter [arcmin]       6.58509
;; Median distance between detectors [arcsec, mm]        13.343330      2.75000
;;   and in terms of lambda/D       0.97102604
;;          758 kids in array        3
;;        1       6.0011175       6.0011175       1.7459746
;;          736 are found within            5 arcseconds
;;         1140         736         292         109           3
;;        1       5.9679852       1.0661905       1.0561677
;;          736 are found within            5 arcseconds
;;         1140         736         314          88           2
;;          734 pixels within       3.00000 arcsec of their nominal position
;;  from a total of         1140 and total of known kids of          758
;;   fraction of well-placed kids over total of known kids     0.968338
;;   fraction of well-placed kids over total kids     0.643860
;;          406 pixels out of       3.00000 arcsec of their nominal position
;; n_used        1140.0000 n_defined         1140.0000
;; min         0.041958482 max           20.540179
;; mean          4.0598812 median        1.2106676
;; rms           4.3761869 sigma        0.12966836 drift    -0.00099851103
;; p10          0.42743769 p20          0.61571962 p30          0.80702740
;; p40          0.97229570 p50           1.2106676 p60           1.7923355
;; p70           8.8061705 p80           9.3307962 p90           9.8010674
;; skewness       0.80494173 kurtosis      -0.75550452
;; n_used        736.00000 n_defined         736.00000
;; min         0.041958482 max           4.7287529
;; mean         0.92160037 median       0.83568757
;; rms          0.53647541 sigma       0.019788194 drift    -9.5484746e-05
;; p10          0.33537304 p20          0.49470520 p30          0.60714960
;; p40          0.71550316 p50          0.83568758 p60          0.94378191
;; p70           1.0780227 p80           1.2790896 p90           1.5856096
;; skewness        1.4224958 kurtosis        4.2667642
;; n_used        1140.0000 n_defined         1140.0000
;; min        0.0038375307 max           2.0254277
;; mean         0.68931216 median       0.56117313
;; rms          0.54291165 sigma       0.016086713 drift     1.1178547e-07
;; p10         0.080272734 p20          0.15786444 p30          0.27667019
;; p40          0.41492644 p50          0.56117314 p60          0.75325996
;; p70          0.96227396 p80           1.2009368 p90           1.5286515
;; skewness       0.65272224 kurtosis      -0.64262463
;; Array 3 center in Nasmyth coordinates:      2.0    -5.8 arcsec
;; Scaling in x, y, avg     4.86    4.90    4.88 arcsec/mm
;; Rotation of the array (design-->Nasmyth) x, y, avg 
;;    -76.4   -76.4   -76.4 degrees
;; KP017 KP018 KQ090 KQ091
;;         6026        6027        6730        6731
;;        9.8500022       8.2813287       9.4814313       7.7581972
;; KP017 KP018
;;         6026        6027
;;        5.7814365       4.3555890
;; Array diameter [arcmin]       6.61001
;; Median distance between detectors [arcsec, mm]        9.7354243      2.00000
;;   and in terms of lambda/D        1.2280149

