
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "a_memoire.h"
#include "def.h"

#include "bloc.h"
#include "bloc_comprime.h"

//#define debug 1


// je crees les bloc_zero qui contiennent un bloc dont on a code les zero
// dans l'entete le type est  bloc_zero et la longueur celle du bloc
// ensuite on a les data qui contiennent le code_longueur et le code2 du bloc original
// le buffer blk doit etre assez grand pour le bloc zero et pour le bloc original


/****************************************************
*                 bloc_to_bloc_zero                 *
****************************************************/
void	bloc_to_bloc_zero(Bloc_standard *blk) {
	int i,j,n;
	int l_bloc = longueur_bloc(blk)/4;
	int num = numero_bloc(blk);
	int4 *buf1 = (int4 *) blk;
	int4 *buf2 =  (int4 *)malloc(4*l_bloc);
	j=0;
	n=0;
#ifdef debug
	printf("\n bloc_to_bloc_zero  l=%d ",l_bloc);
#endif
	for(i=1; i<l_bloc; i++) {	// tout le bloc y compris les codes et la fin
		while (!buf1[i]) {
			i++;
			n++;
		}
		if(n) {
			buf2[j++]=0;
			buf2[j++]=n;
			n=0;
		}
		buf2[j++]=buf1[i];
		if(j>l_bloc-5) {
			free(buf2);    // garde le bloc tel qu'il etait si le bloc_zero n'est pas plus petit
			return;
		}
	}
	blk->code_longueur = (j+3) *4;
	blk->code2		=	(num & 0x00ffffffl ) | ( (((long)bloc_zero)<<24)&0xff000000l );
#ifdef debug
	printf("  fini avec i=%d  j=%d  l=%d  num=%d ",i,j,blk->code_longueur,num);
#endif

	for(i=0; i<j; i++)   blk->data[i] = buf2[i];

	free(buf2);
}



/****************************************************
*                 bloc_zero_to_bloc                 *
****************************************************/
void	bloc_zero_to_bloc(Bloc_standard *blk) {
	int i,j,n;
	int l_bloc_zero = longueur_bloc(blk)/4;
	int l_bloc = blk->data[0]/4;

	if(type_bloc(blk)!=bloc_zero) return ;	// si ce n'est pas un bloc_zero je ne fais rien

#ifdef debug
	printf("\n bloc_zero_to_bloc  l=%d  ->  l=%d  ",l_bloc_zero,l_bloc);
#endif
	int4 *buf2 =  (int4 *)malloc(4*l_bloc);
	j=1;
	n=0;
	for(i=0; i<l_bloc_zero-3; i++) {	// toutes les data du bloc zero (y compris la fin)
		if(!blk->data[i]) {
			i++;
			n=blk->data[i];
			while(n) {
				buf2[j]=0;
				j++;
				n--;
			}
		} else {
			buf2[j]=blk->data[i];
			j++;
		}
	}

	for(i=1; i<l_bloc; i++)   ((int4 *)blk)[i] = buf2[i];

	free(buf2);
}




/*************************************************************
*			comprime  et  decomprime les donnees brutes      *
*************************************************************/
// le tableau d'entiers data contient soit un bloc de brut, soit le meme en comprime
// ces fonctions comprimemnt et de-com-priment les donnees en place
// le tableau data doit etre assez grand pour les donnees brutes decom-primees
// prend chaque donnee commune et chaque donnee detecteur: cherche le vecteur 36 points de chaque detecteur det  pour chaque donnee  j
// je supprime les donnees periodes si elles existent


#define _comp_vector8	{	int decale=0; \
			while(decale<24) { \
				for(p=1;p<dhs->nb_pt_bloc;p++)	tableaudif[p] = tableaubrut[p] - tableaubrut[0];\
				if(decale) for(p=1;p<dhs->nb_pt_bloc;p++) tableaudif[p]=(tableaudif[p]>>decale)+( (tableaudif[p]>>(decale-1))&1); \
				for(p=dhs->nb_pt_bloc-1;p>1;p--) tableaudif[p] = tableaudif[p]-tableaudif[p-1]; \
				for(p=1;p<dhs->nb_pt_bloc;p++)	if( abs(tableaudif[p])>127)	break; \
				if(p == dhs->nb_pt_bloc) break;	\
				decale++; \
			} \
			tabint[0] = tableaubrut[0]; tabchar[0] = (char)decale; \
			for(p=1;p<dhs->nb_pt_bloc;p++)	tabchar[p] = (char)tableaudif[p];\
		}


