#ifndef __BLOC_COMPRIME_H
#define __BLOC_COMPRIME_H

//=================================================================================================================
//========================     la compression  des  blocs  brut					===================================
//=================================================================================================================


extern void	comprime8    (Data_header_shared_memory *dhs,int4 *data);
extern void	decomprime8  (Data_header_shared_memory *dhs,int4 *data);
extern void	comprime10   (Data_header_shared_memory *dhs,int4 *data_comprime,int4 *data);
extern void	decomprime10 (Data_header_shared_memory *dhs,int4 *data);
extern void	comprime10d  (Data_header_shared_memory *dhs,int4 *data_comprime,int4 *data);
extern void	decomprime10d(Data_header_shared_memory *dhs,int4 *data);

extern int	bloc_brut_to_bloc_mini(Data_header_shared_memory *dhs,int num_liste,Bloc_standard *bktp2,Bloc_standard *bktp);
extern void	bloc_mini_to_bloc_brut(Data_header_shared_memory *dhs,int4 *data);

// cree la liste detecteur dans liste_det2  si type>0 prend au depart  liste_detecteurs //  si type <0 cree la liste en foncion du type
//											si liste_bloc_mini != NULL  ne garde que les detecteurs de la liste du bloc mini
// je copie aussi ma nouvelle liste dans  liste_detecteurs et je mets sa longueur dans  dhs->nb_det_mini
extern int4 *cree_list_det(Data_header_shared_memory *dhs,int nb_detecteurs_lut,int4 *liste_detecteurs,int4 *liste_bloc_mini);


// je crees les bloc_zero qui contiennent un bloc dont on a code les zero
// dans l'entete le type est  bloc_zero et la longueur celle du bloc
// ensuite on a les data qui contiennent le code_longueur et le code2 du bloc original
// le buffer blk doit etre assez grand pour le bloc zero et pour le bloc original
extern void	bloc_to_bloc_zero(Bloc_standard *blk);
extern void	bloc_zero_to_bloc(Bloc_standard *blk);


// les types de fichiers sont :
//      -  les fichiers pairs (0,2,4,...)  les fichiers internes
//      -  les fichiers impairs (1,3,5,...)  les fichiers externe sur la machine linuxnikadata
//  -  le fichier   normal   :   0 et 1
//  -  le fichier comprime   :   2 et 3
// les fichiers mini a la suite
#define	_nb_max_fichiers_mini 10									// le nombre maxi de liste de detecteurs
#define	_nb_max_type_fichiers (4+2*_nb_max_fichiers_mini)			// le nombre maxi de fichiers a ecrire


#endif // #define __BLOC_COMPRIME_H


