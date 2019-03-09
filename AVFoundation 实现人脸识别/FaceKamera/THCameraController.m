
#import "THCameraController.h"
#import <AVFoundation/AVFoundation.h>

@interface THCameraController ()<AVCaptureMetadataOutputObjectsDelegate>
@property(nonatomic,strong)AVCaptureMetadataOutput  *metadataOutput;


@end

@implementation THCameraController

- (BOOL)setupSessionOutputs:(NSError **)error {
    
    self.metadataOutput = [[AVCaptureMetadataOutput alloc]init];

    //为捕捉会话添加设备
    if ([self.captureSession canAddOutput:self.metadataOutput]){
        [self.captureSession addOutput:self.metadataOutput];
        
        //获得人脸属性
        NSArray *metadatObjectTypes = @[AVMetadataObjectTypeFace];
        //设置metadataObjectTypes 指定对象输出的元数据类型。
        /*
         限制检查到元数据类型集合的做法是一种优化处理方法！！可以减少我们实际感兴趣的对象数量
         支持多种元数据。这里只保留对人脸元数据感兴趣
         */
        self.metadataOutput.metadataObjectTypes = metadatObjectTypes;
        
        //创建主队列： 因为人脸检测用到了硬件加速GPU，而且许多重要的任务都在主线程中执行，所以需要为这次参数指定主队列。
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        
        //通过设置AVCaptureVideoDataOutput的代理，就能获取捕获到一帧一帧数据
        [self.metadataOutput setMetadataObjectsDelegate:self queue:mainQueue];
     
        return YES;
    }else
    {
        //报错
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Failed to still image output"};
            
            *error = [NSError errorWithDomain:THCameraErrorDomain code:THCameraErrorFailedToAddOutput userInfo:userInfo];
        }
        return NO;
    }
}


//代理方法=捕获到你设置的元数据对象
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {

    //metadataObjects 包含了捕获到人脸数据.(人脸数据重复，上一秒捕获到的人脸位置，下一秒还是捕获)
    //使用循环，打印人脸数据
    for (AVMetadataFaceObject *face in metadataObjects) {
        //faceID、bounds唯一。哪怕是双胞胎
        NSLog(@"Face detected with ID:%li",(long)face.faceID);
        NSLog(@"Face bounds:%@",NSStringFromCGRect(face.bounds));
    }
    //已经获取视频中的人脸个数！人脸的e位置！处理人脸！预览图层上
    //将元数据 传递给 THPreviewView.m   将元数据转换为layer
    [self.faceDetectionDelegate didDetectFaces:metadataObjects];
}

/*
 1.视频采集
 2.为session添加一个元数据的输出.ACCaptureMetadataOutput
 3.设置元数据的范围(人脸数据、二维码数据、一维码...)
 4.开始捕捉(设置捕捉代理)didOutPutMetadataObjects
 5.获取到捕捉人脸相关信息：代理方法中可以获取 didOutputMetadataObjects
 6.对人脸数据的处理！将人脸框出来！(涉及比较多的细节)
*/

@end

