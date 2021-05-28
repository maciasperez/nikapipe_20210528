
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "rotation.h"
#include "def.h"



// ici on calcule la rotation a faire sur les coordonnees theoriques des pixel pour projeter les pixel dans les coordonnees choisies
//  on calculera ensuite les positions avec position pointage - rotation(position theorique)
// rotation_etalon est la rotation de base liee a la definition de la matrice
// pointage_rotazel est la rotation de base liee a la definition de la matrice
// pointage_rotazel est la rotation de base liee a la definition de la matrice
// paralactic   est la rotation pour aller de azel  en radec  (on considere ici l'axe  -Ra )
//
void init_chc(Chg_coor *chc,Etalon_optique_matrice *etalon_matrice_X) {
	if(etalon_matrice_X) {
		chc->grossissement	=	_grossissement_uphys_pixel(etalon_matrice_X);
		chc->dalpha.a		=	_decalage_rotation(etalon_matrice_X);
		chc->dalpha.cos		=	cos( _decalage_rotation(etalon_matrice_X) );
		chc->dalpha.sin		=	sin( _decalage_rotation(etalon_matrice_X) );
		chc->inv			=	_inversion_chc_pixel(etalon_matrice_X);
		chc->offset.x		=	_centre_matrice_x(etalon_matrice_X);
		chc->offset.y		=	_centre_matrice_y(etalon_matrice_X);
	} else {
		chc->grossissement	=	0;
		chc->dalpha.a		=	0;
		chc->dalpha.cos		=	0;
		chc->dalpha.sin		=	0;
		chc->inv			=	0;
		chc->offset.x		=	0;
		chc->offset.y		=	0;
	}
}


void	prepare_chc_radec(Chg_coor *chc,double rotation_etalon,double pointage_rotazel,double paralactic) {
	chc->dalpha.a =  rotation_etalon  + pointage_rotazel - paralactic;
	_valide_angle(chc->dalpha);
}

void	prepare_chc_azel(Chg_coor *chc,double rotation_etalon,double pointage_rotazel) {
	chc->dalpha.a =  rotation_etalon + pointage_rotazel;
	_valide_angle(chc->dalpha);
}



//---------------------------    anciennes fonctions utilisees en 2010  -------------------------------------------------
/**********************************************************
*                       prepare_chc                       *
**********************************************************/
void	prepare_chc(int choix_coordonnees,Chg_coor *chc,double rotation_etalon,double pointage_rotazel,double paralactic) {
	// ici on calcule la rotation a faire sur les coordonnees theoriques des pixel pour projeter les pixel dans les coordonnees choisies
	//  on calculera ensuite les positions avec position pointage - rotation(position theorique)
	// rotation_etalon est la rotation de base liee a la definition de la matrice
	// pointage_rotazel est la rotation de base liee a la definition de la matrice
	// pointage_rotazel est la rotation de base liee a la definition de la matrice
	// paralactic   est la rotation pour aller de azel  en radec  (on considere ici l'axe  -Ra )
	//
	switch(choix_coordonnees) {
		case	_choix_radec			:	// avec ma definition de paralactique (par la derivee de Ra) je dois tourner de + paral pour passer dans le repere RaDec
			// comme les rotations sont inverses, je mets -para
		case	_choix_radec_pixel_th	:
			chc->dalpha.a =  rotation_etalon  + pointage_rotazel - paralactic;
			_valide_angle(chc->dalpha);
			break;

		case	_choix_azel				:	// Je dois tourner de - elevation pour ramener la matrice dans le coordonnees Azel
			// comme les defines de rotations sont inverse,  je tourne la matrice  donc de + elevation
		case	_choix_azel_pixel_th	:
			chc->dalpha.a =  rotation_etalon + pointage_rotazel;
			_valide_angle(chc->dalpha);
			break;
		default	:
			break;			// pas de changement de chc en mode matrice
	}
}


/**********************************************************
*                   prepare_pointage_xy                   *
**********************************************************/
void	prepare_pointage_xy(int choix_coordonnees,Point *pointage_xy,double pointage_rotazel,double paralactic) {
	switch(choix_coordonnees) {	// je fais juste tourner le pointage courant pour etre dans les nouvelles coordonna(C)es
		case	_choix_radec			:
		case	_choix_radec_pixel_th	:
			_rotation((*pointage_xy), -1* paralactic); 	// la meme rotation que les coordonnees matrice
			//pointage_xy->x = - pointage_xy->x;
			break;
		case	_choix_matrice			:
		case	_choix_matrice_pixel_th	:
			_rotation((*pointage_xy),-1.*pointage_rotazel);	//rotation inverse de la rotation matrice en Azel
			break;
		default	:
			break;// pas de rotation sur les coordonnees en azel
	}
}




