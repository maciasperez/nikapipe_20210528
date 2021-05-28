pro nk_test_allskd4, fname, kidparfile, newkidpar, runname, $
                     verbose = verbose, doplot = doplot, png=png, ps=ps, pdf=pdf, $
                     rmslim = rmslim, $
                     help = k_help,  goodscan = goodscan, scanin=scanin,  $
                     skdout = skdout, istart = istart, iend = iend,  $
                     hybrid = hybrid, skdin = skdin, dec2018=dec2018
  

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
; doplot  : 0 nothing is drawn, 1 all plots, 2: stop at each plot,
;                      3: do a pdf for each plot (FXD only)
; rmslim  : used for sigma-clipping: 3 is recommended value and the default
; value
; /help: do nothing, just list the scans to prepare goodscan
; FXD February 2017, same as nk_test_allskd.pro except that goodscan
; is a keyword now and scans are saved/restoreds individually
; Input output changes: allskd2 to allskd3
; FXD Jan 2018 skd3 to skd4: one opacity per array at 1mm
; FXD March 2018, add plots to diagnose bad scans
; FXD April 2018, add the hybrid option where the 2mm opacity is
; deduced from ATM model and the 1mm opacity
; FXD August 2018 add a weighing of each skydip with 1/rms^2
;   rms is provided in the structure skdin produced by an initial iteration
;   (skdin= skdout before the second call)
if n_params() le 0 then begin
   message, /info, 'Call is'
   print, 'nk_test_allskd4, fname, kidparfile, newkidpar, runname, $'
   print, 'verbose = verbose, doplot = doplot, rmslim = rmslim, $'
   print, 'help = k_help,  goodscan = goodscan, scanin=scanin,  $'
   print, 'istart = istart, iend = iend, skdout = skdout, hybrid = hybrid'
endif

mpfitsil = 1                    ; silent mode for mpfit
if keyword_set( verbose) then if verbose ne 1 then mpfitsil = 0
if keyword_set( verbose) then verb = verbose else verb = 0

;;verb = 2  ; FOR DEBUG only
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
   if file_test( filin) then begin
      restore, file = filin, verb = (verb eq 2)
      if isc eq indstart then begin ; initialize the input structure
         nkidtot = n_elements( dout[0].f_tone)
         ndout = long( n_elements( dout))
         doutall = replicate( {f_tone:dblarr(nkidtot), $
                               df_tone:dblarr(nkidtot), el:0D0, $
                               tau225:0D0, tau1:0D0, tau2:0D0, tau3:0D0}, $
                              ndout* nsc)
         skdout = replicate( {scanname:'', $
                              tau225: 0.D0, $
                              tatm:0D0,$
                              tau1:0.,  tau2:0., tau3:0.,$
                              taufinal1:0., taufinal2:0., taufinal3:0., $
                              etaufinal1:0., etaufinal2:0., etaufinal3:0., $
                              taupak1:fltarr( 50),  $
                              taupak2:fltarr( 50),  $
                              taupak3:fltarr( 50),  $
                              taupake1:fltarr( 50),  $
                              taupake2:fltarr( 50),  $
                              taupake3:fltarr( 50),  $
                              c0: dblarr(nkidtot), $
                              c1: dblarr(nkidtot), $
                              c0alt: dblarr(nkidtot), $
                              dt:dblarr(nkidtot), $ ; temperature offset wrt average of all scans
                              rmsa1:0., rmsa2:0., rmsa3:0.}, nsc) 
         
      endif
      jst = jend+1
      jend = jst+ndout-1
      doutall[jst:jend].f_tone  = dout.f_tone  
      doutall[jst:jend].df_tone = dout.df_tone  
      doutall[jst:jend].tau225 = dout.tau225
      doutall[jst:jend].tau1 = dout.tau1
      doutall[jst:jend].tau2 = dout.tau2
      doutall[jst:jend].tau3 = dout.tau1 ; init value
      doutall[jst:jend].el = dout.el
      skdout[isc].scanname = scanname[ isc]
      skdout[isc].tau225 = skydipout.tiptau225GHZ
      skdout[isc].tatm = skydipout.tatm
      skdout[isc].tau1 = skydipout.tau1
      skdout[isc].tau2 = skydipout.tau2
      skdout[isc].tau3 = skydipout.tau1 ; init value
      skdout[isc].c0 = skydipout.c0
      skdout[isc].c1 = skydipout.c1
      skdout[isc].c0alt = skydipout.c0alt
   endif
   
endfor

am = 1/sin( doutall.el)
npoint = n_elements( am)
nam = npoint/nsc

; Fix for N2R50: the elevation is badly computed for last point,
gg=nam*indgen(nsc)+nam-1
u=where( finite(am[gg]), nu)
if nu eq 0 then message, 'This cannot work'
if nu ne nsc then begin
; replace by the correct value
   am[gg]=median(am[gg[u]])
endif

if keyword_set( doplot) then begin
   ;; LP begins ; change to save plots in png, ps and/or pdf 
   ;;prepare_jpgout, 1, ct = 39, /norev, /icon, xsize=900, ysize=700
   ;;prepare_jpgout, 2, ct = 39, /norev, /icon, xsize=900, ysize=700
   ;;prepare_jpgout, 3, ct = 39, /norev, /icon, xsize=900, ysize=700
   ;;prepare_jpgout, 4, ct = 39, /norev, /icon, xsize=900, ysize=700
   ;;prepare_jpgout, 5, ct = 39, /norev, /icon, xsize=900, ysize=700
   ;;prepare_jpgout, 6, ct = 39, /norev, /icon, xsize=900, ysize=700
   
   ;; window size
   wxsize = 1000.
   wysize = 750.
   ;; plot size in files
   pxsize = 19.
   pysize = 14.
   ;; charsize
   charsize  = 1.2
   charthick = 1.0
   mythick = 1.0
   mysymsize   = 0.8
   
   if keyword_set(ps) then begin
      ;; charsize
      ps_charsize  = 1.2
      ps_charthick = 3.0
      ps_mythick   = 3.0 
      ps_mysymsize   = 0.8
  endif
   ;; LP ends
   
