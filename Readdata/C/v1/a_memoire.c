#ifdef  _MANIPQT_
#include "mq_manip.h"
#else

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#endif


#include "def.h"
#include "def_opera.h"
#include "def_nikel.h"
#include "a_memoire.h"
#include "bloc.h"

#define debug 0
//#undef printf

#define		_IP(u)		(int)(((u)>>24)&0xff),(int)(((u)>>16)&0xff),(int)(((u)>>8)&0xff),(int)((u)&0xff)


//  pour afficher un numero IP : faire printf("%d,%d,%d,%d ",_IP(Num_ip) )


int mon_strcmp(char *a,char *b);
void remplace_anciens_param_reglages(Data_header_shared_memory *dhs,int print);


// pour que la comparaison de string ne tienne pas compte des majuscules
#undef strcmp
#define strcmp(a,b) 	mon_strcmp((char*)(a),(char*)(b))

int mon_strcmp(char *a,char *b) {
	char A,B;
	while( *a && *b ) {
		A=*a;
		if( (A >='A') && (A <= 'Z') ) A = A -'A' +  'A';
		B=*b;
		if( (B >='A') && (B <= 'Z') ) B = B -'A' +  'A';
		if(A != B)	return 1;
		a++;
		b++;
	}
	if(*a != *b)	return 1;
	return 0;
}


int _position_champ_reglage(Data_header_shared_memory *dhs, int i){
						uint4* chr = (uint4*) dhs->champ_reglage;
						return ( _version_courante_header(dhs) ? chr[6*(i)]   : (chr[3*(i)]&0xffff) );
						}


/************************************************
*            print_reglages				*
************************************************/
void		print_reglages(Data_header_shared_memory *dhs)       // affiche les valeures des reglages
{
int i,nc;
for(nc=0;nc<dhs->nb_champ_reglage;nc++)        //---   boucle sur tous les champs de reglage  -------
        {
        //int z=_acqbox_champ_reglage(dhs,nc);
        //int rtype=reglage_type(dhs,nc);
        //uint4* RG = reglage_pointer(dhs,rtype,z);
        uint4* RG = _sm_champ_reglage(dhs,nc);
        int l=_longueur_champ_reglage(dhs,nc);
        if(l)
                {
                if(l>10) l=10;
                printf("\n%d  %s ",nc,_sm_nom_champ_reglage(dhs,nc));
                for(i=0;i<l;i++) printf("  %d ",RG[i]);
                }
            
            
        }
}

