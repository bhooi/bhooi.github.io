var CountryList = function(elem, data, userOptions) {
	var defaultOptions = {
		"labelElem": "text",
		"labelClass": "country_label",
		"labelWidth": 120,
		"labelHeight": 50,
		"groupContainerClass": "country_groups_container",
		"groupContainerElem": "g",
		"groupClass": "country_groups",
		"groupElem": "rect",
		"groupHeight": 20,
		"groupWidth": 320,
		"groupX": 100,
		"x": 0,
		"y": 0,
		"countryElem": "g",
		"countryClass": "country_container",
		"countryKey": "countryname",
		"groupKey": "groupname",
		"yearKey": "year",
		"startYear": 1950,
		"endYear": 2009,
		"sizeKey": "groupsize",
		"gapWidth": 8,
		"buttonElem": "rect",
		"buttonClass": "country_button",
		"buttonFill": "#fff",
		"paddingHeight": 10,
		"paddingWidth": 20,
		"resize": true,
		"textLength": 15,
		"tooltipX": 40,
		"tooltipY": -100,
	};
	this.options = mergeOptions(userOptions, defaultOptions);
	this.elem = elem;
	this.data = data;
	this.filter = ""
	this.database = new Database(data);
	this.year = 2000;
	this.selectedCountry = "";
	this.selectedGroup = "";
	this.update();
	this.messageHub = null;
	this.tooltipGroup = "";
	this.tooltip = new Tooltip();
}


CountryList.prototype.setMessageHub = function(messageHub) {
	this.messageHub = messageHub;
	this.messageHub.subscribe("country", bindFn(this.setCountry, this));
	this.messageHub.subscribe("filter", bindFn(this.setFilter, this));
	this.messageHub.subscribe("group", bindFn(this.setGroup, this));
}

CountryList.prototype.setFilter = function(filter) {
	this.filter = filter;
	this.update();
}

CountryList.prototype.setYear = function(year) {
	this.year = year;
	this.update();
}

CountryList.prototype.setCountry = function(country) {
	this.selectedCountry = country;
	this.update();
}

CountryList.prototype.setGroup = function(group) {
	this.selectedGroup = group;
	this.update();
}

CountryList.prototype.countryClickHandler = function(d, i) {

	if (this.messageHub) {
		this.messageHub.send("country", d[this.options.countryKey]);
		if (d.members.length > 0) {
			this.messageHub.send("countrycode", d.members[0].iso);
		}
	} else {
		this.setCountry(d);
	}
}


CountryList.prototype.groupClickHandler = function(d, i) {
	var groupKey = d[this.options.countryKey] + "_" + d[this.options.groupKey];
	if (this.messageHub) {
		this.messageHub.send("country", d[this.options.countryKey]);
		this.messageHub.send("countrycode", d.iso);
		this.messageHub.send("group", groupKey);
		this.messageHub.send("language", d.language);
	} else {
		this.setCountry(groupKey);	
	}
}

CountryList.prototype.update = function() {
	var that = this;

	var xScale = d3.scale.linear()
		.domain([0, 1])
		.range([0, this.options.groupWidth]);

	conditions = {}
	conditions[this.options.yearKey] = this.year;
	var allRows = getFilterRange(this.database.query([], conditions), this.options.startYear, this.options.endYear, this.options.yearKey);
	var countryNames = filterSubstring(getUnique(allRows, this.options.countryKey), this.filter).sort();
	var countryRows = getGroupBy(allRows, this.options.countryKey, countryNames, true);

	var countrySelection = this.elem
		.selectAll("." + this.options.countryClass)
		.data(countryRows, function(d, i) { return d[that.options.countryKey] })

	countrySelection
		.enter()
		.append(this.options.countryElem)

	countrySelection
		.exit()
		.remove()

	countrySelection
		.attr("transform", function(d, i) { return transformTranslate(0, (that.options.groupHeight + that.options.paddingHeight) * i) })
		.classed(this.options.countryClass, true)
		.on("click", bindFn(this.countryClickHandler, this));
	
	var buttonSelection = countrySelection
		.selectAll("." + this.options.buttonClass)
		.data(function(d, i) { return [d[that.options.countryKey]] }, function(d) { return d })

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
		.attr("height", that.options.groupHeight + that.options.paddingHeight)
		.attr("width", this.options.labelWidth + this.options.groupWidth + this.options.paddingWidth)
		.classed("selected", function(d, i) { return that.selectedCountry === d })

	var labelSelection = countrySelection
		.selectAll("." + this.options.labelClass)
		.data(function(d, i) { return [d[that.options.countryKey]] }, function(d) {  return d })

	labelSelection
		.exit()
		.remove()

	labelSelection
		.enter()
		.append(this.options.labelElem)
		.classed(this.options.labelClass, true)

	labelSelection
		.text(function(d, i) { return clipText(d, that.options.textLength) })
		.attr("x", this.options.x + this.options.paddingWidth / 2)
		.attr("y", this.options.y + this.options.groupHeight + this.options.paddingHeight / 2)
		.attr("height", this.options.labelHeight)
		.attr("width", this.options.labelWidth)
	
	var groupSelection = countrySelection
		.selectAll("." + this.options.groupClass)
		.data(function(d, i) { return  getCumulative(d.members.sort(compareGroups), that.options.sizeKey) }, function(d) { return d[that.options.countryKey] + "_" + d[that.options.groupKey] })

	groupSelection
		.exit()
		.remove()

	groupSelection
		.enter()
		.append(this.options.groupElem)
		.classed(this.options.groupClass, true)
		//.attr("x", this.options.x)

	groupSelection
		.attr("x", function(d, i) { return that.options.labelWidth + that.options.paddingWidth / 2 + xScale(d["c_prev_" + that.options.sizeKey]) + that.options.gapWidth / 2 })
		.attr("y", this.options.y + this.options.paddingHeight / 2)
		.attr("width", function(d, i) {
			var w = xScale(d["c_" + that.options.sizeKey] - d["c_prev_" + that.options.sizeKey]) - that.options.gapWidth / 2;
			return w > 1 ? w : 1;
		})
		.attr("height", this.options.groupHeight)
		.classed("selected", function(d, i) { return d[that.options.countryKey] + "_" + d[that.options.groupKey] == that.selectedGroup })
		.on("click", bindFn(this.groupClickHandler, this))
		.on("mouseover", bindFn(this.groupMouseOverHandler, this))
		.on("mouseout", bindFn(this.groupMouseOutHandler, this))

	if (this.options.resize) {
		this.elem
			.attr("width", this.options.x + this.options.labelWidth + this.options.groupWidth + this.options.paddingHeight)
		 	.attr("height", this.options.y + countryNames.length * (that.options.groupHeight + that.options.paddingHeight))
	}
}

CountryList.prototype.groupMouseOverHandler = function(d, i) {
	if (d.groupname != this.tooltipGroup) {
		this.tooltipGroup = d.groupname;
		this.tooltip.show(this.getGroupDetails(d), d3.event.x + this.options.tooltipX, d3.event.y + this.options.tooltipY)
	}
}

CountryList.prototype.groupMouseOutHandler = function(d, i) {
	this.tooltip.hide();
	this.tooltipGroup = "";	
}

/* From Raven's code. */
CountryList.prototype.getGroupDetails = function(d) {
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
