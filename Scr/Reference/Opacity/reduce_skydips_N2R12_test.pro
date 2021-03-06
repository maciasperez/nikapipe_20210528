;;
;;   LAUNCHER SCRIPT OF ALL_SKYDIPS FOR N2R12
;;
;;_________________________________________________


;; directory of the output kidpar
;; (and skydip result files if processing is needed)
;; default is !nika.plot_dir
output_dir = '/home/perotto/NIKA/Plots/N2R12/Opacity'

;; run name
runname = 'N2R12'

;; opacity per array
opacity_per_band = 0

;; skydip scans can be input either by defining input_scan_list or by
;; an automatic selection in a 'log file'

input_scan_list = 0 ;; to extract the scan list from the log book file 

;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; scan selection
;; edit
;; !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(runname)+".dat"
;;
;; test branche 1 :
;;['20171019s38', '20171019s45', '20171020s94', '20171020s95', '20171021s168',$
;; '20171021s226', '20171023s99', '20171023s126', '20171024s94', '20171024s196',$
;; '20171025s43']
file_suffixe = '_branch1'
;;['20171019s45', '20171020s94', '20171020s95', '20171021s168',$
;; '20171021s226', '20171023s99', '20171023s126', '20171024s94', '20171024s196',$
;; '20171025s43']
file_suffixe = '_branch1_v2'
;;
;; test branche 2 :
;;['20171026s183', '20171027s27', '20171027s95', '20171028s185', '20171028s231', '20171029s73']
file_suffixe = '_branch2'

;;file_suffixe=''

file_suffixe='_v2'

file_suffixe='_opera'

;;file_suffixe='_opera_iter'

;; and add outlier scan names 
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;; reduce all skydip scans
reset = 0 ;; if 1, force the re-analysis of all scans 

;; input reference kidpar file (for skydip reduction and as a basis
;; for the output kidpar)
;; must be in !nika.off_proc_dir

kidparfile = 'kidpar_20171025s41_v2_LP_md_recal_calUranus.fits'

;; KEEP THESE 2 OPTIONS TO ZERO
;; method using 2 iterations
two_iter = 0
;; reitere
reiterate = 0


;; redo plots
redo_plot = 0
png=0

;; consistency tests
do_test = 0



;; reduce only the skydips from istart to iend, othewise do them all


;; launch
;;---------------------------------------------------------------------------------
if (redo_plot lt 1 and do_test lt 1 and reiterate lt 1) then begin
   skdout=1
   all_skydips, output_dir=output_dir, input_scan_list=input_scan_list, $
                reset=reset, goodscan = goodscan, kidparfile=kidparfile, $
                runname=runname, file_suffixe=file_suffixe, $
                istart = istart, iend = iend, skdout=skdout, $
                opacity_per_band = opacity_per_band