#define _decomp_vector8		{\
			tableaubrut[0]=tabint[0]; \
			int	decale = tabchar[0]; \
			for(p=1;p<dhs->nb_pt_bloc;p++) \
				tableaubrut[p] = tableaubrut[p-1]  + (tabchar[p] << decale );\
		}


void	comprime8(Data_header_shared_memory *dhs,int4 *data) {
	int4  tableaubrut[36]={0};
	int4  tableaudif[36]={0};
	int4	tabint[10];
	char	*tabchar =  (char *)(tabint+1);
	//printf(" malloc avec %d , %d \n", dhs->nb_brut_d, dhs->nb_detecteurs);
	int4	*data_comprime = malloc(_size_data_comprime8(dhs));
	int k,ndet,p;
	if(dhs->nb_pt_bloc != 36) return;	// ne comprime et decom-prime que les blocs de 36
	for(k=0; k<dhs->nb_brut_c; k++) {
		for(p=0; p<dhs->nb_pt_bloc; p++)	tableaubrut[p] = _brut_ec(dhs,data,k,p);
		_comp_vector8
		//if(k==0)
		//if(tabchar[0])
		{
			//					printf("\nvecteur commun k=%d  decale=%d ",k,tabchar[0]);
			//					for(p=1;p<36;p++) printf("%d ",tabchar[p]);
		}
		for(p=0; p<10; p++) data_comprime[ p + 10 * k] = tabint[p];
	}

	for(k=0; k<dhs->nb_brut_d; k++)
		for(ndet=0; ndet<dhs->nb_detecteurs; ndet++) {
			for(p=0; p<dhs->nb_pt_bloc; p++) tableaubrut[p] = _brut_ed(dhs,data,k,p)[ndet];
			_comp_vector8
			//if(k==2)
			//if(ndet==3)
			//if(tabchar[0])
			{
				//					printf("\nvecteur k=%d  decale=%d ",k,tabchar[0]);
				//					for(p=1;p<36;p++) printf("%d ",tabchar[p]);
			}

			for(p=0; p<10; p++) data_comprime[ p + 10 * (dhs->nb_brut_c +  dhs->nb_detecteurs * k +  ndet )] = tabint[p];
		}
	memcpy(data,data_comprime,_size_data_comprime8(dhs));
	free(data_comprime);
}


void	decomprime8(Data_header_shared_memory *dhs,int4 *data) {
	int4  tableaubrut[36]={0};
	int4	tabint[10]={0};
	char	*tabchar =  (char *)(tabint+1);
	int k,ndet,p;
	if(dhs->nb_pt_bloc != 36) return;	// ne comprime et decomprime que les blocs de 36
	int4	*data_comprime = malloc(_size_data_comprime8(dhs));

	memcpy(data_comprime,data,_size_data_comprime8(dhs));

	//printf("\n\nLe debut du bloc : ");for(p=0;p<100;p++)	{ if(p%10==0) printf("\n");printf("\t%x",data_comprime[p] );}

	for(k=0; k<dhs->nb_brut_c; k++) {
		for(p=0; p<10; p++) tabint[p] = data_comprime[ p + 10 * k];
		_decomp_vector8
		//if(k==0)
		//if(tabchar[0])
		{
			//printf("\nvecteur commun k=%d  decale=%d ",k,tabchar[0]);
			//for(p=1;p<36;p++) printf("%d ",tabchar[p]);
			//printf("\nresult: ");
			//for(p=1;p<36;p++) printf("%d ",tableaubrut[p]);
		}

		for(p=0; p<dhs->nb_pt_bloc; p++)	_brut_ec(dhs,data,k,p) = tableaubrut[p] ;
	}

	for(k=0; k<dhs->nb_brut_d; k++)
		for(ndet=0; ndet<dhs->nb_detecteurs; ndet++) {
			for(p=0; p<10; p++)  tabint[p] = data_comprime[ p + 10 * (dhs->nb_brut_c +  dhs->nb_detecteurs * k +  ndet) ];
			_decomp_vector8
			for(p=0; p<dhs->nb_pt_bloc; p++) _brut_ed(dhs,data,k,p)[ndet] = tableaubrut[p];
		}
	free(data_comprime);
}


