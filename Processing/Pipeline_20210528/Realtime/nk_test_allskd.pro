pro nk_test_allskd, fname, goodscan, kidparfile, newkidpar, runname, $
                    verbose = verbose, doplot = doplot, rmslim = rmslim, $
                    help = k_help

; Do a multi-scan fit of skydips from a given campaign (of name fname)
; Data must be reduced with nk_skydip_4 and put in a structure
; $SAVE/Test_skydip4_'+fname+'.save'
; goodscan is the index of the selected skydips within the ones in fname
; kidparfile is the full name of the fits file containing the proper campaign
;   configuration
; A new kidpar is output that can be later saved as a fits. Only c0 and c1 are
; modified 
; runname is just the chosen string to name the run or a subrun
; verbose=2 :very verbose, 1: essential info, 0: nothing
; doplot  : 0 nothing is drawn, 1 all plots, 2: stop at each plot
; rmslim  : used for sigma-clipping: 3 is recommended value and the default
; value
; /help: do nothing, just list the scans to prepare goodscan
; FXD April 2016
mpfitsil = 1  ; silent mode for mpfit
if keyword_set( verbose) then if verbose ne 1 then mpfitsil = 0 
if not keyword_set( rmslim) then rmslim = 3. ; up to 3 times more noisy are kept
fref = 1.9D9  ; Reference frequency in Hz (to avoid too large numbers)

restore, file = !nika.save_dir+'/Test_skydip_'+fname+'.save', /verb
ndoutkid = n_elements( dout[0].f_tone)

nscan = n_elements( skydipout)
if keyword_set( k_help) then begin
   for i=0, nscan-1 do print,i,' ',skydipout[i].scanname
   return
endif

am = 1/sin( dout.el)
npoint = n_elements( am)
nam = npoint/nscan
skydipout = skydipout[ goodscan]
a = lindgen(  nam, nscan)
gd = reform( a[ *, goodscan], n_elements( goodscan)*nam)
dout = dout[gd]



nscan = n_elements( skydipout)
am = 1/sin( dout.el)
npoint = n_elements( am)
nam = npoint/nscan

if keyword_set( doplot) then begin
   prepare_jpgout, 1, ct = 39, /norev, /icon
   prepare_jpgout, 2, ct = 39, /norev, /icon
   prepare_jpgout, 3, ct = 39, /norev, /icon
   prepare_jpgout, 4, ct = 39, /norev, /icon
endif
; Prepare data
freso = dout.f_tone+dout.df_tone
am = 1/sin( dout.el)
npoint = n_elements( am)
nscan = n_elements( skydipout)
;nscan = 3
nam = npoint/nscan
file = !nika.off_proc_dir+'/'+kidparfile
kidpar = mrdfits( file, 1)
ntotkid = n_elements( kidpar)
if ndoutkid lt ntotkid then message, 'restored dout does not have the correct number of kids'
val = total(finite( freso) and freso gt 1D9,  2)
c1lim = 6000.
c1min = 100. ; a lower limit on c1min (up to 6000)
c1st = 1000. ; starting point

for lamb = 1, 2 do begin ; loop on the 2 wavelengths
;for lamb = 2, 2 do begin ; 2mm only for debug
; Choose between

; 1mm
   if lamb eq 1 then lambt = '1 mm'
; 2mm
   if lamb eq 2 then lambt = '2 mm'

   if lamb eq 1 then $
      valmax = max( val[ where(kidpar.type eq 1 and kidpar.lambda lt 1.5)]) else $
         valmax = max( val[ where(kidpar.type eq 1 and kidpar.lambda gt 1.5)])   
   print, valmax, ' is number of valid points'
;valmax = 109 ; manually choose
   print, valmax, ' is chosen number of valid points'
   if lamb eq 1 then $
      kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                      kidpar.lambda lt 1.5, nallkid) else $
                         kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                                         kidpar.lambda gt 1.5, nallkid)

   print, nallkid, ' valid kids at '+lambt

