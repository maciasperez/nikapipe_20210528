

beam_maps_dir = "$NIKA_PLOT_DIR/Beammaps"
ptg_numdet_ref = 823

kidpar_skydip_file = !nika.off_proc_dir+"/kidpar_skydip_n2r9_skd1.fits"

source = 'Uranus'
scan = '20170223s46'

souce = '3C84'
scan_list = '20170226s415'

;--------------------------------

; LP notes : let's edit ktn_matrix_events.pro in katana and
; comment line about 50 to discard the circles

nk_scan2run, scan_list[0]
if strupcase(source) eq "URANUS" then input_flux_th = !nika.flux_uranus else input_flux_th = [1.d0,1.d0,1.d0]

simu = 0

scanlist2nickname, scan_list, nickname

prepare   = 1
beams     = 1
merge     = 1
select    = 1
finalize  = 1
iteration = 1
make_geometry_5, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
                 simu=simu, point_source=point_source, input_simu_map=input_simu_map, $
                 source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
                 prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize, $
                 nickname=nickname
stop

;; Apply skydip coeffs
kidpar_in_file     = "kidpar_"+nickname+"_v0.fits"
kidpar_out_file    = "kidpar_"+nickname+"_v0_skydip.fits"
skydip_coeffs, kidpar_in_file, kidpar_skydip_file, kidpar_out_file

stop

iteration = 2
input_kidpar_file = kidpar_out_file
aperture_phot = 0
make_geometry_5, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
                 simu=simu, point_source=point_source, input_simu_map=input_simu_map, $
                 source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
                 prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize


end
