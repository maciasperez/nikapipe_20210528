#ifndef _READDATA_H
#define _READDATA_H

//=============================================================================================
//=============================================================================================
//==============																===============
//==============	Les prototypes des fonctions externes de readdata			===============
//==============																===============
//=============================================================================================
//=============================================================================================

#ifndef int4
#define int4 int
#endif

//------------  pour lire un fichier nika :
//--  reserver un tableau d'entiers 4 octets  buffer_header et donner sa longueur (en nombre de mots 4 octets)
//--  appeler la fonction read_nika_start avec le nom de fichier, la liste des data demandees et le tableau vide
//--  le programme retourne une erreur si le tableau est trop petit ou si le fichiier est mauvais
// si tout va bien, il rempli le tableau avec le header nika ou l'on peu retrouver param et reglage
// il retourne  le nombre de sample contenu dans le fichier  (0 s'il y a une erreur)


//-----  ensuite appeler en boucle  read nika_suite avec :
//---      le nom du fichier,et le pointeur sur le buffer_header  prealablement lut avec read_nika_start
//---  un buffer pour stocker les data (en double) et la longueur du buffer (nombre de mots double)
//---  un buffer temporaire avec   malloc(_total_length_buf_btd)   pour les calculs de brut to data
//---  (si le pointeur de buffer temporaire est nul, c'est brut to data qui cree le buffer garde en static dans read nika suite
//---   le programme lira autant de sample que possible compte tenu de la taille du buffer.
//-- le programme retourne le nombre de sample lut
//---  il faut appeler read nika_suite  jusqu'a ce qu'il retourne zero

//int read_nika_start(char* fichier,int length_buf,int4* buffer_header,char* liste_data,int type_listdet,int4* listdet,int silent);

//int		read_nika_suite(char* fichier,int4* buffer_header,int4* listdet,double *buffer_data,int length,int* buffer_data_periode,char* buffer_temp, int silent);

extern int read_nika_start(char *fichier, int length_buf, int4 *buffer_header, char *liste_data, int type_listdet,int4 *listdet,int silent);
extern int read_nika_suite(char *fichier,                 int4 *buffer_header,                                    int4 *listdet,
					double *buffer_data,int length_buf_data,int *buffer_data_periode,char *buffer_temp,                  int silent);

extern int		read_nika_length_temp_buffer(int4 *buffer_header);
extern int		read_nika_indice_param_c(int4 *buffer_header);
extern void	read_nika_noms_var_all(int4 *buffer_header,char *nom);

extern void	send_nika_geometrie(int nb_detecteurs_lu,int4 *raw_number,int4 *x_pix,int4 *y_pix);


//=============================================================================================
//==============	Les prototypes internes qui necessitent a_memoire.h			===============
//=============================================================================================

//-----        Ils sont dans  readbloc.h

#endif

