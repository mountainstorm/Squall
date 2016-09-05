//
//  MtAppDelegate.h
//  squall
//
//  Created by Cooper on 15/08/2012.
//  Copyright (c) 2012 mountainstorm. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MtConfigView/MtConfigViewController.h"
#import "MtConfigViewDelegate.h"
#import <Python.h>

@interface MtAppDelegate : NSObject <NSApplicationDelegate>
{
    PyObject* _scriptObject;
}

@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSView* rootView;

@property (retain) id<MtConfigViewDelegate> pythonDelegate;
@property (retain) MtConfigViewController* configViewController;

@end
