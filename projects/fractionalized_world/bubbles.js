var Bubbles = function (elem, countries, messageHub) {
var SVG_WIDTH = 480;
var SVG_HEIGHT = 480;
var SVG_X = 1020;
var SVG_Y = 230;

var svg = elem
	.style("top", SVG_Y+"px")
	.style("left", SVG_X+"px")
	.attr("width", SVG_WIDTH)
	.attr("height", SVG_HEIGHT);

var MAX_GROUP_RADIUS = SVG_WIDTH * 0.09; // max and min sizes of the sub-bubbles in each country
var MIN_GROUP_RADIUS = SVG_WIDTH * 0.016;

var TITLE_HEIGHT = 25;
var OUTER_PADDING = 15;
var BUBBLE_RADIUS = (SVG_WIDTH - TITLE_HEIGHT - OUTER_PADDING)/2; // country bubble radius/x/y
var BUBBLE_X = SVG_WIDTH / 2;
var BUBBLE_Y = TITLE_HEIGHT + BUBBLE_RADIUS + OUTER_PADDING / 2;
var GROUPTEXT_WIDTH = 50; // label of language groups
var EDGE_STROKE_WIDTH = 5;

var BUBBLE_FONT_MAX = 24;
var BUBBLE_FONT_MIN = 12; 
var BUBBLE_FONT_SCALE = 1.4; // determines what fraction of the bubble will be filled with text

var BUBBLE_FILL_COLOR = '#58b';
var BUBBLE_HIGHLIGHT_COLOR = '#69c';
var BUBBLE_STROKE_COLOR = '#269';
var COUNTRY_BORDER_COLOR = '#888';
var EDGE_COLOR = '#888';
var BRUSH_LINK_FILL = '#fff568';
var BRUSH_LINK_STROKE = '#cbc031';


var MAX_GROUPS = 8; // filter out the smaller groups if there are too many


var countries; // data from in_country_distances.txt, about the subgroup structure in each country
var selectedCountryIndex = -1; 
var selectedGroupIndex = -1; 
var mdsCoords = null;
var countryData = null; // currently selected country data + 'highlighted' attribute

var highlightedGroup = "";

function assert(test, message) {
	if (!test) throw new Error(message);
}

function getRandomInt (min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function filterArray(arr, filter) {
	// uses filter (a boolean array of the same length as arr) to filter arr.

	if(arr.length != filter.length) 
		assert(false, "not same length");
	var res = [];
	for (var i = 0; i < arr.length; i++) {
		if (filter[i]) res.push(arr[i]);
	}
	return res;
}

function getArrayRanks(arr) {
	// returns a vector whose ith element is the rank of arr[i] in the array arr: i.e. returns the permutation whose elements are in the same order as arr. Breaks ties arbitrarily.
	var zip = [];
	for (var i = 0; i < arr.length; i++) {
		zip.push([i, arr[i]]);
	}
	zip.sort(function(a, b){ return a[1] - b[1]; });
	var perm = zip.map(function(pair){ return pair[0]; });
	var res = [];
	for (var i = 0; i < perm.length; i++) {
		res[perm[i]] = i;
	}
	return res;
}

function getDisplaySizeAndText(d, elem) {
	var txtSize = getTextLength(d.name, BUBBLE_FONT_MIN);
	var res = {};
	if (txtSize < d.r * BUBBLE_FONT_SCALE) {
		var base = BUBBLE_FONT_MIN * Math.sqrt(d.r * BUBBLE_FONT_SCALE / txtSize);
		res.text = d.name;
		res.size = Math.min(base, BUBBLE_FONT_MAX);
	} else {
		res.size = BUBBLE_FONT_MIN;
		res.text = trimTextToFit(d.name, BUBBLE_FONT_MIN, d.r * BUBBLE_FONT_SCALE);
	}
	return res;
}

function getTextLength(str, fontSize) {
	return 0.5 * (str.length * fontSize);
	// Removed because that was taking 28% of CPU time by forcing DOM rerenders.
	// var measurer = $("#measurer");
	// measurer.css("font-size", fontSize);
	// measurer.html(str);
	// console.log(measurer[0].offsetWidth / fontSize *);
	// return measurer[0].offsetWidth;
}


function trimTextToFit(str, fontSize, len) {
	var maxChars = 2 * len / fontSize
	if (str.length <= maxChars) {
		return str
	} else {
		return str.substr(0, maxChars - 2) + "\u2026";
	}
	// Removed because that was taking 28% of CPU time by forcing DOM rerenders.
	// if (getTextLength(str, fontSize) < len) return str;
	// for (var i = str.length - 1; i >= 0; i--) {
	// 	var trimmed = str.substring(0, i) + "...";
	// 	if (getTextLength(trimmed) < len) return trimmed;
	// }
	// return "...";
}

function createPicker() {

	var picker = d3.select("#picker");
	var options = picker.selectAll("option")
		.data(countries);

	options.enter()
		.append("option")
		.text(function(d){ return d.name; })
		.attr("value", function(d, i){ return i; });

	var optionElem = $("#picker")[0];
	optionElem.onchange = function(){
		selectedCountryIndex = this.value;
		renderSelectedCountry();
	}
}

function getSubBubbleRadii(sizes) {
	// input: array containing the sizes of the subgroups (e.g. population size of ethnic group)
	// output: array containing the screen radii we should use to plot the circles 

	var sqrtSizes = numeric.sqrt(sizes);
	var sizesToScreen = d3.scale.linear()
		.domain([0, d3.sum(sqrtSizes)])
		.range([MIN_GROUP_RADIUS, MAX_GROUP_RADIUS]);
	return sqrtSizes.map(sizesToScreen);
}

function centerRow (row) {
	// subtracts the mean from an array to make it mean 0
	return numeric.sub(row, d3.mean(row));
}

function centerRows (mat) {
	// centers rows of matrix
	return mat.map(centerRow);
}

function doubleCenter(mat) {
	// 'double centers' a matrix: centers rows, then columns, then divide by -2. 
	// This transforms a matrix containing squared distances into X * X', where 
	// the rows of X are the points that our distances are based on. (X' means 
	// X transpose)

	var rowCentered = centerRows(mat);
	var colCentered = numeric.transpose(centerRows(numeric.transpose(rowCentered)));
	return numeric.mul(colCentered, -0.5);
}


function filterGroups(groups, distanceMatrix) {
	// filters out the smaller groups if there are too many groups, and returns a 
	// boolean array of the same length describing which indices to keep. Currently
	// uses a hard cutoff, but might be interesting to try other methods that e.g. 
	// allow a country to have many groups if they are all above a size cutoff
	var n = groups.length;
	if (n <= MAX_GROUPS) {
		return {groups:groups, dist: distanceMatrix};
	} 
	var groupSizes = groups.map(function(group){ return group.size; });
	groupSizes.sort(function(a, b){ return b - a; }); // sort descending

	var cutoff = groupSizes[MAX_GROUPS - 1];
	var filter = groups.map(function(group){ return group.size >= cutoff; });
	var filteredGroups = filterArray(groups, filter);
	var distTemp = filterArray(distanceMatrix, filter);
	var filteredDist = distTemp.map(function(row){ return filterArray(row, filter); });
	return {groups: filteredGroups, dist: filteredDist};
}


function getDistance(P, Q) {
	// distance between two points
	return Math.sqrt((P.x - Q.x) * (P.x - Q.x) + (P.y - Q.y) * (P.y - Q.y));
}

function repelIntersectingCircles(coords, radii) {
	// coords is of the form {x: array of x, y: array of y}
	// modifies the coords array such that none of the circles with the given radii centered at the coords intersect
	var n = coords.length;
	var MAX_ITER = 100;
	for (var iter = 0; iter < MAX_ITER; iter++) {
		var foundIntersectingCircles = false;
		for (var i = 0; i < n; i++) {
			for (var j = i+1; j < n; j++) {
				var distance = getDistance(coords[i], coords[j]);
				var overlap = radii[i] + radii[j] - distance;
				if (overlap > 0) {
					foundIntersectingCircles = true;
					var deltaX = coords[j].x - coords[i].x;
					var deltaY = coords[j].y - coords[i].y;
					var ratio = radii[i] / radii[j];
					var iMove = 1.0 / (1.0 + ratio);
					var jMove = ratio / (1.0 + ratio);
					coords[i].x -= (deltaX / distance) * overlap * iMove;
					coords[i].y -= (deltaY / distance) * overlap * iMove;
					coords[j].x += (deltaX / distance) * overlap * jMove;
					coords[j].y += (deltaY / distance) * overlap * jMove;
				}
			}
		}
		if (!foundIntersectingCircles) break;
	}
}

function polarToCartesian(r, theta) {
	var sinTh = Math.sin(theta);
	var cosTh = Math.cos(theta); 
	return {x: r * cosTh, y: r * sinTh};
}


function getGroupIndexInCountry(groupCode, countryIndex) {
	// code is a language code, e.g. "eng". Finds the index of this group in this country.
	var country = countries[countryIndex];
	for (var i = 0; i < country.groups.length; i++) {
		if (country.groups[i].code == groupCode) return i;
	}
	return -1;
}

function computeClickedCoordinates(subBubbleRadii, distances, clicked) {
	// computes coordinates for each subgroup in Euclidean space (not screen coordinates) given that the group at index 'clicked' was clicked on. 
	// returns an object with keys x and y, with values arrays of coordinates.
	// the resulting points should be arranged such that their radii are according to the distance matrix, and their angles are equally spaced along a semicircle. The points should be in order of their first MDS coordinate.

	var n = subBubbleRadii.length;
	var distanceRow = distances[clicked];

	assert(mdsCoords != null);

	repelIntersectingCircles(mdsCoords, subBubbleRadii);
	var squaredDist = mdsCoords.map(function(point){ return point.x * point.x + point.y * point.y; });
	var maxRadiiMDS = d3.max(numeric.add(numeric.sqrt(squaredDist), subBubbleRadii)); 
	var remainingDistance = numeric.sub(maxRadiiMDS, subBubbleRadii);
	var scaleDifference = d3.min(numeric.div(remainingDistance, distanceRow));
	var distanceRow = numeric.mul(distanceRow, scaleDifference);

	var mdsX = mdsCoords.map(function(point){ return point.x;});
	var mdsRanks = getArrayRanks(mdsX);
	var angleMap = d3.scale.linear()
		.domain([0, (n - 1)])
		.range([-Math.PI, 0]);
	var angles = mdsRanks.map(angleMap);
	var res = [];
	for (var i = 0; i < n; i++) {
		polar = polarToCartesian(distanceRow[i], angles[i]);
		res.push(polar);
	}
	return res;
}

function getClickedStateScreenCoordinates(countryCenterX, countryCenterY, countryRadius, sizes, distances) {
	// lays out the subgroup bubbles on screen.
	
	var subBubbleRadii = getSubBubbleRadii(sizes);
	var n = sizes.length;	    		
	var coords = computeClickedCoordinates(subBubbleRadii, distances, selectedGroupIndex);
	repelIntersectingCircles(coords, subBubbleRadii);
	var screenCoords = coordsToScreen(coords, subBubbleRadii, countryCenterX, countryCenterY, countryRadius);
	return screenCoords;

}


function getMDSCoordinates(subBubbleRadii, distances) { 
	// does the math part of the MDS (returns points laid out in Euclidean space,
	// not in terms of screen coordinates)

	var sqdistMatrix = numeric.mul(distances, distances);
	var centered = doubleCenter(sqdistMatrix);
	var svd = numeric.svd(centered);
	var sqrtDiag = numeric.diag(numeric.sqrt(svd.S))
	var allPoints = numeric.dot(svd.V, sqrtDiag);
	mdsCoords = allPoints.map(function(row){ return {x: row[0], y: row[1]}; });
	return mdsCoords;
}

function coordsToScreen(coords, subBubbleRadii, cx, cy, r) {
	// takes coords (which is of the form {x: array of x, y : array of y}) and plots them on screen within a circle centered at (cx, cy) with radius r.
	var n = coords.length;
	var squaredDist = coords.map(function(point){ return point.x * point.x + point.y * point.y; });
	var maxRadius = d3.max(numeric.add(numeric.sqrt(squaredDist), subBubbleRadii)); // max distance of an MDS point from the origin
	var padding = r / 10;
	var scaleFactor = (r - padding) / maxRadius;

	var result = [];
	for (var i = 0; i < n; i++) {
		var screenX = cx + scaleFactor * coords[i].x;
		var screenY = cy + scaleFactor * coords[i].y;
		var screenRadius = scaleFactor * subBubbleRadii[i];
		result.push({x: screenX, y: screenY, r: screenRadius});
	}
	return result;

}

function getMDSScreenCoordinates(countryCenterX, countryCenterY, countryRadius, sizes, distances) {
	// computes where to place each (ethnic/religious group) sub-bubble and its radius,
	// given the radius of the enclosing country bubble

	var subBubbleRadii = getSubBubbleRadii(sizes);
	var n = sizes.length;
	if (n == 0) return [];
	if (n == 1) return [{x: countryCenterX, y: countryCenterY, r: countryRadius / 2}];

	var mdsCoords = getMDSCoordinates(subBubbleRadii, distances);
	repelIntersectingCircles(mdsCoords, subBubbleRadii);
	return coordsToScreen(mdsCoords, subBubbleRadii, countryCenterX, countryCenterY, countryRadius);

}

function processCountryDistanceData (data){
	var lines = data.toString().split('\n');
	var countries = [];
	for (var i = 0; i < lines.length; i++) {
		var trimmed = $.trim(lines[i]);
		if (trimmed.length == 0) continue;
		var toks = trimmed.split('\t')
		var numGroups = parseInt(toks[2], 10);
		var groups = [];
		for (var j = 0; j < numGroups; j++) {
			i++;
			var subtoks = $.trim(lines[i]).split('\t');
			var groupDict = {code: subtoks[0], name: subtoks[1], size:parseInt(subtoks[2], 10)};
			groups.push(groupDict);
		}
		var distanceMatrix = numeric.rep([numGroups, numGroups], 0);
		for (var j = 1; j < numGroups; j++) {
			i++;
			var subtoks = $.trim(lines[i]).split('\t');
			for (var k = 0; k < subtoks.length; k++) {
				distanceMatrix[j][k] = distanceMatrix[k][j] = parseFloat(subtoks[k]);
			}
		}
		var filtered = filterGroups(groups, distanceMatrix);
		var countryDict = {code: toks[0], name: toks[1], groups: filtered.groups, dist: filtered.dist};

		countries.push(countryDict);
	}
	return countries;
}


// moves the clicked bubble to the center. previousSelected is the last selected bubble.
function moveToCenter(previousSelected) {

	var selectedCountry = countries[selectedCountryIndex];
	var groupSizes = selectedCountry.groups.map(function(group){ return group.size; });

	var coords = getClickedStateScreenCoordinates(BUBBLE_X, BUBBLE_Y, BUBBLE_RADIUS, groupSizes, selectedCountry.dist);
	var groupData = []; 
	for (var i = 0; i < selectedCountry.groups.length; i++) {
		groupData.push($.extend({}, selectedCountry.groups[i], coords[i]));
	}
	var countryGroup = d3.selectAll(".countrygroup");
	var bubbles = countryGroup.selectAll("circle.subbubble")
		.data(groupData);
	bubbles.transition().duration(1000)
		.attr("cx", function(d){ return d.x; })
		.attr("cy", function(d){ return d.y; })
		.attr("r", function(d){ return d.r; });
	
	var groupNames = countryGroup.selectAll("text.groupname")
		.data(groupData);

	groupNames.transition().duration(1000)
		.attr("x", function(d){ return d.x; })
		.attr("y", function(d){ return d.y; });

	assert(mdsCoords != null);
	var mdsScreenCoords = getMDSScreenCoordinates(BUBBLE_X, BUBBLE_Y, BUBBLE_RADIUS, groupSizes, selectedCountry.dist);

	// if we were previously in the MDS view: make lines join clicked bubble to other bubbles
	var groupLines = countryGroup.selectAll("line.groupline")
		.data(groupData);
	if (previousSelected == -1) {
		groupLines.attr("x1", mdsScreenCoords[selectedGroupIndex].x)
			.attr("y1", mdsScreenCoords[selectedGroupIndex].y)
			.attr("x2", function(d, i){ return mdsScreenCoords[i].x; })
			.attr("y2", function(d, i){ return mdsScreenCoords[i].y; })
			.attr("stroke-opacity", 0);
	}

	// animation: move lines to destination positions of each bubble
	groupLines.transition().duration(1000)
		.attr("x1", coords[selectedGroupIndex].x)
		.attr("y1", coords[selectedGroupIndex].y)
		.attr("x2", function(d){ return d.x; })
		.attr("y2", function(d){ return d.y; })
		.attr("stroke-opacity", 0.7);
	
}

function handleBubbleClick(d) {
	// d is the data (in the d3 sense) for this element
	d3.select(this).attr("opacity", 0.7);
	var clicked = getGroupIndexInCountry(d.code, selectedCountryIndex);
	if (clicked == selectedGroupIndex) {
		// if already selected, deselect it
		selectedGroupIndex = -1;
		deselectBubble();
	} else {
		// otherwise, select it
		var previousSelected = selectedGroupIndex;
		selectedGroupIndex = clicked;
		if (countries[selectedCountryIndex].groups.length > 1) {
			moveToCenter(previousSelected);
		}
	}
}

function deselectBubble() {
	var groupData = getCurrentCountryMDS();
	var countryGroup = svg.select("g.countrygroup");
	countryGroup.selectAll("circle.subbubble")
		.data(groupData)
		.transition().duration(1000)
		.attr("cx", function(d){ return d.x; })
		.attr("cx", function(d){ return d.x; })
		.attr("cy", function(d){ return d.y; });

	countryGroup.selectAll("text.groupname")
		.data(groupData)
		.transition().duration(1000)
		.attr("x", function(d){ return d.x; })
		.attr("y", function(d){ return d.y; });

	countryGroup.selectAll("line.groupline")
		.transition().duration(300)
		.attr("stroke-opacity", 0);
}

function getCurrentCountryMDS() {
	var selectedCountry = countries[selectedCountryIndex];
	var groupSizes = selectedCountry.groups.map(function(group){ return group.size; });
	var mds = getMDSScreenCoordinates(BUBBLE_X, BUBBLE_Y, BUBBLE_RADIUS, groupSizes, selectedCountry.dist);
	var groupData = []; // combines the group info (e.g. name, size) with the display info (x, y, r)
	for (var i = 0; i < selectedCountry.groups.length; i++) {
		groupData.push($.extend({}, selectedCountry.groups[i], mds[i]));
	}
	return groupData;
}

function renderSelectedCountry() {
	selectedGroupIndex = -1;
	countryData = countries[selectedCountryIndex];
	var groupData = getCurrentCountryMDS();

	$("g.countrygroup").remove();

	var countryGroup = svg.append("svg:g").attr("class", "countrygroup");

	countryGroup
		.append("svg:circle")
		.attr("cx", BUBBLE_X)
		.attr("cy", BUBBLE_Y)
		.attr("r", BUBBLE_RADIUS)
		.attr("class", "countrybubble")
		.attr("fill", "none")
		.attr("stroke", COUNTRY_BORDER_COLOR)
		.attr("stroke-width", 2.0);

	/* countryGroup
		.append("svg:text")
		.attr("x", BUBBLE_X)
		.attr("y", TITLE_HEIGHT)
		.attr("width", BUBBLE_RADIUS)
		.attr("height", TITLE_HEIGHT)
		.text("Languages in "+ countryData.name)
		.attr("text-anchor", "middle")
		.attr("font-family", "Verdana, Arial")
		.attr("font-size", 18)
		.attr("font-weight", "bold")
		.attr("fill", "white"); */

	// create line segments, don't show them yet
	var segments = countryGroup.selectAll("line.groupline")
		.data(groupData); 

	segments.enter()
		.append("line").attr("class", "groupline")
		.attr("stroke-width", EDGE_STROKE_WIDTH)
		.attr("stroke", EDGE_COLOR)
		.attr("stroke-opacity", 0)
		.attr("cursor", "pointer")
		.on("mouseover", function(d, i){ 
			edgeHover(d, i);
		 })
		.on("mouseout", function(){
			edgeUnhover();
		});

	var bubbles = countryGroup.selectAll("circle.subbubble")
		.data(groupData);
	bubbles.enter().append("circle")
		.attr("class", "subbubble")
		.attr("cx", function(d){ return d.x; })
		.attr("cy", function(d){ return d.y; })
		.attr("r", function(d){ return d.r; })
		.attr("stroke", BUBBLE_STROKE_COLOR)
		.attr("cursor", "pointer")
		.attr("stroke-width", 2)
		.attr("fill", function(d) {
			if (d.name == highlightedGroup) return BRUSH_LINK_FILL;
			else return BUBBLE_FILL_COLOR;
		})
		.attr("stroke", function(d) {
			if (d.name == highlightedGroup) return BRUSH_LINK_STROKE;
			else return BUBBLE_STROKE_COLOR;
		})
		.attr("opacity", 0.7)
		.on("click", handleBubbleClick)
		.on("mouseover", function(d,i){
			d3.select(this).attr("opacity", 1.0);
			bubbleHover(d, i);
		})
		.on("mouseout", function(){
			d3.select(this).attr("opacity", 0.7);
			bubbleUnhover();
		});

	var textData = [];
	for (var i = 0; i < groupData.length; i++) {
		textData.push($.extend({}, groupData[i], {elemtype: "text"}));
	}
	var groupNames = countryGroup.selectAll("text.groupname")
		.data(textData);

	groupNames
		.enter()
		.append("text")
		.attr("class", "groupname")
		.attr("x", function(d){ return d.x; })
		.attr("y", function(d){ return d.y; })
		.attr("width", GROUPTEXT_WIDTH)
		.text(function(d){ return getDisplaySizeAndText(d, this).text; })
		.attr("text-anchor", "middle").attr("font-size", 
			function(d){ return getDisplaySizeAndText(d, this).size; })
		.attr("font-family", "Verdana, Arial")
		.attr("baseline-shift", "-33%")
		.attr("style", "pointer-events:none;");
	
	countryGroup.selectAll(".subbubble, .groupname")
		.sort(function interleaveCmp(a, b) {
			if (a.name != b.name) return a.name < b.name ? -1 : a.name > b.name ? 1 : 0;
			if (a.elemtype == "text" && b.elemtype != "text") return 1;
			if (a.elemtype != "text" && b.elemtype == "text") return -1;
			return 0;
		});
}

function edgeHover(d, i) {
	// when user mouseovers bubble: popup info panel
	if (selectedGroupIndex != -1) {
		var niceNumber = d3.format(',f');
		$("#nodeLabel")
			.show()
			.html('Language Distance: ' + countryData.dist[selectedGroupIndex][i])
			.offset({left:(SVG_X + d.x),top:(SVG_Y + d.y + d.r/2)});
	}
}

function edgeUnhover() {
	if (selectedGroupIndex != -1) {
		$("#nodeLabel").hide();
	}
}

function bubbleHover(d, i) {
	// when user mouseovers bubble: popup info panel
	var niceNumber = d3.format(',f');
	$("#nodeLabel")
		.show()
		.html('<b>' + d.name + '</b><br><br>' + 'POPULATION: ' + niceNumber(d.size))
		.offset({left:(SVG_X + d.x),top:(SVG_Y + d.y + d.r/2)});
}

function bubbleUnhover() {
	$("#nodeLabel").hide();
}

function highlightGroup(languageName) {
	highlightedGroup = languageName;
	var bubbles = svg.selectAll("circle.subbubble");
	bubbles.attr("fill", function(d) {
	if (d.name == highlightedGroup) return BRUSH_LINK_FILL;
		else return BUBBLE_FILL_COLOR;
	})
	.attr("stroke", function(d) {
		if (d.name == highlightedGroup) return BRUSH_LINK_STROKE;
		else return BUBBLE_STROKE_COLOR;
	})
}

function getCountryIndex(code) {
	var numCountries = countries.length;
	for (var i = 0; i < numCountries; i++) {
		if (countries[i].code == code) {
			return i;
		}
	}
	return -1;
}

function drawEmptyCountry() {
	$("g.countrygroup").remove();
	var countryGroup = svg.append("svg:g").attr("class", "countrygroup");
	countryGroup
		.append("svg:circle")
		.attr("cx", BUBBLE_X)
		.attr("cy", BUBBLE_Y)
		.attr("r", BUBBLE_RADIUS)
		.attr("class", "countrybubble")
		.attr("fill", "none")
		.attr("stroke", COUNTRY_BORDER_COLOR)
		.attr("stroke-width", 2.0);
	countryGroup.append("svg:text")
		.attr("x", BUBBLE_X)
		.attr("y", BUBBLE_Y)
		.attr("height", 30)
		.attr("width", 200)
		.text("No language data available")
		.attr("fill", "white")
		.attr("text-anchor", "middle");

}

function countryListener(code) {
	var index = getCountryIndex(code);
	if (index == selectedCountryIndex) return;
	if (index == -1) {
		drawEmptyCountry();
	}
	if (index >= 0) {
		selectedCountryIndex = index;
		renderSelectedCountry();
	}
}



// countries.sort(function(a, b){ return a.name > b.name; });

// createPicker();
// selectedCountryIndex = getRandomInt(0, countries.length - 1);
// var selectedCountry = countries[selectedCountryIndex];

messageHub.subscribe("countrycode", countryListener);
messageHub.subscribe("language", highlightGroup);

var selectedCountryIndex = 0;
renderSelectedCountry();

}