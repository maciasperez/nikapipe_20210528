;;
;; Merge with other redondant versions (all_skydips, all_skydips_3 and
;; all_skydips_4), added keywords
;; -- opacity_per_band: to use the previous version of nk_test_allskd
;;    (before OPERA, Feb 2018) 
;; -- use_atm for constraint estimation and
;; -- file_suffixe to deal with several versions,
;; LP, March 2018
;;
;; Parallelisation of the skydip reduction, NP, Feb 2018 
;;
;; copied from all_skydips.pro, added keywords output_dir and input_scan_list, LP, Jan 2018
;;
;; Reference of Labtools/FXD/N2R7/test_allsk2.scr
;; Finds the optimal C0 and C1 for a collection of reduced skydips in reduce_all_skydips.pro
;;
; Find a fit for all skydips simultaneously
; for several detectors and several scans
; FXD, Dec 2016
; use the nk_allskd routine
;---------------------------------------------------------------

pro all_skydips, runname, kidparfile=kidparfile, $
                 output_dir=output_dir, input_scan_list=input_scan_list, $
                 logbook_dir = logbook_dir, $
                 blacklist_file = blacklist_file, $
                 reset=reset, goodscan = goodscan, $
                 file_suffixe=file_suffixe, $
                 istart = istart, iend = iend, skdout=skdout, $
                 use_atm=use_atm, opacity_per_band=opacity_per_band, $
                 kidpar_out_file=kidpar_out_file,$
                 keep_nighttime_only=keep_nighttime_only, $
                 hybrid=hybrid, dec2018=dec2018, $
                 png=png, ps=ps, pdf=pdf
  
  ;; reduce only the skydips from istart to iend, othewise do them all
  
  ;; example :  
  ;;all_skydips, output_dir='/home/perotto/NIKA/Plots/N2R12/Opacity',$
  ;;reset=0, goodscan = goodscan, $
  ;;kidparfile='kidpar_20171025s41_v2_LP_md_recal_calUranus.fits', runname='N2R12'
  
  force_kidpar = 1
  
  ;; test hybrid file
  if keyword_set(hybrid) then if file_test(hybrid) lt 1 then begin
     print, 'No opacity table for the hybrid method'
     print, 'File not found: ', hybrid
     stop
  endif
  
  if not keyword_set(kidparfile) then begin
     get_nika2_run_info, nika2run         
     index = where(strmatch(nika2run.nika2run, runname[0]) eq 1, n) 
     day   = nika2run[index].firstday
     scan  = strtrim(day+'s1',2)
     nk_get_kidpar_ref, s, d, info, kidparfile, scan=scan
  endif
  
  if not keyword_set(file_suffixe) then suf = '' else suf = strtrim(file_suffixe,2)
;; if not keyword_set(runname) then runname = 'N2R12' ; 'N2R10' ; 'N2R9' ; 'N2R7'
  fname = runname[0]
  print, 'Suffix is ', suf
;; Output kidpar location and file name
  if keyword_set(output_dir) then begin
     outdir = output_dir
     savedir = !nika.save_dir ;; to restore !nika structure before the end 
     !nika.save_dir = outdir
  endif else outdir = !nika.plot_dir
  newkfdir  = outdir            ; not $OFF_PROC_DIR yet for safety
newkfname = 'kidpar_C0C1_'+strupcase(runname[0])+suf+'.fits'
;;;

;; Original kidpar
  kd  = mrdfits( kidparfile,1,h)
  nkd = n_elements( kd)


  
;; restore "scan" from the logbook file
  scan_list = ''
  lbdir = !nika.pipeline_dir+'/Datamanage/Logbook'
  if keyword_set(logbook_dir) then lbdir = logbook_dir
  first_ok = 1                  ; to init the final structure
  nrun = n_elements(runname)
  nmax = 10000.*nrun
  ke = -1L
  for irun=0, nrun-1 do begin
     restore,  lbdir + $
              '/Log_Iram_tel_'+runname[irun]+'_v0.save'

         
     if keyword_set(input_scan_list) then begin
        ;; use an input scan list
        scan_list_0 = input_scan_list
        keep = intarr( n_elements(scan))
        my_all_scan_list = strtrim(scan.day)+"s"+strtrim(scan.scannum,2)
        my_match, my_all_scan_list, input_scan_list, suba, subb
        nmatch = n_elements(suba)
        if nmatch eq 0 then begin
           message, /info, "input_scan_list does not match the list of scans in "+$
                     lbdir+ $
                    '/Log_Iram_tel_'+runname[irun]+'_v0.save'
           stop
        endif
        scan = scan[suba]
        scan_list_0 = scan_list_0[subb]
        nscans = n_elements(scan_list_0)
        message, /info, strtrim(n_elements(input_scan_list),2)+' requested in input_scan_list'
        message, /info, strtrim(nscans,2)+' input scans (after match with logbook)'
        if nscans gt 0 then scan_list=[scan_list, scan_list_0]
     endif else begin
        ;; retrieve scans from the 'Log' file
        source = 'TipCurrentAzimuth'
        obstype = 'DIY'         ; Skydips
        indscan = nk_select_scan( scan, source, obstype, nscans, avoid = avoid_list)
        print, nscans, ' scans found'
        scan1 = scan[indscan]
        scan = scan1
        if keyword_set(keep_nighttime_only) then begin
           ;; from 21:00 to 09:00 UT
           discard_daytime_scans, scan.date, index ;;, night_begin = night_begin, night_end=night_end
           scan1 = scan[index]
           scan = scan1
        endif
        scan_list_0 = scan.day + 's' + strtrim( scan.scannum,2)
        
        print, 'Projects found: ', scan[ uniq( scan.projid)].projid
        print,'Tau 225: ', scan.tiptau225GHz
        
        if n_elements(scan_list_0) gt 0 then scan_list = [scan_list, scan_list_0]
        
     endelse

     ;; as in nk_get_all_scan
     nsc = n_elements( scan)
     if first_ok eq 1 then begin
        sc = replicate( scan[0], nmax)
        first_ok = 0
     endif
     kb = ke+1
     ke = kb+nsc-1
     sc[kb:ke] = scan
  endfor
  scan = sc
  if n_elements(scan_list) gt 1 then scan_list=scan_list[1:*]
  nscans = n_elements(scan_list)
  
  
  print, 'List of found skydip scans', scan_list