/************************************************
*            print_noms_presents				*
************************************************/
void print_noms_presents(Data_header_shared_memory *dhs) {	// affiche les noms de toutes les variables presentes dans le fichier
	int p,k;
	printf("\n\n--------      print_noms_presents    -------------");
	printf("\n\n  nom d'experience  :    %s  ",_sm_nom_experiment(dhs));
	printf("   size header = %ld ",_size_bloc_header(dhs));
	printf("\n\n  on a  %d reglages  :",dhs->nb_champ_reglage);

	char *mes_reglages_type[_nb_type_reglage_possibles] = _chaines_reglage;
	for(p=0; p<dhs->nb_champ_reglage; p++) {
		int ok=0;
		for(k=0; k<_nb_type_reglage_possibles; k++) if(mon_strcmp(mes_reglages_type[k],_sm_nom_champ_reglage(dhs,p))) ok=1;
		if(ok) printf(" %s ",_sm_nom_champ_reglage(dhs,p));
		else	 printf(" $%s$ ",_sm_nom_champ_reglage(dhs,p));
	}

	printf("\n\n  on a  %d parametres  communs :",dhs->nb_param_c);
	for(p=0; p<dhs->nb_param_c; p++)
		printf(" %s ",_sm_nom_param_c(dhs,p));

	printf("\n\n  on a  %d parametres  detecteurs :",dhs->nb_param_d);
	for(p=0; p<dhs->nb_param_d; p++)
		printf(" %s ",_sm_nom_param_d(dhs,p));

	printf("\n\n  on a  %d brut  communs :",dhs->nb_brut_c);
	for(p=0; p<dhs->nb_brut_c; p++)
		printf(" %s ",_sm_nom_brut_c(dhs,p));

	printf("\n\n  on a  %d brut  detecteurs :",dhs->nb_brut_d);
	for(p=0; p<dhs->nb_brut_d; p++)
		printf(" %s ",_sm_nom_brut_d(dhs,p));

	printf("\n\n");


}
/************************************************
*               position_header					*
************************************************/
// ce programme alloue la place pour le tableau Data_header_position dhp.
// il stocke son adresse dans  _DHP  qui est  dhs->pointeur_dhp  avec un cast en pointeur
// pour le liberer, faire  free(_DHP(dhs));
void	position_header(Data_header_shared_memory *dhs,int print) {


	Data_header_position *dhp	= malloc(sizeof(Data_header_position));
	//Data_header_position * dhp	= malloc(1000);
	int z,i,q,pr,p;

	*(Data_header_position **) (&dhs->pointeur_dhp)  = dhp;
	//if(print)  printf("\n  creation DHP et ecriture pointeur %p  dans dhs ",dhp);



	if(print) printf("\n\n--------  position_header  %s    (version header  %d )   -------------",_sm_nom_experiment(dhs),_version_courante_header(dhs));

	remplace_anciens_param_reglages(dhs,print);

	dhp->P_tableau_reglage		= sizeof(Data_header_shared_memory)/4;
	dhp->P_nom_reglage			= dhp->P_tableau_reglage + + dhs->nb_champ_reglage*( _version_courante_header(dhs)? 6 : 3 );
	dhp->P_nom_param_c			= dhp->P_nom_reglage + dhs->nb_champ_reglage * ( _version_courante_header(dhs)? 4 : 2 ) ;
	dhp->P_nom_param_d			= dhp->P_nom_param_c + dhs->nb_param_c * ( _version_courante_header(dhs)? 4 : 2 ) ;
	dhp->P_val_reglage			= dhp->P_nom_param_d + dhs->nb_param_d * ( _version_courante_header(dhs)? 4 : 2 ) ;
	dhp->P_val_param_c			= dhp->P_val_reglage + (_position_champ_reglage(dhs,(dhs)->nb_champ_reglage-1)+_longueur_champ_reglage(dhs,(dhs)->nb_champ_reglage-1)) ;
	dhp->P_val_param_d			= dhp->P_val_param_c + dhs->nb_param_c;
	dhp->P_nom_brut_c			= dhp->P_val_param_d + dhs->nb_param_d * dhs->nb_detecteurs;
	dhp->P_nom_brut_d			= dhp->P_nom_brut_c  + dhs->nb_brut_c * ( _version_courante_header(dhs)? 4 : 2 ) ;
	dhp->P_nom_unite_data_c		= dhp->P_nom_brut_d  + dhs->nb_brut_d * ( _version_courante_header(dhs)? 4 : 2 ) ;
	dhp->P_nom_unite_data_d		= dhp->P_nom_unite_data_c  + dhs->nb_data_c * ( _version_courante_header(dhs)? 8 : 4 ) ;
	dhp->fin_header				= dhp->P_nom_unite_data_d  + dhs->nb_data_d * ( _version_courante_header(dhs)? 8 : 4 ) ;

	dhs->lg_header_util	= _len_header_util_shared_memory(dhs);	// la nouvelle longueur util du header
	dhs->lg_header_util	= dhp->fin_header*sizeof(int4);	// la nouvelle longueur util du header
	//printf("\n longueur du header :  %ld == %d \n",_len_header_util_shared_memory(dhs),dhs->lg_header_util);
	dhp->L_brut_c			= dhs->nb_brut_c ;
	dhp->L_brut_d			= dhs->nb_brut_d * dhs->nb_detecteurs ;
	dhp->L_brut_periode		= dhs->nb_detecteurs  * dhs->nb_brut_periode ;
	dhp->L_brut_total		= dhp->L_brut_c + dhp->L_brut_d + dhp->L_brut_periode;

	dhp->L_data_c			= dhs->nb_data_c ;;
	dhp->L_data_d			= dhs->nb_data_d * dhs->nb_detecteurs ;
	dhp->L_data_periode		= dhs->nb_detecteurs  * dhs->nb_brut_periode ;
	dhp->L_data_total		= dhp->L_data_c + dhp->L_data_d + dhp->L_data_periode;




	// rustine pour lire le run 5 : Nikel au lieu de nikel et Opera au lieu de opera
	for(p=0; p<dhs->nb_champ_reglage; p++) {
		if(!mon_strcmp("Nikel",_sm_nom_champ_reglage(dhs,p)+1)) {
			if(print) printf("\n enleve majuscule a %s ",_sm_nom_champ_reglage(dhs,p));
			strcpy(_sm_nom_champ_reglage(dhs,p)+1,"nikel");
		}
		if(!mon_strcmp("Opera",_sm_nom_champ_reglage(dhs,p)+1)) {
			if(print) printf("\n enleve majuscule a %s ",_sm_nom_champ_reglage(dhs,p));
			strcpy(_sm_nom_champ_reglage(dhs,p)+1,"opera");
		}
	}


	//---------------   table  des  reglages  possibles   -------------------------------
	char *mes_reglages_type[_nb_type_reglage_possibles] = _chaines_reglage;
	q=0;
	if(print) printf("\n\nREGLAGES :  ");
	for(z=0; z<_nb_max_acqbox; z++) {
		for(i=0; i<_nb_type_reglage_possibles; i++) {
			char ss[16];
			sprintf(ss,"%c%s",'A'+z,mes_reglages_type[i]);
			dhp->reglage_possibles[q++] = cherche_indice_champ_reglage(dhs,ss,print);
		}
	}


	//---------------   table  des  param  possibles   -------------------------------
	char *mes_param_simple[_nb_param_simple_possibles]=_chaines_param_simple;
	char *mes_param_box[_nb_param_box_possibles]=_chaines_param_box;
	char *mes_param_detecteur[_nb_param_detecteur_possibles]=_chaines_param_detecteur;
	if(print) printf("\n\nPARAMS  :  ");
	pr=1;
	q=0;
	for(i=0; i<_nb_param_simple_possibles; i++)	dhp->param_possibles[q++]= cherche_pointeur_param(dhs,mes_param_simple[i],print);
	for(z=0; z<_nb_max_acqbox; z++) {
		if(print && pr && (z<dhs->nb_boites_mesure) ) {
			printf("\n-- Box%c -- : ",'A'+z);
			pr=0;
		}
		for(i=0; i<_nb_param_box_possibles; i++) {
			char ss[16];
			sprintf(ss,"%c%s",'A'+z,mes_param_box[i]);
			dhp->param_possibles[q] = cherche_pointeur_param(dhs,ss,print);
			if( dhp->param_possibles[q++] ) pr=1;
		}
	}
	if(print) {
		printf("\n DETECTORS :      ");
		pr=0;
	}
	for(i=0; i<_nb_param_detecteur_possibles; i++)
		dhp->param_possibles[q++] =  cherche_pointeur_param(dhs,mes_param_detecteur[i],print);



	//---------------   table  des  brut  possibles   -------------------------------
	char *mes_data_simple[_nb_data_simple_possibles]=_chaines_data_simple;
	char *mes_data_box[_nb_data_box_possibles]=_chaines_data_box;
	char *mes_data_detecteur[_nb_data_detecteur_possibles]=_chaines_data_detecteur;
	if(print) printf("\n\nBRUT  :  ");
	pr=1;
	q=0;
	for(i=0; i<_nb_data_simple_possibles; i++)		dhp->brut_possibles[q++] = cherche_indice_brut_commun(dhs,mes_data_simple[i],print);

	for(z=0; z<_nb_max_acqbox; z++) {
		if(print && pr && (z<dhs->nb_boites_mesure) ) {
			printf("\n --Box%c-- :  ",'A'+z);
			pr=0;
		}
		for(i=0; i<_nb_data_box_possibles; i++) {
			char ss[16];
			sprintf(ss,"%c%s",'A'+z,mes_data_box[i]);
			dhp->brut_possibles[q] = cherche_indice_brut_commun(dhs,ss,print);
			if(dhp->brut_possibles[q++]>=0) pr=1;
		}
	}
	if(print) {
		printf("\n  DETECTOR :   ");
		pr=0;
	}
	for(i=0; i<_nb_data_detecteur_possibles; i++)		dhp->brut_possibles[q++] = cherche_indice_brut_detecteur(dhs,mes_data_detecteur[i],print);



	//---------------   table  des  data  possibles   -------------------------------
	if(print) printf("\n\nDATA  :  ");
	pr=1;
	q=0;
	for(i=0; i<_nb_data_simple_possibles; i++)		dhp->data_possibles[q++] = cherche_indice_data_commun(dhs,mes_data_simple[i],print);
	for(z=0; z<_nb_max_acqbox; z++) {
		if(print && pr && (z<dhs->nb_boites_mesure) ) {
			printf("\n --Box%c-- :  ",'A'+z);
			pr=0;
		}
		for(i=0; i<_nb_data_box_possibles; i++) {
			char ss[16];
			sprintf(ss,"%c%s",'A'+z,mes_data_box[i]);
			dhp->data_possibles[q] = cherche_indice_data_commun(dhs,ss,print);
			if(dhp->data_possibles[q++]>=0) pr=1;
		}
	}
	if(print) {
		printf("\n  DETECTORS :    ");
		pr=0;
	}
	for(i=0; i<_nb_data_detecteur_possibles; i++)	dhp->data_possibles[q++] = cherche_indice_data_detecteur(dhs,mes_data_detecteur[i],print);


	int acqbox=-2;
	int array;
	int n0,n1;
	if(print) printf("\n\n-----------    liste des boites d'acquisitions   et de leur reglages   ---------------------");



	for(p=0; p<dhs->nb_champ_reglage; p++) {
		//printf("\n p=%d  boite %c  position%d  length %d ",p,'A'+_acqbox_champ_reglage(dhs,p),_position_champ_reglage(dhs,p),_longueur_champ_reglage(dhs,p));
		if(acqbox != _acqbox_champ_reglage(dhs,p)) { // chaque fois que j'aborde une nouvelle boite
			//printf("\n----  old box = %d  lecture box %d (champ %d)",acqbox,_acqbox_champ_reglage(dhs,p),p);
			acqbox	= _acqbox_champ_reglage(dhs,p);
			//printf(" acqbox=%d \n",acqbox);
			array	= _array_champ_reglage(dhs,p);
			//printf(" array=%d \n",array);
			n0		= _first_det_champ_reglage(dhs,p);
			//printf(" n0=%d \n",n0);
			n1		= _nb_det_champ_reglage(dhs,p);
			//printf(" n1=%d \n",n1);
			if(print) printf("\n%c %s (%d)  \tdetect %4d \t.. %4d ",'A'+acqbox,_nom_acqbox(dhs,acqbox),array,n0,n0+n1);
			//printf("\n%d %s   \tdetect %4d \t.. %4d ",acqbox,_nom_acqbox(dhs,acqbox),n0,n0+n1);
			if(n0+n1 > dhs->nb_detecteurs) printf("\n*****  erreur: trop de detecteurs   box%d n0=%d n1=%d  dhs->nb_detecteurs=%d  *******\n"
													  ,acqbox,n0,n1,dhs->nb_detecteurs);
			else	if(n1) for(i=n0; i<n0+n1; i++) if(_presence_param_d(dhs,_pd_type)) {
						// rustine pour convertir les anciens types en puissance de 10
						/*  //ab  supprime la rustine pour lire les anciens types en puissance de 10
										if((_param_d(dhs,_pd_type,i) /10)%100  ==0)
											{
											_param_d(dhs,_pd_type,i) = _param_d(dhs,_pd_type,i) %1000;
											//printf("\n ancien type = %d ",_param_d(dhs,_pd_type,i) );
											}
						*/
						_param_d(dhs,_pd_type,i) = _type_det(dhs,i) + (acqbox<<16) + (array<<24);
						//printf("\n %d :  type=  %d   acqbox=%d  param_d = %x   ",i,_type_det(dhs,i) ,acqbox,_param_d(dhs,_pd_type,i) );
					}
		}
		if(print) printf("\tRg%d : %s  ",p,_sm_nom_champ_reglage(dhs,p));
	}

	if(print) printf("\n--------------------------------------------------------------------------------------------\n");


	//=========================================================================================================================
	//======================================        calcul  de  l'echantillonage_nano   		===============================
	//=========================================================================================================================
	dhs->echantillonnage_nano = 0;
	uint4 *RG_nikel=reglage_pointer_nikel_amc(dhs,-1);
	//printf("\n RGnikel = %d ",(int)RG_nikel);
	if(RG_nikel) {
		dhs->echantillonnage_nano = _echantillonnage_nano_kid(dhs,RG_nikel);
		if(print) printf("\n  mesure  kid  avec boite  nikel  \n");
	} else {
		uint4 *RG_opera=reglage_pointer(dhs,_r_opera,-1);
		if(RG_opera) {
			if(print) printf("\n mesure  bolo  avec opera \n");
			dhs->echantillonnage_nano = (int)(1e9 * _echantillonnage_bolo(RG_opera));
			//dhs->echantillonnage_nano =1000;
		}
	}
	if(!dhs->echantillonnage_nano) printf("\n\n$$$$$$$$$   ERROR   dhs->echantillonnage_nano = 0  $$$$$$$$$$\n");
	if(print) printf("\n-----  dhs->echantillonnage_nano = %d ",dhs->echantillonnage_nano);

	//==========================   fin   ============
	return;
}

