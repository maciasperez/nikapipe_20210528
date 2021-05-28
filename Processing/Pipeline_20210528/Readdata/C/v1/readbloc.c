
#ifdef _MANIPQT_

#include "mq_manip.h"			// pour lecture et client_trace dans le MAC

#else							// pour readdata IDL  et pour les boitiers d'acquisition
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#endif


#include "a_memoire.h"
#include "def.h"

#include "bloc.h"
#include "bloc_comprime.h"

#include "readbloc.h"

#define debug 0
#undef printf

#undef  __BIG_ENDIAN__			// probleme car dans trace, __BIG_ENDIAN__ est defini quelque part !!!!!!


#ifdef __BIG_ENDIAN__
#define  _int4_swap(mot)	{char * cc= (char*) (mot);char a=cc[0];cc[0]=cc[3];cc[3]=a;a=cc[1];cc[1]=cc[2];cc[2]=a;}
#define	 swap_bloc(i)		((i)^3)
#else
#define  _int4_swap(mot)	{}
#define	 swap_bloc(i)		(i)
#endif


//******       prototypes et definitions internes    ***********

void	swap_header(Data_header_shared_memory *dhs);
int		test_code_zero(FILE *file);

#define		_bit_code_zero			(1l<<48)
#define		_code_zero(aa)			( ((aa)>>48) & 1 )
#define		_fix_code_zero(aa)		 aa = (1l<<48)
#define		_fix_pos_fich(aa,bb)	  (aa) = ( (aa) & _bit_code_zero ) || (bb)
#define		_pos_fich(aa)			( (aa) & 0x0ffffffffffffl )



/********************************************
*              test_code_zero               *
********************************************/
#define nb_char_recherche (12*4)
int test_code_zero(FILE *file) {
	int i;
	char buffer[nb_char_recherche];
	//printf("\n test le code zero  sur %d cara \n ",nb_char_recherche);
	rewind(file);
	int nbbuf=fread(buffer,1,nb_char_recherche,file);
	rewind(file);
	if(nbbuf<nb_char_recherche) {
		/*printf("\n ERROR  file trop courte  !!! ");*/return -1;
	}

	//printf("\n");
	//for(i=0;i<nb_char_recherche-1;i++)  printf(" %d ",buffer[i]);
	//printf("\n");

	for(i=0; i<nb_char_recherche-1; i++)
		if( (buffer[i]==0) && (buffer[i+1]==0) ) return 0;

	return 1;	// les zero ont ete codes car on n'a jamais 2 zero de suite !!
}



/********************************************
*              read_nom_file_bloc               *
********************************************/
// il faut donner a la fonction:le nom du fichier et la position
// le programme ouvre puis referme le fichier
//  le programme ressort le type du bloc lut, le bloc est dans blk
int	 read_nom_file_bloc(Data_header_shared_memory   *dhs,char *nomfich,Bloc_standard *blk,long *pos,int max_len)
// reecrit en novembre 2014
//retourne le type du bloc lut (-1 =fin de fichier   -2 = erreur)
{
	FILE *file = fopen(nomfich, "rb");
	if (file==NULL) return -2;
	int type=read_file_bloc(dhs, file, blk, pos, max_len, 1);
	fclose(file);				// et ferme le fichier
	return type;
}


/********************************************
*              read_file_bloc               *
********************************************/
// il faut donner a la fonction:le pointeur FILE* sur le fichier ouvert
//  le programme deplace le pointeur de position dans le fichier et ressort le type du bloc lut
// en cas d'erreur, retourne un code d'erreur negatif :
//		-1 = je suis a la fin du fichier : plus rien a lire
//		-2 = pas de fichier ouvert
//		-3 = erreur de positionnement dans le fichier
// ne retourne le type du bloc lut que si le bloc est complet ou si j'ai rempli le bloc blk jusqu'a  max_len

