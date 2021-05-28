function permut, seed,  nel
                                ; Function to permute nel elements
                                ; randomly with a bijection from
                                ; 0,nel-1 to 0,nel-1
                                ; seed is to be able to reproduce the
                                ; randomisation if needed
                                ; FXD May 2020, to simulate random kid
                                ; position
radist = randomu(seed, nel, /double)
return, sort( radist)
end
