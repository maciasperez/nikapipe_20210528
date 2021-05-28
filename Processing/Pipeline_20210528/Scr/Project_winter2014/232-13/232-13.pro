;;===============================================================
;;           Project: 232-13
;;           PI: Dole & Macias-Perez
;;           Affiliation: IAS & LPSC
;;           Title: Confirming z SZgt= 2 cluster candidates observed by Planck and Herschel (NIKA guaranteed time proposal)
;;           NIKA team manager: Macias-Perez
;;           IRAM manager: 
;;           Target description: 
;;===============================================================
 
project_name = '232-13'
;;------- The list of the scans to be reduced
;scan_num_list = [39,40,41,42,43,44,45,46,47,48,49,50,51,52,53 $
   ;             ]              
;day_list = '201402'+[replicate('21',15) $
 ;                   ]                   
scan_num_list = [62,63,64,65,66,67,68,69,70,71,72,73,74,75,76]
day_list = '201402'+[replicate('26',15)]

;scan_num_list = [62,63,64,68,69,71,72,73,76]
;day_list = '201402'+[replicate('26',9)]
;bad scans so far
;
;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+ project_name
;spawn, "rm -rf "+project_dir                 
spawn, "mkdir -p "+project_dir                 

;;------- My analysis parameters
;version = 'V0' ; standard processing for point sources
version = 'V1testNEW' ; Adding new filtering from Remi !
size_map_x = 250.0
size_map_y = 250.0
reso = 2.0
decor_mode = 'COMMON_MODE_BLOCK' 
d_min = 20.0
nbloc_min = 15
nsig_bloc = 2
apply_filter = 1

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
                           no_flag=no_flag, $
                           dist_source_filter = 0.1

                           

end