// n'utilise plus code_zero  mais utilise le bit 48 de pos.
// Si *pos est nul, test le code zero
int	 read_file_bloc(Data_header_shared_memory   *dhs,FILE *file,Bloc_standard *blk,long *pos,int max_len,int convert)
// reecrit en novembre 2014
//retourne le type du bloc lut (-1 =fin de fichier   -2 = erreur)
{
	int length_buffer=12000;		// pour optimiser la vitesse: 12 koctets plus gros qu'un bloc kid ou pkid a 400 detecteurs
	//xxx int length_buffer=600000;		// pour optimiser la vitesse: 12 koctets plus gros qu'un bloc kid ou pkid a 400 detecteurs
	char *buffer = malloc(length_buffer);	// le buffer pour lire le fichier
	int code_zero=0;
	int type=0;
	int i,ii,j,k,len,q;
	int maxj;
	int nbbuf=0;
	long fpos;
	//char *buf = malloc(2*max_len);	// le buffer pour lire le bloc code_zero
	char *out = (char *) blk;
	int4 _debutswap=debut_block_mesure;
	_int4_swap(&_debutswap);
	if(!file)							{
		free(buffer);    //  pas de fichier ouvert
		return -2;
	}
	if(pos)	{

		if(*pos==0) {
			int code_zero = test_code_zero(file);
			if(code_zero ==-1) {
				free(buffer);    // fichier trop court: rien a lire
				return -1;
			}
			if(code_zero == 1)  *pos = _bit_code_zero;
		}
		// ici *pos  vaut zero ou _bit_code_zero
		code_zero	= _code_zero(*pos);
		fpos		= _pos_fich(*pos);
        if(debug) 	printf("\n   *pos  =  %lx    fpos = %ld ",*pos,fpos);
		//fpos=*pos;
		if ( fseek(file,fpos,SEEK_SET) )		{
			free(buffer);    // erreur de positionnement dans le fichier
			return -3;
		}
	} else	{
		fpos = ftell(file);
		printf("\n ERROR  : read_file_bloc avec pas de variable pos \n");
	}

	// ici  fpos est la position de depart de la recherche dans le fichier

	if(debug) printf("\n\nread_file bloc() debut code_zero=%d   position %d  ",code_zero,(int)fpos);

	nbbuf=fread(buffer,1,length_buffer,file);

	if(nbbuf < 16)					{
		free(buffer);    // erreur sur  fread: il reste moins de 4 mots dans le fichier
		return -1;
	}


	for(i=0; i<nbbuf-4; i++)		if( ((int4 *)((buffer)+i))[0] == _debutswap ) break; //-- cherche un indicateur de debut de bloc par pas de 1

	// si c'est bon,  i==0
	while(i)
        {	// si le debut n'est pas correct, j'avance de i et je relit le buffer
        if(debug) 	printf("\n fpos=%ld   maxlen=%d  nbbuf=%d  saute %d mots pour retrouver un bloc correct ",fpos,max_len,nbbuf,i);
		//printf("(%d) ",i);
		//printf(" $ ");
		fseek(file,fpos,SEEK_SET);			// repositionne au debut
		if(fseek(file,i,SEEK_CUR))		{
			free(buffer);    // erreur de positionnement dans le fichier
			return -3;
		}
		fpos = ftell(file);
		nbbuf=fread(buffer,1,length_buffer,file);
		if(nbbuf < 16)					{
			free(buffer);    // erreur sur  fread: il reste moins de 4 mots dans le fichier
			return -1;
		}
		for(i=0; i<nbbuf-4; i++)		if( ((int4 *)((buffer)+i))[0] == _debutswap ) break; //-- cherche un indicateur de debut de bloc par pas de 1
	}


	// le debut du bloc est dans buffer, il suffit de le de_code_zero dans blk  sans depasser  max_len caracteres
	// je le de_code_zero en le copiant dans out et en le deswappant: out est deswappe
	// la longueur du bloc est connue quand on a les 8 premiers caracteres du bloc
	// je dois m'arreter quand j=len (on a alors jamais de zero car le code fin_de_block n'en contient pas
	//printf("\n lecture un bloc avec max_len=%d  ",max_len);
	//for(i=0;i<100;i++) printf(" %x",buf[i]&0x0ff);


	maxj=max_len;
	j=0;
	len=-1;
	ii=0;
	while(j<maxj) {
		//printf("\n  j=%d  len=%d  nbbuf=%d  max_len=%d  maxj=%d",j,len,nbbuf,max_len,maxj);
		for(i=0; i<nbbuf; i++) {
			if(code_zero &&  (i==nbbuf-1) && (buffer[i]==0) ) break;  // je sort pour lire la suite avant de traiter le dernier point
			out[swap_bloc(j)]=buffer[i];
			j++;
			if(j>=maxj)			{
				i++;
				break;
			}

			if( code_zero && (buffer[i]==0) ) {
				i++;
				for(k=(unsigned char)buffer[i]; (k>1) && (j<maxj); k--) {
					out[swap_bloc(j)]=0;
					j++;
					if(j>=maxj)			break;
				}
			}

			if( (len==-1) && (j>=8) ) {
				// j'ai deja lu 2 mots de 4 byte, je peux savoir la longueur du bloc
				len=longueur_bloc((Bloc_standard *)blk);
				if( len < maxj ) maxj=len;
				//printf("\n trouve bloc l=%d \n",len);
			}
			if(j>=maxj) 	{
				i++;    // j'ai fini de lire le bloc mais il faut incrementer i
				break;
			}
		}

		ii+=i;
		//printf(" i=%d   ii=%d ",i,ii);


		if( j<maxj ) {
			// le buffer est trop petit, il faut lire le suivant
			// je recopie la fin du buffer de i a nbuf, au debut (j'ai deja lut buf[i]
			for(q=0; i<nbbuf;)	buffer[q++]=buffer[i++];
			//printf(" recopie buffer q=%d ",q);
			nbbuf=fread(buffer+q,1,length_buffer-q,file);
			if(nbbuf < 1)					{
				free(buffer);    // erreur sur  fread: plus rien a lire
				return -1;
			}
			nbbuf+=q;
		}
	}

	// ici j'ai bien lut tout le bloc
	type=type_bloc(blk);



	if( (maxj==len) && dhs) {	// ne verifie le bloc que si j'ai lut un bloc complet
		if(debug)
			{
			int err=_verifie_bloc(dhs,blk);
			
			if(err) {
				Def_nom_block
				printf("\n ERROR verification du bloc type %s err=%d ",nom_block[type],err);
				/*			printf("\n  longueur du bloc = %d",longueur_bloc(blk));
							printf("\n  type   du bloc = %d",type_bloc(blk));
							printf("\n  size_bloc(dhs,type_bloc(blk)) = %d",_size_bloc(dhs,type_bloc(blk)));
							printf("\n  size_bloc(dhs,21) = %d",_size_bloc(dhs,1));
							printf("\n  dhs->nb_pt_bloc = %d",dhs->nb_pt_bloc);
							printf("\n  dhs->nb_brut_c = %d",dhs->nb_brut_c);
							printf("\n  dhs->nb_detecteurs = %d",dhs->nb_detecteurs);
							printf("\n  dhs->nb_brut_d = %d",dhs->nb_brut_d);
							printf("\n  dhs->nb_brut_periode = %d",dhs->nb_brut_periode);*/
					}
			}
		
	}

	// ici i est le nombre d'octets du bloc avec le codage des zero dans le fichier
	// par contre, le bloc avec ses zero est copie dans out (idem blk)
	// si le type est comprime, je le decomprime en changeant le type


	//printf("\n decompression du bloc terminee avec i=%d  j=%d ",i,j);
	//printf("\n decode_zero :  ",max_len);  for(k=0;k<1000;k++) printf(" %x",out[k]&0x0ff);
	//printf("\n decode_zero1000 :  ",max_len); for(k=1000;k<1100;k++) printf(" %x",out[k]&0x0ff);
	//printf("\n decode_zero10000 :  ",max_len); for(k=10000;k<10100;k++) printf(" %x",out[k]&0x0ff);
	if(type<1) printf("\n ANORMAL : je trouve un type <1 dans read file bloc \n");


	if(pos) {
		fpos=fpos+ii;
		if(code_zero)	*pos = _bit_code_zero + fpos;
		else			*pos = fpos;
	} else {
		fseek(file,fpos,SEEK_SET);	// remet le fichier au debut du bloc
		fseek(file,ii,SEEK_CUR);		// avance de la longueur du bloc
		//if(pos) *pos = ftell(file);			// relit la position
	}

	Def_nom_block
	if(debug) printf("\nread_file bloc() fin fpos=%ld  *pos=%lx  bloc type %d %s ",fpos,*pos,type,nom_block[type]);
	//	printf(" l=%d ",longueur_bloc(blk));


// le traitement des blocs comprime et des blocs mini est inutile dans param
#ifndef _PARAM_

	if(dhs && convert) { // ne fait la decompression que si dhs est connu et si convert==1
		if(type==bloc_comprime8 ) {	// converti le bloc comprime en bloc brut
			decomprime8(dhs,blk->data);
			_valide_bloc(dhs,blk,bloc_brut,numero_bloc(blk) );
			type=bloc_brut;
		}

		if(type==bloc_comprime10 ) {	// converti le bloc comprime en bloc brut
			decomprime10(dhs,blk->data);
			_valide_bloc(dhs,blk,bloc_brut,numero_bloc(blk) );
			type=bloc_brut;
		}
		if(type==bloc_comprime10d ) {	// converti le bloc comprime en bloc brut
			decomprime10d(dhs,blk->data);
			_valide_bloc(dhs,blk,bloc_brut,numero_bloc(blk) );
			type=bloc_brut;
		}

		if(type==bloc_mini ) {	// converti en bloc brut sur place
			int num=numero_bloc(blk);
		if(debug) printf("\n bloc mini num=%d ",num);
			bloc_mini_to_bloc_brut(dhs,blk->data);
			_valide_bloc(dhs,blk,bloc_brut,num );
			type=bloc_brut;
		}
	}

	if(debug==2)	// apres la decompression
		{
		Def_nom_block
		printf("\nread_file bloc(): fpos=%ld   type %d %s ",fpos,type,nom_block[type]);
		printf(" l=%d ",longueur_bloc(blk));
		}

#endif      //    #ifndef _PARAM_
	free(buffer);
	return type;
}



