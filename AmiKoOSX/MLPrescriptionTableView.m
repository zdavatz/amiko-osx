//
//  MLPrescriptionTableView.m
//  AmiKo
//
//  Created by Alex Bettarini on 7 May 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPrescriptionTableView.h"

@implementation MLPrescriptionTableView

// Page headers are generated only if the user defaults contain the key NSPrintHeaderAndFooter with the value YES.
// As for images, those can be added to a NSAttributedString using a NSTextAttachment
// mySignView
- (NSAttributedString *)pageHeader
{
    // doctor
    NSMutableAttributedString *strDoc =
    [[NSMutableAttributedString alloc] initWithString:self.doctor];
    [strDoc setAlignment:NSTextAlignmentRight range:NSMakeRange(0, [strDoc length])];
    
    [strDoc addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:9]}
                    range:NSMakeRange(0, [strDoc length])];
    
    // patient
    NSMutableParagraphStyle *paragraphStyleLeft = NSMutableParagraphStyle.new;
    paragraphStyleLeft.alignment = NSTextAlignmentLeft;
    NSAttributedString *strPat =
    [[NSAttributedString alloc] initWithString:self.patient
                                    attributes:@{NSParagraphStyleAttributeName:paragraphStyleLeft,
                                                 NSFontAttributeName:[NSFont systemFontOfSize:9]}];
    
    // signature
    NSTextAttachment *icon = [[NSTextAttachment alloc] init];
    [icon setImage:self.signature];
    NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:icon];
    NSMutableAttributedString *attrStringWithImageR = [attrStringWithImage mutableCopy];
    [attrStringWithImageR setAlignment:NSTextAlignmentRight range:NSMakeRange(0, [attrStringWithImageR length])];
    
    // place date
    NSAttributedString *strPlaceDate =
    [[NSAttributedString alloc] initWithString:self.self.placeDate
                                    attributes:@{NSParagraphStyleAttributeName:paragraphStyleLeft,
                                                 NSFontAttributeName:[NSFont systemFontOfSize:9]
                                                 }];
    
    //
    NSAttributedString *strNewLine = [[NSAttributedString alloc] initWithString:@"\n"];
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
    [str appendAttributedString:[super pageHeader]];  // app name, time stamp
    [str appendAttributedString:[super pageFooter]];  // page number
    [str appendAttributedString:strNewLine];
    [str appendAttributedString:strPat];
    [str appendAttributedString:strNewLine];
    [str appendAttributedString:strDoc];
    [str appendAttributedString:strNewLine];
    [str appendAttributedString:attrStringWithImageR];
    [str appendAttributedString:strNewLine];
    [str appendAttributedString:strPlaceDate];
    
    return str;
}

- (NSAttributedString *)pageFooter
{
    return nil;
}

// Thankyou http://iannopollo.com/blog/2012/11/03/print-and-paginate-nstableviews/
// Taken from here: http://lists.apple.com/archives/cocoa-dev/2002/Nov/msg01710.html
// Ensures rows in the table aren't cut off when printing
- (void)adjustPageHeightNew:(CGFloat *)newBottom
                        top:(CGFloat)oldTop
                     bottom:(CGFloat)oldBottom
                      limit:(CGFloat)bottomLimit
{
    if (!topBorderRows) {
        topBorderRows = [NSMutableArray array];
        bottomBorderRows = [NSMutableArray array];
    }
    
    NSInteger cutoffRow = [self rowAtPoint:NSMakePoint(0, oldBottom)];
    NSRect rowBounds;
    
    *newBottom = oldBottom;
    if (cutoffRow != -1) {
        rowBounds = [self rectOfRow:cutoffRow];
        if (oldBottom < NSMaxY(rowBounds)) {
            *newBottom = NSMinY(rowBounds);
            
            NSNumber *row = [NSNumber numberWithInteger:cutoffRow];
            NSNumber *previousRow = [NSNumber numberWithInteger:cutoffRow - 1];
            
            // Mark which rows need which border, ignore ones we've already seen, and adjust ones that need different borders
            if (![[topBorderRows lastObject] isEqual:row]) {
                if ([[bottomBorderRows lastObject] isEqual:row]) {
                    [topBorderRows removeLastObject];
                    [bottomBorderRows removeLastObject];
                }
                
                [topBorderRows addObject:row];
                [bottomBorderRows addObject:previousRow];
            }
        }
    }
}

// Draw the row as normal, and add any borders to cells that were pushed down due to pagination
- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect
{
    [super drawRow:rowIndex clipRect:clipRect];
    
    if ([topBorderRows count] == 0)
        return;
    
    NSRect rowRect = [self rectOfRow:rowIndex];
    NSBezierPath *gridPath = [NSBezierPath bezierPath];
    NSColor *color = [NSColor darkGrayColor];
    
    for (int i=0; i<[topBorderRows count]; i++) {
        NSInteger rowNeedingTopBorder = [(NSNumber *)[topBorderRows objectAtIndex:i] integerValue];
        if (rowNeedingTopBorder == rowIndex) {
            [gridPath moveToPoint:rowRect.origin];
            [gridPath lineToPoint:NSMakePoint(rowRect.origin.x + rowRect.size.width, rowRect.origin.y)];
            
            [color setStroke];
            [gridPath stroke];
        }
        
        NSInteger rowNeedingBottomBorder = [(NSNumber *)[bottomBorderRows objectAtIndex:i] integerValue];
        if (rowNeedingBottomBorder == rowIndex) {
            [gridPath moveToPoint:NSMakePoint(rowRect.origin.x, rowRect.origin.y + rowRect.size.height)];
            [gridPath lineToPoint:NSMakePoint(rowRect.origin.x + rowRect.size.width, rowRect.origin.y + rowRect.size.height)];
            
            [color setStroke];
            [gridPath stroke];
        }
    }
}

@end
