function deleteRow(tableID,currentRow) {
    // var myfunc = window.RemoveMeds;
    try {
		if (tableID=="Delete_all") {
            // window.alert("delete all rows");
            WebViewJavascriptBridge.send("delete_all");
			// myfunc.removeMeds_("delete_all");
		} else {
			var table = document.getElementById(tableID);
			var rowCount = table.rows.length;		
			for (var i=0; i<rowCount; i++) {
				var row = table.rows[i];
				if (row==currentRow.parentNode.parentNode) {
                    // window.alert("delete single row");
                    WebViewJavascriptBridge.send(row.cells[1].innerText);
                    // Assumes rowCount < 999
					// myfunc.removeMeds_(row.cells[1].innerText);
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