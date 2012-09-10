//
//  iSopaViewController.m
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

#import "iSopaViewController.h"

@implementation iSopaViewController
@synthesize imageWidth;
@synthesize iniWidth;
@synthesize iOffset;
@synthesize iOrientation;
@synthesize isYet;
@synthesize isTerminatedByUser;
@synthesize isRotate;
@synthesize setButton;
@synthesize textField;
@synthesize myLabel;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	// Do any additional setup after loading the view, typically from a nib.
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
     if(orientation == UIInterfaceOrientationPortrait){
         iOrientation = 0;
         NSLog(@"Initial orientation : Portrait");
     
     }
     else{
         iOrientation = 1;
         NSLog(@"Initial orientation : landscape");
     
     }   
    
    iniWidth = 480;
    iOffset = 0;
    
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(sopaReproductionFinished) 
                   name:@"sopaReproductionFinished" object:player];  
    [center addObserver:self selector:@selector(sopaInfo) 
                   name:@"sopaInfo" object:player];  
    [center addObserver:self selector:@selector(didRotate:)
                    name:@"UIDeviceOrientationDidChangeNotification" object:nil];  
    
    [player setIsPlaying:NO];
    
    NSString *textStr = @"http://staff.aist.go.jp/ashihara-k/resource/panther22k.sopa";
    [textField setText:textStr];
    isRotate = FALSE;
    [self setURLText];
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [textField release];
    textField = nil;
    [setButton release];
    setButton = nil;
    [myLabel release];
    myLabel = nil;
    [scrollview release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)scrollViewDidScroll:(UIScrollView *)sender{
    CGPoint p = [scrollview contentOffset];
    SInt16 width = iniWidth * 4;
    double dVal;
    
    if(p.x <= 0){
        scrollview.contentOffset = CGPointMake(width + iOffset + (SInt16)p.x,0);
    }
    else if(p.x >= width * 2 - iniWidth){
        scrollview.contentOffset = CGPointMake((SInt16)p.x - width,0);
    }

    dVal = (double)p.x - (double)imageWidth;
    dVal /= (double)imageWidth;
    dVal *= -72;
    if(isYet)
        [player setIRot:(SInt16)dVal];
}

-(IBAction)setURLText{
    SInt16 height,iTmp;
    double dRatio,dWidth;
    NSURL *tmpUrl,*newUrl;
    NSData *data;
    NSString *gifPath,*text;
    
    if(!isRotate){
        if(player.isPlaying){
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle : @"Not available"
                                      message : @"Not available during reproduction\nTap on the imageview to stop reproduction"
                                      delegate: nil
                                      cancelButtonTitle : @"OK"
                                      otherButtonTitles : nil];
            [alertView show];
            [alertView release]; 
            return;
        }
        
        isYet = NO;
        text = textField.text;
        NSURL *url = [[NSURL alloc]initWithString:text];
        
        NSRange rang = [text rangeOfString:@"://"];
        if(rang.location == NSNotFound){
            NSString *newStr = [text stringByDeletingPathExtension];
            gifPath = [[NSBundle mainBundle] pathForResource:newStr ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:gifPath];
        }
        else {
            tmpUrl = url.URLByDeletingPathExtension;
            newUrl = [tmpUrl URLByAppendingPathExtension:@"gif"];
            data    = [NSData dataWithContentsOfURL:newUrl];
        }
        if(data == nil){
            gifPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:gifPath];
        }
        UIImage *img    = [[UIImage alloc] initWithData:data];
        UIImageView *imageView0 = [[UIImageView alloc]initWithImage:img];
        UIImageView *imageView1 = [[UIImageView alloc]initWithImage:img];
        
        [url release];
        
        CGRect rect = imageView0.frame;
        imageWidth = rect.size.width;
        dRatio = (double)iniWidth * 4 / (double)imageWidth;
        dWidth = (double)imageWidth * dRatio;
        imageWidth = (SInt16)dWidth;
        height = rect.size.height;
        dWidth = (double)height * dRatio;
        height = (SInt16)dWidth;
        [imageView0 setFrame:CGRectMake(0.0, 0.0, imageWidth, height)];
        [imageView1 setFrame:CGRectMake(imageWidth, 0.0, imageWidth, height)];
        NSLog(@"%@",text);

        [scrollview removeFromSuperview];
        
        scrollview = [[scroller alloc]initWithFrame:CGRectMake(0.0,32.0,iniWidth,height)];
        [self.view addSubview:scrollview];
        [scrollview release];
        scrollview.pagingEnabled = NO;  
        scrollview.contentSize = CGSizeMake(imageView0.frame.size.width * 2, imageView0.frame.size.height);  
        scrollview.showsHorizontalScrollIndicator = NO;  
        scrollview.showsVerticalScrollIndicator = NO; 
        scrollview.bounces = NO;
        [scrollview setDelegate:(id)self];
        [img release];
        
        [scrollview addSubview:imageView0];
        [imageView0 release];
        [scrollview addSubview:imageView1];
        [imageView1 release];
        if(!player.isPlaying){
            if(player)
                [player release];
            player = [[SopaQueue alloc]init];
            player.urlStr = text;
            
            if(![player loadDatabase]){
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle : @"Database error!"
                                          message : @"Database not found"
                                          delegate: nil
                                          cancelButtonTitle : @"OK"
                                          otherButtonTitles : nil];
                [alertView show];
                [alertView release]; 
                return;
            }
            if([player numPacketsToRead] != 0){
                isYet = YES;
            }
            NSLog(@"Packets to read = %lu",player.numPacketsToRead);
        }
    }
    [textField resignFirstResponder];
    [myLabel removeFromSuperview];
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown){
        myLabel = [[UILabel alloc] initWithFrame:CGRectMake(4,144,312,128)];
        iOffset = imageWidth / 18;
    }
    else{
        myLabel = [[UILabel alloc] initWithFrame:CGRectMake(4,144,472,128)];
        iOffset = 0;
    }
    if(isRotate){
        iTmp = scrollview.contentOffset.x;
        if(iOffset == 0){
            iTmp -= imageWidth / 18;
        }
        else{
            iTmp += iOffset;
        }
        scrollview.contentOffset = CGPointMake(iTmp,0);
    }
    else
        scrollview.contentOffset = CGPointMake(imageWidth + iOffset,0);
    
    myLabel.textAlignment = UITextAlignmentCenter;
    myLabel.backgroundColor = [UIColor blackColor];
    myLabel.textColor = [UIColor lightTextColor];
    myLabel.numberOfLines = 4;
    if(player.isPlaying){
        NSString *newStr = [NSString stringWithFormat:@"Sampling rate %d Hz\nFrame size %d\nScroll imageview to control the panning\nTap on imageview to stop reproduction",player.numSampleRate,player.iSize];
        myLabel.text = newStr;
    }
    else{
        myLabel.text = @"Tap on imageview to start reproduction\nSOPA player for iPhone\niSOPA\nCopyright (c) 2012, AIST";
    }
    [self.view addSubview:myLabel];
    if(isRotate)
        isRotate = FALSE;
}


