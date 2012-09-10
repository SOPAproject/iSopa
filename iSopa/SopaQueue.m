//
//  SopaQueue.m
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

#import "SopaQueue.h"

@implementation SopaQueue

@synthesize ExtBufSize;
@synthesize myConn;
@synthesize mData;
@synthesize urlStr;
@synthesize numBytesWritten;
@synthesize numOffset;
@synthesize nBytesRead;
@synthesize nTrial;
@synthesize isLoaded;
@synthesize iRatio;
@synthesize iSize;
@synthesize iProc;
@synthesize iFrames;
@synthesize iRem;
@synthesize iHlf;
@synthesize iOverlapFactor;
@synthesize sHrtf;
@synthesize sPhase;
@synthesize ResultLeft;
@synthesize ResultRight;

-(void)setNumSampleRate:(UInt32)nNum{
    numSampleRate = nNum;
}

-(UInt32)numSampleRate{
    return numSampleRate;
}

-(void)setNumPacketsToRead:(UInt32)nNum{
    numPacketsToRead = nNum;
}

-(UInt32)numPacketsToRead{
    return numPacketsToRead;
}

-(void)setIRot:(SInt16)rot{
    iRot = rot;
}

-(SInt16)iRot{
    return iRot;
}

-(void)setIsPlaying:(BOOL)yn{
    isPlaying = yn;
}

-(BOOL)isPlaying{
    return isPlaying;
}

-(id)init{
    self = [super init];
    
    ExtBufSize = 16384;
    [self setNumPacketsToRead:ExtBufSize / 4];
    [self setIRot:0];
    
    return self;
}

-(BOOL)loadDatabase{
    NSURL *hrtfUrl,*phaseUrl;
    NSURL *sopaUrl;
    
    //  Prepare HRTF database
    SInt32 nInt;
    NSData *val0,*val1;
    NSMutableData *data0,*data1;
    
    sHrtf = (malloc(sizeof(SInt16) * 36864));
    sPhase = (malloc(sizeof(SInt16) * 36864));

    NSRange rang = [self.urlStr rangeOfString:@"://"];
    if(rang.location == NSNotFound){
        NSLog(@"Search files in the application directories");
        hrtfUrl = [NSURL fileURLWithPath:
                   [[NSBundle mainBundle] pathForResource:@"hrtf512" ofType:@"bin"]];
        phaseUrl = [NSURL fileURLWithPath:
                   [[NSBundle mainBundle] pathForResource:@"phase512" ofType:@"bin"]];
    }
    else{
        sopaUrl = [[NSURL alloc]initWithString:self.urlStr];
        NSURL *newUrl = sopaUrl.URLByDeletingLastPathComponent;
        hrtfUrl = [newUrl URLByAppendingPathComponent:@"hrtf512.bin"];
        phaseUrl = [newUrl URLByAppendingPathComponent:@"phase512.bin"];
        
        [sopaUrl release];
    }
    data0 = [NSData dataWithContentsOfURL:hrtfUrl];
    if(data0 == nil)
        return NO;
    for(nInt = 0;nInt < 36864;nInt ++){
        val0 = [data0 subdataWithRange:NSMakeRange(nInt * 2,1)];
        val1 = [data0 subdataWithRange:NSMakeRange(nInt * 2 + 1,1)];
        sHrtf[nInt] = *(SInt16 *)[val0 bytes];
        sHrtf[nInt] += *(SInt16 *)[val1 bytes] * 256;
    }
    NSLog(@"HRTF (level) ready");
    //    [data0 release];
    
    data1 = [NSData dataWithContentsOfURL:phaseUrl];
    if(data1 == nil){
        return NO;
    }
    for(nInt = 0;nInt < 36864;nInt ++){
        val0 = [data1 subdataWithRange:NSMakeRange(nInt * 2,1)];
        val1 = [data1 subdataWithRange:NSMakeRange(nInt * 2 + 1,1)];
        sPhase[nInt] = *(SInt16 *)[val0 bytes];
        sPhase[nInt] += *(SInt16 *)[val1 bytes] * 256;
    }
    NSLog(@"HRTF (phase) ready");
    //    [data1 release];
    
    isPrepared = NO;
    [self setIsPlaying:NO];
    return YES;
}

