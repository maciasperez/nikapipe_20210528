
/************************************************************************************************/
/*                                                                 				*/
/*          programme  contenant les conversions en mesure physique				*/
/*                            a jour version vol Kiruna						*/
/*                                                                   				*/
/************************************************************************************************/

#ifdef _MANIPQT_ 	//-------  uniquement dans le mac avec ManipQt ( defini dans le .pri )
#include "mq_manip.h"			// pour acquisition et client_trace dans le MAC

#else							// pour linux et les boitiers d'acquisition

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#endif

#include "a_memoire.h"
#include "def.h"
#include "def_opera.h"



#include "bolo_unit.h"


#define  _capa(dhs,n_bol)	(double)_param_d(dhs,_pd_capa,n_bol)*1e-15   	//  capa lue dans le fichier parametre en entier et en fFarad convertie en F
#define  _tension_dacL_pleine_echelle 1
//#define  _capa(n_bol)	4.7e-12									// pour test du multiplexeur  4.7 pif
//#define  _tension_dacL_pleine_echelle	0.8						// avec la MUPA: mesure 800mV pleine echelle

/* ------------------------------------   corps  des fonctions	 ------------------------------ */
/* -------------------------------------------------------------------------------------------- */
/****************************************************
*                  DAC_MUV_COEF                     *
****************************************************/
/* donne la valeur en millivolt pour 1 pas du DAC	*/
double DAC_muV_coef(Data_header_shared_memory *dhs, int n_bol) {
	double div=(double)_param_d(dhs,_pd_diviseur,n_bol);
	if(div) return (2441. /  div );
	else	return(0);
}

/****************************************************
*                    DAC_MUV                        *
****************************************************/
/* donne la valeur du DAC bolometre en millivolt	*/
double DAC_muV(Data_header_shared_memory *dhs, int n_bol) {
//	uint4 *RG_opera = reglage_pointer(dhs,_r_opera,-1);
	uint4 *RG1_opera = reglage_pointer(dhs,_r_o_rg1,-1);
	double car= (double)_dac_V(dhs,n_bol)  ;
	return (car * DAC_muV_coef(dhs,n_bol));
}

/****************************************************
*                  DAC_MUA_COEF                     *
****************************************************/
/* en mode bolo,  donne la valeur en microAmperes pour 1 pas du _dac_I	*/
/* en mode mux,   donne la charge en coulomb pour 1 pas du _dac_I  (triangle = courant)	, pour le courant, il faut voir que le pas est divise par 2^6=64 a la frequence d'echantillonage */
double	DAC_muA_coef(Data_header_shared_memory *dhs,int n_bol) {
	double Q,I,capa=_capa(dhs,n_bol); //  capa  lue dans le fichier parametre et convertie en Farad  (4000 = 4 pF  )
	//if(_type_det(dhs,n_bol)==_type_BEDIFF)	capa*=0.868;	// la capa est a reduire pour les BEDIFF	// AUB : 10/03/2011 - cela doit etre fait dans le fichie de config !!!

	//--------------------------------------
	//                 MUX                --
	//--------------------------------------
	if(_est_un_MUX_bolo (_type_det(dhs,n_bol)) ) {
		//  calcul pour le multiplexeur : DAC_muA_coef donne une charge et non un courant
		//  la capa dans le fichier parametre est la capa de feedback de l'ampli
		// pour le mux, on a 800mV pour 2000 points du convertisseur pour piloter la capa du preampli froid (triangle)

		//	Q = capa * 10. / 2048.;	//  la charge est donnee par Q = C * V et V sera donne en 2048 pour 10V
		if(_est_une_BEBO (_type_det(dhs,n_bol)) )	Q = capa * 1.0 / 32768.;	// pour BEMUX : j'ai 1V pour la pleine echelle
		// si je change le switch pour 10V pleine echelle, il suffit de mettre dans le param une capa de polar 10 fois plus grande que la realite
		else													Q = capa * 0.8 / 2000.;		// pour MUPA  : il faudrait verifier la vraie valeur de capa avec 800mV pour 2000 points du DAC

		//printf("bol=%d capa=%g pF  Q=%g \n",n_bol,capa*1e12,Q);
		return Q;	// en Coulombs pour le MUX pour 1 point du convertisseur a l'affichage (2000 points pleine echelle pour MUPA)
		// je dois diviser par la periode de modulation: ce sera fait a l'utilisation
	}

	//--------------------------------------
	//               NON MUX              --
	//--------------------------------------
	else {
		I=(capa / (4096. * 22. * 20.) )* 1e12;	//  sans doute les valeurs de l'integrateur des boitiers bolo MLPA et BEDIFF	en micro A par point du convertisseur
		//printf("bol=%d capa=%g pF I=%g \n",n_bol,capa*1e12,I);
		return I;
	}
}


