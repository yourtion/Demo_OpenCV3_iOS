//
//  ViewController.m
//  OpenCV3
//
//  Created by YourtionGuo on 4/27/16.
//  Copyright © 2016 Yourtion. All rights reserved.
//

#define cvCvtPixToPlane cvSplit
#define cvCvtPlaneToPix cvMerge
#define cvQueryHistValue_2D( hist, idx0, idx1 ) \
        cvGetReal2D( (hist)->bins, (idx0), (idx1) )


#import "ViewController.h"
#import <opencv2/opencv.hpp>
using namespace cv;

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imgV1;
@property (weak, nonatomic) IBOutlet UIImageView *imgV2;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIImageView *hig1;
@property (weak, nonatomic) IBOutlet UIImageView *hig2;

@end

@implementation ViewController {
    NSString *_btn;
}

- (IBAction)btnOne:(id)sender {
    _btn = @"1";
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
    
}

- (IBAction)btnTwo:(id)sender {
    _btn = @"2";
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    if ([_btn isEqualToString:@"1"]) {
        self.imgV1.image = chosenImage;
    }
    
    if ([_btn isEqualToString:@"2"]) {
        self.imgV2.image = chosenImage;
    }
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (IBAction)btnComp:(id)sender {
    float ret = [self comp:self.imgV1.image to:self.imgV2.image];
    self.resultLabel.text = [NSString stringWithFormat:@"得分： %f", ret];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}


-(float)comp:(UIImage *)img1 to:(UIImage *)img2 {
    IplImage *src1= [self CreateIplImageFromUIImage:img1];
    IplImage *src2 = [self CreateIplImageFromUIImage:img2];
    
    // HSV image and decompose into separate planes
    
    IplImage* hsv1 = cvCreateImage( cvGetSize(src1), 8, 3 );
    cvCvtColor( src1, hsv1, CV_BGR2HSV);
    
    
    IplImage* h_plane1 = cvCreateImage( cvGetSize(src1), 8, 1 );
    IplImage* s_plane1 = cvCreateImage( cvGetSize(src1), 8, 1 );
    IplImage* v_plane1 = cvCreateImage( cvGetSize(src1), 8, 1 );
    IplImage* planes1[] = { h_plane1, s_plane1 };
    cvCvtPixToPlane( hsv1, h_plane1, s_plane1, v_plane1, 0 );
    
    IplImage* hsv2 = cvCreateImage( cvGetSize(src2), 8, 3 );
    cvCvtColor( src2, hsv2, CV_BGR2HSV);
    
    
    IplImage* h_plane2 = cvCreateImage( cvGetSize(src2), 8, 1 );
    IplImage* s_plane2 = cvCreateImage( cvGetSize(src2), 8, 1 );
    IplImage* v_plane2 = cvCreateImage( cvGetSize(src2), 8, 1 );
    IplImage* planes2[] = { h_plane2, s_plane2 };
    cvCvtPixToPlane( hsv2, h_plane2, s_plane2, v_plane2, 0 );
    
    // Build the histogram amd compute
    int h_bins = 30, s_bins = 32;
    CvHistogram *hist1, *hist2;
    {
        int hist_size[] = { h_bins, s_bins };
        float h_ranges[] = { 0, 180 };
        float s_ranges[] = { 0, 255 };
        float* ranges[] = { h_ranges, s_ranges };
        hist1 = cvCreateHist( 2, hist_size, CV_HIST_ARRAY, ranges, 1 );
        hist2 = cvCreateHist( 2, hist_size, CV_HIST_ARRAY, ranges, 1 );
    }
    cvCalcHist( planes1, hist1, 0, 0 );
    cvNormalizeHist( hist1, 1.0 );
    
    cvCalcHist( planes2, hist2, 0, 0 );
    cvNormalizeHist( hist2, 1.0 );
    
    // Get signature using EMD
    CvMat *sig1,*sig2;
    int numrows = h_bins * s_bins;
    
    sig1 = cvCreateMat(numrows, 3, CV_32FC1);
    sig2 = cvCreateMat(numrows, 3, CV_32FC1);
    
    // Create image to visualize
    int scale = 10;
    IplImage* hist_img1 = cvCreateImage( cvSize(h_bins*scale, s_bins*scale), 8, 3);
    cvZero( hist_img1 );
    IplImage* hist_img2 = cvCreateImage( cvSize(h_bins*scale, s_bins*scale), 8, 3);
    cvZero( hist_img2 );
    
    float max_value1 = 0;
    cvGetMinMaxHistValue( hist1, 0, &max_value1, 0, 0 );
    float max_value2 = 0;
    cvGetMinMaxHistValue( hist2, 0, &max_value2, 0, 0 );
    
    // Fill
    for ( int h = 0; h < h_bins; h ++ ) {
        for ( int s = 0; s < s_bins ; s++ ) {
            float bin_val1 = cvQueryHistValue_2D( hist1, h, s );
            float bin_val2 = cvQueryHistValue_2D( hist2, h, s );
            // Image
            int intensity1 = cvRound( bin_val1 * 255 / max_value1 );
            cvRectangle(hist_img1,
                        cvPoint( h*scale, s*scale ),
                        cvPoint( (h+1)*scale-1, (s+1)*scale-1 ),
                        CV_RGB(intensity1, intensity1, intensity1),
                        CV_FILLED
                        );
            int intensity2 = cvRound( bin_val2 * 255 / max_value2 );
            cvRectangle(hist_img2,
                        cvPoint( h*scale, s*scale ),
                        cvPoint( (h+1)*scale-1, (s+1)*scale-1 ),
                        CV_RGB(intensity2, intensity2, intensity2),
                        CV_FILLED
                        );
            
            // Signature
            cvSet2D(sig1, h*s_bins+s, 0, cvScalar(bin_val1)); // bin value
            cvSet2D(sig1, h*s_bins+s, 1, cvScalar(h)); // Coord 1
            cvSet2D(sig1, h*s_bins+s, 2, cvScalar(s)); // Coord 2
            cvSet2D(sig2, h*s_bins+s, 0, cvScalar(bin_val2)); // bin value
            cvSet2D(sig2, h*s_bins+s, 1, cvScalar(h)); // Coord 1
            cvSet2D(sig2, h*s_bins+s, 2, cvScalar(s)); // Coord 2
        }
    }
    
    float emd = cvCalcEMD2( sig1, sig2, CV_DIST_L2);
    self.hig1.image = [self UIImageFromIplImage:hist_img1];
    self.hig2.image = [self UIImageFromIplImage:hist_img2];
    printf("EMD : %f ;", emd);
    
    cvReleaseImage( &src1 );
    cvReleaseImage( &hist_img1 );
    cvReleaseHist( &hist1 );
    cvReleaseMat( &sig1 );
    cvReleaseImage( &src2 );
    cvReleaseImage( &hist_img2 );
    cvReleaseHist( &hist2 );
    cvReleaseMat( &sig2 );
    return emd;
}


// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
                                       cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4
                                       );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

- (UIImage *)UIImageFromIplImage:(IplImage *)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Allocating the buffer for CGImage
    NSData *data =
    [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((CFDataRef)data);
    // Creating CGImage from chunk of IplImage
    CGImageRef imageRef = CGImageCreate(
                                        image->width, image->height,
                                        image->depth, image->depth * image->nChannels, image->widthStep,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    // Getting UIImage from CGImage
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}


@end