/********************************************************
*						compare_header					*
********************************************************/
//enum {header_identiques,header_dif_reglage,header_dif_param_d,header_dif_param_c,header_dif_noms_reglage_param,header_dif_longueur,header_dif_nom};
int			compare_header(Data_header_shared_memory   *dhs1,Data_header_shared_memory   *dhs2) {
	int i,n,p;
	if(mon_strcmp(_sm_nom_experiment(dhs1),_sm_nom_experiment(dhs2))) {
		printf("\n headers avec nom d'experience different :name1= %s  ->  name2= %s ",_sm_nom_experiment(dhs1),_sm_nom_experiment(dhs2));
		return header_dif_nom;
	}


	if(dhs1->lg_header_util != dhs2->lg_header_util)
        {
		printf("\n headers avec longueur totale differente, je continue :  %d  ->  %d ",dhs1->lg_header_util,dhs2->lg_header_util);
	//	return header_dif_longueur;
        }

	// une difference dans les champs de reglages ou dans le noms de param
	/*n= (_len_infos_reglage_param_shared_memory(dhs1)-sizeof(Data_header_shared_memory))/4;
	for(i=0;i<n;i++) if(dhs1->champ_reglage[i]!=dhs2->champ_reglage[i])
		{
		printf("\n headers avec une difference dans les noms de reglage ou de param  n=%d  i=%d ",n,i);
		i-=4;
		printf("  //   %s  -> %s  ",(char*)(dhs1->champ_reglage+i),(char*)(dhs2->champ_reglage+i));
		i+=4;
		printf("  //   %s  -> %s  ",(char*)(dhs1->champ_reglage+i),(char*)(dhs2->champ_reglage+i));
		i+=4;
		printf("  //   %s  -> %s  ",(char*)(dhs1->champ_reglage+i),(char*)(dhs2->champ_reglage+i));
		return header_dif_noms_reglage_param;
		}
	*/


	for(p=0; p<dhs1->nb_champ_reglage; p++)	if(mon_strcmp(_sm_nom_champ_reglage(dhs1,p),_sm_nom_champ_reglage(dhs2,p))) {
			printf("\n headers avec noms de reglage differents  :  %s -> %s ",
				   _sm_nom_champ_reglage(dhs1,p),_sm_nom_champ_reglage(dhs2,p));
			return header_dif_noms_reglage_param;
		}

	for(p=0; p<dhs1->nb_param_c; p++)	if(mon_strcmp(_sm_nom_param_c(dhs1,p),_sm_nom_param_c(dhs2,p)
												   ))	{
			printf("\n headers avec noms de  param_c differents  :  %s -> %s ",
				   _sm_nom_param_c(dhs1,p),_sm_nom_param_c(dhs2,p));
			return header_dif_noms_reglage_param;
		}

	for(p=0; p<dhs1->nb_param_d; p++)	if(mon_strcmp(_sm_nom_param_d(dhs1,p),_sm_nom_param_d(dhs2,p))) {
			printf("\n headers avec noms de  param_d differents  :  %s -> %s ",
				   _sm_nom_param_d(dhs1,p),_sm_nom_param_d(dhs2,p));
			return header_dif_noms_reglage_param;
		}

	for(p=0; p<dhs1->nb_brut_c; p++)	if(mon_strcmp(_sm_nom_brut_c(dhs1,p),_sm_nom_brut_c(dhs2,p))) {
			printf("\n headers avec noms de brut_c  differents  :  %s -> %s ",
				   _sm_nom_brut_c(dhs1,p),_sm_nom_brut_c(dhs2,p));
			/*
			printf("\n\n *********************************   dhs1   ***********************************");
			print_noms_presents(dhs1);
			printf("\n\n *********************************   dhs2  ***********************************");
			print_noms_presents(dhs2);
			*/
			return header_dif_noms_reglage_param;
		}

	for(p=0; p<dhs1->nb_brut_d; p++)	if(mon_strcmp(_sm_nom_brut_d(dhs1,p),_sm_nom_brut_d(dhs2,p))) {
			printf("\n headers avec noms de brut_d  differents  :  %s -> %s ",
				   _sm_nom_brut_d(dhs1,p),_sm_nom_brut_d(dhs2,p));
			return header_dif_noms_reglage_param;
		}


	// une difference dans les valeurs de param_c (je saute le nom d'experience deja teste
	for(i=4; i<dhs1->nb_param_c; i++) if(_sm_param_c(dhs1,0)[i]!=_sm_param_c(dhs2,0)[i]) {
			printf("\n headers avecavec differences dans les parametres communs  :  i=%d   %s = %d -> %d  ",
				   i,_sm_nom_param_c(dhs1,i), _sm_param_c(dhs1,0)[i],_sm_param_c(dhs2,0)[i]);
			return header_dif_param_c;
		}

	// une difference dans les valeurs de param_d
	//n=dhs1->nb_param_d*dhs1->nb_detecteurs;
	//for(i=0;i<n ;i++) if(_sm_param_d(dhs1,0)[i]!=_sm_param_d(dhs2,0)[i])

	for(n=0; n<dhs1->nb_detecteurs; n++)
		for(i=0; i<dhs1->nb_param_d; i++)
			if(_sm_param_d(dhs1,i)[n]!=_sm_param_d(dhs2,i)[n]) {
				printf("\nrecut headers avec differences dans les parametres detecteurs  i=%d :  %s[%d] = %d -> %d ",
					   i,_sm_nom_param_d(dhs1,i),i,_sm_param_d(dhs1,i)[n],_sm_param_d(dhs2,i)[n]);
				return header_dif_param_d;
			}

	// une difference dans les valeurs du reglage
	n=_len_reglage_shared_memory(dhs1)/4;
	for(i=0; i<n; i++) if(_sm_champ_reglage(dhs1,0)[i]!=_sm_champ_reglage(dhs2,0)[i]) {
			//printf(" diff reglages : ");
			return header_dif_reglage;
		}

	return header_identiques;
}