endif else begin 
   
   kidpar = mrdfits(!nika.off_proc_dir+'/'+kidparfile,1)
   testkidpar_file = output_dir+'/kidpar_N2R12'+strtrim(file_suffixe)+'_skydip.fits'
   print, "test kidpar = ", testkidpar_file
   newkidpar = mrdfits(testkidpar_file, 1)
   testsave_file = output_dir+'/all_skydip_fit_N2R12'+strtrim(file_suffixe)+'.save'
   print, "test save = ",  testsave_file
   restore, testsave_file, /v

   
   if reiterate gt 0 then begin
      print, "reiterate"
      kidpar = newkidpar
      skdin = skdout
      savedir = !nika.save_dir
      !nika.save_dir = output_dir
      nk_test_allskd4_reiter, kidpar, newkidpar, runname, skdin, $
                              verbose = verbose, doplot = 1, rmslim = rmslim, $
                              help = k_help,  goodscan = goodscan, $
                              skdout = skdout, istart = istart, iend = iend
      
      ;; Write the final kidpar file
      nk_write_kidpar, newkidpar, output_dir+'/kidpar_'+runname+strtrim(file_suffixe)+'_iter2_skydip.fits'
      
      ;; save the fit results
      savefile = output_dir+'/all_skydip_fit_'+runname+strtrim(file_suffixe)+"_iter2.save"
      save, skdout, filename=savefile
      
      ;; restore !nika.plot_dir if modified
      !nika.save_dir = savedir
      
      stop
      
   endif

   
   if redo_plot gt 0 then begin
      if opacity_per_band lt 1 then begin
         plot_test_allskd4, skdout, kidpar, newkidpar, plotdir=output_dir, png=png, $
                            runname=runname, file_suffixe=file_suffixe
      endif else begin
         plot_test_allskd3, skdout, kidpar, newkidpar, plotdir=output_dir, png=png, $
                            runname=runname, file_suffixe=file_suffixe
      endelse
   endif
   
   if do_test gt 0 then begin
      
      nk_default_param, param
      param.force_kidpar = 1
      param.file_kidpar  =  testkidpar_file
      
      param.do_opacity_correction=4-2*opacity_per_band
      nk_default_info, info
      
      scanname = skdout.scanname
      nsc = n_elements(scanname)
      
      tau_recalc = dblarr(nsc, 4)
      for isc = 0, nsc-1 do begin
         
         filin = output_dir+'/Test_skydip2_'+ $
                  scanname[ isc]+ '.save'
         print, strtrim( isc, 2), ' ',  filin
         restore, file = filin, verb = 0

         scansub= where(dout.el gt 0, nscansub)
         if nscansub gt 8 then begin 
         
            
            ;; Update dout with subscan and scan_valid for
            ;; ingestion in nk_get_opacity
            tags  = tag_names(dout)
            ntags = n_elements(tags)
            data = dout[0]
            data = create_struct( data, $
                                  "subscan", 1, $
                                  "scan_valid", [0, 0], $
                                  "toi", dout.f_tone*0.+1.  )
            ;; Upgrade to number of elements
            data = replicate( data, n_elements(dout))
            ;; Copy each field of the input data
            tags_out = tag_names(data)
            my_match, tags_out, tags, suba, subb
            for i=0, n_elements(suba)-1 do data.(suba[i]) = dout.(subb[i])
            
            
            nk_get_opacity, param, info, data, newkidpar
            tau_recalc[isc, 0] = info.result_tau_1
            tau_recalc[isc, 1] = info.result_tau_3
            tau_recalc[isc, 2] = info.result_tau_1mm
            tau_recalc[isc, 3] = info.result_tau_2mm
         endif else begin
            print,''
            print, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            print, scanname[ isc], ": only ", nscansub, " pts"
            print, ''
         endelse
      endfor

      logfile =  '/mnt/data/NIKA2Team/perotto/Plots/N2R12/Opacity/Log_Opacity_N2R12_opera.save'
      restore, logfile, /v
      wskd = where(scan.obstype eq 'DIY', nskd)
      scan = scan[wskd]
      print, "skydip list : ", scan.day+'s'+strtrim(scan.scannum,2)
      

      png=0
      wind, 1, 1, /free,xsize=600, ysize=550
      ;;my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
      outplot, file='Test_C0C1_tau1_tau2_ratio'+runname, png=png

      xmin = min(skdout.taufinal1)-0.05

      if opacity_per_band gt 0 then begin
         
         plot, tau_recalc[*, 2], tau_recalc[*, 3]/tau_recalc[*, 2], ytitle="zenith opacity 2mm-to-1mm ratio", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[xmin, 0.8], yr=[0.2,1.]
         oplot, tau_recalc[*, 2], tau_recalc[*, 3]/tau_recalc[*, 2], psym=4, col=250, symsize=1.1
         oplot, skdout.taufinal1, skdout.taufinal2/skdout.taufinal1, psym=8, col=80, symsize=0.8
         if nskd gt 0 then oplot, scan.tau1mm, scan.tau2mm/scan.tau1mm,psym=5, col=0, symsize=0.5
         legendastro, ["pipe tau2/tau1", 'skydip tau2/tau1'], col=[200, 80], psym = [4, 8], symsize=[1.1,0.8], box=0, /trad, textcol=col, pos=[0.55, 0.95]
      endif else begin
         
         plot, tau_recalc[*, 0], tau_recalc[*, 3]/tau_recalc[*, 2], ytitle="zenith opacity 2mm-to-1mm ratio", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[xmin, 0.8], yr=[0.2,1.]
         oplot, tau_recalc[*, 0], tau_recalc[*, 3]/tau_recalc[*, 0], psym=4, col=200, symsize=1.1
         oplot, tau_recalc[*, 0], tau_recalc[*, 3]/tau_recalc[*, 1], psym=4, col=250, symsize=1.1
         oplot, skdout.taufinal1, skdout.taufinal2/skdout.taufinal1, psym=8, col=80, symsize=0.8
         oplot, skdout.taufinal1, skdout.taufinal2/skdout.taufinal3, psym=8, col=50, symsize=0.8
         if nskd gt 0 then oplot, scan.tau1, scan.tau2mm/scan.tau1,psym=1, col=25, symsize=0.5
         if nskd gt 0 then oplot, scan.tau1, scan.tau2mm/scan.tau3,psym=5, col=0, symsize=0.5
      
         legendastro, ["pipe A2/A1", "pipe A2/A3", 'skydip A2/A1', 'skydip A2/A3'], col=[200, 250, 80, 50], psym = [4, 4, 8, 8], symsize=[1.1, 1.1, 0.8, 0.8], box=0, /trad, textcol=col, pos=[0.55, 0.95]
        
      endelse
      
      outplot, /close
      
   endif

   stop

   