endif
; Prepare data
freso = doutall.f_tone+doutall.df_tone
u = where(doutall.f_tone le 0., nu)
if nu ne 0 then freso[u] = !values.d_nan
for ip = 0, npoint-1 do begin
                                ; sometimes el can be zero, so am is infinity
   if am[ ip] gt 4 or am[ip] lt 1 then begin
      freso[*, ip] = !values.d_nan
   endif
endfor
;; file = !nika.off_proc_dir+'/'+kidparfile
file = kidparfile

if file_test( file) then kidpar = mrdfits( file, 1) else begin
   stop, 'No kidpar available '+ file
endelse

ntotkid = n_elements( kidpar)
if nkidtot lt ntotkid then message, 'restored dout does not have the correct number of kids'
val = total(finite( freso) and freso gt 0.9D9,  2)
c1lim = 6000.
c1min = 100.                    ; a lower limit on c1min (up to 6000)
c1st = 1000.                    ; starting point

for narr = 1, 3 do begin        ; loop on the 3 arrays

   if narr eq 2 then lamb = 2 else lamb = 1
   
; 1mm
   if lamb eq 1 then lambt = '1 mm A'+strtrim( narr, 2)
; 2mm
   if lamb eq 2 then lambt = '2 mm'

   if lamb eq 1 then $
      valmax = max( val[ where(kidpar.type eq 1 and kidpar.lambda lt 1.5)]) else $
         valmax = max( val[ where(kidpar.type eq 1 and kidpar.lambda gt 1.5)])   
   if verb ge 1 then print, valmax, ' is the chosen number of valid points'
   if lamb eq 1 then $
      kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                      kidpar.array eq narr, nallkid) else $
                         kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                                         kidpar.lambda gt 1.5, nallkid)

   if nallkid lt 30 then begin
                                ; fail proof version in case valmax is too far from the median
      if lamb eq 1 then $
         valmax = median( val[ where(kidpar.type eq 1 and kidpar.lambda lt 1.5)]) else $
            valmax = median( val[ where(kidpar.type eq 1 and kidpar.lambda gt 1.5)]) 
      if verb ge 1 then print, valmax, ' is the (corrected) chosen number of valid points'
      if lamb eq 1 then $
         kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                         kidpar.array eq narr, nallkid) else $
                            kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                                            kidpar.lambda gt 1.5, nallkid)
   endif
   if verb ge 1 then print, nallkid, ' valid kids  in array '+strtrim(narr, 2)
   


; Limit the kids to 40 at a block 
   nbak = 40                    ; 40 kids put together
   if nallkid lt nbak then nbak = nallkid
   npak = nallkid/nbak
   if narr eq 1 then begin
      npak1 = npak
      taupak1 = fltarr( npak, nsc)
      taupake1 = fltarr( npak, nsc)
      if keyword_set( skdin) then errskd = skdin.rmsa1 $
      else errskd = replicate( 1., nsc)
   endif
   
   if narr eq 2 then begin
      npak2 = npak
      taupak2 = fltarr( npak, nsc)
      taupake2 = fltarr( npak, nsc)
      if keyword_set( skdin) then errskd = skdin.rmsa2 $
      else errskd = replicate( 1., nsc)
   endif
   
   if narr eq 3 then begin
      npak3 = npak
      taupak3 = fltarr( npak, nsc)
      taupake3 = fltarr( npak, nsc)
      if keyword_set( skdin) then errskd = skdin.rmsa3 $
      else errskd = replicate( 1., nsc)
   endif
   
   for ipak = 0, npak-1 do begin
      jst = ipak*nbak
      jen = (ipak+1)*nbak-1
      if ipak eq (npak-1) then jen = nallkid-1
      if verb eq 2 then $
         print, 'Take kids from ', jst, ' to ', jen,  $
                ' in array '+strtrim(narr, 2)
      kid = kidall[jst:jen]
      nkid = n_elements( kid)
      if verb eq 2 then print, nkid, ' chosen valid '
      fstr = {nkid:nkid, nsc:nsc, nam:nam}
      ytot = reform( transpose( freso[ kid, *]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nsc)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref    ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim, -c1min] ; reasonable range
      for i = 0, nsc-1 do parinfo[i+2*nkid].limits=[0.D0,2D0]      ; reasonable range
                                ;e_r = replicate( 1.d3,  nkid*npoint)
      e_r = dblarr( nkid, nsc, nam)
      for isc = 0, nsc-1 do e_r[*, isc, *] = 1./errskd[ isc]^2 ; user has to check this is not zero
      e_r = reform( e_r, nkid*npoint)
      p_start = [( max( freso[ kid, *], dim = 2, /nan) < 2.4D9)-fref, $
                 replicate(-c1st, nkid), $
;                  skdout[indgen(nsc)].tau225>0.1]
                 replicate(0.3, nsc)] ; do not depend on tau225

;;       ;;--------------------------
;;       message, /info, "check array dimensions and try taux_model2"
;;       nkid2 = 2*nkid
;;       nam = 11
;;       p = p_start
;;       x = am
;;       ntot = nkid2+nsc-1        ; number of parameters
;;       ptau = reform( replicate(1.D0, nam)#p[nkid2:ntot], nam*nsc) ;tau values
;;       farr  = reform( replicate(1.D0, nam*nsc) # p[0:nkid-1], nkid*nam*nsc)
;;       y = farr + $
;;           reform( (1.d0 - exp( - x*ptau))#(p[nkid:nkid2-1]*270.d0), $
;;                   nkid*nam*nscan)
;; 
;;       exp_x_ptau = 1.d0 + (-x*ptau) + (-x*ptau)^2/2 + (-x*ptau)^3/6.d0 + $
;;                    (-x*ptau)^4/24.d0 + (-x*ptau)^5/120.d0 + (-x*ptau)^6/720.d0 + $
;;                    (-x*ptau)^7/5040.d0 + (-x*ptau)^8/40320.d0
;;       y1 = farr + reform( (1.d0-exp_x_ptau)#(p[nkid:nkid2-1]*270.d0), nkid*nam*nscan)
;;       stop
;;       ;;----------------------------
      
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, $
                      /nan, maxiter = 20, $
                      perror = perror, bestnorm = bestnorm)
;      help, perror

;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set
      dof = nam*nsc - n_elements( p_start)  ; deg of freedom
      pcerror = perror* sqrt( bestnorm/dof) ; scaled uncertainties
;
;      if keyword_set(skdin) then stop
      
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
      endfor
      badpt = where(  alloutfit gt rmslim, nbadpt)
      if verb eq 2 then $
         print, 'A total of ', nbadpt, ' bad points are eliminated'
      if nbadpt eq npoint then goto, noluck
      if ngdkid eq 0 then goto, noluck

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
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref  ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim,c1min] ; reasonable range
      for i = 0, nsc-1 do parinfo[i+2*nkid].limits=[0.D0,1.7D0]  ; reasonable range
      e_r = dblarr( nkid, nsc, nam)
      for isc = 0, nsc-1 do e_r[*, isc, *] = 1./errskd[ isc]^2 ; user has to check this is not zero
      e_r = reform( e_r, nkid*npoint)
      ;;; e_r = replicate( 1.d3,  nkid*npoint)
      p_start = [ ( max( freso[ kid, *], dim = 2, /nan)< 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
                                ;            skdout[gdscan].tau225>0.1]
                  replicate(0.3, nsc)] ; do not depend on tau225

; Limit iterations
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, $
                      /nan, maxiter = 30, $
                      perror = perror, bestnorm = bestnorm)

