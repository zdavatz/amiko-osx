/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 27/07/2017.
 
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

#import "MLAbout.h"
#import "MLUtilities.h"

@implementation MLAbout

+ (void) showReportFile
{
    // A. Check first users documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Get documents directory
    NSString *documentsDir = [MLUtilities documentsDirectory];
    if ([MLUtilities isGermanApp]) {
        NSString *filePath = [[documentsDir stringByAppendingPathComponent:@"amiko_report_de"] stringByAppendingPathExtension:@"html"];
        if ([fileManager fileExistsAtPath:filePath]) {
            // Starts Safari
            [[NSWorkspace sharedWorkspace] openFile:filePath];
        } else {
            NSURL *aboutFile = [[NSBundle mainBundle] URLForResource:@"amiko_report_de" withExtension:@"html"];
            // Starts Safari
            [[NSWorkspace sharedWorkspace] openURL:aboutFile];
        }
    } else if ([MLUtilities isFrenchApp]) {
        NSString *filePath = [[documentsDir stringByAppendingPathComponent:@"amiko_report_fr"] stringByAppendingPathExtension:@"html"];
        if ([fileManager fileExistsAtPath:filePath]) {
            // Starts Safari
            [[NSWorkspace sharedWorkspace] openFile:filePath];
        } else {
            NSURL *aboutFile = [[NSBundle mainBundle] URLForResource:@"amiko_report_fr" withExtension:@"html"];
            // Starts Safari
            [[NSWorkspace sharedWorkspace] openURL:aboutFile];
        }
    }
}

+ (void) showAboutPanel
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *creditsPath = [mainBundle pathForResource:@"Credits" ofType:@"rtf"];  // localized
    NSAttributedString *credits = [[NSAttributedString alloc] initWithPath:creditsPath documentAttributes:nil];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd.MM.yyyy"];
    NSString *compileDate = [dateFormat stringFromDate:today];
    
    NSString *versionString = [NSString stringWithFormat:@"%@", compileDate];
    
    NSDictionary *optionsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 credits, @"Credits",
                                 [mainBundle objectForInfoDictionaryKey:@"CFBundleName"], @"ApplicationName",
                                 [mainBundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"], @"Copyright",
                                 [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], @"ApplicationVersion",
                                 versionString, @"Version",
                                 nil];
    
    [NSApp orderFrontStandardAboutPanelWithOptions:optionsDict];
}

+ (void) sendFeedback
{
    NSString *subject = [NSString stringWithFormat:@"%@ Feedback", APP_NAME];
    NSString *encodedSubject = [NSString stringWithFormat:@"mailto:zdavatz@ywesee.com?subject=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *helpFile = [NSURL URLWithString:encodedSubject];
    // Starts mail client
    [[NSWorkspace sharedWorkspace] openURL:helpFile];
}

+ (void) shareApp
{
    // Starts mail client
    NSString* subject = [NSString stringWithFormat:@"%@ OS X", APP_NAME];
    NSString* body = nil;
    if ([MLUtilities isGermanApp])
        body = [NSString stringWithFormat:@"%@ OS X: Schweizer Arzneimittelkompendium\r\n\n"
                "Get it now: https://itunes.apple.com/us/app/amiko/id%@?mt=12\r\n\nEnjoy!\r\n", APP_NAME, APP_ID];
    else if ([MLUtilities isFrenchApp])
        body = [NSString stringWithFormat:@"%@ OS X: Compendium des Médicaments Suisse\r\n\n"
                "Get it now: https://itunes.apple.com/us/app/amiko/id%@?mt=12\r\n\nEnjoy!\r\n", APP_NAME, APP_ID];

    NSString *encodedSubject = [NSString stringWithFormat:@"subject=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedBody = [NSString stringWithFormat:@"body=%@", [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedURLString = [NSString stringWithFormat:@"mailto:?%@&%@", encodedSubject, encodedBody];
    
    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
    
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

+ (void) rateApp
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", APP_ID]]];
}

+ (void) showHelp
{
    // Starts Safari
    if ([[MLUtilities appOwner] isEqualToString:@"zurrose"]) {
        NSURL *helpFile = [NSURL URLWithString:@"http://www.zurrose.ch/amiko"];
        [[NSWorkspace sharedWorkspace] openURL:helpFile];
    }
    else if ([[MLUtilities appOwner] isEqualToString:@"ywesee"]) {
        NSURL *helpFile = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/amiko/id%@?mt=12", APP_ID]];
        [[NSWorkspace sharedWorkspace] openURL:helpFile];
    }
    else if ([[MLUtilities appOwner] isEqualToString:@"desitin"]) {
        NSURL *helpFile = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/amiko/id%@?mt=12", APP_ID]];
        [[NSWorkspace sharedWorkspace] openURL:helpFile];
    }
}

@end
