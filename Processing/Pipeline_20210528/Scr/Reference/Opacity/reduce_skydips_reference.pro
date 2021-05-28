;;
;;   REFERENCE LAUNCHER SCRIPT OF ALL_SKYDIPS
;;
;;   LP, April 2018
;;_________________________________________________

;input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'
;reduce_skydips_reference, 'N2R9', input_kidpar_file, baseline=1, $
;                          hightau2=0, atmlike=0, $
;                          output_dir='/home/ponthieu/NIKA/Plots/N2R9/Opacity', $
;                          showplot=1, png=png, $
;                          do_first_iteration=0, $
;                          do_skydip_selection=0, $
;                          do_second_iteration=0, $
;                          check_after_selection=0, $
;                          reiterate=0



pro reduce_skydips_reference, runname, input_kidpar_file, baseline=baseline, $
                              root_dir = root_dir, $
                              output_dir = output_dir, $
                              logbook_dir = logbook_dir, $
                              nostop=nostop, $
                              hightau2=hightau2, atmlike=atmlike, $
                              showplot=showplot, png=png, ps=ps, pdf=pdf, $
                              do_first_iteration=do_first_iteration, $
                              do_skydip_selection=do_skydip_selection, $
                              do_second_iteration=do_second_iteration, $
                              check_after_selection=check_after_selection, $
                              reiterate=reiterate, input_scan_list=input_scan_list, dec2018=dec2018, $
                              output_skydip_scan_list=output_skydip_scan_list, skdout = skdout
  

;; directory of the output kidpar
;; (and skydip result files if processing is needed)
;; default is getenv('NIKA_PLOT_DIR')+'/'+runname+'/Opacity'

  
  if keyword_set(output_dir) then $
     output_dir = output_dir else if keyword_set(root_dir) then $
        output_dir = root_dir+'/Opacity' else $
           output_dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]+'/Opacity'
  
  if file_test(output_dir, /directory) gt 1 then spawn, "mkdir -p "+output_dir

  if keyword_set(nostop) then nostop = 1 else nostop = 0 

  ;; REFERENCE ANALYSIS STEPS 
  ;;------------------------------------------------------------------------------

  ;; 1. first iteration using all available skydip scans
  if keyword_set(do_first_iteration) then do_first_iteration = 1 else do_first_iteration=0
  
  ;; 2. skydip selection
  if keyword_set(do_skydip_selection) then do_skydip_selection = 1 else do_skydip_selection=0
  rmscut = [4.0D4, 4.0D4] ;; Hz 
  dtcut  = [2.0D0, 4.0D4] ;; 3.0D0 ;; K
  tau3cut = 2.0
  if keyword_set(hightau2) then tau3cut = 0.6
  if keyword_set(hightau2) then tau3cut = 0.8   ;; high tau2 light
  if keyword_set(baseline) then rmscut  = [2.0D4,2.0D4]  ;; Hz 
  if keyword_set(baseline) then begin
     ;; LP 2020 Nov : release a bit the criterion on rms 
     ;;rmscut  = [1.5D4, 1.5D4]                 ;; Hz at 1 and 2 mm (2x median(rms) = 1.8 )
     rmscut = [2.0D4, 2.0d4]
     dtcut   = [1.6D0, 5D0]                   ;; K  at 1 and 2 mm (2 x stddev(dt))
     if baseline gt 1 then tau3cut = 0.9
     if baseline gt 2 then tau3cut = 0.8
  endif
  
  ;; 3. second iteration using skydip selection
  if  keyword_set(do_second_iteration) then do_second_iteration = 1 else do_second_iteration =0

  
  ;; REFERENCE ANALYSIS PARAMETERS
  ;;------------------------------------------------------------------------------
  ;; opacity per band or per array (default setting is per array: opacity_per_band=0)
  opacity_per_band=0


  ;; to deal with versions of the analysis
  base_file_suffixe = ''

  ;; skydip scans can be input either by defining input_scan_list or by
  ;; an automatic selection in a 'log file'
  input_scan_list = 0 ;; to extract the scan list from the log book file 

