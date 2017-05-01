/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
 This file is part of AmiKo for OSX.
 
 AmiKo for OSX is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLMedication.h"
#import "MLUtilities.h"

static NSString* SectionTitle_DE[] = {@"Zusammensetzung", @"Galenische Form", @"Kontraindikationen", @"Indikationen", @"Dosierung/Anwendung",
    @"Vorsichtsmassnahmen", @"Interaktionen", @"Schwangerschaft", @"Fahrtüchtigkeit", @"Unerwünschte Wirk.", @"Überdosierung", @"Eig./Wirkung",
    @"Kinetik", @"Präklinik", @"Sonstige Hinweise", @"Zulassungsnummer", @"Packungen", @"Inhaberin", @"Stand der Information"};

static NSString* SectionTitle_FR[] = {@"Composition", @"Forme galénique", @"Contre-indications", @"Indications", @"Posologie", @"Précautions",
    @"Interactions", @"Grossesse/All.", @"Conduite", @"Effets indésir.", @"Surdosage", @"Propriétés/Effets", @"Cinétique", @"Préclinique", @"Remarques",
    @"Numéro d'autorisation", @"Présentation", @"Titulaire", @"Mise à jour"};

@implementation MLMedication

@synthesize medId;
@synthesize customerId;
@synthesize title;
@synthesize auth;
@synthesize atccode;
@synthesize substances;
@synthesize regnrs;
@synthesize atcClass;
@synthesize therapy;
@synthesize application;
@synthesize indications;
@synthesize packInfo;
@synthesize addInfo;
@synthesize sectionIds;
@synthesize sectionTitles;
@synthesize styleStr;
@synthesize contentStr;

- (NSArray *) listOfSectionIds
{
    return [sectionIds componentsSeparatedByString:@","];
}

- (NSArray *) listOfSectionTitles
{
    NSMutableArray *titles = [[sectionTitles componentsSeparatedByString:@";"] mutableCopy];
    NSUInteger n = [titles count];
    for (int i=0; i<n; ++i) {
        titles[i] = [self shortTitle:titles[i]];
    }
    return titles;
}

- (NSDictionary *) indexToTitlesDict
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    NSArray *ids = [self listOfSectionIds];
    NSArray *titles = [self listOfSectionTitles];
    
    NSUInteger n1 = [ids count];
    NSUInteger n2 = [titles count];
    NSUInteger n = n1 < n2 ? n1 : n2;
    for (NSUInteger i=0; i<n; ++i) {
        NSString *id = ids[i];
        id = [id stringByReplacingOccurrencesOfString:@"section" withString:@""];
        id = [id stringByReplacingOccurrencesOfString:@"Section" withString:@""];
        if ([id length]>0) {
            dict[id] = [self shortTitle:titles[i]];
        }
    }
    
    return dict;
}

- (NSString *) shortTitle:(NSString *)longTitle
{
    NSString *t = [longTitle lowercaseString];
    if ([MLUtilities isGermanApp]) {
        for (int i=0; i<19; i++) {
            NSString *compareString = [SectionTitle_DE[i] lowercaseString];
            if (compareString!=nil) {
                if ([t rangeOfString:compareString].location != NSNotFound) {
                    t = SectionTitle_DE[i];
                    return t;
                }
            }
        }
    } else if ([MLUtilities isFrenchApp]) {
        for (int i=0; i<19; i++) {
            NSString *compareString = [SectionTitle_FR[i] lowercaseString];
            if (compareString!=nil) {
                if ([t rangeOfString:compareString].location != NSNotFound) {
                    t = SectionTitle_FR[i];
                    return t;
                }
            }
        }
    }
    return longTitle;
}

@end
