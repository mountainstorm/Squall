//
//  MtConfigPaneController.h
//  squall
//
//  Created by Cooper on 16/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MtConfigView.h"
#import "MtConfigViewDelegate.h"

@interface MtConfigViewController : NSObject<MtConfigViewDelegateInternal>

// public
- (id)initWithFrame:(NSRect)frame;
- (NSDictionary*)archiveLayout;
- (void)unarchiveLayout:(NSDictionary*)layout;

@property (retain) id<MtConfigViewDelegate> delegate;
@property (retain) NSView* view;

@end
