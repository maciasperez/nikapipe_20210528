;;
;; LAUNCHER SCRIPT OF ALL_SKYDIPS FOR N2R15
;; Hacked from reduce_skydips_N2R12
;;_________________________________________________

;; run name
runname = 'N2R15'


;; directory of the output kidpar
;; (and skydip result files if processing is needed)
;; default is !nika.plot_dir
;; output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Opacity'
output_dir = !nika.plot_dir+"/N2R15/Opacity"

;; opacity per band or per array (default setting is per array: opacity_per_band=0)
opacity_per_band = 0

file_suffixe=''       ; to deal with versions of the analysis


;; skydip scans can be input either by defining input_scan_list or by
;; an automatic selection in a 'log file'
;; restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R15_v0.save"
;; db_scan = scan
;; w = where( strupcase( db_scan.obstype) eq "DIY", nw)
;; input_scan_list =
;; strtrim(db_scan[w].day,2)+"s"+strtrim(db_scan[w].scannum,2)
input_scan_list = 0
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; scan selection if input_scan_list = 0
;; edit !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(runname)+file_suffixe+".dat"
;; and add outlier scan names 
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;; reduce all skydip scans
reset = 0 ;; if 1, force the re-analysis of all scans 

;; input reference kidpar file (for skydip reduction and as a basis
;; for the output kidpar)
;; MUST BE COPIED IN !nika.off_proc_dir
kidparfile = "kidpar_20171025s41_v2_LP_skd_kids_out.fits"

;; if redo_plot = 1, no analysis will be run whereas  plots
;; from a previous analysis will be done to help the skydip scan selection 
redo_plot = 0
png=0

;; consistency tests: set to 1 to compare the final tau estimate
;; outputs of the skydip analysis and the tau calculated from the
;; final (C0, C1) 
do_test = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  NO MORE EDITING NEEDED FROM NOW ON
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;; launch
;;---------------------------------------------------------------------------------
if (redo_plot lt 1 and do_test lt 1) then begin
   skdout=1
;; all_skydips_lp, output_dir=output_dir, input_scan_list=input_scan_list, $
;;                 reset=reset, goodscan = goodscan, kidparfile=kidparfile, $
;;                 runname=runname, istart = istart, iend = iend, skdout=skdout
;; all_skydips_lp_np, output_dir=output_dir, input_scan_list=input_scan_list, $
;;                    reset=reset, goodscan = goodscan, kidparfile=kidparfile, $
;;                    runname=runname, istart = istart, iend = iend, skdout=skdout
   all_skydips, output_dir=output_dir, input_scan_list=input_scan_list, $
                reset=reset, goodscan = goodscan, kidparfile=kidparfile, $
                runname=runname, file_suffixe=file_suffixe, $
                istart = istart, iend = iend, skdout=skdout, $
                use_atm=0, opacity_per_band=opacity_per_band
endif else begin 
   
   kidpar = mrdfits(!nika.off_proc_dir+'/'+kidparfile,1)
   
   testkidpar_file = output_dir+'/kidpar_'+strupcase(runname)+strtrim(file_suffixe, 2)+'_skydip.fits'
   print, "test kidpar = ", testkidpar_file
   newkidpar = mrdfits(testkidpar_file, 1)
   
   testsave_file = output_dir+'/all_skydip_fit_'+strupcase(runname)+strtrim(file_suffixe,2)+'.save'
   print, "test save = ",  testsave_file
   restore, testsave_file, /v
   
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
      param.do_opacity_correction=4-2*opacity_per_band
      param.force_kidpar = 1
      param.file_kidpar  =  testkidpar_file
      
      nk_default_info, info
      
      scanname = skdout.scanname
      nsc = n_elements(scanname)
      
      tau_recalc = dblarr(nsc, 4)
      for isc = 0, nsc-1 do begin
         
         ;; reading the data for individual skydips
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

      
      png=0
      wind, 1, 1, /free,xsize=600, ysize=550
      ;;my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
      outplot, file='Test_C0C1_tau1_tau2_ratio'+runname, png=png

      xmin = min(skdout.taufinal1)-0.05

      if opacity_per_band gt 0 then begin
         
         plot, tau_recalc[*, 2], tau_recalc[*, 3]/tau_recalc[*, 2], ytitle="zenith opacity 2mm-to-1mm ratio", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[xmin, 0.8], yr=[0.2,1.]
         oplot, tau_recalc[*, 2], tau_recalc[*, 3]/tau_recalc[*, 2], psym=4, col=250, symsize=1.1
         oplot, skdout.taufinal1, skdout.taufinal2/skdout.taufinal1, psym=8, col=80, symsize=0.8
         
         legendastro, ["pipe tau2/tau1", 'skydip tau2/tau1'], col=[200, 80], psym = [4, 8], symsize=[1.1,0.8], box=0, /trad, textcol=col, pos=[0.55, 0.95]
      endif else begin
         
         plot, tau_recalc[*, 0], tau_recalc[*, 3]/tau_recalc[*, 2], ytitle="zenith opacity 2mm-to-1mm ratio", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[xmin, 0.8], yr=[0.2,1.]
         oplot, tau_recalc[*, 0], tau_recalc[*, 3]/tau_recalc[*, 0], psym=4, col=200, symsize=1.1
         oplot, tau_recalc[*, 0], tau_recalc[*, 3]/tau_recalc[*, 1], psym=4, col=250, symsize=1.1
         oplot, skdout.taufinal1, skdout.taufinal2/skdout.taufinal1, psym=8, col=80, symsize=0.8
         oplot, skdout.taufinal1, skdout.taufinal2/skdout.taufinal3, psym=8, col=50, symsize=0.8
        
         legendastro, ["pipe A2/A1", "pipe A2/A3", 'skydip A2/A1', 'skydip A2/A3'], col=[200, 250, 80, 50], psym = [4, 4, 8, 8], symsize=[1.1, 1.1, 0.8, 0.8], box=0, /trad, textcol=col, pos=[0.55, 0.95]
        
      endelse
      
      outplot, /close
      
   endif

   stop

   
endelse


;;kpnew = mrdfits(output_dir+'/kidpar_N2R15skd.fits', 1)

kpref = mrdfits(!nika.off_proc_dir+'/'+kidparfile,1)
kpnew = mrdfits(output_dir+'/kidpar_'+strupcase(runname)+strtrim(file_suffixe)+'_skydip.fits', 1)


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
outplot, file=dir+'/Coefficient_checks_'+runname+file_suffixe, png=png, ps=ps
my_multiplot, 2, 1, pp, pp1, /rev, gap_x=0.1, xmargin=0.1, ymargin=0.09 ; 1e-6
w=where(abs(kpref.c0_skydip) gt 1d-10)
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


stop


end
