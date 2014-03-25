//
//  ViewController.m
//  CCHLinkTextView Example
//

#import "ViewController.h"

#import "CCHLinkTextView.h"
#import "CCHLinkTextViewDelegate.h"
#import "TextView.h"

@interface ViewController () <CCHLinkTextViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet CCHLinkTextView *linkTextView;
@property (weak, nonatomic) IBOutlet TextView *standardTextView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpLinkTextView:self.linkTextView];
    [self setUpStandardTextView:self.standardTextView];
}

#pragma mark - CCHLinkTextView solution

- (void)setUpLinkTextView:(CCHLinkTextView *)linkTextView
{
    linkTextView.editable = NO;
    linkTextView.selectable = NO;
    
    NSMutableAttributedString *attributedText = [linkTextView.attributedText mutableCopy];
    if (attributedText) {
        [attributedText addAttribute:CCHLinkAttributeName value:@"1" range:NSMakeRange(0, 20)];
        [attributedText addAttribute:CCHLinkAttributeName value:@"2" range:NSMakeRange(5, 20)];
        [attributedText addAttribute:CCHLinkAttributeName value:@"3" range:NSMakeRange(120, 100)];
        linkTextView.attributedText = attributedText;
    }
    
    linkTextView.linkDelegate = self;
}

- (void)linkTextView:(CCHLinkTextView *)linkTextView didTapLinkWithValue:(id)value
{
    NSLog(@"Link tapped %@", value);
}

- (void)linkTextView:(CCHLinkTextView *)linkTextView didLongPressLinkWithValue:(id)value
{
    NSLog(@"Link long pressed %@", value);
}

#pragma mark - NSLinkAttributeName solution

- (void)setUpStandardTextView:(TextView *)standardTextView
{
    standardTextView.editable = NO;
    standardTextView.viewController = self;

    NSMutableAttributedString *attributedText = [standardTextView.attributedText mutableCopy];
    if (attributedText) {
        [attributedText addAttribute:NSLinkAttributeName value:@"1" range:NSMakeRange(0, 20)];
        [attributedText addAttribute:NSLinkAttributeName value:@"2" range:NSMakeRange(5, 20)];
        [attributedText addAttribute:NSLinkAttributeName value:@"3" range:NSMakeRange(120, 100)];
        standardTextView.attributedText = attributedText;
    }
    
//    attributedText = [standardTextView.attributedText mutableCopy];
//    if (attributedText) {
//        [attributedText addAttribute:NSForegroundColorAttributeName value:UIColor.redColor range:NSMakeRange(100, 50)];
//        [attributedText addAttribute:NSUnderlineStyleAttributeName value:@(1) range:NSMakeRange(100, 50)];
//        standardTextView.attributedText = attributedText;
//    }
    
    standardTextView.delegate = self;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    NSLog(@"Tap NSLinkAttributeName %@", URL);
    return NO;
}

@end
