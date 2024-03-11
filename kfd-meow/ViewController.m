//
//  ViewController.m
//  kfd-meow
//
//  Created by doraaa on 2023/12/14.
//

#import "ViewController.h"
#include "kfd/libkfd.h"
#include "dmaFail/pplrw.h"
#include "sockport2/sockport2.h"
#include "utils.h"

uint64_t _kfd = 0;
uint64_t puaf_method = 1;

extern void (*log_UI)(const char *text);
void log_toView(const char *text);
static ViewController *sharedController = nil;

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
    self.textView.text = @"";
    self.textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
    [[sharedController meowButton] setEnabled:TRUE];
    log_UI = log_toView;
}

- (IBAction)meow:(id)sender {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char buf[16];
        if (puaf_method == 2) {
            get_tfp0();
            if (@available(iOS 10.0, *)) {
                kreadbuf_sp(KERNEL_BASE_ADDRESS + get_kslide_new(), buf, sizeof(buf));
            } else {
                kreadbuf_sp(KERNEL_BASE_ADDRESS9 + get_kslide_anchor(), buf, sizeof(buf));
            }
        } else {
            _kfd = kopen((1 << puaf_method));
            kreadbuf_kfd(KERNEL_BASE_ADDRESS + get_kernel_slide(), buf, sizeof(buf));
        }
        
        util_hexprint(buf, sizeof(buf), "kbase");
        
        if(isarm64e()) {
            sleep(1);
            test_pplrw();
        }
        
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
    uint64_t mode = self.SelectedMode.selectedSegmentIndex;
    if(!mode) {
        printf("nothing to do!\n");
    }
}


@end

void log_toView(const char *text)
{
    dispatch_sync( dispatch_get_main_queue(), ^{
        [[sharedController textView] insertText:[NSString stringWithUTF8String:text]];
        [[sharedController textView] scrollRangeToVisible:NSMakeRange([sharedController textView].text.length, 1)];
    });
}
