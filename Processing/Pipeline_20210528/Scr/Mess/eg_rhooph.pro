;;===============================================================
;;           Example script 3 - Rho Ophuchius (Run6)
;;           Source properties: weak extended with multiple pointings
;;===============================================================
 
;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'Rho Ophuchius'                           ;Name of the source
version = 'Veg'                                    ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
map_coord = {ra:[16.0,27.0,15.1], dec:[-24.0,28.0,20.0]}

;;--------- The scans I want to use and the corresponding days
scan_num = [245,247,249,251,253, 2, 179,$
            220,221,222,224, 226,228, 233,235,$
            2, 4, 105,107,109]
day = '201306'+['15','15','15','15','15', '16', '16', $
                '15','15','15','15','15','15','15','15', $
                '18','18','17','17','17']

;;--------- Prepare output directory for plots and logbook 
output_dir = !nika.plot_dir+"/Example/"+name4file
spawn, "mkdir -p "+output_dir

;;--------- Init default param and change the ones you want to change 
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir
param.coord_map = map_coord

param.map.size_ra = 600
param.map.size_dec = 600
param.map.reso = 5
param.decor.method = 'pca_1band'
param.decor.pca.pca_subscan = 'yes'
param.decor.pca.dec_subscan = 'yes'
param.decor.pca.Ncomp = 1

;;------- Launch the pipeline
nika_pipe_launch, param, map_combi, map_list, range_plot_scan_a=[-0.07,0.07],range_plot_scan_b=[-0.03,0.03], /meas_atm, /check_flag_speed, /check_flag_cor, /ps, /make_log

;;======= Plots after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar
anapar.flux_map.noise_max = 30.0
anapar.flux_map.range1mm = [-0.01,0.070]
anapar.flux_map.range2mm = [-0.005,0.02]
anapar.flux_map.relob.a = 10.0
anapar.flux_map.relob.b = 10.0
anapar.noise_map.relob.a = 10.0
anapar.noise_map.relob.b = 10.0
anapar.time_map.relob.a = 10.0
anapar.time_map.relob.b = 10.0
anapar.snr_map.relob.a = 10.0
anapar.snr_map.relob.b = 10.0

anapar.snr_map.conts1mm = [-12,-9,-6,-3,3,6,9,12,15,18,21]
anapar.snr_map.conts2mm = [-12,-9,-6,-3,3,6,9,12,15,18,21]

anapar.search_ps.apply = 'yes'
anapar.search_ps.range1mm = [-0.04,0.04]
anapar.search_ps.range2mm = [-0.02,0.02]

anapar.cor_zerolevel.a = 0.035
anapar.cor_zerolevel.b = 0.01

cubehelix
nika_anapipe_launch, param, anapar, /no_sat
loadct,39
stop
end