/****************************************************
*                    DAC_MUA                        *
****************************************************/
/* donne la valeur du DAC bolometre en microAmperes  ou la charge en coulombs pour le multiplexeur sans calcul	*/
double DAC_muA(Data_header_shared_memory *dhs,  int n_bol) {

//	uint4 *RG_opera  = reglage_pointer(dhs,_r_opera,-1);
	uint4 *RG1_opera = reglage_pointer(dhs,_r_o_rg1,-1);
	double dacI= (double)_dac_I(dhs,n_bol)  ;
	if( _est_un_MUX (_type_det(dhs,n_bol)) ) dacI-=2048; 	//  bipolaire
	//printf(" DAC_muA: dacI=%g  muacoef=%g  ",dacI,DAC_muA_coef(n_bol));
	return (dacI * DAC_muA_coef(dhs,n_bol));
}

//****************************************************
//****************************************************
//****************************************************
//****************************************************
//****************************************************
//
//---  a partir d'ici, il faut l'externe  Dhs  :  a corriger   !!!!!!!!

#ifdef _TRACE_			// ne compile pas sans le global Dhs

extern Data_header_shared_memory *Dhs;




/****************************************************
*                CALCUL_DACL_REGL                   *
****************************************************/
int calcul_dacL_regl(int dacL_affiche) {

	//  les 2 bit de poid fort multiplient la vitesse par 1,2,4,8
	// les 10 bit faibles +20  donnent le temps entre deux increments
	// si on demarre avec  0  et  1000
	// 200 pts on avance par pas de 3 jusqu'a 0 et 400
	// 100 pts on avance par pas de 2 jusqu'a 0 et 200
	// 100 pts on avance par pas de 1 jusqu'a 0 et 100   equivalent a 1 et 200
	// 100 pts on avance par pas de 1 jusqu'a 1 et 100   equivalent a 2 et 200
	// 100 pts on avance par pas de 1 jusqu'a 2 et 100   equivalent a 3 et 200
	// 180 pts  on avance par pas de 1 jusqu'a 3 et 20
	//  total de 0 a 730 points

	//  100 pts de  0,1000 a 0,700 par pas de 3
	//  100 pts de  0,700 a 0,400 par pas de 3
	//  100 pts de  0,400 a 0,200 par pas de 2
	//  100 pts de  0,200 a 0,100 par pas de 1
	//  100 pts de  1,200 a 1,100 par pas de 1
	//  100 pts de  2,200 a 2,100 par pas de 1
	//  100 pts de  3,200 a 3,100 par pas de 1
	//  80 pts de  3,100 a 0,20 par pas de 1
	//    Total 780 points
	int x=0;
	return dacL_affiche;	//bolomux

	if (dacL_affiche>780) dacL_affiche=780;
	if (dacL_affiche!=0)  switch(dacL_affiche/100) {
			case 0	:
				x=1000-3*(dacL_affiche%100) -20;
				break;
			case 1	:
				x=700-3*(dacL_affiche%100) -20;
				break;
			case 2	:
				x=400-2*(dacL_affiche%100) -20;
				break;
			case 3	:
				x=200-(dacL_affiche%100) -20;
				break;
			case 4	:
				x=200-(dacL_affiche%100) -20	+	1024;
				break;
			case 5	:
				x=200-(dacL_affiche%100) -20	+	2048;
				break;
			case 6	:
				x=200-(dacL_affiche%100) -20	+	3072;
				break;
			case 7	:
				x=100-(dacL_affiche%100) -20	+	3072;
				break;
			default	:
				x=0;
				break;
		}
	return x;
}

int calcul_dacL_affiche(int dacL_regl) {
	int x=0;
	return dacL_regl;	//bolomux
	if (dacL_regl!=0)  switch(dacL_regl/1024) {
			case 0 :
				if(dacL_regl>400-20)	x=(1000-dacL_regl-20)/3;
				else	if(dacL_regl>200-20)	x=200+ (400-dacL_regl-20)/2;
				else	x=300+ (200-dacL_regl-20);
				break;
			case 1 :
				x=400+ (200-(dacL_regl%1024)-20);
				break;
			case 2 :
				x=500+ (200-(dacL_regl%1024)-20);
				break;
			case 3 :
				x=600+ (200-(dacL_regl%1024)-20);
				break;
			default	:
				x=0;
				break;
		}
	return x;
}