; Limit the kids to 40 at a block 
   nbak = 40                    ; 40 kids put together
   if nallkid lt nbak then nbak = nallkid
   npak = nallkid/nbak
   if lamb eq 1 then taupak1 = fltarr( npak, nscan)
   if lamb eq 2 then taupak2 = fltarr( npak, nscan)

   for ipak = 0, npak-1 do begin
      ist = ipak*nbak
      ien = (ipak+1)*nbak
      if ipak eq (npak-1) then ien = nallkid-1
      print, 'Take kids from ', ist, ' to ', ien,  ' at '+lambt
;kid = kid[100:149]
      kid = kidall[ist:ien]
      nkid = n_elements( kid)
      print, nkid, ' chosen valid at '+lambt
      fstr = {nkid:nkid, nscan:nscan, nam:nam}
      ytot = reform( transpose( freso[ kid, *]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nscan)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim, -c1min] ; reasonable range
      for i = 0, nscan-1 do parinfo[i+2*nkid].limits=[0.D0,1.6D0] ; reasonable range
      e_r = replicate( 1.d3,  nkid*npoint)
      p_start = [( max( freso[ kid, *], dim = 2, /nan) < 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
                  skydipout[0:nscan-1].tiptau225GHZ>0.1]

      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, /nan, maxiter = 20)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set

      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nscan = nscan)
; Evaluate bad kids

      rmsfit = fltarr( nkid)
      npoint = nam*nscan
      outfit = dblarr( nkid*npoint)
      for ik = 0, nkid-1 do begin
         a = (yfit-ytot)[ik*npoint:(ik+1)*npoint-1]
         u = where( finite(a), nu)
         if nu ne 0 then begin
            rmsfit[ ik] = stddev( a[u])
            outfit[ ik*npoint:(ik+1)*npoint-1]= a/rmsfit[ik]
         endif

      endfor
                                ;print, rmsfit

      gdkid = where( rmsfit lt rmslim*median( rmsfit), ngdkid)
      print, ngdkid, ' good kids out of ', nkid

; Evaluate bad scans
      rmsfit2 = fltarr( nscan)
      npoint = nam*nscan
      ii = reform( lindgen( nam*nscan*nkid), nam, nscan,  nkid)
      for isc = 0, nscan-1 do begin
         ind = reform( ii[ *, isc, *], nkid*nam)
         u = where( (finite(yfit-ytot))[ind])
         rmsfit2[ isc] = stddev( (yfit-ytot)[ind[u]])
      endfor
                                ;print, rmsfit2

      gdscan = where( rmsfit2 lt rmslim*median( rmsfit2), ngdscan)
      print, ngdscan, ' good scans out of ', nscan, ' but all are kept'
      ngdscan = nscan
      gdscan = indgen( nscan)

; Evaluate bad points in a skydip
      alloutfit = fltarr( npoint)
      for ii = 0, npoint-1 do begin
         ind = ii+ npoint*indgen( nkid)
         a = outfit[ind]
         u = where( finite(a))
         alloutfit[ ii] = avg( abs( a[u]))
;         if alloutfit[ ii] gt rmslim then ytot[ ind] = !values.d_nan
      endfor
      badpt = where(  alloutfit gt rmslim, nbadpt)
      print, 'A total of ', nbadpt, ' bad points are eliminated'
      if nbadpt eq npoint then goto, noluck

; Try again with a better selection of kids and not changing selection of
; scans except for isolated points
      kid = kid[ gdkid]
      nkid = n_elements( kid)
      allpoint = lindgen( nam, nscan)
      nscan = ngdscan
      npoint = nam*nscan
      gdpoint = reform( allpoint[ *, gdscan], npoint)

      fstr = {nkid:nkid, nscan:nscan, nam:nam}
      ftemp = freso[ kid, *]
      if nbadpt ne 0 then ftemp[*, badpt] = !values.d_nan
      ytot = reform( transpose( ftemp[ *, gdpoint]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nscan)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim,c1min] ; reasonable range
      for i = 0, nscan-1 do parinfo[i+2*nkid].limits=[0.D0,1.7D0] ; reasonable range
      e_r = replicate( 1.d3,  nkid*npoint)
