;;===============================================================
;;           Project:  151-13
;;           PI: 
;;           Affiliation: 
;;           Title: 
;;           NIKA team manager: macias
;;           IRAM manager:
;;           Target description:
;;===============================================================
 
project_name = '151-13'


scan_num_list =[262,263,264,265,266,267,268,269,271,272,273,274, $
               185,186,187,188,189,190,191,192,193,194,195,198,200,201,202,203,204,205,206,207,208,209,210]
day_list =  [replicate('20140223',12),replicate('20140225',23)]


project_name = '151-13'
; get_ok_scan_list, project_name, day_list, scan_num_list


;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+project_name 
print, "WORKING ON PROJECT: "
print, file_basename(project_dir)
;;; version = 'V0'
output_dir = project_dir+'/'+version
direxist = FILE_TEST(output_dir, /DIRECTORY)
if (direxist lt 1) then spawn, "mkdir -p "+output_dir 


;;------- My analysis parameters
size_map_x = 350.0  ; changed from 250
size_map_y = 350.0
reso = 2.0
decor_mode = 'COMMON_MODE_BLOCK' 
d_min = 15.0  ; 30 too big changed back to 20
nbloc_min = 15
nsig_bloc = 2
apply_filter = 1

;;------- Do you want something specific
sens_per_kid = 0 ; don't need map per kid
rm_toi = 1                       
rm_bp = 1                   
rm_fp = 1                   
rm_uc = 1 
cos_sin= 1

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
                           no_flag=no_flag, /silent

end
