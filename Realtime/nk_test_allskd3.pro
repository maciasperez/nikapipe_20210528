pro nk_test_allskd3, fname, kidparfile, newkidpar, runname, $
                    verbose = verbose, doplot = doplot, rmslim = rmslim, $
                     help = k_help,  goodscan = goodscan, scanin=scanin,  $
                     skdout = skdout, istart = istart, iend = iend, png=png
  

; Do a multi-scan fit of skydips from a given campaign (of name fname)
; Data must be reduced with nk_skydip_5 and put in a structure
; $SAVE/Test_skydip2_'+fname+'.save'
; See examples in routines with a name like Test_skydip2.scr
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
; FXD February 2017, same as nk_test_allskd.pro except that goodscan
; is a keyword now and scans are saved/restoreds individually
; Input output changes: allskd2 to allskd3
  if n_params() le 0 then begin
     message, /info, 'Call is'
     print, 'nk_test_allskd3, fname, kidparfile, newkidpar, runname, $'
     print, 'verbose = verbose, doplot = doplot, rmslim = rmslim, $'
     print, 'help = k_help,  goodscan = goodscan, scanname=scanin,  $'
     print, '                   skdout = skdout'
  endif
  
mpfitsil = 1  ; silent mode for mpfit
if keyword_set( verbose) then if verbose ne 1 then mpfitsil = 0
if keyword_set( verbose) then verb = verbose else verb = 0
if not keyword_set( rmslim) then rmslim = 3. ; up to 3 times more noisy are kept
fref = 1.9D9                                 ; Reference frequency in Hz (to avoid too large numbers)

;; NP, Feb. 18th, 2017: scanname can be passed via keyword
;; FXD, changed scanname to scanin to avoid confusion
if not keyword_set(scanin) then begin
   restore,'$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
           'Log_Iram_tel_'+runname+'_v0.save'
; Make a loop on all skydips
   source = 'TipCurrentAzimuth'
   obstype = 'DIY'              ; Skydips
   indscan = nk_select_scan( scan, source, obstype, nscan)
   scanname = scan[ indscan].day+'s'+strtrim(scan[ indscan].scannum, 2)
   if keyword_set( k_help) then begin
      for isc=0, nscan-1 do print,isc,' ', scanname[isc]
      return
   endif
   if not keyword_set( goodscan) then goodscan = indgen( nscan)
   scan = scan[ indscan[ goodscan]]
   scanname = scan.day+'s'+strtrim(scan.scannum, 2)
endif else begin
   nscan = n_elements( scanin)
   if keyword_set( k_help) then begin
      for isc=0, nscan-1 do print,isc,' ', scanin[isc]
      return
   endif
   if not keyword_set( goodscan) then goodscan = indgen( nscan)
   scanname = scanin[ goodscan]
endelse

nsc = n_elements(scanname)
print, 'Only ', strtrim( nsc, 2),  $
       ' scans will be used out of ', strtrim(nscan, 2)

jend = -1L
if keyword_set( istart) then indstart = istart else indstart = 0
if keyword_set( iend) then indend = iend else indend = nsc-1
if keyword_set( goodscan) then begin
   indstart = 0
   indend = nsc-1
endif

