;+
; NAME:
;
;   read_nika_v2
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
; KEYWORD PARAMETERS:
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

FUNCTION READ_NIKA_v2, file, param_c, param_d, data, units, $ ;periode, $
                    list_data=list_data, list_detector=list_detector, $
                    silent=silent, no_data=no_data, buffer_header=buffer_header, $
                    code_list_detector=code_list_detector, katana=katana, polar=polar

;message, /info, "in NIKA_lib"
;stop

if not keyword_set(code_list_detector) then code_list_detector = 2L
if not keyword_set(list_data)           then list_data = "all"
if keyword_set(silent) then silent = long(silent) else silent= 0L
if keyword_set(no_data) then no_data = long(no_data) else no_data= 0L

;print , "silent" , silent
;stop


; Test if the file exists
nb_tot_samples = 0
res = file_test( file)
if res ne 1 then begin
   print, 'not a valid file: '+ file
   goto, notafile
endif


;; compilation_dir = '/home/nika2/NIKA/Processing/NIKA_lib_AB_OB_gui/Readdata/C/'
;; libso = compilation_dir + 'libreadnikadata.so'
compilation_dir = !nika.pipeline_dir+"/Readdata/IDL_so_files/"
libso = compilation_dir + "IDL_read_data_v2.so"

; ----------  les parametres du programme que l'on peut changer  
length_header = 300000L

; ---------- Call READSTART function first  ------------------------------
buffer_header = lonarr(length_header)
file_tmp = convert_toc_string(file)
list_data_tmp = convert_toc_string(list_data)

;; must be longer than list_data_tmp: initialising, will be
;; overwritten by Alain
;; list_data = convert_toc_string('all')

;; Allocate 8000, NP+AB, Feb. 12th, 2018
list_detector    = lonarr(8001)
list_detector[0] = 8000L

;;NP+AB+OB, Feb. 12th, 2018
nb_char_nom     = 16L
var_name_length = 200000L
nom_var_all     = bytarr(var_name_length)
;; list_data       = convert_toc_string('all')
;list_data       = convert_toc_string('common I Q dI dQ ')
idx_param_c     = -1L
idx_param_d     = -1L

;silent=1
;silent=0
nb_read_samples = call_external( libso, 'IDL_read_infos', file_tmp, buffer_header, $
                                 length_header, nom_var_all, var_name_length, $
                                 list_data_tmp, code_list_detector, list_detector, idx_param_c, $
                                 idx_param_d, silent)

; -----    read and write infos to buffer_header   -----

nb_boites_mesure        = buffer_header[6]
nb_detecteurs           = buffer_header[7]
nb_pt_bloc              = buffer_header[8]
nb_sample_fichier       = buffer_header[9]
nb_param_c              = buffer_header[13]
nb_param_d              = buffer_header[14]
size_motor_module_table = buffer_header[4]
nb_data_communs         = buffer_header[19]
nb_data_detecteurs      = buffer_header[20]
nb_champ_reglage        = buffer_header[21]


n_det = list_detector[0]

;message, /info, "fix me:"
;n_det = 8000
;stop

;print ,"$$$$$$$$$$$$$$$$$$$$$ detect et detect lu" , nb_detecteurs,n_det

;-------  on recupere le nom des parametres et des data dans nom_var_all ----------
idxinit= 0
nom_param_c = nom_var_all[idxinit:idxinit+nb_char_nom*nb_param_c-1]
idxinit += nb_char_nom*nb_param_c
nom_param_d = nom_var_all[idxinit:idxinit+nb_char_nom*nb_param_d-1]
idxinit += nb_char_nom*nb_param_d
if (nb_data_communs gt 0) then begin
   nom_data_c = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_communs-1]
   idxinit += nb_char_nom*nb_data_communs
                                ;unites_data_c = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_communs-1]
                                ;idxinit += nb_char_nom*nb_data_communs
endif
if (nb_data_detecteurs gt 0) then begin
   nom_data_d = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_detecteurs-1]
   idxinit += nb_char_nom*nb_data_detecteurs
                                ;unites_data_d = nom_var_all[idxinit:idxinit+nb_char_nom*nb_data_detecteurs-1]
                                ;idxinit += nb_char_nom*nb_data_detecteurs
endif
; les noms de detecteurs sont toujours sur 16 bytes maintenant =
; nb_char_nom (Feb. 2018)
nom_detecteurs = nom_var_all[idxinit:idxinit+nb_char_nom * nb_detecteurs-1]
;idxinit += 8 * nb_detecteurs
idxinit += nb_char_nom * nb_detecteurs

