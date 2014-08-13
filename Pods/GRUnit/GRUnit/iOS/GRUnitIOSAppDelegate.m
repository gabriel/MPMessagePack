//
//  GRUnitIOSAppDelegate.m
//  GRUnitIOS
//
//  Created by Gabriel Handford on 1/25/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "GRUnitIOSAppDelegate.h"
#import "GRUnitIOSViewController.h"
#import "GRUnit.h"

@interface GRUnitIOSAppDelegate (Terminate)
- (void)_terminateWithStatus:(int)status;
@end

@interface GRUnitIOSAppDelegate ()
@property GRUnitIOSViewController *viewController;
@end

@implementation GRUnitIOSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	char *stderrRedirect = getenv("GRUNIT_STDERR_REDIRECT");
	if (stderrRedirect) {
		NSString *stderrRedirectPath = @(stderrRedirect);
		freopen([stderrRedirectPath fileSystemRepresentation], "a", stderr);
	}
	
  if (getenv("GRUNIT_CLI")) {
    GRTestRunner *runner = [GRTestRunner runnerFromEnv];
    [runner run:^(id<GRTest> test) {
      // TODO: Fix exitStatus
      if ([application respondsToSelector:@selector(_terminateWithStatus:)]) {
        [(id)application _terminateWithStatus:0];
      } else {
        exit(0);
      }
    }];
  }
  _viewController = [[GRUnitIOSViewController alloc] init];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:_viewController];
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor whiteColor];
  self.window.rootViewController = navigationController;
  [self.window makeKeyAndVisible];
  
  [_viewController loadDefaults];

  if (getenv("GRUNIT_AUTORUN")) [_viewController runTests];
  
  return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called only graceful terminate; Closing simulator won't trigger this
  [_viewController saveDefaults];
}


@end
