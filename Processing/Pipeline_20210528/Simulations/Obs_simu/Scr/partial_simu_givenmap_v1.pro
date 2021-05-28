
;############### Full name of the source used in plots ###############
source = 'Reprocessing of M87'
version = 'v1'
coord = {ra:[12,30,49.40],dec:[+12,23,28]} ;Pointing coordinates

;############### Map parameters (NIKA pipeline) ###############
plotmap = {fov:140,$            ;field of view for the map
           relob:10,$           ;beam for smoothing (arcsec)
           range:{A:[-200,1300],$  ;minmax values of the maps
                  B:[-200,1400]},$
           cont:{A:[-1e5,1e5], $ ;contours level
                 B:[-1e5,1e5]}}

;############### Sources  ###############
type = 'given_map'

loc = {x:0.0,$                  ;Distance from the center (arcsec)
       y:0.0}

mapfile = !nika.SAVE_DIR+'/astrometry_M87.fits' ;File with flux A,B and associated variances

caract_source = {type:type,loc:loc,mapfile:mapfile}

;############### Atmosphere  ###############
atmo = {tau0_a:0.15,$
        tau0_b:0.1,$             ;tau at 140 GHz
        F_0:50,$                ;fluctuation amplitude when tau is infinity (Jy)
        alpha:0.8,$             ;Pente du bruit atmospherique (Kolmogorov :2.alpha= 5/3)
        cloud_vx:1.0,$          ;vitesse de defilement du nuage dans la direction x (azimuth)
        cloud_vy:0.1,$          ;vitesse de defilement du nuage dans la direction y (elevation)
        cloud_map_reso:0.5,$    ;resolution de la carte de nuages (metres)
        disk_convolve:1}        ;set to 1 to convolve cloud map with telescope diameter

;############### Electronic noise  ###############
elec = {f_ref:1,$               ;reference frequency (Hz)
        beta:-0.6,$             ;Slope of the electronic noise
        amp_cor:70.0e-3,$       ;Amplitude of the correlated noise at f_ref (Jy/sqrt(Hz))
        amp_dec:30.0e-3}        ;Amplitude of the correlated noise at f_ref (Jy/sqrt(Hz))

;############### Scan  ###############
year =  '2012'
month = '11'
day = {d14:-1,$                 ;Use scan corresponding to the given map
       d15:-1,$
       d16:-1,$
       d17:-1,$
       d18:-1,$
       d19:-1,$
       d20:-1,$
       d21:-1,$
       d22:-1,$
       d23:-1,$
       d24:[104,105,107,108],$
       d25:-1,$
       d26:-1}

;############### KIDs parameters file ###############
;file_kid_a = !nika.OFF_PROC_DIR+'/2012_11_15_22h27m16_0099_W1_kidpar_v6.fits'
;file_kid_b = !nika.OFF_PROC_DIR+'/2012_11_15_22h27m16_0099_W2_kidpar_v6.fits'
file_kid_a = !nika.OFF_PROC_DIR+'/Kidpar_A1mm_avg_20121120_v1.fits'
file_kid_b = !nika.OFF_PROC_DIR+'/Kidpar_B2mm_avg_20121120_v2.fits'
;file_kid_a = !nika.OFF_PROC_DIR+'/Kidpar_A1mm_avg_20121115_v1.fits'
;file_kid_b = !nika.OFF_PROC_DIR+'/Kidpar_B2mm_avg_20121115_v2.fits'

kid_file = {A:file_kid_a,B:file_kid_b}
  
;############### Map parameters (NIKA pipeline) ###############
  map = {size_ra:900,$        ;arcsec
         size_dec:900,$       ;arcsec
         reso:2}              ;arcsec

;############### Deglitching (NIKA pipeline) ###############
  glitch = {width:100,$
            nsigma:100}
  
