PRO compile_read_nika_pipe, compilation_dir=compilation_dir, version=version
;+
; NAME:
;  
; PURPOSE:
;  compile routines C for reading camera data
;
; CALLING SEQUENCE:
;  compile_camer
; INPUT:
;  none
; OUTPUT:
;  none
; KEYWORDS:
;
; EXAMPLES:
;
; RESTRICTIONS:
;  None.
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;  Written by J. Macias Perez, September 2010
;  Modify A.Benoit  january 2013
;  Modified NP, Feb. 4th, 2013 : replaced hard coded directories by
;                                !nika.camera_dir for portability
; Modified NP, Jan. 9th, 2014 : to replace compile_read_nika and avoid confusion
; with NIKA_lib/Readdata/IDL/compile_read_nika

 
;; if NOT keyword_set( compilation_dir) then begin
;; ;   compilation_dir = !nika.soft_dir+'/Pipeline/Readdata/C/'
;; ;   compilation_dir =
;; ;   '/home/observer/NIKA/branch/Observer/Pipeline/Readdata/C/'
;;    compilation_dir = !nika.pipeline_dir+'/Readdata/C/'
;; endif
;; 
;; ;;so_dir = !nika.soft_dir+"/Pipeline/Readdata/IDL_so_files/"
;; so_dir = !nika.pipeline_dir+"/Readdata/IDL_so_files/"
;; 
;; spawn, "mkdir -p " + so_dir
;; spawn, "mkdir -p " + compilation_dir
;; Spawn, 'rm -f '+so_dir+'*.so'
;; input_files = ["IDL_read_data","a_memoire","brut_to_data","kid_flag","rotation","bolo_unit","readdata"]
;; exported_routines = ["IDL_read_data","IDL_read_infos","IDL_read_start", "IDL_geo_bcast"]
;; make_dll,input_files,exported_routines,compile_directory=compilation_dir
;; Spawn, 'mv ' + compilation_dir + '*.so ' + so_dir
;; 
;; RETURN
;; END

if NOT keyword_set( compilation_dir) then begin
   ;compilation_dir = !nika.soft_dir+'/NIKA_lib/Readdata/C/'
   compilation_dir = !nika.pipeline_dir+'/Readdata/C/v1/'
endif

so_dir = !nika.pipeline_dir+"/Readdata/IDL_so_files/"

spawn, "mkdir -p " + so_dir
spawn, "mkdir -p " + compilation_dir
;; Spawn, 'rm -f '+so_dir+'*.so'
input_files = ["IDL_read_data","a_memoire","brut_to_data","bloc_comprime","rotation","readbloc","readdata"]
exported_routines = ["IDL_read_data","IDL_read_infos","IDL_read_start", "IDL_geo_bcast"]

;; make_dll,input_files,exported_routines,compile_directory=compilation_dir

;; NP, Apr. 15th : ported these new compilation flags from G. Dargaud
; You can find the directory for openmp with "locate libgomp.a"
;; make_dll,input_files,exported_routines,compile_directory=compilation_dir,EXTRA_CFLAGS="-O3 -march=native -fopenmp",EXTRA_LFLAGS="-flto -L/usr/lib/gcc/x86_64-linux-gnu/4.9 -lgomp"

make_dll,input_files,exported_routines,compile_directory=compilation_dir,EXTRA_CFLAGS="-O3 -march=native",EXTRA_LFLAGS="-flto"

;;cmd = 'mv ' + compilation_dir + '*.so ' + so_dir
cmd = 'mv ' + compilation_dir + 'IDL_read_data.so ' + so_dir+'IDL_read_data_v1.so'

print, cmd
;; Spawn, cmd

RETURN
END

