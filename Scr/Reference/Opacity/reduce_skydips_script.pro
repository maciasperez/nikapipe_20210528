;;
;;   LAUNCHER SCRIPT OF REDUCE_SKYDIPS_REFERENCE
;;
;;   LP, April 2018
;;_________________________________________________


;; N2R9
;;_________________________________________________

runname = 'N2R9'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'

do_first_iteration  = 0
;; NB: equivalent to '_1803'

do_skydip_selection = 0
do_second_iteration = 0

show_plot = 0 
check_after_selection =1

atmlike  = 1
hightau2 = 0

png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection

stop


;; N2R12
;;_________________________________________________



;; N2R14
;;_________________________________________________



end
