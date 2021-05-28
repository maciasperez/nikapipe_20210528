#include "comprime10.h"

int main(int argc, char *argv[])
{
  char *filename;
  char myfile[500];
  filename = (char *)  argv[1];
  sprintf(myfile,"%s",filename);
  printf("\ncomprime8  file  : %s ",filename);
 
  
int length = 100000;
int code_zero = 1;
int4 * buffer_header = malloc(length*sizeof(int4));
int type=0;
  
  //============================================================================================
  //==========						READ  NIKA  START							================
  int nsample= read_nika_start(filename," ",buffer_header,length,1);
//==========																	================
  //============================================================================================
 if(nsample<1) {printf("\n error in reading the file %s ",filename);return 0;}

	printf("\n read_nika_start  :   %d  sample",nsample);


 Data_header_shared_memory * dhs = (Data_header_shared_memory * ) buffer_header ;

int size_bloc_standard = _len_brut_bloc_shared_memory(dhs) + sizeof(Bloc_standard) ;
// printf("size_bloc_standard %ld",size_bloc_standard);

Bloc_standard*  blk=(Bloc_standard*)malloc(size_bloc_standard);
// printf("blk %x",blk);
FILE * file = fopen(filename,"rb");
char fichwrite[1000];
int i;
int lfichbrut=0;
int lfichcomp=0;
int lfichcompzero=0;
strcpy(fichwrite,filename);
for(i=strlen(fichwrite)-2;i>0;i--)	if(fichwrite[i]=='/') break;
for(i=i-1;i>0;i--)	if(fichwrite[i]=='Y')	{fichwrite[i]='X';break;}

if(i<1) {printf(" pas possible de creer le nom de fichier ");return;}

FILE * filewrite = fopen(fichwrite,"wb+");
if(!filewrite) {printf(" pas possible de creer fichier %s ",fichwrite);return;}
printf("\n ecriture fichier %s ",fichwrite);
printf("\n size bloc brut=%d k  size bloc comprime=%d k  \n",(int)_size_bloc_brut(dhs)/1024,(int)_size_bloc_comprime10(dhs)/1024);
while(type>=0)	//------------  boucle sur la lecture des blocs dans le fichier  ----------------------------
	{
	//Def_nom_block
	int type = lecture_bloc_fichier(file,code_zero,blk,size_bloc_standard,dhs);
	//printf("type= %d  soit  %s  \n",type,nom_block[type]);

	if(type==bloc_brut)
		{
		int num = numero_bloc(blk);
		lfichbrut+=longueur_bloc(blk);
		//printf("BLOC_BRUT  num=%d  \n",num);
		if(!(num%10)) printf(".");
		comprime10(dhs,blk->data);
		_valide_bloc(dhs,blk,bloc_comprime10,num);
		}

	if(type<=0) break;
	lfichcomp+=longueur_bloc(blk);

{
int long_b=longueur_bloc(blk);
char* buf = malloc(long_b*2);	// pour etre sur d'avoir la place
char* in = (char*) blk;
int i,j,k;

j=0;
for(i=0;i<long_b;i++)
	{
	buf[j]=in[i];
	j++;
	if(in[i]==0)
		{
		k=1;
		while( (i+1<long_b) && (in[i+1]==0) && (k<250)	) {k++;i++;}
		buf[j]=k;
		j++;
		}
	}
lfichcompzero+=j;
fwrite(buf,1,j,filewrite);
free(buf);
}
	}
printf("\n fin de compression  \n");
//printf("\n lfichbrut=%d  lfichcomp=%d  lfichcompzero=%d ",lfichbrut,lfichcomp,lfichcompzero);
free(blk);

fclose(file);
fclose(filewrite);

return 0;
}
