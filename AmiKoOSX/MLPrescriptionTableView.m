//
//  MLPrescriptionTableView.m
//  AmiKo
//
//  Created by Alex Bettarini on 7 May 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPrescriptionTableView.h"

#ifdef DEBUG
#import "MLColors.h"
#endif

@implementation MLPrescriptionTableView

#pragma mark Printing

#ifdef METHOD_2

// NSView method
// To draw additional marks
// To draw logo see https://stackoverflow.com/questions/9038240/is-it-possible-to-change-the-header-height-of-an-nstextview
- (void)drawPageBorderWithSize:(NSSize)pageSize // same as printInfo NSPaperSize
{
    [super drawPageBorderWithSize:pageSize];

    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    
    NSRect savedFrame = [self frame];
    NSRect newFrame = NSMakeRect(0, 0, pageSize.width, pageSize.height);

    CGFloat tableViewWidth = savedFrame.size.width;
    // variable margin in the view, around the table view
    CGFloat yellowMargin = (pageSize.width-[printInfo rightMargin]-[printInfo leftMargin] - tableViewWidth)/2;
    
    // Alignment guides
    CGFloat leftPosition = [printInfo leftMargin] + yellowMargin + 3; // table view text has a 3-pix inset
    CGFloat rightPosition = pageSize.width - [printInfo rightMargin] - yellowMargin;

    CGFloat fontSize = 11;

#ifdef DEBUG
    [[NSColor lightRed] set];
    NSRect r1 = newFrame;
    NSRectFill( r1 );

    [[NSColor yellowColor] set];
    CGFloat h = pageSize.height-[printInfo topMargin]-[printInfo bottomMargin];
    NSRect r1a = NSMakeRect([printInfo leftMargin],
                            pageSize.height-[printInfo topMargin]-h,
                            pageSize.width-[printInfo rightMargin]-[printInfo leftMargin],
                            h); // XYWH
    NSLog(@"%d yellow:%@", __LINE__, NSStringFromRect(r1a));
    NSRectFill( r1a );

    NSRect r2 = NSMakeRect(2, 2, 30, 30); // (0,0) is BL corner of the page
    [[NSColor blueColor] set];
    NSRectFill( r2 );

    // mark the top margin
    NSRect r3 = NSMakeRect(0, pageSize.height-[printInfo topMargin],
                           pageSize.width, 2);
    [[NSColor textColor] set];
    NSRectFill( r3 );
    
#if 0
    // logo
    NSImage* logo = [NSImage imageNamed:@"desitin_icon_512x512"];
    NSSize logoSize = [logo size];
    NSPoint offset = NSMakePoint((leftPosition+rightPosition)/2 - logoSize.width/2, 20.0);
    NSPoint imageOrigin = NSMakePoint(offset.x, pageSize.height - (offset.y + logoSize.height));
    [logo drawInRect:NSMakeRect(imageOrigin.x, imageOrigin.y, logoSize.width, logoSize.height)
                                fromRect:NSZeroRect
                                operation:NSCompositingOperationSourceOver
                                fraction:1.0
                                respectFlipped:YES
                                hints:nil];
#endif
#endif

    // Temporarily set print view frame size to border size (paper size), to print in margins.
    [self setFrame:newFrame];

    // patient
    NSMutableParagraphStyle *paragraphStyleLeft = NSMutableParagraphStyle.new;
    paragraphStyleLeft.alignment = NSTextAlignmentLeft;
    NSAttributedString *strPat =
    [[NSAttributedString alloc] initWithString:self.patient
                                    attributes:@{NSParagraphStyleAttributeName:paragraphStyleLeft,
                                                 NSFontAttributeName:[NSFont systemFontOfSize:fontSize]}];

    // doctor
    NSMutableAttributedString *strDoc =
    [[NSMutableAttributedString alloc] initWithString:self.doctor];
    [strDoc setAlignment:NSTextAlignmentRight range:NSMakeRange(0, [strDoc length])];
    
    [strDoc addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:fontSize]
#ifdef DEBUG
                            , NSBackgroundColorAttributeName:[NSColor greenColor]
#endif
                            }
                    range:NSMakeRange(0, [strDoc length])];

    // place date
    NSAttributedString *strPlaceDate =
    [[NSAttributedString alloc] initWithString:self.self.placeDate
                                    attributes:@{NSParagraphStyleAttributeName:paragraphStyleLeft,
                                                 NSFontAttributeName:[NSFont systemFontOfSize:fontSize]
                                                 }];
    //
    NSAttributedString *jobTitle =
    [[NSAttributedString alloc] initWithString:[[NSPrintOperation currentOperation] jobTitle]
                                    attributes:@{NSParagraphStyleAttributeName:paragraphStyleLeft,
                                                 NSFontAttributeName:[NSFont systemFontOfSize:fontSize]
#ifdef DEBUG
                                                 , NSBackgroundColorAttributeName:[NSColor greenColor]
#endif
                                                 }];
    
    NSMutableAttributedString *pageNumber = [[super pageFooter] mutableCopy];
    // Trim leading white space
    //NSUInteger nReplacements =
    [[pageNumber mutableString] replaceOccurrencesOfString:@"\t"
                                            withString:@""
                                               options:NSAnchoredSearch
                                                 range:NSMakeRange(0, [pageNumber length])];
    //NSString *s = pageNumber.string;
    //NSLog(@"nReplacements %lu for <%@> %lu", (unsigned long)nReplacements, s, (unsigned long)s.length);
    [pageNumber addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:fontSize]
