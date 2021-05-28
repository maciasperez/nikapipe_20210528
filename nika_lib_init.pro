
pro nika_lib_init, nojpb=nojpb, alain=alain,  minimal = minimal, no_set_plot_x=no_set_plot_x, nika_run = nika_run

defsysv, "!psep",  ':'
defsysv, "!sep",  '/'

nika_init_structure
nika_init_path,  minimal = minimal, no_set_plot_x=no_set_plot_x

set_plot_z = getenv('SET_PLOT_Z')
if set_plot_z ne 0 then !outplot.old_device = 'Z'

;; Define other convenient system variables to interact with other libraries
nika_pr = { xrange:[0.d0, 0.d0], yrange:[0.d0, 0.d0]}
defsysv, "!nika_pr", nika_pr
defsysv, "!screen_size", get_screen_size()

;; By default, init !nika.run to the latest value
;; No !!! Bullshit !
julday = systime( 0, /julian)
caldat, julday, month, day, year
myscan = string(year,format="(I4.4)")+string(month,format="(I2.2)")+string(day,"(I2.2)")+"s1"
nk_scan2run, myscan, nika_run = nika_run
;;nika_run = 47

;; To debug
junk = create_struct("lvl", 0, "cm_dmin", 0.d0)
defsysv, '!db', junk

defsysv, '!arcsec2deg', 1.d0/3600.d0



end