/********************************************************
*          remplace_anciens_param_reglages				*
********************************************************/

#define _nb_reglage_remplace 18
void remplace_anciens_param_reglages(Data_header_shared_memory *dhs,int print) {
	int i,p;

	//=========================================================================================================================
	//=====================             remplacement des anciens param par les nouveaux          ===========================
	//=========================================================================================================================
#define _nb_param_remplace 9
	char *anciens_global_param[_nb_param_remplace]= {"ip_op","ip_kA","ip_kB","ip_kC","port_op","port_kA","port_kB","syntheA","syntheB"};
	char *remplace_global_param[_nb_param_remplace]= {"A_ip","B_ip","C_ip","D_ip","A_port","B_port","C_port","Bsynthe","Csynthe"};

	for(p=0; p<dhs->nb_param_c; p++) {
		//printf("\n cherche a remplacer  %s  ",_sm_nom_param_c(dhs,p));
		for(i=0; i<_nb_param_remplace; i++)
			if(!mon_strcmp(_sm_nom_param_c(dhs,p),anciens_global_param[i]))
				strcpy(_sm_nom_param_c(dhs,p),remplace_global_param[i]);
	}

	//printf("\n******  liste des param possibles  ");
	//for(i=0;i<_nb_param_possibles;i++) printf("\n  param possible%d  : %s",i,global_param[i]);

	char *anciens_global_reglage[_nb_reglage_remplace]= {"horloge","mpi","mux","equi","b_rg1","b_rg2","kid_A","kid_B","kid_C","kid_D","k_freqA","k_freqB","k_freqC","k_freqD","k_nivA","k_nivB","k_nivC","k_nivD"}; // dimensioner Dhs->nb_detecteurs
	char *remplace_global_reglage[_nb_reglage_remplace]= {"AOpera","Ao_mpi","Ao_mux","Ao_equi","Ao_rg1","Ao_rg2","BNikel","CNikel","DNikel","ENikel","Bk_freq","Ck_freq","Dk_freq","Ek_freq","Bk_niv","Ck_niv","Dk_niv","Ek_niv"}; // dimensioner Dhs->nb_detecteurs

	int flag_ancien=0;
	for(p=0; p<dhs->nb_champ_reglage; p++) {
		//	printf("\n  reglage : %s ==> ",_sm_nom_champ_reglage(dhs,p));
		for(i=0; i<_nb_reglage_remplace; i++)
			if(!mon_strcmp(_sm_nom_champ_reglage(dhs,p),anciens_global_reglage[i])) {
				if(!mon_strcmp(_sm_nom_champ_reglage(dhs,p),"horloge"))  flag_ancien=flag_ancien | 1;		// une boite opera
				if(!mon_strcmp(_sm_nom_champ_reglage(dhs,p),"kid_A"))	flag_ancien=flag_ancien | 2;		// une boite kid
				//				printf("remplace %s  par  %s  ",_sm_nom_champ_reglage(dhs,p),remplace_global_reglage[i]);
				strcpy(_sm_nom_champ_reglage(dhs,p),remplace_global_reglage[i]);
			}
	}

	//=========================================================================================================================
	//=====================             remplacement des anciens brut par les nouveaux          ===========================
	//=========================================================================================================================




#define _nb_brut_remplace 11
	char *anciens_global_brut[_nb_brut_remplace]= {"t_opera","t_kidA","t_kidB",\
			"freq_A", "freq_B","msq_A","msq_B","nv_dacA", "nv_dacB","nv_adcA","nv_adcB"
												  };
	char *remplace_global_brut[_nb_brut_remplace]= {"A_t_utc","B_t_utc","C_t_utc",\
			"B_freq","C_freq","B_masq","C_masq","B_n_inj","C_n_inj","B_n_mes","C_n_mes"
												   }; // dimensioner Dhs->nb_detecteurs


	for(p=0; p<dhs->nb_brut_c; p++)
		for(i=0; i<_nb_brut_remplace; i++)
			if(!mon_strcmp(_sm_nom_brut_c(dhs,p),anciens_global_brut[i]))
				strcpy(_sm_nom_brut_c(dhs,p),remplace_global_brut[i]);




	//=========================================================================================================================
	//====================            Dans le cas ou je remplace des anciens reglages par des nouveaux          ===============
	//====================            je fabrique les parametres acqbox,  array  et num det                     ===============
	//=========================================================================================================================
	if(flag_ancien && print) 	printf("\n\n==============================================================================================");

	if(flag_ancien && (_version_courante_header(dhs)>0)) {
		printf(" ------  ERROR  :   _version_courante_header = %d  avec des anciens kid \n\n",_version_courante_header(dhs));
		flag_ancien = 0;
	}

	if(flag_ancien == 1) {
		int n=0;
		if(print) printf("\n====== remplacement reglage ancien fichier opera seul  mode bolo 0 .. %d  ",dhs->nb_detecteurs);
		// je rajoute juste le nombre de detecteurs dans le 1er champ
		dhs->champ_reglage[3*n+1]	=	(dhs->champ_reglage[3*n+1]&0xffff) |  (dhs->nb_detecteurs<<16);
	}

	if( (flag_ancien == 2) && print )	printf("\n====== remplacement reglage ancien fichier kid seul  sans  opera  ");


	if( (flag_ancien == 3) && print )	printf("\n====== remplacement reglage ancien fichier kid  avec   opera  ");


	if(flag_ancien & 2)		// dans tous les cas ou il y a des kid

	{
		int array = 1;
		int numdet=0;
		// je balaye les champs de type  Nikel pour rajouter les num detecteurs de chaque boite (400 par boite)
		// je mets aussi un array pour chaque boite : 1 et 2
		for(p=0; p<dhs->nb_champ_reglage; p++) {
			if(!mon_strcmp(_sm_nom_champ_reglage(dhs,p)+1,"Opera")) {
				if(print) printf("\n======  reglage %d : %s  ",p,_sm_nom_champ_reglage(dhs,p));
			}
			if(!mon_strcmp(_sm_nom_champ_reglage(dhs,p)+1,"Nikel")) {
				if(print) printf("\n======  reglage %d : %s   array %d   detecteurs %d .. %d ",p,_sm_nom_champ_reglage(dhs,p),array,numdet,numdet+400);
				dhs->champ_reglage[3*p]		=	(dhs->champ_reglage[3*p]&0xffff)    | (numdet<<16) ;
				dhs->champ_reglage[3*p+1]	=	(dhs->champ_reglage[3*p+1]&0xffff)  | (400<<16);
				dhs->champ_reglage[3*p+2]	=	(dhs->champ_reglage[3*p+2]&0xff)	| (array<<8);
				array++;
				numdet+=400;
			}
		}
	}


	if(flag_ancien && print ) 	printf("\n==============================================================================================\n\n");

}


// pour la recherche des noms dans la carte roach je redefini mon_strcmp en inversant les octets par 4
//#ifdef __BIG_ENDIAN__
//#define mon_strcmp(a,b)	 ( (a[3]-b[0])?1: (a[2]-b[1])?1: (b[1]==0)?0: (a[1]-b[2])?1: (b[2]==0)?0: (a[0]-b[3])?1: (b[3]==0)?0:  (a[7]-b[4])?1: (b[4]==0)?0: (a[6]-b[5])?1: (b[5]==0)?0: (a[5]-b[6])?1: (b[6]==0)?0: (a[4]-b[7]==0)?0: 1)
//#endif


//============================================================================================================
//============================================================================================================
//=========================    les nouvelles fonctions pour trouver les reglages   ===========================
//============================================================================================================
//============================================================================================================