#ifdef DEBUG
                            , NSBackgroundColorAttributeName:[NSColor greenColor]
#endif
                            }
                    range:NSMakeRange(0, [pageNumber length])];

    // Placement
    CGFloat topPageNum   = pageSize.height - mm2pix(50);
    CGFloat topPatDoc    = pageSize.height - mm2pix(60);
    CGFloat topSignature = topPatDoc - strDoc.size.height; // bottom of doc
    CGFloat topPlaceDate = topPatDoc - strPat.size.height - mm2pix(5);  // 5mm below pat
    
    NSSize signSize = [self.signature size];
    NSPoint signOrigin = NSMakePoint(rightPosition - signSize.width,
                                     topSignature - signSize.height);

    // Draw everything

    //[self lockFocus];

    [jobTitle drawAtPoint:NSMakePoint(leftPosition, topPageNum)];
    [pageNumber drawAtPoint:NSMakePoint(rightPosition - pageNumber.size.width, topPageNum)];

    [strPat drawAtPoint:NSMakePoint(leftPosition,
                                    topPatDoc - strPat.size.height)]; // BL corner
    
    [strDoc drawAtPoint:NSMakePoint(rightPosition - signSize.width, //- strDoc.size.width,
                                    topPatDoc - strDoc.size.height)]; // BL corner

    [self.signature drawInRect:NSMakeRect(signOrigin.x, signOrigin.y, signSize.width, signSize.height)
                      fromRect:NSZeroRect
                     operation:NSCompositingOperationSourceOver
                      fraction:1.0
                respectFlipped:YES
                         hints:nil];
    
    [strPlaceDate drawAtPoint:NSMakePoint(leftPosition, topPlaceDate-strPlaceDate.size.height)];

    //[self unlockFocus];

    // Restore print view frame size.
    [self setFrame:savedFrame];
}
#endif

#ifdef DEBUG
- (void)drawRect:(NSRect)dirtyRect
{
    if ([[NSGraphicsContext currentContext] isDrawingToScreen]) {
        [super drawRect:dirtyRect];
        return;
    }
    
    NSLog(@"%s dirtyRect %@", __FUNCTION__, NSStringFromRect(dirtyRect));
    
    [[NSColor blueColor] set];
    NSRectFill( dirtyRect );
}
#endif

#ifndef METHOD_2
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
#endif

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