;for idx=0,20 do print , convert_fromc_string(nom_detecteurs[8*idx:8*idx+7])

;-----------     creation structure   PARAM_C   ------------------------
;strexc = 'param_c ={'
;for idx=0,nb_param_c-2 do strexc=strexc + convert_fromc_string(nom_param_c[idx*nb_char_nom:*]) +': long(0),'
;strexc=strexc + convert_fromc_string(nom_param_c[idx*nb_char_nom:*]) +': long(0)'
;strexc = strexc + '}'
;dummy = execute(strexc)
;nom_param_c_IDL = tag_names(param_c)

;for idx=0,nb_param_c-1 do param_c.(idx) = buffer_header[idx_param_c+idx]

; COPIE FROM MARS 2016 version of param C
names_param_c = ['']
for idx=0,nb_param_c-1 do names_param_c = [names_param_c, convert_fromc_string(nom_param_c[idx*nb_char_nom:*]) ]
names_param_c = names_param_c[1:*]

;; print, names_param_c

; box parameters !
eboxes = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U']
box_par = ['fmod','f_mod','f_bin']

keep_par_index = [0]
for ie=0,n_elements(eboxes)-1 do begin
   for bpar=0,n_elements(box_par)-1 do begin
      for iparc = 0,nb_param_c-1 do begin
         if (strmatch(eboxes[ie]+'_'+box_par[bpar],names_param_c[iparc]) gt 0) then keep_par_index=[keep_par_index,iparc]
      endfor
   endfor
endfor

;; common parameters
;; c_par = ['div_kid','ret_elv','retard']
c_par = ['div_kid','retard','data_dIdQ', 'data_pIpQ', '1-modulFreq', '2-modulFreq', '3-modulFreq']
;for i=0, n_elements(names_param_c)-1 do print, names_param_c[i]
;stop
for icpar =0, N_elements(c_par)-1 do for iparc = 0,nb_param_c-1 do $
   if (strmatch(c_par[icpar],names_param_c[iparc]) gt 0) then keep_par_index=[keep_par_index,iparc]

keep_par_index = keep_par_index[1:*]
nb_keep_par_index = n_elements(keep_par_index)
;; IDL does not accept structure tags starting with a digit: need to
;; rename them:
idl_name_param_c = strarr( nb_keep_par_index)
for idx=0, nb_keep_par_index-1 do begin
   c_name = convert_fromc_string(nom_param_c[keep_par_index[idx]*nb_char_nom:*])
   ;; remove "."
   c_name = str_replace( c_name, "\.", "_", /global)
   ;; remove "-"
   c_name = str_replace( c_name, "-", "_", /global)

   if strmid( c_name, 0, 1) eq '1' or $
      strmid( c_name, 0, 1) eq '2' or $
      strmid( c_name, 0, 1) eq '3' then begin
      idl_name_param_c[idx] = "Array"+c_name
   endif else begin
      idl_name_param_c[idx] = c_name
   endelse
endfor
;; print, idl_name_param_c

strexc = 'param_c ={'
;; for idx=0,nb_keep_par_index-2 do strexc=strexc + convert_fromc_string(nom_param_c[keep_par_index[idx]*nb_char_nom:*]) +': long(0),'
;; strexc=strexc + convert_fromc_string(nom_param_c[keep_par_index[idx]*nb_char_nom:*]) +': long(0)'
;; strexc = strexc + '}'
for idx=0, nb_keep_par_index-2 do strexc = strexc + idl_name_param_c[idx] +': long(0),'
strexc = strexc + idl_name_param_c[idx] +': long(0)}'
dummy = execute(strexc)
;print, "ok"
;stop

nom_param_c_IDL = tag_names(param_c)
for idx=0,nb_keep_par_index-1 do param_c.(idx) = buffer_header[idx_param_c+keep_par_index[idx]]

;-----------     creation structure   PARAM_D  -----------------------
; d'abord une structure provisoire pp_d pour la lecture brut des param_d
strexc = "pp_d ={NAME:'a' "
for idx=2,nb_param_d-1 do strexc=strexc + ", "+convert_fromc_string(nom_param_d[idx*nb_char_nom:*]) +': 0L'
strexc = strexc + "}"
;print , strexc
dummy = execute(strexc)


pp_d = replicate( pp_d, nb_detecteurs)
for idx=0,nb_detecteurs-1 do pp_d[idx].name = convert_fromc_string( nom_detecteurs[idx*nb_char_nom:(idx+1)*nb_char_nom-1])
for idx=2,nb_param_d-1 do $
   pp_d.(idx-1) = reform(buffer_header[idx_param_d +idx*nb_detecteurs : idx_param_d +idx*nb_detecteurs+nb_detecteurs-1])



