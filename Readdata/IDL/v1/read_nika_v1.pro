;+
; NAME:
;
;   read_nika_v1
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
;
;
; KEYWORD PARAhMETERS:
;
;     list_data     = liste of requested data    : ascii names separated by spaces
;     list_detector = list of requested detector : vector of detector
;     number )
;     code_list_detector = indicates type of detector list to be read
;	  silent	:	no print during execution
;	  no_data :  read only paral_c and param_d
;
; OUTPUTS:
;
;   param_c	:	structure with all common  parameters
;   param_d	:	structure with all detecteurs  parameters for the requested detectors  ( to be done ?? )
;   data	:	structure with all the requested data
;	units	:	units of the data in the data structure
;	periode :	for the bolometers the trace of the response during one modulation period
;
; EXAMPLE:
;
;dir       = '/Users/macias/DataMatrice/'
;file      = "/Users/archeops/NIKA/Data/Y6_2013_01_25/Y_2013_01_25_11h27m00_0001_I"
;list_data = "sample  ofs_X  ofs_Y   I   Q  RF_didq  retard 49 "
;
;
; Modification HISTORY:
;   Created by JFMP, dec 2010

;; compilation_dir=compilation_dir

FUNCTION READ_NIKA_v1, file, param_c, param_d, data, units, periode, $
                       list_data=list_data, list_detector=list_detector, code_list_detector= code_list_detector, $
                       silent=silent, no_data=no_data, buffer_header=buffer_header, polar=polar, katana=katana

;message, /info, "in NIKA_lib"
;stop

t0 = systime(0,/sec)
  
if not keyword_set(list_data)           then list_data = "all"
if keyword_set(silent) then silent = long(silent) else silent= 0L
if keyword_set(no_data) then no_data = long(no_data) else no_data= 0L


; Test if the file exists
nb_tot_samples = 0
res = file_test( file)
if res ne 1 then begin
   print, 'not a valid file: '+ file
   goto, notafile
endif


t1 = systime(1)

;;compilation_dir = !nika.soft_dir+'/NIKA_lib/Readdata/IDL_so_files/'
compilation_dir = !nika.pipeline_dir+'/Readdata/IDL_so_files/'
libso = compilation_dir +'IDL_read_data_v1.so'

; ----------  les parametres du programme que l'on peut changer  
length_header = 600000L

login_info = get_login_info()
if login_info.machine_name eq 'bambini' then begin
   ;; FXD Too big for bambini length_bufferdata = 1000000000L
   length_bufferdata = 40000000L
endif else begin
   length_bufferdata = 1000000000L
endelse

; ---------- Call READSTART function first  ------------------------------
buffer_header = lonarr(length_header)
file_tmp = convert_toc_string(file)
list_data_tmp = convert_toc_string(list_data)
list_detector = lonarr(5001)
list_detector[0] = 5000L
;print,  "****************  call de  IDL_read_start   silent =  ",silent
;nb_tot_samples = call_external(libso,'IDL_read_start',file_tmp,list_data_tmp,length_header,buffer_header, silent)
; NEW VERSION ALAIN
nb_tot_samples = call_external(libso,'IDL_read_start',file_tmp,length_header,buffer_header,list_data_tmp,code_list_detector,list_detector,silent)

;print,  "****************  fin  call de  IDL_read_start  "

if nb_tot_samples le 0 then begin
   message, /info, 'problem with reading that file: '+ file
   goto, notafile
endif

; -----    read and write infos to buffer_header   -----

nb_boites_mesure = buffer_header[6]
nb_detecteurs = buffer_header[7]
nb_pt_bloc = buffer_header[8]
nb_sample_fichier = buffer_header[9]
nb_param_c = buffer_header[13]
nb_param_d = buffer_header[14]
nb_brut_periode =  buffer_header[18]
nb_data_communs = buffer_header[19]
nb_data_detecteurs = buffer_header[20]
nb_champ_reglage = buffer_header[21]

;if not keyword_set(list_detector) then list_detector = lindgen(nb_detecteurs)
;list_detector = long(list_detector) ; make sure that the input list had the correct format
;n_det = n_elements(list_detector)
n_det = list_detector[0]

;print ,"$$$$$$$$$$$$$$$$$$$$$ detect et detect lu" , nb_detecteurs,n_det

				; ---------- Call READ_INFOS  function  ------------------------------
nom_var_all = bytarr(16*(nb_param_c+nb_param_d+nb_data_communs*2+nb_data_detecteurs*2+nb_detecteurs))
idx_param_c = -1L
length_buffertemp = -1L
nb_char_nom = 0L