;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set
      dof = nam*nsc - n_elements( p_start)  ; deg of freedom
      pcerror = perror* sqrt( bestnorm/dof) ; scaled uncertainties
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
      if verb eq 2 then message, /info, strtrim(ngdkid2,2)+' good kids out of '+strtrim(nkid,2)

; Evaluate bad scans
      rmsfit2 = fltarr( nsc)+!values.f_nan
      npoint = nam*nsc
      ii = reform( lindgen( nam*nsc*nkid), nam, nsc,  nkid)
      for isc = 0, nsc-1 do begin
         ind = reform( ii[ *, isc, *], nkid*nam)
         u = where( (finite(yfit-ytot))[ind], nu)
         if nu gt 1 then begin
            rmsfit2[ isc] = stddev( (yfit-ytot)[ind[u]])
         endif else begin
            message, /info, 'Bad scan? '+strtrim(isc,2)+' out of '+strtrim(nsc,2)+$
                     ' with '+strtrim(nu,2)+' good points: '+ scanname[ isc]
;            stop
         endelse
      endfor

      gdscan2 = where( rmsfit2 lt rmslim*median( rmsfit), ngdscan2)
      if verb eq 2 then print, ngdscan2, ' good scans out of ', nsc


; Plots
      if keyword_set( doplot) then begin
         wind, 3, 1, xsize=750, ysize=750 
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
               title = '4 Kids in Block '+strtrim(ipak, 2)+ ' in array '+strtrim(narr, 2)
            if total( finite(ytot[ik*npoint+ipt])) ge 2 then begin
               plot, psym = 4, Tsky[ipt], 1E-6*ytot[ik*npoint+ipt], $
                     xra = [0, 300], ysty = 16, $
                     xtitle = 'Tsky [K]', $
                     ytitle = 'Freso-1.9GHz [MHz]', $
                     title = title
               oplot, psym = -3, Tsky[ipt], 1E-6*yfit[ik*npoint+ipt], col = 100
            endif
         endfor
         if verb eq 2 then print, 'New tau, tau225, one-scan_tau'
         for isc = 0, nsc-1 do $
            if verb eq 2 then $
               print, fit[2*nkid+isc], skdout[gdscan[isc]].tau225, $
                      skdout[gdscan[isc]].tau1, format = '(3F8.3)'
         
         wind, 4, 4, xsize=450, ysize=400 
         wshet, 4
         !p.multi = 0
         if ngdscan ge 2 then begin
            if lamb eq 1 then begin 
            plot, fit[2*nkid:*], skdout[gdscan].tau225, $
                  psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, $
                  xtitle = 'Tau Arr'+strtrim(narr, 2)+ ' 1mm (multi-scan)', $
                                ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
                  ytitle='Tau', $
                  title = 'NIKA2 '+ $
                  runname+ ', Block '+strtrim(ipak, 2)+ ' Array '+strtrim(narr, 2)
            legendastro, ['Tau 225GHz', 'Tau 1mm (one-scan)'], col=[!p.color, 100], psym=[4,8], box=0
            oplot, fit[2*nkid:*], skdout[gdscan].tau1, col = 100, psym = 8
            oplot, [0, 1.7], [0, 1.7], psym = -3
         endif else begin
            plot, fit[2*nkid:*], skdout[gdscan].tau225, $
                  psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, $
                  xtitle = 'Tau 2mm (multi-scan)', $
                                ; ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
                  ytitle = 'Tau', $
                  title = 'NIKA2 '+ $
                  runname+ ', Block '+strtrim(ipak, 2)+ ' at '+lambt
