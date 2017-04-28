/*
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 Created on 28/04/2017.
 All interaction cart related JS callbacks
 */

function deleteRow(tableID,currentRow) {
    // var myfunc = window.RemoveMeds;
    try {
        if (tableID=="Notify_interaction") {
            var payload = ["interactions_cb", "notify_interaction", ""];
            WebViewJavascriptBridge.send(payload);
        } else if (tableID=="Delete_all") {
            // window.alert("delete all rows");
            var payload = ["interactions_cb", "delete_all", ""];
            WebViewJavascriptBridge.send(payload);
		} else {
            var table = document.getElementById(tableID);
			var rowCount = table.rows.length;
            // window.alert("num rows = " + rowCount);
			for (var i=0; i<rowCount; i++) {
				var row = table.rows[i];
				if (row==currentRow.parentNode.parentNode) {
                    // window.alert("delete single row");
                    var payload = ["interactions_cb", "delete_row", row.cells[1].innerText];
                    WebViewJavascriptBridge.send(payload);
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
