// Function to coadd data
void map_coadd(int ndata, double *data, double *w8, long *px, long *py, long nxmap, long nymap, double *map. double *nhits)
{

  long pos = 0;
  // Simple projection in to the map
  for (int index =0; index < ndata; index++)
    {
      pos = py[index] * nmap + px[index];
      map[pos]   += (data[index] * w8[index]);
      nhits[pos] += w8[index];
         
    }

  // Normalize
  for (int index=0,nxmap*nymap){
    if nhits[index] > 0.0
	      {
		map[index] /= nhits[index];
	      }
  }

}