;               title = 'NIKA2 R'+!nika.run
            legendastro, ['Tau 225GHz', 'Tau 2mm (one-scan)'], col=[!p.color, 100], line=0, box=0
            oplot, fit[2*nkid:*], skdout[gdscan].tau2, col = 100, psym = 8
            oplot, [0, 1.7], [0, 1.7], psym = -3
         endelse
         endif
         if doplot ge 2 then cont_plot, nostop = nostop
      ;;; if lamb eq 2 and ipak eq 0 then stop
         if doplot ge 3 then begin ; save one pdf plot
            fxd_ps, /portrait, /color
            !p.multi = [0, 2, 2]
            nind = 4
            ind = 0+indgen( nind)
            ipt = indgen( npoint) ;;;nam*0+indgen(nam*3)
            Tsky = 270.*(1-exp(-am*(replicate(1D0, nam)#fit[ 2*nkid:*])))
            for i = 0, nind-1 do begin
               ik = ind[ i]
               title = 'NIKA2 '+ runname
               if i eq 0 then $
                  title = '4 Kids in Block '+strtrim(ipak, 2)+ ' in array '+strtrim(narr, 2)
               if total( finite(ytot[ik*npoint+ipt])) ge 2 then begin
                  plot, psym = 4, Tsky[ipt], 1E-6*ytot[ik*npoint+ipt], $
                        xra = [0, 300], ysty = 16, $
                        xtitle = 'Tsky [K]', $
                        ytitle = 'Freso-1.9GHz [MHz]', $
                        title = title
                  oplot, psym = -3, Tsky[ipt], 1E-6*yfit[ik*npoint+ipt], col = 100
               endif
            endfor
            ;; Change the number _5... if more than one plot
         
            fxd_psout, save = !nika.save_dir+'/test_allskd4_'+fname+'_5.pdf', /over
            stop, !nika.save_dir+'/test_allskd4_'+fname+'_5.pdf' + ' was created, exit now'
         endif
      endif
;;;if narr eq 1 then stop, 'Check Array 1'
   if narr eq 1 then begin
      taupak1[ipak, *] = fit[2*nkid:*]
      taupake1[ipak, *] = pcerror[2*nkid:*]
   endif
   if narr eq 2 then begin
      taupak2[ipak, *] = fit[2*nkid:*]
      taupake2[ipak, *] = pcerror[2*nkid:*]
   endif
   if narr eq 3 then begin
      taupak3[ipak, *] = fit[2*nkid:*]
      taupake3[ipak, *] = pcerror[2*nkid:*]
   endif
noluck:
endfor                          ;end loop on ipak


   
endfor                          ; end loop on narr

; FXD Apr 2021, 20 was hard coded in replicate(1., 20): corrected
; now. Add one more check 1.7 is the blocked opacity Check that this
; is not reached, npak depends on the array !
tpke1= median( taupake1, dim = 1)
tpk1 = median( taupak1,  dim = 1)
badtpk1=where( taupak1 gt 1.65 or $
               abs(taupak1 - replicate(1.,npak1)#tpk1) gt 2*taupake1 or $
               taupake1 gt 3*replicate(1.,npak1)#tpke1 $
               or taupake1 le 0.,nbadtpk1)
if nbadtpk1 ne 0 then begin
   message, /info, 'Some blocks*scans array 1 have to be discarded '+strtrim( nbadtpk1)
   taupak1[ badtpk1]=!values.f_nan
endif
taufinal1 = avg(taupak1, 0, /nan)
if npak1 gt 1 then etaufinal1 = stddev(taupak1, dim = 1, /nan) $
else etaufinal1 = fltarr(nsc)

; FXD June 2020 (add this feature to all arrays, done), have to clear
; some block away because of bad behaviour.
tpke3=median( taupake3,dim=1)
tpk3 = median( taupak3,  dim = 1)
badtpk3=where( taupak3 gt 1.65 or $
               abs(taupak3 - replicate(1.,npak3)#tpk3) gt 2*taupake3 or $
               taupake3 gt 3*replicate(1., npak3)#tpke3 or taupake3 le 0.,nbadtpk3)
if nbadtpk3 ne 0 then begin
   message, /info, 'Some blocks*scans array 3 have to be discarded '+strtrim( nbadtpk3)
   taupak3[ badtpk3]=!values.f_nan
endif
taufinal3 = avg(taupak3, 0, /nan)
if npak3 gt 1 then etaufinal3 = stddev(taupak3, dim = 1, /nan) $
else etaufinal3 = fltarr(nsc)

tpke2=median( taupake2,dim=1)
tpk2 = median( taupak2,  dim = 1)
badtpk2=where( taupak2 gt 1.65 or $
               abs(taupak2 - replicate(1.,npak2)#tpk2) gt 2*taupake2 or $
               taupake2 gt 3*replicate(1., npak2)#tpke2 or taupake2 le 0.,nbadtpk2)
if nbadtpk2 ne 0 then begin
   message, /info, 'Some blocks*scans array 2 have to be discarded '+strtrim( nbadtpk2)
   taupak2[ badtpk2]=!values.f_nan
endif
taufinal2 = avg(taupak2, 0, /nan)
etaufinal2 = stddev(taupak2, dim = 1, /nan)
if nsc gt 1 then print, median( etaufinal1),median( etaufinal3), median( etaufinal2), ' dispersion on tau 1,3&2'
;    0.0300144     0.110962 dispersion on tau 1&2

; Take a different approach for the 2mm opacity (or not)
if keyword_set( hybrid) then begin
; Read the opacity table from a file and interpolate to get taufinal2
   ;;read_col,hybrid,ta1,ta2,ta3
   ;; LP, 17 april, replacing the line above by the following lines 
   template_file = '/home/perotto/NIKA/Processing/Pipeline/Datamanage/template_tau_arrays_April_2018.save'
   ;;template = ascii_template(hybrid)
   ;;save, template, filename = template_file
   restore, template_file
   tab = read_ascii(hybrid, template=template)
   ta1 = tab.(0)
   ta2 = tab.(1)
   ta3 = tab.(2)
   ;; end LP, 17 april
   taufinal2 = interpol( ta2, ta1, taufinal1)
   npaktot = n_elements( taupak1)
   taupak2[ lindgen( npaktot)] = interpol( ta2,  ta1, taupak1[ lindgen( npaktot)])
endif

;;;;stop, 'Check taupak1'
skdout[gdscan].taufinal1 = taufinal1
skdout[gdscan].taufinal2 = taufinal2
skdout[gdscan].taufinal3 = taufinal3
skdout[gdscan].etaufinal1 = etaufinal1
skdout[gdscan].etaufinal2 = etaufinal2
skdout[gdscan].etaufinal3 = etaufinal3
skdout[gdscan].taupak1[0:n_elements( taupak1[*, 0])-1]= taupak1
skdout[gdscan].taupak2[0:n_elements( taupak2[*, 0])-1]= taupak2
skdout[gdscan].taupak3[0:n_elements( taupak3[*, 0])-1]= taupak3
skdout[gdscan].taupake1[0:n_elements( taupak1[*, 0])-1]= taupake1
skdout[gdscan].taupake2[0:n_elements( taupak2[*, 0])-1]= taupake2
skdout[gdscan].taupake3[0:n_elements( taupak3[*, 0])-1]= taupake3

badscan = where( etaufinal1 le 0. or etaufinal2 le 0. or etaufinal3 le 0. $
                 or etaufinal1 gt 10*median(etaufinal1) $
                 or etaufinal2 gt 10*median(etaufinal2) $
                 or etaufinal3 gt 10*median(etaufinal3) ,  nbadscan)
if nbadscan ne 0 then begin
   print, goodscan[ badscan], $
          ' scan(s) give a bad solution, consider removing it (them)'
   print,  taufinal1[ badscan]
   print, etaufinal1[ badscan]
   print,  taufinal3[ badscan]
   print, etaufinal3[ badscan]
   print,  taufinal2[ badscan]
   print, etaufinal2[ badscan]
   print, skdout[ badscan].scanname
   print, badscan
endif

if keyword_set( doplot) then begin
   ;; NB this plot is repeated in plot_test_allskd4.pro
   wind, 1, 2, /free, xsize=wxsize, ysize=wysize 
   ;;wshet, 1
   !p.multi = [0, 3, 2]
   outfile = !nika.save_dir+'/test_allskd4_'+fname+'_1'
   outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
   plot, taufinal1, skdout[gdscan].tau225, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
         xtitle = 'Tau arr1 1mm (multi-scan)', $
                                ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
         ytitle='Tau', $
         title = 'NIKA2 '+runname, thick = 2, /iso
   legendastro, ['Tau 225GHz', 'Tau Arr1 1mm'], col=[!p.color, 100], psym=[4,8], box=0
   oplot, taufinal1, skdout[gdscan].tau1, col = 100, psym = 8
   oploterror, taufinal1,  skdout[gdscan].tau1, etaufinal1, replicate(0, nsc), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3
   
   plot, taufinal3, skdout[gdscan].tau225, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
         xtitle = 'Tau arr3 1mm (multi-scan)', $
                                ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
         ytitle='Tau', $
         title = 'NIKA2 '+runname, thick = 2, /iso
   legendastro, ['Tau 225GHz', 'Tau Arr3 1mm'], col=[!p.color, 100], psym=[4,8], box=0
   oplot, taufinal3, skdout[gdscan].tau3, col = 100, psym = 8
   oploterror, taufinal3,  skdout[gdscan].tau3, etaufinal3, replicate(0, nsc), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3

   plot, taufinal2, skdout[gdscan].tau225,  /xsty, /ysty, /iso, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau 2mm (multi-scan)', $
                                ;ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
         ytitle = 'Tau', $
         title = 'NIKA2 '+runname, thick = 2
   legendastro, ['Tau 225GHz', 'Tau 2mm'], col=[!p.color, 100], psym=[4,8], box=0
   oplot, taufinal2, skdout[gdscan].tau2, col = 100, psym = 8
   oploterror, taufinal2,  skdout[gdscan].tau2, etaufinal2, replicate(0, nsc), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3
   
   plot, taufinal1, taufinal2,/iso, /xsty, /ysty, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau Arr 1 1mm (multi-scan)', $
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
   legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                 'Fitexy slope '+string(b,form='(F4.2)')], textcol=250
;   oplot, taufinal3, taufinal2, psym = 4, col = 50
   
   plot, taufinal3, taufinal2,/iso, /xsty, /ysty, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau Arr 3 1mm (multi-scan)', $
         ytitle = 'Tau 2mm (multi-scan)', $
         title = 'NIKA2 '+runname, thick = 2
   oploterror, taufinal3,  taufinal2, etaufinal3, etaufinal2, $
               errcolor = 200, psym = 3
   a = linfit(taufinal3, taufinal2)
   oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 150
   xyouts, .1, .7, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
   xyouts, .1, .8, 'Const = '+string(a[0],format='(1F5.2)'), col=150
   print, 'zero point, slope tau2 vs tau3', a
   fitexy, taufinal3, taufinal2, a, b, x_sig=etaufinal3, y_sig=etaufinal2
   oplot, [0, 2], a+b*[0, 2], col = 250
   legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                 'Fitexy slope '+string(b,form='(F4.2)')], textcol=250
;   oplot, taufinal3, taufinal2, psym = 4, col = 50

   plot, taufinal1, taufinal3,/iso, /xsty, /ysty, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau Arr 1 1mm (multi-scan)', $
         ytitle = 'Tau Arr 3 1mm (multi-scan)', $
         title = 'NIKA2 '+runname, thick = 2
   oploterror, taufinal1,  taufinal3, etaufinal1, etaufinal3, $
               errcolor = 200, psym = 3
   a = linfit(taufinal1, taufinal3)
   oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 150
   xyouts, .1, .7, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
   xyouts, .1, .8, 'Const = '+string(a[0],format='(1F5.2)'), col=150
   print, 'zero point, slope tau3 vs tau1', a
   fitexy, taufinal1, taufinal3, a, b, x_sig=etaufinal1, y_sig=etaufinal3
   oplot, [0, 2], a+b*[0, 2], col = 250
   legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                 'Fitexy slope '+string(b,form='(F4.2)')], textcol=250

   ;; LP modifs
   ;;jpgout, !nika.save_dir+'/test_allskd4_'+fname+'_1.jpg', /over
   outplot, /close
   
;    0.0275618     0.571271

   ;; repeat the plot for saving in ps/pdf
   outfile = !nika.save_dir+'/plot_allskd4_'+fname+'_1'
   outplot, file=outfile, ps=ps, xsize=ps_pxsize, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick
   plot, taufinal1, skdout[gdscan].tau225, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
         xtitle = 'Tau arr1 1mm (multi-scan)', $
         ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
         ytitle='Tau', $
         title = 'NIKA2 '+runname, thick = 2, /iso
   legendastro, ['Tau 225GHz', 'Tau Arr1 1mm'], col=[!p.color, 100], psym=[4,8], box=0
   oplot, taufinal1, skdout[gdscan].tau1, col = 100, psym = 8, symsize=ps_mysymsize
   oploterror, taufinal1,  skdout[gdscan].tau1, etaufinal1, replicate(0, nsc), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3
   
   plot, taufinal3, skdout[gdscan].tau225, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
         xtitle = 'Tau arr3 1mm (multi-scan)', $
         ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
         ytitle='Tau', $
         title = 'NIKA2 '+runname, thick = 2, /iso
   legendastro, ['Tau 225GHz', 'Tau Arr3 1mm'], col=[!p.color, 100], psym=[4,8], box=0
   oplot, taufinal3, skdout[gdscan].tau3, col = 100, psym = 8, symsize=ps_mysymsize
   oploterror, taufinal3,  skdout[gdscan].tau3, etaufinal3, replicate(0, nsc), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3

   plot, taufinal2, skdout[gdscan].tau225,  /xsty, /ysty, /iso, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau 2mm (multi-scan)', $
         ;ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
         ytitle = 'Tau', $
         title = 'NIKA2 '+runname, thick = 2
   legendastro, ['Tau 225GHz', 'Tau 2mm'], col=[!p.color, 100], psym=[4,8], box=0
   oplot, taufinal2, skdout[gdscan].tau2, col = 100, psym = 8, symsize=ps_mysymsize
   oploterror, taufinal2,  skdout[gdscan].tau2, etaufinal2, replicate(0, nsc), $
               errcolor = 200, psym = 3
   oplot, [0, 1.7], [0, 1.7], psym = -3
   
   plot, taufinal1, taufinal2,/iso, /xsty, /ysty, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau Arr 1 1mm (multi-scan)', $
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
   legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                 'Fitexy slope '+string(b,form='(F4.2)')], textcol=250
;   oplot, taufinal3, taufinal2, psym = 4, col = 50
 
   plot, taufinal3, taufinal2,/iso, /xsty, /ysty, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau Arr 3 1mm (multi-scan)', $
         ytitle = 'Tau 2mm (multi-scan)', $
         title = 'NIKA2 '+runname, thick = 2
   oploterror, taufinal3,  taufinal2, etaufinal3, etaufinal2, $
               errcolor = 200, psym = 3
   a = linfit(taufinal3, taufinal2)
   oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 150
   xyouts, .1, .7, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
   xyouts, .1, .8, 'Const = '+string(a[0],format='(1F5.2)'), col=150
   print, 'zero point, slope tau2 vs tau3', a
   fitexy, taufinal3, taufinal2, a, b, x_sig=etaufinal3, y_sig=etaufinal2
   oplot, [0, 2], a+b*[0, 2], col = 250
   legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                 'Fitexy slope '+string(b,form='(F4.2)')], textcol=250
;   oplot, taufinal3, taufinal2, psym = 4, col = 50

   plot, taufinal1, taufinal3,/iso, /xsty, /ysty, $
         psym = 4, xra = [0, 1.7], yra = [0, 1.7], $
         xtitle = 'Tau Arr 1 1mm (multi-scan)', $
         ytitle = 'Tau Arr 3 1mm (multi-scan)', $
         title = 'NIKA2 '+runname, thick = 2
   oploterror, taufinal1,  taufinal3, etaufinal1, etaufinal3, $
               errcolor = 200, psym = 3
   a = linfit(taufinal1, taufinal3)
   oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 150
   xyouts, .1, .7, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
   xyouts, .1, .8, 'Const = '+string(a[0],format='(1F5.2)'), col=150
   print, 'zero point, slope tau3 vs tau1', a
   fitexy, taufinal1, taufinal3, a, b, x_sig=etaufinal1, y_sig=etaufinal3
   oplot, [0, 2], a+b*[0, 2], col = 250
   legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                 'Fitexy slope '+string(b,form='(F4.2)')], textcol=250

   outplot, /close
   if keyword_set(pdf) then spawn, 'epspdf --bbox '+outfile+'.eps'
   ;; restore plot aspect
   !p.thick = 1.0
   !p.charsize  = 1.0
   !p.charthick = 1.0
   ;; LP ends
   
endif

;-----------------------------------------------------------------------
; Now compute the coefficients of each kid to feed into new c0 and c1
newkidpar = kidpar
newkidpar.c0_skydip = 0.
newkidpar.c1_skydip = 0.
rmsarr = fltarr(3, nsc)
dtarr = fltarr( nkidtot, nsc)   ; delta_c0 per scan per kid, and written in temperature
for narr = 1, 3 do begin        ; loop on the 3 arrays

   if narr eq 2 then lamb = 2 else lamb = 1
   
; 1mm
   if lamb eq 1 then lambt = '1 mm A'+strtrim( narr, 2)
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
      kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                      kidpar.array eq narr, nallkid) else $
                         kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                                         kidpar.lambda gt 1.5, nallkid)

   if nallkid lt 30 then begin
                                ; fail proof version in case valmax is too far from the median
      if lamb eq 1 then $
         valmax = median( val[ where(kidpar.type eq 1 and kidpar.lambda lt 1.5)]) else $
            valmax = median( val[ where(kidpar.type eq 1 and kidpar.lambda gt 1.5)]) 
      if verb ge 1 then print, valmax, ' is the (corrected) chosen number of valid points'
      if lamb eq 1 then $
         kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                         kidpar.array eq narr, nallkid) else $
                            kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                                            kidpar.lambda gt 1.5, nallkid)
   endif
   if verb ge 2 then print, nallkid, ' valid kids  in array '+strtrim(narr, 2)
