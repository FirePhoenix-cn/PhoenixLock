
#import <UIKit/UIKit.h>

@interface MyLock : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate,libBleLockDelegate>

@property (retain, nonatomic) IBOutlet UICollectionView *mangedLock;
@property (retain, nonatomic) IBOutlet UICollectionView *sharedLock;

@property (retain,nonatomic)  NSTimer *timer;
/*数据持久化*/
@property (retain, nonatomic) NSUserDefaults *userdefaults;
/*转16进制*/
-(NSData *) NSStringConversionToNSData:(NSString*)string;

@end
