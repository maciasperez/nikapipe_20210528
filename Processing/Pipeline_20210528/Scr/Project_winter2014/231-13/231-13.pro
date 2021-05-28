;;===============================================================
;;           Project:  231-13
;;           PI: Omont
;;           Affiliation: IAP
;;           Title: Identifying high-z single-halo proto-clusters of H-ATLAS submm galaxies
;;           NIKA team manager:  Francois-Xavier Desert
;;           IRAM manager:  Albrecht Sievers 
;;           Target description: Point Source
;;===============================================================

project_name = '231-13'

;;------- The list of the scans to be reduced
scan_num_list = [329,330,331,332,333,341,342,343,344,1, $ ; H0902-01 'L'
                ; 2,3,4,5, $ ; H0902-01 'O'
                 334,335,336,337,338,7,8,9,10, $ ; H0844-00 'L'
                ; 11,12,13,14, $ ; H0844-00 'O'
                 326,328,340]  ;0823+033
; bad scans so far
; 
day_list = ['20140219'+strarr(9), '20140220', $           ; H0902-01 'L'
            '20140219'+strarr(5), '20140220'+strarr(4), $ ; H0844-00 'L'
            '20140219'+strarr(3) ]                        ; 0823+033

;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+project_name 
direxist = FILE_TEST(project_dir, /DIRECTORY)
;spawn, "rm -rf "+project_dir   
if (direxist lt 1) then spawn, "mkdir -p "+project_dir                 
print, "WORKING ON PROJECT: "
print, project_dir
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
;cos_sin = 1

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
