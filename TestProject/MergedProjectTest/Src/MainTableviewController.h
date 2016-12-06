#import <UIKit/UIKit.h>
#import "SpilTV/Spil.h"

@interface MainTableviewController : UITableViewController<SpilDelegate, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableViewCell *userDataCell;

@end
