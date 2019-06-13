/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 27/04/2017.
 
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

#import "MLInteractionsHtmlView.h"

#import "MLInteractionsCart.h"
#import "MLUtilities.h"

@implementation MLInteractionsHtmlView
{
    MLInteractionsCart *medCart;
}

@synthesize listofSectionIds;
@synthesize listofSectionTitles;

- (id) init
{
    medCart = [[MLInteractionsCart alloc] init];
    return [super init];
}

- (void) pushToMedBasket:(MLMedication *)med
{
    if (med!=nil) {
        NSString *title = [med title];
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([title length]>30) {
            title = [title substringToIndex:30];
            title = [title stringByAppendingString:@"..."];
        }
        
        // Add med to medication basket
        [medCart.cart setObject:med forKey:title];
    }
}

- (void) removeFromMedBasketForKey:(NSString *)key
{
    [medCart.cart removeObjectForKey:key];
}

- (void) clearMedBasket
{
    [medCart.cart removeAllObjects];
}

/** 
 Create full interactions html
 */
- (NSString *) fullInteractionsHtml:(MLInteractionsAdapter *)interactions
{
    // --> OPTIMIZE!! Pre-load the following files!
    
    NSString *colorCss = [MLUtilities getColorCss];

    // Load style sheet from file
    NSString *interactionsCssPath = [[NSBundle mainBundle] pathForResource:@"interactions_css" ofType:@"css"];
    NSString *interactionsCss = [NSString stringWithContentsOfFile:interactionsCssPath encoding:NSUTF8StringEncoding error:nil];
    
    // Load javascript from file
    NSString *jscriptPath = [[NSBundle mainBundle] pathForResource:@"interactions_callbacks" ofType:@"js"];
    NSString *jscriptStr = [NSString stringWithContentsOfFile:jscriptPath encoding:NSUTF8StringEncoding error:nil];
    
    // Generate main interaction table
    NSString *htmlStr = [NSString stringWithFormat:@"<html><head><meta charset=\"utf-8\" />"];
    htmlStr = [htmlStr stringByAppendingFormat:@"<script type=\"text/javascript\">%@</script><style type=\"text/css\">%@</style><style type=\"text/css\">%@</style></head><body><div id=\"interactions\">%@<br><br>%@<br>%@</body></div></html>",
               jscriptStr,
               colorCss,
               interactionsCss,
               [self medBasketHtml],
               [self interactionsHtml:interactions],
               [self footNoteHtml]];
    
    return htmlStr;
}

/**
 Create interaction basket html string
 */
- (NSString *) medBasketHtml
{
    // basket_html_str + delete_all_button_str + "<br><br>" + top_note_html_str
    int medCnt = 0;
    NSString *medBasketStr = @"";
    if ([MLUtilities isGermanApp])  // TODO: localize
        medBasketStr = [medBasketStr stringByAppendingString:@"<div id=\"Medikamentenkorb\"><fieldset><legend>Medikamentenkorb</legend></fieldset></div><table id=\"InterTable\" width=\"100%25\">"];
    else if ([MLUtilities isFrenchApp])
        medBasketStr = [medBasketStr stringByAppendingString:@"<div id=\"Medikamentenkorb\"><fieldset><legend>Panier des Médicaments</legend></fieldset></div><table id=\"InterTable\" width=\"100%25\">"];
    
    // Check if there are meds in the "Medikamentenkorb"
    if ([medCart size]>0) {
        // First sort them alphabetically
        NSArray *sortedNames = [[medCart.cart allKeys] sortedArrayUsingSelector: @selector(compare:)];
        // Loop through all meds
        for (NSString *name in sortedNames) {
            MLMedication *med = [medCart.cart valueForKey:name];
            NSArray *m_code = [[med atccode] componentsSeparatedByString:@";"];
            NSString *atc_code = @"k.A.";
            NSString *active_ingredient = @"k.A";
            if ([m_code count]>1) {
                atc_code = [m_code objectAtIndex:0];
                active_ingredient = [m_code objectAtIndex:1];
            }
            // Increment med counter
            medCnt++;
            // Update medication basket
            medBasketStr = [medBasketStr stringByAppendingFormat:@"<tr>"
                            @"<td>%d</td>"
                            @"<td>%@</td>"
                            @"<td>%@</td>"
                            @"<td>%@</td>"
                            @"<td align=\"right\"><input type=\"image\" src=\"217-trash.png\" onclick=\"deleteRow('InterTable',this)\" />"
                            @"</tr>", medCnt, name, atc_code, active_ingredient];
        }
        // Add delete all button
        // TODO: localize
        if ([MLUtilities isGermanApp])
            medBasketStr = [medBasketStr stringByAppendingString:@"</table><div id=\"Delete_all\"><input type=\"button\" value=\"Korb leeren\" onclick=\"deleteRow('Delete_all',this)\" /></div>"];
        else if ([MLUtilities isFrenchApp])
            medBasketStr = [medBasketStr stringByAppendingString:@"</table><div id=\"Delete_all\"><input type=\"button\" value=\"Tout supprimer\" onclick=\"deleteRow('Delete_all',this)\" /></div>"];
    }
    else {
        medBasketStr = [NSString stringWithFormat:@"<div>%@<br><br></div>",
                        NSLocalizedString(@"Your medicine basket is empty", "html")];
    }
    
    return medBasketStr;
}

