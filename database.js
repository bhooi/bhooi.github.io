var Database = function(data) {
	this.data = data;
}

Database.prototype.query = function(columns, conditions) {
	// Set default aparameters.
	if (typeof columns === "object") {
		if (columns.length === 0 && this.data.length > 0) {
			columns = Object.getOwnPropertyNames(this.data[0]);
		}
	} else if (typeof columns !== "object") {
		if (typeof columns === "undefined" && this.data.length > 0) {
			columns = Object.getOwnPropertyNames(this.data[0]);
		} else {
			columns = [columns];
		}
	}
	if (typeof columns !== "object") {
		conditions = {};
	}
	
	// Go through each row in the data.
	var results = [];
	var numDataRows = this.data.length;
	for (var i = 0; i < numDataRows; i++) {
		// Get row.
		var dataRow = this.data[i];

		// Skip this row if we don't match all the conditions.
		var match = true;
		for (conditionCol in conditions) {
			if (conditions.hasOwnProperty(conditionCol)) {
				if (dataRow[conditionCol] !== conditions[conditionCol]) {
					match = false;
					break;
				}
			}
		}
		if (match == false) continue;
		
		// Add the columns to the results.
		var resultRow = {}
		var numQueryCols = columns.length;
		for (var j = 0; j < numQueryCols; j++) {
			resultRow[columns[j]] = dataRow[columns[j]];
		}
		results.push(resultRow);
	}
	return results;
}
/*
// Example data
sourceData = [
	{"country": "Singapore", "year": 2010, "group": "Chinese", "population": 204},
	{"country": "Singapore", "year": 2011, "group": "Chinese", "population": 205},
	{"country": "Singapore", "year": 2012, "group": "Chinese", "population": 206},
	{"country": "Singapore", "year": 2011, "group": "Malay", "population": 207},
	{"country": "Singapore", "year": 2010, "group": "Malay", "population": 208},
	{"country": "Singapore", "year": 2012, "group": "Malay", "population": 209},
	{"country": "Singapore", "year": 2010, "group": "Indian", "population": 210},
	{"country": "Singapore", "year": 2011, "group": "Indian", "population": 211},
	{"country": "Singapore", "year": 2012, "group": "Indian", "population": 212},
];

// Example usage
db = new Database(sourceData);

console.log("All rows:")
console.log(db.query());

console.log("Get a single column:")
console.log(db.query("population"));

console.log("Filter by columns:")
console.log(db.query(["group", "year", "population"]));

console.log("Population of Chinese:")
console.log(db.query(["population", "year"], {group: "Chinese"}));

console.log("Population breakdown in 2012:")
console.log(db.query(["population", "group"], {year: 2012}));

console.log("Complete row for Chinese in 2012:")
console.log(db.query([], {group: "Chinese", year: 2012}));

console.log("Complete row for Chinese in 2012:")
console.log(db.query([], {group: "Chinese", year: 2012}));


// [] is shorthand for all columns.
// Columns and conditions parameters are both optional.
*/