/**********************************************************
*                 position_pointage_bolo                  *
**********************************************************/
// prend la position xy d'un detecteur et la transforme en position sur la carte
void position_pointage_bolo(Point *xy,int choix_coordonnees,Chg_coor chc,Point pointage_xy) {
	Point  pix;		//   pix = _XYpix(n_bol);	 a mettre a l'exterieur avant l'appel de la fonction
	pix = *xy;

	switch(choix_coordonnees) {
		case	_choix_radec				:
		case	_choix_azel					:
		case	_choix_matrice				:
			*xy = pointage_xy;
			break;

		case	_choix_azel_pixel_th		:
		case	_choix_matrice_pixel_th		:
			xy->x = _X_ciel_def(pix,chc,pointage_xy);
			xy->y = _Y_ciel_def(pix,chc,pointage_xy);
			break;

		case	_choix_radec_pixel_th		:
			xy->x = _X_ciel_def(pix,chc,pointage_xy);		// je ne change pas le signe du x car je trace en ra inverse
			xy->y = _Y_ciel_def(pix,chc,pointage_xy);
			break;

		case	_choix_sans_projection		:
			xy->x = pix.x*10;
			xy->y = pix.y*10;
			break;

		default								:
			xy->x=undef_double;
			xy->y=undef_double;
			break;
	}
}




/*======================================================================================*/
/*-------------------------------     utilitaires  divers      -------------------------*/
/*======================================================================================*/
double angle_paralactique(double Ra,double Dec,double LST,double latitude) {
	double sinH;
	double cosH;
	double para;
	double ha=LST-Ra;
	sinH=cos(latitude)*sin(ha);
	cosH=sin(latitude)*cos(Dec)-cos(latitude)*sin(Dec)*cos(ha);
	para = atan2(sinH,cosH);
	//printf("angle paralactique = %f soit %f\n",para,para*180/PI);
	return para;
}


double calcul_derive_radec(double Ra,double Dec,double LST,double latitude) {
	double para;
	double ha=LST-Ra;
	double X=-cos(ha)*cos(Dec)*sin(latitude)+sin(Dec)*cos(latitude);
	double Y=-sin(ha)*cos(Dec);
	double Z=cos(ha)*cos(Dec)*cos(latitude)+sin(Dec)*sin(latitude);
	double R=_amplitude(X, Y);

	// je derive par rapport a ha   (idem  Ra au signe pres)
	double dX = sin(ha)*cos(Dec)*sin(latitude);
	double dY = -cos(ha)*cos(Dec);
	double dZ = -sin(ha)*cos(Dec)*cos(latitude);
	double dR = ( X * dX + Y * dY ) / R ;
	double daz = 1 / (X*X+Y*Y) * ( X * dY - Y * dX);
	double del = 1 / (R*R+Z*Z) * ( R * dZ - Z * dR);
	daz = daz * cos(atan2(Z,R));		// divise par le cos de l'elevation
	para = atan2(del,daz);
	// ici para est l'angle de l'axe -Ra  dans le repere Azel
	// a partir du repere Azel  on tourne de para pour faire un repere  (-Ra,dec)
	//printf("dans calcul_para daz = %g  del=%g  ",daz,del);
	return para;
}



// converti les coordonnees RaDec absolues en coordonnees AzEl absolues
void radec_a_azel(double Ra,double Dec,double LST,double latitude,double *Az,double *El) {

	double ha=LST-Ra;
	double X=-cos(ha)*cos(Dec)*sin(latitude)+sin(Dec)*cos(latitude);
	double Y=-sin(ha)*cos(Dec);
	double Z=cos(ha)*cos(Dec)*cos(latitude)+sin(Dec)*sin(latitude);
	double R=_amplitude(X, Y);
	*Az=atan2(Y,X); //printf(" *Az = %g ",*Az);
	*El=atan2(Z,R); //printf(" *El = %g ",*El);
	if(*Az <0) *Az = *Az + 2* PI;
	//printf(" ra=%f soit %f deg  dec=%f soit %f deg  lst = %f soit %f secondes  latitude = %f soit %f deg"
	//			,Ra,Ra*180/PI,Dec,Dec*180/PI,LST,LST*3600*12/PI,latitude,latitude*180/PI);
	//printf(" ra=%f soit %f min ou %f deg  dec=%f soit %f deg  lst = %f soit %f sec  lat = %f soit %f deg \n"
	//			,Ra,Ra*12*60/PI,Ra*180/PI,Dec,Dec*180/PI,LST,LST*12*3600/PI,latitude,latitude*180/PI);
	//double el2 = asin ( sin(Dec)*sin(latitude) + cos(Dec)*cos(latitude)*cos(ha) ) ;
	//double az2 = 2*PI -  acos( (sin(Dec) - sin(el2)*sin(latitude)) / (cos(el2)*cos(latitude)));
}

