//
//  ViewController.m
//  LEDRemote
//
//  Created by Toni Möckel on 17.01.12.
//  Copyright (c) 2012 -. All rights reserved.
//

#import "ViewController.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "GCDAsyncUdpSocket.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation ViewController
@synthesize addressField;
@synthesize portField;
@synthesize messageField;
@synthesize sendButton;
@synthesize myPortField;
@synthesize connectionButton;
@synthesize resultTextView;
@synthesize pickerView;
@synthesize isRunning;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	// Setup our socket.
	// The socket will invoke our delegate methods using the usual delegate paradigm.
	// However, it will invoke the delegate methods on a specified GCD delegate dispatch queue.
	// 
	// Now we can configure the delegate dispatch queues however we want.
	// We could simply use the main dispatc queue, so the delegate methods are invoked on the main thread.
	// Or we could use a dedicated dispatch queue, which could be helpful if we were doing a lot of processing.
	// 
	// The best approach for your application will depend upon convenience, requirements and performance.
	// 
	// For this simple example, we're just going to use the main thread.
	
	udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	NSError *error = nil;
	
	if (![udpSocket bindToPort:0 error:&error])
	{
		DDLogError(@"Error binding: %@", error);
		return;
	}
	if (![udpSocket beginReceiving:&error])
	{
		DDLogError(@"Error receiving: %@", error);
		return;
	}
    
    udpRecieveSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
	
	DDLogVerbose(@"Ready");
    
    commands = [[NSMutableArray alloc] init];

    [self.pickerView setDelegate:self];
    [self.pickerView setDataSource:self];
    
    [pickerView selectRow:1 inComponent:0 animated:NO];
}

- (void)viewDidUnload
{
    [self setAddressField:nil];
    [self setPortField:nil];
    [self setMessageField:nil];
    [self setSendButton:nil];
    [self setResultTextView:nil];
    [self setMyPortField:nil];
    [self setConnectionButton:nil];
    [self setPickerView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)dealloc {
    [addressField release];
    [portField release];
    [messageField release];
    [sendButton release];
    [resultTextView release];
    [myPortField release];
    [connectionButton release];
    [pickerView release];
    [super dealloc];
}

- (void)scrollToBottom
{
    /*
	NSScrollView *scrollView = [logView enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0F, 0.0F);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];
     */
}

- (void)logError:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	[resultTextView setText:[resultTextView.text stringByAppendingString:paragraph]];
	[self scrollToBottom];
}

- (void)logInfo:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	[resultTextView setText:[resultTextView.text stringByAppendingString:paragraph]];
	[self scrollToBottom];
}

- (void)logMessage:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	[resultTextView setText:[resultTextView.text stringByAppendingString:paragraph]];
	[self scrollToBottom];
}

- (IBAction)sendTouchedUp:(id)sender
{
	NSString *host = addressField.text;
	if ([host length] == 0)
	{
		[self logError:@"Address required"];
		return;
	}
	
	int port = [portField.text intValue];
	if (port <= 0 || port > 65535)
	{
		[self logError:@"Valid port required"];
		return;
	}
	
	NSString *msg = messageField.text;
	if ([msg length] == 0)
	{
		[self logError:@"Message required"];
		return;
	}
	
	NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
	[udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:tag];

	[self logMessage:[NSString stringWithFormat:@"SENT (%i): %@", (int)tag, msg]];
	
	tag++;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
	// You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	// You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
	NSString *msg = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if (msg)
	{
		[self logMessage:[NSString stringWithFormat:@"RECV: %@", msg]];
	}
	else
	{
		NSString *host = nil;
		uint16_t port = 0;
		[GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
		
		[self logInfo:[NSString stringWithFormat:@"RECV: Unknown message from: %@:%hu", host, port]];
	}
    NSArray* strings = [msg componentsSeparatedByString: @";"];
    if ([[strings objectAtIndex:0] isEqualToString:@"GLEDIATOR"]) {
        if ([[strings objectAtIndex:1] isEqualToString:@"ADD_SCENE"]){
            [commands addObject:[strings objectAtIndex:2]];
            [self.pickerView reloadAllComponents];
        }
        if ([[strings objectAtIndex:1] isEqualToString:@"CLEAR_LIST"]){
            [commands removeAllObjects];    
            [self.pickerView reloadAllComponents];
        }
        
        if ([[strings objectAtIndex:1] isEqualToString:@"SET_SELECTED_INDEX"]){
            [pickerView selectRow:[[strings objectAtIndex:2] intValue] inComponent:0 animated:YES]; 
        }
    }
        
    
    

}


- (IBAction)connectButtonTouchedUp:(id)sender {

    if (connectionButton.tag == 1)
	{
		// STOP udp echo server
		NSLog(@"Close");
		[udpRecieveSocket close];
		
		[self logInfo:@"Stopped Udp Echo server"];
        [connectionButton setTag:0];
		
		[portField setEnabled:YES];
		[connectionButton setTitle:@"Start" forState:UIControlStateNormal];
	}
	else
	{
        // START udp echo server
        NSLog(@"Start");
        int port = [myPortField.text intValue];
        
        
        NSError *error = nil;
        
        if (![udpRecieveSocket bindToPort:port error:&error])
        {
            [self logError:[NSString stringWithFormat:@"Error starting server (bind): %@",error ]];
            return;
        }
        if (![udpRecieveSocket beginReceiving:&error])
        {
            [udpRecieveSocket close];
            
            [self logError:[NSString stringWithFormat:@"Error starting server (recv): %@", error]];
            return;
        }
        
        [self logInfo:[NSString stringWithFormat:@"Udp Echo server started on port %hu", [udpRecieveSocket localPort]]];
        [self setIsRunning:YES];

		[connectionButton setTag:1];
		[connectionButton setTitle:@"Stop" forState:UIControlStateNormal];
        
        [self sendMessageToServer:@"GLEDIATOR;GET_REQUEST;dummy;"];
    }
}

#pragma mark
#pragma mark - Picker View methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
{
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *msg = [NSString stringWithFormat:@"GLEDIATOR;SET_SCENE;%d;",row];
    [self sendMessageToServer:msg];

}

-(void) sendMessageToServer:(NSString *)message{
    NSString *host = addressField.text;
	if ([host length] == 0)
	{
		[self logError:@"Address required"];
		return;
	}
	
	int port = [portField.text intValue];
	if (port <= 0 || port > 65535)
	{
		[self logError:@"Valid port required"];
		return;
	}
    
	
	if ([message length] == 0)
	{
		[self logError:@"Message required"];
		return;
	}
	
    
	NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
	[udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:tag];
    
	[self logMessage:[NSString stringWithFormat:@"SENT (%i): %@", (int)tag, message]];
	
	tag++;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
{
    return [commands count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
{
    return [commands objectAtIndex:row];
}

@end
