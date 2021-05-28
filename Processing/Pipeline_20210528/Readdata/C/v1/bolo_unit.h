#ifndef ARCUNIT_H
#define ARCUNIT_H

/*======================================================================*/
/*                                                                      */
/* 		 bolo_unit.h  :	conversion en mesure physique               	*/
/*                                                                      */
/*======================================================================*/

//--------------------------------------
//   HORLOGES et CONVERSIONS DAC/ADC  --
//--------------------------------------


//--------------------------------------
//        MULTIPLEXEUR (MUPA ?)       --
//--------------------------------------
#define	_mux_V(dacV)  ((2048-(dacV))*0.01/2048.)	// en V : 10mV pleine echelle
#define	_mux_R(muxR)  ((double)(muxR)*1000.)		// en ohm : maxi 32 Mohm 
#define	_mux_C(muxC)  ((double)(muxC)*1e-11)		// la lecture est en dizaines de pif et je converti en farad (pour pouvoir depasse 2nF)

extern int		calcul_dacL_affiche(int dacL_regl);
extern int		calcul_dacL_regl(int dacL_affiche);
extern double	calcul_dacL_valeur(int dacL_regl);
extern int		calcul_dacL_affiche_de_valeur(double val);
extern int		calcul_dacL_Ipente ( int n_bol,double Ipente);



/* ----------------------------   prototypes des fonctions	 ------------------------------ */
/* -------------------------------------------------------------------------------------------- */
extern double	bolo_temp(	 double R,int n_bol);

extern double	DAC_muV_coef(Data_header_shared_memory *dhs, int n_bol);
extern double	DAC_muV(Data_header_shared_memory *dhs, int n_bol);

extern double	DAC_muA_coef(Data_header_shared_memory *dhs, int n_bol);
extern double	DAC_muA(Data_header_shared_memory *dhs, int n_bol);

extern double	DAC_Ipente( int n_bol);



/* ----------------------------   define utilise pour les calculs	 ------------------------------ */
/*  la fonction  bol_micro_volt  est toujours utilisee pour lire un bloc bolo				*/
/*  comme j'ai divise par 2 le calcul  du bloc bolo : ce n'est plus qu'une somme des donnees brutes de l'ADC 	*/

/*  le 2 parceque j'ai change le calcul de la somme des valeurs de ADC					*/
/*  le 4 parceque je veux remetre un gain de 100 au lieu de 25 dans le tableau de param.h		*/
/*  et encore 2  pour que ca tombe juste a l'oscillo							*/
/*  le facteur provient sans doute du fait que je n'ai que 12 bits de ADC				*/

//  je transforme  gg->don.don_bolo[n_bol]  de short en double
//#define	bol_micro_volt(val,gain_total)	((val==undef_short)?(undef_double):(2.*4.*2.*(1e7*(double)val)/(65536.*(gain_total))))


//#define	bol_micro_volt(val,gain_total)	((val==undef_double)?(undef_double):(2.*4.*2.*(1e7*(double)val)/(65536.*(gain_total))))

// je redefini le gain pour avoir  2.5V sur 16 bit
// ici j'ai plutot 10V pour 16 bit


#endif // ARCUNIT_H
