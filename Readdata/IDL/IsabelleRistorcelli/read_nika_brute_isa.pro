;+
; NAME:
;
;   read_nika_brute
;
; PURPOSE:
;  
;   Read nika data using the raw data files directly.
;
;
; CALLING SEQUENCE:
;
;   
;
; INPUTS:
;
;     file = file name
;
; OPTIONAL INPUTS:
;
;     list_data = liste of requested data names separated by spaces  
;     list_detector = liste of requested detectors  raw number  
;     read_type			if present, read only detctors with the given type
;     read_array		if present, read only detctors of the given array
;
;
; KEYWORD PARAMETERS:
;
;
; OUTPUTS:
;
;   param_c	:	structure with all common  parameters
;   kidpar	:	structure with all detecteurs  parameters
;   data	:	structure with all the requested data
;
;
; EXAMPLE:
;
;file      = "/Users/archeops/NIKA/Data/Y6_2013_01_25/Y_2013_01_25_11h27m00_0001_I"
;list_data = "sample  ofs_X  ofs_Y   I   Q  RF_didq  retard 49 "
;
;print, READ_NIKA_BRUTE( file,list_data,param_c,kidpar,data)

;
; Modification HISTORY:
;   Created by JFMP, dec 2010



;; Liste des variables possibles: ( dans  NIKA_lib/Acquisition/Readdata/name_list.h  )

;;#define _chaines_data_simple  {"sample","t_mac","synchro","sy_flag","sy_per","sy_pha","Bra_mpi",\
;;		"ofs_X","ofs_Y", "Paral", "Az","El", "MJD_int","MJD_dec","MJD_dec2","LST","Ra","Dec","t_elvin",\
;;		"ofs_Az", "ofs_El","ofs_Ra","ofs_Dec","ofs_Mx","ofs_My","MJD","rotazel", \
;;		"year","month","day","scan","subscan","scan_st","obs_st","size_x","size_y","nb_sbsc","step_y","speed","tau",\
;;		"antMJD_int","antMJD_dec","antLST","antxoffset","antyoffset","antAz","antEl",\
;;		"antMJDf_int","antMJDf_dec","antactualAz","antactualEl","anttrackAz","anttrackEl",\
;;		"map_tbm","map_t4k","map_pinj"}
;-

FUNCTION READ_NIKA_BRUTE_isa, file, param_c, kidpar, data, units, $
                              param_d = param_d, $
                              list_data=list_data, list_detector=list_detector,$
                              amp_modulation=amp_modulation, $
                              read_type=read_type, read_array=read_array, silent=silent
  

;-------------------   preparation de la liste des detecteurs en fonction des keywords  --------------------------------
nb_tot_samples = read_nika_isa( file, param_c, param_d, data, silent=1, no_data=1);, list_detector=list_detector)

if nb_tot_samples le 0 then goto, ciao

n_det = n_elements( param_d.(0))

if keyword_set(list_detector) then begin
   ;; do nothing else and read the requested list_detectors
endif else begin
   if keyword_set( read_type) then begin

      if read_type gt 99 then begin
         ;; read all kids then...
      endif else begin
         if read_type le 9 then begin
            type_list = read_type
         endif else begin
            t1 = long(read_type/10)
            t2 = read_type - 10*t1
            type_list = [t1, t2]
         endelse
         
         w = where(param_d.type eq type_list[0], nw)
         if nw ne 0 then keep = w else keep = [-1]
         if n_elements(type_list) eq 2 then begin
            w1 = where( param_d.type eq type_list[1], nw1)
            if nw1 ne 0 then keep = [keep, w1]
         endif
         if keep[0] ne -1 then begin
            list_detector = keep
            param_d       = param_d[keep]
            n_det         = n_elements(keep)
         endif else begin
            return, -1
         endelse 
      endelse
   endif

   if keyword_set( read_array) then begin
      if defined(list_detector) eq 0 then list_detector = lindgen( n_det)
      w = where( param_d.array eq read_array, nw)
      if nw eq 0 then begin
         message, /info, "No kid was found for array "+strtrim(read_array,2)
         message, /info, "Check your read_type and read_array parameters"
         stop
      endif else begin
         param_d       = param_d[w]
         list_detector = list_detector[w]
         n_det         = nw
      endelse
   endif
endelse ; list_detectors

;----------------------------------------   lecture  des data  ---------------------------------------------

nb_tot_samples = read_nika_isa( file, param_c, param_d, data, units,  $
                                list_data=list_data, list_detector=list_detector, $
                                silent=silent, buffer_header=buffer_header)
							
n_det = n_elements(list_detector)


;; ---------------------------      Create kidpar   et  ajoute toutes les varables necessaires			--------------------------------

strexc = "kidpar = create_struct('name', 'a'  "

;; Copy tous les param_d tags qui sont des valeurs numeriques (en sautant le "name" )
d_tags = tag_names( param_d)
nd_tags = n_elements( d_tags)
for i=0, nd_tags-1 do begin	
	if(d_tags[i] ne "NAME" ) then   strexc = strexc + ", '"+ d_tags[i]+"', 0L"
endfor

