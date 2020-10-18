//
//  MLPrescriptionTextFinderClient.m
//  AmiKo
//
//  Created by b123400 on 2020/10/15.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLPrescriptionTextFinderClient.h"
#import "MLPrescriptionCellView.h"

@interface MLPrescriptionTextFinderClient ()

@property (nonatomic, strong) MLPrescriptionsAdapter *adapter;
@property (nonatomic, weak) MLMainWindowController *mainWindowController;

// e.g.
// ["patient name", "doctor name", "med 1", "med 2"]
@property (nonatomic, strong) NSArray<NSString*> *searchStrings;

// The index of search string of patient in searchString, or -1
@property (nonatomic, assign) NSInteger patientIndex;
// The index of search string of doctor in searchString, or -1
@property (nonatomic, assign) NSInteger doctorIndex;
// The index of beginning of search strings of packages, e.g. prescriptions start with this index
@property (nonatomic, assign) NSInteger prescriptionIndex;

@end

@implementation MLPrescriptionTextFinderClient

- (instancetype)initWithAdapter:(MLPrescriptionsAdapter*)adapter mainWindowController:(MLMainWindowController*)mainWindowController {
    if (self = [super init]) {
        self.adapter = adapter;
        self.mainWindowController = mainWindowController;
        self.searchStrings = @[];
        self.patientIndex = -1;
        self.doctorIndex = -1;
        self.prescriptionIndex = 0;
    }
    return self;
}

- (BOOL)isSelectable {
    return NO;
}
- (BOOL)allowsMultipleSelection {
    return NO;
}

- (NSRange)firstSelectedRange {
    return NSMakeRange(0, 0);
}

- (void)reloadSearchString {
    self.patientIndex = -1;
    self.doctorIndex = -1;
    NSInteger index = 0;
    NSMutableArray<NSString *> *strings = [NSMutableArray array];
    NSString *patientString = [[self.adapter patient] asString];
    if ([patientString length]) {
        [strings addObject:patientString];
        self.patientIndex = index;
        index++;
    }
    if ([self.adapter.doctor.familyName length] && [self.adapter.doctor.givenName length]) {
        NSString *doctorString = [self.adapter.doctor retrieveOperatorAsString];
        if ([doctorString length]) {
            [strings addObject:doctorString];
            self.doctorIndex = index;
            index++;
        }
    }
    MLPrescriptionsCart *cart = [MLMainWindowController prescriptionsCartWithId:0];
    NSArray<MLPrescriptionItem*> *items = cart.cart;
    self.prescriptionIndex = index;
    for (MLPrescriptionItem *item in items) {
        [strings addObject:[item fullPackageInfo]];
    }
    self.searchStrings = strings;
}

- (NSString *)stringAtIndex:(NSUInteger)characterIndex effectiveRange:(NSRangePointer)outRange endsWithSearchBoundary:(BOOL *)outFlag {
    int currentCharacterIndex = 0;
    for (NSString *string in self.searchStrings) {
        BOOL isThisString = currentCharacterIndex <= characterIndex && characterIndex < currentCharacterIndex + string.length;
        if (isThisString) {
            *outFlag = YES;
            (*outRange).location = currentCharacterIndex;
            (*outRange).length = [string length];
            return string;
        } else {
            currentCharacterIndex += string.length;
        }
    }
    return nil;
}

- (NSUInteger)stringLength {
    return [[self.searchStrings valueForKeyPath:@"@sum.length"] unsignedIntegerValue];
}

- (void)scrollRangeToVisible:(NSRange)range {
    int currentCharacterIndex = 0;
    NSUInteger characterIndex = range.location;
    for (NSInteger i = 0; i < self.searchStrings.count; i++) {
        NSString *string = self.searchStrings[i];
        BOOL isThisString = currentCharacterIndex <= characterIndex && characterIndex < currentCharacterIndex + string.length;
        if (isThisString) {
            if (i >= self.prescriptionIndex) {
                NSUInteger rowIndex = i - self.prescriptionIndex;
                [self.mainWindowController.myPrescriptionsTableView scrollRowToVisible:rowIndex];
                return;
            }
        } else {
            currentCharacterIndex += string.length;
        }
    }
}

- (NSView *)contentViewAtIndex:(NSUInteger)characterIndex effectiveCharacterRange:(NSRangePointer)outRange {
    int currentCharacterIndex = 0;
    for (NSInteger i = 0; i < self.searchStrings.count; i++) {
        NSString *string = self.searchStrings[i];
        BOOL isThisString = currentCharacterIndex <= characterIndex && characterIndex < currentCharacterIndex + string.length;
        if (isThisString) {
            (*outRange).location = currentCharacterIndex;
            (*outRange).length = [string length];
            if (i == self.patientIndex) {
                NSLog(@"returning paitent");
                return self.mainWindowController.myPatientAddressTextField;
            } else if (i == self.doctorIndex) {
                NSLog(@"returning doctor");
                return self.mainWindowController.myOperatorIDTextField;
            } else {
                MLPrescriptionCellView *cellView = [self.mainWindowController.myPrescriptionsTableView viewAtColumn: 0
                                                                                                                row: i - self.prescriptionIndex
                                                                                                    makeIfNecessary:NO];
                NSLog(@"cell view: %@", [cellView description]);
                return [cellView textField];
            }
        } else {
            currentCharacterIndex += string.length;
        }
    }
    NSLog(@"return no view");
    return nil;
}

- (NSArray<NSValue *> *)rectsForCharacterRange:(NSRange)inRange {
    NSRange r = NSMakeRange(0, 0);
    NSView *view = [self contentViewAtIndex:inRange.location effectiveCharacterRange:&r];
    NSRange range = NSMakeRange(inRange.location - r.location, inRange.length);
    if ([view isKindOfClass:[NSTextField class]]) {
        NSTextField *textField = (NSTextField*)view;
        NSRect textBounds = [textField.cell titleRectForBounds:textField.bounds];

        NSTextContainer* textContainer = [[NSTextContainer alloc] init];
        NSLayoutManager* layoutManager = [[NSLayoutManager alloc] init];
        NSTextStorage* textStorage = [[NSTextStorage alloc] init];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
        textContainer.lineFragmentPadding = 2;
        layoutManager.typesetterBehavior = NSTypesetterBehavior_10_2_WithCompatibility;

        textContainer.containerSize = textBounds.size;
        [textStorage beginEditing];
        textStorage.attributedString = textField.attributedStringValue;
        [textStorage endEditing];

        NSUInteger count;
        NSRectArray rects = [layoutManager rectArrayForCharacterRange:range
                                         withinSelectedCharacterRange:range
                                                      inTextContainer:textContainer
                                                            rectCount:&count];
        NSMutableArray<NSValue *> *values = [NSMutableArray array];
        for (NSUInteger i = 0; i < count; i++)
        {
            NSRect rect = NSOffsetRect(rects[i], textBounds.origin.x, textBounds.origin.y);
            [values addObject:[NSValue valueWithRect:rect]];
        }
        
        return values;
    } else {
        NSLog(@"what type %@", [view description]);
        return nil;
    }
}

- (void)drawCharactersInRange:(NSRange)range forContentView:(NSView *)view {
    NSArray<NSValue *> *values = [self rectsForCharacterRange:range];
    for (NSValue *v in values) {
        [view drawRect:v.rectValue];
    }
}

@end
