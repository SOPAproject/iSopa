//
//  SopaQueue.h
//  iSopa
//
/*
 Copyright (c) 2012, AIST
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "fft.h"

@interface SopaQueue : NSObject {
    AudioQueueRef sopaQueueObject;
    UInt32 ExtBufSize;
    UInt32 numPacketsToRead;
    UInt32 numBytesWritten;
    UInt32 numOffset;
    UInt32 numSampleRate;
    SInt16 *sHrtf;
    SInt16 *sPhase;
    UInt32 nBytesRead;
    BOOL nTrial;
    SInt32 iRatio;
    SInt16 iSize;
    SInt16 iProc;
    SInt16 iFrames;
    SInt16 iRem;
    SInt16 iHlf;
    SInt16 iOverlapFactor;
    SInt16 iRot;
    NSURLConnection *myConn;
    NSMutableData *mData;
    NSString *urlStr;
    BOOL isPrepared;
    BOOL isPlaying;
    BOOL isLoaded;
    SInt16 *ResultLeft;
    SInt16 *ResultRight;
}

@property UInt32 ExtBufSize;
@property UInt32 numBytesWritten;
@property UInt32 numOffset;
@property UInt32 nBytesRead;
@property BOOL nTrial;
@property BOOL isLoaded;
@property SInt32 iRatio;
@property SInt16 iSize;
@property SInt16 iProc;
@property SInt16 iFrames;
@property SInt16 iRem;
@property SInt16 iHlf;
@property SInt16 iOverlapFactor;
@property (retain)NSURLConnection *myConn;
@property (retain)NSMutableData *mData;
@property (retain)NSString *urlStr;
@property (assign)SInt16 *sHrtf;
@property (assign)SInt16 *sPhase;
@property (assign)SInt16 *ResultLeft;
@property (assign)SInt16 *ResultRight;

-(void)setNumSampleRate:(UInt32)uNum;
-(UInt32)numSampleRate;
-(void)play;
-(BOOL)loadDatabase;
-(void)prepareSopaQueue;
-(void)stop:(BOOL)shouldStopImmediate;
-(void)setNumPacketsToRead:(UInt32)nNum;
-(UInt32)numPacketsToRead;
-(void)setIRot:(SInt16)rot;
-(SInt16)iRot;
-(SInt16)getData:(UInt32)nNum;
-(void)setIsPlaying:(BOOL)yn;
-(BOOL)isPlaying;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end
