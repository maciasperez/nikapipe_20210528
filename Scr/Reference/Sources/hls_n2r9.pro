
;; This script combines several scans into a final map and derives the
;; NEFD with two methods:
;; 1. Fitting the noise on the center flux as a function of the
;; cumulated observation time
;; 2. Measuring the NEFD on jackknife maps
;;-------------------------------------------------------------------

pro hls_n2r9, reset=reset, png=png

reset = 0
method_num = 2
compute = 0 ; 1
process = 1
average = 1

;;*************
;; Careful for these parameters that are only temporary !
math = "RF"
do_opacity_correction = 1
;;*************

source = 'HLS091828'
restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v0.save"
db_scan = scan
w = where( strupcase(db_scan.object) eq strupcase(source) and $
           db_scan.obstype eq "onTheFlyMap", nw)
scan_list = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)

parallel = 1

;; Param
nk_default_param, param
param.math                 = math
param.alain_rf             = 1
param.do_opacity_correction = do_opacity_correction

param.silent               = 0
param.map_reso             = 2.d0
param.ata_fit_beam_rmax    = 60.d0
param.polynomial           = 0
param.map_xsize            = 15.*60.d0
param.map_ysize            = 15.*60.d0
param.interpol_common_mode = 1
param.do_plot              = 1
param.plot_png             = 0
param.plot_ps              = 1
param.new_deglitch         = 0
param.flag_sat             = 0
param.flag_oor             = 0
param.flag_ovlap           = 0
param.line_filter          = 0
param.fourier_opt_sample   = 1
param.do_meas_atmo         = 0
param.w8_per_subscan       = 1
param.decor_elevation      = 1
param.version              = 1
param.do_aperture_photometry = 0

param.preproc_copy = 0
param.preproc_dir = !nika.plot_dir+"/Preproc"
param.source    = source
param.name4file = source

if method_num eq 1 then begin
   param.flag_sat             = 1
   param.flag_oor             = 1
   param.flag_ovlap           = 1
   param.bandpass = 1
   param.freqhigh = 7.
   param.decor_method = "COMMON_MODE_ONE_BLOCK"
endif

if method_num eq 2 then begin
   param.flag_sat             = 1
   param.flag_oor             = 1
   param.flag_ovlap           = 1
   param.bandpass = 1
   param.freqhigh = 7.
   param.decor_method = "COMMON_MODE_ONE_BLOCK"
endif

if method_num eq 3 then begin
   param.flag_sat             = 1
   param.flag_oor             = 1
   param.flag_ovlap           = 1
   param.bandpass = 1
   param.freqhigh = 7.
   param.decor_method = "COMMON_MODE_ONE_BLOCK"
   param.lf_sin_fit_n_harmonics = 5
endif

method = param.decor_method

project_dir = !nika.plot_dir+"/Sources/"+source+"_"+method+"_"+strtrim(method_num,2)
param.project_dir = project_dir
in_param_file = source+'_param.save'
save, param, file=in_param_file

if compute eq 1 then begin
   point_source_batch, scan_list, project_dir, source, $
                       reset=reset, process=process, average=average, $
                       parallel=parallel, simu=simu, test=test, decor2=decor2, $
                       method=method, quick_noise_sim=quick_noise_sim, input_kidpar_file=input_kidpar_file, $
                       mask=do_mask, in_param_file=in_param_file
endif

nk_fits2grid, project_dir+"/MAPS_"+param.name4file+"_v1.fits", output_maps
nk_grid2info, output_maps, info, /edu

print, info.result_nefd_center_i_1mm
print, info.result_nefd_center_i_2mm

!mamdlib.coltable = 4

;; Quicklook
imrange_i1 = [-1,1]*0.1
imrange_i2 = [-1,1]*0.005
nk_display_grid, output_maps, title=file_basename(project_dir), $
                 imrange_i1 = imrange_i1, imrange_i2 = imrange_i2

;; Derive flux maps
nk_map_photometry, output_maps.map_i_1mm, output_maps.map_var_i_1mm, $
                   output_maps.nhits_1mm, output_maps.xmap, output_maps.ymap, $
                   !nika.fwhm_nom[0], flux, sigma_flux, /edu, $
                   /noplot, map_flux=map_flux_1mm, map_var_flux=map_var_flux_1mm

nk_map_photometry, output_maps.map_i1, output_maps.map_var_i1, $
                   output_maps.nhits_1, output_maps.xmap, output_maps.ymap, $
                   !nika.fwhm_nom[0], flux, sigma_flux, /edu, $
                   /noplot, map_flux=map_flux1, map_var_flux=map_var_flux1