for isc = indstart, indend do begin
;;;for isc = 0, nsc-1 do begin
   filin =  !nika.save_dir+'/Test_skydip2_'+ $
             scanname[ isc]+ '.save'
   print, strtrim( isc, 2), ' ',  filin
   restore, file = filin, verb = (verb eq 2)
   if isc eq indstart then begin  ; initialize the input structure
      nkid = n_elements( dout[0].f_tone)
      ndout = long( n_elements( dout))
      doutall = replicate( {f_tone:dblarr(nkid), $
                            df_tone:dblarr(nkid), el:0D0, $
                            tau225:0D0, tau1:0D0, tau2:0D0}, ndout* nsc)
      skdout = replicate( {scanname:'', $
                              tau225: 0.D0, $
                              tatm:0D0,$
                           tau1:0.,  tau2:0., $
                           taufinal1:0., taufinal2:0., $
                           etaufinal1:0., etaufinal2:0., $
                           taupak1:fltarr( 50),  $
                           taupak2:fltarr( 50),  $
                              c0: dblarr(nkid), $
                              c1: dblarr(nkid), c0alt: dblarr(nkid)}, nsc)

   endif
   jst = jend+1
   jend = jst+ndout-1
   doutall[jst:jend].f_tone  = dout.f_tone  
   doutall[jst:jend].df_tone = dout.df_tone  
   doutall[jst:jend].tau225 = dout.tau225
   doutall[jst:jend].tau1 = dout.tau1
   doutall[jst:jend].tau2 = dout.tau2
   doutall[jst:jend].el = dout.el
   skdout[isc].scanname = scanname[ isc]
   skdout[isc].tau225 = skydipout.tiptau225GHZ
   skdout[isc].tatm = skydipout.tatm
   skdout[isc].tau1 = skydipout.tau1
   skdout[isc].tau2 = skydipout.tau2
   skdout[isc].c0 = skydipout.c0
   skdout[isc].c1 = skydipout.c1
   skdout[isc].c0alt = skydipout.c0alt
endfor

am = 1/sin( doutall.el)
npoint = n_elements( am)
nam = npoint/nsc

if keyword_set( doplot) then begin
   prepare_jpgout, 1, ct = 39, /norev, /icon, xsize=900, ysize=700
   prepare_jpgout, 2, ct = 39, /norev, /icon, xsize=900, ysize=700
   prepare_jpgout, 3, ct = 39, /norev, /icon, xsize=900, ysize=700
   prepare_jpgout, 4, ct = 39, /norev, /icon, xsize=900, ysize=700
endif
; Prepare data
freso = doutall.f_tone+doutall.df_tone
for ip = 0, npoint-1 do begin
   ; sometimes el can be zero, so am is infinity
   if am[ ip] gt 4 or am[ip] lt 1 then begin
      freso[*, ip] = !values.d_nan
   endif
endfor
;; file = !nika.off_proc_dir+'/'+kidparfile
file = kidparfile

kidpar = mrdfits( file, 1)
ntotkid = n_elements( kidpar)
if nkid lt ntotkid then message, 'restored dout does not have the correct number of kids'
val = total(finite( freso) and freso gt 0.9D9,  2)
c1lim = 6000.
c1min = 100. ; a lower limit on c1min (up to 6000)
c1st = 1000. ; starting point

for lamb = 1, 2 do begin ; loop on the 2 wavelengths

; 1mm
   if lamb eq 1 then lambt = '1 mm'
; 2mm
   if lamb eq 2 then lambt = '2 mm'

   if lamb eq 1 then $
      valmax = max( val[ where(kidpar.type eq 1 and kidpar.lambda lt 1.5)]) else $
         valmax = max( val[ where(kidpar.type eq 1 and kidpar.lambda gt 1.5)])   
   if verb ge 1 then print, valmax, ' is chosen number of valid points'
   if lamb eq 1 then $
      kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                      kidpar.lambda lt 1.5, nallkid) else $
                         kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                                         kidpar.lambda gt 1.5, nallkid)

   if verb ge 1 then print, nallkid, ' valid kids at '+lambt

; Limit the kids to 40 at a block 
   nbak = 40                    ; 40 kids put together
   if nallkid lt nbak then nbak = nallkid
   npak = nallkid/nbak
   if lamb eq 1 then taupak1 = fltarr( npak, nsc)
   if lamb eq 2 then taupak2 = fltarr( npak, nsc)

   for ipak = 0, npak-1 do begin
      jst = ipak*nbak
      jen = (ipak+1)*nbak
      if ipak eq (npak-1) then jen = nallkid-1
      if verb eq 2 then $
         print, 'Take kids from ', jst, ' to ', jen,  ' at '+lambt