;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; scan selection
;; edit
;; !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(runname)+file_suffixe+".dat"
;; and add outlier scan names 
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ;; select scans observed from 21:00 to 09:00
  select_night = 0

  ;; reduce all skydip scans
  reset = 0 ;; if 1, force the re-analysis of all scans 

  ;; input reference kidpar file (for skydip reduction and as a basis
  ;; for the output kidpar)
  kidparfile = input_kidpar_file
  
  ;; Hybrid method: tau for A2 deduced from tau A1, A3 and an ATM model
  ;; hybrid = !nika.pipeline_dir+'/Datamanage/tau_arrays_April_2018.dat'
  hybrid=''

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  END OF PARAMETER SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; launch
;;---------------------------------------------------------------------------------

;; 1/ first iteration using all skydip scans
  if do_first_iteration gt 0 then begin
     print, ''
     print, 'FIRST ITERATION OF THE SKYDIP ANALYSIS'
     print, '-----------------------------------'
     file_suffixe = base_file_suffixe+'_v0'
     skdout=1
     goodscan=0
     blacklist_file = output_dir+"/blacklist_"+strupcase(runname[0])+file_suffixe+'.dat'
     if file_test( blacklist_file) then message, /info, 'Will use this black list '+ $
        blacklist_file else print, 'No black list file found: use all scans, '+ $
        blacklist_file
     all_skydips, runname, output_dir=output_dir, input_scan_list=input_scan_list, $
                  logbook_dir = logbook_dir, $
                  blacklist_file = blacklist_file, $
                  reset=reset, goodscan = goodscan, kidparfile=kidparfile, $
                  file_suffixe=file_suffixe, $
                  istart = istart, iend = iend, skdout=skdout, $
                  opacity_per_band=opacity_per_band, hybrid=hybrid, $
                  png=png, ps=ps, pdf=pdf
     print, ''
     print, '  END OF THE FIRST ITERATION'
     if nostop lt 1 then begin
        print, '  To continue ?'
        rep=''
        read, rep
     endif
  endif
  selected_skydip_list = skdout.scanname ; Default if not updated
  
;; Plotting v0 
  if (keyword_set(showplot) and do_second_iteration lt 1 and do_skydip_selection lt 1 and check_after_selection lt 1) then begin
     
     file_suffixe = base_file_suffixe+'_v0'
     
     kidpar = mrdfits(kidparfile,1)
     testkidpar_file = output_dir+'/kidpar_C0C1_'+strupcase(runname[0])+strtrim(file_suffixe, 2)+'.fits'
     print, "test kidpar = ", testkidpar_file
     newkidpar = mrdfits(testkidpar_file, 1)
     
     testsave_file = output_dir+'/all_skydip_fit_'+strupcase(runname[0])+strtrim(file_suffixe,2)+'.save'
     print, "test save = ",  testsave_file
     restore, testsave_file, /v
     
     if opacity_per_band lt 1 then begin 
        plot_test_allskd4, skdout, kidpar, newkidpar, $
                           plotdir=output_dir, png=png, ps=ps, pdf=pdf, $
                           runname=runname[0], file_suffixe=file_suffixe
     endif else begin
        plot_test_allskd3, skdout, kidpar, newkidpar, plotdir=output_dir, png=png, $
                           runname=runname[0], file_suffixe=file_suffixe
     endelse

     print, ''
     print, '  END OF PLOTTING RESULTS AFTER THE FIRST ITERATION'
     if nostop lt 1 then begin
        rep = ''
        print, '  Delete all windows and continue ? '
        read, rep
        stop
     endif
     wd, /a
  endif
  
