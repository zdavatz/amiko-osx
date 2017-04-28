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

#import "MLInteractionsCart.h"
#import "MLMedication.h"
#import "MLUtilities.h"

@implementation MLInteractionsCart
{
    NSMutableDictionary *medBasket;
}

@synthesize listofSectionIds;
@synthesize listofSectionTitles;

- (NSUInteger) basketSize
{
    return [medBasket count];
}

- (void) updateMedBasket:(NSMutableDictionary *)basket
{
    medBasket = basket;
}

/**
 Create interaction basket html string
 */
- (NSString *) medBasketHtml
{
    // basket_html_str + delete_all_button_str + "<br><br>" + top_note_html_str
    int medCnt = 0;
    NSString *medBasketStr = @"";
    if ([MLUtilities isGermanApp])
        medBasketStr = [medBasketStr stringByAppendingString:@"<div id=\"Medikamentenkorb\"><fieldset><legend>Medikamentenkorb</legend></fieldset></div><table id=\"InterTable\" width=\"100%25\">"];
    else if ([MLUtilities isFrenchApp])
        medBasketStr = [medBasketStr stringByAppendingString:@"<div id=\"Medikamentenkorb\"><fieldset><legend>Panier des Médicaments</legend></fieldset></div><table id=\"InterTable\" width=\"100%25\">"];
    
    // Check if there are meds in the "Medikamentenkorb"
    if ([medBasket count]>0) {
        // First sort them alphabetically
        NSArray *sortedNames = [[medBasket allKeys] sortedArrayUsingSelector: @selector(compare:)];
        // Loop through all meds
        for (NSString *name in sortedNames) {
            MLMedication *med = [medBasket valueForKey:name];
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
        if ([MLUtilities isGermanApp])
            medBasketStr = [medBasketStr stringByAppendingString:@"</table><div id=\"Delete_all\"><input type=\"button\" value=\"Korb leeren\" onclick=\"deleteRow('Delete_all',this)\" /></div>"];
        else if ([MLUtilities isFrenchApp])
            medBasketStr = [medBasketStr stringByAppendingString:@"</table><div id=\"Delete_all\"><input type=\"button\" value=\"Tout supprimer\" onclick=\"deleteRow('Delete_all',this)\" /></div>"];
    } else {
        // Medikamentenkorb is empty
        if ([MLUtilities isGermanApp])
            medBasketStr = @"<div>Ihr Medikamentenkorb ist leer.<br><br></div>";
        else if ([MLUtilities isFrenchApp])
            medBasketStr = @"<div>Votre panier des médicaments est vide.<br><br></div>";
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
    
    if ([medBasket count]>0) {
        if ([MLUtilities isGermanApp])
            sectionTitles = [[NSMutableArray alloc] initWithObjects:@"Medikamentenkorb", nil];
        else if ([MLUtilities isFrenchApp])
            sectionTitles = [[NSMutableArray alloc] initWithObjects:@"Panier des médicaments", nil];
    }
    
    // Check if there are meds in the "Medikamentenkorb"
    if ([medBasket count]>1) {
        // First sort them alphabetically
        NSArray *sortedNames = [[medBasket allKeys] sortedArrayUsingSelector: @selector(compare:)];
        // Big loop
        for (NSString *name1 in sortedNames) {
            for (NSString *name2 in sortedNames) {
                if (![name1 isEqualToString:name2]) {
                    // Extract meds by names from interaction basket
                    MLMedication *med1 = [medBasket valueForKey:name1];
                    MLMedication *med2 = [medBasket valueForKey:name2];
                    // Get ATC codes from interaction db
                    NSArray *m_code1 = [[med1 atccode] componentsSeparatedByString:@";"];
                    NSArray *m_code2 = [[med2 atccode] componentsSeparatedByString:@";"];
                    NSArray *atc1 = nil;
                    NSArray *atc2 = nil;
                    if ([m_code1 count]>1)
                        atc1 = [[m_code1 objectAtIndex:0] componentsSeparatedByString:@","];
                    if ([m_code2 count]>1)
                        atc2 = [[m_code2 objectAtIndex:0] componentsSeparatedByString:@","];
                    
                    NSString *atc_code1 = @"";
                    NSString *atc_code2 = @"";
                    if (atc1!=nil && [atc1 count]>0) {
                        for (atc_code1 in atc1) {
                            if (atc2!=nil && [atc2 count]>0) {
                                for (atc_code2 in atc2) {
                                    NSString *html = [interactions getInteractionHtmlBetween:atc_code1 and:atc_code2];
                                    if (html!=nil) {
                                        // Replace all occurrences of atc codes by med names apart from the FIRST one!
                                        NSRange range1 = [html rangeOfString:atc_code1 options:NSBackwardsSearch];
                                        html = [html stringByReplacingCharactersInRange:range1 withString:name1];
                                        NSRange range2 = [html rangeOfString:atc_code2 options:NSBackwardsSearch];
                                        html = [html stringByReplacingCharactersInRange:range2 withString:name2];
                                        // Concatenate strings
                                        [interactionStr appendString:html];
                                        // Add to title and anchor lists
                                        [sectionTitles addObject:[NSString stringWithFormat:@"%@ \u2192 %@", name1, name2]];
                                        [sectionIds addObject:[NSString stringWithFormat:@"%@-%@", atc_code1, atc_code2]];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if ([sectionTitles count]<2) {
            [interactionStr appendString:[self topNoteHtml]];
        } else if ([sectionTitles count]>2) {
            [interactionStr appendString:@"<br>"];
        }
    }
    
    if ([medBasket count]>0) {
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
    
    if ([medBasket count]>1) {
        // Add note to indicate that there are no interactions
        if ([MLUtilities isGermanApp]) {
            topNote = @"<fieldset><legend>Bekannte Interaktionen</legend></fieldset><p class=\"paragraph0\">Zur Zeit sind keine Interaktionen zwischen diesen Medikamenten in der EPha.ch-Datenbank vorhanden. Weitere Informationen finden Sie in der Fachinformation.</p><div id=\"Delete_all\"><input type=\"button\" value=\"Interaktion melden\" onclick=\"deleteRow('Notify_interaction',this)\" /></div><br>";
        } else if ([MLUtilities isFrenchApp]) {
            topNote = @"<fieldset><legend>Interactions Connues</legend></fieldset><p class=\"paragraph0\">Il n’y a aucune information dans la banque de données EPha.ch à propos d’une interaction entre les médicaments sélectionnés. Veuillez consulter les informations professionelles.</p><div id=\"Delete_all\"><input type=\"button\" value=\"Signaler une interaction\" onclick=\"deleteRow('Notify_interaction',this)\" /></div><br>";
        }
    }
    
    return topNote;
}

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
    if ([medBasket count]>0) {
        if ([MLUtilities isGermanApp]) {
            NSString *legend = {
                @"<fieldset><legend>Fussnoten</legend></fieldset>"
                @"<p class=\"footnote\">1. Farblegende: </p>"
                @"<table id=\"Farblegende\" style=\"background-color:#ffffff;\" cellpadding=\"3px\" width=\"100%25\">"
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
        } else if ([MLUtilities isFrenchApp]) {
            NSString *legend = {
                @"<fieldset><legend>Notes</legend></fieldset>"
                @"<p class=\"footnote\">1. Légende des couleurs: </p>"
                @"<table id=\"Farblegende\" style=\"background-color:#ffffff;\" cellpadding=\"3px\" width=\"100%25\">"
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

@end
