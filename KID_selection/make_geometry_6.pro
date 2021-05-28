;; From NP/Nika2Run1/np_make_geometry.pro
;; Jan 13th, 2015
;; From IDLtools/make_geometry_4.pro, July 27th, 2016
;;
;; This code runs each step of the kidpar definition, but the
;; attribution of the skydip coefficients, c0 and c1.
;;
;;-----------------------------------
;;1. make_geometry_5, ..., /prepare
;;Will read raw data, median filter the tois
;;
;;2. make_geometry_5, ..., /project
;;Produces a map per kid.
;;
;;3. make_geometry_5, .., /beams
;;Will fit the beam parameters (fwhm, position, flux) for each kid. These parameters
;;are saved in a bunch of kidpar files that contain a subset of detetors (coming from the parallelization of this process)
;;
;;4. make_geometry_5, ..., /merge
;;Will merge the sub-kidpars produced during the previous step into a single kidpar
;;
;;5. make_geometry_5, ..., /select
;;Will launch a light version of katana to help the user remove "doubles" or anomalous kids interactively
;;
;;6. make_geometry_5, ..., /finalize
;;will take the last kid selection performed at the previous step to improve the determination of the
;;(azel to nasmyth) center of rotation, and writes the kidpar_XXX_V0.fits.
;;
;;7. At this stage, you should be able to add the skydip coeffs to this kidpar
;;
;;8. make_geometry_5, ..., /process, input_kidpar_file="kidpar_XXX_V0.fits", iteration=2
;;Will take the kidpar previously derived to compute the position of the planet and performe a common_mode_kids_out decorrelation to improve the absolute calibration per kid.
;;
;;9. make_geometry_5, ..., /beams, input_kidpar_file="kidpar_XXX_V0.fits", iteration=2
;;Improves the kid offsets and flux and calibration.
;;
;;10. make_geometry_5, ..., /merge input_kidpar_file="kidpar_XXX_V0.fits", iteration=2
;;
;;11. make_geometry_5, ..., /select, input_kidpar_file="kidpar_XXX_V0.fits", iteration=2
;;There should be very few kids to discard at this stage, but sometimes the decorrelation is a bit more robust than the median filter
;;or highlights some defects (or anomalous kids that werer un-noticed at the first selection)
;;
;;12. make_geometry_5, ..., /finalize, input_kidpar_file="kidpar_XXX_V0.fits", iteration=2
;;The kidpar is ready to use. To improve the absolute calibration, use this kidpar for multiple
;;observations of the calibration source, like in e.g. calibration_run_XXX.pro
;;-----------------------------------------------

pro make_geometry_6, scan_list, input_flux_th, nproc=nproc, black_list=black_list, $
                     prepare=prepare, project=project, beams=beams, merge=merge, select=select, $
                     preproc=preproc, decor_method=decor_method, $
                     finalize=finalize, nickname=nickname, $
                     simu=simu, input_simu_map=input_simu_map, point_source=point_source, $
                     nostop=nostop, reso=reso, $
                     iteration=iteration, $
                     ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject, source=source, $
                     input_kidpar_file=input_kidpar_file, png=png, ps=ps, beam_maps_dir=beam_maps_dir, $
                     sn_min_list=sn_min_list, sn_max_list=sn_max_list, zigzag=zigzag, $
                     parallel=parallel, plateau=plateau, gamma=gamma, asymfast=asymfast, ata_fit_beam_rmax=ata_fit_beam_rmax, $
                     no_ref_center=no_ref_center, sub_kidpar_file=sub_kidpar_file, aperture_phot=aperture_phot, do_plot=do_plot

if not keyword_set(gamma) then gamma = 1d-10
if not keyword_set(reso) then reso     = 4.d0 ; 8.d0
keep_neg = 0

if not keyword_set(source)    then source = 'Uranus'
if not keyword_set(iteration) then iteration  = 1
if not keyword_set(nproc) then nproc = 16
if not keyword_set(dist_reject) then dist_reject=20

;; Concatenate "scan_list" into "nickname" to name the final kidpar
scanlist2nickname, scan_list, nickname

;; To prevent overwriting the actual kidpar of this scan :)
if keyword_set(simu) then nickname += +"_simu"

; if not keyword_set(beam_maps_dir) then beam_maps_dir = !nika.plot_dir+'/Beam_maps_reso_'+strtrim(reso, 2)
if not keyword_set(beam_maps_dir) then $
   beam_maps_dir = '$NIKA_PLOT_DIR/Run'+!nika.run+'/Geometries/Beam_maps_reso_'+strtrim(reso, 2)
spawn, "mkdir "+beam_maps_dir