nk_map_photometry, output_maps.map_i3, output_maps.map_var_i3, $
                   output_maps.nhits_3, output_maps.xmap, output_maps.ymap, $
                   !nika.fwhm_nom[0], flux, sigma_flux, /edu, $
                   /noplot, map_flux=map_flux3, map_var_flux=map_var_flux3

nk_map_photometry, output_maps.map_i2, output_maps.map_var_i2, $
                   output_maps.nhits_2, output_maps.xmap, output_maps.ymap, $
                   !nika.fwhm_nom[1], flux, sigma_flux, /edu, $
                   /noplot, map_flux=map_flux2, map_var_flux=map_var_flux2

;; Retrieve total observation time
nk_read_csv, project_dir+"/photometry_"+strupcase(strtrim(param.name4file,2))+"_v1.csv", str
total_obs_time = str[-1].total_obs_time

w = where( map_var_flux_1mm ne 0, nw)
map_sn_1mm = map_flux_1mm*0.d0
map_sn_1mm[w] = map_flux_1mm[w]/sqrt(map_var_flux_1mm[w])

w = where( map_var_flux1 ne 0, nw)
map_sn1 = map_flux1*0.d0
map_sn1[w] = map_flux1[w]/sqrt(map_var_flux1[w])

w = where( map_var_flux3 ne 0, nw)
map_sn3 = map_flux3*0.d0
map_sn3[w] = map_flux3[w]/sqrt(map_var_flux3[w])

w = where( map_var_flux2 ne 0, nw)
map_sn2 = map_flux2*0.d0
map_sn2[w] = map_flux2[w]/sqrt(map_var_flux2[w])

;; ;; A773 cluster
;; ;R.A. = 09 h 17 m 52.87 s
;; ;Dec. = +51 deg 43' 39.2" (J2000.0)
;; ;; HLS091828            EQ 2000 09:18:28.600  +51:42:23.300   LSR 0.000 FL 0.000
;; 
;; x_a773 = (17./60. + 52.87/3600.d0)*15.d0*3600.d0
;; y_a773 = 43.*60. + 39.2
;; x_hls = (18./60 + 28.6/3600.d0)*15.d0*3600.d0
;; y_hls = 42.*60 + 23.3
;; 
;; dec = (51.+43./60+39.2/3600)*!dtor
;; x = -(x_a773-x_hls)*cos(dec)
;; y = y_a773-y_hls

;;------------------------------------
;; Hack at $DEV/Deepfield/df_sources.pro and $DEV/../Deepfield/gn1200.pro
;; Define source parameters
point_source =  {name:'12646', ra:189.11474611, dec:62.2050095, z:0.d0, $
           flux_1mm:0.d0, sigma_flux_1mm:0.d0, sigma_flux_pos_1mm:0.d0, $
           flux_2mm:0.d0, sigma_flux_2mm:0.d0, sigma_flux_pos_2mm:0.d0}

;readcol, !nika.soft_dir+"/Labtools/NP/DeepField/gn_source_list.dat", source_list, ra_list, dec_list, flux1mm, flux2mm, $
;         delimiter=',', comment="#", format="A,A,A"
source_list = [source,'Abell773']
ra_list  = ['09:18:28.6', '09:17:52.87']
dec_list = ['51:42:23.3', '51:43:39.2']
nsources = n_elements(source_list)
point_source = replicate( point_source, nsources)
for isource = 0, nsources-1 do begin
   point_source[isource].name = source_list[isource]

   r = double(strtrim(strsplit( ra_list[isource], ":", /extract),2))
   point_source[isource].ra   = (r[0] + r[1]/60.d0 + r[2]/3600.d0)*15.d0

   d = double(strtrim(strsplit( dec_list[isource], ":", /extract),2))
   point_source[isource].dec = d[0] + d[1]/60.d0 + d[2]/3600.d0
endfor
wsource = where( source_list eq source)
r = double(strtrim(strsplit( ra_list[wsource], ":", /extract),2))
ra_center  = (r[0] + r[1]/60.d0 + r[2]/3600.d0)*15.d0
d = double(strtrim(strsplit( dec_list[wsource], ":", /extract),2))
dec_center = d[0] + d[1]/60.d0 + d[2]/3600.d0
source_legend_text = ['']
fmt = "(F5.2)"
for i = 0, nsources-1 do source_legend_text = [source_legend_text, $
                                               point_source[i].name+": "+string(point_source[i].flux_1mm, form = fmt)+" +- "+$
                                               string(point_source[i].sigma_flux_1mm,  form =  fmt)]
;;------------------------------------

