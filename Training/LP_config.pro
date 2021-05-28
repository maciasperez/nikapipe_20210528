

!nika.run          = 6
!nika.raw_acq_dir  = '/Users/perotto/MesTrucs/NIKA/Test/Test_data'           ; point to Test_data ; export NIKA_RAW_ACQ_DIR=/Data/NIKA/Iram_nov2012/Raw/Files
!nika.imb_fits_dir = '/Users/perotto/MesTrucs/NIKA/Test/Test_imbfits'           ; point to Test_imbfits
!nika.plot_dir     =  '/Users/perotto/MesTrucs/NIKA/Training/mai22'          ; anywhere you want to save plots

compile_read_nika

;; focus va planter parce qu'il lui manque le kidpar
;; focus, 220, '20121122', 8, 414, /tau_force, /log, /png

end
