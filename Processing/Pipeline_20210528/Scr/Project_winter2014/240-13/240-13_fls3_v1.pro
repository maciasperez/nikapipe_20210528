;;===============================================================
;;           Project:  240-13
;;           PI: 
;;           Affiliation: 
;;           Title: 
;;           NIKA team manager: 
;;           IRAM manager:
;;           Target description:
;;===============================================================
project_name = '240-13'

;csvfile = !nika.save_dir+"/Project_winter2014/Scan_Lists/"+project_name+".csv"
;extract_scan_list,csvfile,day_list,scan_num_list
;check_scan_list_exist,day_list, scan_num_list

vers = version

scan_22= [220,221,222,223,224,225,227,229,230,231,232,233,234,235,236,238,239,240,242,243,262,263,264,265,266,267,268,269,270,271,271,273,275,276,277,278,279,280,281,282,283]
scan_23 =[83,84,85,86,88,89,90,91,92,93,94,95,96,97,98,100,101,102,103,104,105,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,218,219,220,221,223,224,225,226,227,228,231,232,233,234,238,239,240,242,243,245,246,247,248,249,250,251,252,254,255,256]
scan_25=[113,114,115,116,117,118,119,120,121,122,125,126,127,128,129,130,131,132,133,134,135]
;; scan_25=[113,114,115,116,117,118,119,120,121,122,125,126,127,128,129,130,131,132,133,134,135,136]
scan_26=[142,144,145,146,147,148,149,150,151,152,153,154,155,156,158,159,160,161,162,163,164,165]
scan_28=[157,158,159,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,222,223,225,226,227]

case dayproc of
   22: begin
      scan_num_list =scan_22
      day_list = replicate('20140222',n_elements(scan_num_list))
      version = vers+'_22'
   end
   23: begin
      scan_num_list =scan_23
      day_list = replicate('20140223',n_elements(scan_num_list))
      version = vers+'_23'
   end
   25: begin
      scan_num_list =scan_25
      day_list = replicate('20140225',n_elements(scan_num_list))
      version = vers+'_25'
   end
   26: begin
      scan_num_list =scan_26
      day_list = replicate('20140226',n_elements(scan_num_list))
      version = vers+'_26'
   end
   28: begin
      scan_num_list =scan_28
      day_list = replicate('20140228',n_elements(scan_num_list))
      version = vers+'_28'
   end
   else: begin
      print, 'Define correct day !!!'
      return
   end
endcase

;; scan_num_list =[scan_22,scan_23,scan_25,scan_26,scan_28]
;; day_list = [replicate('20140222',n_elements(scan_22)),replicate('20140223',n_elements(scan_23)),replicate('20140225',n_elements(scan_25)),replicate('20140226',n_elements(scan_26)),replicate('20140228',n_elements(scan_28))]


;;------- The directory where to save the results
project_dir = !nika.save_dir+'/Project_winter2014/'+project_name 
print, "WORKING ON PROJECT: "
print, file_basename(project_dir)
;;; version = 'V0'
output_dir = project_dir+'/'+version
direxist = FILE_TEST(output_dir, /DIRECTORY)
if (direxist lt 1) then spawn, "mkdir -p "+output_dir 



;;------- My analysis parameters
;;version = 'V0FLS3only'
size_map_x = 420.0
size_map_y = 420.0
reso = 2.0
decor_mode = 'COMMON_MODE_BLOCK' 
d_min = 20.0
nbloc_min = 15
nsig_bloc = 2
apply_filter = 1

;;------- Do you want a something specific
sens_per_kid = 0  ; 1 to get one map per det.
rm_toi = 1                       
rm_bp = 1                   
rm_fp = 1                   
rm_uc = 1 
cos_sin= 1

;;;coord_map = {ra:[0,0,0.001],dec:[0,0,0.001]} ;Pointing coordinates                                                                                                                                                            


;;------- Launch everything
nika_pipe_launch_all_scan, scan_num_list, day_list, $
                           dir_plot=project_dir, $         
                           version=version,$               
                           size_map_x=size_map_x,$         
                           size_map_y=size_map_y,$       
                           coord_map = coord_map, $
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
                           /silent

version = vers
end