-(void)prepareSopaQueue{
    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate = numSampleRate;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 2;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerPacket = 4;
    audioFormat.mBytesPerFrame = 4;
    audioFormat.mReserved = 0;
    
    AudioQueueNewOutput(&audioFormat,outputCallback,self,NULL,NULL,0,&sopaQueueObject);
    
    AudioQueueBufferRef buffers[3];
    
    NSLog(@"numPacketsToRead = %lu",numPacketsToRead);
    UInt32 bufferByteSize = numPacketsToRead * audioFormat.mBytesPerPacket;
    
    int bufferIndex;
    for(bufferIndex = 0;bufferIndex < 3;bufferIndex ++){
        AudioQueueAllocateBuffer(sopaQueueObject,bufferByteSize,&buffers[bufferIndex]);
        outputCallback(self,sopaQueueObject,buffers[bufferIndex]);
    }
    isPrepared = YES;
    AudioQueueStart(sopaQueueObject, NULL);
}

-(void)play{
    NSURL *sopaUrl;
    
    NSRange rang = [self.urlStr rangeOfString:@"://"];
    if(rang.location == NSNotFound){
        NSLog(@"Check for a file path");
        NSString *tmpStr = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"gif"];
        NSString *newStr = [tmpStr stringByDeletingLastPathComponent];
        tmpStr = [newStr stringByAppendingPathComponent:self.urlStr];
        sopaUrl = [[NSURL alloc]initFileURLWithPath:tmpStr];
    }
    else {
        sopaUrl = [[NSURL alloc]initWithString:self.urlStr];
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:sopaUrl];
    
    isLoaded = NO;
    numBytesWritten = nBytesRead = 0;
    
    myConn = [[NSURLConnection alloc]initWithRequest : request delegate : self];
	if (myConn == nil) {
		UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle : @"ConnectionError"
                              message : @"ConnectionError"
                              delegate : nil cancelButtonTitle : @"OK"
                              otherButtonTitles : nil];
		[alert show];
        [alert release];    
        NSLog(@"Connection failed");
        return;
	}
    [sopaUrl release];
    
	// Initialize data stream
    self.mData = [[NSMutableData alloc] initWithData:0];
    [self setIsPlaying:YES];
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"Connected");
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    if(!isPlaying)
        return;
    //  Append data to data stream
    [[self mData] appendData:data];
    
    self.nBytesRead += [data length];
    
    //  Check file header
    if(self.nBytesRead > ExtBufSize * 4 && !nTrial){
        nTrial = YES;
        int nDat[4];
        int nTerm0[] = {82,73,70,70};   // RIFF
        int nTerm1[] = {83,79,80,65};   // SOPA
        int nTerm2[] = {102,109,116};   // fmt
        int nInt,nBit,nSampleRate;
        NSMutableData *val0;
        
        for(nInt = 0;nInt < 4;nInt ++){
            val0 = (NSMutableData *)[[self mData] subdataWithRange:NSMakeRange(nInt,1)];
            nDat[nInt] = *(int *)([val0 bytes]);
        }
        if(memcmp(nDat,nTerm0,4) != 0){
            NSLog(@"Format error!");
            [[self mData] release];
            val0 = nil;
            return;
        }
        for(nInt = 0;nInt < 4;nInt ++){
            val0 = (NSMutableData *)[[self mData] subdataWithRange:NSMakeRange(8 + nInt,1)];
            nDat[nInt] = *(int *)([val0 bytes]);
        }
        if(memcmp(nDat,nTerm1,4) != 0){
            NSLog(@"Format error!");
            [[self mData] release];
            val0 = nil;
            return;
        }
        for(nInt = 0;nInt < 3;nInt ++){
            val0 = (NSMutableData *)[[self mData] subdataWithRange:NSMakeRange(12 + nInt,1)];
            nDat[nInt] = *(int *)([val0 bytes]);
        }
        if(memcmp(nDat,nTerm2,3) != 0){
            NSLog(@"Format error!");
            [[self mData] release];
            val0 = nil;
            return;
        }
        val0 = (NSMutableData *)[[self mData] subdataWithRange:NSMakeRange(16,1)];
        nBit = *(int *)([val0 bytes]);
        if(nBit != 16){
            NSLog(@"Data are not 16-bit!");
            [[self mData] release];
            val0 = nil;
            return;
        }
        val0 = (NSMutableData *)[[self mData] subdataWithRange:NSMakeRange(20,1)];
        nBit = *(int *)([val0 bytes]);
        if(nBit != 1){
            NSLog(@"Data are not PCM!");
            [[self mData]release];
            val0 = nil;
            return;
        }
        val0 = (NSMutableData *)[[self mData] subdataWithRange:NSMakeRange(22,1)];
        iOverlapFactor = *(int *)([val0 bytes]);
        if(iOverlapFactor != 2 && iOverlapFactor != 4){
            NSLog(@"Wrong value!");
            [[self mData]release];
            val0 = nil;
            return;
        }
        val0 = (NSMutableData *)[[self mData] subdataWithRange:NSMakeRange(24,1)];
        nSampleRate = *(int *)([val0 bytes]);
        val0 = (NSMutableData *)[[self mData] subdataWithRange:NSMakeRange(25,1)];
        nSampleRate += *(int *)([val0 bytes]) * 256;
        NSLog(@"Sampling rate is %d Hz",nSampleRate);
        [self setNumSampleRate:nSampleRate];
        self.numOffset = 44;
        //        if(!isPrepared)
        [self prepareSopaQueue];    
        
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    isLoaded = YES;
    NSLog(@"\n%lu bytes read",nBytesRead);
    [connection release];
	NSString *error_str = [error localizedDescription];
	UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle : @"RequestError"
                              message : error_str delegate : nil
                              cancelButtonTitle : @"OK"
                              otherButtonTitles : nil];
	[alertView show];
    [alertView release];    
    NSLog(@"Error detected");
    if(nBytesRead == 0){
        [self setIsPlaying:NO];
        [self stop:YES];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// memory
    isLoaded = YES;
    NSLog(@"Finished");
    NSLog(@"\n%lu bytes read",nBytesRead);
    [connection release];
    if(!isPlaying)
        [[self mData]release];
}   