endelse
   

kpref = mrdfits('/home/perotto/NIKA/Processing/Kidpars/kidpar_20171025s41_v2_LP_skd_kids_out.fits',1)
;;kpref = mrdfits(!nika.off_proc_dir+'/'+kidparfile,1)
kpnew = mrdfits(output_dir+'/kidpar_N2R12'+strtrim(file_suffixe)+'_skydip.fits', 1)

kpref = mrdfits(output_dir+'/kidpar_N2R12_opera_skydip.fits', 1)


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
outplot, file=dir+'/Coefficient_checks_n2r12'+file_suffixe, png=png, ps=ps
my_multiplot, 2, 1, pp, pp1, /rev, gap_x=0.1, xmargin=0.1, ymargin=0.09 ; 1e-6
w=where(abs(kpref.c0_skydip) gt 1d-10)
;; plot, kpref[w].c0_skydip,  kpnew[w].c0_skydip/kpref[w].c0_skydip, /nodata, xtitle="C0, ref kidpar", ytitle = "C0, new-to-ref kidpar ratio", pos=pp1[0, *], yr=[0.997, 1.003], /ys
;; oplot, kpref[wa1].c0_skydip,  kpnew[wa1].c0_skydip/kpref[wa1].c0_skydip, psym=8, col=200, symsize=1
;; oplot, kpref[wa2].c0_skydip,  kpnew[wa2].c0_skydip/kpref[wa2].c0_skydip, psym=8, col=80, symsize=0.8
;; oplot, kpref[wa3].c0_skydip,  kpnew[wa3].c0_skydip/kpref[wa3].c0_skydip, psym=8, col=250, symsize=0.8
;; ind=indgen(1000)*min(kpref.c0_skydip)/999.
;; oplot,ind ,ind*0.+1d0, col=0
plot, kpref[w].c0_skydip,  kpnew[w].c0_skydip-kpref[w].c0_skydip, /nodata, xtitle="C0, ref kidpar", ytitle = "C0, new-to-ref kidpar difference", pos=pp1[0, *], yr=[-7d5, 7d5], /ys
oplot, kpref[wa1].c0_skydip,  kpnew[wa1].c0_skydip-kpref[wa1].c0_skydip, psym=8, col=200, symsize=1
oplot, kpref[wa2].c0_skydip,  kpnew[wa2].c0_skydip-kpref[wa2].c0_skydip, psym=8, col=80, symsize=0.8
oplot, kpref[wa3].c0_skydip,  kpnew[wa3].c0_skydip-kpref[wa3].c0_skydip, psym=8, col=250, symsize=0.8
ind=indgen(1000)*min(kpref.c0_skydip)/999.
oplot,ind ,ind*0., col=0
!p.multi = [0, 1, 2]
plot, kpref.c1_skydip,  kpnew.c1_skydip, /nodata, xtitle="C1, ref kidpar", ytitle = "C1, new kidpar", pos=pp1[1, *], /noerase
oplot, kpref[wa1].c1_skydip,  kpnew[wa1].c1_skydip, psym=8, col=200, symsize=1
oplot, kpref[wa2].c1_skydip,  kpnew[wa2].c1_skydip, psym=8, col=80, symsize=0.8
oplot, kpref[wa3].c1_skydip,  kpnew[wa3].c1_skydip, psym=8, col=250, symsize=0.8
ind=indgen(1000)*3.
oplot,ind ,ind, col=0
legendastro, ['A1', 'A3', 'A2'], col=[200, 250, 80], psym=[8, 8, 8], textcolor=[200, 250, 80],box=0


!p.multi=0
outplot, /close


;; restore nika struct
;;!nika.off_proc_dir = offproc_dir



stop

end
