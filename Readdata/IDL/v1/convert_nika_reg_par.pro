pro convert_nika_reg_par, divkid, regparorg,  regpar_a,  regpar_b, a_only=a_only

 nb_pas_synthe_possibles = 13

; DECONDING KID A 

 kida =  regparorg.kid_A
 att_bf_a =  kida[0] mod 256
 att_hf_a =  kida[0]/256L mod 256
 gain_dac_roach_a = kida[1] mod 256
 gain_adc_roach_a = kida[1]/2l^8 mod 256
 ; ------
 
 ampl_mod_a = kida[1]/2l^16 mod 256 ; 1 a 250 Khz
 
;-----
 kid_balayage_freq_base_a =  0.01*kida[2] ; Khz
 kid_balayage_freq_par_bin_brut_a =  0.001*(kida[3] mod 16777216L)
 if  kid_balayage_freq_par_bin_brut_a lt 0.5 then kid_balayage_freq_par_bin_a =  0.5 else kid_balayage_freq_par_bin_a = kid_balayage_freq_par_bin_brut_a

 echantillonnage_kid_a = 1.0/(kid_balayage_freq_par_bin_a*1000./divkid) 
 echantillonnage_nano_kid_a =      (divkid * 1000000.0/kid_balayage_freq_par_bin_a )
 
 kid_balayage_pas_a =  kida[3]/2l^24 mod 16
 kid_balayage_code_synthe_a =  kida[3]/2l^28 mod 16	 
 pas_synthe = [0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]

 if (kid_balayage_pas_a gt 0 and kid_balayage_pas_a lt nb_pas_synthe_possibles) then kid_balayage_val_pas_a = pas_synthe[kid_balayage_pas_a] else kid_balayage_val_pas_a = 1

 kid_balayage_nb_pas_a =  kida[4] mod 16L^3
 kid_balayage_temps_mort_A =  kida[4]/2l^12 mod 16 
 kid_balayage_duree_a = kida[4]/2l^16 mod 16^2	
 kid_balayage_action_A  = kida[4]/2l^24 mod 3	
 kid_balayage_mac_auto_a = kida[4]/2l^26 mod 16	

 if not keyword_set(a_only) then begin
; ---------- B ---------
    kidb =  regparorg.kid_b
    att_bf_b =  kidb[0] mod 256
    att_hf_b =  kidb[0]/256 mod 256
    gain_dac_roach_b = kidb[1] mod 256
    gain_bdc_roach_b = kidb[1]/2l^8 mod 256
    ampl_mod_b = kidb[1]/2l^16 mod 256 ; 1 a 250 Khz

    kid_balayage_freq_base_b =  0.01*kidb[2] ; Khz
    kid_balayage_freq_par_bin_brut_b =  0.001*(kidb[3] mod 16777216L)
    if  kid_balayage_freq_par_bin_brut_b lt 0.5 then kid_balayage_freq_par_bin_b =  0.5 else kid_balayage_freq_par_bin_b = kid_balayage_freq_par_bin_brut_b

    echantillonnage_kid_b = 1.0/(kid_balayage_freq_par_bin_b*1000./divkid) 
    echantillonnage_nano_kid_b =      (divkid * 1000000.0/kid_balayage_freq_par_bin_b )
    
    kid_balayage_pas_b =  kidb[3]/2l^24 mod 16
    kid_balayage_code_synthe_b =  kidb[3]/2l^28 mod 16	 
    pas_synthe = [0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]

    if (kid_balayage_pas_b gt 0 and kid_balayage_pas_b lt nb_pas_synthe_possibles) then kid_balayage_val_pas_b = pas_synthe[kid_balayage_pas_b] else kid_balayage_val_pas_b = 1

    kid_balayage_nb_pas_b =  kidb[4] mod 16L^3
    kid_balayage_temps_mort_b =  kidb[4]/2l^12 mod 16 
    kid_balayage_duree_b = kidb[4]/2l^16 mod 16l^2	
    kid_balayage_bction_b  = kidb[4]/2l^24 mod 3	
    kid_balayage_mac_buto_b = kidb[4]/2l^26 mod 16	
endif
 
 regpar_a = {att_bf_a:att_bf_a, att_hf_a:att_hf_a,gain_dac_roach_a:gain_dac_roach_a, gain_adc_roach_a:gain_adc_roach_a, $
            ampl_mod_a:ampl_mod_a, kid_balayage_freq_base_a:kid_balayage_freq_base_a, kid_balayage_freq_par_bin_brut_a:kid_balayage_freq_par_bin_brut_a, $
            kid_balayage_freq_par_bin_a:kid_balayage_freq_par_bin_a, echantillonnage_kid_a:echantillonnage_kid_a,  $
            echantillonnage_nano_kid_a:echantillonnage_nano_kid_a  ,  $
            kid_balayage_pas_a:kid_balayage_pas_a, kid_balayage_code_synthe_a:kid_balayage_code_synthe_a, $
            kid_balayage_val_pas_a: kid_balayage_val_pas_a, kid_balayage_nb_pas_a:kid_balayage_nb_pas_a, kid_balayage_temps_mort_A:kid_balayage_temps_mort_A,  $
            kid_balayage_duree_a:kid_balayage_duree_a, kid_balayage_action_A:kid_balayage_action_A, kid_balayage_mac_auto_a:kid_balayage_mac_auto_a}

 if not keyword_set(a_only) then begin
    regpar_b = {att_bf_b:att_bf_b, att_hf_b:att_hf_b,gain_dac_roach_b:gain_dac_roach_b, gain_bdc_roach_b:gain_bdc_roach_b, $
                ampl_mod_b:ampl_mod_b, kid_balayage_freq_base_b:kid_balayage_freq_base_b, kid_balayage_freq_par_bin_brut_b:kid_balayage_freq_par_bin_brut_b, $
                kid_balayage_freq_par_bin_b:kid_balayage_freq_par_bin_b, echantillonnage_kid_b:echantillonnage_kid_b,  $
                echantillonnage_nano_kid_b:echantillonnage_nano_kid_b,    $
                kid_balayage_pas_b:kid_balayage_pas_b, kid_balayage_code_synthe_b:kid_balayage_code_synthe_b, $
                kid_balayage_val_pas_b: kid_balayage_val_pas_b, kid_balayage_nb_pas_b:kid_balayage_nb_pas_b, kid_balayage_temps_mort_b:kid_balayage_temps_mort_b,  $
                kid_balayage_duree_b:kid_balayage_duree_b, kid_balayage_bction_b:kid_balayage_bction_b, kid_balayage_mac_buto_b:kid_balayage_mac_buto_b}
    
 endif

return
end
