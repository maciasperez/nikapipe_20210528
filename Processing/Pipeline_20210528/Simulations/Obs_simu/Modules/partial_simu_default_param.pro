;+
;PURPOSE: Produces a default param structure and parameter file to be used by the
;         simulation pipeline modules
;
;INPUT: The type of the source to be simulated
;
;OUTPUT: The param structure.
;
;LAST EDITION: 
;   2013: creation (adam@lpsc.in2p3.fr)
;   27/09/2013: add error beam source type (adam@lpsc.in2p3.fr)
;   23/01/2014: change units of the pressure profile and add
;               concentration parameter
;-

pro partial_simu_default_param, param, type_of_the_source

;;############### Sources  ###############
  case strupcase(type_of_the_source) of
     ;;-1------- Point source
     "POINT_SOURCE": begin
        message, /info, "The simulated source is a point source"
        type = 'point_source'
        flux = {A:1.0, B:1.0}     ;Jy
        beam = {A:12.5, B:18.5}
        caract_source = {type:type, flux:flux, beam:beam}
     end
     
     ;;-1bis---- Point source with error beam
     "POINT_SOURCE_EB": begin
        message, /info, "The simulated source is a point source including error beams"
        type = 'point_source_eb'
        flux = {A:1.0, B:1.0}     ;Jy
        beam1 = {A:10.5, B:16.0}  ;Based on Greve et al. 150 and 230 GHz
        beam2 = {A:125.0, B:175.0}
        beam3 = {A:180.0, B:280.0}
        amp1 = {A:0.975, B:1.0}
        amp2 = {A:0.005, B:0.0015}
        amp3 = {A:0.001, B:0.00055}
        caract_source = {type:type, flux:flux, beam1:beam1, beam2:beam2, beam3:beam3, $
                         amp1:amp1, amp2:amp2, amp3:amp3}
     end
     
     ;;-2------- Galaxy cluster
     "CLUSTER": begin
        message, /info, "The simulated source is a galaxy cluster"
        type = 'cluster'
        z = 0.45                ;redshift
        P0 = 3.28               ;Parametre de pression central (keV/cm^3)
        a = 0.9                 ;Parametrisation universelle de pression (chandra: 0.9)
        b = 5.0                 ;Parametrisation universelle de pression (chandra: 5)
        c = 0.0                 ;Parametrisation universelle de pression (chandra: 0.4)
        conc = 1.81             ;Parametrisation universelle de pression (concentration)
        rs = 70.0               ;Parametrisation universelle de pression (en arcsec)
        beam = {A:12.5, B:18.5}
        caract_source = {type:type,z:z,P0:P0,a:a,b:b,c:c,conc:conc,rs:rs, beam:beam}
     end
     
     ;;-3------- Galaxy cluster + 1 point source
     "CLUSTER+PS": begin
        message, /info, "The simulated source is a galaxy cluster containing a point source"
        type = 'cluster+ps'
        loc_ps = {x:21.15,$     ;Loc of the point source
                  y:31.9}
        flux_ps = {A:0.0032,$   ;Flux of the point source in mJy
                   B:0.0044}
        
        z = 0.45                ;redshift
        P0 = 3.28               ;Parametre de pression central (keV/cm^3)
        a = 0.9                 ;Parametrisation universelle de pression (chandra: 0.9)
        b = 5.0                 ;Parametrisation universelle de pression (chandra: 5)
        c = 0.0                 ;Parametrisation universelle de pression (chandra: 0.4)
        conc = 1.81             ;Parametrisation universelle de pression (concentration)
        rs = 70.0               ;Parametrisation universelle de pression (en arcsec)

        beam = {A:12.5, B:18.5}

        caract_source = {type:type,ps:{loc:loc_ps, flux:flux_ps},beam:beam,$
                         cluster:{z:z,P0:P0,a:a,b:b,c:c,conc:conc,rs:rs}}
     end

     ;;-4------- Disk (sharp, no lobe)
     "DISK": begin
        message, /info, "The simulated source is a disk"
        type='disk'
        flux = {A:1.0, B:1.0}
        radius = 30.0
        caract_source = {type:type, flux:flux, radius:radius}
     end

     ;;-5------- Lensing
     "CLUSTER_LENSING": begin
        message, /info, "The simulated source is the CMB lensed by a cluster (no SZ included)"
        type = 'cluster_lensing'
        z = 1.0                 ;redshift
        M_200 = 1.4285715e15    ;Cluster mass
        a = 1.0                 ;Parametrisation universelle
        b = 3.0                 ;Parametrisation universelle
        c = 1.0                 ;Parametrisation universelle
        rs = 323.55422          ;scale radius of the density profile (kpc)       
        unlensclt_file = !nika.soft_dir+'/NIKA_lib/Simulations/Cosmofid/base_Planck_lmax21000_unlensClT.fits' ; fiducial unlensed ClT fits file (from CAMB) 
        cmbstockastic = 0       ;set to 1 to generate a cmb map realisation from the Cl; if set to 0, tmap is a pure gradient
        cmbsubtraction = 0      ;set to 1 to obtain the lensed map subtracted for the unlensed cmb
        beam = {A:12.5, B:18.5}
        caract_source = {type:type,$
                         z:z,M_200:M_200,a:a,b:b,c:c,rs:rs,$
                         beam:beam,$
                         unlensclt_file:unlensclt_file,cmbstockastic:cmbstockastic,cmbsubtraction:cmbsubtraction}
     end
     
     ;;-7------- Given map
     "GIVEN_MAP": begin
        message, /info, "The simulated source is a given map"
        message, /info, "It has to be a fits with the corresponding file given in param.caract_source.mapfile"
        type = 'given_map'
        mapfile1mm = ''         ;File with flux 1mm and associated variances
        mapfile2mm = ''         ;File with flux 2mm and associated variances
        relob = {A:10.0, B:10.0}
        caract_source = {type:type,mapfile1mm:mapfile1mm,mapfile2mm:mapfile2mm,relob:relob}
     end
  endcase

  ;;############### Atmosphere  ###############
  atmo = {tau0_a:0.12,$          ;tau at 240 GHz, set to -1 for real values
          tau0_b:0.1,$           ;tau at 140 GHz
          F_0:[157.0,29.0],$     ;fluctuation amplitude when tau is infinity (Jy)
          F_el:[43.0,13.0]*273,$ ;fluctuation amplitude when tau is infinity (Jy/arcsec)
          alpha:1.35,$           ;Pente du bruit atmospherique (Kolmogorov :2.alpha= 5/3)
          cloud_vx:1.0,$         ;vitesse de defilement du nuage dans la direction x (azimuth)
          cloud_vy:0.1,$         ;vitesse de defilement du nuage dans la direction y (elevation)
          cloud_map_reso:0.2,$   ;resolution de la carte de nuages (metres)
          cloud_alt:2000.0,$     ;Altitude des nuages
          disk_convolve:1}       ;set to 1 to convolve cloud map with telescope diameter

  ;;############### Electronic noise  ###############
  elec = {f_ref:1.0,$                ;reference frequency (Hz)
          beta:-0.3,$                ;Slope of the electronic noise
          amp_cor:[50.0,20.0]*1e-3,$ ;Amplitude of the correlated noise at f_ref (Jy.sqrt(s))
          beta_block:-0.6, $
          amp_block:[10.0,15.0,20.0,25.0,30.0, $
                     2.0,4.0,6.0,8.0,10.0]*1e-3, $
          amp_dec:[57.0,29.0]*1e-3}  ;Amplitude of the correlated noise at f_ref (Jy.sqrt(s))
  
  ;;############### Glitches ###############
  simu_glitch = {rate:1.0/60.0,$
                 mean_ampli:0.0,$
                 sig_ampli:1.3}

  ;;############### Pulse tube ###############
  pulse_tube = {freq:[2.75, 5.5, 11.0],$
                amp:[0.0, 0.0, 0.0],$
                phase:[0.0,0.0,0.0]} ;phase: amp * cos(2*!pi* t*freq + phase)

  ;;############### The plateau ###############
  plateau = {A:0.0, B:0.0}      ;percentage of the total flux in the array that goes into the TOI of a KID
  
  ;;############### Add this parameters to the original structure ###############
  new_struct = {caract_source:caract_source,$
                atmo:atmo,$
                elec:elec,$
                simu_glitch:simu_glitch,$
                pulse_tube:pulse_tube,$
                plateau:plateau}
  upgrade_struct, param, new_struct, new_param
  param = new_param

end