;print,  "****************  fin  call de  IDL_read_infos  "
dummy = call_external(libso,'IDL_read_infos',buffer_header, idx_param_c, length_buffertemp ,nom_var_all,nb_char_nom, silent)
;print,  "****************  fin  call de  IDL_read_infos  "

;-------  on recupere le nom des parametres et des data dans nom_var_all ----------
idxinit= 0
nom_param_c = nom_var_all[idxinit:idxinit+nb_char_nom*nb_param_c-1]
idxinit += nb_char_nom*nb_param_c
nom_param_d = nom_var_all[idxinit:idxinit+nb_char_nom*nb_param_d-1]
idxinit += nb_char_nom*nb_param_d
if (nb_data_communs gt 0) then begin
   nom_data_c = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_communs-1]
   idxinit += nb_char_nom*nb_data_communs
   unites_data_c = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_communs-1]
   idxinit += nb_char_nom*nb_data_communs
endif
if (nb_data_detecteurs gt 0) then begin
   nom_data_d = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_detecteurs-1]
   idxinit += nb_char_nom*nb_data_detecteurs
   unites_data_d = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_detecteurs-1]
   idxinit += nb_char_nom*nb_data_detecteurs
endif
; les noms de detecteurs sont toujours a 8 byte independament de la valeur de nb_char_nom
nom_detecteurs = nom_var_all[idxinit:idxinit+8 * nb_detecteurs-1]
idxinit += 8 * nb_detecteurs


 names_param_c = ['']
 for idx=0,nb_param_c-1 do names_param_c = [names_param_c, convert_fromc_string(nom_param_c[idx*nb_char_nom:*]) ]
 names_param_c = names_param_c[1:*]
; box parameters !
 eboxes = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T']
 box_par = ['fmod','f_mod','f_bin']

 keep_par_index = [0]
 for ie=0,n_elements(eboxes)-1 do begin
    for bpar=0,n_elements(box_par)-1 do begin
       for iparc = 0,nb_param_c-1 do begin
          if (strmatch(eboxes[ie]+'_'+box_par[bpar],names_param_c[iparc]) gt 0) then keep_par_index=[keep_par_index,iparc]
       endfor
    endfor
 endfor

 ; common parameters ??
 c_par = ['div_kid','ret_elv','retard']
 for icpar =0, N_elements(c_par)-1 do for iparc = 0,nb_param_c-1 do $
    if (strmatch(c_par[icpar],names_param_c[iparc]) gt 0) then keep_par_index=[keep_par_index,iparc]
 
 keep_par_index = keep_par_index[1:*]
 nb_keep_par_index = n_elements(keep_par_index)

strexc = 'param_c ={'
for idx=0,nb_keep_par_index-2 do strexc=strexc + convert_fromc_string(nom_param_c[keep_par_index[idx]*nb_char_nom:*]) +': long(0),'
strexc=strexc + convert_fromc_string(nom_param_c[keep_par_index[idx]*nb_char_nom:*]) +': long(0)'
strexc = strexc + '}'
dummy = execute(strexc)
nom_param_c_IDL = tag_names(param_c)
for idx=0,nb_keep_par_index-1 do param_c.(idx) = buffer_header[idx_param_c+keep_par_index[idx]]


;-----------     creation structure   PARAM_D  -----------------------
; d'abord une structure provisoire pp_d pour la lecture brut des param_d
; ensuite je change les types qui contiennet plusieurs donn??es compacte et je cree param_d

;; replace idx=0 by idx=0LL : Bug solved by Florian: 8*idx is out of "integer" bounds on NIKA2 with 8000
;; detectors !
strexc = "pp_d ={NAME:'a' "
for idx=2LL,nb_param_d-1 do strexc=strexc + ", "+convert_fromc_string(nom_param_d[idx*nb_char_nom:*]) +': 0L'
strexc = strexc + "}"
;print , strexc
dummy = execute(strexc)
pp_d = replicate( pp_d, nb_detecteurs)

for idx=0LL,nb_detecteurs-1 do pp_d[idx].name = convert_fromc_string( nom_detecteurs[idx*8:(idx+1)*8-1])
for idx=2LL,nb_param_d-1 do $
   pp_d.(idx-1) = reform(buffer_header[idx_param_c +nb_param_c +idx*nb_detecteurs:idx_param_c +nb_param_c+idx*nb_detecteurs+nb_detecteurs-1])

d_tags = tag_names( pp_d)
nd_tags = n_elements( d_tags)