/*********************************************************************************************************
*			comprime  et  decomprime les donnees brutes    marche aussi pour les bolos (72 pt / bloc)    *
*********************************************************************************************************/
// le tableau d'entiers data contient soit un bloc de brut, soit le meme en comprime
// ces fonctions comprimemnt et de-com-priment les donnees en place
// le tableau data doit etre assez grand pour les donnees brutes decom-primees
// prend chaque donnee commune et chaque donnee detecteur:
//	cherche le vecteur n points de chaque detecteur det  pour chaque donnee  j


#define _comp_vector10	{\
		int decale=0;	\
		while(decale<24) {\
			for(p=1;p<dhs->nb_pt_bloc;p++)            tableaudif[p] = tableaubrut[p] - tableaubrut[0]; \
			if(decale) for(p=1;p<dhs->nb_pt_bloc;p++) tableaudif[p]=(tableaudif[p]>>decale)+( (tableaudif[p]>>(decale-1))&1); \
			for(p=dhs->nb_pt_bloc-1;p>1;p--)          tableaudif[p] = tableaudif[p]-tableaudif[p-1]; \
			for(p=1;p<dhs->nb_pt_bloc;p++)	if( abs(tableaudif[p])>500)	break; \
			if(p == dhs->nb_pt_bloc) break;	\
			decale++;\
		} \
		tabint[0] = tableaubrut[0]; tableaudif[0] = decale;	\
		for(p=0;3*p<dhs->nb_pt_bloc;p++)	\
			tabint[p+1] = (tableaudif[3*p]&0x03ff) | ((tableaudif[3*p+1]&0x03ff)<<10) | ((tableaudif[3*p+2]&0x03ff)<<20) ;\
	}


#define _decomp_vector10xx		{\
		tableaubrut[0]=tabint[0];	\
		int	decale = tabint[1] & 0x3ff;			\
		for(p=1;p<dhs->nb_pt_bloc;p++) {	\
			int a = ((tabint[1+p/3]>>10*(p%3) ) & 0x3ff) ;\
			if (a&0x200) a|=0xfffffc00;	\
			tableaubrut[p]  = tableaubrut[p-1]  + (a << decale );\
		}	}

#define _decomp_vector10		{\
		tableaubrut[0]=tabint[0];	\
		int	decale = tabint[1] & 0x3ff;			\
		for(p=1;p<dhs->nb_pt_bloc;p++)		{\
			int a =tabint[1+p/3]; \
			if(a!=0) {\
				a = (a>>(10*(p%3)) )& 0x3ff  ;\
				if (a&0x200) a|=0xfffffc00; \
				a<<= decale;\
				tableaubrut[p]  = tableaubrut[p-1]  + a;\
			}	\
			else {\
				a=tableaubrut[p-1];\
				while (p%3!=2) tableaubrut[p++]=a;\
				tableaubrut[p]=a;\
			}	}	}

