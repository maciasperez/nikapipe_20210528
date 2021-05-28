
file_nika ='/mnt/NewData/NIKA/Data/run34_X/X36_2018_11_28/X_2018_11_28_09h22m16_AA_man'
file_nika='/mnt/NewData/NIKA/Data/run39_ABOB_X/X36_2018_12_04/X_2018_12_04_15h47m00_0207_P_Mars'
file_nika='/home/nika2/NIKA/Data/run39_ABOB_X/X36_2018_12_04/X_2018_12_04_15h47m00_0207_P_Mars'
file_nika='/home/nika2/NIKA/Data/run39_ABOB_X/X36_2018_12_04/X_2018_12_04_19h04m26_0247_P_Uranus'
list_data = "sample subscan scan El retard "+strtrim(0,2) + $
               " Az Paral scan_st MJD LST"+$
               " k_flag RF_didq "
letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u']

for ii = 0, n_elements(letter)-1 do  list_data += (" " + strupcase(letter[ii])+"_masq ")

list_data += 'C_position C_synchro O_position O_synchro Q_position Q_synchro U_position U_synchro'

list_data += " F_tone dF_tone I Q dI dQ"
list_data += " pI pQ X_tbm"

for ii=0, n_elements(letter)-1 do  list_data += (" "+ strupcase(letter[ii]) +"_time "+strupcase(letter[ii])+"_time_pps")

silent = 1
nsamples = READ_NIKA_BRUTE_v3( file_nika, param_c, kidpar, data, dataU, $
                             param_d = param_d, $
                             list_data=list_data, list_detector=list_detector,$
                             amp_modulation=amp_modulation, $
                             silent=silent, read_type=read_type, $
                             katana=katana, polar=polar)