-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self.view];

    if(isYet){
        if(location.y < scrollview.frame.size.height + 36 && location.y > 32){
            if([player isPlaying] == NO){
                isTerminatedByUser = NO;
                [player play];                      // Start reproduction
                myLabel.text = @"Searching for a SOPA file";
                NSLog(@"Reproducing SOPA");
            }
            else{
                isTerminatedByUser = YES;
                [player setIsPlaying:NO];
                [player stop:YES];                  // Stop reproduction
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    return TRUE;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    BOOL isAnimate;
    if(interfaceOrientation == UIInterfaceOrientationPortrait){
        if(iOrientation == 1)
            isAnimate = TRUE;
        else
            isAnimate = FALSE;
        iOrientation = 0;
        NSLog(@"Portrait normal");
    }
    else if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        if(iOrientation == 1)
            isAnimate = TRUE;
        else
            isAnimate = FALSE;
        iOrientation = 0;
        NSLog(@"Portrait upsidedown");
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        if(iOrientation == 1)
            isAnimate = FALSE;
        else
            isAnimate = TRUE;
        iOrientation = 1;
        NSLog(@"Landscape left");
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeRight){
        if(iOrientation == 1)
            isAnimate = FALSE;
        else
            isAnimate = TRUE;
        iOrientation = 1;
        NSLog(@"Landscape right");
    }
    if(isAnimate){
        isRotate = TRUE;
        [self setURLText];
    }
}

-(void)sopaInfo{
    int iVal = player.numSampleRate;
    short sVal = player.iSize;
    NSString *newStr = [NSString stringWithFormat:@"Sampling rate %d Hz\nFrame size %d\nScroll imageview to control the panning\nTap on imageview to stop reproduction",iVal,sVal];
    myLabel.text = newStr;
    setButton.enabled = NO;
}

-(void)sopaReproductionFinished{
    UInt32 uVal = player.numBytesWritten;
    NSString *newStr;
    
    setButton.enabled = YES;
    if(isTerminatedByUser)
        newStr = [NSString stringWithFormat:@"%lu bytes reproduced",uVal];
    else
        newStr = [NSString stringWithFormat:@"%lu bytes reproduced\nand finished",uVal];
    myLabel.text = newStr;
}

- (void)didRotate:(id)sender{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown){
//        iniWidth = 320;
        NSLog(@"Portrait");
        
    }
    else{
        iniWidth = 480;
        NSLog(@"landscape");
        
    }
}

- (void)dealloc {
    [player stop:YES];
    [player release];        
    [scrollview release];
    [textField release];
    [textField release];
    [setButton release];
    [myLabel release];
    [[NSNotificationCenter defaultCenter] removeObserver:nil];
    [super dealloc];
}
@end
