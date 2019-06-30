var getNullRow = function(row) {
	var nullRow = {};
	for (columnName in row) {
		if (row.hasOwnProperty(columnName)) {
			if (typeof row[columnName] === "string") {
				nullRow[columnName] = "";
			} else if (typeof row[columnName] === "number") {
				nullRow[columnName] = 0;
			} else if (typeof row[columnName] === "boolean") {
				nullRow[columnName] = false;
			}
		}
	}
	return nullRow;
}

var toDenseYearSeries = function(sparseYearSeries, userOptions) {
	// Set default parameters
	var defaultOptions = {
		"key": "year",
		"startYear": START_YEAR,
		"endYear": END_YEAR,
	}
	var options = mergeOptions(userOptions, defaultOptions);

	// Create map of years to rows
	var yearMap = {}
	var numSparseRows = sparseYearSeries.length;
	for (var i = 0; i < numSparseRows; i++) {
		var sparseRow = sparseYearSeries[i];
		yearMap[sparseRow[options.key]] = sparseRow;
	}

	// Create new dense year series
	var denseYearSeries = [];
	for (var i = options.startYear; i <= options.endYear; i++) {
		if (yearMap.hasOwnProperty(i)) {
			denseYearSeries.push(yearMap[i]);
		} else {
			var nullRow = getNullRow(sparseYearSeries[0]);
			nullRow[options.key] = i;
			denseYearSeries.push(nullRow);
		}
	}
	return denseYearSeries;
}

var heatmapBlockClass = ".heatmap_block";


var mergeOptions = function(userOptions, defaultOptions) {
	var options = {};
	for (propertyName in userOptions) {
		if (userOptions.hasOwnProperty(propertyName)) {
			options[propertyName] = userOptions[propertyName];
		}
	}
	for (propertyName in defaultOptions) {
		if (defaultOptions.hasOwnProperty(propertyName)) {
			if (!options.hasOwnProperty(propertyName)) {
				options[propertyName] = defaultOptions[propertyName];
			}
		}
	}
	return options;

}

var classToSelector = function(className) {
	return "." + className;
}

var filterSubstring = function(rows, substring) {
	var numRows = rows.length;
	var filteredRows = []
	for (var i = 0; i < numRows; i++) {
		var row = rows[i]
		if (row.toLowerCase().indexOf(substring.toLowerCase()) >= 0) {
			filteredRows.push(rows[i]);
		}
	}
	return filteredRows;
}

var clipText = function(text, maxLength) {
	return (text.length <= maxLength) ?
		text :
		text.substr(0, maxLength - 3) + "..."
}

var compareGroups = function(a, b) { return b.groupsize - a.groupsize }

var addMatrixIndices = function(matrix) {
	var numRows = matrix.length;
	for (var i = 0; i < numRows; i++) {
		var row = matrix[i];
		var numCols = row.length;
		for (var j = 0; j < numCols; j++) {
			var cell = row[j];
			cell.rowIndex = i;
			cell.colIndex = j;
		}
	}
	return matrix;
}

var bindFn = function(fn,that) {
	return function() {
		return fn.apply(that, arguments);
	}
}

var getGroupBy = function(rows, key, groupKeys, wrapper) {
	if (typeof(groupKeys) === "undefined") {
		var groupKeys = getUnique(rows, key).sort();
	}
	if (typeof(wrapper) === "undefined") {
		var wrapper = false;
	}
	var groups = [];
	var numGroups = groupKeys.length;
	for (var i = 0; i < numGroups; i++) {
		var groupKey = groupKeys[i];
		var group = [];
		var numRows = rows.length;
		for (var j = 0; j < numRows; j++) {
			var row = rows[j];
			if (row[key] === groupKey) {
				group.push(row);
			}
		}
		if (wrapper) {
			var wrappedGroup = {};
			wrappedGroup[key] = groupKey;
			wrappedGroup.members = group;
			groups.push(wrappedGroup);
		} else {
			groups.push(group);
		}
		
	}
	return groups;
}

var getUnique = function(rows, key) {
	if (typeof key === "undefined") {
		if (rows.length > 0 && Object.getOwnPropertyNames(rows[0]).length === 1) {
			key = Object.getOwnPropertyNames(rows[0])[0];
		} else {
			return [];
		}
	}
	var uniqueMap = {};
	var numRows = rows.length;
	for (var i = 0; i < numRows; i++) {
		var row = rows[i];
		uniqueMap[row[key]] = true;
	}
	return Object.getOwnPropertyNames(uniqueMap);
}


var transformTranslate = function(x, y) {
	return "translate(" + x + ", " + y + ")";
}

var getPluck = function(rows, key) {
	if (typeof key === "undefined") {
		if (rows.length > 0 && Object.getOwnPropertyNames(rows[0]).length === 1) {
			key = Object.getOwnPropertyNames(rows[0])[0];
		} else {
			return [];
		}
	}
	var values = [];
	var numRows = rows.length;
	for (var i = 0; i < numRows; i++) {
		values.push(rows[i][key])
	}
	return values
}

var getFilterRange = function(rows, min, max, key) {
	if (typeof key === "undefined") {
		if (rows.length > 0 && Object.getOwnPropertyNames(rows[0]).length === 1) {
			key = Object.getOwnPropertyNames(rows[0])[0];
		} else {
			return [];
		}
	}
	var filteredRows = []
	var numRows = rows.length;
	for (var i = 0; i < numRows; i++) {
		var row = rows[i];
		if (row[key] >= min && row[key] <= max) {
			filteredRows.push(row)
		}
	}
	return filteredRows;
}

var getCumulative = function(rows, key) {
	var numRows = rows.length;
	var z = 0;
	for (var i = 0; i < numRows; i++) {
		var row = rows[i];
		z += row[key];
	}
	var c = 0;
	for (var i = 0; i < numRows; i++) {
		var row = rows[i];
		row["c_prev_" + key] = c / z;
		c += row[key]
		row["c_" + key] = c / z;
	}
	return rows;
}
