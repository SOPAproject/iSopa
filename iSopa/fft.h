//
//  fft.h
//  iSopa
//
//  Created by 郁 蘆原 on 12/07/11.
//  Copyright (c) 2012年 AIST. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface fft : NSObject{
    UInt16 uTap;
}

@property UInt16 uTap;

-(id)initWithFrameSize:(UInt16)Tap;
-(BOOL)fastFt:(double *)real:(double *)image:(BOOL)isInv;
-(BOOL)isPowerOfTwo;

@end
