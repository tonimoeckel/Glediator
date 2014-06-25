//
//  ViewController.h
//  LEDRemote
//
//  Created by Toni Möckel on 17.01.12.
//  Copyright (c) 2012 -. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCDAsyncUdpSocket;

@interface ViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource>{
    long tag;
	GCDAsyncUdpSocket *udpSocket;
    GCDAsyncUdpSocket *udpRecieveSocket;
    
    NSMutableArray *commands;
    
}
@property (retain, nonatomic) IBOutlet UIPickerView *pickerView;

@property (nonatomic, assign) BOOL isRunning;

@property (retain, nonatomic) IBOutlet UITextField *addressField;
@property (retain, nonatomic) IBOutlet UITextField *portField;
@property (retain, nonatomic) IBOutlet UITextField *messageField;
@property (retain, nonatomic) IBOutlet UIButton *sendButton;
@property (retain, nonatomic) IBOutlet UITextField *myPortField;
@property (retain, nonatomic) IBOutlet UIButton *connectionButton;

@property (retain, nonatomic) IBOutlet UITextView *resultTextView;

-(void) sendMessageToServer:(NSString *)message;

- (IBAction)sendTouchedUp:(id)sender;
- (IBAction)connectButtonTouchedUp:(id)sender;

@end
