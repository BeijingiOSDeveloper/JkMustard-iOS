/*
 * This file is part of the JPNavigationController package.
 * (c) NewPan <13246884282@163.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Click https://github.com/Chris-Pan
 * or http://www.jianshu.com/users/e2f2d779c022/latest_articles to contact me.
 */

#import "JPFullScreenPopGestureRecognizerDelegate.h"
#import "UIViewController+JPNavigationController.h"
#import "UINavigationController+JPFullScreenPopGesture.h"
#import "JPSnapTool.h"
#import "JPManageSinglePopVCTool.h"

// a note for navigation controller left slip.
NSString * const JPNavigationControllerDidScrolledLeftNotification = @"com.newpan.navigation.did.scrolled.left.notification";
// a note for navigation controller right slip.
NSString * const JPNavigationControllerDidScrolledRightNotification = @"com.newpan.navigation.did.scrolled.right.notification";

@implementation JPFullScreenPopGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer{
    
    // System pop action.
    SEL action = NSSelectorFromString(@"handleNavigationTransition:");
    
    CGPoint translation = [gestureRecognizer velocityInView:gestureRecognizer.view];
    if (translation.x<0) {
        if ([self.delegate respondsToSelector:@selector(navigationControllerLeftSlipShouldBegain)]) {
            BOOL result = [self.delegate navigationControllerLeftSlipShouldBegain];
            if (result) {
                UIViewController *rootVc = [UIApplication sharedApplication].keyWindow.rootViewController;
                UIImage *snapImage = [JPSnapTool snapShotWithView:rootVc.view];
                NSDictionary *dict = @{
                                       @"snapImage" : snapImage,
                                       @"navigationController" : self.navigationController
                                       };
                // left-slip --> push.
                [[NSNotificationCenter defaultCenter]postNotificationName:JPNavigationControllerDidScrolledLeftNotification object:dict userInfo:nil];
                [gestureRecognizer removeTarget:_target action:action];
                return YES;
            }
            return NO;
        }
    }
    else{
        // right-slip --> pop.
        
        // Forbid pop when the start point beyond user setted range for pop.
        // 当开始触发的点大于用户指定的最大触发点的时候, 禁止pop.
        
        CGPoint beginningLocation = [gestureRecognizer locationInView:gestureRecognizer.view];
        CGFloat maxAllowedInitialDistance = self.navigationController.jp_interactivePopMaxAllowedInitialDistanceToLeftEdge;
        if (maxAllowedInitialDistance >= 0 && beginningLocation.x > maxAllowedInitialDistance) {
            return NO;
        }
        else{
            if ([self.delegate respondsToSelector:@selector(navigationControllerRightSlipShouldBegain)]) {
                BOOL result = [self.delegate navigationControllerRightSlipShouldBegain];
                if (result) {
                    [[NSNotificationCenter defaultCenter]postNotificationName:JPNavigationControllerDidScrolledRightNotification object:self.navigationController userInfo:nil];
                    [gestureRecognizer addTarget:_target action:action];
                }
                else{
                    return NO;
                }
            }
        }
    }
    
    
    // Check current view controller is close pop or not.
    // 检查要pop的页面是否被设置禁止pop.
    
    NSArray *closePopVCArr = [JPManageSinglePopVCTool shareTool].jp_closePopVCArr;
    UIViewController *vc = self.navigationController.viewControllers.lastObject;
    NSUInteger hash = [vc hash];
    if ([closePopVCArr containsObject:@(hash)]) {
        return NO;
    }
    
    
    // Forbid pop when current viewController is root viewController.
    // 根控制器不允许pop.
    
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    
    // Forbid pop when transitioning.
    // 正在做过渡动画的时候禁止pop.
    
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    
    // Forbid pop when closed all viewControllers' pop gesture.
    // 为所有界面关闭pop手势禁止pop.
    
    if (self.closePopForAllVC) {
        return NO;
    }
    
    return YES;
}


@end