;kid = kid[100:149]
      kid = kidall[jst:jen]
      nkid = n_elements( kid)
      if verb eq 2 then print, nkid, ' chosen valid at '+lambt
      fstr = {nkid:nkid, nsc:nsc, nam:nam}
      ytot = reform( transpose( freso[ kid, *]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nsc)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim, -c1min] ; reasonable range
      for i = 0, nsc-1 do parinfo[i+2*nkid].limits=[0.D0,2D0] ; reasonable range
      e_r = replicate( 1.d3,  nkid*npoint)
      p_start = [( max( freso[ kid, *], dim = 2, /nan) < 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
;                  skdout[indgen(nsc)].tau225>0.1]
                  replicate(0.3, nsc)] ; do not depend on tau225

      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, /nan, maxiter = 20)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set

      rmsfit = fltarr( nkid)
      npoint = nam*nsc
      outfit = dblarr( nkid*npoint)

      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nsc = nsc)
; Evaluate bad kids
      if finite( yfit[0]) eq 1 then begin
      for ik = 0, nkid-1 do begin
         a = (yfit-ytot)[ik*npoint:(ik+1)*npoint-1]
         u = where( finite(a), nu)
         if nu ne 0 then begin
            rmsfit[ ik] = stddev( a[u])
            outfit[ ik*npoint:(ik+1)*npoint-1]= a/rmsfit[ik]
         endif

      endfor
      endif
                                ;print, rmsfit

      gdkid = where( rmsfit lt rmslim*median( rmsfit), ngdkid)
      if verb eq 2 then print, ngdkid, ' good kids out of ', nkid

; Evaluate bad scans
      rmsfit2 = fltarr( nsc)
      npoint = nam*nsc
      ii = reform( lindgen( nam*nsc*nkid), nam, nsc,  nkid)
      for isc = 0, nsc-1 do begin
         ind = reform( ii[ *, isc, *], nkid*nam)
         u = where( (finite(yfit-ytot))[ind])
         rmsfit2[ isc] = stddev( (yfit-ytot)[ind[u]])
      endfor
                                ;print, rmsfit2

      gdscan = where( rmsfit2 lt rmslim*median( rmsfit2), ngdscan)
      if verb eq 2 then $
         print, ngdscan, ' good scans out of ', nsc, ' but all are kept'
      ngdscan = nsc
      gdscan = indgen( nsc)

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
      if verb eq 2 then $
         print, 'A total of ', nbadpt, ' bad points are eliminated'
      if nbadpt eq npoint then goto, noluck

; Try again with a better selection of kids and not changing selection of
; scans except for isolated points
      kid = kid[ gdkid]
      nkid = n_elements( kid)
      allpoint = lindgen( nam, nsc)
      nsc = ngdscan
      npoint = nam*nsc
      gdpoint = reform( allpoint[ *, gdscan], npoint)

      fstr = {nkid:nkid, nsc:nsc, nam:nam}
      ftemp = freso[ kid, *]
      if nbadpt ne 0 then ftemp[*, badpt] = !values.d_nan
      ytot = reform( transpose( ftemp[ *, gdpoint]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nsc)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim,c1min] ; reasonable range
      for i = 0, nsc-1 do parinfo[i+2*nkid].limits=[0.D0,1.7D0] ; reasonable range
      e_r = replicate( 1.d3,  nkid*npoint)
      p_start = [ ( max( freso[ kid, *], dim = 2, /nan)< 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
      ;            skdout[gdscan].tau225>0.1]
                  replicate(0.3, nsc)] ; do not depend on tau225

; Limit iterations
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, /nan, maxiter = 30)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set
      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nsc = nsc)

; Evaluate bad kids

      rmsfit2 = fltarr( nkid)
      npoint = nam*nsc
      for ik = 0, nkid-1 do begin
         a = (yfit-ytot)[ik*npoint:(ik+1)*npoint-1]
         u = where( finite(a), nu)
         if nu gt 10 then rmsfit2[ ik] = stddev( a[u])
      endfor
                                ;print, rmsfit2

      gdkid2 = where( rmsfit2 gt 0 and rmsfit2 lt rmslim*median( rmsfit2), ngdkid2)
      if verb eq 2 then print, ngdkid2, ' good kids out of ', nkid