;; p_start = [ replicate( 2D9, nkid), replicate(-1000.D0, nkid), $
;;             skydipout[0:nscan-1].tiptau225GHZ>0.1]
      p_start = [ ( max( freso[ kid, *], dim = 2, /nan)< 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
                  skydipout[gdscan].tiptau225GHZ>0.1]
; Limit iterations
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, /nan, maxiter = 30)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set
      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nscan = nscan)

; Evaluate bad kids

      rmsfit2 = fltarr( nkid)
      npoint = nam*nscan
      for ik = 0, nkid-1 do begin
         a = (yfit-ytot)[ik*npoint:(ik+1)*npoint-1]
         u = where( finite(a), nu)
         if nu gt 10 then rmsfit2[ ik] = stddev( a[u])
      endfor
                                ;print, rmsfit2

      gdkid2 = where( rmsfit2 gt 0 and rmsfit2 lt rmslim*median( rmsfit2), ngdkid2)
      print, ngdkid2, ' good kids out of ', nkid

; Evaluate bad scans
      rmsfit2 = fltarr( nscan)
      npoint = nam*nscan
      ii = reform( lindgen( nam*nscan*nkid), nam, nscan,  nkid)
      for isc = 0, nscan-1 do begin
         ind = reform( ii[ *, isc, *], nkid*nam)
         u = where( (finite(yfit-ytot))[ind], nu)
         if nu gt 1 then rmsfit2[ isc] = stddev( (yfit-ytot)[ind[u]]) else $
            print, isc,  nscan, nu
      endfor
                                ;print, rmsfit2

      gdscan2 = where( rmsfit2 lt rmslim*median( rmsfit), ngdscan2)
      print, ngdscan2, ' good scans out of ', nscan