/*****************************************
*			   swap header               *
*****************************************/



void	swap_header(Data_header_shared_memory *dhs) {
	// ici on doit deswapper tous les mots du header contenant des chaines de caracteres
	// en effet, le header a ete swappe globalement lors de la lecture du fichier
#ifdef __BIG_ENDIAN__
	int i;
	int4 *buf = (int4 *) dhs;
	int a,b;

	//---------   swap  des noms de reglage et de param   ----------------------------------
	a =_len_header_shared_memory(dhs)/4;
	b=_len_header_shared_memory(dhs)/4 + 2*dhs->nb_champ_reglage + 2*(dhs->nb_param_c+dhs->nb_param_d);
	for( i= a ; i< b  ; i++)   _int4_swap(buf[i]);

	//---------   swap  des noms de brut et de data    ----------------------------------
	a =_len_total_reglage_param_shared_memory(dhs)/4;
	b=_len_total_reglage_param_shared_memory(dhs)/4 + 2*(dhs->nb_brut_c + dhs->nb_brut_d)
	  + 4 * (dhs->nb_data_c + dhs->nb_data_d);
	for( i= a ; i< b  ; i++)   _int4_swap(buf[i]);
#else
	(void) dhs;
#endif
}


/****************************************************
*				read_nom_file_header					*
****************************************************/
// fourni un header avec appel de  position_header()
//  n'utilise plus la variable  code_zero
Data_header_shared_memory 	*read_nom_file_header(char *nom_fich,int print) {
	//printf("\n read nom file header avec silent=%d  \n",print);
	FILE *file = fopen(nom_fich,"rb");
	if(!file)		{
		printf("\n Ne trouve pas le fichier  %s \n",nom_fich);
		return 0;
	}
	if(print) printf("\n\n------------------------------------------------------------------------------------------------------------------------");
	if(print) printf("\n read_nom_file_header: %s    ",nom_fich);
	if(print) printf("\n------------------------------------------------------------------------------------------------------------------------\n");

	//printf("\n  read_nom_file_header()  print=%d  \n",print);
	Data_header_shared_memory *dhs = read_file_header(file,print);
	if(print) printf("\n\n------------------------------------------------------------------------------------------------------------------------");
	if(print) printf("\n fin de read_nom_file_header   ");
	if(print) printf("\n------------------------------------------------------------------------------------------------------------------------\n");
	fclose(file);
	return dhs;
}


