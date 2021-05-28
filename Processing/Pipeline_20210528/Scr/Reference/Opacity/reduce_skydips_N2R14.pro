;;
;;   LAUNCHER SCRIPT OF ALL_SKYDIPS FOR N2R12
;;
;;_________________________________________________


;; run name
runname = 'N2R14'

;; directory of the output kidpar
;; (and skydip result files if processing is needed)
;; default is !nika.plot_dir
output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Opacity'

;; opacity per band or per array (default setting is per array: opacity_per_band=0)
opacity_per_band=0


; to deal with versions of the analysis
file_suffixe = '_16skd'
file_suffixe = '_14skd'
file_suffixe = '_avril' ;; all skydips
file_suffixe = '_avril_15skd' ;; 1 outlier
file_suffixe = '_avril_13skd' ;; 3 outliers
file_suffixe = '_avril_13skd_hybrid' ;; 3 outliers

;; skydip scans can be input either by defining input_scan_list or by
;; an automatic selection in a 'log file'
input_scan_list = ['20180116s69', '20180117s20', '20180117s195', '20180118s31',$
                    '20180118s197', '20180119s8' ]

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
;; must be in !nika.off_proc_dir

kidparfile0 = !nika.off_proc_dir+'/kidpar_20180117s92_v2_LP.fits'

;;kidparfile = 'kidpar_20180117s92_v2_LP_oldskd.fits'
;;kidpar_skydip_file = !nika.off_proc_dir+"/kidpar_20171022s158_v0_LP_skd_calUranusv2.fits"
;;skydip_coeffs, kidparfile0, kidpar_skydip_file, kidparfile
;;offproc_dir = !nika.off_proc_dir
;;!nika.off_proc_dir = output_dir

kidparfile = !nika.off_proc_dir+'/kidpar_20180117s92_v2_LP_skd13_calUranus12.fits' 
kidparfile = !nika.off_proc_dir+'/kidpar_20180117s92_v2_LP_skd16_calUranus16.fits'
kidparfile = !nika.off_proc_dir+'/kidpar_20180122s309_v2_HA_skd16_calUranus17.fits' 


;; Hybrid method: tau for A2 deduced from tau A1, A3 and an ATM model
hybrid = !nika.pipeline_dir+'/Datamanage/tau_arrays_April_2018.dat'


;; redo plots
redo_plot = 1
png=1

;; reduce only the skydips from istart to iend, othewise do them all


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  NO MORE EDITING NEEDED FROM NOW ON
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; launch
;;---------------------------------------------------------------------------------
if redo_plot lt 1 then begin
   skdout=1
   goodscan=0
   all_skydips, output_dir=output_dir, input_scan_list=input_scan_list, $
                reset=reset, goodscan = goodscan, kidparfile=kidparfile, $
                file_suffixe=file_suffixe, $
                runname=runname, istart = istart, iend = iend, skdout=skdout, $
                opacity_per_band=opacity_per_band, hybrid=hybrid
endif else begin
   
   kidpar = mrdfits(kidparfile,1)
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
   
endelse
   
   
kpref = mrdfits(kidparfile,1)
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
plot, kpref[w].c0_skydip,  kpnew[w].c0_skydip-kpref[w].c0_skydip, /nodata, xtitle="C0, ref kidpar", ytitle = "C0, new-to-ref kidpar difference", pos=pp1[0, *], yr=[-3d5, 3d5], /ys
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

print, "A1 median C0 diff = ", median( kpnew[wa1].c0_skydip-kpref[wa1].c0_skydip)*1d-4
print, "A3 median C0 diff = ", median( kpnew[wa3].c0_skydip-kpref[wa3].c0_skydip)*1d-4
print, "A2 median C0 diff = ", median( kpnew[wa2].c0_skydip-kpref[wa2].c0_skydip)*1d-4

!p.multi=0
outplot, /close


;; comparison with N2R12
kpref = mrdfits('/home/perotto/NIKA/Processing/Kidpars/kidpar_20171025s41_v2_LP_skd_kids_out.fits',1)
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
outplot, file=dir+'/Opacity_checks_n2r12_vs_n2r14_14skd', png=png, ps=ps
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
