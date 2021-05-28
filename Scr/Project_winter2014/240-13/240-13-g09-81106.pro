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
source = 'G09-81106'                              ;Name of the source
version = 'V0'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
map_coord = {ra:[08.0,49.0,37.0], dec:[00.0,14.0,55.0]}

;;--------- The scans I want to use and the corresponding days
csvfile = !nika.save_dir+"/Project_winter2014/Scan_Lists/"+project_name+'-'+source+".csv"
extract_scan_list,csvfile,day_list,scan_num_list

;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+project_name+'/G' 
direxist = FILE_TEST(project_dir, /DIRECTORY)
if (direxist lt 1) then spawn, "mkdir -p "+project_dir                 
print, "WORKING ON PROJECT: "
print, project_dir

;;------- pre-selection of the scans (discarding bad ones)
get_ok_scan_list, day_list, scan_num_list,output_dir=project_dir

;;------- try more aggressive selection
day_list=['20140221','20140221','20140221']
scan_num_list = ['3','4','5']

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
