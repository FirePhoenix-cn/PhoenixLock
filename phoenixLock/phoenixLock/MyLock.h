
#import "LockViewController.h"
@interface MyLock : LockViewController<UICollectionViewDataSource,UICollectionViewDelegate,libBleLockDelegate>
@property (strong, nonatomic) IBOutlet UICollectionView *mangedLock;
@property (strong, nonatomic) IBOutlet UICollectionView *sharedLock;
@end
