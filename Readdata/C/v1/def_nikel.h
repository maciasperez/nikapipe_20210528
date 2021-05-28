#ifndef __DEF_NIKEL__
#define __DEF_NIKEL__


//================================================================================================================================
//===================			la largeur de resonnance et le flag dans le reglage					==============================
//================================================================================================================================

// dans le reglage la largeur est en 0.001 bin
// dans le param elle est en Hz


//uint4* RG_width=reglage_pointer(dhs,_r_k_width,z);

#define _flag_du_reglage(RG_width,nkid)				(RG_width[nkid]&0xff)
#define _width_du_reglage(RG_width,nkid)			((RG_width[nkid]&0x8fffff00)>>8)		// la largeur en bin/1000

#define _code_width_flag(width,flag)				( ((width)<<8) | ((flag)&0xff) )

//RG_width[kid] = _code_width_flag(width,flag);




#endif	//  #ifndef __DEF_NIKEL__

