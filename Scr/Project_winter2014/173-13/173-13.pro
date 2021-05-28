;;===============================================================
;;           Project: 173-13
;;           PI: Lestrade
;;           Affiliation: 
;;           Title: Modelling the azimuthal structures of the debris disk around SZepsilon Eri
;;           NIKA team manager:
;;           IRAM manager: 
;;           Target description: 
;;===============================================================
 
project_name = '173-13'
;;------- The list of the scans to be reduced
scan_num_list = [ 234,235,236,238,239,240,241,242,243,244,245,248,257,258,259,260,262,$
                  232,233,234,235,236,237,238,239,240,241,242,243,247,248,249,250,251,252,253,254,255,256 $ 
                ]              
day_list = '201402'+[replicate('19',17), $
                    replicate('19',22) $
                    ]                   
;bad scans so far
;261
;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+ project_name
spawn, "rm -rf "+project_dir                 
spawn, "mkdir -p "+project_dir                 

;;------- My analysis parameters
version = 'V1'
size_map_x = 250.0
size_map_y = 250.0
reso = 2.0
decor_mode = 'COMMON_MODE_BLOCK' 
d_min = 20.0
nbloc_min = 15
nsig_bloc = 2
apply_filter = 1

;;------- Do you want a something specific
sens_per_kid = 1
rm_toi = 1                       
rm_bp = 1                   
rm_fp = 1                   
rm_uc = 1 
cos_sin = 1

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