/**
 Create html displaying interactions between drugs
 */
- (NSString *) interactionsHtml:(MLInteractionsAdapter *)interactions
{
    NSMutableString *interactionStr = [[NSMutableString alloc] initWithString:@""];
    NSMutableArray *sectionIds = [[NSMutableArray alloc] initWithObjects:@"Medikamentenkorb", nil];
    NSMutableArray *sectionTitles = nil;
    
    if ([medCart size]>0) {
        if ([MLUtilities isGermanApp])
            sectionTitles = [[NSMutableArray alloc] initWithObjects:@"Medikamentenkorb", nil];
        else if ([MLUtilities isFrenchApp])
            sectionTitles = [[NSMutableArray alloc] initWithObjects:@"Panier des médicaments", nil];
    }
    
    // Check if there are meds in the "Medikamentenkorb"
    NSString *html = [medCart interactionsAsHtmlForAdapter:interactions withTitles:sectionTitles andIds:sectionIds];
    [interactionStr appendString:html];
    
    if ([medCart size]>1) {
        if ([sectionTitles count]<2) {
            [interactionStr appendString:[self topNoteHtml]];
        } else if ([sectionTitles count]>2) {
            [interactionStr appendString:@"<br>"];
        }
    }
    
    if ([medCart size]>0) {
        [sectionIds addObject:@"Farblegende"];
        if ([MLUtilities isGermanApp])
            [sectionTitles addObject:@"Farblegende"];
        else if ([MLUtilities isFrenchApp])
            [sectionTitles addObject:@"Légende des couleurs"];
    }
    
    // Update section title anchors
    listofSectionIds = [NSArray arrayWithArray:sectionIds];
    // Update section titles (here: identical to anchors)
    listofSectionTitles = [NSArray arrayWithArray:sectionTitles];
    
    return interactionStr;
}

- (NSString *) topNoteHtml
{
    NSString *topNote = @"";
    
    if ([medCart size]>1) {
        // Add note to indicate that there are no interactions
        if ([MLUtilities isGermanApp]) {  // TODO: localize
            topNote = @"<fieldset><legend>Bekannte Interaktionen</legend></fieldset><p class=\"paragraph0\">Zur Zeit sind keine Interaktionen zwischen diesen Medikamenten in der EPha.ch-Datenbank vorhanden. Weitere Informationen finden Sie in der Fachinformation.</p><div id=\"Delete_all\"><input type=\"button\" value=\"Interaktion melden\" onclick=\"deleteRow('Notify_interaction',this)\" /></div><br>";
        } else if ([MLUtilities isFrenchApp]) {
            topNote = @"<fieldset><legend>Interactions Connues</legend></fieldset><p class=\"paragraph0\">Il n’y a aucune information dans la banque de données EPha.ch à propos d’une interaction entre les médicaments sélectionnés. Veuillez consulter les informations professionelles.</p><div id=\"Delete_all\"><input type=\"button\" value=\"Signaler une interaction\" onclick=\"deleteRow('Notify_interaction',this)\" /></div><br>";
        }
    }
    
    return topNote;
}

