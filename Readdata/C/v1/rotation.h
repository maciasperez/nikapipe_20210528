#ifndef _ROTATION_H_
#define _ROTATION_H_

#ifndef int4
#define int4 int
#define uint4 unsigned int
#define undef_int4		0x7fffffff
#endif

/*======================================================================*/
/*                                                                      */
/* 		 ROTATION_H                   	*/
/*                                                                      */
/*======================================================================*/
#ifndef   __ROTATION_COORDONNEES__
#define   __ROTATION_COORDONNEES__

#ifndef PI
#define PI   3.1415926535897932384626433832795028841971L
#endif
// pour la manipulation de changement de coordonnees  ->  deplace dans def_base

typedef struct	{
	double	a;
	double	cos;
	double  sin;
} Angle;

typedef struct	{
	double	x;
	double	y;
} Point;

typedef struct	{
	double	grossissement;
	Angle	dalpha;
	double	inv;
	Point	offset;
} Chg_coor;

#endif	// #ifndef   __ROTATION_COORDONNEES__

typedef struct {
	int4		g;		/*	grossissement en microradian / 1000 pixel   */
	int4		x0;		/*	coordonnee du centre en milli pixel					*/
	int4		y0;		/*	coordonnee du centre en milli pixel					*/
	int4		alpha;		/*	angle de rotation erreur de la matrice en microradians				*/
} Etalon_optique_matrice;



// pour valider un angle (calcul du cos et du sin) appeler le define suivant
#define _valide_angle(alpha)	{alpha.cos=cos(alpha.a);alpha.sin=sin(alpha.a);}

#ifndef _DEF_PA
#define _DEF_PA
// Note: as a macro this is slow because it does too many evaluations
static inline double petit_angle(double a)	{
	return	(a> PI) ? (a-2*PI) : 
			(a<-PI) ? (a+2*PI) :
			           a;
}
#endif

// je change le signe car ma rotation est aussi en negatif

//abab : je change l'angle car j'ai change le signe didq dans nikel
//#define _dangleIQdIdQ(x2,x1,y2,y1)	(petit_angle(PI/2 - atan2((double)(x1),(double)(y1)) + atan2((double)(x2),(double)(y2))))			avant de changer le signe
//#define _dangleIQdIdQ(x2,x1,y2,y1)	(petit_angle( - atan2((double)(x1),(double)(y1)) + atan2((double)(x2),(double)(y2)) - PI/2 ))		reponse bizarre

// on y va pas a pas :
#define		_dangleIQdIdQbrut(x2,x1,y2,y1)	petit_angle(atan2((x1),(y1)) - atan2((x2),(y2)))
//#define		_dangleIQdIdQ(x2,x1,y2,y1)		( _dangleIQdIdQbrut(x2,x1,y2,y1) + PI/2 )
// enlever PI puis changer le signe
//#define		_dangleIQdIdQ(x2,x1,y2,y1)		( _dangleIQdIdQbrut(x2,x1,y2,y1) - PI/2 )
#define		_dangleIQdIdQ(x2,x1,y2,y1)		petit_angle( -PI/2 - _dangleIQdIdQbrut(x2,x1,y2,y1))		// je veux une courbe croissante

// ancienne definition de dphase
#define _dphase(x2,x1,y2,y1)	(petit_angle(atan2(x1,y1)-atan2(x2,y2)))
// je remplace  sin(dphase)  par  -cos(dangle)
//  dangle = -PI/2 - dphase  ==>  cos(dangle) = cos(PI/2 + phase) = -sin(dphase)

#define	_amplitude(a,b)			(sqrt((a)*(a)+(b)*(b)))
//#define	_amplitude(a,b)			hypot((a), (b))	// C99 - But slower than sqrt by at best 15%

#define  new_chg_coor(chc)	{(chc)->offset.x = 0;(chc)->offset.y = 0;(chc)->grossissement = 1;(chc)->dalpha.a = 0;(chc)->inv = 1;_valide_angle((chc)->dalpha);}