void	comprime10(Data_header_shared_memory *dhs,int4 *data_comprime,int4 *data) {
	int4  tableaubrut[300]={0};
	int4  tableaudif[300]={0};
	int4	tabint[100]={0};		// _nb_mot
	int k,ndet,p;
	for(k=0; k<dhs->nb_brut_c; k++) {
		for(p=0; p<dhs->nb_pt_bloc; p++)	tableaubrut[p] = _brut_ec(dhs,data,k,p);
		_comp_vector10
		//if(k==0)
		//if(tabchar[0])
		{
			//					printf("\nvecteur commun k=%d  decale=%d ",k,tabchar[0]);
			//					for(p=1;p<36;p++) printf("%d ",tabchar[p]);
		}
		for(p=0; p<_nb_mot10n(dhs); p++) data_comprime[ p + _nb_mot10n(dhs) * k] = tabint[p];
	}

	for(k=0; k<dhs->nb_brut_d; k++)
		for(ndet=0; ndet<dhs->nb_detecteurs; ndet++) {
			for(p=0; p<dhs->nb_pt_bloc; p++) tableaubrut[p] = _brut_ed(dhs,data,k,p)[ndet];
			_comp_vector10
			//if(k==2)
			//if(ndet==3)
			//if(tabchar[0])
			{
				//					printf("\nvecteur k=%d  decale=%d ",k,tabchar[0]);
				//					for(p=1;p<36;p++) printf("%d ",tabchar[p]);
			}

			for(p=0; p<_nb_mot10n(dhs); p++) data_comprime[ p + _nb_mot10n(dhs) * (dhs->nb_brut_c +  dhs->nb_detecteurs * k +  ndet )] = tabint[p];
		}
}

// decomprime en place dans data qui doit etre assez grand
void	decomprime10(Data_header_shared_memory *dhs,int4 *data) {
	int4  tableaubrut[300]={0};
	int4	tabint[100]={0};
	int k,ndet,p;
	int4	*data_comprime = malloc(_size_data_comprime10(dhs));

	memcpy(data_comprime,data,_size_data_comprime10(dhs));

	//printf("\n\nLe debut du bloc : ");for(p=0;p<100;p++)	{ if(p%10==0) printf("\n");printf("\t%x",data_comprime[p] );}

	for(k=0; k<dhs->nb_brut_c; k++) {
		for(p=0; p<_nb_mot10n(dhs); p++) tabint[p] = data_comprime[ p + _nb_mot10n(dhs) * k];
		_decomp_vector10
		for(p=0; p<dhs->nb_pt_bloc; p++)	_brut_ec(dhs,data,k,p) = tableaubrut[p] ;
	}

	for(k=0; k<dhs->nb_brut_d; k++)
		for(ndet=0; ndet<dhs->nb_detecteurs; ndet++) {
			for(p=0; p<_nb_mot10n(dhs); p++)  tabint[p] = data_comprime[ p + _nb_mot10n(dhs) * (dhs->nb_brut_c +  dhs->nb_detecteurs * k +  ndet) ];
			_decomp_vector10
			for(p=0; p<dhs->nb_pt_bloc; p++) _brut_ed(dhs,data,k,p)[ndet] = tableaubrut[p];
		}
	free(data_comprime);
}


/*********************************************************************************************************
*		 comprime  et  decomprime uniquement les data_d et pas les data_c qui restent non-comprimees     *
*********************************************************************************************************/

void	comprime10d(Data_header_shared_memory *dhs,int4 *data_comprime,int4 *data) {
	int4  tableaubrut[300]={0};
	int4  tableaudif[300]={0};
	int4	tabint[100]={0};		// _nb_mot
	int k,ndet,p;
	for(k=0; k<dhs->nb_brut_c; k++) {
		for(p=0; p<dhs->nb_pt_bloc; p++)	data_comprime[ p + dhs->nb_pt_bloc * k] = _brut_ec(dhs,data,k,p);
	}

	for(k=0; k<dhs->nb_brut_d; k++)
		for(ndet=0; ndet<dhs->nb_detecteurs; ndet++) {
			for(p=0; p<dhs->nb_pt_bloc; p++) tableaubrut[p] = _brut_ed(dhs,data,k,p)[ndet];
			_comp_vector10
			//if(k==2)
			//if(ndet==3)
			//if(tabchar[0])
			{
				//					printf("\nvecteur k=%d  decale=%d ",k,tabchar[0]);
				//					for(p=1;p<36;p++) printf("%d ",tabchar[p]);
			}

			for(p=0; p<_nb_mot10n(dhs); p++) data_comprime[dhs->nb_pt_bloc*dhs->nb_brut_c +  _nb_mot10n(dhs) * (dhs->nb_detecteurs * k +  ndet) + p] = tabint[p];
		}
}