;; 2/ Skydip scan selection
  if do_skydip_selection gt 0 then begin
     
     print, ''
     print, 'SKYDIP SELECTION'
     print, '-----------------------------------'
     file_suffixe = base_file_suffixe+'_v0'
     
     testkidpar_file = output_dir+'/kidpar_C0C1_'+strupcase(runname[0])+strtrim(file_suffixe, 2)+'.fits'
     print, "kidpar = ", testkidpar_file
     newkidpar = mrdfits(testkidpar_file, 1)
     
     testsave_file = output_dir+'/all_skydip_fit_'+strupcase(runname[0])+strtrim(file_suffixe,2)+'.save'
     print, "skydip struct = ",  testsave_file
     restore, testsave_file, /v

     ;; test for an existing blacklist for the first iteration
     ;;blacklist_to_update = !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(runname)+file_suffixe+'.dat'
     blacklist_to_update = output_dir+"/blacklist_"+strupcase(runname[0])+file_suffixe+'.dat'
     if file_test(blacklist_to_update) lt 1 then blacklist_to_update=''

     if keyword_set(atmlike) then suf = '_atmlike' else $
        if keyword_set(hightau2) then suf = '_hightau2' else $
           if keyword_set(baseline) then suf = '_baseline' else suf = ''
     if keyword_set(baseline) then begin
        if baseline gt 1 then suf=suf+'_v'+strtrim(string(baseline),2)
     endif
              
     
     ;;blacklist_file = !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(runname)+base_file_suffixe+suf+'.dat'
     blacklist_file = output_dir+"/blacklist_"+strupcase(runname[0])+base_file_suffixe+suf+'.dat'
     
     print, ''
     print, ' Cut values : '
     print, '    -- RSM_1mm  < ', rmscut[0], ' Hz'
     print, '    -- RSM_2mm  < ', rmscut[1], ' Hz'
     print, '    -- dT_1mm   < ', dtcut[0] , ' K'
     print, '    -- dT_2mm   < ', dtcut[1] , ' K'
     print, '    -- tau3 < ', tau3cut
     pname = strupcase(runname[0])+strtrim(base_file_suffixe,2)+suf
     selected_skydip_list = 1
     select_skydips, skdout, newkidpar, blacklist_file, $
                     dtcut=dtcut, rmscut=rmscut, tau3cut=tau3cut, $
                     plotdir =  output_dir, plotname=pname , png=png, ps=ps, pdf=0, $
                     blacklist_to_update=blacklist_to_update, dec2018=dec2018, $
                     selected_skydip_list = selected_skydip_list

     print, ''
     print, '  END OF SKYDIP SCAN SELECTION'
     if nostop lt 1 then begin
        rep = ''
        print, '  Delete all windows and continue ? '
        read, rep
        stop
     endif
     wd, /a
 
  endif
  
  ;; 3/ second iteration using the chosen skydip selection
  if do_second_iteration gt 0 then begin
     print, ''
     print, 'SECOND ITERATION OF THE SKYDIP ANALYSIS'
     print, '-----------------------------------'
     if keyword_set(atmlike) then suf = '_atmlike' else $
        if keyword_set(hightau2) then suf = '_hightau2'  else $
           if keyword_set(baseline) then suf = '_baseline' else suf = ''
     if keyword_set(baseline) then begin
        if baseline gt 1 then suf=suf+'_v'+strtrim(string(baseline),2)
     endif
          
     file_suffixe = base_file_suffixe+suf
     if keyword_set(reiterate) then file_suffixe = file_suffixe+reiterate

     ;; test blacklist_file
     ;;blf = !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(runname)+file_suffixe+".dat"
     blf =  output_dir+"/blacklist_"+strupcase(runname[0])+file_suffixe+".dat"
     if file_test(blf) gt 0 then begin
        print, "Will use blacklist = ", blf
        skdout=1
        goodscan=0
        all_skydips, runname, output_dir=output_dir, input_scan_list=input_scan_list, $
                     logbook_dir = logbook_dir, $
                     blacklist_file = blf, $
                     reset=reset, goodscan = goodscan, kidparfile=kidparfile, $
                     file_suffixe=file_suffixe, $
                     istart = istart, iend = iend, skdout=skdout, $
                     opacity_per_band=opacity_per_band, hybrid=hybrid, dec2018=dec2018, $
                     png=png, ps=ps, pdf=pdf
     endif else begin
        ;; the black list file has not been created at the skydip
        ;; selection step: means no outliers
        print, "No new skydip selection..."
        print, "The new C0, C1 kidpar, kidpar_C0C1_"+strupcase(runname[0])+file_suffixe+".fits"
        print, "is a copy of kidpar_C0C1_"+strupcase(runname[0])+base_file_suffixe+"_v0.fits" 
        cmd = "cp "+output_dir+"/kidpar_C0C1_"+strupcase(runname[0])+base_file_suffixe+"_v0.fits "+output_dir+"/kidpar_C0C1_"+strupcase(runname[0])+file_suffixe+".fits "
        spawn, cmd
        cmd = "cp "+output_dir+"/all_skydip_fit_"+strupcase(runname[0])+base_file_suffixe+"_v0.save "+output_dir+"/all_skydip_fit_"+strupcase(runname[0])+file_suffixe+".save "
        spawn, cmd
     endelse

     print, ''
     print, '  END OF SECOND C0, C1 ESTIMATE USING THE SELECTION'
     if nostop lt 1 then begin
        rep = ''
        print, '  Delete all windows and continue ? '
        read, rep
     endif
     wd, /a
  endif

  ;; checking v2
  if keyword_set(check_after_selection) then begin
     print, ''
     print, 'SKYDIP SELECTION CHECKING'
     print, '-----------------------------------'
     if keyword_set(atmlike) then suf = '_atmlike' else $
        if keyword_set(hightau2) then suf = '_hightau2'  else $
           if keyword_set(baseline) then suf = '_baseline' else suf = ''
     if keyword_set(baseline) then begin
        if baseline gt 1 then suf=suf+'_v'+strtrim(string(baseline),2)
     endif
          
     if keyword_set(reiterate) then suf = suf+reiterate
     file_suffixe = base_file_suffixe+suf
     
     testkidpar_file = output_dir+'/kidpar_C0C1_'+strupcase(runname[0])+strtrim(file_suffixe, 2)+'.fits'
     print, "kidpar = ", testkidpar_file
     newkidpar = mrdfits(testkidpar_file, 1)
     
     testsave_file = output_dir+'/all_skydip_fit_'+strupcase(runname[0])+strtrim(file_suffixe,2)+'.save'
     print, "skydip struct = ",  testsave_file
     restore, testsave_file, /v
     blacklist_to_update = output_dir+"/blacklist_"+strupcase(runname[0])+file_suffixe+'.dat'
     blacklist_file = output_dir+"/blacklist_"+strupcase(runname[0])+file_suffixe+'_check.dat'
     
     print, ''
     print, ' Cut values : '
     print, '    -- RSM_1mm  < ', rmscut[0], ' Hz'
     print, '    -- dT_1mm   < ', dtcut[0] , ' K'
     print, '    -- RSM_2mm  < ', rmscut[1], ' Hz'
     print, '    -- dT_2mm   < ', dtcut[1] , ' K'
     print, '    -- tau3 < ', tau3cut
     pname = strupcase(runname[0])+strtrim(base_file_suffixe,2)+suf+'_check'
     check_selected_skydip_list = 1
     select_skydips, skdout, newkidpar, blacklist_file, dtcut=dtcut, rmscut=rmscut, tau3cut=tau3cut, $
                     plotdir =  output_dir, plotname=pname , png=png, ps=ps, pdf=pdf, $
                     blacklist_to_update=blacklist_to_update, dec2018=dec2018, $
                     selected_skydip_list=check_selected_skydip_list

     if nostop lt 1 then stop
  endif

     
  ;; Plotting v2
  if keyword_set(showplot) then begin
     
     if keyword_set(atmlike) then suf = '_atmlike' else $
        if keyword_set(hightau2) then suf = '_hightau2'  else $
           if keyword_set(baseline) then suf = '_baseline' else suf = ''
     if keyword_set(baseline) then begin
        if baseline gt 1 then suf=suf+'_v'+strtrim(string(baseline),2)
     endif

     file_suffixe = base_file_suffixe+suf
     if keyword_set(reiterate) then file_suffixe = file_suffixe+reiterate
     
     kidpar = mrdfits(kidparfile,1)
     testkidpar_file = output_dir+'/kidpar_C0C1_'+strupcase(runname[0])+strtrim(file_suffixe, 2)+'.fits'
     print, "test kidpar = ", testkidpar_file
     newkidpar = mrdfits(testkidpar_file, 1)
     
     testsave_file = output_dir+'/all_skydip_fit_'+strupcase(runname[0])+strtrim(file_suffixe,2)+'.save'
     print, "test save = ",  testsave_file
     restore, testsave_file, /v
     if opacity_per_band lt 1 then begin 
        plot_test_allskd4, skdout, kidpar, newkidpar, $
                           plotdir=output_dir, png=png, ps=ps, pdf=pdf, $
                           runname=runname[0], file_suffixe=file_suffixe, dec2018=dec2018
     endif else begin
        plot_test_allskd3, skdout, kidpar, newkidpar, plotdir=output_dir, $
                           png=png, ps=ps, pdf=pdf, $
                           runname=runname[0], file_suffixe=file_suffixe, dec2018=dec2018
     endelse
  endif


  