; Evaluate bad scans
      rmsfit2 = fltarr( nsc)
      npoint = nam*nsc
      ii = reform( lindgen( nam*nsc*nkid), nam, nsc,  nkid)
      for isc = 0, nsc-1 do begin
         ind = reform( ii[ *, isc, *], nkid*nam)
         u = where( (finite(yfit-ytot))[ind], nu)
         if nu gt 1 then rmsfit2[ isc] = stddev( (yfit-ytot)[ind[u]]) else $
            print, 'Bad scan? ', isc, 'out of ', nsc, $
                   ' with ', nu, ' good points'
      endfor
                                ;print, rmsfit2

      gdscan2 = where( rmsfit2 lt rmslim*median( rmsfit), ngdscan2)
      if verb eq 2 then print, ngdscan2, ' good scans out of ', nsc

      

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
         if total( finite(ytot[ik*npoint+ipt])) ge 2 then begin
            plot, psym = 4, Tsky[ipt], ytot[ik*npoint+ipt], $
                  xra = [0, 300], ysty = 16, $
                  xtitle = 'Tsky [K]', $
                  ytitle = 'Freso-1.9GHz [Hz]', $
                  title = title
            oplot, psym = -3, Tsky[ipt], yfit[ik*npoint+ipt], col = 100
         endif
      endfor

      if verb eq 2 then print, 'Scan index, New tau, tau225, one-scan_tau'
      for isc = 0, nsc-1 do begin
         if verb eq 2 then begin 
            ;;print, skdout[gdscan[isc]].scanname 
            print, isc, fit[2*nkid+isc], skdout[gdscan[isc]].tau225, $
                   skdout[gdscan[isc]].tau1, format = '(4F8.3)' 
         endif
      endfor

      wshet, 4
      !p.multi = 0
      if lamb eq 1 then begin 
         plot, fit[2*nkid:*], skdout[gdscan].tau225, $
               psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, $
               xtitle = 'Tau 1mm (multi-scan)', $
               ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
               ytitle='Tau', $
               title = 'NIKA2 '+ $
               runname+ ', Block '+strtrim(ipak, 2)+ ' at '+lambt
         oplot, fit[2*nkid:*], skdout[gdscan].tau1, col = 100, psym = 8
         oplot, [0, 1.7], [0, 1.7], psym = -3
         ;;xyouts, fit[2*nkid:*], skdout[gdscan].tau1, strtrim(strmid(skdout[gdscan].scanname, 6, 6),2), chars=0.6, col=0
         xyouts, fit[2*nkid:*], skdout[gdscan].tau1, strtrim(indgen(ngdscan), 2), chars=0.6, col=0
         legendastro, ['Tau 225GHz', 'Tau 1mm (one-scan)'], col=[!p.color, 100], psym=[4,8], box=0
      endif else begin
         plot, fit[2*nkid:*], skdout[gdscan].tau225, $
               psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, $
               xtitle = 'Tau 2mm (multi-scan)', $
               ; ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
               ytitle = 'Tau', $
               title = 'NIKA2 '+ $
               runname+ ', Block '+strtrim(ipak, 2)+ ' at '+lambt
;               title = 'NIKA2 R'+!nika.run
         oplot, fit[2*nkid:*], skdout[gdscan].tau2, col = 100, psym = 8
         oplot, [0, 1.7], [0, 1.7], psym = -3
         xyouts, fit[2*nkid:*], skdout[gdscan].tau1, strtrim(indgen(ngdscan), 2), chars=0.6, col=0
         legendastro, ['Tau 225GHz', 'Tau 2mm (one-scan)'], col=[!p.color, 100], line=0, box=0
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
  else etaufinal1 = fltarr(nsc)
