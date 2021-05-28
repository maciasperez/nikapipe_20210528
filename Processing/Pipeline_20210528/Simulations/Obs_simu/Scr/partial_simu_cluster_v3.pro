
;############### Full name of the source used in plots ###############
source = 'Simulation - cluster compact 0cor'
version = 'v1'
coord = {ra:[13,47,31],dec:[-11,45,13]} ;Pointing coordinates

;############### Map parameters (NIKA pipeline) ###############
plotmap = {fov:300,$            ;field of view for the map
           relob:10,$           ;beam for smoothing (arcsec)
           range:{A:[-100,100],$  ;minmax values of the maps
                  B:[-13,13]},$
           cont:{A:[-1e5,-5,5,1e5], $ ;contours level
                 B:[-1e5,-9,-6,-3,3,1e5]}}

;############### Sources  ###############
type = 'cluster'

loc = {x:0.0,$                  ;Distance from the center (arcsec)
       y:0.0}

z = 0.45                        ;redshift
M_500 = 0                       ;Cluster mass (solar mass, set it to 0 if you want only P0 and not P500)
P0 = 526e-12                    ;Parametre de pression central (sans unite, unless M_500 is 0)
a = 0.9                         ;Parametrisation universelle de pression (chandra: 0.9)
b = 5.0                         ;Parametrisation universelle de pression (chandra: 5)
c = 0.0                         ;Parametrisation universelle de pression (chandra: 0.4)
rs = 406.0                      ;Parametrisation universelle de pression (en kpc)

caract_source = {type:type,loc:loc,z:z,M_500:M_500,P0:P0,a:a,b:b,c:c,rs:rs}

;############### Atmosphere  ###############
atmo = {tau0_a:'real',$         ;tau at 240 GHz
        tau0_b:'real',$         ;tau at 140 GHz
        F_0:[0,0],$            ;fluctuation amplitude when tau is infinity (Jy)
        F_el:[0,0]*273,$       ;fluctuation amplitude when tau is infinity (Jy/arcsec)
        alpha:1.35,$           ;Pente du bruit atmospherique (Kolmogorov :2.alpha= 5/3)
        cloud_vx:1.0,$         ;vitesse de defilement du nuage dans la direction x (azimuth)
        cloud_vy:0.1,$         ;vitesse de defilement du nuage dans la direction y (elevation)
        cloud_map_reso:0.5,$   ;resolution de la carte de nuages (metres)
        disk_convolve:1}       ;set to 1 to convolve cloud map with telescope diameter

;############### Electronic noise  ###############
elec = {f_ref:1,$               ;reference frequency (Hz)
        beta:-0.25,$            ;Slope of the electronic noise
        amp_cor:[0,0]*1e-3,$    ;Amplitude of the correlated noise at f_ref (Jy/sqrt(Hz))
        amp_dec:[81,31]*1e-3}   ;Amplitude of the correlated noise at f_ref (Jy/sqrt(Hz))

;############### Scan  ###############
year =  '2012'
month = '11'
day = {d14:-1,$
       d15:-1,$
       d16:-1,$
       d17:-1,$
       d18:-1,$
       d19:-1,$
       d20:-1,$
       ;Scan analyse
       d21:[82,88,89,90,100,102,103,104],$
       d22:[78,79,81,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104],$ 
       d23:[89,90,92,93,95,97,98,99,100,102,103,104,105,107,108,109,110,112,113,114,115,117,118],$
       d24:-1,$
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
  map = {size_ra:600,$        ;arcsec
         size_dec:600,$       ;arcsec
         reso:2}              ;arcsec

;############### Deglitching (NIKA pipeline) ###############
  glitch = {width:100,$
            nsigma:4}
  
;############### Decorrelation used (NIKA pipeline) ###############
  decor = {IQ_plane:'no',$     ;Do you want to (try) decorrelate the electronic noise in the IQ plane?
           ;method:'median',$
           ;method:'common_mode',$
           method:'none',$
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
  filter = {apply:'no',$
            width:200,$
            nsigma:4.5,$
            freq_start:0.04}  ;Hz
  
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