// copie l'etalon matrice sauve dans une structure entiere   dans une structure de type  Chg_coor
#define _copie_chg(chg,etalon_matrice_X)	{\
		(chg)->grossissement =_grossissement_uphys_pixel(etalon_matrice_X); \
		(chg)->inv=_inversion_chc_pixel(etalon_matrice_X);\
		(chg)->offset.x=_centre_matrice_x(etalon_matrice_X);\
		(chg)->offset.y=_centre_matrice_y(etalon_matrice_X);\
		(chg)->dalpha.a=_decalage_rotation(etalon_matrice_X);\
		_valide_angle((chg)->dalpha);}


#define	_chg_etalon(etalon_matrice_X)		{\
		_grossissement_uphys_pixel(etalon_matrice_X),\
		{_decalage_rotation(etalon_matrice_X),\
		 cos(_decalage_rotation(etalon_matrice_X)),\
		 sin(_decalage_rotation(etalon_matrice_X))\
		},\
		_inversion_chc_pixel(etalon_matrice_X),\
		{_centre_matrice_x(etalon_matrice_X) ,_centre_matrice_y(etalon_matrice_X) } }



/*  Les data xoffset et yoffset donnees par le telescope sont en azel

Quand on recupere le pointage sur le ciel il faut:
--------------  choix de l'orientation de la carte: fixe sur le ciel ou fixe sur la matrice
1)  si l'on travaille avec carte en radec
		definir un pointage en faisant la rotation sur xy    de  - angle_paralactique
		definir un Chg_coor avec pour angle   alpha = angle paralactique + elevation + dalpha (de l'etalonnage)
		On peut ensuite utiliser les define generaux

1)  si l'on travaille avec carte en azel
		definir le pointage avec x,y =  valeur xy directe
		definir un Chg_coor avec pour angle   alpha =  elevation + PI + dalpha (de l'etalonnage)
		On peu ensuite utilisr les define generaux

2) si l'on travaille avec carte en coordonnees matrice
	- definir un pointage en faisant la rotation sur xy    elevation + PI
	- definir un Chg_coor avec pour angle   dalpha (de l'etalonnage)
		On peut ensuite utiliser les define generaux

a) si l'on travaille en valeur brutes, on trace chaque bolo au point de coordonnees x,y donnee par le telescope
b) si l'on travaille
*/

// pour faire la rotation sur le pointage venant du ciel
// singe,inversion		signe vaut +1 ou -1 pour rotation angle oppose
//					inversion vaut +1 ou -1 pour changement du signe x (image dans un mirroir)

#define		_X_rot(xy,teta)	(xy.x*teta.cos+xy.y*teta.sin)
#define		_Y_rot(xy,teta)	(xy.y*teta.cos-xy.x*teta.sin)// pour faire la rotation sur le pointage venant du ciel



// idem, mais prend en compte le undef_double
#define		_X_rot_def(xy,teta)	((xy.x==undef_double)||(xy.y==undef_double)?undef_double:_X_rot(xy,teta))
#define		_Y_rot_def(xy,teta)	((xy.x==undef_double)||(xy.y==undef_double)?undef_double:_Y_rot(xy,teta))

#define		_rotation(xy,teta)		{Angle ang;ang.a=teta;_valide_angle(ang);double x = _X_rot(xy,ang);double y = _Y_rot(xy,ang);xy.x=x;xy.y=y;}