strexc = "param_d = create_struct('RAW_NUM' , 0.d0 , 'NAME', 'a' , 'NUMDET' , 0.d0 "
for i=0, nd_tags-1 do begin
   p=0
   if strupcase( d_tags[i] eq "NAME") then p=1
   if strupcase( d_tags[i] eq "RES_FRQ") then begin
      strexc = strexc + ", 'res_frq', 0.d0"
      p=1
   endif
   if (p eq 0) and (strupcase( d_tags[i]) eq "RES_LG") then begin
      strexc = strexc+  ", 'res_lg', 0.d0 , 'k_flag', 0.d0 "
      p=1
   endif
   
   if (p eq 0) and (strupcase( d_tags[i]) eq "TYPE") then begin
      strexc = strexc+", 'type', 0.d0 , 'acqbox', 0.d0 , 'array', 0.d0 "
      p=1
   endif
   
   ; if tag not found, then create it
   if (p eq 0) then begin
      strexc = strexc+", '"+ d_tags[i]+"' , 0.d0 "
   endif
endfor
strexc = strexc + ")"
;print , strexc
dummy = execute( strexc)

;; Replicate
param_d = replicate( param_d, n_det)


; boucle sur les tags de ppd
for i=0, nd_tags-1 do begin
   p=0
   if strupcase( d_tags[i] eq "RES_FRQ") then begin
      param_d.res_frq = pp_d(list_detector[1:n_det]).res_frq * 10.d0
      p=1
   endif
   if (p eq 0) and (strupcase( d_tags[i]) eq "RES_LG") then begin
      param_d.k_flag = pp_d(list_detector[1:n_det]).res_lg/2L^24
      param_d.res_lg = pp_d(list_detector[1:n_det]).res_lg mod 2L^24
      p=1
   endif

   if (p eq 0) and (strupcase( d_tags[i]) eq "TYPE") then begin
      param_d.acqbox = (pp_d(list_detector[1:n_det]).type/65536) mod 256
      param_d.array = pp_d(list_detector[1:n_det]).type/(65536*256)
;      param_d.type = pp_d(list_detector).type mod 65536
; changement le 25 aout par A. Benoit pour ne pas lire les bit permettant de masquer un kid lors de l'acquisition
      param_d.type = pp_d(list_detector[1:n_det]).type mod 256
      p=1
   endif

   if (p eq 0 ) then begin
      w = where( tag_names( param_d) eq d_tags[i], nw)
      if nw eq 0 then begin
         print, "probleme"
         stop
      endif else begin
         param_d.(w) = pp_d(list_detector[1:n_det]).(i)
      endelse
   endif
endfor

;---------------   calcule  raw_num et NUMDET
param_d.raw_num = list_detector[1:n_det]
for ikid=0, n_det-1 do begin
   if (param_d[ikid].type eq 1) then begin
      name = param_d[ikid].name
      l = strlen( name)
      str_numdet = strmid(name,l-1) ; init
      for i=l-2, 0, -1 do begin
         char = strmid(name,i,1)
         if  (byte(char) ge 48) and (byte(char) le 57) then begin
            str_numdet = char+str_numdet
         endif
      endfor
      param_d[ikid].numdet = long( str_numdet)
   endif
endfor


;----------------------------------------------------------------------------
if (no_data gt 0) then goto , notafile
;----------------------------------------------------------------------------


;   ---------------     creation structure    DATA DCOMMUNS + DETECTEURS    ---------------------------
strexc = 'data ={'
if (nb_data_communs gt 0) then begin
   for idx=0,nb_data_communs-1 do begin
      if not keyword_set(silent) then print, 'dcommuns pb : '+ convert_fromc_string(nom_data_c[idx*nb_char_nom:*])
;;      strexc=strexc + convert_fromc_string(nom_data_c[idx*nb_char_nom:*]) +': 0.d0,'
      mytag = strtrim( strupcase(convert_fromc_string(nom_data_c[idx*nb_char_nom:*])), 2)
      if strmid(mytag,2) eq "POSITION" then mytag = "POSITION"
      if strmid(mytag,2) eq "SYNCHRO"  then mytag = "SYNCHRO"
      strexc=strexc + mytag +': 0.d0,'
   endfor
endif

if (nb_data_detecteurs gt 0) then begin
   for idx=0, nb_data_detecteurs-1 do begin
      mytag = strtrim( strupcase(convert_fromc_string(nom_data_d[idx*nb_char_nom:*])), 2)
      ;; RF_DIDQ is not read anymore to save time when we work in PF. If
      ;; param.math='RF', then rf_didq is computed in
      ;; nk_data_conventions.pro
      ;; Aug. 4th 2016, NP
      
      ;; Put it back, at least temporarily for data cross checks, NP,
      ;; Sept. 19th, 2016
      if mytag eq "RF_DIDQ"  then mytag = "TOI"
      strexc = strexc + mytag + ':dblarr('+ strtrim(n_det,2)+'), '

   endfor