;; strexc = strexc + " , 'nas_x', 0.d0, 'nas_y', 0.d0, 'nas_center_x', 0.d0, 'nas_center_y', 0.d0, 'magnif', 0.d0, "+$
;;          "'calib', 0.d0, 'calib_fix_fwhm', 0.d0, 'atm_x_calib', 0.d0, 'fwhm', 0.d0, 'fwhm_x', 0.d0, 'fwhm_y', 0.d0, 'theta', 0.d0, "+$
;;          "'lambda', 0.d0, 'num_array', 0L, 'units', 'Jy/Beam', 's1', 0.d0, 's2', 0.d0, 'a_peak', 0.d0, 'tau0', 0.d0, 'el_source', 0.d0 " + ")"
strexc = strexc + " , 'nas_x', 0.d0, 'nas_y', 0.d0, 'nas_center_x', 0.d0, 'nas_center_y', 0.d0, 'magnif', 0.d0, "+$
         "'calib', 0.d0, 'calib_fix_fwhm', 0.d0, 'atm_x_calib', 0.d0, 'fwhm', 0.d0, 'fwhm_x', 0.d0, 'fwhm_y', 0.d0, 'theta', 0.d0, "+$
         "'lambda', 0.d0, 'num_array', 0L, 'units', 'Jy/Beam', 's1', 0.d0, 's2', 0.d0, 'a_peak', 0.d0, 'tau0', 0.d0, 'el_source', 0.d0, "+$
         "'nas_x_offset_ref', 0.d0, 'nas_y_offset_ref', 0.d0 "+ ")"
dummy = execute( strexc)

;; Replicate
kidpar = replicate( kidpar, n_det)

for i=0, nd_tags-1 do begin
   w = where( tag_names( kidpar) eq d_tags[i], nw)
   if nw eq 0 then begin
      print, "probleme"
      stop
   endif else begin
      kidpar.(w) = param_d.(i)
   endelse
endfor

;; RETURN, nb_tot_samples


;----------------------------------   a   verifier car ca ne marche plus     -------------------------------------
;;Get the amplitude of the modulation in case of the RUN 5
name_begin_file = strsplit(file,!nika.raw_acq_dir,/EXTRACT, /REGEX)
name_begin_file = strmid(name_begin_file, 3, 7)
if name_begin_file eq '2012_11' then amp_modulation = buffer_header[[158,158+806]]/2L^16*1e3 $
else amp_modulation = [-1,-1]


;	----------  Mise a jour de la frequence
!nika.f_sampling = 5d8/2.d0^19/param_c.div_kid

;	----------  Calcul du retard d'Elvin
dt_elvin = 2*1.d0/8. ; les 8Hz d'Elvin a partir du Run6
retard_elvin = round( dt_elvin*!nika.f_sampling)

retard_pointage = 0 ; default

if tag_exist( param_c, "ret_elv") then begin
   ;; This tag does not exist for run 5 and earlier.
   ;; Run5 works with retard_pointage = 0
   ;; If synchronization using MJD, ret_elv is -1 and no retard_pointage is
   ;; needed (already accounted for in the .c)

;;   if param_c.ret_elv ge 0 then begin
   ;; Changed condition "ge 0" into "ne 0" to work for RunCryo data (NP,
   ;; Nov. 14th, 2013)
   ;;if param_c.ret_elv ne 0 then begin
      
   ;; back to previous version after discussion with Alain, ret_elvin=-2 is a
   ;; code, it has nothing to do with a certain number of samples delay
   ;; Nico, Nov. 19th, 2013
   if param_c.ret_elv ge 0 then begin

      retard_pointage = retard_elvin - param_c.ret_elv

      var_list = [$
                 "ofs_X", "ofs_Y", "Paral", "Az", "El", "MJD_int", "MJD_dec", $
                 "LST", "Ra", "Dec", "t_elvin", "ofs_Az", "ofs_El", $
                 "ofs_Ra", "ofs_Dec", "MJD", "rotazel", "year", "month", "day", "scan", "subscan", "scan_st", "obs_st"]
      for i=0, n_elements(var_list)-1 do begin
         if tag_exist( data, var_list[i]) then begin
            ;;print, "shifting "+var_list[i]+" by "+strtrim(retard_pointage,2)
            cmd = "data."+var_list[i]+" = shift( data."+var_list[i]+", retard_pointage)"
            junk = execute(cmd)
         endif
      endfor
   endif
endif

;; Flag the first 48 samples in nika_pipe_getdata
shift_rf_dIdQ = -49
if tag_exist(data, 'RF_dIdQ') eq 1 then begin
   n_kid = n_elements(data[0].rf_didq)
   for ikid=0, n_kid-1 do data.RF_dIdQ[ikid,*] = shift(data.RF_dIdQ[ikid,*], shift_rf_dIdQ)
endif

;; Add fields to kidpar depending on the current Run
;; nika_upgrade_kidpar, kidpar
;; kidpar.f_tone = data[0].f_tone
nk_upgrade_kidpar, kidpar



data.a_t_utc = data.mjd*86400.d0
data.toi = data.rf_didq

ciao:
RETURN, nb_tot_samples
END