;; Reject bad scans
  message, /info, strtrim(nscans,2)+' input scans (before checking the black list)'

  blf = !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(runname[0])+suf+".dat"
  if keyword_set(blacklist_file) then blf = blacklist_file 
  if file_test( blf) eq 1 then begin
     print, 'Reading blacklist file ', blf
     readcol, blf, badscans, format='A', /silent
     my_match, scan_list, badscans, suba, subb ;, nmatch
     keep = lonarr(nscans) + 1
     if suba[0] ne -1 then nmatch = n_elements(suba) else nmatch=0
     if nmatch ne 0 then keep[suba] = 0
     w = where( keep eq 1)
     scan_list = scan_list[w]
  endif
  
  nscans = n_elements( scan_list)
  message, /info, strtrim(nscans,2)+" scans finally selected."
  nkid = 3000
;;---------------------------------------------------------
;; Reduce skydip scans if needed
  !nika.save_dir = outdir
  if keyword_set( istart) then indstart = istart else indstart = 0
  if keyword_set( iend)   then indend   = iend   else indend   = nscans-1

;; Which scans do we need to process:
  tbp_scan_list = scan_list[indstart:indend]
  nscans_tbp = n_elements(tbp_scan_list)
  if keyword_set(reset) then begin
     for i=0, nscans_tbp-1 do begin
        spawn, "rm -rf "+outdir+"/Skydips/"+strtrim(tbp_scan_list[ i], 2)
;        spawn, "rm -rf "+outdir+"/Skydips/"+scanname
     endfor
  endif
  keep = intarr(nscans_tbp) + 1
  for i=0, nscans_tbp-1 do begin
     if file_test(outdir +"/Skydips/"+strtrim(tbp_scan_list[i],2)+"/results.save") eq 1 then keep[i] = 0
  endfor


;; Process scans that need it
  w = where( keep eq 1, nw)
  if nw ge 1 then begin
     tbp_scan_list = tbp_scan_list[w]
     nscans_tbp = n_elements(tbp_scan_list)
;     skydip_sub, 0, tbp_scan_list, outdir, kidparfile, output_dir  ;;;;
;     stop ;;;
     nproc = min([nscans_tbp, 20])
     
     ;; JFMP, 28 March 2020 : do analysis before blacklisting scans
     split_for, 0, nscans_tbp-1, nsplit=nproc, $
                commands='skydip_sub, i, tbp_scan_list, outdir, kidparfile, output_dir', $
                varnames=['tbp_scan_list', 'outdir', 'kidparfile', 'output_dir']
     ;; JFMP: end 28 March 2020
     
     ;; LP, March 2020: black list the scans that could not be processed
     ;; if any
     test_scan_list = scan_list[indstart:indend]
     test_nscans = n_elements(test_scan_list)
     keep = intarr(test_nscans)+1
     for i=0, test_nscans-1 do if file_test(outdir +"/Skydips/"+strtrim(test_scan_list[i],2)+"/results.save") lt 1 then keep[i] = 0
     w = where( keep lt 1, nw, compl=wok, ncompl=nok)
     if nw ge 1 then begin
        ;;blacklist_file = !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(runname[0])+suf+".dat"   
        if file_test( blf) eq 1 then begin
           readcol, blf, blacklist, format='A', /silent
           blacklist = [blacklist, test_scan_list[w]]
        endif else blacklist = test_scan_list[w]
        openw, lun2, blf, /get_lun
        nout = n_elements(blacklist)
        for i=0, nout-1 do printf, lun2, blacklist[i]
        close, lun2
        free_lun, lun2
     
        if nok gt 0 then begin
           scan_list = test_scan_list[wok]
           nscans    = n_elements(scan_list)
        endif else begin
           print, 'all skydip-scan processing failure'
           stop
        endelse
     endif      
  endif
  
  
