var Heatmap = function(elem, data, userOptions) {
	var defaultOptions = {
		"startYear": 1950,
		"endYear": 2009,
		"defaultCountry": "Afghanistan",
		"defaultYear": 2000,
		"x": 0,
		"y": 0,
		"width": 800,
		"height": 10,
		"buttonElem": "rect",
		"buttonClass": "heatmap_button",
		"labelWidth": 120,
		"labelHeight": 120,
		"groupHeight": 10,
		"groupClass": "heatmap_group",
		"groupElem": "g",
		"labelClass": "heatmap_label",
		"labelElem": "text",
		"pointClass": "heatmap_point",
		"pointElem": "rect",
		"pointWidth": 10,
		"pointHeight": 10,
		"axisElem": "g",
		"axisClass": "heatmap_axis",
		"axisHeight": 40,
		"axisY": 30,
		"yearKey": "year",
		"countryKey": "countryname",
		"groupKey": "groupname",
		"measure": "conflict",
		"cursorElem": "rect",
		"cursorClass": "heatmap_cursor",
		"paddingHeight": 20,
		"paddingWidth": 20,
		"resize": true,
		"flagKey": "incidence_flag",
		"textLength": 15,
		"tooltipX": 40,
		"tooltipY": -100,
	};
	this.options = mergeOptions(userOptions, defaultOptions);
	this.elem = elem;
	this.data = data;
	this.country = "";
	this.database = new Database(data);
	this.year = this.options.defaultYear;
	this.country = this.options.defaultCountry;
	this.selectedGroup = "";
	this.tooltipGroup = "";
	this.tooltip = new Tooltip();
	this.tooltipTimer = null;
	this.setupScale();
	this.drawAxis();
	this.setupCursor();
	this.update();
	this.messageHub = null;
	this.setupMouse();
}

Heatmap.prototype.setupScale = function() {
	this.xScale = d3.scale.linear()
		.domain([this.options.startYear, this.options.endYear])
		.range([this.options.x + this.options.labelWidth + this.options.paddingWidth / 2, this.options.x + this.options.labelWidth + this.options.paddingWidth / 2 + this.options.width]);
}

Heatmap.prototype.setupCursor = function() {
	this.cursorX = this.xScale(this.options.defaultYear)
}
Heatmap.prototype.drawCursor = function() {
	if (this.cursor) {
		this.cursor.remove();
	}
	this.cursor = this.elem
		.append("rect")
		.attr("x", this.cursorX)
		.attr("y", this.options.y + this.options.axisY)
		.attr("width", 1)
		.attr("height", 1000)
		.style('fill', '#eee')
}

Heatmap.prototype.setupMouse = function() {
	var that = this;
	this.mousedown = false;
	document.addEventListener("mousedown", function() { that.mousedown = true; }, false);
	document.addEventListener("mouseup", function() { that.mousedown = false; }, false);
	this.elem.on("mousemove", bindFn(this.cursorMouseOverHandler, this));
	this.elem.on("click", bindFn(this.cursorMouseOverHandler, this));
}

Heatmap.prototype.cursorMouseOverHandler = function(d, i) {
	var mouseX = d3.mouse(this.elem.node())[0];
	var leftX = this.options.x + this.options.labelWidth + this.options.paddingWidth / 2;
	var rightX = this.options.x + this.options.labelWidth + this.options.paddingWidth / 2 + this.options.width;
	if ((d3.event.type === "click" || this.mousedown) && mouseX >= this.xScale(this.options.startYear) && mouseX <= this.xScale(this.options.endYear)) {
		this.cursorX = mouseX;
		this.cursor
			.attr("x", mouseX);
		var year = d3.round(this.xScale.invert(mouseX))
		if (year !== this.year && this.messageHub) {
			this.year = year;
			messageHub.send("year", year);
		}
	}
}

Heatmap.prototype.setCountry = function(country) {
	this.country = country;
	this.update();
}


Heatmap.prototype.setGroup = function(group) {
	this.selectedGroup = group;
	this.update();
}

Heatmap.prototype.setMessageHub = function(messageHub) {
	this.messageHub = messageHub;
	messageHub.subscribe("country", bindFn(this.setCountry, this));
	messageHub.subscribe("group", bindFn(this.setGroup, this));
}

Heatmap.prototype.groupClickHandler = function(d, i) {
	if (this.messageHub) {
		if (d.members.length > 0) {
			this.messageHub.send("language", d.members[0].language);
		}
	} else {
		this.setGroup(d);
	}
}

Heatmap.prototype.compareGroups = function(a, b) {
	return b.members[b.members.length - 1].groupsize - a.members[a.members.length - 1].groupsize
}