wind, 1, 1, /free, /large
outplot, file=project_dir+"/maps_"+param.name4file, png=png, ps=ps
my_multiplot, 4, 2, pp, pp1, /rev
;; start with the combined map to init imrange_1mm
imrange_1mm = [-1,1]*0.01/2.
imrange_2mm = [-1,1]*0.01/2.
nsigma = 5 ; 3
imview, map_flux_1mm, xmap =output_maps.xmap, ymap = output_maps.ymap, imrange=imrange_1mm, $
        title='Flux 1mm', position=pp1[2,*]
legendastro, "Total obs. time: "+string(total_obs_time/60., format="(F5.1)")+" mn", box=0, /bottom
oplot, (point_source.ra-ra_center)*3600.d0*cos(dec_center), $
       (point_source.dec-dec_center)*3600.d0, psym=6, syms=1, col=100

imview, map_flux1, xmap =output_maps.xmap, ymap = output_maps.ymap, imrange=imrange_1mm, $
        title='Flux A1', position=pp1[0,*], /noerase
oplot, (point_source.ra-ra_center)*3600.d0*cos(dec_center), $
       (point_source.dec-dec_center)*3600.d0, psym=6, syms=1, col=100

imview, map_flux3, xmap =output_maps.xmap, ymap = output_maps.ymap, imrange=imrange_1mm, $
        title='Flux A3', position=pp1[1,*], /noerase
oplot, (point_source.ra-ra_center)*3600.d0*cos(dec_center), $
       (point_source.dec-dec_center)*3600.d0, psym=6, syms=1, col=100

imview, map_flux2, xmap =output_maps.xmap, ymap = output_maps.ymap, imrange=imrange_2mm, $
        title='Flux A2', position=pp1[3,*], /noerase
oplot, (point_source.ra-ra_center)*3600.d0*cos(dec_center), $
       (point_source.dec-dec_center)*3600.d0, psym=6, syms=1, col=100

imview, map_sn1, xmap = output_maps.xmap, ymap = output_maps.ymap, imr = [0, nsigma], title="S/N Flux A1", $
        position=pp1[4,*], /noerase
oplot, (point_source.ra-ra_center)*3600.d0*cos(dec_center), $
       (point_source.dec-dec_center)*3600.d0, psym=6, syms=1, col=100

imview, map_sn3, xmap = output_maps.xmap, ymap = output_maps.ymap, imr = [0, nsigma], title="S/N Flux A3", $
        position=pp1[5,*], /noerase
oplot, (point_source.ra-ra_center)*3600.d0*cos(dec_center), $
       (point_source.dec-dec_center)*3600.d0, psym=6, syms=1, col=100

imview, map_sn_1mm, xmap = output_maps.xmap, ymap = output_maps.ymap, imr = [0, nsigma], title="S/N Flux 1mm", $
        position=pp1[6,*], /noerase
oplot, (point_source.ra-ra_center)*3600.d0*cos(dec_center), $
       (point_source.dec-dec_center)*3600.d0, psym=6, syms=1, col=100

imview, map_sn2, xmap = output_maps.xmap, ymap = output_maps.ymap, imr = [0, nsigma], title="S/N Flux A2", $
        position=pp1[7,*], /noerase
oplot, (point_source.ra-ra_center)*3600.d0*cos(dec_center), $
       (point_source.dec-dec_center)*3600.d0, psym=6, syms=1, col=100
my_multiplot, /reset
outplot, /close

print, "Measured Gaussian fluxes: "
print, info.result_flux_i1, info.result_flux_i2, info.result_flux_i3
;;      0.065862635     0.012442301     0.068202898

;; Traditionnal plot
;; retrieve param1:
restore, project_dir+"/v_1/"+scan_list[0]+"/results.save"
param1.educated = 1
param1.do_aperture_photometry = 0
nk_average_scans, param1, scan_list, output_maps, info=info, /cumul, /center_nefd_only, $
                  flux_cumul=flux_cumul, sigma_flux_cumul=sigma_flux_cumul, $
                  flux_center_cumul=flux_center_cumul, sigma_flux_center_cumul=sigma_flux_center_cumul, $
                  time_center_cumul=time_center_cumul
nefd_plot, time_center_cumul, sigma_flux_center_cumul, nefd_list, source=source, $
           file=project_dir+'/NEFD_'+param.name4file, png=png, ps=ps

print, "max(time_center_cumul): ", max(time_center_cumul)

;; From Jackknife (check conventions in terms of full matrix, opacity
;; etc...)
;; nk_sensitivity_from_jk2, param1, scan_list
nk_sensitivity_from_jk3, param1, scan_list, nefd_jk_center_res

end
