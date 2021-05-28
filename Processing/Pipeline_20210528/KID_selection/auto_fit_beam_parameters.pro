
;; ****** DO NOT RUN THIS UNDER VNC, FOR AN UNKNOWN REASON, SPLIT_FOR
;; KILLS THE VNC SERVER ****************
pro auto_fit_beam_parameters, nproc, maps_dir, maps_output_dir, kidpars_output_dir, nickname, input_flux_th, $
                              noplot=noplot, plateau=plateau, gamma=gamma, $
                              kids_out=kids_out, reso=reso, source=source, $
                              ata_fit_beam_rmax=ata_fit_beam_rmax, asymfast=asymfast, $
                              aperture_phot=aperture_phot ;, input_kidpar_file = input_kidpar_file

  
if not keyword_set(kids_out) then kids_out = 0
if not keyword_set(reso) then reso = 4.d0
if not keyword_set(source) then source = 'Uranus'
if not keyword_set(plateau) then plateau=0
if not keyword_set(gamma) then gamma=!dpi/4.d0
if not keyword_set(asymfast) then asymfast=0
if not keyword_set(ata_fit_beam_rmax) then ata_fit_beam_rmax=0
if not keyword_set(aperture_phot) then aperture_phot = 0

spawn, "mkdir -p "+maps_output_dir
spawn, "mkdir -p "+kidpars_output_dir

varnames = ['file_list', 'maps_dir', 'maps_output_dir', $
            "kidpars_output_dir", "kids_out",  "reso", "nickname", "input_flux_th", $
            "source", "plateau", "asymfast", "ata_fit_beam_rmax", 'aperture_phot']


root_name = "kid_maps_"+nickname
file_list = root_name+"_"+strtrim(indgen(nproc),2)+".save"
   
;; need to refresh nsplit
nsplit = nproc

;;;;----------------------
;;
;;   message, /info, "fix me: comment back to launch split for"
;; i=0
;; geom_fit_beam_parameters_sub, i, file_list, maps_dir, $
;;                               maps_output_dir, kidpars_output_dir, kids_out, $
;;                               nickname, input_flux_th, reso=reso, $
;;                               source=source, plateau=plateau, $
;;                               gamma=gamma, asymfast=asymfast, ata_fit_beam_rmax=ata_fit_beam_rmax, $
;;                               aperture_phot=aperture_phot
;; stop
;; 
;; ;;;;----------------------

split_for, 0, nproc-1, $
           commands=['auto_fit_beam_parameters_sub, i, file_list, maps_dir, '+$
                     'maps_output_dir, kidpars_output_dir, kids_out, '+$
                     'nickname, input_flux_th, reso=reso, source=source, plateau=plateau, gamma=gamma, '+$
                     'asymfast=asymfast, ata_fit_beam_rmax=ata_fit_beam_rmax, aperture_phot=aperture_phot'], $
           varnames = varnames, nsplit=nsplit
;endfor

end