/****************************************************
*			cherche_indice_champ_reglage			*
****************************************************/
// utilise uniquement pour construire la table de recherche rapide   irg[]
//  et pour l'envoie d'une commande par nom de champ reglage
int cherche_indice_champ_reglage(Data_header_shared_memory *dhs,char *nom_champ,int print) {
	int p;
	//printf("\ncherche champ");
	for(p=0; p<dhs->nb_champ_reglage; p++) {
		//printf(" p=%d  : %s ",p,_sm_nom_champ_reglage(dhs,p));
		if(!mon_strcmp(_sm_nom_champ_reglage(dhs,p),nom_champ)) {
			if(print) printf("  ch%d= %s  ",p,nom_champ);
			return p;
		}
	}
	return -1;
}



/****************************************************
*				reglage_champ						*
****************************************************/
// retourne le numero du champ de reglage  (-1 si pas de reglage)
// type_reglage est le type de reglage dans l'enum des reglages
// z est le numero de la boite.
//  Si z==-1, cherche le reglage de ce type dans la premiere boite
//  si type_reglage==-1,  cherche le premier type reglage de la boite z
int	reglage_champ(Data_header_shared_memory *dhs,int type_reglage,int z) 
{
int nc;
	
if(z<0)
		{	
		char mes_reglages_type[_nb_type_reglage_possibles][16] = _chaines_reglage;
		for(nc=0; nc<dhs->nb_champ_reglage; nc++) 
				{
				char nom_champ[16];
				strcpy(nom_champ,_sm_nom_champ_reglage(dhs,nc)+1);
				if(!mon_strcmp(mes_reglages_type[type_reglage],nom_champ)) return nc;
				}
		return -1;
		
		}

if(type_reglage<0) 
		{
		for(nc=0; nc<dhs->nb_champ_reglage; nc++)
			if(_acqbox_champ_reglage(dhs, nc) == z)
				return nc;
		return -1;
		}

nc=_rpo(dhs) [ _nb_type_reglage_possibles*z+type_reglage] ;
return nc;
}



/****************************************************
*				reglage_type						*
****************************************************/
// retourne le type d'un reglage dont on connait le numero de champ
int	reglage_type(Data_header_shared_memory *dhs,int nc)
{
char* reglage_type[_nb_type_reglage_possibles] = _chaines_reglage;
int k;
for(k=0;k<_nb_type_reglage_possibles;k++)
            {
            //printf("\n p=%d k=%d   nom reglage=%s reglage_type[k]=%s ",p,k,_sm_nom_champ_reglage(dhs,p),reglage_type[k]);
            if(!mon_strcmp(_sm_nom_champ_reglage(dhs,nc)+1,reglage_type[k])) return k;
            }
return -1;
}

/****************************************************
*				reglage_parambox_associe			*
****************************************************/
// retourne le type du premier parambox associe a un reglage dont on donne le type
int	reglage_parambox_associe(int rtype)
{
int parambox_associe[_nb_type_reglage_possibles] =  _reglage_parambox_associe;
return ( parambox_associe[rtype] );
}
/****************************************************
*				reglage_pointer						*
****************************************************/
// retourne soit un pointeur au bon endroit sur la memoire dhs, soit un pointeur null
// type_reglage est le type de reglage dans l'enum des reglages
// z est le numero de la boite.
//  Si z==-1, cherche le reglage de ce type dans la premiere boite
//  si type_reglage==-1,  cherche le premier type reglage de la boite z
uint4	*reglage_pointer(Data_header_shared_memory *dhs,int type_reglage,int z) {
	int nc=reglage_champ(dhs,type_reglage,z);
	if(nc<0) return NULL;
	return _sm_champ_reglage(dhs,nc);
}

/****************************************************
*				reglage_pointer_nikel_amc						*
****************************************************/
// retourne soit un pointeur au bon endroit sur la memoire dhs, soit un pointeur null
// z est le numero de la boite.
//  Si z==-1, cherche le reglage de ce type dans la premiere boite
uint4	*reglage_pointer_nikel_amc(Data_header_shared_memory *dhs,int z) {
	int nc=reglage_champ(dhs,_r_nikel,z);
	if(nc<0) nc=reglage_champ(dhs,_r_amc,z);
	if(nc<0) nc=reglage_champ(dhs,_r_bside,z);
	if(nc<0) return NULL;
	return _sm_champ_reglage(dhs,nc);
}


/********************************************
*			first_box				*
*********************************************/
int		first_box(Data_header_shared_memory *dhs,int type_reglage) {
	int z;
	for (z=0; z<(dhs)->nb_boites_mesure; z++)
		if ( reglage_champ(dhs, type_reglage, z)>=0) return z;
	return -1;
}


/********************************************
*			first_box_nikel_amc				*
*********************************************/
int first_box_nikel_amc(Data_header_shared_memory *dhs) {
	int z;
	for (z=0; z<(dhs)->nb_boites_mesure; z++) {
		if ( reglage_champ(dhs, _r_nikel, z)>=0) return z;
		if ( reglage_champ(dhs, _r_amc, z)>=0) return z;
		if ( reglage_champ(dhs, _r_bside, z)>=0) return z;
	}
	return -1;
}


int first_box_nikel_amc_active(Data_header_shared_memory *dhs)
{
int z;
// je cherche d'abord la premiere amc
for (z=0; z<(dhs)->nb_boites_mesure; z++)
        {
		if(_param_b(dhs,_pb_enable,z))
            {
			if ( reglage_champ(dhs, _r_amc, z)>=0) return z;
            }
        }
	// s'il n'y en a pas, je cherche  la premiere bside
for (z=0; z<(dhs)->nb_boites_mesure; z++)
        {
		if(_param_b(dhs,_pb_enable,z))
            {
			if ( reglage_champ(dhs, _r_bside, z)>=0) return z;
            }
        }
	// s'il n'y en a pas, je cherche  la premiere nikel
for (z=0; z<(dhs)->nb_boites_mesure; z++)
        {
		if(_param_b(dhs,_pb_enable,z))
            {
			if ( reglage_champ(dhs, _r_nikel, z)>=0) return z;
            }
        }
return -1;
}



/****************************************************
*			nb_elements_reglage_partiel				*
****************************************************/
// retourne le nb d'elements total du reglage associe a la boite n
// retourne 0 si le bloc n'est pas un bon bloc reglage partiel existant

int nb_elements_reglage_partiel(Data_header_shared_memory *dhs,int z) {
	int i;
	int ll=0;
	for(i=0; i<dhs->nb_champ_reglage; i++)
		if( z==_acqbox_champ_reglage(dhs,i) )
			ll+=_longueur_champ_reglage(dhs,i);
	return ll;
}


/****************************************************
*			cherche_indice_enum_parambox			*
****************************************************/
int cherche_indice_enum_parambox(char *nom) {
	int i;
	char *chaine[_nb_param_box_possibles] = _chaines_param_box;
	for(i=0; i<_nb_param_box_possibles; i++)
		if(!mon_strcmp(nom+1,chaine[i]))	return i;
	return -1;
}


/****************************************************
*			cherche_pointeur_param					*
****************************************************/
// retourne soit un pointeur au bon endroit sur la memoire dhs, soit un pointeur null
int4 		*cherche_pointeur_param(Data_header_shared_memory *dhs,char *nom_indice,int print) {
	int4 *p;
	//printf("\ncherche indice param (%s)  avec dhs->nb_param_c=%d  dhs->nb_param_d=%d ",nom_indice,dhs->nb_param_c,dhs->nb_param_d);
	p=cherche_pointeur_param_communs(dhs,nom_indice,print);
	if(!p) p=cherche_pointeur_param_detecteurs(dhs,nom_indice,print);
	return p;
}


