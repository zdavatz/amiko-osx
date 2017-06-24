/*
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 Created on 28/04/2017.
 All interaction cart related JS callbacks
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

function callback(payload) {
    
}

function deleteRow(tableID,currentRow) {
    // var myfunc = window.RemoveMeds;
    try {
        if (tableID=="Notify_interaction") {
            var payload = ["interactions_cb", "notify_interaction", ""];
            setupWebViewJavascriptBridge(function(bridge) {
                                         bridge.callHandler('JSToObjC_', payload, function responseCallback(responseData) {
                                                            console.log("JS received response:", responseData);
                                                            })
                                         })
        } else if (tableID=="Delete_all") {
            // window.alert("delete all rows");
            var payload = ["interactions_cb", "delete_all", ""];
            setupWebViewJavascriptBridge(function(bridge) {
                                         bridge.callHandler('JSToObjC_', payload, function responseCallback(responseData) {
                                                            console.log("JS received response:", responseData);
                                                            })
                                         })
		} else {
            var table = document.getElementById(tableID);
			var rowCount = table.rows.length;
            // window.alert("num rows = " + rowCount);
			for (var i=0; i<rowCount; i++) {
				var row = table.rows[i];
				if (row==currentRow.parentNode.parentNode) {
                    // window.alert("delete single row");
                    var payload = ["interactions_cb", "delete_row", row.cells[1].innerText];
                    setupWebViewJavascriptBridge(function(bridge) {
                                                 bridge.callHandler('JSToObjC_', payload, function responseCallback(responseData) {
                                                                    console.log("JS received response:", responseData);
                                                                    })
                                                 })
					// Delete row
					table.deleteRow(i);		
					// Update counters
					rowCount--;
				}
			}
        }
    } catch (e) {
        window.alert(e);
    }
}
