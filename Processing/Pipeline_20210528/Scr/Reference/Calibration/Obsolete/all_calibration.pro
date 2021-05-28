
;; Choose which run
run = 'N2R9'

;; Determine which scan data base to use
case strupcase(run) of
   "N2R9" : begin
      db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v1.save"
      source = 'Uranus'
   end
   "N2R10": begin
      db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v2.save"
      source = 'Uranus'
   end
   "N2R11": begin
      db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R11_v0.save"
      source = 'Uranus'
   end
   "N2R12": begin
      db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v3.save"
      source = 'Uranus'
   end
   "N2R13": begin
      db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R13_v0.save"
      source = 'Uranus'
   end
   "N2R14": begin
      db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R14_v3.save"
      source = 'Uranus'
   end
   "N2R15": begin
      db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R15_v0.save"
      source = 'Uranus'
   end
   else: begin
      message, /info, "Either add "+strupcase(run)+" to the list of possible cases"
      message, /info, "or edit and run log_iram_tel"+strlowcase(run)+".pro"
      goto, exit
   end
endcase

output_dir = !nika.plot_dir+"/Calibration_"+run

;;-----------------------------------------------------------------------
;; No need to edit the script beyond this line to run it in default mode
;;-----------------------------------------------------------------------
spawn, "mkdir -p "+output_dir

;; 1. Determine C0 and C1 coeffs for each kid based on the skydips of
;; this run. By default, all the skydips are used. If you wish to
;; refine the selection, pass skydip_scan_list in input of
;; reduce_all_skydips
;;
;; 2. By default, the reference kidpar is found in this routine via
;; nk_get_kidpar_ref. If you wish to change it, pass it as a keyword
;; to reduce_all_skydips

reduce_all_skydips, run, db_file, $
                    skydip_scan_list=skydip_scan_list, $
                    kidpar_file=kidpar_file, reset=reset, $
                    kidpar_out_file=kidpar_skd_file, $
                    output_dir=output_dir
print, "OK !"
stop
;; kidpar_skd_file = "/home/ponthieu/Projects/NIKA/Plots/Run19/Calibration_N2R9/kidpar_N2R9_skydip.fits"


;; 2. Determine absolute calibration on the reference calibrator
;; you can edit scan_list and pass it to the routine
compute = 1
perform_abs_cal, run, db_file, kidpar_skd_file, scan_list=scan_list, $
                 source=source, version=version, reset=reset, $
                 output_kidpar_file=kidpar_file, $
                 output_dir=output_dir, compute=compute















exit:
end