taufinal2 = avg(taupak2, 0)
etaufinal2 = stddev(taupak2, dim = 1)
print, median( etaufinal1),median( etaufinal2), ' dispersion on tau 1&2'
;    0.0300144     0.110962 dispersion on tau 1&2
skdout[gdscan].taufinal1 = taufinal1
skdout[gdscan].taufinal2 = taufinal2
skdout[gdscan].etaufinal1 = etaufinal1
skdout[gdscan].etaufinal2 = etaufinal2
skdout[gdscan].taupak1[0:n_elements( taupak1[*, 0])-1]= taupak1
skdout[gdscan].taupak2[0:n_elements( taupak2[*, 0])-1]= taupak2

badscan = where( etaufinal1 le 0. or etaufinal2 le 0.,  nbadscan)
if nbadscan ne 0 then begin
   print, goodscan[ badscan], ' scan(s) give a bad solution, consider removing it (them)'
   print,  taufinal1[ badscan]
   print,  etaufinal1[ badscan]
   print,  taufinal2[ badscan]
   print, etaufinal2[ badscan]
endif


if keyword_set( doplot) then begin
   scan_idx = indgen(nsc)
   ;;wshet, 1
   ;;!p.multi = [0, 2, 2]

   wind, 1, 1, /free, xsize=1000, ysize=550
   outfile =  !nika.save_dir+'/test_allskd0_'+fname
   outplot, file=outfile, png=png, ps=ps
   my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.05, gap_x=0.06, xmargin=0.1, ymargin=0.1 ; 1e-6
  
   plot, taufinal1, skdout[gdscan].tau225, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
         xtitle = 'Tau 1mm (multi-scan)', $
         ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
         ytitle='Tau', $
         title = 'NIKA2 '+runname, thick = 2, /iso, pos=pp1[0, *]
   legendastro, ['Tau 225GHz', 'Tau 1mm'], col=[!p.color, 100], psym=[4,8], box=0
   oplot, taufinal1, skdout[gdscan].tau1, col = 100, psym = 8
   oploterror, taufinal1,  skdout[gdscan].tau1, etaufinal1, replicate(0, nsc), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3
   xyouts, taufinal1, skdout[gdscan].tau1, strtrim(scan_idx[gdscan], 2), chars=0.6, col=0
   
   plot, taufinal2, skdout[gdscan].tau225,  /xsty, /ysty, /iso, $
         psym = 4, xra = [0, 1.4], yra = [0, 1.4], $
         xtitle = 'Tau 2mm (multi-scan)', $
         ;ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
         ytitle = 'Tau', $
         title = 'NIKA2 '+runname, thick = 2, pos=pp1[1, *], /noerase
   legendastro, ['Tau 225GHz', 'Tau 2mm'], col=[!p.color, 100], psym=[4,8], box=0
   oplot, taufinal2, skdout[gdscan].tau2, col = 100, psym = 8
   oploterror, taufinal2,  skdout[gdscan].tau2, etaufinal2, replicate(0, nsc), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3
   xyouts, taufinal2, skdout[gdscan].tau2, strtrim(scan_idx[gdscan], 2), chars=0.6, col=0
   !p.multi=0
   outplot, /close
   
   
   wind, 1, 1, /free, xsize=800, ysize=600
   outfile = !nika.save_dir+'/test_allskd1_'+fname
   outplot, file=outfile, png=png, ps=ps
  
   plot, taufinal1, taufinal2, /iso, /xsty, /ysty, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.4], $
         xtitle = 'Tau 1mm (multi-scan)', $
         ytitle = 'Tau 2mm (multi-scan)', $
         title = 'NIKA2 '+runname, thick = 2
   oploterror, taufinal1,  taufinal2, etaufinal1, etaufinal2, $
               errcolor = 200, psym = 3
   a = linfit(taufinal1, taufinal2)
   oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 150
   xyouts, .1, .7, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
   xyouts, .1, .8, 'Const = '+string(a[0],format='(1F5.2)'), col=150
   print, 'zero point, slope tau2 vs tau1', a
   fitexy, taufinal1, taufinal2, a, b, x_sig=etaufinal1, y_sig=etaufinal2
   oplot, [0, 2], a+b*[0, 2], col = 250
   xyouts, taufinal1, taufinal2, strtrim(scan_idx[gdscan], 2), chars=0.6, col=0
   legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                 'Fitexy slope '+string(b,form='(F4.2)')], textcol=250

   outplot, /close
   ;;jpgout, !nika.save_dir+'/test_allskd_'+fname+'.jpg', /over

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
   if verb eq 2 then print, valmax, ' is found number of valid points'
   valch = ((4*nam) < (valmax-18)) > nam
   if verb eq 2 then print, valch, ' is min chosen number of valid points'
   if lamb eq 1 then $
      kidall = where( val ge valch and kidpar.type eq 1 and $
                      kidpar.lambda lt 1.5, nallkid) else $
      kidall = where( val ge valch and kidpar.type eq 1 and $
                                         kidpar.lambda gt 1.5, nallkid)

   if verb eq 2 then print, nallkid, ' valid at '+lambt
