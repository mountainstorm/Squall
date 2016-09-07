//
//  TextController.h
//  squall
//
//  Created by cooper on 05/09/2016.
//  Copyright © 2016 mountainstorm. All rights reserved.
//

#import "PaneController.h"

@interface TextController : PaneController

- (IBAction)updated:(id)sender;

- (void)updateResults:(NSAttributedString*)s;

@property (assign) IBOutlet NSTextView* results;

@end