/* pour obtenir la position physique d'un pixel de la matrice sur le ciel lorsque le telescope pointe en 0,0
		-  la position du pixel en pixel :							Point		pix;
		-	le changement de coordonnees etalonnIE???a?a(C)e precedemment		Chg_coor	chc;
*/
//#define	_X_ciel0(pix,chc)	((((pix.x-chc.offset.x)*chc.dalpha.cos-(pix.y-chc.offset.y)*chc.dalpha.sin)*chc.grossissement))
//#define	_Y_ciel0(pix,chc)	((((pix.y-chc.offset.y)*chc.dalpha.cos+(pix.x-chc.offset.x)*chc.dalpha.sin)*chc.grossissement))
//#define	_X_ciel0(pix,chc)	((chc).inv*(((pix.x-(chc).offset.x)*(chc).dalpha.cos+(pix.y-(chc).offset.y)*(chc).dalpha.sin)*(chc).grossissement))
//#define	_Y_ciel0(pix,chc)	((((pix.y-(chc).offset.y)*(chc).dalpha.cos-(pix.x-(chc).offset.x)*(chc).dalpha.sin)*(chc).grossissement))
#define		_X_ciel0(pix,chc)	((((chc).inv*(pix.x-(chc).offset.x)*(chc).dalpha.cos+(pix.y-(chc).offset.y)*(chc).dalpha.sin)*(chc).grossissement))
#define		_Y_ciel0(pix,chc)	((((pix.y-(chc).offset.y)*(chc).dalpha.cos-(chc).inv*(pix.x-(chc).offset.x)*(chc).dalpha.sin)*(chc).grossissement))

// idem, mais prend en compte le undef_double
#define		_X_ciel0_def(pix,chc)	((pix.x==undef_double)||(pix.y==undef_double)?undef_double:_X_ciel0(pix,(chc)))
#define		_Y_ciel0_def(pix,chc)	((pix.x==undef_double)||(pix.y==undef_double)?undef_double:_Y_ciel0(pix,(chc)))

//#define		_chc_X(SS,n_bol)		(_matrice_A(n_bol)?chc_A:chc_B)

/* pour obtenir la position physique d'un pixel de la matrice sur le ciel, connaissant
		-  la position du pixel en pixel :							Point		pix;
		-	le changement de coordonnees etalonnee precedemment		Chg_coor	chc;
		-	le pointage sur le ciel									Point		xy;
*/
#define		_X_ciel(pix,chc,pointage_xy)		(pointage_xy.x - _X_ciel0(pix,chc) )
#define		_Y_ciel(pix,chc,pointage_xy)		(pointage_xy.y - _Y_ciel0(pix,chc) )

// idem, mais prend en compte le undef_double
#define		_X_ciel_def(pix,chc,pointage_xy)	((pix.x==undef_double)||(pix.y==undef_double)?undef_double:_X_ciel(pix,chc,pointage_xy))
#define		_Y_ciel_def(pix,chc,pointage_xy)	((pix.x==undef_double)||(pix.y==undef_double)?undef_double:_Y_ciel(pix,chc,pointage_xy))


/* pour obtenir la position sur la matrice d'un point de la carte   connaissant
		-   la position du pixel en pixel :							Point		pix;
		-	le changement de coordonnees etalonnIE???a?a(C)e precedemment		Chg_coor	chc;
		-	le pointage sur le ciel									Point		xy;
*/

//#define	_X_pixel(chc,xy)	((chc.inv*(xy.x)*chc.dalpha.cos-(xy.y)*chc.dalpha.sin) /chc.grossissement+chc.offset.x)
//#define	_Y_pixel(chc,xy)	(((xy.y)*chc.dalpha.cos+chc.inv*(xy.x)*chc.dalpha.sin)/chc.grossissement+chc.offset.y)
#define		_X_pixel(chc,xy)		(chc.inv*((xy.x)*chc.dalpha.cos-(xy.y)*chc.dalpha.sin) /chc.grossissement+chc.offset.x)
#define		_Y_pixel(chc,xy)		(((xy.y)*chc.dalpha.cos+(xy.x)*chc.dalpha.sin)/chc.grossissement+chc.offset.y)


// idem, mais prend en compte le undef_double
#define		_X_pixel_def(chc,xy)	((xy.x==undef_double)||(xy.x==undef_double)?undef_double:_X_pixel(chc,xy))
#define		_Y_pixel_def(chc,xy)	((xy.x==undef_double)||(xy.x==undef_double)?undef_double:_Y_pixel(chc,xy))

/*
Quand on travaille avec la table xy  il suffit de faire angle paralactique + elevation = 0
Le changement de coordonnees a alors pour angle  dalpha
Que l'on fasse la carte en radec ou en coordonnees matrice ne change rien
*/


