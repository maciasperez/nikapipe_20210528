
;; ****** DO NOT RUN THIS UNDER VNC, FOR AN UNKNOWN REASON, SPLIT_FOR
;; KILLS THE VNC SERVER ****************
pro compute_kid_maps, scan, nproc=nproc, noplot=noplot, input_kidpar_file =  input_kidpar_file,  kids_out =  kids_out, $
                      beam_maps_dir = beam_maps_dir, reso = reso

if not keyword_set(nproc) then nproc = 8  
if not keyword_set(kids_out) then kids_out = 0

if not keyword_set(beam_maps_dir) then beam_maps_dir = !nika.plot_dir+'/Beam_maps'

toi_dir            = beam_maps_dir+'/Beam_maps/TOIs'
maps_output_dir    = beam_maps_dir+'/Beam_maps/Maps'
kidpars_output_dir = beam_maps_dir+'/Beam_maps/Kidpars'

if kids_out eq 1 then begin
   toi_dir            += "_kids_out"
   maps_output_dir    += "_kids_out"
   kidpars_output_dir += "_kids_out"
endif
spawn, "mkdir -p "+toi_dir
spawn, "mkdir -p "+maps_output_dir
spawn, "mkdir -p "+kidpars_output_dir


root_name = "otf_geometry_toi_"+scan
file_list = root_name+"_"+string(indgen(nproc),format='(I3.3)')+".save"

nk_scan2run, scan, run ; to update !nika.raw_acq_dir
;; otf_geometry_bcast_data, scan, file_list, toi_dir, $
;;                             kid_step=kid_step, $
;;                             discard_outlyers=discard_outlyers, $
;;                             force_file=force_file, nproc=nproc, noplot=noplot, $
;;                             input_kidpar_file=input_kidpar_file, kids_out=kids_out

if not keyword_set(reso) then reso = 4.d0



varnames = ['file_list', 'toi_dir', 'maps_output_dir', "kidpars_output_dir", "kids_out",  "reso"]
nsplit = nproc
split_for, 0, nproc-1, $
           commands=['nk_otf_geometry_sub, i, file_list, toi_dir, '+$
                     'maps_output_dir, kidpars_output_dir, kids_out, reso=reso'], $
           varnames = varnames, nsplit=nsplit

end