; Limit the kids to 40 at a block 
   nbak = 40                    ; 40 kids put together
   if nallkid lt nbak then nbak = nallkid
   npak = nallkid/nbak
   rmspak = fltarr(npak, nsc)
   for ipak = 0, npak-1 do begin
      jst = ipak*nbak
      jen = (ipak+1)*nbak-1  ; -1 FXD May 2020 bug corrected
      if ipak eq (npak-1) then jen = nallkid-1
      if verb eq 2 then $
         print, 'Take kids from ', jst, ' to ', jen,  $
                ' in array '+strtrim(narr, 2)
      kid = kidall[jst:jen]
      nkid = n_elements( kid)
      if verb eq 2 then print, nkid, ' chosen valid '

      fstr = {nkid:nkid, nsc:nsc, nam:nam}
      fref = 1.9D9
      ftemp = freso[ kid, *]
      ytot = reform( transpose( ftemp[ *, gdpoint]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nsc)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref   ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim,-c1min] ; reasonable range
      for i = 0, nsc-1 do parinfo[i+2*nkid].limits=[0.D0,2D0]     ; reasonable range
;;;      e_r = replicate( 1.d3,  nkid*npoint)
      e_r = dblarr( nkid, nsc, nam)
      for isc = 0, nsc-1 do e_r[*, isc, *] = 1./errskd[ isc]^2 ; user has to check this is not zero
      e_r = reform( e_r, nkid*npoint)
