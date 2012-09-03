//
//  fft.m
//  iSopa
//
//  Created by 郁 蘆原 on 12/07/11.
//  Copyright (c) 2012年 AIST. All rights reserved.
//

#import "fft.h"

@implementation fft

@synthesize uTap;

-(id)initWithFrameSize:(UInt16)Tap{
    self = [super init];
    uTap = Tap;
    return self;
}

-(BOOL)fastFt:(double *)dData:(double *)dImg:(BOOL)isInv{
    double sc,f,c,s,t,c1,s1,x1,kyo1;
    double dHan,dPower,dPhase;
    double dPi = M_PI * 2;
    int n,n1,j,i,k,ns,l1,i0,i1;
    int iInt;
    
    if(!isInv){
        for(iInt = 0;iInt < uTap;iInt ++)
        {
            dImg[iInt] = 0;														// Imaginary part 
            dHan = (1 - cos((dPi * (double)iInt) / (double)uTap)) / 2;          // Hanning Window 
            dData[iInt] *= dHan;												// Real part 
        }
    }	
    
    n = uTap;	/* NUMBER of DATA */
    n1 = n / 2;
    sc = M_PI;
    j = 0;
    
    for(i = 0;i < n - 1;i ++)
    {
        if(i <= j)
        {
            t = dData[i];  dData[i] = dData[j];  dData[j] = t;
            t = dImg[i];   dImg[i] = dImg[j];   dImg[j] = t;
        }
        k = n / 2;
        while(k <= j)
        {
            j = j - k;
            k /= 2;
        }
        j += k;
    }
    
    ns = 1;
    if(isInv)															// reverse
        f = 1.0;
    else
        f = -1.0;
    
    while(ns <= n / 2)
    {
        c1 = (double)cos(sc);
        s1 = (double)sin(f * sc);
        c = 1.0;
        s = 0.0;
        for(l1 = 0;l1 < ns;l1 ++)
        {
            for(i0 = l1;i0 < n;i0 += (2 * ns))
            {
                i1 = i0 + ns;
                x1 = (dData[i1] * c) - (dImg[i1] * s);
                kyo1 = (dImg[i1] * c) + (dData[i1] * s);
                dData[i1] = dData[i0] - x1;
                dImg[i1] = dImg[i0] - kyo1;
                dData[i0] = dData[i0] + x1;
                dImg[i0] = dImg[i0] + kyo1;
            }
            t = (c1 * c) - (s1 * s);
            s = (s1 * c) + (c1 * s);
            c = t;
        }
        ns *= 2;
        sc /= 2.0;
    }
    
    if(!isInv)
    {
        for(iInt = 0;iInt < uTap;iInt ++)
        {
            dData[iInt] /= (double)uTap;
            dImg[iInt] /= (double)uTap;
            dPower = sqrt(dData[iInt] * dData[iInt] + dImg[iInt] * dImg[iInt]);
            dPhase = atan2(dImg[iInt],dData[iInt]);
            dData[iInt] = dPower;
            dImg[iInt] = dPhase;
        }
    }
    return true;
}

-(BOOL)isPowerOfTwo{
    return uTap > 0 && (uTap & (uTap - 1)) == 0;  
}

-(void)dealloc{
    [super dealloc];
}

@end