// decomprime en place dans data qui doit etre assez grand
void	decomprime10d(Data_header_shared_memory *dhs,int4 *data) {
	int4  tableaubrut[300]={0};
	int4	tabint[100]={0};
	int k,ndet,p;
	int4	*data_comprime = malloc(_size_data_comprime10d(dhs));

	memcpy(data_comprime,data,_size_data_comprime10d(dhs));

	//printf("\n\nLe debut du bloc : ");for(p=0;p<100;p++)	{ if(p%10==0) printf("\n");printf("\t%x",data_comprime[p] );}

	for(k=0; k<dhs->nb_brut_c; k++) {
		for(p=0; p<dhs->nb_pt_bloc; p++)	_brut_ec(dhs,data,k,p) = data_comprime[ p + dhs->nb_pt_bloc * k];
	}

	for(k=0; k<dhs->nb_brut_d; k++)
		for(ndet=0; ndet<dhs->nb_detecteurs; ndet++) {
			for(p=0; p<_nb_mot10n(dhs); p++)  tabint[p] = data_comprime[dhs->nb_pt_bloc*dhs->nb_brut_c +  _nb_mot10n(dhs) * (dhs->nb_detecteurs * k +  ndet) + p];
			_decomp_vector10
			for(p=0; p<dhs->nb_pt_bloc; p++) _brut_ed(dhs,data,k,p)[ndet] = tableaubrut[p];
		}
	free(data_comprime);
}


// ici on fabrique des bloc_mini dans  bktp2
//==================   la longueur d'un bloc de brut dans la shared_memory   ===================================
// le bloc mini contient: le nb de det mini, la liste de leur rawnum, les brut_c les brut_d

//pour les brut detecteurs, je me defini un brut_datad et un brut_datadmini
// sachant que data et datamini pointent au debut des data detecteur du bloc
//#define		_brut_ed(dhs,br,k,i)		( (int4*)(br) + ( (dhs)->nb_brut_c * (dhs)->nb_pt_bloc + (k)*(dhs)->nb_pt_bloc*(dhs)->nb_detecteurs  + (dhs)->nb_detecteurs * (i) )  )
#define		_brut_datad(data,k,i)		( data  + (k)*(dhs)->nb_pt_bloc*(dhs)->nb_detecteurs  + (dhs)->nb_detecteurs * (i) )
#define		_brut_datadmini(data,k,i)	( data  + (k)*(dhs)->nb_pt_bloc*(dhs)->nb_det_mini    + (dhs)->nb_det_mini * (i)   )

int4 			*Liste_det_mini[_nb_max_fichiers_mini];	   // Pour chaque fichier, la liste des detecteurs


