
#include "stdlib.h"
#include "stdio.h"
#include "string.h"
#include "math.h"

#include "rotation.h"
#include "a_memoire.h"
#include "a_def.h"

#include "kid_flag.h"


// ce fichier est dans la librairie de readdata mais c'est le seul de cette librairie appele par acquisition

//	contient la fonction  calcul_ftone_tangle_flagkid()
//	et les fonctions de compression/decompression

//int	calcul_ftone_tangle_flagkid(Data_header_shared_memory * dhs,int4* br,int nper, double* ftone,double* tangle,int* flagkid,int* timer)
//   cette fonction est utilisee par   hysto  ainsi que par  brut_to_data
// c'est elle qui cherche des valeurs dans le reglage pour les mettre dans les data

//   elle calcule ftone, l'angle et le flag qui seront mis dans les data
//  elle flag :
//		-	le tuning et le balayage du synthe
//		-	le flag de qualite qu'elle prend dans le param




/************************************************************
*				calcul_ftone_tangle_flagkid					*
************************************************************/

void	calcul_ftone_tangle_flagkid(Data_header_shared_memory * dhs,int4* br,int nper,
										double* ftone,double* tangle,int* flagkid)
{
int ndet,k;
int z;

// J'AI BESOIN DU REGLAGE POUR TROUVER ftone ainsi que les flag
for(z=0;z<dhs->nb_boites_mesure;z++)
	{
	uint4* RG_nikel=reglage_pointer(dhs,_r_nikel,z);
	uint4* RG_freq=reglage_pointer(dhs,_r_k_freq,z);
	uint4* RG_w=reglage_pointer(dhs,_r_k_width,z);
	if(RG_nikel && RG_freq)
			{
            int nn1 = _first_det_box(dhs,z);
			int nn2 = _last_det_box(dhs,z);
			k=0;
			for(ndet=nn1;ndet<nn2;ndet++)
				{

				//tangle[ndet]  = _brut_to_angle_IQdIdQ(dhs,br,nper,ndet);
				tangle[ndet]  =  0;
				int type_det=  _param_d((dhs), _pd_type, (ndet))  &0xffff ;
				if(	type_det ==	__kid_pixel)
					{
					tangle[ndet]= _dangleIQdIdQ(_brut_pdd(dhs,br,_dd_Q,nper)[ndet],_brut_pdd(dhs,br,_dd_dQ,nper)[ndet],_brut_pdd(dhs,br,_dd_I,nper)[ndet],_brut_pdd(dhs,br,_dd_dI,nper)[ndet]);
					}

				//ftone[ndet]	=	_brut_to_ftone(dhs,br,z,nper,ndet,RG_nikel,RG_freq[k]);
				ftone[ndet]	= 0.01*_brut_pb(dhs,br,_db_freq,z,nper) + kid_balayage_freq_par_binX(RG_nikel) * (double)RG_freq[k];

				//flagkid[ndet] =	_brut_to_flag(dhs,br,z,nper,ndet);
				if(RG_w)	flagkid[ndet] =  (int) ((_brut_pb(dhs,br,_db_masq,z,nper)&0x0f)	|
										(_flag_du_reglage(RG_w,ndet-nn1)&0xf0) );
				else		flagkid[ndet] =  (int) ((_brut_pb(dhs,br,_db_masq,z,nper)&0x0f)	|
										(_flag_du_paramd(dhs,ndet)&0xf0) );
				k++;
				}
			}
	}

}




/*************************************************************
*			comprime  et  decomprime les donnees brutes      *
*************************************************************/
// le tableau d'entiers data contient soit un bloc de brut, soit le meme en comprime
// ces fonctions comprimemnt et de-com-priment les donnees en place
// le tableau data doit etre assez grand pour les donnees brutes decom-primees
// prend chaque donnee commune et chaque donnee detecteur: cherche le vecteur 36 points de chaque detecteur det  pour chaque donnee  j
// je supprime les donnees periodes si elles existent


#define _comp_vector8	{	int decale=0;	\
		while(decale<24) {for(p=1;p<dhs->nb_pt_bloc;p++)	tableaudif[p] = tableaubrut[p] - tableaubrut[0];			\
		if(decale) for(p=1;p<dhs->nb_pt_bloc;p++)	tableaudif[p]=(tableaudif[p]>>decale)+( (tableaudif[p]>>(decale-1))&1);	\
		for(p=dhs->nb_pt_bloc-1;p>1;p--)	tableaudif[p] = tableaudif[p]-tableaudif[p-1];		\
		for(p=1;p<dhs->nb_pt_bloc;p++)	if( abs(tableaudif[p])>127)	break;					\
		if(p == dhs->nb_pt_bloc) break;	decale++;}		\
		tabint[0] = tableaubrut[0]; tabchar[0] = decale;  for(p=1;p<dhs->nb_pt_bloc;p++)	tabchar[p] = tableaudif[p];}


