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

;; skydip scans can be input either by defining input_scan_list or by
;; an automatic selection in a 'log file'
input_scan_list = [ '20171019s38', '20171019s45', '20171020s94', '20171020s95', '20171021s168',$
                    '20171021s226', '20171023s99', '20171023s126', '20171024s94', '20171024s196',$
                    '20171025s43', '20171026s183', '20171027s27', '20171027s95', '20171028s185', $
                    '20171028s231', '20171029s73', '20171029s189', '20171029s191', '20171030s158', $
                    '20171030s181']

;; Xavier list :
;;       0 20171019s38
;;       1 20171019s45
;;       2 20171020s94
;;       3 20171020s95
;;       4 20171023s99
;;       5 20171023s126
;;       6 20171024s94
;;       7 20171024s196
;;       8 20171025s43
;;       9 20171026s183
;;      10 20171027s27
;;      11 20171027s95
;;      12 20171028s185
;; --> tous ceux qui passent RTA sauf ceux du 29 

input_scan_list = 0

;; scan selection
;; edit
;; !nika.pipeline_dir+"/Datamanage/blacklist_"+strupcase(runname)+".dat"
;; and add outlier scan names 

;; reduce all skydip scans
reset = 0 ;; if 1, force the re-analysis of all scans 

;; input reference kidpar file (for skydip reduction and as a basis for the output kidpar)
kidparfile = 'kidpar_20171025s41_v2_LP_md_recal_calUranus.fits'

;; reduce only the skydips from istart to iend, othewise do them all

;; opacity per band or per array (default setting is per array: opacity_per_band=0)
opacity_per_band=1




;; launch
;;---------------------------------------------------------------------------------
skdout=1
all_skydips, output_dir=output_dir, input_scan_list=input_scan_list, $
             reset=reset, goodscan = goodscan, kidparfile=kidparfile, $
             runname=runname, istart = istart, iend = iend, skdout=skdout, $
             opacity_per_band=opacity_per_band

kpref = mrdfits(!nika.off_proc_dir+'/'+kidparfile,1)
;;kpnew = mrdfits(output_dir+'/kidpar_N2R12skd.fits', 1)
kpnew = mrdfits(output_dir+'/kidpar_N2R12_skydip.fits', 1)

wind, 1, 1, /free, xsize=800, ysize=600

outplot, file='Opacity_checks_n2r12', png=png, ps=ps
my_multiplot, 2, 1, pp, pp1, /rev, gap_x=0.1, xmargin=0.12, ymargin=0.05 ; 1e-6
plot, kpref.c0_skydip,  kpnew.c0_skydip, /nodata, xtitle="C0, ref kidpar", ytitle = "C0, new kidpar", pos=pp1[0, *]
oplot, kpref.c0_skydip,  kpnew.c0_skydip, psym=8, col=80
!p.multi = [0, 1, 2]
plot, kpref.c1_skydip,  kpnew.c1_skydip, /nodata, xtitle="C1, ref kidpar", ytitle = "C1, new kidpar", pos=pp1[1, *], /noerase
oplot, kpref.c1_skydip,  kpnew.c1_skydip, psym=8, col=80
!p.multi=0
outplot, /close
 
stop

end
