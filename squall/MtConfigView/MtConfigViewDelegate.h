//
//  MtConfigurableViewDelegate.h
//  squall
//
//  Created by Richard Cooper on 18/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MtConfigView.h"


@protocol MtConfigViewDelegateInternal <NSMenuDelegate>

- (void)createItem:(NSMenuItem*)item inView:(MtConfigView*)view;
- (void)removingView:(MtConfigView*)view;

@end


@protocol MtConfigViewDelegate <MtConfigViewDelegateInternal>

- (NSDictionary*)archiveConfigOfView:(MtConfigView*)view;
- (void)unarchiveConfig:(NSDictionary*)settings intoView:(MtConfigView*)view;

@end