d_tags = tag_names( pp_d)
nd_tags = n_elements( d_tags)

;print, d_tags

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
   
   if (p eq 0) and (strupcase( d_tags[i]) eq "TYPEDET") then begin
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
   if strupcase( d_tags[i] eq "NAME") then begin
      param_d.name = pp_d(0:n_det-1).name
      p=1
   endif
   
   if strupcase( d_tags[i] eq "RES_FRQ") then begin
      param_d.res_frq = pp_d(list_detector[1:n_det]).res_frq * 10.d0
      p=1
   endif
   if (p eq 0) and (strupcase( d_tags[i]) eq "RES_LG") then begin
      param_d.k_flag = pp_d(list_detector[1:n_det]).res_lg/2L^24
      param_d.res_lg = pp_d(list_detector[1:n_det]).res_lg mod 2L^24
      p=1
   endif

   if (p eq 0) and (strupcase( d_tags[i]) eq "TYPEDET") then begin
      param_d.acqbox = (pp_d(list_detector[1:n_det]).typedet/65536) mod 256
      param_d.array = pp_d(list_detector[1:n_det]).typedet/(65536*256)
; changement le 25 aout par A. Benoit pour ne pas lire les bit permettant de masquer un kid lors de l'acquisition
      param_d.type = pp_d(list_detector[1:n_det]).typedet mod 256
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

;stop


;---------------   calcu  raw_num et NUMDET
param_d.raw_num = list_detector[1:n_det]

for ikid=0, n_det-1 do begin
   if (param_d[ikid].type eq 1) then begin
;   if (param_d[ikid].typedet eq 1) then begin
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
      if not keyword_set(silent) then print, 'dcommuns box parameter : '+ convert_fromc_string(nom_data_c[idx*nb_char_nom:*])
;;      strexc=strexc + convert_fromc_string(nom_data_c[idx*nb_char_nom:*]) +': 0.d0,'
      mytag = strtrim( strupcase(convert_fromc_string(nom_data_c[idx*nb_char_nom:*])), 2)
      print, convert_fromc_string(nom_data_c[idx*nb_char_nom:*])
      if strmid(mytag,2) eq "POSITION" then mytag = "POSITION"
      if strmid(mytag,2) eq "SYNCHRO"  then mytag = "SYNCHRO"

      if mytag eq "OFS_X" then mytag = "OFS_AZ"
      if mytag eq "OFS_Y" then mytag = "OFS_EL"

      strexc=strexc + mytag +': 0.d0,'
   endfor
endif


if (nb_data_detecteurs gt 0) then begin
   for idx=0, nb_data_detecteurs-1 do begin
      mytag = strtrim( strupcase(convert_fromc_string(nom_data_d[idx*nb_char_nom:*])), 2)

      if mytag eq "RF_DIDQ"  then mytag = "TOI"

      strexc = strexc + mytag + ':dblarr('+ strtrim(n_det,2)+'), '
   endfor
endif
;print, strexc


;;----------------------------------
;; Add extra fields required by the pipeline
;; here to avoid data duplication in nk_update_fields and save memory
;;
;; Need a_t_utc for the pipeline but it does not exist anymore in
;; !nika.acq_version=v2
strexc = strexc + "A_T_UTC:0.d0, elev_offset:0.d0, "

strexc = strexc + $
         "dra:dblarr("+strtrim(n_det,2)+"), "+$
         "ddec:dblarr("+strtrim(n_det,2)+"), "+$
         "w8:dblarr("+strtrim(n_det,2)+"), "+$
         "flag:lonarr("+strtrim(n_det,2)+"), "+$
         "off_source:dblarr("+strtrim(n_det,2)+")+1, "+$
         "ipix:dblarr("+strtrim(n_det,2)+")-1, "+$
         "snr:dblarr("+strtrim(n_det,2)+")+1, "+$
         "nsotto:intarr(3), "+$
         "fpga_change_frequence:0, "+$
         "balayage_en_cours:0, "+$
         "blanking_synthe:0, "+$
         "modulation:0, "+$
         "tuning_en_cours:0"

;; Add rf_pIpQ if needed
for idx=0, nb_data_detecteurs-1 do begin
   mytag = strtrim( strupcase(convert_fromc_string(nom_data_d[idx*nb_char_nom:*])), 2)
   if mytag eq "PI" then strexc = strexc + ", RF_PIPQ" + ':dblarr('+ strtrim(n_det,2)+')'
endfor

