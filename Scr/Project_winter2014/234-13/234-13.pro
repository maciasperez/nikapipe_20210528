;;===============================================================
;;           Project: 234-13
;;           PI: Matthieu Béthermin 
;;           Affiliation: ESO Garching 
;;           Title: Dust content in a merger of two very-high-mass galaxies at z∼3.2
;;           NIKA team manager: Nicolas Ponthieu
;;           IRAM manager: Israel Hermelo 
;;           Target description: Point source 
;;===============================================================
 
project_name = '234-13'
;;------- The list of the scans to be reduced
scan_num_list = [48,49,50,51,52,53]              
;scan_num_list = [49,50,51,52,53]              
day_list = '201402'+[replicate('19',6)]

; redefined from CSV file                    ]                   
csvfile = !nika.save_dir+"/Laurence/234-13.csv"
extract_scan_list,csvfile,day_list,scan_num_list

; bad scans 54
nscans = n_elements(scan_num_list)
scan_num_list = scan_num_list[0:nscans-2]  
day_list = day_list[0:nscans-2]  

;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+ project_name
direxist = FILE_TEST(project_dir, /DIRECTORY)
;spawn, "rm -rf "+project_dir                 
if (direxist lt 1) then spawn, "mkdir -p "+project_dir                 

;;------- My analysis parameters
version = 'V0allscans'
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