// TODO: localize
- (NSString *) footNoteHtml
{
    /*
     Risikoklassen
     -------------
     A: Keine Massnahmen notwendig (grün)
     B: Vorsichtsmassnahmen empfohlen (gelb)
     C: Regelmässige Überwachung (orange)
     D: Kombination vermeiden (pinky)
     X: Kontraindiziert (hellrot)
     0: Keine Angaben (grau)
     */
    if ([medCart size]>0) {
        if ([MLUtilities isGermanApp]) {
            NSString *legend = {
                @"<fieldset><legend>Fussnoten</legend></fieldset>"
                @"<p class=\"footnote\">1. Farblegende: </p>"
                @"<table id=\"Farblegende\" style=\"background-color:transparent;\" cellpadding=\"3px\" width=\"100%25\">"
                @"  <tr bgcolor=\"#caff70\"><td align=\"center\">A</td><td>Keine Massnahmen notwendig</td></tr>"
                @"  <tr bgcolor=\"#ffec8b\"><td align=\"center\">B</td><td>Vorsichtsmassnahmen empfohlen</td></tr>"
                @"  <tr bgcolor=\"#ffb90f\"><td align=\"center\">C</td><td>Regelmässige Überwachung</td></tr>"
                @"  <tr bgcolor=\"#ff82ab\"><td align=\"center\">D</td><td>Kombination vermeiden</td></tr>"
                @"  <tr bgcolor=\"#ff6a6a\"><td align=\"center\">X</td><td>Kontraindiziert</td></tr>"
                @"</table>"
                @"<p class=\"footnote\">2. Datenquelle: Public Domain Daten von EPha.ch.</p>"
                @"<p class=\"footnote\">3. Unterstützt durch:  IBSA Institut Biochimique SA.</p>"
            };
            return legend;
        }
        
        if ([MLUtilities isFrenchApp]) {
            NSString *legend = {
                @"<fieldset><legend>Notes</legend></fieldset>"
                @"<p class=\"footnote\">1. Légende des couleurs: </p>"
                @"<table id=\"Farblegende\" style=\"background-color:transparent;\" cellpadding=\"3px\" width=\"100%25\">"
                @"  <tr bgcolor=\"#caff70\"><td align=\"center\">A</td><td>Aucune mesure nécessaire</td></tr>"
                @"  <tr bgcolor=\"#ffec8b\"><td align=\"center\">B</td><td>Mesures de précaution sont recommandées</td></tr>"
                @"  <tr bgcolor=\"#ffb90f\"><td align=\"center\">C</td><td>Doit être régulièrement surveillée</td></tr>"
                @"  <tr bgcolor=\"#ff82ab\"><td align=\"center\">D</td><td>Eviter la combinaison</td></tr>"
                @"  <tr bgcolor=\"#ff6a6a\"><td align=\"center\">X</td><td>Contre-indiquée</td></tr>"
                @"</table>"
                @"<p class=\"footnote\">2. Source des données : données du domaine publique de EPha.ch.</p>"
                @"<p class=\"footnote\">3. Soutenu par : IBSA Institut Biochimique SA.</p>"
            };
            return legend;
        }
    }
    
    return @"";
}

- (void) sendInteractionNotice
{
    NSMutableString *bodyStr = [[NSMutableString alloc] initWithString:@""];
    
    // Starts mail client
    NSString *subject = [NSString stringWithFormat:@"%@ OS X: Unbekannte Interaktionen", APP_NAME];
    
    NSString* body = nil;
    if ([medCart size]>0) {
        NSArray *sortedNames = [[medCart.cart allKeys] sortedArrayUsingSelector: @selector(compare:)];
        for (NSString *name in sortedNames) {
            [bodyStr appendString:[NSString stringWithFormat:@"- %@\r\n", name]];
        }
        if ([[MLUtilities appLanguage] isEqualToString:@"de"])
            body = [NSString stringWithFormat:@"Sehr geehrter Herr Davatz\r\n\nMedikamentenkorb:\r\n\n%@\r\nBeste Grüsse\r\n\n", bodyStr];
        else if ([[MLUtilities appLanguage] isEqualToString:@"fr"])
            body = [NSString stringWithFormat:@"Sehr geehrter Herr Davatz\r\n\nPanier des médicaments:\r\n\n%@\r\nBeste Grüsse\r\n\n", bodyStr];
    }
    NSString *encodedSubject = [NSString stringWithFormat:@"subject=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedBody = [NSString stringWithFormat:@"body=%@", [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedURLString = [NSString stringWithFormat:@"mailto:?%@&%@", encodedSubject, encodedBody];
    
    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
    
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

@end
