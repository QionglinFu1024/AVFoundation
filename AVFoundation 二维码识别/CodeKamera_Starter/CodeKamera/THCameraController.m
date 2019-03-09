
#import "THCameraController.h"
#import <AVFoundation/AVFoundation.h>

@interface THCameraController ()<AVCaptureMetadataOutputObjectsDelegate>

@property(strong,nonatomic)AVCaptureMetadataOutput *metadataOutput; //通过代理方法，拿到接收元数据时的通知

@end


@implementation THCameraController

- (NSString *)sessionPreset {
    
    //重写sessionPreset方法，可以选择最适合应用程序捕捉预设类型。
    //苹果公司建议开发者使用最低合理解决方案以提高性能
    return AVCaptureSessionPreset640x480;
}

- (BOOL)setupSessionInputs:(NSError *__autoreleasing *)error {

    //设置相机自动对焦，这样可以在任何距离都可以进行扫描。
    BOOL success = [super setupSessionInputs:error];
    if(success)
    {
        //判断是否能自动聚焦
        if (self.activeCamera.autoFocusRangeRestrictionSupported) {
            
            //锁定设备
            if ([self.activeCamera lockForConfiguration:error]) {
                
                //自动聚焦
                /*
                    iOS 7.0新增属性 允许使用范围约束来对功能进行定制。
                  因为扫描条码，距离都比较近。所以AVCaptureAutoFocusRangeRestrictionNear，
                 通过缩小距离，来提高识别成功率。
                 */
                self.activeCamera.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
                
                //释放排他锁
                [self.activeCamera  unlockForConfiguration];
            }
        }
    }

    return YES;
}

- (BOOL)setupSessionOutputs:(NSError **)error {

    //获取输出设备
    self.metadataOutput = [[AVCaptureMetadataOutput alloc]init];
    
    //判断是否能添加输出设备
    if ([self.captureSession canAddOutput:self.metadataOutput]) {
        
        //添加输出设备
        [self.captureSession addOutput:self.metadataOutput];
        
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        
        //设置委托代理
        [self.metadataOutput setMetadataObjectsDelegate:self queue:mainQueue];
        
        //指定扫描对是OR码 & Aztec 码 (移动营销)
        NSArray *types = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeAztecCode,AVMetadataObjectTypeDataMatrixCode,AVMetadataObjectTypePDF417Code];
        
        self.metadataOutput.metadataObjectTypes = types;
        
    }else
    {
        //错误时，存储错误信息
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Faild to add metadata output."};
        *error = [NSError errorWithDomain:THCameraErrorDomain code:THCameraErrorFailedToAddOutput userInfo:userInfo];
        return NO;
    }
    return YES;
}


//委托代理回掉。处理条码
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    
    if (metadataObjects.count > 0) {
        
        NSLog(@"%@",metadataObjects[0]);
        
        /*
         <AVMetadataMachineReadableCodeObject: 0x17002db20, type="org.iso.QRCode", bounds={ 0.4,0.4 0.1x0.2 }>corners { 0.4,0.6 0.6,0.6 0.6,0.4 0.4,0.4 }, time 122373330766250, stringValue ""http://www.echargenet.com/portal/csService/html/app.html
         */
    }
    //获取了
    [self.codeDetectionDelegate didDetectCodes:metadataObjects];

}



@end

