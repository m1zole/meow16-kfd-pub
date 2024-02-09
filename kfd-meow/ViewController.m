//
//  ViewController.m
//  kfd-meow
//
//  Created by doraaa on 2023/12/14.
//

#import "ViewController.h"
#include "libkfd.h"
#include "pplrw.h"
#include "troll.h"
#include "meow.h"

uint64_t _kfd = 0;
uint64_t puaf_method = 2;
uint64_t mode = 0;

extern void (*log_UI)(const char *text);
void log_toView(const char *text);
static ViewController *sharedController = nil;

uint64_t kopen_bridge(uint64_t puaf_method, uint64_t debug) {
    uint64_t exploit_type = (1 << puaf_method);
    _kfd = kopen(exploit_type, debug);
    offset_exporter();
    if(debug == 0) {
        if(isarm64e()) {
            sleep(1);
            test_pplrw();
        } else {
            sleep(1);
            meow();
        }
    } else {
        TrollStoreinstall();
    }
    if(_kfd != 0)
        return _kfd;
    
    return 0;
}

uint64_t kclose_bridge(uint64_t _kfd) {
    kclose(_kfd);
    return 0;
}


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *meowButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *SelectedExploit;
@property (weak, nonatomic) IBOutlet UISegmentedControl *SelectedMode;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    sharedController = self;
    self.textView.text = @"[*] hi";
    self.textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
    [[sharedController meowButton] setEnabled:TRUE];
    log_UI = log_toView;
}

- (IBAction)meow:(id)sender {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        _kfd = kopen_bridge(puaf_method, 0);
        
        sleep(1);
        
        if(_kfd) {
            
            NSLog(@"Success");
            kclose(_kfd);
        }
        
    });
}

- (IBAction)exploit:(id)sender {
    puaf_method = self.SelectedExploit.selectedSegmentIndex;
}

- (IBAction)mode:(id)sender {
    mode = self.SelectedMode.selectedSegmentIndex;
}


@end

void log_toView(const char *text)
{
    dispatch_sync( dispatch_get_main_queue(), ^{
        [[sharedController textView] insertText:[NSString stringWithUTF8String:text]];
        [[sharedController textView] scrollRangeToVisible:NSMakeRange([sharedController textView].text.length, 1)];
    });
}