;;; FINAL PLOTS

  if keyword_set(atmlike) then suf = '_atmlike' else $
     if keyword_set(hightau2) then suf = '_hightau2'  else $
        if keyword_set(baseline) then suf = '_baseline' else suf = ''
  if keyword_set(baseline) then begin
     if baseline gt 1 then suf=suf+'_v'+strtrim(string(baseline),2)
  endif
       
  file_suffixe = base_file_suffixe+suf
  
  kpref = mrdfits(kidparfile,1)
  
  kpnew = mrdfits(output_dir+'/kidpar_C0C1_'+strupcase(runname[0])+strtrim(file_suffixe)+'.fits', 1)
  
  wr = where( kpref.type eq 1, nw1)
  w  = where( kpnew.type eq 1, nw)
  kpref = kpref[wr]
  kpnew = kpnew[w]
  my_match, kpref.numdet, kpnew.numdet, suba, subb
  kpref = kpref[suba]
  kpnew = kpnew[subb]
  
  wa1 = where(kpref.array eq 1)
  wa2 = where(kpref.array eq 2)
  wa3 = where(kpref.array eq 3)
  
  wind, 1, 1, /free, xsize=1200, ysize=550
  
  dir = output_dir
  outplot, file=dir+'/Coefficient_checks_'+runname[0]+file_suffixe, png=png, ps=ps
  my_multiplot, 2, 1, pp, pp1, /rev, gap_x=0.1, xmargin=0.1, ymargin=0.09 ; 1e-6
  w=where(abs(kpref.c0_skydip) gt 1d-10, nw)
  if nw ne 0 then begin  ; If nothing exists for c0 previous to this analysis, plot is meaningless, FXD
     plot, kpref[w].c0_skydip,  kpnew[w].c0_skydip-kpref[w].c0_skydip, /nodata, xtitle="C0, ref kidpar", ytitle = "C0, new-to-ref kidpar difference", pos=pp1[0, *], yr=[-3d5, 3d5], /ys
     oplot, kpref[wa1].c0_skydip,  kpnew[wa1].c0_skydip-kpref[wa1].c0_skydip, psym=8, col=200, symsize=1
     oplot, kpref[wa2].c0_skydip,  kpnew[wa2].c0_skydip-kpref[wa2].c0_skydip, psym=8, col=80, symsize=0.8
     oplot, kpref[wa3].c0_skydip,  kpnew[wa3].c0_skydip-kpref[wa3].c0_skydip, psym=8, col=250, symsize=0.8
     ind=indgen(1000)*min(kpref.c0_skydip)/999.
     oplot,ind ,ind*0., col=0
  endif
  !p.multi = [0, 1, 2]
  plot, kpref.c1_skydip,  kpnew.c1_skydip, /nodata, xtitle="C1, ref kidpar", ytitle = "C1, new kidpar", pos=pp1[1, *], /noerase
  oplot, kpref[wa1].c1_skydip,  kpnew[wa1].c1_skydip, psym=8, col=200, symsize=1
  oplot, kpref[wa2].c1_skydip,  kpnew[wa2].c1_skydip, psym=8, col=80, symsize=0.8
  oplot, kpref[wa3].c1_skydip,  kpnew[wa3].c1_skydip, psym=8, col=250, symsize=0.8
  ind=indgen(1000)*3.
  oplot,ind ,ind, col=0
  legendastro, ['A1', 'A3', 'A2'], col=[200, 250, 80], psym=[8, 8, 8], textcolor=[200, 250, 80],box=0
  
  print, "A1 median C0 diff = ", median( kpnew[wa1].c0_skydip-kpref[wa1].c0_skydip)*1d-4
  print, "A3 median C0 diff = ", median( kpnew[wa3].c0_skydip-kpref[wa3].c0_skydip)*1d-4
  print, "A2 median C0 diff = ", median( kpnew[wa2].c0_skydip-kpref[wa2].c0_skydip)*1d-4
  
  !p.multi=0
  outplot, /close

  if keyword_set(output_skydip_scan_list) then output_skydip_scan_list = selected_skydip_list

  
end
