#pragma OPENCL EXTENSION cl_khr_fp64 : enable


uint ThomasWangHash(uint key)
{
    key = (~key) + (key << 21); // key = (key << 21) - key - 1;
    key = key ^ (key >> 24);
    key = (key + (key << 3)) + (key << 8); // key * 265
    key = key ^ (key >> 14);
    key = (key + (key << 2)) + (key << 4); // key * 21
    key = key ^ (key >> 28);
    key = key + (key << 31);
    //return (double)5.42101086242752217E-20 * (double)key;
    return key;
}

uint wang_hash(uint seed)
{
    seed = (seed ^ 61) ^ (seed >> 16);
    seed *= 9;
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return seed;
}

float wang_rnd(uint seed)
{
    uint maxint=0;
    maxint--; // not ok but works
    uint rndint=wang_hash(seed);
    return ((float)rndint)/(float)maxint;
}

__kernel void localjc(const int n, const int permutations, const unsigned long last_seed, const unsigned long num_vars, __global int *zz,  __global double *local_jc,  __global int *num_nbrs, __global int *nbr_idx, __global double *p) {
    
    // Get the index of the current element
    size_t i = get_global_id(0);

    if (i >= n) {
        return;
    }
    if (local_jc[i] == 0) {
        p[i] = 0;
        return;
    }
   
    size_t j = 0;
    size_t seed_start = i + last_seed;
    
    size_t numNeighbors = num_nbrs[i];
    if (numNeighbors == 0) {
        return;
    }
    
    size_t nbr_start = 0;
    
    for (j=0; j <i; j++) {
        nbr_start += num_nbrs[j];
    }
    
    size_t max_rand = n-1;
    int newRandom;
    
    size_t perm=0;
    size_t rand = 0;
    
    bool is_valid;
    double rng_val;
    double permutedLag = 0;
    double localJC=0;
    size_t countLarger = 0;
    size_t rnd_numbers[123]; // 1234 can be replaced with max #nbr
    
    for (perm=0; perm<permutations; perm++ ) {
        rand=0;
        permutedLag =0;
        while (rand < numNeighbors) {
            is_valid = true;
            rng_val = wang_rnd(seed_start++) * max_rand;
            newRandom = (int)rng_val;
          
            if (newRandom != i ) {
                for (j=0; j<rand; j++) {
                    if (newRandom == rnd_numbers[j]) {
                        is_valid = false;
                        break;
                    }
                }
                if (is_valid) {
                    permutedLag += zz[newRandom];
                    rnd_numbers[rand] = newRandom;
                    rand++;
                }
            }
        
        }
        if (permutedLag >= local_jc[i]) {
            countLarger++;
        }
    }
    
    // pick the smallest
    if (permutations-countLarger < countLarger) {
        countLarger = permutations-countLarger;
    }
    
    double sigLocal = (countLarger+1.0)/(permutations+1);
    p[i] = sigLocal;
}