int	bloc_brut_to_bloc_mini(Data_header_shared_memory *dhs,int num_liste,Bloc_standard *bktp2,Bloc_standard *bktp) {
	int4  tableaubrut[300]={0};
	int4  tableaudif[300]={0};
	int4	tabint[100]={0};		// _nb_mot

	int k,p,q,ndet;
	int4 *data = bktp->data;
	int4 *datamini = bktp2->data;
	int ndetmini =  Liste_det_mini[num_liste][0];
	if(!ndetmini) return 0;

	dhs->nb_det_mini=ndetmini;	// pour definir la longueur des blocs mini comprime

	//-----  - 1 -  le nb de detecteurs et la liste dans datamini
	for(q=0; q<ndetmini+1; q++) datamini[q]=Liste_det_mini[num_liste][q]; // la liste avec le nb d'elements en [0]
	datamini+=ndetmini+1;	// pour se placer au debut des data brutc

	//----   - 2 -   copie tous les brutc  en les comprimant  ---------
	for(k=0; k<dhs->nb_brut_c; k++) {
		for(p=0; p<dhs->nb_pt_bloc; p++)	tableaubrut[p] = _brut_ec(dhs,data,k,p);
		_comp_vector10
		for(p=0; p<_nb_mot10n(dhs); p++) datamini[ _nb_mot10n(dhs) * k + p] = tabint[p];
	}
	data	+=  dhs->nb_pt_bloc * dhs->nb_brut_c ;		// pour se placer au debut des brut detecteurs
	datamini+= _nb_mot10n(dhs)  * dhs->nb_brut_c ;

	//----  - 3 -   copie les brutd des detecteurs demandés  en les comprimant
	for(k=0; k<dhs->nb_brut_d; k++)
		for(q=0; q<dhs->nb_det_mini; q++) {
			ndet=Liste_det_mini[num_liste][q+1];
			for(p=0; p<dhs->nb_pt_bloc; p++) tableaubrut[p] = _brut_ed(dhs,data,k,p)[ndet];
			_comp_vector10
			for(p=0; p<_nb_mot10n(dhs); p++) datamini[ p + _nb_mot10n(dhs) * ( dhs->nb_det_mini * k + q)] = tabint[p];
		}
	_valide_bloc(dhs,bktp2,bloc_mini,numero_bloc(bktp));
	//printf("\n brut->mini %d :  l=%d ",num_liste,_size_bloc(dhs,bloc_mini));
	return 1;
}



void	bloc_mini_to_bloc_brut(Data_header_shared_memory *dhs,int4 *data) {
	int k, p=0, q, ndet;
	int nb_det_mini=data[0];
	int4	tableaubrut[300]={0};
	int4	tabint[100]={0};

	int4	*buf			= malloc(_len_brut_mini(dhs));
	// je copie les data dans buf pour ensuite faire la conversion de buf vers data
	memcpy(buf,data,_len_brut_mini(dhs));
	dhs->nb_det_mini = buf[0];		// le nombre de detecteurs de la liste

	int *liste = buf+1;
	int4	*datamini	= buf + nb_det_mini+1;	// pour se placer au debut des data brutc


	//----  copie les brutc  en les decomprimant
	for(k=0; k<dhs->nb_brut_c; k++) {
		for(p=0; p<_nb_mot10n(dhs); p++)	tabint[p] = datamini[ _nb_mot10n(dhs) * k + p];
		_decomp_vector10
		for(p=0; p<dhs->nb_pt_bloc; p++)	_brut_ec(dhs,data,k,p) = tableaubrut[p] ;
	}

	data	+=  dhs->nb_pt_bloc * dhs->nb_brut_c ;		// pour se placer au debut des brut detecteurs
	datamini+= _nb_mot10n(dhs)  * dhs->nb_brut_c ;

	for(k=0; k<dhs->nb_brut_d; k++) {
		for(ndet=0; ndet<dhs->nb_detecteurs; ndet++) _brut_datad(data,k,p)[ndet]=0;
		for(q=0; q<dhs->nb_det_mini; q++) {
			ndet=liste[q];
			for(p=0; p<_nb_mot10n(dhs); p++)  tabint[p] = datamini[ _nb_mot10n(dhs) * ( dhs->nb_detecteurs * k +  q) + p ];
			_decomp_vector10
			for(p=0; p<dhs->nb_pt_bloc; p++) _brut_ed(dhs,data,k,p)[ndet] = tableaubrut[p];
		}
	}

	free(buf);
}