Heatmap.prototype.update = function() {
	var that = this;

	var xScale = d3.scale.linear()
		.domain([this.options.startYear, this.options.endYear])
		.range([0, this.options.width]);

	conditions = {}
	conditions[this.options.countryKey] = this.country;
	var countriesRows = getFilterRange(this.database.query([], conditions), this.options.startYear, this.options.endYear, this.options.yearKey);
	var groupsRows = getGroupBy(countriesRows, this.options.groupKey, undefined, true).sort(this.compareGroups);
//	console.log(groupsRows)
	var groupSelection = this.elem
		.selectAll("." + this.options.groupClass)
		.data(groupsRows, function(d, i) { return that.country + "_" + d[that.options.groupKey] })

	groupSelection
		.enter()
		.append(this.options.groupElem)
		.attr("transform", function(d, i) { return transformTranslate(0, (that.options.groupHeight + that.options.paddingHeight) * i + that.options.axisHeight) })
		.classed(this.options.groupClass, true)
		.on("click", bindFn(this.groupClickHandler, this))
		.on("mouseover", bindFn(this.groupMouseOverHandler, this))
		.on("mouseout", bindFn(this.groupMouseOutHandler, this))

	groupSelection
		.exit()
		.remove()

	var buttonSelection = groupSelection
		.selectAll("." + this.options.buttonClass)
		.data(function(d, i) { return [d[that.options.groupKey]] }, function(d) { return that.country + "_" + d })

	buttonSelection
		.exit()
		.remove()

	buttonSelection
		.enter()
		.append(this.options.buttonElem)
		.classed(this.options.buttonClass, true)

	buttonSelection
		.attr("x", this.options.x)
		.attr("y", this.options.y)
		.attr("height", this.options.groupHeight + this.options.paddingHeight)
		.attr("width", this.options.labelWidth + this.options.width + this.options.paddingWidth)
		.classed("selected", function(d, i) { return that.selectedGroup === that.country + "_" + d })

	var labelSelection = groupSelection
		.selectAll("." + this.options.labelClass)
		.data(function(d, i) { return [d[that.options.groupKey]] }, function(d) { return that.country + "_" + d })

	labelSelection
		.enter()
		.append(this.options.labelElem)
		.classed(this.options.labelClass, true)
		.text(function(d, i) { return clipText(d, that.options.textLength) })
		.attr("x", this.options.x + this.options.paddingWidth / 2)
		.attr("y", this.options.y + this.options.pointHeight + this.options.paddingHeight / 2)
		.attr("height", this.options.labelHeight)
		.attr("width", this.options.labelWidth)

	var pointsSelection = groupSelection
		.selectAll("." + this.options.pointClass)
		.data(function(d, i) { return d.members }, function(d) { return that.country + "_" + d[that.options.groupKey] + "_" + d[that.options.yearKey] })

	pointsSelection
		.enter()
		.append(this.options.pointElem)
		.classed(this.options.pointClass, true)
		.text(function(d, i) { return d })
		.attr("x", function(d, i) { return that.options.x + that.options.labelWidth + that.options.paddingWidth / 2 + xScale(d[that.options.yearKey] - 0.5) })
		.attr("y", function(d, i) { return (that.options.y + that.options.paddingHeight / 2) + (d[that.options.flagKey] ? 0 : that.options.pointHeight / 2)})
		.attr("height", function(d, i) { return d[that.options.flagKey] ? that.options.pointHeight : 3})
		.attr("width", xScale(1) - xScale(0))
		.classed(this.options.pointClass + "_conflict", function(d, i) { return d[that.options.flagKey] })

	pointsSelection
		.exit()
		.remove()

	if (this.options.resize) {
		this.elem
			.attr("height", this.options.axisHeight + (this.options.groupHeight + this.options.paddingHeight) * groupsRows.length)
			.attr("width", this.options.labelWidth + this.options.width + this.options.paddingWidth)
	}

	this.drawCursor();
}

Heatmap.prototype.drawAxis = function() {
	var xAxis = d3.svg.axis()
		.scale(this.xScale)
		.orient("top")
		.tickFormat(d3.format("d"))
		
	this.elem
		.append(this.options.axisElem)
		.classed(this.options.axisClass, true)
		.attr("transform", transformTranslate(0, this.options.y + this.options.axisY))
	.call(xAxis)
}

Heatmap.prototype.groupMouseOverHandler = function(d, i) {
	if (this.tooltipTimer) {
		clearTimeout(this.tooltipTimer);
		this.tooltipTimer = null;
	}
	if (!this.mousedown && d.groupname != this.tooltipGroup && d.members.length > 0) {
		var row = d.members[0];
		this.tooltipGroup = row.groupname;
		this.tooltip.show(this.getGroupDetails(row), d3.event.x + this.options.tooltipX, d3.event.y + this.options.tooltipY)
	}
}

Heatmap.prototype.groupMouseOutHandler = function(d, i) {
	var that = this;
	if (this.tooltipTimer === null) {
		this.tooltipTimer = setTimeout(function() {
			that.tooltip.hide();
			that.tooltipGroup = "";		
		}, 100)	
	}
	
}

/* From Raven's code. */
Heatmap.prototype.getGroupDetails = function(d) {
  var output = '';
  output += '<p><b>' + d.groupname + ' [' + d3.format('.2%')(d.groupsize) + ']</b></p>';
  output += '<p>STATUS: ' + d.statusname.toProperCase() + '</p>';
  output += '<p>LANGUAGE(s): ' + d.language + '</p>';
  output += '<p>PEACE YEARS: ' + d.peaceyears + '</p>';
  output += '<p>SETTLEMENT PATTERN: ';
  patterns = [];
  if (d.isurban == 1) patterns.push('urban');
  if (d.ismigrant == 1) patterns.push('migrant');
  if (d.isdispersed == 1) patterns.push('dispersed');
  if (d.hassetarea == 1) patterns.push('set area');
  output += patterns.join(', ');
  output += '</p>'
  return output;
}

