function deleteRow(tableID,currentRow) {
    try {
		if (tableID=="Delete_all") {
			invokeJava("Delete all",0);
		} else {
			var table = document.getElementById(tableID);
			var rowCount = table.rows.length;		
			for (var i=0; i<rowCount; i++) {
				var row = table.rows[i];
				if (row==currentRow.parentNode.parentNode) {
					/*
					if (rowCount <= 1) {
						alert("Cannot delete all the rows.");
						break;
					}
					*/
					invokeJava(row.cells[1].innerText,rowCount);
					// Delete row				
					table.deleteRow(i);		
					// Update counters
					rowCount--;
					i--;
				}
			}
        }
    } catch (e) {
        // alert(e);
    }
}