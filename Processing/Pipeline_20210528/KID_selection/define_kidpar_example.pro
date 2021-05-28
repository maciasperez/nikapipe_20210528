;;=====================================================================
;;
;;    Beam map scan analysis and Kidpar file production
;;
;;=====================================================================

scan_list      = '20171022s158'
ptg_numdet_ref =  823

source         =  'Uranus'
nk_scan2run, scan_list[0]
input_flux_th  = !nika.flux_uranus

;; define a directory for the analysis outputs
beam_maps_dir = "/mnt/data/NIKA2Team/ruppin/Plots/Run25/beammaps_auto"

prepare   = 1
beams     = 1
merge     = 1
select    = 1
finalize  = 1
iteration = 1
;; set do_plot to 1 if you want to make a .pdf file with all the discarded KID maps
;; !! WARNING: If the wheather conditions were very bad, a lot of KIDs
;; will be discarded and the .pdf file will be large and take some
;; time to be written...
do_plot = 0
reso      = 4.   ;;If you change the resolution you will need to train the CNN again...

make_geometry_6, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
                 reso=reso, $
                 source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
                 prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize, do_plot=do_plot


end