; Bug corrected on 13/4/2018 (no impact because it is right further down)
      if narr eq 1 then tau = taufinal1
      if narr eq 2 then tau = taufinal2
      if narr eq 3 then tau = taufinal3
      p_start = [ ( max( freso[ kid, *], dim = 2, /nan)< 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
                  tau]

; Fix tau as the best values and compute better parameters
      for i = 0, nsc-1 do parinfo[i+2*nkid].fixed = 1
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, $
                      /nan, maxiter = 30, $
                      perror = perror, bestnorm = bestnorm)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set
      dof = nam*nsc - n_elements( p_start)  ; deg of freedom
      pcerror = perror* sqrt( bestnorm/dof) ; scaled uncertainties

      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nsc = nsc)

; Evaluate bad points in a skydip
      alloutfit = fltarr( npoint)
      for ii = 0, npoint-1 do begin
         ind = ii+ npoint*indgen( nkid)
         a = outfit[ind]
         u = where( finite(a), nu)
         if nu ne 0 then alloutfit[ ii] = avg( abs( a[u]))
      endfor
      badpt = where(  alloutfit eq 0 or alloutfit gt rmslim, nbadpt)
      if verb eq 2 then $
         print, 'A total of ', nbadpt, ' bad points are eliminated'

      ftemp = freso[ kid, *]
      if nbadpt ne 0 then ftemp[*, badpt] = !values.d_nan
      ytot = reform( transpose( ftemp[ *, gdpoint]), nkid*npoint)-fref
      parinfo = replicate({fixed:0, limited:[1,1], $
                           limits:[0.,0.D0]}, 2*nkid+nsc)
      for i = 0, nkid-1 do parinfo[i].limits=[0.9d9,2.5d9]-fref   ; reasonable range
      for i = 0, nkid-1 do parinfo[i+nkid].limits=[-c1lim,-c1min] ; reasonable range
      for i = 0, nsc-1 do parinfo[i+2*nkid].limits=[0.D0,2D0]     ; reasonable range
