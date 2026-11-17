#import <Foundation/Foundation.h>

int main() {
    @autoreleasepool {
        void (^myBlock)(NSString *) = ^(NSString *name) {
            NSLog(@"Hello, %@ from Objective-C Block!", name);
        };
        
        myBlock(@"world");
    }
    return 0;
}