; Limit the kids to 40 at a block 
   nbak = 40                    ; 40 kids put together
   if nallkid lt nbak then nbak = nallkid
   npak = nallkid/nbak
   for ipak = 0, npak-1 do begin
      jst = ipak*nbak
      jen = (ipak+1)*nbak
      if ipak eq (npak-1) then jen = nallkid-1
      if verb eq 2 then $
         print, 'Take kids from ', jst, ' to ', jen,  ' at '+lambt
      kid = kidall[jst:jen]
      nkid = n_elements( kid)
      if verb eq 2 then print, nkid, ' chosen valid at '+lambt

      fstr = {nkid:nkid, nsc:nsc, nam:nam}
      fref = 1.9D9
      ftemp = freso[ kid, *]
      ytot = reform( transpose( ftemp[ *, gdpoint]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nsc)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim,-c1min] ; reasonable range
      for i = 0, nsc-1 do parinfo[i+2*nkid].limits=[0.D0,2D0] ; reasonable range
      e_r = replicate( 1.d3,  nkid*npoint)
      if lamb eq 1 then tau = taufinal1 else tau = taufinal2
      p_start = [ ( max( freso[ kid, *], dim = 2, /nan)< 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
                  tau]

; Fix tau as the best values and compute better parameters
      for i = 0, nsc-1 do parinfo[i+2*nkid].fixed = 1
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, /nan, maxiter = 20)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set

      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nsc = nsc)

; Evaluate bad points in a skydip
      alloutfit = fltarr( npoint)
      for ii = 0, npoint-1 do begin
         ind = ii+ npoint*indgen( nkid)
         a = outfit[ind]
         u = where( finite(a))
         alloutfit[ ii] = avg( abs( a[u]))
      endfor
      badpt = where(  alloutfit gt rmslim, nbadpt)
      if verb eq 2 then $
         print, 'A total of ', nbadpt, ' bad points are eliminated'

      ftemp = freso[ kid, *]
      if nbadpt ne 0 then ftemp[*, badpt] = !values.d_nan
      ytot = reform( transpose( ftemp[ *, gdpoint]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nsc)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim,-c1min] ; reasonable range
      for i = 0, nsc-1 do parinfo[i+2*nkid].limits=[0.D0,2D0] ; reasonable range
      e_r = replicate( 1.d3,  nkid*npoint)
      if lamb eq 1 then tau = taufinal1 else tau = taufinal2
      p_start = [ ( max( freso[ kid, *], dim = 2, /nan)< 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
                  tau]

; Fix tau as the best values and compute better parameters
      for i = 0, nsc-1 do parinfo[i+2*nkid].fixed = 1
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, /nan, maxiter = 20)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set

      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nsc = nsc)




