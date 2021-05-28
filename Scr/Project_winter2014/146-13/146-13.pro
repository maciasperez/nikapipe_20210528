;;===============================================================
;;           Project:  146-13
;;           PI: P. Andre
;;           Affiliation: SAP-CEA
;;           Title: Probing the inner structure of the Taurus main filament (NIKA guaranteed time proposal)
;;           NIKA team manager:  Nicolas Ponthieu
;;           IRAM manager: Nicolas Billot 
;;           Target description: Extended emission
;;===============================================================

project_name = '146-13'

;;------- The list of the scans to be reduced
scan_num_list = [269,270,271,272,294,295,296,297,298,299,$      ; 2014-02-19
                 300,301,302,303,304,310,311,312,313,314,316, $ ; 2014-02-19
                 310, 311, 312, 320, 321, 322, 323, 324, 329, $ ; 2014-02-20 
                 330, 331, 332, 333, 334, 335, 336, 337, 338, $ ; 2014-02-20
                 339, 340, 346, 347, 348, 349] 
day_list = ['20140219'+strarr(10), $                 ;
            '20140219'+strarr(11), $
            '20140220'+strarr(18), $ 
            '20140220'+strarr(6)]                    ;

;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+project_name 
spawn, "rm -rf "+project_dir   
spawn, "mkdir -p "+project_dir                 
print, "WORKING ON PROJECT: "
print, project_dir
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
cos_sin = 1

;;------- Do you want a something specific
sens_per_kid = 1
rm_toi = 1                       
rm_bp = 1                   
rm_fp = 1                   
rm_uc = 1 

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