endif

;;----------------------------------
;; Add extra fields required by the pipeline
;; here to avoid data duplication in nk_update_fields and save memory
;; NP, Feb. 15th and Apr. 15th, 2016                                                                                                       
;; a_t_utc does not exist for run5 => create it
if strupcase( strtrim(!nika.run,2)) eq "CRYO" or $
   strupcase( strtrim( !nika.run,2)) eq '5' then strexc = strexc + "a_t_utc:0.d0, "

;; to enable a new decorrelation method
strexc = strexc + "elev_offset:0.d0, "

;; Added 'toi' now that rf_didq is commented out, NP Aug 4th 2016.
;; comment it out to read rf_dida from the raw data again fro cross
;; checks, NP. Sept. 19th, 2016
strexc = strexc + $
         ;;   "toi:dblarr("+strtrim(n_det,2)+"), "+$ 
         "dra:dblarr("+strtrim(n_det,2)+"), "+$
         "ddec:dblarr("+strtrim(n_det,2)+"), "+$
         "w8:dblarr("+strtrim(n_det,2)+"), "+$
         "flag:lonarr("+strtrim(n_det,2)+"), "+$
         "off_source:dblarr("+strtrim(n_det,2)+")+1, "+$
         "ipix:dblarr("+strtrim(n_det,2)+")-1, "+$
         "nsotto:intarr(3), "+$
         "fpga_change_frequence:0, "+$
         "balayage_en_cours:0, "+$
         "blanking_synthe:0, "+$
         "modulation:0, "+$
         "tuning_en_cours:0"

;print, strexc
;stop
;; Add rf_pIpQ if needed
for idx=0, nb_data_detecteurs-1 do begin
   mytag = strtrim( strupcase(convert_fromc_string(nom_data_d[idx*nb_char_nom:*])), 2)
   if mytag eq "PI" then strexc = strexc + ", RF_PIPQ" + ':dblarr('+ strtrim(n_det,2)+')'
endfor
;print, strexc
;stop

if keyword_set(katana) then $
   strexc = strexc + ", ipix_nasmyth:0.d0, ipix_azel:0.d0, ofs_nasx:0.d0, ofs_nasy:0.d0"

if keyword_set(polar) then $
   strexc = strexc + ", "+$
            "toi_q:dblarr("+strtrim(n_det,2)+"), "+$
            "toi_u:dblarr("+strtrim(n_det,2)+"), "+$
            "w8_q:dblarr("+strtrim(n_det,2)+"), "+$
            "w8_u:dblarr("+strtrim(n_det,2)+"), "+$
            "cospolar:0.d0, sinpolar:0.d0"

;;-------------------------------------
strexc = strexc + ', scan_valid:intarr('+strtrim(nb_boites_mesure,2)+')}'
dummy = execute(strexc)

data = replicate(data,nb_tot_samples)

; Unites COMMUNS + DETECTEURS
strexc = 'units ={'
if (nb_data_communs gt 0) then begin
   for idx=0,nb_data_communs-1 do begin
      if not keyword_set(silent) then print, convert_fromc_string(nom_data_c[idx*nb_char_nom:*])
      strexc=strexc + convert_fromc_string(nom_data_c[idx*nb_char_nom:*]) +": '"+convert_fromc_string( unites_data_c[idx*nb_char_nom:*])+"',"
   endfor
endif

if (nb_data_detecteurs gt 0) then for idx=0, nb_data_detecteurs-1 do $
   strexc=strexc + convert_fromc_string(nom_data_d[idx*nb_char_nom:*]) + ": '"+convert_fromc_string( unites_data_d[idx*nb_char_nom:*])+"',"
;; remove ending comma:
l = strlen(strexc)
strexc = strmid( strexc,0,l-1)
; execute
strexc = strexc + '}'
if not keyword_set(silent) then print, "strexc = "+strexc
dummy = execute(strexc)


;   ---------------     creation buffer  PERIODE  pour les bolos     ---------------------------
periode = lonarr(nb_brut_periode,n_det,nb_tot_samples/nb_pt_bloc)


;------------------   preparation des buffer de lecture pour IDL_read_data  -----------
; le bufferdata sert a ranger les donnes lues dans le fichier
; le buffertemp est utilise par brut_to_data comme memoire de calcul


length_data_per_sample = nb_data_communs + nb_data_detecteurs*n_det