; Evaluate bad kids

      rmsfit = fltarr( nkid)
      npoint = nam*nsc
      for ik = 0, nkid-1 do begin
         a = (yfit-ytot)[ik*npoint:(ik+1)*npoint-1]
         u = where( finite(a))
         rmsfit[ ik] = stddev( a[u])
      endfor
                                ;print, rmsfit

      gdkid = where( rmsfit lt rmslim*median( rmsfit), ngdkid)
      if verb eq 2 then print, ngdkid, ' good kids out of ', nkid

      newkidpar[ kid[ gdkid]].c0_skydip = -(fit[ gdkid]+fref)
      newkidpar[ kid[ gdkid]].c1_skydip = -fit[ nkid+gdkid]

; Evaluate bad scans
      rmsfit = fltarr( nsc)
      npoint = nam*nsc
      ii = reform( lindgen( nam*nsc*nkid), nam, nsc,  nkid)
      for isc = 0, nsc-1 do begin
         ind = reform( ii[ *, isc, *], nkid*nam)
         u = where( (finite(yfit-ytot))[ind])
         rmsfit[ isc] = stddev( (yfit-ytot)[ind[u]])
      endfor
;      print, rmsfit
      bdscan = where( rmsfit gt rmslim*median( rmsfit), nbdscan)
      if verb eq 1 then print, nbdscan, ' bad scans out of ', nsc
      if nbdscan ge 1 then if verb eq 1 then print, bdscan
      if nbdscan ge 1 then if verb eq 1 then print, skdout[ bdscan].scanname

   endfor                       ;end loop on ipak

endfor                          ; end loop on lambda

if keyword_set(doplot) then begin
; Plot new c1 against old c1
   ;;wshet, 2
   ;;!p.multi = [0, 2, 2]
   wind, 1, 1, /free, /large
   outfile = !nika.save_dir+'/test_allskd2_'+fname
   outplot, file=outfile, png=png, ps=ps
   my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.08, xmargin=0.1, ymargin=0.1 ; 1e-6
   
   for lamb = 1, 2 do begin     ; loop on the 2 wavelengths
      if lamb eq 1 then lambt = '1 mm'
      if lamb eq 2 then lambt = '2 mm'
      if lamb eq 1 then $
         kidall = where( kidpar.type eq 1 and $
                         kidpar.lambda lt 1.5, nallkid) else $
                            kidall = where( kidpar.type eq 1 and $
                                            kidpar.lambda gt 1.5, nallkid)

      if verb ge 1 then print, nallkid, ' valid at '+lambt
      noerase=1
      if lamb eq 1 then noerase=0
      plot, kidpar[ kidall].c1_skydip, newkidpar[ kidall].c1_skydip, $
            xrang = [0, c1lim], yrang = [0, c1lim], /xsty, /ysty, psym = 8, $
            /iso, xtitle='Response [Hz/K] (old kidpar)', $ ;xtitle = 'Response [Hz/K] one-scan', $
            ytitle = 'Response [Hz/K] multi-scan',  $
            title = 'NIKA2 '+runname+', c1 at '+ lambt, thick = 2, $
            pos=pp1[2.*(lamb-1), *], noerase=noerase, charsize=0.8
      if lamb eq 1 then legendastro, ['Array 1', 'Array 3'], psym=[4,4], col=[100,200], box=0, textcol=[100,200]
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

      xrang = [0, 0.4]
      plot,1E-3/ newkidpar[ kidall].calib_fix_fwhm, newkidpar[ kidall].c1_skydip, $
           xrang = xrang, yrang = [0, c1lim], /xsty, /ysty, psym = 8, $
           xtitle = 'PS Response [Hz/(mJy/beam)]', $
           ytitle = 'Response [Hz/K] multi-scan',  $
           title = 'NIKA2 '+runname+', calib_fix_fwhm, c1 at '+ lambt, thick = 2, $
           pos=pp1[2.*(lamb-1)+1, *], noerase=1, charsize=0.8
      if lamb eq 1 then legendastro, ['Array 1', 'Array 3'], psym=[4,4], col=[100,200], box=0, textcol=[100,200]
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

   !p.multi=0
   outplot, /close
   ;;jpgout, !nika.save_dir+'/test_allskd2_'+fname+'.jpg', /over
endif

end 
