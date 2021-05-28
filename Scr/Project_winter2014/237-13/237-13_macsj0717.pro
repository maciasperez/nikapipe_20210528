;;===============================================================
;;           Project: 237-13
;;           PI: Rémi Adam & Barbara Comis 
;;           Affiliation: LPSC 
;;           Title: Thermal Sunyaev-Zel’dovich mapping of high redshift galaxy clusters
;;           NIKA team manager: Barbara Comis
;;           IRAM manager: Carsten Kramer
;;           Target description: SZ cluster
;;===============================================================
 
;;------- Properties of the source to be given here ------------------
source = 'MACSJ0717'                                  ;Name of the source
version = 'v1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'

;;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.plot_dir+"/"+name4file
spawn, "mkdir -p "+output_dir

;;------- OTF Scans --------------
sn1 = [234,235,236,237,239,240,241,242,243,244,245,246,247]
sn2 = [011,012,013,014,015,016,017,018,019,020,021,022,023,024,029,030,031,032,033,034,035,036,355,356,357,358,359,360,361,362,363,364,365,366,367,368,379,380,381,382,383,384,385,386,387,388,389,441,442,443,444,445,446,447,448,449,450,451,452,453,454]
sn3 = [04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21]
sn4 = [313,314,315,316,336,337,345]

d1 = '20140221'+strarr(n_elements(sn1))
d2 = '20140222'+strarr(n_elements(sn2))
d3 = '20140223'+strarr(n_elements(sn3))
d4 = '20140223'+strarr(n_elements(sn4))

scan_num = [sn1,sn2,sn3,sn4]
day = [d1,d2,d3,d4]

;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir

param.map.reso = 5
param.map.size_ra = 600
param.map.size_dec = 600

param.filter.apply = 'yes'
param.filter.freq_start = 1.5
param.filter.nsigma = 5

param.w8.nsigma_cut = 4.0
param.zero_level.per_subscan = 'yes'

param.decor.method = 'COMMON_MODE'

;;------- Launch the pipeline
;nika_pipe_launch, param, map_combi, map_list, /use_noise_from_map, /check_flag_cor, /check_flag_speed, /meas_atm, /plot_decor_toi, /ps

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar
anapar.flux_map.relob.a = 5
anapar.flux_map.relob.b = 5
anapar.flux_map.noise_max = 2
;anapar.flux_map.range1mm = [-5,5]*1e-3
;anapar.flux_map.range2mm = [-3,3]*1e-3
;anapar.flux_map.conts2mm = [-3,-2,-1,1,2,3]*1e-3
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10
anapar.snr_map.fov = 500
anapar.flux_map.fov = 500

anapar.noise_meas.apply = 'yes'
anapar.noise_meas.jk.relob.a = 15
anapar.noise_meas.jk.relob.b = 15

anapar.profile.apply = 'yes'
anapar.profile.method = 'coord'
anapar.profile.nb_pt = 60
anapar.profile.xr[0,*] = [0,160]
anapar.profile.coord[0].ra = [07.0,17.0,33.0]
anapar.profile.coord[0].dec = [37.0,45.0,0.0]

anapar.cor_zerolevel.a = 0.6e-3
anapar.cor_zerolevel.b = -0.4e-3

nika_anapipe_launch, param, anapar

stop
end