#define _decomp_vector8		{tableaubrut[0]=tabint[0];	int		decale = tabchar[0];			\
		for(p=1;p<dhs->nb_pt_bloc;p++)	tableaubrut[p]  = tableaubrut[p-1]  + (tabchar[p] << decale );}


void	comprime8(Data_header_shared_memory * dhs,int4* data)
{
int4  tableaubrut[36];
int4  tableaudif[36];
int4	tabint[10];
char*	tabchar =  (char*)(tabint+1);
//printf(" malloc avec %d , %d \n", dhs->nb_brut_d, dhs->nb_detecteurs);
int4*	data_comprime = malloc(_size_data_comprime8(dhs));
int k,ndet,p;
if(dhs->nb_pt_bloc != 36) return;	// ne comprime et decom-prime que les blocs de 36
for(k=0;k<dhs->nb_brut_c;k++)
		{
		for(p=0;p<dhs->nb_pt_bloc;p++)	tableaubrut[p] = _brut_ec(dhs,data,k,p);
		_comp_vector8
		//if(k==0)
			//if(tabchar[0])
					{
//					printf("\nvecteur commun k=%d  decale=%d ",k,tabchar[0]);
//					for(p=1;p<36;p++) printf("%d ",tabchar[p]);
					}
		for(p=0;p<10;p++) data_comprime[ p + 10 * k] = tabint[p];
		}

for(k=0;k<dhs->nb_brut_d;k++)
	for(ndet=0;ndet<dhs->nb_detecteurs;ndet++)
		{
		for(p=0;p<dhs->nb_pt_bloc;p++) tableaubrut[p] = _brut_ed(dhs,data,k,p)[ndet];
		_comp_vector8
		//if(k==2)
			//if(ndet==3)
				//if(tabchar[0])
					{
//					printf("\nvecteur k=%d  decale=%d ",k,tabchar[0]);
//					for(p=1;p<36;p++) printf("%d ",tabchar[p]);
					}

		for(p=0;p<10;p++) data_comprime[ p + 10 * (dhs->nb_brut_c +  dhs->nb_detecteurs * k +  ndet )] = tabint[p];
		}
memcpy(data,data_comprime,_size_data_comprime8(dhs));
free(data_comprime);
}


void	decomprime8(Data_header_shared_memory * dhs,int4* data)
{
int4  tableaubrut[36];
int4	tabint[10];
char*	tabchar =  (char*)(tabint+1);
int k,ndet,p;
if(dhs->nb_pt_bloc != 36) return;	// ne comprime et decomprime que les blocs de 36
int4*	data_comprime = malloc(_size_data_comprime8(dhs));

memcpy(data_comprime,data,_size_data_comprime8(dhs));

//printf("\n\nLe debut du bloc : ");for(p=0;p<100;p++)	{ if(p%10==0) printf("\n");printf("\t%x",data_comprime[p] );}

for(k=0;k<dhs->nb_brut_c;k++)
		{
		for(p=0;p<10;p++) tabint[p] = data_comprime[ p + 10 * k];
		_decomp_vector8
		//if(k==0)
			//if(tabchar[0])
					{
					//printf("\nvecteur commun k=%d  decale=%d ",k,tabchar[0]);
					//for(p=1;p<36;p++) printf("%d ",tabchar[p]);
					//printf("\nresult: ");
					//for(p=1;p<36;p++) printf("%d ",tableaubrut[p]);
					}

		for(p=0;p<dhs->nb_pt_bloc;p++)	_brut_ec(dhs,data,k,p) = tableaubrut[p] ;
		}

for(k=0;k<dhs->nb_brut_d;k++)
	for(ndet=0;ndet<dhs->nb_detecteurs;ndet++)
		{
		for(p=0;p<10;p++)  tabint[p] = data_comprime[ p + 10 * (dhs->nb_brut_c +  dhs->nb_detecteurs * k +  ndet) ];
		_decomp_vector8
		for(p=0;p<dhs->nb_pt_bloc;p++) _brut_ed(dhs,data,k,p)[ndet] = tableaubrut[p];
		}
free(data_comprime);
}


/*************************************************************
*			comprime  et  decomprime les donnees brutes      *
*************************************************************/
// le tableau d'entiers data contient soit un bloc de brut, soit le meme en comprime
// ces fonctions comprimemnt et de-com-priment les donnees en place
// le tableau data doit etre assez grand pour les donnees brutes decom-primees
// prend chaque donnee commune et chaque donnee detecteur: cherche le vecteur 36 points de chaque detecteur det  pour chaque donnee  j
// je supprime les donnees periodes si elles existent