;;;      e_r = replicate( 1.d3,  nkid*npoint)
      e_r = dblarr( nkid, nsc, nam)
      for isc = 0, nsc-1 do e_r[*, isc, *] = 1./errskd[ isc]^2 
      e_r = reform( e_r, nkid*npoint)
      if narr eq 1 then tau = taufinal1
      if narr eq 2 then tau = taufinal2
      if narr eq 3 then tau = taufinal3
      
      p_start = [ ( max( freso[ kid, *], dim = 2, /nan)< 2.4D9)-fref, $
                  replicate(-c1st, nkid), $
                  tau]

; Fix tau as the best values and compute better parameters
      for i = 0, nsc-1 do parinfo[i+2*nkid].fixed = 1
      fit = mpfitfun( 'taux_model2', am, ytot, $
                      e_r, p_start, quiet = mpfitsil, $
                      parinfo=parinfo, functargs = fstr, $
                      /nan, maxiter = 30, $
                      perror = perror, bestnorm = bestnorm)
;  Data values of NaN or Infinity for "Y", "ERR" or "WEIGHTS" will be
;  ignored as missing data if the NAN keyword is set
      dof = nam*nsc - n_elements( p_start)  ; deg of freedom
      pcerror = perror* sqrt( bestnorm/dof) ; scaled uncertainties

      yfit = taux_model2( am, fit, nkid = nkid, nam = nam, nsc = nsc)

; Evaluate bad kids

      rmsfit = fltarr( nkid)+!values.f_nan
      npoint = nam*nsc
      for ik = 0, nkid-1 do begin
         a = (yfit-ytot)[ik*npoint:(ik+1)*npoint-1]
         u = where( finite(a), nu)
         if nu ge 2 then rmsfit[ ik] = stddev( a[u])
      endfor
                                ;print, rmsfit

      gdkid = where( rmsfit gt 0 or finite( rmsfit) eq 1 or $
                     rmsfit lt rmslim*median( rmsfit), ngdkid)
      if verb eq 2 then print, ngdkid, ' good kids out of ', nkid
;;;      if narr eq 2 then stop

      newkidpar[ kid[ gdkid]].c0_skydip = -(fit[ gdkid]+fref)
      newkidpar[ kid[ gdkid]].c1_skydip = -fit[ nkid+gdkid]

; Evaluate bad scans
      rmsfit = fltarr( nsc)
      npoint = nam*nsc
      ii = reform( lindgen( nam*nsc*nkid), nam, nsc,  nkid)
      for isc = 0, nsc-1 do begin
         ind = reform( ii[ *, isc, *], nkid*nam)
         ind2 = reform( ii[ *, isc, *], nam, nkid)
         u = where( (finite(yfit-ytot))[ind])
         rmsfit[ isc] = stddev( (yfit-ytot)[ind[u]])
         dtarr[ kid, isc] = mean( (yfit-ytot)[ind2], dim = 1, /nan, /double)/ $
                            newkidpar[kid].c1_skydip ; no test here, just average over one scan and convert to K_RJ what is defined (Nan means not defined)
      endfor

;      print, rmsfit
      bdscan = where( rmsfit eq 0 or finite( rmsfit) eq 0 or $
                      rmsfit gt rmslim*median( rmsfit), nbdscan)
      if verb eq 2 then print, nbdscan, ' bad scans out of ', nsc
      if nbdscan ge 1 then if verb eq 2 then print, bdscan
      if nbdscan ge 1 then if verb eq 2 then print, skdout[ bdscan].scanname
      rmspak[ipak, *] = rmsfit
;;;      if narr eq 2 then stop
   endfor                       ;end loop on ipak
   rmsarr[narr-1, *] = median(rmspak, dim =1 )
endfor                          ; end loop on narr

skdout.dt = dtarr
skdout.rmsa1 = reform(rmsarr[0, *])
skdout.rmsa2 = reform(rmsarr[1, *])
skdout.rmsa3 = reform(rmsarr[2, *])