/****************************************************
*				read_file_header					*
****************************************************/
// fourni un header avec appel de  position_header()
//  n'utilise plus la variable  code_zero
Data_header_shared_memory 	*read_file_header(FILE *file,int print) {
	Data_header_shared_memory *dhs;
	int len_debut_header=sizeof(Data_header_shared_memory) + sizeof(Bloc_standard);
	long  position_fich=0;
	Bloc_standard *blkheader_provisoire = malloc(len_debut_header );	// uniquement l'entete du header
	Data_header_shared_memory *Dhs1 = (Data_header_shared_memory *) (blkheader_provisoire->data);

	//printf("\n  read_file_header()  print=%d  \n",print);

	//printf("\n cherche_header_fichier() avec codezero=%d  ",code_zero);
	// premiere lecture avec une memoire provisoire pour ne lire que le debut du header
	rewind(file);
	if(debug) printf(" code_zero==%d  \n", test_code_zero(file) ? 1 : 0);

	if(test_code_zero(file) )	position_fich=_bit_code_zero;
	else						position_fich=0;

	if(debug) printf("\n dans read header  on a  position_fich = %lx  ",position_fich);

	if( read_file_bloc(NULL,file,(Bloc_standard *) blkheader_provisoire,&position_fich,len_debut_header,0)!= bloc_header) {
		printf("\n dans cherche header_fichier  ne trouve pas le 1er bloc ");
		return 0;
	}
	if(debug) printf("\n apres le 1er read_bloc  position_fich = %lx  ",position_fich);

	if(print) printf("\nDebut header %4.1f koctets : %d boites avec  %d champs reglage ",((double)Dhs1->lg_header_util)/1024.,Dhs1->nb_boites_mesure,Dhs1->nb_champ_reglage);

	Bloc_standard *blkheader=malloc(Dhs1->lg_header_util + sizeof(Bloc_standard) );	// juste la place pour lire le bloc header
	//Bloc_standard * blkheader = malloc(_len_header_complet(Dhs1)+ sizeof(Bloc_standard));			// la place pour le dhs complet
	rewind(file);
	position_fich=0;
	// seconde lecture apres allocation de la memoire necessaire
	if( read_file_bloc(NULL,file,(Bloc_standard *) blkheader,&position_fich,Dhs1->lg_header_util + sizeof(Bloc_standard),0) != bloc_header ) {
		printf("\n pas de header en debut de fichier ");
		return 0;
	}
	//printf("\n reglage : ");
	//----  je copie le header dans la zone allouee pour un dhs  complet
	// J'aurais pu allouer toute la memoire pour blkheader et la copie n'aurait pas ete necessaire
	dhs = malloc(_len_header_complet((Data_header_shared_memory *)blkheader->data));			// le dhs complet
	memcpy(dhs, blkheader->data, Dhs1->lg_header_util);	// je copie la partie util du dhs

	swap_header(dhs);		//   ???  pourquoi ???

	free(blkheader_provisoire);
	free(blkheader);

	if(print) print_noms_presents(dhs);		// affiche les noms de toutes les variables presentes dans le fichier

	position_header(dhs,0);


	/*
	if(print)
		{
		printf("\n _size_bloc_brut = %d  ", (int)_size_bloc_brut(dhs));
		printf(" _size_bloc_header=%d  ", (int)_size_bloc_header(dhs));
		printf("_size_bloc_modele=%d ",(int)_size_bloc_modele(dhs));
		}
	*/
	return dhs;
}

