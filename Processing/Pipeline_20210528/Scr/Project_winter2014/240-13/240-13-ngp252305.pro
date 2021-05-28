;;===============================================================
;;           Project:  240-13
;;           PI: Rob Ivison
;;           Affiliation: UKATC & IAC
;;           Title: The space density and environments of z>4 ultra-red Herschel SMGs 
;;           NIKA team manager:  Francois-Xavier Desert
;;           IRAM manager:  Carsten Kramer
;;           Target description: Point source
;;===============================================================

project_name = '240-13'

;;--------- Some names I want to use + pointing (to be read from IMB_fits) 
source = 'NGP-252305'                              ;Name of the source
version = 'V1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
map_coord = {ra:[12.0,56.0,07.0], dec:[22.0,30.0,46.0]}

;;--------- The scans I want to use and the corresponding days
csvfile = !nika.save_dir+"/Project_winter2014/Scan_Lists/"+project_name+'-'+source
extract_scan_list,csvfile,day_list,scan_num_list
check_scan_list_exist,day_list, scan_num_list


;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+project_name+'/NGP' 
direxist = FILE_TEST(project_dir, /DIRECTORY)
if (direxist lt 1) then spawn, "mkdir -p "+project_dir                 
print, "WORKING ON PROJECT: "
print, project_dir

;;------- My analysis parameters
size_map_x = 250.0
size_map_y = 250.0
reso = 2.0
decor_mode = 'COMMON_MODE_BLOCK' 
d_min = 20.0
nbloc_min = 15
nsig_bloc = 2
apply_filter = 1
cos_sin = 1
low_cut_filter = 0

;;------- Do you want something specific ?
sens_per_kid = 1
rm_toi = 1                       
rm_bp = 1                   
rm_fp = 1                   
rm_uc = 1 


;;------- Launch everything
lp_nika_pipe_launch_all_scan, scan_num_list, day_list, $
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