maxsample = length_bufferdata / length_data_per_sample
length_bufferperiode = (2 + maxsample/nb_pt_bloc) * nb_brut_periode*n_det

; REDEFINITION AFTERWARDS
bufferdata = dblarr(length_bufferdata)
buffertemp =  bytarr(length_buffertemp)
bufferdataperiode =  lonarr(length_bufferperiode)

if not keyword_set(silent) then print, "Lecture data : Buffer data : ", length_bufferdata*8/1000 , " kbyte "
if not keyword_set(silent) then print, "               Buffer temp : ",length_buffertemp/1000," kbyte "
if not keyword_set(silent) then print, "               lecture maxi  ",length_bufferdata/length_data_per_sample ," sample"

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; ---------- Loop  with  Call   IDL_read_data  ------------------------------
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

nb_samples_lu = 1L
nb_sample_total = 0L
nb_bloc_total = 0L
isample = 0
indiceboucle=0                  ;
buffertemp[0] = 1               ; pour demander une initialisation des tableaux temporaires de brut_to_data

;
;;print , "YYY", n_det,"liste : ", list_detector


while (nb_samples_lu gt 0) do begin

		;print ,"************  nb_samples_lu=", nb_samples_lu , "APPEL IDL_read_data"
;   nb_samples_lu = call_external(libso,'IDL_read_data',file_tmp,buffer_header,n_det,list_detector,length_bufferdata,bufferdata,bufferdataperiode,buffertemp, silent)
; NEW VERSION ALAIN
   	nb_samples_lu = call_external(libso,'IDL_read_data',file_tmp,buffer_header,list_detector,length_bufferdata,bufferdata,bufferdataperiode,buffertemp, silent)
		;print ,"****************apres call : nb_samples_lu=", nb_samples_lu

		if (nb_samples_lu gt 0) then begin
			indiceboucle += 1
			nb_bloc_lu = nb_samples_lu/nb_pt_bloc
			if not keyword_set(silent) then print, "bloc",indiceboucle,"  :  sample lu=",nb_samples_lu,nb_sample_total
                               ;--------------  extract data from bufferdata  to IDL structures
				bufferdata = reform(bufferdata[0L:length_data_per_sample*nb_samples_lu-1l],length_data_per_sample,nb_samples_lu)

			;; Convertit les undef d'Alain en IDL(NAN)
			w = where( bufferdata eq -32768.5, nw)
			if nw ne 0 then begin
				if not keyword_set( silent) then print, "undef double found ", nw
				bufferdata[w] = !values.d_nan
			endif
			w = where( bufferdata eq 2147483647, nw)
			if nw ne 0 then begin
				if not keyword_set( silent) then print, "undef int4 found ", nw
				bufferdata[w] = !values.d_nan
			endif



;	----------  les  data  communs  -----------------
                        if isample+nb_samples_lu gt nb_tot_samples or isample lt 0 then begin
                           nb_tot_samples = 0
                           if not keyword_set( silent) then message, 'Corrupted file '+file
                           goto, notafile
                        endif else begin
                           if not keyword_set( silent) then $
                              print, 'There ?', isample, isample+nb_samples_lu,  nb_tot_samples-1
                        endelse


			for idx=0,nb_data_communs-1 do data[isample:isample+nb_samples_lu-1].(idx) = reform(bufferdata[idx,*],nb_samples_lu)
      
;	----------  les  data  detecteurs  -----------------
			for idx=0,nb_data_detecteurs-1 do begin
				;data[isample:isample+nb_samples_lu-1].(idx+nb_data_communs) = $
				;	(bufferdata[nb_data_communs+idx*n_det: nb_data_communs+idx*n_det+n_det-1,*])[wkeep,*]
				data[isample:isample+nb_samples_lu-1].(idx+nb_data_communs) = $
					(bufferdata[nb_data_communs+idx*n_det: nb_data_communs+idx*n_det+n_det-1,*])
			endfor

;	----------  les  data  periode  (pour les bolometres  uniquement   -----------------
			bufferdataperiode = bufferdataperiode - (bufferdataperiode/32768) * 32768  - 16384
			periode(*,*,nb_bloc_total:nb_bloc_total+nb_bloc_lu-1)  = reform(bufferdataperiode[0:nb_bloc_lu*n_det*nb_brut_periode-1],nb_brut_periode,n_det,nb_bloc_lu)

			isample += nb_samples_lu
			nb_sample_total += nb_samples_lu
			nb_bloc_total += nb_bloc_lu
		endif

endwhile 

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------



notafile: 

RETURN, nb_tot_samples
END