;############### Decorrelation used (NIKA pipeline) ###############
  decor = {IQ_plane:'no',$     ;Do you want to (try) decorrelate the electronic noise in the IQ plane?
           ;method:'median',$
           method:'common_mode',$
           ;method:'none',$
           ;method:'SZ_1_array',$ ;Common mode from the KIDs far away
           ;method:'SZ_2_array',$ ;Common mode from 240 GHz
           ;method:'full',$
           ;method:'KIDs_close',$
           ;method:'test',$
           sz_dmin:50,$         ;Min distance for using the KID
           nkid_close:15,$
           width_median:200,$
           width_baseline:200,$
           nsmooth_common_mode:20}
  
;############### Filtering used (NIKA pipeline) ###############
  filter = {apply:'yes',$
           width:200,$
            nsigma:5,$
            freq_start:0.10}  ;Hz
  
;###### Observ. wavelength en mm ###############
JYperKRJ = {A:6.5,$             ;From the interpolation of the data given here:
            B:8.0}              ;http://www.iram.es/IRAMES/mainWiki/Iram30mEfficiencies

;########################################################################################################
;##################################### Derived parameters ###############################################
;########################################################################################################
  
nu = {A:!const.c*1d-6/!nika.lambda[0], B:!const.c*1d-6/!nika.lambda[1]}

  scan_list = 'none'
  if day.d14[0] ne -1 then scan_list = [scan_list, year+month+'14s'+string(day.d14, format="(I4.4)")]
  if day.d15[0] ne -1 then scan_list = [scan_list, year+month+'15s'+string(day.d15, format="(I4.4)")]
  if day.d16[0] ne -1 then scan_list = [scan_list, year+month+'16s'+string(day.d16, format="(I4.4)")]
  if day.d17[0] ne -1 then scan_list = [scan_list, year+month+'17s'+string(day.d17, format="(I4.4)")]
  if day.d18[0] ne -1 then scan_list = [scan_list, year+month+'18s'+string(day.d18, format="(I4.4)")]
  if day.d19[0] ne -1 then scan_list = [scan_list, year+month+'19s'+string(day.d19, format="(I4.4)")]
  if day.d20[0] ne -1 then scan_list = [scan_list, year+month+'20s'+string(day.d20, format="(I4.4)")]
  if day.d21[0] ne -1 then scan_list = [scan_list, year+month+'21s'+string(day.d21, format="(I4.4)")]
  if day.d22[0] ne -1 then scan_list = [scan_list, year+month+'22s'+string(day.d22, format="(I4.4)")]
  if day.d23[0] ne -1 then scan_list = [scan_list, year+month+'23s'+string(day.d23, format="(I4.4)")]
  if day.d24[0] ne -1 then scan_list = [scan_list, year+month+'24s'+string(day.d24, format="(I4.4)")]
  if day.d25[0] ne -1 then scan_list = [scan_list, year+month+'25s'+string(day.d25, format="(I4.4)")]
  if day.d26[0] ne -1 then scan_list = [scan_list, year+month+'26s'+string(day.d26, format="(I4.4)")]
  scan_list = scan_list[1:*]

  iscan = 0                     ;label the scan used, modified in the pipeline
  scan_type = ' '               ;Direction of the scan (azimuth or elevation) 

;########################################################################################################
;##################################### Creation of the structure ########################################
;########################################################################################################

param = {source:source,$
         version:version,$
         coord:coord,$
         caract_source:caract_source,$
         scan_list:scan_list,$
         plotmap:plotmap,$
         atmo:atmo,$
         elec:elec,$
         iscan:iscan,$
         scan_type:scan_type,$
         kid_file:kid_file,$
         map:map,$
         glitch:glitch,$
         decor:decor,$
         filter:filter,$
         nu:nu,$
         JYperKRJ:JYperKRJ}

name4file = STRJOIN(STRSPLIT(source, /EXTRACT), '_')  
source_param_file = !nika.SAVE_DIR+'/partial_simu_param_'+name4file+'_'+version+'.save'

save, filename=source_param_file, param

partial_simu_launch, source_param_file
nika_pipe_launch, !nika.SAVE_DIR+'/partial_simu_TOI_'+name4file+'_'+version, map_combi, /simu
  
end