;;---------------------------------------------------------
;; Gather results from all scans
  for isc=0, nscans-1 do begin
     scanname = strtrim(scan_list[isc],2)
     result_dir = outdir +"/Skydips/"+scanname
     file_save  = result_dir+"/results.save"
     
     if file_test(file_save) then begin
        restore, file_save
        dout = replicate( {f_tone:dblarr(nkid), df_tone:dblarr(nkid), el:0D0, tau225:0D0, tau1:0D0, tau2:0D0}, 11L)
        skydipout = {scanname:'', $
                     tiptau225GHz: 0.D0, $
                     tatm:0D0,$
                     tau1:0.,  tau2:0., $
                     c0: dblarr(nkid), c1: dblarr(nkid), c0alt: dblarr(nkid)   }
        
        nkidpar = n_elements( kidpar)
        skydipout. scanname = scanname
        skydipout. tiptau225GHz = scan[ isc].tiptau225GHz
        skydipout. tatm = scan[ isc].tambient_c+273.23
        if info.status eq 0 and $
           nkidpar le nkid then begin
           match, kidpar.numdet, kd.numdet, na, nb
           nel = n_elements( na)
           skydipout. tau1 = info.result_tau_1mm
           skydipout. tau2 = info.result_tau_2mm
           skydipout. c0[nb] = kidpar[na].c0_skydip
           skydipout. c1[nb] = kidpar[na].c1_skydip
           skydipout. c0alt[nb] = kidout[na].c0_skydip
           ndred = n_elements( dred)
           if ndred lt 10 then message, /info, $
              '  --> Strange number of subscans'+ strtrim( ndred, 2)+ ' '+ scanname
           ist = 0
;;; iend -> ie (conflicting with iend in call to all_skydips !)
           ie = ist+ndred-1
           if total(finite( dred.f_tone[na])) lt 0.8*nel then begin
              print, total(finite( dred.f_tone[na])), ' = ? 10 times ', nel
              print, total(finite( dred.df_tone[na]))
              print, total(finite( dred.df_tone[na]),1)
              message, /info, 'Check !!!'
           endif
           
           dout[ist:ie].f_tone[nb] = dred.f_tone[na]
           dout[ist:ie].df_tone[nb] = dred.df_tone[na]
           dout[ist:ie].tau225 = scan[ isc].tiptau225GHz
           dout[ist:ie].tau1 = info.result_tau_1mm
           dout[ist:ie].tau2 = info.result_tau_2mm
           dout[ist:ie].el = dred.el
        endif else if info.status eq 0 then $
           print, info.status, '  ', nkidpar, ' gt ', nkid
        print, 'Writing ','Test_skydip2_'+scanname+'.save' 
        save, file = outdir+'/Test_skydip2_'+scanname+'.save', $
              kidpar, kidout, skydipout, dout
     endif
     
  endfor
  
 
;;-------------------------------------------------------
;; Gather all results and fit optimals C0's and C1's
;; /help just informative: gives the list of scans
  nk_test_allskd4, fname, kidparfile, newkidpar, runname[0], $
                   scanin=scan_list, /help, istart = istart, iend = iend
;; nk_test_allskd3 replaced by nk_test_allskd4 :
;; One tau per array 1 and 3 (OPERA), Feb. 20th, NP according
;; to Xavier's prescription

  ;; Does the actual job
  if keyword_set(opacity_per_band) then begin
     nk_test_allskd3, fname, kidparfile, newkidpar, runname[0], $
                      goodscan = goodscan, $
                      verb = 1, doplot = 1, rmslim = 3., scanin=scan_list, $
                      skdout = skdout, istart = istart, iend = iend
     
  endif else begin
     ;; opacity per array
     if keyword_set(use_atm) then begin
        ;; use a prior from the ATM model to fit tau A2 (LP)
        nk_test_allskd5, fname, kidparfile, newkidpar, runname[0], $
                         goodscan = goodscan, $
                         verb = 1, doplot = 1, rmslim = 3., scanin=scan_list, $
                         skdout = skdout, istart = istart, iend = iend
     endif else begin
        ;; here we are :
        nk_test_allskd4, fname, kidparfile, newkidpar, runname[0], $
                         goodscan = goodscan, $
                         verb = 1, doplot = 1, png=png, ps=ps, pdf=pdf, $
                         rmslim = 3., scanin=scan_list, $
                         skdout = skdout, istart = istart, iend = iend, $
                         hybrid=hybrid, dec2018=dec2018
                         
     endelse
  endelse
  
;; Write the final kidpar file
  kidpar_out_file = newkfdir+'/'+newkfname
  nk_write_kidpar, newkidpar, kidpar_out_file

;; save the fit results
;;;  savefile = newkfdir+'/all_skydip_fit_'+runname+suf+".save"
savefile = newkfdir+'/all_skydip_fit_'+strupcase(runname[0])+suf+".save"
;;;
  save, skdout, filename=savefile
  
;; ;; wshet does not work on nika2a
;; wshet, 1
;; jpgout,'$SAVE/test_allskd1mm_2mm_'+fname+'.jpg',/over
;; wshet, 2
;; jpgout,'$SAVE/test_allskd1mm_2mm_coeff'+fname+'.jpg',/over
  
end