/****************************************************
*			cherche_pointeur_param_communs					*
****************************************************/
// retourne soit un pointeur au bon endroit sur la memoire dhs, soit un pointeur null
int4 		*cherche_pointeur_param_communs(Data_header_shared_memory *dh,char *nom_indice,int print) {
	int p;
	//printf("\ncherche indice param (%s)  avec dh->nb_param_c=%d  dh->nb_param_d=%d ",nom_indice,dh->nb_param_c,dh->nb_param_d);
	for(p=0; p<dh->nb_param_c; p++) {
		//printf(" p=%d  : %s ",p,_sm_nom_champ_reglage(dh,p));
		if(!mon_strcmp(_sm_nom_param_c(dh,p),nom_indice)) {
			if(print) printf("  %s",nom_indice);
			return _sm_param_c(dh,p);
		}

		//-------  rustine provisoire pour relire les fichiers contenant un "rt_bras" la ou on voudrait un "retard" dans le param
		if( (!mon_strcmp("retard",nom_indice)) && !mon_strcmp(_sm_nom_param_c(dh,p),"rt_bras")) {
			if(print) printf("  %s",nom_indice);
			return _sm_param_c(dh,p);
		}

		//-------  rustine provisoire pour relire les fichiers contenant un "rt_poin" la ou on voudrait un "phaseds" dans le param
		if( (!mon_strcmp("phaseds",nom_indice)) && !mon_strcmp(_sm_nom_param_c(dh,p),"rt_poin")) {
			if(print) printf("  %s",nom_indice);
			return _sm_param_c(dh,p);
		}



	}
	return 0;
}

/****************************************************
*			cherche_pointeur_param_detecteurs					*
****************************************************/
// retourne soit un pointeur au bon endroit sur la memoire dhs, soit un pointeur null
int4 		*cherche_pointeur_param_detecteurs(Data_header_shared_memory *dhs,char *nom_indice,int print) {
	int p;
	//printf("\ncherche indice param (%s)  avec dhs->nb_param_c=%d  dhs->nb_param_d=%d ",nom_indice,dhs->nb_param_c,dhs->nb_param_d);
	for(p=0; p<dhs->nb_param_d; p++) {
		//printf(" p=%d  : %s ",p,_sm_nom_champ_reglage(dhs,p));
		if(!mon_strcmp(_sm_nom_param_d(dhs,p),nom_indice)) {
			if(print) printf("  %s",nom_indice);
			return _sm_param_d(dhs,p);
		}
	}
	return 0;
}




/********************************************
*			cherche_indice_brut				*
********************************************/
// attention, la premiere brut commun retourne zero : retourne -1 en erreur  !!la place
// a partir du nom ASCII du brut, retourne la place du brut dans le header
int		cherche_indice_brut(Data_header_shared_memory *dhs,char *nom_indice,int print) {
	int p;
	//printf("\ncherche indice brut");
	p=cherche_indice_brut_commun(dhs,nom_indice,print);
	if(p>=0) return p;
	p=cherche_indice_brut_detecteur(dhs,nom_indice,print);
	return p;
}


/********************************************
*			cherche_indice_brut_commun		*
********************************************/
// brut simple et brut box
// attention, la premiere brut commun retourne zero : retourne -1 en erreur  !!la place
// a partir du nom ASCII du brut, retourne la place du brut dans le header
int		cherche_indice_brut_commun(Data_header_shared_memory *dhs,char *nom_indice,int print) {
	int p;
	//printf("\ncherche indice brut");
	for(p=0; p<dhs->nb_brut_c; p++) {
		//printf(" p=%d  : %s ",p,_sm_nom_champ_reglage(dhs,p));
		if(!mon_strcmp(_sm_nom_brut_c(dhs,p),nom_indice)) {
			//printf(" %s(c%d)",nom_indice,p);
			if(print) printf(" %s",nom_indice);
			return  p;
		}
	}
	return -1;
}


/********************************************
*			cherche_indice_brut_detecteur	*
********************************************/
// attention, le premiere brut detecteur retourne zero : retourne -1 en erreur  !!la place
// a partir du nom ASCII du brut, retourne la place du brut dans le header
int		cherche_indice_brut_detecteur(Data_header_shared_memory *dhs,char *nom_indice,int print) {
	int p;
	for(p=0; p<dhs->nb_brut_d; p++) {
		//printf(" p=%d  : %s ",p,_sm_nom_champ_reglage(dhs,p));
		if(!mon_strcmp(_sm_nom_brut_d(dhs,p),nom_indice)) {
			//printf("  %s(d%d)",nom_indice,p);
			if(print) printf(" %s",nom_indice);
			return  p;
		}
	}
	return -1;
}


/********************************************
*			cherche_indice_data				*
********************************************/
// attention, la premiere brut commun retourne zero : retourne -1 en erreur  !!
int		cherche_indice_data(Data_header_shared_memory *dhs,char *nom_indice,int print) {
	int p=cherche_indice_data_commun(dhs,nom_indice,print);
	if(p<0) p=cherche_indice_data_detecteur(dhs,nom_indice,print);
	return p;
}



/********************************************
*			cherche_indice_data_communs				*
********************************************/
// attention, la premiere brut communs retourne zero : retourne -1 en erreur  !!
int		cherche_indice_data_commun(Data_header_shared_memory *dhs,char *nom_indice,int print) {
	int k;
	for(k=0; k<dhs->nb_data_c; k++) {
		//printf(" p=%d  : %s ",p,_sm_nom_champ_reglage(dhs,p));
		if(!mon_strcmp(_sm_nom_data_c(dhs,k),nom_indice)) {
			if(print) printf(" %s",nom_indice);
			return  k;
			//return  (dhs)->nb_pt_bloc * k;
		}
	}
	return -1;
}


/********************************************
*			cherche_indice_data_detecteurs				*
********************************************/
// attention, la premiere brut communs retourne zero : retourne -1 en erreur  !!
int		cherche_indice_data_detecteur(Data_header_shared_memory *dhs,char *nom_indice,int print) {
	int p;
	for(p=0; p<dhs->nb_data_d; p++) {
		//printf(" p=%d  : %s ",p,_sm_nom_champ_reglage(dhs,p));
		if(!mon_strcmp(_sm_nom_data_d(dhs,p),nom_indice)) {
			if(print) printf(" %s",nom_indice);
			return  p;
			//return  (dhs)->nb_data_c * (dhs)->nb_pt_bloc + (dhs)->nb_pt_bloc * (dhs)->nb_detecteurs * p;
		}
	}
	return -1;
}




/****************************************************
*        change_liste_data                          *
****************************************************/
// change la liste des data ecrite dans le header binaire dhs
// on donne en argument la liste des data que l'on veut voir apparaitre dans le header
// eventuellement on peu remplacer la liste par "all " : on aura alrs toutes les data possibles
// eventuellement, on peu changer la valeur d'un parametre en indiquant dans la liste, son nom suivit d'une valeur entiere
// La fonction fait un realloc car le header binaire change de longueur

// ici je vais changer : _len_header_util_shared_memory(dhs)  est la longueur reellle utilisee pour le header
//   Dhs1->lg_header_util est toujours  >=   et c'est la taille de la memoire allouee.
// donc je peux faire change_liste_data sans faire de reallocation s'il y a la place

