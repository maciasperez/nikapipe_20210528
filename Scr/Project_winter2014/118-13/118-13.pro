;;===============================================================
;;           Project:  118-13
;;           PI: Lellouch
;;           Affiliation: OBSPM
;;           Title: Pluto's thermal emission at radio-wavelengths
;;           NIKA team manager: macias
;;           IRAM manager:
;;           Target description: point sources
;;===============================================================
 
project_name = '118-13'

;;------- The list of the scans to be reduced
;; scan_num_list = [177,179,180,181,182,183,184,186,188,189,190, $ ; Pluto
;;                  192,193,203,204] ; Uranus                   
;; ; bad scans so far
;; ; 187,200, 201,194
;; day_list = ['20140219'+strarr(11), $                 ;
;;             '20140219'+strarr(4)]                   ;

;scan_num_list =[178]
;day_list =  ['20140219']
project_name = '118-13'
; get_ok_scan_list, project_name, day_list, scan_num_list

csvfile = !nika.save_dir+"/Project_winter2014/Scan_Lists/"+project_name+".csv"
extract_scan_list,csvfile,day_list,scan_num_list
;get_ok_scan_list, project_name, day_list, scan_num_list

;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+project_name 
direxist = FILE_TEST(project_dir, /DIRECTORY)
if (direxist lt 1) then spawn, "mkdir -p "+project_dir  
print, "WORKING ON PROJECT: "
print, file_basename(project_dir)
version = 'V0'
;output_dir = project_dir+'/'+version
;direxist = FILE_TEST(output_dir, /DIRECTORY)
;if (direxist lt 1) then spawn, "mkdir -p "+output_dir 

;;------- pre-selection of the scans (discarding bad ones)
get_ok_scan_list, day_list, scan_num_list,output_dir=project_dir

;;------- My analysis parameters
size_map_x = 250.0
size_map_y = 250.0
reso = 2.0
decor_mode = 'COMMON_MODE_BLOCK' 
d_min = 20.0
nbloc_min = 15
nsig_bloc = 2
apply_filter = 1

;;------- Do you want something specific
sens_per_kid = 1
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
                           no_flag=no_flag

end