if keyword_set(doplot) then begin
; Plot new c1 against old c1
   ;;wshet, 2
   wind, 1, 2, /free, xsize=900, ysize=800
   outfile = !nika.save_dir+'/test_allskd4_'+fname+'_2'
   outplot, file=outfile, png=png, xsize=16., ysize=14., charsize=charsize, thick=mythick, charthick=charthick
   !p.multi = [0, 2, 2]
   for lamb = 1, 2 do begin     ; loop on the 2 wavelengths
      
      if lamb eq 1 then lambt = '1 mm'
      if lamb eq 2 then lambt = '2 mm'
      if lamb eq 1 then $
         kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                         kidpar.lambda lt 1.5, nallkid) else $
                            kidall = where( val ge valmax-18 and kidpar.type eq 1 and $
                                            kidpar.lambda gt 1.5, nallkid)
      if verb ge 1 then print, nallkid, ' valid kids  in lambda = ',  lambt
      
      plot, kidpar[ kidall].c1_skydip, newkidpar[ kidall].c1_skydip, $
            xrang = [0, c1lim], yrang = [0, c1lim], /xsty, /ysty, psym = 8, $
            /iso, xtitle='Response [Hz/K] (old kidpar)', $ ;xtitle = 'Response [Hz/K] one-scan', $
            ytitle = 'Response [Hz/K] multi-scan',  $
            title = 'NIKA2 '+runname+', c1 at '+ lambt, thick = 2
      if lamb eq 1 then legendastro, ['Array 1', 'Array 3'], $
                                     psym=[4,4], col=[100,200], box=0, $
                                     textcol=[100,200]
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
           title = 'NIKA2 '+runname+', calib_fix_fwhm, c1 at '+ lambt, thick = 2
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
   ;;jpgout, !nika.save_dir+'/test_allskd4_'+fname+'_2.jpg', /over
   outplot, /close
endif


; Insert here plots of the fit quality
if keyword_set(doplot) then begin

   plot_color_convention, col_a1, col_a2, col_a3, $
                          col_mwc349, col_crl2688, col_ngc7027, $
                          col_n2r9, col_n2r12, col_n2r14, col_1mm
   
; Quality of scans
   ;;wshet, 5
   wind, 1, 4, /free, xsize=750, ysize=550
   outfile = !nika.save_dir+'/test_allskd4_'+fname+'_3'
   outplot, file=outfile, png=png, xsize=11., ysize=6., charsize=charsize, thick=mythick, charthick=charthick
   !p.multi = 0
   plot, rmsarr[ 0, *], indgen(nsc), yrange = [-1, nsc], xsty = 0, /nodata, $
         xrange = [0, max(rmsarr)*2], ysty = 0, $
         title = 'NIKA2 '+runname+', Skydip dispersion', $
         thick = 2, xtitle = 'Median rms [Hz]', ytitle = 'Scan number'
   legendastro, reverse( zeropadd( indgen(nsc), 2)+': '+ $
                         string(scanname, '(A13)')+' ; tau1='+ $
                         string( taufinal1, '(1F6.2)')), $
                box = 0, /bottom, /right, charsize=0.8
   legendastro, psym = [4, 4, 4], ['Arr1', 'Arr3', 'Arr2'], $
                colors = [col_a1, col_a3, col_a2], /top, /right
   oplot, psym = -4, color = col_a1, rmsarr[0, *], indgen(nsc)
   oplot, psym = -4, color = col_a3, rmsarr[2, *], indgen(nsc)
   oplot, psym = -4, color = col_a2, rmsarr[1, *], indgen(nsc)
   ;;jpgout, !nika.save_dir+'/test_allskd4_'+fname+'_3.jpg', /over
   outplot, /close

; Plot Deltac0 per scan
   dtall = rmsarr*0.
   for narr = 1, 3 do begin     ; loop on arrays
      kidall = where( kidpar.type eq 1 and $
                      kidpar.array eq narr, nallkid)       

      ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
      ;; TBC !!!
      if keyword_set(dec2018) then $
         kidall = where( kidpar.c0_skydip ne 0 and kidpar.type eq 1 and $
                         kidpar.array eq narr, nallkid)       
      
      for isc = 0, nsc-1 do begin ; Median function does not exclude Nans
         u = where( finite( dtarr[ kidall, isc]) eq 1, nu)

         ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
         ;; TBC !!!
         if keyword_set(dec2018) then $
            u = where( finite( dtarr[ kidall, isc]) and dtarr[kidall,isc] ne 0, nu)
         
         if nu gt 3 then dtall[narr-1, isc]= $
            median(/double, dtarr[ kidall[ u], isc])
      endfor
      
   endfor
   ;;wshet, 6
   wind, 1, 2, /free, xsize=750, ysize=550
   outfile = !nika.save_dir+'/test_allskd4_'+fname+'_4'
   outplot, file=outfile, png=png, xsize=11., ysize=6., charsize=charsize, thick=mythick, charthick=charthick
   !p.multi = 0
   plot, dtall[ 0, *], indgen(nsc), yrange = [-1, nsc], xsty = 0, /nodata, $
         xrange = [min(dtall), max(dtall)*2], ysty = 0, $
         title = 'NIKA2 '+runname+', Skydip offset', $
         thick = 2, xtitle = 'Median dT [K]', ytitle = 'Scan number'
   legendastro, reverse( zeropadd( indgen(nsc), 2)+': '+ $
                         string(scanname, '(A13)')+' ; tau1='+ $
                         string( taufinal1, '(1F6.2)')), $
                box = 0, /bottom, /right, charsize=0.8
   legendastro, psym = [4, 4, 4], ['Arr1', 'Arr3', 'Arr2'], $
                colors = [col_a1, col_a3, col_a2], /top, /right
   oplot, psym = -4, color = col_a1, dtall[0, *], indgen(nsc)
   oplot, psym = -4, color = col_a3, dtall[2, *], indgen(nsc)
   oplot, psym = -4, color = col_a2, dtall[1, *], indgen(nsc)
   oplot, psym = -3, [0, 0], !y.crange, thick = 2
   ;;jpgout, !nika.save_dir+'/test_allskd4_'+fname+'_4.jpg', /over
   outplot, /close

   ;; restore the usual ct
   loadct, 39
   
endif


end 
