
pro nika_pipe_ab_flag2pipe_flag, param, data, kidpar


;; Feb. 7th, 2014

;;//--- ce flag provient de la carte nikel et apparait dans les data par boite :    A_masq  B_masq  ...
;;//--- il n' pas change depuis les run 5 et 6
;;
;;#define_flag_balayage_en_cours0x01// flag ecrit lors du balayage du synthe
;;#define_flag_blanking_synthe0x02// flag ecrit lors du balayage du synthe
;;#define_flag_fpga_change_frequence0x04// indique le chargement des tones
;;
;;//---  les flag suivants apparaissent dans le param pour chaque detecteur :  "flag"
;;
;;#define_flag_mauvais_tuning0x20// fixe par le prg  calcul_tuning_2
;;#define_flag_resonnance_mal_placee0x40        // les resonnances qui devient par rapport a leur place dans le param
;;#define_flag_resonnance_perdue0x80// utilise par "retrouve resonnances
;;
;;//---  enfin tous les flags apparaissent dans les data  "k_flag" de chaque detecteur 


;; IDL function to convert from Hexadecimal to integers
;; IDL> reads, '0x40', number, format="(Z)" & print, number


flag_list = [0, 1, 2, 5, 6, 7]

nflags = n_elements(flag_list)

pipe_flag_list = indgen( nflags) + 12

for i=0, n_elements(flag_list)-1 do begin
   powerOfTwo = 2L^flag_list[i]
   flagged  = where( (long( data.k_flag) and powerOfTwo) EQ powerOfTwo, nflagged)

   powerOfTwo = 2L^pipe_flag_list[i]
    
   w = where((long(data.flag[flagged]) and poweroftwo ) eq flag_list[i], nw ,comp=wapp, ncomp=nwapp)
   IF nwapp gt 0 then begin
      data.flag[flagged[wapp]] += poweroftwo
   endif 

         
 endfor


 return
end

