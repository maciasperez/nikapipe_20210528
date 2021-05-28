
pro nika_init_path, minimal = minimal, nojpb = nojpb, no_set_plot_x=no_set_plot_x

if not keyword_set(no_set_plot_x) then no_set_plot_x = 0
  
if not keyword_set( nojpb) then begin 
;; JPB lib
   defsysv, '!jpblib_dir', !nika.soft_dir+"/idl-libs/JPBlib"
   !PATH = !PATH + !psep + EXPAND_PATH('+'+!jpblib_dir)
   defsysv, '!jpblib_version', '1.4'
   defsysv, '!indef',-32768.
   defsysv,'!jpblib_example_dir',!jpblib_dir+!sep+'Examples'+!sep
   defsysv,'!jpblib_issa_dir',!jpblib_dir+!sep+'ISSA'+!sep
   defsysv,'!jpblib_help_dir',!jpblib_dir+!sep+'Help'+!sep+'Html'+!sep
   jpblib_init
endif

;; Common
defsysv, "!commonsoft_dir", !nika.soft_dir+"/idl-libs/Common"
!PATH = !PATH + !psep + EXPAND_PATH('+'+!commonsoft_dir)

;; NIKA
;;!PATH = !PATH + !psep + EXPAND_PATH('+'+!nika.soft_dir+"/NIKA_lib")

;; Coyote
!path=!path+':'+ EXPAND_PATH('+'+!nika.soft_dir+"/idl-libs/coyote")

;; NP_lib
defsysv, "!np_lib", !nika.soft_dir+"/idl-libs/NP_lib"
!path = !path+':'+ EXPAND_PATH('+'+!np_lib+"/IDL")
np_lib_init

;; AClib
defsysv, "!ac_lib", !nika.soft_dir+"/idl-libs/AClib"
!path = !path+':'+ EXPAND_PATH('+'+!ac_lib)

;; POKER (some simulation routines are in there)
defsysv, "!poker", !nika.soft_dir+"/idl-libs/Poker"
!path = !path + !psep + expand_path("+"+!poker+"/IDL")
poker_init

;; Fastphot
!path = !path+':'+ EXPAND_PATH('+'+!nika.soft_dir+"/idl-libs/Fastphot")

;; SourceDetection
!path = !path+':'+ EXPAND_PATH('+'+!nika.soft_dir+"/idl-libs/SourceDetection")

;; PARALLEL LIB and STRUCTURE LIB
defsysv, "!parallel_lib", !nika.soft_dir+"/idl-libs/parallellib"
!path = !path+':'+ EXPAND_PATH('+'+!parallel_lib)

defsysv, "!jmstruct_lib", !nika.soft_dir+"/idl-libs/structlib"
!path = !path+':'+ EXPAND_PATH('+'+!jmstruct_lib)

;; Archeops
;!PATH = !PATH + !psep + EXPAND_PATH('+'+!nika.soft_dir+"/idl-libs/Archeops")

;HEALPIX
;-------
defsysv, "!HEALPIX_DIR", !nika.soft_dir+"/idl-libs/Healpix"
!PATH = !PATH + !psep+ EXPAND_PATH('+'+!HEALPIX_DIR)
; check that init_healpix is accessible
pathtab = expand_path(!path,/array)
junk = file_search(pathtab+path_sep()+'init_healpix.pro', count=count)
if (count gt 0) then begin $
   init_healpix & $
   print,'Healpix version: '+!healpix.version & $
endif else begin $
   print,'!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' & $
   print,'!  WARNING: the Healpix routines are currently NOT found  !' & $
   print,'!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' & $
endelse

;; ASTRON
; Some fits routines must be taken in !HEALPIX_DIR/src/idl/zzz_external/astron
; this is why I split !astron_dir
!PATH = !PATH + !psep+ EXPAND_PATH('+'+!healpix_dir+'/src/idl/zzz_external/astron')
!PATH = !PATH + !psep+ EXPAND_PATH('+'+!nika.soft_dir+"/idl-libs/Astron_dec2010")

;IF ((!D.NAME EQ 'X') OR (!D.NAME EQ 'WIN')) THEN DEVICE, RETAIN=2

;; JHUAPL
DEFSYSV, '!JHUAPL_DIR', !nika.soft_dir+"/idl-libs/jhuapl"
!PATH = !PATH + !psep+ EXPAND_PATH('+'+!JHUAPL_DIR)

;; ICE
defsysv,'!ICE_DIR',!nika.soft_dir+"/idl-libs/ice"
COMMON SESSION_PARAMS, SITE, VERSION, PROJECT, USER, node
COMMON SESSION_BLOCK, SESSION_MODE, ERROR_CURRENT, STATUS_BOOL
!path = !path + !psep+ EXPAND_PATH("+"+!ICE_DIR) 
SET_LOGFILE, /noerror, /nosession, /nomaster
PRINT,"ICE Software now available"

if not keyword_set(minimal) then begin
;;;;------------------
;;;; For Alain
;;;;   no_set_plot_x = 1
;;;;------------------

;; MAMD (put it before bolored to bypass ps.pro)
   DEFSYSV, '!MAMDLIB_DIR', !nika.soft_dir+"/idl-libs/mamdlib"
   !path=!path+':'+ EXPAND_PATH('+'+!MAMDLIB_DIR)
   mamdlib_init, 39, no_set_plot_x=no_set_plot_x
   if no_set_plot_x ne 1 then wd
endif

;; Bolored
!PATH = !PATH + !psep + EXPAND_PATH('+'+!nika.soft_dir+"/idl-libs/Diabolo/Bolored")

;; Open Pool 3 reduction scripts
!PATH = !PATH + !psep + EXPAND_PATH('+'+!nika.pipeline_dir+"/Scr/Openpool3")

;; Markwardtlib
!path=!path+':'+ EXPAND_PATH('+'+!nika.soft_dir+"/idl-libs/Markwardt")

;; Spice
!path=!path+':'+ EXPAND_PATH('+'+!nika.soft_dir+"/idl-libs/PolSpice-v02-04-00")

;; Scanamorphos
!PATH = !path+":"+expand_path("+"+!nika.soft_dir+"/idl-libs/SCANAMORPHOS")


!nika.new_find_data_method=1

end