#define _comp_vector10	{	int decale=0;	\
		while(decale<24) {for(p=1;p<dhs->nb_pt_bloc;p++)	tableaudif[p] = tableaubrut[p] - tableaubrut[0];			\
		if(decale) for(p=1;p<dhs->nb_pt_bloc;p++)	tableaudif[p]=(tableaudif[p]>>decale)+( (tableaudif[p]>>(decale-1))&1);	\
		for(p=dhs->nb_pt_bloc-1;p>1;p--)	tableaudif[p] = tableaudif[p]-tableaudif[p-1];		\
		for(p=1;p<dhs->nb_pt_bloc;p++)	if( abs(tableaudif[p])>500)	break;					\
		if(p == dhs->nb_pt_bloc) break;	decale++;}		\
		tabint[0] = tableaubrut[0]; tableaudif[0] = decale;		\
		for(p=0;3*p<dhs->nb_pt_bloc;p++)	\
		tabint[p+1] = (tableaudif[3*p]&0x03ff) | ((tableaudif[3*p+1]&0x03ff)<<10) | ((tableaudif[3*p+2]&0x03ff)<<20) ;}


#define _decomp_vector10		{tableaubrut[0]=tabint[0];	int	decale = tabint[1] & 0x3ff;			\
		for(p=1;p<dhs->nb_pt_bloc;p++)	\
			{int a = ((tabint[1+p/3]>>10*(p%3) ) & 0x3ff) ;if (a&0x200) a=a | 0xfffffc00;	\
			tableaubrut[p]  = tableaubrut[p-1]  + (a << decale );}}

#define _nb_mot	13
void	comprime10(Data_header_shared_memory * dhs,int4* data)
{
int4  tableaubrut[36];
int4  tableaudif[36];
int4	tabint[_nb_mot];		// le tableaubrut[0]  et les 12 valeurs de tableaudif
//printf(" malloc avec %d , %d \n", dhs->nb_brut_d, dhs->nb_detecteurs);
int4*	data_comprime = malloc(_size_data_comprime10(dhs));
int k,ndet,p;
if(dhs->nb_pt_bloc != 36) return;	// ne comprime et decom-prime que les blocs de 36
for(k=0;k<dhs->nb_brut_c;k++)
		{
		for(p=0;p<dhs->nb_pt_bloc;p++)	tableaubrut[p] = _brut_ec(dhs,data,k,p);
		_comp_vector10
		//if(k==0)
			//if(tabchar[0])
					{
//					printf("\nvecteur commun k=%d  decale=%d ",k,tabchar[0]);
//					for(p=1;p<36;p++) printf("%d ",tabchar[p]);
					}
		for(p=0;p<_nb_mot;p++) data_comprime[ p + _nb_mot * k] = tabint[p];
		}

for(k=0;k<dhs->nb_brut_d;k++)
	for(ndet=0;ndet<dhs->nb_detecteurs;ndet++)
		{
		for(p=0;p<dhs->nb_pt_bloc;p++) tableaubrut[p] = _brut_ed(dhs,data,k,p)[ndet];
		_comp_vector10
		//if(k==2)
			//if(ndet==3)
				//if(tabchar[0])
					{
//					printf("\nvecteur k=%d  decale=%d ",k,tabchar[0]);
//					for(p=1;p<36;p++) printf("%d ",tabchar[p]);
					}

		for(p=0;p<_nb_mot;p++) data_comprime[ p + _nb_mot * (dhs->nb_brut_c +  dhs->nb_detecteurs * k +  ndet )] = tabint[p];
		}
memcpy(data,data_comprime,_size_data_comprime10(dhs));
free(data_comprime);
}


void	decomprime10(Data_header_shared_memory * dhs,int4* data)
{
int4  tableaubrut[36];
int4	tabint[_nb_mot];
int k,ndet,p;
if(dhs->nb_pt_bloc != 36) return;	// ne comprime et decomprime que les blocs de 36
int4*	data_comprime = malloc(_size_data_comprime10(dhs));

memcpy(data_comprime,data,_size_data_comprime10(dhs));

//printf("\n\nLe debut du bloc : ");for(p=0;p<100;p++)	{ if(p%10==0) printf("\n");printf("\t%x",data_comprime[p] );}

for(k=0;k<dhs->nb_brut_c;k++)
		{
		for(p=0;p<_nb_mot;p++) tabint[p] = data_comprime[ p + _nb_mot * k];
		_decomp_vector10
		//if(k==0)
			//if(tabchar[0])
					{
					//printf("\nvecteur commun k=%d  decale=%d ",k,tabchar[0]);
					//for(p=1;p<36;p++) printf("%d ",tabchar[p]);
					//printf("\nresult: ");
					//for(p=1;p<36;p++) printf("%d ",tableaubrut[p]);
					}

		for(p=0;p<dhs->nb_pt_bloc;p++)	_brut_ec(dhs,data,k,p) = tableaubrut[p] ;
		}

for(k=0;k<dhs->nb_brut_d;k++)
	for(ndet=0;ndet<dhs->nb_detecteurs;ndet++)
		{
		for(p=0;p<_nb_mot;p++)  tabint[p] = data_comprime[ p + _nb_mot * (dhs->nb_brut_c +  dhs->nb_detecteurs * k +  ndet) ];
		_decomp_vector10
		for(p=0;p<dhs->nb_pt_bloc;p++) _brut_ed(dhs,data,k,p)[ndet] = tableaubrut[p];
		}
free(data_comprime);
}

#undef _nb_mot

