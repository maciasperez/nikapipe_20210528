#ifndef __KID_FLAG_H
#define __KID_FLAG_H


extern void	calcul_ftone_tangle_flagkid(Data_header_shared_memory * dhs,int4* br,int nper,
										double* ftone,double* tangle,int* flagkid);

extern void	comprime8(Data_header_shared_memory * dhs,int4* data);
extern void	decomprime8(Data_header_shared_memory * dhs,int4* data);
extern void	comprime10(Data_header_shared_memory * dhs,int4* data);
extern void	decomprime10(Data_header_shared_memory * dhs,int4* data);

#define	_size_data_comprime8(dhs)	sizeof(int4) * 10 * (dhs->nb_brut_c + dhs->nb_brut_d * dhs->nb_detecteurs)
#define	_size_data_comprime10(dhs)	sizeof(int4) * 13 * (dhs->nb_brut_c + dhs->nb_brut_d * dhs->nb_detecteurs)

#endif // __KID_FLAG_H