/*
pour calculer l'origineX a partir de chc.offset.x et y  il suffit d'appliquer  _X_ciel0 au pixel de coordones 0,0 apres avoir defini chc
pour calculer les offset a partir de origineX et origineY :
		-  definir un chc avec offset=0
		-  calculer  _X_pixel(chc,origine)	: on trouve  l'offset
*/


// pour faire la difference entre deux angles et etre sur de tomber entre -PI et +PI
#define  _dif_angle(a,b)	( (((a)-(b))>PI) ? ((a)-(b)-2*PI) : (((a)-(b))< -1*PI) ? ((a)-(b)+2*PI) : ((a)-(b)))
//#define  _dif_angle(a,b)	((a-b))



//enum{_choix_radec,_choix_radec_pixel_th,_choix_azel,_choix_azel_pixel_th,_choix_matrice,_choix_matrice_pixel_th,_choix_sans_projection};
enum {_choix_radec,_choix_radec_pixel_th,_choix_azel,_choix_azel_pixel_th,_choix_matrice,_choix_matrice_pixel_th,_choix_sans_projection,_nb_choix_coordonnees};
#define _def_choix_coordonnees	char noms_coordonnees[_nb_choix_coordonnees][32]={"RaDec_brut","RaDec_pixel_th","AzEl_brut","AzEl_pixel_th","matrice_brut","matrice_pixel_th","sans projection"};

//----  nouvelles fonctions our le calcul de dUser
extern void	init_chc(Chg_coor *chc,Etalon_optique_matrice *etalon_matrice_X);
extern void	prepare_chc_radec(Chg_coor *chc,double rotation_etalon,double pointage_rotazel,double paralactic);
extern void	prepare_chc_azel(Chg_coor *chc,double rotation_etalon,double pointage_rotazel);



extern void	prepare_chc(int choix_coordonnees,Chg_coor *chc,double rotation_etalon,double pointage_rotazel,double paralactic);
extern void	prepare_pointage_xy(int choix_coordonnees,Point *pointage_xy,double pointage_rotazel,double paralactic);
extern void	position_pointage_bolo(Point *xy,int choix_coordonnees,Chg_coor chc,Point pointage_xy);


extern void radec_a_azel(double Ra,double Dec,double LST,double latitude,double *Az,double *El);
extern double calcul_derive_radec(double Ra,double Dec,double LST,double latitude);
extern double angle_paralactique(double Ra,double Dec,double LST,double latitude);




//================================================================================================================================
//===================				les definitions pour le calcul du pointage matrice				==============================
//================================================================================================================================

// ------  les defines suivants s'applique a une structure de type   &Gp->repere_pointage[z]

#define _centre_matrice_x(etalon)				(0.001*(double)(etalon)->x0)
#define _centre_matrice_y(etalon)				(0.001*(double)(etalon)->y0)
#define _inversion_chc_pixel(etalon)			((etalon)->g>0?1:-1)	// l'effet miroir (ou pas) pour l'identification des pixels d'une matrice
#define _grossissement_uphys_pixel(etalon)		(0.001*(double)( _inversion_chc_pixel(etalon) * (etalon)->g))	// le grossissement en unites physiques (mm, murad,...) par pixel
#define _decalage_rotation(etalon)				(0.000001*(double)(etalon)->alpha)


#define _IRAM_latitude						(37.065941*PI/180.)


// position des detecteurs dans le param
#define	_Xpix(dhs,n_bol)				((double)_param_d((dhs),_pd_X,n_bol)/1000.)		// en pixels
#define	_Ypix(dhs,n_bol)				((double)_param_d((dhs),_pd_Y,n_bol)/1000.)		// en pixels



//===================================   les conversions d'unite pour passer du pointage elvin et brut en entier,  data en double  =================================
#define _d2ra(a)	(0.000001*(double)(a)*PI/180.)	 					// ce sont des mircrodegres convertis en radians
#define _r2ra(a)	(0.000001 * (double)(a) )							// ce sont des mircroradians convertis en radians
#define _r2mr(a)	( (180.*3600.) / (PI * 1e6) *  (double)(a) )			// je passe en seconde d'arc  pour les ofsets x et y 


#endif
