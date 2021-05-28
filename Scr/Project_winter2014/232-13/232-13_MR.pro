;;===============================================================
;;           Project: 232-13
;;           PI: Dole & Macias-Perez
;;           Affiliation: IAS & LPSC
;;           Title: Confirming z SZgt= 2 cluster candidates observed by Planck and Herschel (NIKA guaranteed time proposal)
;;           NIKA team manager: Macias-Perez
;;           IRAM manager: 
;;           Target description: 
;;===============================================================
 
project_name = '232-13_MR'
;;------- The list of the scans to be reduced

scan_num_list = [39,40,41,42,43,44,45,46,47,48,49,50,51, $
                 52,53,60,61,62,63,64,65,66,67,68,69, $       ; PHZG322p62 'L'
                 57,58,59,60,61,62,63,64,65,66,67,68,69, $
                 70,71,65,66,67,68,69,81,82,83,84,85,86, $
                 87,88,89,90,91,92,93,94,95,96,97,98,99,100, $; PHZG006p61 'L'
                 58,59,61,62,63,64,65,66,67,68,70,71, $
                 72,73,74, $                                  ; PHZG325p63 'L'
                 242,243,244,245,246,247,248,249,250,251, $
                 252,253,254,255,256, $                       ; PHZG198p67 'L'
                 62,63,64,65,66,67,68,69,70,71,72,73,74, $
                 75,76]                                       ; PHZG191p62 'L'


day_list = ['20140221'+strarr(25), $                          ; PHZG322p62 'L'
            '20140223'+strarr(15), '20140228'+strarr(25), $   ; PHZG006p61 'L'
            '20140225'+strarr(15), $                          ; PHZG325p63 'L'
            '20140225'+strarr(15), $                          ; PHZG198p67 'L'
            '20140226'+strarr(15)]                            ; PHZG191p62 'L


;bad scans so far
;
;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+ project_name
;spawn, "rm -rf "+project_dir                 

spawn, "mkdir -p "+project_dir                 

;;------- My analysis parameters
;version = 'V0' ; standard processing for point sources
version = 'v2NOFILT' ; Adding new filtering from Remi !
size_map_x = 250.0
size_map_y = 250.0
reso = 2.0
decor_mode = 'COMMON_MODE_BLOCK' 
d_min = 20.0
nbloc_min = 15
nsig_bloc = 2
apply_filter = 0

;;------- Do you want a something specific
sens_per_kid = 0
rm_toi = 1                       
rm_bp = 1                   
rm_fp = 1                   
rm_uc = 1 
cos_sin = 1
;low_cut_filter=[0.15,0.25]
;;------- Launch everything
nika_pipe_launch_all_scan, scan_num_list, day_list, $
                           dir_plot=project_dir, $         
                           version=version,$               
                           size_map_x=size_map_x,$         
                           size_map_y=size_map_y,$         
                           reso=reso,$                     
                           decor=decor_mode,$              
                           nsig_bloc=nsig_bloc,$          
                           nbloc_min=nbloc_min,$           
                           d_min=d_min,$                   
                           apply_filter=apply_filter,$     
                           low_cut_filter=low_cut_filter,$ 
                           cos_sin=cos_sin,$               
                           rm_toi=rm_toi,$                       
                           rm_bp=rm_bp,$                   
                           rm_fp=rm_fp,$                   
                           rm_uc=rm_uc,$                   
                           sens_per_kid=sens_per_kid,$
                           no_flag=no_flag
                           

end