// la fonction appelle complete_header() pour terminer pour que le header soit complet avec les tables de recherche rapide
Data_header_shared_memory	*change_liste_data(Data_header_shared_memory   *dhs,char *liste_data,int print) {
	int i,j,z;
	int p,pp,q,a,k;
	int n_max;
	int dc,db,dd;
	int all=0;


	char premier_mot[8];

	//	_def_global_data
	//	_def_global_unite
	//	_def_global_data_dependance

	char *global_data_simple[_nb_data_simple_possibles]=_chaines_data_simple;
	char *global_data_box[_nb_data_box_possibles]=_chaines_data_box;
	char *global_data_detecteur[_nb_data_detecteur_possibles]=_chaines_data_detecteur;
	char *global_brut_detecteur[_nb_brut_detecteur_possibles]=_chaines_brut_detecteur;

	char *global_unite_simple[_nb_data_simple_possibles]=_chaines_unite_simple;
	char *global_unite_box[_nb_data_box_possibles]=_chaines_unite_box;
	char *global_unite_detecteur[_nb_data_detecteur_possibles]=_chaines_unite_detecteur;

	int global_data_simple_dependance[_nb_data_simple_possibles] = _data_simple_dependance;
	int global_data_box_dependance[_nb_data_box_possibles] = _data_box_dependance;
	int global_data_detecteur_dependance[_nb_data_detecteur_possibles] = _data_detecteur_dependance;

	if(debug) print=1;    // je laisse les printf de debug du change liste data
//#endif

	if(print) printf("\n\n*******   CHANGE  LISTE  DATA   ***************\n");
	/*    printf("\n   boloA=%s   ",global_data[_d_boloA]);
		printf("\n   _d_Ra_det=%s   ",global_data[_d_Ra_det]);
		printf("\n   _d_ds_pha=%s   ",global_data[_d_ds_pha]);
	*/
	// je cherche le premier mot en enlevant les blancs

	if(print)
		{
		// recapitule la liste des champs de reglage presents
		printf("\nREGLAGES : ");
		for(i=0;i<dhs->nb_champ_reglage;i++)
			{
			printf("  %s",_sm_nom_champ_reglage(dhs,i));
			}
		printf("\n");
		}
	j=0;
	for(i=0; liste_data[i]; i++) {
		if (liste_data[i]!=' ')	{
			premier_mot[j]=liste_data[i];
			j++;
		} else if(j) break;
	}
	premier_mot[j]=0;

	// je regarde si  ca commence par "all"
	//printf("\n premier mot de la liste = <%s> ",premier_mot);
	if(!mon_strcmp(premier_mot,"all")) all=1;
	if(!mon_strcmp(premier_mot,"raw")) all=2;

	//----  je commence par compter les elements separes par des blancs pour pouvoir faire le malloc (y compris les parametres dont on doit fixer la valeur)
	a=0;
	n_max=0;
	for(i=0; liste_data[i]; i++) {
		if( (!a) && (liste_data[i]!=' ') )	{
			n_max++;
			a=1;
		}
		if(  a   && (liste_data[i]==' ') )	a=0;
	}

	if(!n_max) {         // liste vide : ne fait rien
		return dhs;
	}

	if(all==1) {
		if(print) printf("\n\n-----> ajoute toutes les data possibles (liste data = all )   nmax=%d  ",_nb_data_possibles);
		n_max += _nb_data_possibles;
	}
	if(all==2) {
		if(print) printf("\n\n-----> ajoute touts les brut possibles (liste data = raw )   nmax=%d  ",_nb_data_possibles);
		n_max += _nb_data_possibles;
	} else {
		if(print) printf("\n----> nouvelle liste data avec %d objets : ",n_max);
	}

if(print) printf(" nmax total=%d ",n_max);

//------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------
typedef struct {
	char mot[32];
    }
Un_mot;

#define _nb_cara_mot_liste  16

	n_max++;	// par securite et pour eviter l'affichage de l'erreur p=nmax
	Un_mot *maliste=(Un_mot *)malloc(sizeof(Un_mot)*(n_max+1));
	Un_mot *maliste_unite=(Un_mot *)malloc(sizeof(Un_mot)*(n_max+1));
	int*    flag=(int *)malloc(sizeof(int)*(n_max+1));

	p=0;
	//------  copie des noms dans ma liste a la suite en les rangeant regulierement avec 16 cara par nom
    for(i=0; liste_data[i]; i++) {
		if(liste_data[i]!=' ') {	// premier cara non blanc d'un nom de ma liste
			// cherche la longueur du nom suivant dans liste_data
			for(k=0; k<15; k++) if( (!liste_data[i+k]) || (liste_data[i+k]==' ') ) break;			// on a exactement k caracteres dans le nom
			strncpy(maliste[p].mot,liste_data+i,k);
			maliste[p].mot[k]=0;
			if(print) printf(" p=%d:%s",p,maliste[p].mot);
			i+=k-1;		// pour chercher le mot suivant dans la liste  // je change pour k-1
			p++;
			if (p>=n_max) printf("\n$$$$$$***********  erreur dans change_liste data  ***********$$$$$$$$$$$$$ \n");
		}
	}
	// ici p est le nombre d'elements dans maliste


	if(all) {
		for(i=0; i<_nb_data_simple_possibles; i++) {
			strcpy(maliste[p++].mot,global_data_simple[i]);
			if (p>=n_max) printf("\n$$$$$$***********  erreur dans change_liste data  ***********$$$$$$$$$$$$$ \n");
		}
		for(z=0; z<dhs->nb_boites_mesure; z++)
			for(i=0; i<_nb_data_box_possibles; i++) {
				char ss[16];
				sprintf(ss,"%c%s",'A'+z,global_data_box[i]);
				strcpy(maliste[p++].mot,ss);
			}
		if(all==1)	for(i=0; i<_nb_data_detecteur_possibles; i++)	strcpy(maliste[p++].mot,global_data_detecteur[i]);
		if(all==2)	for(i=0; i<_nb_brut_detecteur_possibles; i++)	strcpy(maliste[p++].mot,global_brut_detecteur[i]);
	}

	n_max=p;
	//printf("\n---  fin de liste avec  %d  elements dans la liste  -----\n",n_max);


	//=========================    recherche des noms de ma liste dans la liste des possibles     ===================================
	//  Je flag ma nouvelle liste de data en comparant ma liste avec les data possibles
	// je flag les noms :  data_c : flag=1;  data_d flag=2; param= flag=3


	dc=0;
	db=0;
	dd=0;
	for(p=0; (p<n_max) && maliste[p].mot[0]; p++)	// test successivement sur chaque element de la liste
		// (le test de maliste[p].mot[0] est inutile car n_max est en principe correct)
	{
		int z;
		int cherche=1;
		flag[p]=0;
		//	printf(" \n cherche element  <<%s>>  => ",maliste[p].mot);
		if(cherche_pointeur_param_communs(dhs,maliste[p].mot,0)) {
			// printf("\n dans la liste, param : %s ",maliste[p].mot);
			flag[p]=3;			// c'est un param commun dont je dois changer la valeur
		}

		for(pp=0; pp<_nb_data_simple_possibles; pp++) {											// boucle sur les data_simple possibles
			if(!mon_strcmp(global_data_simple[pp],maliste[p].mot))
				if( _presence_brut(dhs,global_data_simple_dependance[pp]) ) {
					//					printf(" trouve data simple %d ",pp);
					cherche=0;
					dc++;
					flag[p]=1;
					strcpy(maliste_unite[p].mot,global_unite_simple[pp]);/*printf("%s ",maliste[p].mot);*/
				}

		}
		if(cherche) for(z=0; z<dhs->nb_boites_mesure; z++) for(pp=0; pp<_nb_data_box_possibles; pp++) {	// boucle sur les data_box de chaque box
					char ss[16];
					sprintf(ss,"%c%s",'A'+z,global_data_box[pp]);
					//			printf(" <%s> ",ss);
					//			if(!mon_strcmp(maliste[p].mot,"A_t_utc"))	printf("\n-------pp=%d  global_data_box_dependance[pp]=%d   presence _presence_brutbox = %d ",pp,global_data_box_dependance[pp],_presence_brutbox(dhs,global_data_box_dependance[pp],z));
					if(!mon_strcmp(ss,maliste[p].mot))			// c'est une data possible
						if( _presence_brutbox(dhs,global_data_box_dependance[pp],z) ) {
							db++;
							flag[p]=1;
							strcpy(maliste_unite[p].mot,global_unite_box[pp]);
							//					printf(" trouve data box pp=%d  z=%d  total=%d ",pp,z,_nb_data_simple_possibles+pp*_nb_max_acqbox+z);
							cherche=0;
						}

				}
		if(cherche) for(pp=0; pp<_nb_data_detecteur_possibles; pp++)
                {
				if(!mon_strcmp(global_data_detecteur[pp],maliste[p].mot))
                    {
                    if(print) printf("\n boucle pp=%d  p=%d  %s %s ",pp,p,maliste[p].mot,global_unite_detecteur[pp]);// boucle sur les data_detecteur possibles
                    
					if( ( (global_data_detecteur_dependance[pp] == _if_pointage ) &&  (_presence_brut(dhs,_d_ofs_X)) )
							|| ( (global_data_detecteur_dependance[pp] == _if_synchro  ) &&  (_presence_brut(dhs,_d_synchro_rapide)) )
							|| ( _presence_brutdet(dhs,global_data_detecteur_dependance[pp]) ) )
                            {
                            dd++;
                            flag[p]=2;		// c'est une data detecteur
                            strcpy(maliste_unite[p].mot,global_unite_detecteur[pp]);
                            //printf(" trouve data detecteur  pp=%d  total=%d ",pp,_nb_data_c_b_possibles+pp);
                            cherche=0;
                            }
                    }
			}
	}
	// en sortie j'ai le nombre de data_c  et de data_d  dans  dc  db et  dd
	//if(print) printf("    ===>  garde %d  datas  ",dc+db+dd);

	dhs->nb_data_c=dc+db;
	dhs->nb_data_d=dd;
	free(_DHP(dhs));		// je libere le Data_header_position   dhp

    if((int)_len_header_util_shared_memory(dhs)<=dhs->lg_header_util)
        {
        if(print) printf("\n change liste data nouveau header plus petit: je garde l'allocation memoire");
        if(print) printf(" alloue = %d   taille reelle = %d  ",dhs->lg_header_util,(int)_len_header_util_shared_memory(dhs));
        }
    else
        {
        if(print) printf("\n change liste data nouveau header plus grand: je fais un realloc ");
        if(print) printf("  %d ==> %d  ",dhs->lg_header_util,(int)_len_header_util_shared_memory(dhs));
        dhs = realloc(dhs,_len_header_util_shared_memory(dhs));
        dhs->lg_header_util= _len_header_util_shared_memory(dhs);	// la nouvelle longueur util du header
        }

	// ----  j'ecris les data communes  ------
	q=0;
	if(print) printf("\n DATA COMMUNS :");
	for(p=0; (p<n_max) && maliste[p].mot; p++) {
		if(flag[p]==1) {
			strncpy(_sm_nom_data_c(dhs,q),maliste[p].mot,__nbch(dhs));				// je la place en q
			strncpy(_sm_nom_data_c(dhs,q)+__nbch(dhs),maliste_unite[p].mot,__nbch(dhs));		// je la place en q
			//for(i=0;i<8;i++)	if(_sm_nom_data_d(dhs,q)[i]==' ')	_sm_nom_data_d(dhs,q)[i]=0;
			//		printf("\n   data commune  %d   :  %s (%s) ",q,_sm_nom_data_c(dhs,q),_sm_nom_data_c(dhs,q)+8);
			if(print) printf(" %s ",_sm_nom_data_c(dhs,q));
			//		if(print) printf("\n maliste=%s  unite=%s  :  %s ",maliste[p].mot,maliste_unite[p].mot,_sm_nom_data_c(dhs,q));
			q++;
		}
	}
	// ----  j'ecris les data detecteurs  ------
	q=0;
	if(print) printf("\n DATA DETECTEURS :");
	for(p=0; (p<n_max) && maliste[p].mot; p++) {
		if(flag[p]==2) {

			strncpy(_sm_nom_data_d(dhs,q),maliste[p].mot,__nbch(dhs));		// je la place en q
			strncpy(_sm_nom_data_d(dhs,q)+__nbch(dhs),maliste_unite[p].mot,__nbch(dhs));		// je la place en q
			//for(i=0;i<8;i++)	if(_sm_nom_data_d(dhs,q)[i]==' ')	_sm_nom_data_d(dhs,q)[i]=0;
			//		printf("\n   data detecteur  %d   :  %s  (%s)  ",q,_sm_nom_data_d(dhs,q),_sm_nom_data_d(dhs,q)+8);
			if(print) printf("%s ",_sm_nom_data_d(dhs,q));
			q++;
		}
	}
	if(print) printf("\n");
	// ecrire les param dont on doit changer la valeur
	q=0;
	for(p=0; (p<n_max) && maliste[p].mot; p++) {
		if(flag[p]==3) {
			int p2;
			for(p2=0; p2<dhs->nb_param_c; p2++) {
				//printf(" p=%d  : %s ",p,_sm_nom_champ_reglage(dh,p));
				if(!mon_strcmp(_sm_nom_param_c(dhs,p2),maliste[p].mot)) {
					_sm_param_c(dhs,p2)[0] = atoi(maliste[p+1].mot);
					if(print) printf("je force param %s=%d  ",_sm_nom_param_c(dhs,p2),_sm_param_c(dhs,p2)[0]);
				}
			}
		}
	}


	//printf("\n\n  je reecris le hader avec les nouveaux data (%d data)  et je cherche les pointeurs globaux   \n",q);
	// le nouveau header est forcement plus court et je n'ai donc pas besoin de faire un nouveau m alloc
	free(maliste);
	free(maliste_unite);
	free(flag);
    
    
	if(debug)  printf("\n$$$$$$   position header  en  fin  de  change  liste  data  $$$$$$$$$$$$$$");
	position_header(dhs,debug);		// je cree a nouveau le Data_header_position  dhp

	return dhs;
}





