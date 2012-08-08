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
@synthesize isYet;
@synthesize isTerminatedByUser;
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
    //    SInt16 height,iniWidth;
    //    double dRatio,dWidth;
    
    /*    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
     if(orientation == UIInterfaceOrientationPortrait){
     iniWidth = 320;
     NSLog(@"Portrait");
     
     }else{
     iniWidth = 480;
     NSLog(@"landscape");
     
     }   */
    
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(sopaReproductionFinished) 
                   name:@"sopaReproductionFinished" object:player];  
    [center addObserver:self selector:@selector(sopaInfo) 
                   name:@"sopaInfo" object:player];  
    
    iniWidth = 480;
    [player setIsPlaying:NO];
    
    NSString *textStr = @"http://staff.aist.go.jp/ashihara-k/resource/panther22k.sopa";
    [textField setText:textStr];
    [self setURLText];
    
    myLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 144, 472, 128)];
    myLabel.textAlignment = UITextAlignmentCenter;
    myLabel.backgroundColor = [UIColor blackColor];
    myLabel.textColor = [UIColor lightTextColor];
    myLabel.numberOfLines = 4;
    myLabel.text = @"SOPA player for iPhone\niSOPA\nCopyright (c) 2012, AIST";
    [self.view addSubview:myLabel];
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)scrollViewDidScroll:(UIScrollView *)sender{
    CGPoint p = [scrollview contentOffset];
    SInt16 width = imageWidth;
    double dVal;
    
    if(p.x <= 0){
        scrollview.contentOffset = CGPointMake(width + (SInt16)p.x,0);
    }
    else if(p.x >= width * 2 - scrollview.frame.size.width){
        scrollview.contentOffset = CGPointMake((SInt16)p.x - width,0);
    }
    dVal = (double)p.x - (double)imageWidth;
    dVal /= (double)imageWidth;
    dVal *= -72;
    if(isYet)
        [player setIRot:(SInt16)dVal];
}

-(IBAction)setURLText{
    SInt16 height;
    double dRatio,dWidth;
    NSURL *tmpUrl,*newUrl;
    NSData *data;
    NSString *gifPath,*text;
    
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
    
    scrollview = [[scroller alloc]initWithFrame:CGRectMake(0.0,32.0,iniWidth,height)];
    [self.view addSubview:scrollview];
    [scrollview release];
    //    [scrollview setFrame:CGRectMake(0.0, 0.0, 320, height)];
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
    
    scrollview.contentOffset = CGPointMake(imageWidth,0);
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
        myLabel.text = @"Tap on imageview to start reproduction\nSOPA player for iPhone\niSOPA\nCopyright (c) 2012, AIST";
        if([player numPacketsToRead] != 0){
            isYet = YES;
/*            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle : @"Tap me"
                                      message : @"Tap on the imageview to start reproduction"
                                      delegate: nil
                                      cancelButtonTitle : @"OK"
                                      otherButtonTitles : nil];
            [alertView show];
            [alertView release];    */
        }
        NSLog(@"Packets to read = %lu",player.numPacketsToRead);
    }
    [textField resignFirstResponder];
}


-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self.view];
    //	NSLog(@"x:%f y:%f",location.x,location.y); 
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
    //    [[UIDevice currentDevice] setOrientation:UIInterfaceOrientationPortrait];
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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if(interfaceOrientation == UIInterfaceOrientationPortrait){
        //        iniWidth = 320;
        NSLog(@"Portrait");
    }
    else if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        NSLog(@"Portrait");
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        iniWidth = 480;
        NSLog(@"Landscape");
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeRight){
        iniWidth = 480;
        NSLog(@"Landscape");
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