// cree la liste detecteur dans listdet  en utilisant le code  type_listdet
//		si code>0  prend au depart  liste_detecteurs avec nb_detecteurs_lut detecteurs
//		si code<0  fabrique la liste (si liste_detecteurs est NULL) fait le malloc
//		si liste_bloc_mini != NULL  ne garde que les detecteurs de la liste du bloc mini
// le pointeur sur la liste sera retourne.
//				si listdet est non nul, on retourne listdet
//				si listdet est nul,     on retourne u n nouveau pointeur qu'il faudra liberer avec free()
#define 	_bon_detecteur_liste(dhs,code,ndet)	( ( (code_listdet==_liste_detecteurs_all) ) \
		|| ( (code_listdet==_liste_detecteurs_not_zero) && (_type_det(dhs,ndet)!=0) )	\
		|| ( (code_listdet==_liste_detecteurs_kid_pixel) && (_type_det(dhs,ndet)==__kid_pixel) ) \
		|| ( (code_listdet==_liste_detecteurs_kid_pixel_array1) && (_type_det(dhs,ndet)==__kid_pixel) && (_array(dhs,ndet)==1)  ) \
		|| ( (code_listdet==_liste_detecteurs_kid_pixel_array2) && (_type_det(dhs,ndet)==__kid_pixel) && (_array(dhs,ndet)==2)  ) \
		|| ( (code_listdet==_liste_detecteurs_kid_pixel_array3) && (_type_det(dhs,ndet)==__kid_pixel) && (_array(dhs,ndet)==3)  ) )



// si  listdet est NULL,  fait un malloc et retourne un pointeur sur le nouveau listdet
// si listdet existe, il doit etre dimensionne au moins a dhs->nb_detecteurs+1
int4 *cree_list_det(Data_header_shared_memory *dhs,int code_listdet,int4 *listdet,int4 *liste_det_bloc_mini) {
	int ndet,nk,nk1;
	int4 *listdet2;
	//printf("\n cree liste detecteur code_liste=%d  ",code_listdet);

	if(listdet==NULL) {
		listdet2=malloc(sizeof(int4)*dhs->nb_detecteurs+1);
		listdet2[0]=dhs->nb_detecteurs;
	} else	{
		listdet2=listdet;
	}

	if(code_listdet==0) {	// je prend la liste donnee et ne garde que les detecteurs du fichier
		int *all_det=malloc(sizeof(int)* dhs->nb_detecteurs);
		for(ndet=0; ndet<dhs->nb_detecteurs; ndet++)	all_det[ndet]=0;
		for(nk=0; nk<listdet2[0]; nk++)
			if( (listdet2[nk]>=0) &&  (listdet2[nk]<dhs->nb_detecteurs) )
				all_det[listdet[nk]]=1;
		if(liste_det_bloc_mini) {
			for(nk=0; nk<liste_det_bloc_mini[0]; nk++)
				if( (liste_det_bloc_mini[nk]>=0) &&  (liste_det_bloc_mini[nk]<dhs->nb_detecteurs) )
					all_det[liste_det_bloc_mini[nk]]|=2;
		} else	for(ndet=0; ndet<dhs->nb_detecteurs; ndet++)	all_det[ndet]|=2;
		nk=0;
		for(ndet=0; ndet<dhs->nb_detecteurs; ndet++) if(all_det[ndet]==3) listdet2[1+nk++]=ndet;
		listdet[0]=nk;
		free(all_det);
	}

	else {				// je cree une nouvelle liste a partir du code
		if(liste_det_bloc_mini) {
			nk=0;
			for(nk1=0; nk1<liste_det_bloc_mini[0]; nk1++) {
				ndet=liste_det_bloc_mini[1+nk1];
				if(_bon_detecteur_liste(dhs,code_listdet,ndet)) listdet2[1+nk++]=ndet;
				//if(nk>=listdet2[0]) break;
			}
			listdet2[0] = nk;
		} else {
			nk=0;
			for(ndet=0; ndet<dhs->nb_detecteurs; ndet++) {
				if(_bon_detecteur_liste(dhs,code_listdet,ndet)) listdet2[1+nk++]=ndet;
				//if(nk>=listdet2[0]) break;
			}
			listdet2[0] = nk;
		}
	}

	#ifdef debug
		int nb_det_mini=dhs->nb_detecteurs;
		if(liste_det_bloc_mini) nb_det_mini=liste_det_bloc_mini[0];
		printf("\n cree liste detecteur type_liste=%d  list bloc mini=%d   final=%d ",code_listdet,nb_det_mini,listdet2[0]);
	#endif
	return listdet2;
}