/****************************************************
*				calcul_kid_boite					*
*****************************************************/

//   cette fonction est utilisee par   hysto  ainsi que par  brut_to_data
// c'est aussi elle qui cherche des valeurs dans le reglage pour les mettre dans les data

//   elle calcule ftone, l'angle le flag et la largeur qui seront mis dans les data
//  le flag retourne contient :
//		-	le flag change FPGA  et le flag balayage du synthe dans les data kid
//		-	le flag de qualite de tuning qu'elle prend dans le reglage width

// calcul pour les kid d'une boite donnee. Seule la partie correspondant des tableau sera remplie
// le reste des tableaux (ftone,tangle,flagkid,width) reste inchangé
// si un tableau est null, il ne sera pas rempli
// alors que width est en bin/1000   dans le reglage, le tableau de sortie est aussi en bin/1000
//  ne pas oublier que dans le param, la largeur est en kHz
//  le tableau fone en sortie est lui en kHz

void	calcul_kid_boite(Data_header_shared_memory *dhs,int z,double freq,int msq,int4 *I,int4 *Q,int4 *dI,int4 *dQ,
						 double *ftone,double *tangle,int *flagkid,int *width) {
	int ndet,k;
	uint4 *RG_nikel=reglage_pointer_nikel_amc(dhs,z);
	uint4 *RG_freq=reglage_pointer(dhs,_r_k_freq,z);
	uint4 *RG_width=reglage_pointer(dhs,_r_k_width,z);
	if(RG_nikel && RG_freq) {
		//double f_bin= kid_balayage_freq_par_binX(RG_nikel);
		int nn1 = _first_det_box(dhs,z);
		int nn2 = _last_det_box(dhs,z);
		k=0;
		for(ndet=nn1; ndet<nn2; ndet++) {
			if(tangle)  tangle[ndet]	= 0;
			if(width)   width[ndet]		= 0;
			if(flagkid) flagkid[ndet]	= 0;
			if(ftone)   ftone[ndet]		= 0;

			int type_det=  _param_d((dhs), _pd_type, (ndet))  &0xffff ;
			if(tangle)
				if(	type_det ==	__kid_pixel)
					tangle[ndet]= _dangleIQdIdQ(Q[k],dQ[k],I[k],dI[k]);

			if(ftone) ftone[ndet]	= freq + _f_bin * (double)RG_freq[k];

			if(RG_width)	{
				if(flagkid)  flagkid[ndet] =  (msq &0x0f) | (_flag_du_reglage(RG_width,k)&0xf0) ;
				if(width)    width[ndet] =  _width_du_reglage(RG_width,k);   //  / _f_bin ;
			}
			k++;
		}
	}
}






