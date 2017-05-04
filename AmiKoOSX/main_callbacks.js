/*
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 Created on 28/04/2017.
 All main JS callbacks
 */

/**
 */
function setupWebViewJavascriptBridge(callback) {
    if (window.WebViewJavascriptBridge) {
        return callback(WebViewJavascriptBridge);
    }
    if (window.WVJBCallbacks) {
        return window.WVJBCallbacks.push(callback);
    }
    window.WVJBCallbacks = [callback];
    var WVJBIframe = document.createElement('iframe');
    WVJBIframe.style.display = 'none';
    WVJBIframe.src = 'https://__bridge_loaded__';
    document.documentElement.appendChild(WVJBIframe);
    setTimeout(function() { document.documentElement.removeChild(WVJBIframe) }, 0);
}

/**
 */
function displayFachinfo(ean, anchor) {
    try {
        if (anchor == 'undefined')
            anchor = '';
        var payload = ["main_cb", "display_fachinfo", ean, anchor];
        setupWebViewJavascriptBridge(function(bridge) {
                                     bridge.callHandler('JSToObjC_', payload, function responseCallback(responseData) {
                                                        console.log("JS received response:", responseData);
                                                        // moveToHighlight(responseData);
                                                        })
                                     bridge.registerHandler('ObjCToJS_', function(data, responseCallback) {
                                                          //
                                                        })
                                     })
        
    } catch (e) {
        alert(e);
    }
}

/**
 * Identifies the anchor's id and scrolls to the first mark tag.
 * Javascript is brilliant :-)
 */
function moveToHighlight(anchor) {
    if (typeof anchor !== 'undefined') {
        try {
            var elem = document.getElementById(anchor);
            if (elem !== null) {
                var marks = elem.getElementsByClassName('mark')
                if (marks.length > 0) {
                    marks[0].scrollIntoView(true);
                }
            }
        } catch(e) {
            alert(e);
        }
    }
}
