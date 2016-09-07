//
//  PaneController.h
//  squall
//
//  Created by cooper on 05/09/2016.
//  Copyright © 2016 mountainstorm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <squall/MtConfigView/MtConfigView.h>


@protocol PaneController

- (id)initWithConfig:(NSDictionary*)config inView:(MtConfigView*)view;

@property (assign) IBOutlet NSView* toolbar;
@property (assign) IBOutlet NSView* content;

@end