; Plots
if keyword_set( doplot) then begin
      wshet, 3
      !p.multi = [0, 2, 2]
      nind = 4
      ind = 0+indgen( nind)
      ipt = indgen( npoint) ;;;nam*0+indgen(nam*3)
      Tsky = 270.*(1-exp(-am*(replicate(1D0, nam)#fit[ 2*nkid:*])))
      for i = 0, nind-1 do begin
         ik = ind[ i]
         title = 'NIKA2 '+ runname
         if i eq 0 then $
            title = '4 Kids in Block '+strtrim(ipak, 2)+ ' at '+lambt
         plot, psym = 4, Tsky[ipt], ytot[ik*npoint+ipt], $
               xra = [0, 300], ysty = 16, $
               xtitle = 'Tsky [K]', $
               ytitle = 'Freso-1.9GHz [Hz]', $
               title = title
         oplot, psym = -3, Tsky[ipt], yfit[ik*npoint+ipt], col = 100
      endfor
      print, 'New tau, tau225, one-scan_tau'
      for isc = 0, nscan-1 do $
         print, fit[2*nkid+isc], skydipout[gdscan[isc]].tiptau225GHZ, $
                skydipout[gdscan[isc]].tau1, format = '(3F8.3)'

      wshet, 4
      !p.multi = 0
      if lamb eq 1 then begin 
         plot, fit[2*nkid:*], skydipout[gdscan].tiptau225GHZ, $
               psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, $
               xtitle = 'Tau 1mm (multi-scan)', $
               ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
               title = 'NIKA2 '+ $
               runname+ ', Block '+strtrim(ipak, 2)+ ' at '+lambt
         oplot, fit[2*nkid:*], skydipout[gdscan].tau1, col = 100, psym = 8
         oplot, [0, 1.7], [0, 1.7], psym = -3
      endif else begin
         plot, fit[2*nkid:*], skydipout[gdscan].tiptau225GHZ, $
               psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, $
               xtitle = 'Tau 2mm (multi-scan)', $
               ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
               title = 'NIKA2 R'+!nika.run
         oplot, fit[2*nkid:*], skydipout[gdscan].tau2, col = 100, psym = 8
         oplot, [0, 1.7], [0, 1.7], psym = -3
      endelse
      if doplot ge 2 then cont_plot, nostop = nostop
      ;;; if lamb eq 2 and ipak eq 0 then stop

   endif

      if lamb eq 1 then taupak1[ipak, *] = fit[2*nkid:*] else $
         taupak2[ipak, *] = fit[2*nkid:*]
noluck:
   endfor                       ;end loop on ipak
endfor                          ; end loop on lambda

taufinal1 = avg(taupak1, 0)
if npak gt 1 then etaufinal1 = stddev(taupak1, dim = 1) $
  else etaufinal1 = fltarr(nscan)
taufinal2 = avg(taupak2, 0)
etaufinal2 = stddev(taupak2, dim = 1)
print, median( etaufinal1),median( etaufinal2), ' dispersion on tau 1&2'
;    0.0300144     0.110962 dispersion on tau 1&2
if keyword_set( doplot) then begin
   wshet, 1
   !p.multi = [0, 2, 2]
   plot, taufinal1, skydipout[gdscan].tiptau225GHZ, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
         xtitle = 'Tau 1mm (multi-scan)', $
         ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
         title = 'NIKA2 '+runname, thick = 2, /iso
   oplot, taufinal1, skydipout[gdscan].tau1, col = 100, psym = 8
   oploterror, taufinal1,  skydipout[gdscan].tau1, etaufinal1, replicate(0, nscan), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3
   plot, taufinal2, skydipout[gdscan].tiptau225GHZ,  /xsty, /ysty, /iso, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau 2mm (multi-scan)', $
         ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
         title = 'NIKA2 '+runname, thick = 2
   oplot, taufinal2, skydipout[gdscan].tau2, col = 100, psym = 8
   oploterror, taufinal2,  skydipout[gdscan].tau2, etaufinal2, replicate(0, nscan), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3
   plot, taufinal1, taufinal2,/iso, /xsty, /ysty, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau 1mm (multi-scan)', $
         ytitle = 'Tau 2mm (multi-scan)', $
         title = 'NIKA2 '+runname, thick = 2
   oploterror, taufinal1,  taufinal2, etaufinal1, etaufinal2, $
               errcolor = 200, psym = 3
   a = linfit(taufinal1, taufinal2)
   oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 150
   xyouts, .1, .7, 'Slope= '+string(a[1], format = '(1F5.2)')
   jpgout, !nika.save_dir+'/test_allskd_'+fname+'.jpg', /over
   print, 'zero point, slope tau2 vs tau1', a
;    0.0275618     0.571271
endif


; Now compute the coefficients of each kid to feed into new c0 and c1
newkidpar = kidpar
newkidpar.c0_skydip = 0.
newkidpar.c1_skydip = 0.
for lamb = 1, 2 do begin        ; loop on the 2 wavelengths
; Choose between

; 1mm
   if lamb eq 1 then lambt = '1 mm'

;;;       or
; 2mm
   if lamb eq 2 then lambt = '2 mm'
   if lamb eq 1 then $
      valmax = max( val[ where(kidpar.type eq 1 and kidpar.lambda lt 1.5)]) else $
         valmax = max( val[ where(kidpar.type eq 1 and kidpar.lambda gt 1.5)])   
   valmax = long(valmax)
   print, valmax, ' is found number of valid points'
   valch = ((4*nam) < (valmax-18)) > nam
   print, valch, ' is min chosen number of valid points'
   if lamb eq 1 then $
      kidall = where( val ge valch and kidpar.type eq 1 and $
                      kidpar.lambda lt 1.5, nallkid) else $
      kidall = where( val ge valch and kidpar.type eq 1 and $
                                         kidpar.lambda gt 1.5, nallkid)

   print, nallkid, ' valid at '+lambt
; Limit the kids to 40 at a block 
   nbak = 40                    ; 40 kids put together
   if nallkid lt nbak then nbak = nallkid
   npak = nallkid/nbak
   for ipak = 0, npak-1 do begin
      ist = ipak*nbak
      ien = (ipak+1)*nbak
      if ipak eq (npak-1) then ien = nallkid-1
      print, 'Take kids from ', ist, ' to ', ien,  ' at '+lambt
      kid = kidall[ist:ien]
      nkid = n_elements( kid)
      print, nkid, ' chosen valid at '+lambt

      fstr = {nkid:nkid, nscan:nscan, nam:nam}
      fref = 1.9D9
      ftemp = freso[ kid, *]
      ytot = reform( transpose( ftemp[ *, gdpoint]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nscan)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim,-c1min] ; reasonable range
      for i = 0, nscan-1 do parinfo[i+2*nkid].limits=[0.D0,1.6D0] ; reasonable range
      e_r = replicate( 1.d3,  nkid*npoint)
      if lamb eq 1 then tau = taufinal1 else tau = taufinal2
      p_start = [ ( max( freso[ kid, *], dim = 2, /nan)< 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
                  tau]

; Fix tau as the best values and compute better parameters
      for i = 0, nscan-1 do parinfo[i+2*nkid].fixed = 1
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, /nan, maxiter = 20)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set

      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nscan = nscan)

; Evaluate bad points in a skydip
      alloutfit = fltarr( npoint)
      for ii = 0, npoint-1 do begin
         ind = ii+ npoint*indgen( nkid)
         a = outfit[ind]
         u = where( finite(a))
         alloutfit[ ii] = avg( abs( a[u]))
      endfor
      badpt = where(  alloutfit gt rmslim, nbadpt)
      print, 'A total of ', nbadpt, ' bad points are eliminated'

      ftemp = freso[ kid, *]
      if nbadpt ne 0 then ftemp[*, badpt] = !values.d_nan
      ytot = reform( transpose( ftemp[ *, gdpoint]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nscan)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim,-c1min] ; reasonable range
      for i = 0, nscan-1 do parinfo[i+2*nkid].limits=[0.D0,1.6D0] ; reasonable range
      e_r = replicate( 1.d3,  nkid*npoint)
      if lamb eq 1 then tau = taufinal1 else tau = taufinal2
      p_start = [ ( max( freso[ kid, *], dim = 2, /nan)< 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
                  tau]

; Fix tau as the best values and compute better parameters
      for i = 0, nscan-1 do parinfo[i+2*nkid].fixed = 1
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, /nan, maxiter = 20)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set

      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nscan = nscan)




; Evaluate bad kids

      rmsfit = fltarr( nkid)
      npoint = nam*nscan
      for ik = 0, nkid-1 do begin
         a = (yfit-ytot)[ik*npoint:(ik+1)*npoint-1]
         u = where( finite(a))
         rmsfit[ ik] = stddev( a[u])
      endfor
                                ;print, rmsfit

      gdkid = where( rmsfit lt rmslim*median( rmsfit), ngdkid)
      print, ngdkid, ' good kids out of ', nkid

      newkidpar[ kid[ gdkid]].c0_skydip = -(fit[ gdkid]+fref)
      newkidpar[ kid[ gdkid]].c1_skydip = -fit[ nkid+gdkid]

; Evaluate bad scans
      rmsfit = fltarr( nscan)
      npoint = nam*nscan
      ii = reform( lindgen( nam*nscan*nkid), nam, nscan,  nkid)
      for isc = 0, nscan-1 do begin
         ind = reform( ii[ *, isc, *], nkid*nam)
         u = where( (finite(yfit-ytot))[ind])
         rmsfit[ isc] = stddev( (yfit-ytot)[ind[u]])
      endfor
;      print, rmsfit
      bdscan = where( rmsfit gt rmslim*median( rmsfit), nbdscan)
      print, nbdscan, ' bad scans out of ', nscan
      if nbdscan ge 1 then print, bdscan
      if nbdscan ge 1 then print, skydipout[ bdscan].scanname

   endfor                       ;end loop on ipak

endfor                          ; end loop on lambda

if keyword_set(doplot) then begin
; Plot new c1 against old c1
   wshet, 2
   !p.multi = [0, 2, 2]
   for lamb = 1, 2 do begin     ; loop on the 2 wavelengths
      if lamb eq 1 then lambt = '1 mm'
      if lamb eq 2 then lambt = '2 mm'
      if lamb eq 1 then $
         kidall = where( kidpar.type eq 1 and $
                         kidpar.lambda lt 1.5, nallkid) else $
                            kidall = where( kidpar.type eq 1 and $
                                            kidpar.lambda gt 1.5, nallkid)

      print, nallkid, ' valid at '+lambt
      plot, kidpar[ kidall].c1_skydip, newkidpar[ kidall].c1_skydip, $
            xrang = [0, c1lim], yrang = [0, c1lim], /xsty, /ysty, psym = 8, $
            /iso, xtitle = 'Response [Hz/K] one-scan', $
            ytitle = 'Response [Hz/K] multi-scan',  $
            title = 'NIKA2 '+runname+', c1 at '+ lambt, thick = 2
      a1 = where( kidpar[ kidall].array eq 1, na1)
      if na1 ne 0 then $
         oplot, kidpar[ kidall[a1]].c1_skydip, $
                newkidpar[ kidall[a1]].c1_skydip, psym = 4, col = 100
      a3 = where( kidpar[ kidall].array eq 3, na3)
      if na3 ne 0 then $
         oplot, kidpar[ kidall[a3]].c1_skydip, $
                newkidpar[ kidall[a3]].c1_skydip, psym = 4, col = 200
      gdk = where(kidpar[ kidall].c1_skydip gt 0. and $
                  newkidpar[ kidall].c1_skydip gt 0., ngdk)
      if ngdk ne 0 then begin
         slope = avg( newkidpar[ kidall[ gdk]].c1_skydip / $
                      kidpar[ kidall[ gdk]].c1_skydip)
         oplot, [0, c1lim], slope*[0, c1lim], psym = -3, col = 150
         xyouts, 1000, 3000, 'Slope= '+string(slope, format = '(1F5.2)')
      endif

      plot,1E-3/ newkidpar[ kidall].calib_fix_fwhm, newkidpar[ kidall].c1_skydip, $
           xrang = [0, 0.4], yrang = [0, c1lim], /xsty, /ysty, psym = 8, $
           xtitle = 'PS Response [Hz/(mJy/beam)]', $
           ytitle = 'Response [Hz/K] multi-scan',  $
           title = 'NIKA2 '+runname+', calib_fix_fwhm, c1 at '+ lambt, thick = 2
      a1 = where( kidpar[ kidall].array eq 1, na1)
      if na1 ne 0 then $
         oplot,1E-3/ newkidpar[ kidall[a1]].calib_fix_fwhm, $
               newkidpar[ kidall[a1]].c1_skydip, psym = 4, symsize = 2, col = 100
      a3 = where( kidpar[ kidall].array eq 3, na3)
      if na3 ne 0 then $
         oplot,1E-3/ newkidpar[ kidall[a3]].calib_fix_fwhm, $
               newkidpar[ kidall[a3]].c1_skydip, psym = 4, symsize = 1, col = 200
      gdk = where(newkidpar[ kidall].calib_fix_fwhm gt 0. and $
                  newkidpar[ kidall].c1_skydip gt 0., ngdk)
      if ngdk ne 0 then begin
         slope = avg( newkidpar[ kidall[ gdk]].c1_skydip * $
                      newkidpar[ kidall[ gdk]].calib_fix_fwhm)*1E3
         oplot, [0, 0.3], slope*[0, 0.3], psym = -3, col = 150
         xyouts, .20, 500, 'Slope= '+string(slope, format = '(1F7.0)')
      endif


   endfor
   jpgout, !nika.save_dir+'/test_allskd2_'+fname+'.jpg', /over
endif

end 
