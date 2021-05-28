;;===============================================================
;;           Project:  240-13
;;           PI: Rob Ivison
;;           Affiliation: UKATC & IAC
;;           Title: The space density and environments of z>4 ultra-red Herschel SMGs 
;;           NIKA team manager: Francois-Xavier Desert
;;           IRAM manager: Carsten Kramer
;;           Target description: Point source+Extended
;;===============================================================
project_name = '240-13-G'

; all avail. scan for this project (extracted from TAPAS) :       
csvfile = !nika.save_dir+"/Project_winter2014/Scan_Lists/"+project_name+".txt"
extract_scan_list,csvfile,day_list,scan_num_list,/singlesource


;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+project_name 
direxist = FILE_TEST(project_dir, /DIRECTORY)
if (direxist lt 1) then spawn, "mkdir -p "+project_dir  
print, "WORKING ON PROJECT: "
print, file_basename(project_dir)


;;------- first conservative pre-selection of the scans
get_ok_scan_list, day_list, scan_num_list,output_dir=project_dir


;;------- My analysis parameters
version = 'V0'
size_map_x = 250.0
size_map_y = 250.0
reso = 2.0
decor_mode = 'COMMON_MODE_BLOCK' 
d_min = 20.0
nbloc_min = 15
nsig_bloc = 2
apply_filter = 1
cos_sin = 1

;;------- Do you want something specific
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