if iteration eq 1 then begin
   maps_dir           = beam_maps_dir+"/Maps/"
   beams_output_dir   = beam_maps_dir+"/Beams/"
   kidpars_output_dir = beam_maps_dir+"/Kidpars/"
   toi_dir            = beam_maps_dir+"/TOIs/"
   if keyword_set(input_kidpar_file) then kidpar_file = input_kidpar_file
   version = 0
endif else begin
   version = 2
   if not keyword_set(input_kidpar_file) then begin
      message, /info, "You must provide input_kidpar_file for the second iteration"
      return
   endif
   
   kids_out = 1
   maps_dir           = beam_maps_dir+"/Maps_kids_out/"
   beams_output_dir   = beam_maps_dir+"/Beams_kids_out/"
   kidpars_output_dir = beam_maps_dir+"/Kidpars_kids_out/"
   toi_dir            = beam_maps_dir+"/TOIs_kids_out/"
endelse
plot_dir = beam_maps_dir+"/Plots"

if keyword_set(zigzag) then begin
   maps_dir           += "_zigzag"
   beams_output_dir   += "_zigzag"
   kidpars_output_dir += "_zigzag"
endif

spawn, "mkdir -p "+maps_dir
spawn, "mkdir -p "+beams_output_dir
spawn, "mkdir -p "+kidpars_output_dir
spawn, "mkdir -p "+toi_dir
spawn, "mkdir -p "+plot_dir

;;-------------------------------------------------------------------------------------
;;------------------------------------ Main loop --------------------------------------
;;-------------------------------------------------------------------------------------

if n_elements(scan_list) gt 1 then multiscans = 1 else multiscans = 0

if keyword_set(prepare) then begin
   if keyword_set(simu) then begin
      ;; Simulate timelines
      geom_simu, scan_list, toi_dir, maps_dir, nickname, nproc=nproc, $
                 input_kidpar_file = input_kidpar_file, reso=reso, kids_out=kids_out, $
                 plot_dir=plot_dir, point_source=point_source, input_simu_map=input_simu_map, $
                 multiscans=multiscans
   endif else begin
      ;; Clean TOIs, can be done to the 1st beammap while the other ones are being observed
      if keyword_set(parallel) then begin
         auto_prepare_toi_parall, scan_list, toi_dir, maps_dir, nickname, nproc=nproc, $
                                  input_kidpar_file = input_kidpar_file, reso=reso, $
                                  preproc=preproc, kids_out=kids_out, $
                                  sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
                                  zigzag=zigzag, gamma=gamma, plot_dir=plot_dir, $
                                  multiscans=multiscans, decor_method=decor_method
      endif else begin
         for iscan=0, n_elements(scan_list)-1 do begin
            auto_prepare_toi_sub, iscan, scan_list, toi_dir, maps_dir, nickname, nproc=nproc, $
                                  noplot=noplot, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
                                  zigzag=zigzag, kids_out=kids_out, reso=reso, $
                                  input_kidpar_file=input_kidpar_file, gamma=gamma, plot_dir=plot_dir, $
                                  multiscans=multiscans, decor_method=decor_method
         endfor
      endelse
      ;; return
   endelse
endif


;; Combine scans to produce maps per kid
if keyword_set(prepare) and multiscans eq 1 then begin
   auto_toi2kidmaps_parall, scan_list, toi_dir, maps_dir, nickname, nproc=nproc, $
                            input_kidpar_file = input_kidpar_file, reso=reso, $
                            preproc=preproc, kids_out=kids_out, $
                            sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
                            zigzag=zigzag, gamma=gamma
   ;; return
endif

;; Fit beam parameters on kid maps
if keyword_set(beams) then begin
   auto_fit_beam_parameters, nproc, maps_dir, beams_output_dir, kidpars_output_dir, nickname, input_flux_th, $
                             noplot = noplot,  source=source, $
                             reso = reso, plateau=plateau, gamma=gamma, asymfast=asymfast, $
                             ata_fit_beam_rmax=ata_fit_beam_rmax, aperture_phot=aperture_phot
   ;; return
endif

;; Merge the sub kidpars
if keyword_set(merge) then begin
   auto_merge_sub_kidpars, kidpars_output_dir, nproc, nickname, nostop=nostop, version=version, $
                           ptg_numdet_ref=ptg_numdet_ref, dist_reject=dist_reject, png=png, ps=ps, plot_dir=plot_dir, $
                           black_list=black_list, no_ref_center=no_ref_center
   ;; return
endif

spawn,"python convnet_kid_selection.py --load-model 1 --weights output/lenet_weights_iter1.hdf5 --beam_dir "+beams_output_dir+" --beammap "+nickname+" --ncpu "+strtrim(nproc,2)+" --iter 2 --kidpar_dir "+kidpars_output_dir+" --plot "+strtrim(do_plot,2)

auto_merge_subkidpar, kidpars_output_dir, nickname, nproc

end