/****************************************************
*               CALCUL_DACL_VALEUR                  *
****************************************************/
// en entree, la valeur du dacL , retourne des volt/sec sur la capa de contre reaction (la rampe est faite avec une horloge fixe)
double calcul_dacL_valeur(int dacL_regl) {
	double x=0;
	//bolomux

	if (dacL_regl!=0)	switch(dacL_regl/1024) {
			case 0 :
				x=1000./((double)(dacL_regl%1024)+20.);
				break;
			case 1 :
				x=2000./((double)(dacL_regl%1024)+20.);
				break;
			case 2 :
				x=4000./((double)(dacL_regl%1024)+20.);
				break;
			case 3 :
				x=8000./((double)(dacL_regl%1024)+20.);
				break;
			default	:
				x=0;
				break;
		}
	//  x est le nombre de points de variation du Dac en 1000 fois la periond de 100 ns (10 MHz)
	x = x * 10000;		//  x * 10 000 est le nb de points / seconde
	x = x * 4 ;		//  je multiplie par 4 la vitesse dans le programme FPGA  MUPA  (dans OPERA_camera)
	x = x * _tension_dacL_pleine_echelle / (32768.);		// on a ici le nombre de volt / seconde
	//x = x * 10000./3276.8;	//  rampe en V/sec en sortie de convertisseur
	//  c'est le seul endroit ou ca apparait car la fonction inverse calcul_dacL_affiche_de_valeur() travaille par dichotomie
	// ici j'ai suppose 10V pour 32768 points. En fat je n'ai que 800mV pour pleine echelle du convertisseur bipolaire (voir
	//  comme je n'ai que 0.8V je dois corriger
	//x = x * 0.8 / 10.;
	//  il serait mieux d'utiliser  DAC_muA_coef qui me donne la charge pour la  pleine echelle du convertisseur bipolaire soit pour 32768 points
	//  x * 10000./32768.

	//  je renvoie des volt/sec et ne calibre pas en courant avec la capa: ca sera fait ailleur
	//printf("  calcul_dacL_valeur x=%g ",x);
	return x;
}

/****************************************************
*         CALCUL_DACL_AFFICHE_DE_VALEUR             *
****************************************************/
int calcul_dacL_affiche_de_valeur(double val) {
	//  la valeur est une fonction croissante de l'affichage de 0 a 780
	int x,pas;
	x=0;	// l'affichage
	//printf(" je rentre avec val=%g  et je trouve %d \n",val,x);
	for(pas=512; pas>0; pas=pas/2)
		if(calcul_dacL_valeur(calcul_dacL_regl(x+pas)) < val ) x+=pas;
	//printf(" je rentre avec val=%g  et je trouve %d \n",val,x);
	return x;
}

/****************************************************
*                   DAC_IPENTE                      *
****************************************************/
/* donne la valeur du courant cree par la pente du terme dacL pour le multiplexeur	*/
double DAC_Ipente( int n_bol) {
	uint4 *RG2_opera = reglage_pointer(Dhs,_r_o_rg2,-1);
	int a;
	double I=0;
	double capa = _capa(Dhs,n_bol); 	//  capa lue dans le fichier parametre convertie en F
	double pente;
#ifdef _ManipQt_
	#ifdef debug
		if(n_bol==2) printf("bolo%d reglage capa= %d  capa=%gnF ",n_bol,_param_d(Dhs,_pd_capa,n_bol),capa*1e9);
	#endif
	a=_dac_L(n_bol);
	pente=calcul_dacL_valeur(a);
	I= pente*capa;		// en A car la pente est en V/sec
	#ifdef debug
		if(n_bol==2) printf("\n capa=%g pF  _dac_L=%d  reg_dacL=%d",capa*1e12,calcul_dacL_affiche(_dac_L(n_bol)),_dac_L(n_bol)),
					printf("  pente=%g V/s  I=%g nA \n",pente,I*1e9);
	#endif
#endif
	return I;
}

/****************************************************
*               CALCUL_DACL_IPENTE                  *
****************************************************/
int	calcul_dacL_Ipente (  int n_bol,double Ipente) {
	// WARNING // int a;
	double capa = _capa(Dhs,n_bol); 	//  capa lue dans le fichier parametre convertie en F
	double pente=1;
	int dacL_regl,dacL_affiche;
#ifdef _ManipQt_
	if(capa>1e-15) pente=Ipente/capa;			//  pente en V/sec

	dacL_affiche=calcul_dacL_affiche_de_valeur(pente);
	dacL_regl=calcul_dacL_regl(dacL_affiche);
	printf("pente=%g  refl=%d   affich=%d  ",pente,dacL_regl,dacL_affiche);
#endif
	return dacL_regl;
}

#endif		//	#ifdef _TRACE_			// ne compile pas sans le global Dhs