-(void)stop:(BOOL)shouldStopImmediate{
    AudioQueueStop(sopaQueueObject, shouldStopImmediate);
    isPrepared = NO;
    NSLog(@"Reproduction finished");
    NSLog(@"%lu bytes played",numBytesWritten);
    //    [self setNumBytesWritten:0];
    //    [self setNBytesRead:44];
    if(sopaQueueObject){
        AudioQueueDispose(sopaQueueObject,YES);
        sopaQueueObject = NULL;
    }
    nTrial = NO;
    
    if(isLoaded){
        [[self mData]release];
        isLoaded = NO;
    }
    else{
        [myConn cancel];
        [myConn release];
    }
    NSNotification* notification;
    notification = [NSNotification notificationWithName:@"sopaReproductionFinished" object:self]; 
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    
    // Post notification
    [center postNotification:notification];
    
    //    [self release];
    //    self = nil;
}

-(SInt16)getData:(UInt32)nNum{
    SInt16 sVal;
    unsigned char byte;
    
    if(nNum >= nBytesRead)
        sVal = 0;
    else{
        [mData getBytes: &byte range: NSMakeRange(nNum,1)]; 
        sVal = (SInt16)byte;
    }
    
    return sVal;
}

static void outputCallback(void *inUserData,AudioQueueRef inAQ,AudioQueueBufferRef inBuffer){
    SopaQueue *player = (SopaQueue *)inUserData;
    UInt32 iCount,iFnum,iOffset;
    UInt32 numPackets = [player numPacketsToRead];
    UInt32 numBytes = numPackets * sizeof(SInt16) * 2;
    SInt32 iInt,sSample,iNum,iPos,iPosImage;
    double dSpL,dSpR,dSpImageL,dSpImageR,dPhaseL,dPhaseR,dPhaseImageL,dPhaseImageR;
    double dHan;
    
    SInt16 nSin;
    
    SInt16 *output = inBuffer->mAudioData;
    
    if(!player.isPlaying){
        [player stop:YES];
        return;
    }
    else if(player.numOffset == 44){
        
        iInt = 5;
        sSample = 1;
        while(sSample > 0){
            sSample = [player getData:[player numOffset] + iInt];
            iInt += 4;
        }
        player.iSize = iInt - 5;                    // Frame size
        NSLog(@"Frame size is %d",player.iSize);
        player.iRatio = 44100 / [player numSampleRate];
        player.iRatio *= player.iSize / 512;
        player.iProc = player.iSize / player.iOverlapFactor;
        player.iFrames = numPackets / player.iProc;
        player.iRem = player.iSize - player.iProc;
        player.iHlf = player.iSize / 2;
        
        player.ResultLeft = (malloc(sizeof(SInt16) * [player iSize]));
        player.ResultRight = (malloc(sizeof(SInt16) * [player iSize]));
        
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"sopaInfo" object:player]; 
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
    }
    
    double realLeft[player.iSize + 1];
    double imageLeft[player.iSize + 1];
    double realRight[player.iSize + 1];
    double imageRight[player.iSize + 1];
    SInt16 dir[[player iSize] + 1];                 // Direction factor
    
    fft *trans;
    trans = [[fft alloc] initWithFrameSize:player.iSize];
    if(![trans isPowerOfTwo]){
        [player stop:YES];
        return;
    }
    
    for(iFnum = 0;iFnum < player.iFrames;iFnum ++){
        
        iOffset = [player numOffset];
        
        for(iCount = 0;iCount < player.iSize * 4;iCount += 4){
            if(iCount < player.iProc * 4){
                nSin = [player getData:iOffset + iCount];
                dir[iCount / 2 + 1] = nSin;
                nSin = [player getData:iOffset + iCount + 1];
                dir[iCount / 2] = nSin;                // Direction
                if(nSin > 72 || nSin < 0)
                    NSLog(@"Wrong value!");
            }
            nSin = [player getData:iOffset + iCount + 2];
            nSin += [player getData:iOffset + iCount + 3] * 256;
            realRight[iCount / 4] = nSin;               // PCM data
            imageRight[iCount / 4] = 0;
        }
        [trans fastFt:realRight:imageRight:NO];
        dir[player.iHlf] = 0;
        
        for(iNum = 0;iNum < player.iHlf;iNum ++){
            SInt32 iFreq = (iNum / player.iRatio);
            if(dir[iNum] <= 0 || iFreq == 0){
                dSpL = dSpR = realRight[iNum];
                dSpImageL = dSpImageR = realRight[iNum];
                dPhaseL = dPhaseR = imageRight[iNum];
                dPhaseImageL = dPhaseImageR = imageRight[iNum];
            }
            else{
                dir[iNum] += player.iRot;               // Add panning factor
                dir[iNum] -= 1;
                
                if(dir[iNum] > 71)
                    dir[iNum] -= 72;
                else if(dir[iNum] < 0)
                    dir[iNum] += 72;
                
                //              Construct Temporal HRTF by using HRTF database (left channel)
                iPos = 512 * (72 - dir[iNum]) + iFreq;
                iPosImage = 512 * (72 - dir[iNum]) + 512 - iFreq;
                if(iPosImage >= 36864)
                    iPosImage -= 36864;
                else if(iPosImage < 0)
                    iPosImage += 36864;
                if(iPos >= 36864)
                    iPos -= 36864;
                else if(iPos < 0)
                    iPos += 36864;
                
                //              Superimpose Temporal HRTF on spectrum of reference signal (left channel)
                dSpL = realRight[iNum] * (double)(player.sHrtf[iPos]) / 2048.0;
                dSpImageL = realRight[player.iSize - iNum] * (double)(player.sHrtf[iPosImage]) / 2048.0;
                dPhaseL = imageRight[iNum] + (double)(player.sPhase[iPos]) / 10000.0;
                dPhaseImageL = imageRight[player.iSize - iNum] + (double)(player.sPhase[iPosImage]) / 10000.0;  
                
                //              Construct Temporal HRTF by using HRTF database (right channel)
                iPos = 512 * dir[iNum] + iFreq;
                iPosImage = 512 * dir[iNum] + 512 - iFreq;
                if(iPosImage >= 36864)
                    iPosImage -= 36864;
                else if(iPosImage < 0)
                    iPosImage += 36864;
                if(iPos >= 36864)
                    iPos -= 36864;
                else if(iPos < 0)
                    iPos += 36864;
                
                //              Superimpose Temporal HRTF on spectrum of reference signal (right channel)
                dSpR = realRight[iNum] * (double)(player.sHrtf[iPos]) / 2048.0;
                dSpImageR = realRight[player.iSize - iNum] * (double)(player.sHrtf[iPosImage]) / 2048.0;
                dPhaseR = imageRight[iNum] + (double)(player.sPhase[iPos]) / 10000.0;
                dPhaseImageR = imageRight[player.iSize - iNum] + (double)(player.sPhase[iPosImage]) / 10000.0;                
            }
            realLeft[iNum] = dSpL * cos(dPhaseL);
            realRight[iNum] = dSpR * cos(dPhaseR);
            imageLeft[iNum] = dSpL * sin(dPhaseL);
            imageRight[iNum] = dSpR * sin(dPhaseR);
            realLeft[player.iSize - iNum] = dSpImageL * cos(dPhaseImageL);
            realRight[player.iSize - iNum] = dSpImageR * cos(dPhaseImageR);
            imageLeft[player.iSize - iNum] = dSpImageL * sin(dPhaseImageL);
            imageRight[player.iSize - iNum] = dSpImageR * sin(dPhaseImageR);
        }
        
        realLeft[player.iHlf] = realRight[player.iHlf];
        imageLeft[player.iHlf] = imageRight[player.iHlf];
        
        [trans fastFt:realLeft:imageLeft:YES];              // Inverse FFT (left channel)
        [trans fastFt:realRight:imageRight:YES];            // Inverse FFT (right channel)
        
        //      Overlap and add process
        for(iNum = 0;iNum < player.iSize;iNum ++){
            dHan = (1 - cos(2 * M_PI * (double)iNum / (double)(player.iSize))) / 4;
            realLeft[iNum] *= dHan;
            realRight[iNum] *= dHan;
            
            if(player.numBytesWritten == 0){
                player.ResultLeft[iNum] = (SInt16)realLeft[iNum];
                player.ResultRight[iNum] = (SInt16)realRight[iNum];
            }
            else{
                player.ResultLeft[iNum] += (SInt16)realLeft[iNum];
                player.ResultRight[iNum] += (SInt16)realRight[iNum];
            }
        }
        
        for(iCount = 0;iCount < player.iSize;iCount ++){
            if(iCount < player.iProc){
                *output++ = player.ResultLeft[iCount];
                *output++ = player.ResultRight[iCount];
                player.numBytesWritten += 4;
                player.numOffset += 4;
                if(player.numBytesWritten >= player.nBytesRead - 44){
                    if(!player.isLoaded){
                        UIAlertView *alert = [[UIAlertView alloc]
                                              initWithTitle : @"StreamingError"
                                              message : @"Terminated because not enough data are loaded"
                                              delegate : nil cancelButtonTitle : @"OK"
                                              otherButtonTitles : nil];
                        [alert show];
                        [alert release];    
                        NSLog(@"Insufficient data loaded");
                    }
                    iFnum = player.iFrames;
                    [player setIsPlaying:NO];
                    [player stop:YES];
                    break;
                }
            }
            if(iCount < player.iRem){
                player.ResultLeft[iCount] = player.ResultLeft[iCount + player.iProc];
                player.ResultRight[iCount] = player.ResultRight[iCount + player.iProc];
            }
            else{
                player.ResultLeft[iCount] = 0;
                player.ResultRight[iCount] = 0;
            }
        }
    }
    [trans release];
    inBuffer->mAudioDataByteSize = numBytes;
    AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
    
}

-(void)dealloc{
    free(ResultLeft);
    free(ResultRight);
    free(sHrtf);
    free(sPhase);
    if(sopaQueueObject)
        AudioQueueDispose(sopaQueueObject,YES);
    [[self mData]release];
    [super dealloc];
}

@end
