/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
 This file is part of AMiKoOSX.
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
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

#import "MLSearchWebView.h"

@implementation WebView (MLSearchWebView)

- (NSInteger) highlightAllOccurencesOfString: (NSString*)str
{
    // Load Javascript file
    NSString *path = [[NSBundle mainBundle] pathForResource:@"MLSearchWebView" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    // Inject it into webpage
    [self stringByEvaluatingJavaScriptFromString:jsCode];
    
    // Call Javascript function
    NSString *startSearch = [NSString stringWithFormat:@"MyApp_HighlightAllOccurencesOfString('%@')", str];
    [self stringByEvaluatingJavaScriptFromString:startSearch];
    
    // Access variable defined in Javascript code
    NSString *result = [self stringByEvaluatingJavaScriptFromString:@"MyApp_SearchResultCount"];
    
    // Return
    return [result integerValue];
}

- (void) removeAllHighlights
{   
    [self stringByEvaluatingJavaScriptFromString:@"MyApp_RemoveAllHighlights()"];
}

@end
