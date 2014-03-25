//
//  CCHLinkTextView.m
//  CCHLinkTextView
//
//  Copyright (C) 2014 Claus Höfele
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

// Based on http://stackoverflow.com/questions/19332283/detecting-taps-on-attributed-text-in-a-uitextview-on-ios-7

#import "CCHLinkTextView.h"

#import "CCHLinkTextViewDelegate.h"
#import "CCHLinkGestureRecognizer.h"

NSString *const CCHLinkAttributeName = @"CCHLinkAttributeName";
#define DEBUG_COLOR [UIColor colorWithWhite:0 alpha:0.3]

@interface CCHLinkTextView () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGPoint touchDownLocation;
@property (nonatomic, strong) CCHLinkGestureRecognizer *linkGestureRecognizer;

@end

@implementation CCHLinkTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setUp];
}

- (void)setUp
{
    self.touchDownLocation = CGPointZero;
    
    self.linkGestureRecognizer = [[CCHLinkGestureRecognizer alloc] initWithTarget:self action:@selector(linkAction:)];
    self.linkGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.linkGestureRecognizer];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    NSMutableAttributedString *mutableAttributedText = [attributedText mutableCopy];
    [mutableAttributedText enumerateAttribute:CCHLinkAttributeName inRange:NSMakeRange(0, attributedText.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            [mutableAttributedText addAttributes:self.linkTextAttributes range:range];
        }
    }];
    
    [super setAttributedText:mutableAttributedText];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    UIGraphicsPushContext(context);
//
//    CGContextSetFillColorWithColor(context, DEBUG_COLOR.CGColor);
//    [self enumerateViewRectsForRanges:self.linkRanges usingBlock:^(CGRect rect, NSRange range, BOOL *stop) {
//        CGContextFillRect(context, rect);
//    }];
//    
//    UIGraphicsPopContext();
}

- (BOOL)enumerateLinkRangesContainingLocation:(CGPoint)location usingBlock:(void (^)(NSRange range))block
{
    __block BOOL found = NO;
    
    NSAttributedString *attributedString = self.attributedText;
    [attributedString enumerateAttribute:CCHLinkAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            [self enumerateViewRectsForRanges:@[[NSValue valueWithRange:range]] usingBlock:^(CGRect rect, NSRange range, BOOL *stop) {
                if (CGRectContainsPoint(rect, location)) {
                    found = YES;
                    *stop = YES;
                    if (block) {
                        block(range);
                    }
                }
            }];
        }
    }];
    
    return found;
}

- (void)enumerateViewRectsForRanges:(NSArray *)ranges usingBlock:(void (^)(CGRect rect, NSRange range, BOOL *stop))block
{
    if (!block) {
        return;
    }

    for (NSValue *rangeAsValue in ranges) {
        NSRange range = rangeAsValue.rangeValue;
        NSRange glyphRange = [self.layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
        [self.layoutManager enumerateEnclosingRectsForGlyphRange:glyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:self.textContainer usingBlock:^(CGRect rect, BOOL *stop) {
            rect.origin.x += self.textContainerInset.left;
            rect.origin.y += self.textContainerInset.top;
            
            block(rect, range, stop);
        }];
    }
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    NSMutableAttributedString *attributedText = [self.attributedText mutableCopy];
    [attributedText addAttributes:attributes range:range];
    self.attributedText = attributedText;
}

- (void)setMinimumPressDuration:(CFTimeInterval)minimumPressDuration
{
    self.linkGestureRecognizer.minimumPressDuration = minimumPressDuration;
}

- (CFTimeInterval)minimumPressDuration
{
    return self.linkGestureRecognizer.minimumPressDuration;
}

- (void)setAllowableMovement:(CGFloat)allowableMovement
{
    self.linkGestureRecognizer.allowableMovement = allowableMovement;
}

- (CGFloat)allowableMovement
{
    return self.linkGestureRecognizer.allowableMovement;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL linkFound = [self enumerateLinkRangesContainingLocation:point usingBlock:NULL];
    return linkFound;
}

#pragma mark Gesture recognition

- (void)linkAction:(CCHLinkGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSAssert(CGPointEqualToPoint(self.touchDownLocation, CGPointZero), @"Invalid touch down location");
        
        CGPoint location = [recognizer locationInView:self];
        self.touchDownLocation = location;
        [self didTouchDownAtLocation:location];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSAssert(!CGPointEqualToPoint(self.touchDownLocation, CGPointZero), @"Invalid touch down location");
        
        CGPoint location = self.touchDownLocation;
        if (recognizer.result == CCHLinkGestureRecognizerResultTap) {
            [self didTapAtLocation:location];
        } else if (recognizer.result == CCHLinkGestureRecognizerResultLongPress) {
            [self didLongPressAtLocation:location];
        }
        
        [self didCancelTouchDownAtLocation:location];
        self.touchDownLocation = CGPointZero;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark Gesture handling

- (void)didTouchDownAtLocation:(CGPoint)location
{
    [self enumerateLinkRangesContainingLocation:location usingBlock:^(NSRange range) {
        NSDictionary *attributes = @{NSBackgroundColorAttributeName : UIColor.greenColor};
        [self addAttributes:attributes range:range];
    }];
}

- (void)didCancelTouchDownAtLocation:(CGPoint)location
{
    [self enumerateLinkRangesContainingLocation:location usingBlock:^(NSRange range) {
        NSDictionary *attributes = @{NSBackgroundColorAttributeName : UIColor.clearColor};
        [self addAttributes:attributes range:range];
    }];
}

- (void)didTapAtLocation:(CGPoint)location
{
    [self enumerateLinkRangesContainingLocation:location usingBlock:^(NSRange range) {
        if ([self.linkDelegate respondsToSelector:@selector(linkTextView:didTapLinkWithValue:)]) {
            id value = [self.attributedText attribute:CCHLinkAttributeName atIndex:range.location effectiveRange:NULL];
            [self.linkDelegate linkTextView:self didTapLinkWithValue:value];
        }
    }];
}

- (void)didLongPressAtLocation:(CGPoint)location
{
    [self enumerateLinkRangesContainingLocation:location usingBlock:^(NSRange range) {
        if ([self.linkDelegate respondsToSelector:@selector(linkTextView:didLongPressLinkWithValue:)]) {
            id value = [self.attributedText attribute:CCHLinkAttributeName atIndex:range.location effectiveRange:NULL];
            [self.linkDelegate linkTextView:self didLongPressLinkWithValue:value];
        }
    }];
}

@end