if keyword_set(katana) then $
   strexc = strexc + ", ipix_nasmyth:0.d0, ipix_azel:0.d0, ofs_nasx:0.d0, ofs_nasy:0.d0"

if keyword_set(polar) then $
   strexc = strexc + ", "+$
            "toi_q:dblarr("+strtrim(n_det,2)+"), "+$
            "toi_u:dblarr("+strtrim(n_det,2)+"), "+$
            "w8_q:dblarr("+strtrim(n_det,2)+"), "+$
            "w8_u:dblarr("+strtrim(n_det,2)+"), "+$
            "cospolar:0.d0, sinpolar:0.d0"

;;;; remove ending comma:
;;l = strlen(strexc)
;;strexc = strmid( strexc,0,l-1)
strexc = strexc + ', scan_valid:intarr('+strtrim(nb_boites_mesure,2)+')}'
dummy = execute(strexc)

;stop


;; ; Unites COMMUNS + DETECTEURS
;; strexc = 'units ={'
;; if (nb_data_communs gt 0) then begin
;;    for idx=0,nb_data_communs-1 do begin
;;       if not keyword_set(silent) then print, convert_fromc_string(nom_data_c[idx*nb_char_nom:*])
;;       strexc=strexc + convert_fromc_string(nom_data_c[idx*nb_char_nom:*]) +": '"+convert_fromc_string( unites_data_c[idx*nb_char_nom:*])+"',"
;;    endfor
;; endif
;; 
;; if (nb_data_detecteurs gt 0) then for idx=0, nb_data_detecteurs-1 do $
;;    strexc=strexc + convert_fromc_string(nom_data_d[idx*nb_char_nom:*]) + ": '"+convert_fromc_string( unites_data_d[idx*nb_char_nom:*])+"',"
;; ;; remove ending comma:
;; l = strlen(strexc)
;; strexc = strmid( strexc,0,l-1)
;; ; execute
;; strexc = strexc + '}'
;; if not keyword_set(silent) then print, "strexc = "+strexc
;; dummy = execute(strexc)


;   ---------------     creation buffer  PERIODE  pour les bolos     ---------------------------
; useless now (Feb. 9th, 2018)
;periode = lonarr(nb_brut_periode,n_det,nb_tot_samples/nb_pt_bloc)


;------------------   preparation des buffer de lecture pour IDL_read_data  -----------
; le bufferdata sert a ranger les donnes lues dans le fichier
; le buffertemp est utilise par brut_to_data comme memoire de calcul


length_data_per_sample = nb_data_communs + nb_data_detecteurs*n_det


;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; ---------- Loop  with  Call   IDL_read_data  ------------------------------
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

isample = 0
;; nb_samples_lu = 1L
;; nb_sample_total = 0L
;; nb_bloc_total = 0L

;; indiceboucle=0                  ;
;; buffertemp[0] = 1               ; pour demander une initialisation des tableaux temporaires de brut_to_data
;; 
;;while (nb_samples_lu gt 0) do begin


nb_samples_request = nb_read_samples

;message, /info, "fix me:"
;nb_samples_request = 1000
;stop

;print, "nb_read_samples: ", nb_read_samples
;stop

bufferdata = dblarr(nb_samples_request*length_data_per_sample)

;; Because the code read entire blocks, nb_samples_lu can be a bit
;; smaller than nb_samples_request.
;print, "nb_samples_request: ", nb_samples_request
;message, /info, 'fix me: '
;nb_samples_request /= 10
;stop

list_data_tmp = convert_toc_string(list_data)
nb_samples_lu = call_external( libso,'IDL_read_data', file_tmp, bufferdata, $
                               list_data_tmp, list_detector, nb_samples_request, silent)

if nb_samples_lu le 0 then begin
   message, /info, "No sample read"
   goto, notafile
endif

nb_bloc_lu = nb_samples_lu/nb_pt_bloc
bufferdata = reform(bufferdata[0L:length_data_per_sample*nb_samples_lu-1l],length_data_per_sample,nb_samples_lu)

;print, "nb_samples_lu: ", nb_samples_lu
;stop
data = replicate( data, nb_samples_lu)

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


for idx=0,nb_data_communs-1 do $
   data.(idx) = reform(bufferdata[idx,*], nb_samples_lu)
      
;; ----------  les  data  detecteurs  -----------------
for idx=0,nb_data_detecteurs-1 do begin
   data.(idx+nb_data_communs) = (bufferdata[nb_data_communs+idx*n_det: nb_data_communs+idx*n_det+n_det-1,*])
endfor

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
notafile: 

return, nb_samples_lu
END
