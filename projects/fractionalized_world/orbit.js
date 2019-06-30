var Orbit = function(data, messageHub) {

if (!messageHub)
  var messageHub = new MessageHub;

var w = 480,
    h = 480,
    c_radius = 60;

var orbit_x = w/2,
    orbit_y = h/2,
    orbit_r = 220;

var rows,
    countries,
    curData,
    groupPos,
    curCircle;

var startYear,
    endYear;

var statusnames = [

  "MONOPOLY",
  "DOMINANT",
  "SENIOR PARTNER",
  "JUNIOR PARTNER",
  "REGIONAL AUTONOMY",
  "SEPARATIST AUTONOMY",
  "POWERLESS",
  "IRRELEVANT",
  "DISCRIMINATED",
  "STATE COLLAPSE",
  ""
];

var selectedGroup = ""; 

var statusR = [0.0, 0.0, 0.1, 0.3, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.0]

var circleSize = d3.scale.pow()
  .exponent(0.5)
  .domain([0, 1])
  .range([2, c_radius]);

var ordinalScale = d3.scale.ordinal()
  .domain(statusnames)
  .range(statusR)

var strokeWidth = function (d) {
  return (1.1 - ordinalScale(d)) * 5;
}

var orbitRadius = function(d) {
  return ordinalScale(d) * orbit_r;
}

var orbitPhase = function(d) {
  var i = statusnames.indexOf(d);
  return 0;//(i % 3) * 1/3 * Math.PI;
}

var svg = d3.select('#orbitDraw')
  .style('width', w + 'px')
  .style('height', h + 'px');

var marking = svg
  .append('g')
  .attr('id', 'orbitMarking');

var diagram = svg
  .append('g')
  .attr('id', 'orbitDiagram');

var container = d3.select('#orbitWidget');

var groupLabel = container
  .append('div')
  .attr('id', 'groupLabel')

var groupDetails = container
  .append('div')
  .attr('id', 'groupDetails')
  .style('left', parseInt(svg.style('left'), 10) + 'px')
  .style('top', parseInt(svg.style('top'), 10) + parseInt(svg.style('height'), 10) + 'px')

var options,
    yearOptions;

rows = data;

var cmap = {};
rows.forEach(function(d) {
  cmap[d.countries_cowid] = d.countryname;
});

countries = new Array();
for (var key in cmap) {
  countries.push({'countryname': cmap[key], 'countries_cowid': key});
}
countries.sort(function(a, b) { return a.countryname > b.countryname});

//CreateMenu();
//CreateGradient();
DisplayMarking();
messageHub.subscribe('country', DisplayCountry);
messageHub.subscribe('year', DisplayYear);
messageHub.subscribe('group', HighlightCircle);

function CreateMenu() {
  //console.debug(countries);

  var menu = container
    .append('div')
    .attr('id', 'navigation')
    .append('form')

  options = menu
    .append('select')
    .attr('id', 'menu')

  options
    .selectAll('option')
    .data(countries)
    .enter()
    .append('option')
    .text(function(d) { return d.countryname; })
    .attr('value', function(d) { return d.countryname; })

  var y = document.getElementById('menu');
  y.onchange = function() { messageHub.send('country', y.value) };
}

function CreateYearMenu(yearList) {
  if (yearOptions) yearOptions.remove();

  var menu = d3.select('#navigation')
    .select('form')

  yearOptions = menu
    .append('select')
    .attr('id', 'yearMenu')

  yearOptions
    .selectAll('option')
    .data(yearList)
    .enter()
    .append('option')
    .text(function(d) { return d; })
    .attr('value', function(d) { return d; })

  var y = document.getElementById('yearMenu');
  y.onchange = function() { messageHub.send('year', y.value) };
}

function CreateGradient() {
  var gradient = svg.append('svg:defs').append('svg:radialGradient')
    .attr('id', 'gradient')
    .attr('cx', '50%')
    .attr('cy', '50%')
    .attr('r', '50%')
    .attr('fx', '50%')
    .attr('fy', '50%');

  gradient
    .append('stop')
    .attr('offset', '0%')
    .style('stop-color', '#bbb')

  gradient
    .append('stop')
    .attr('offset', '100%')
    .attr('stop-opacity', '0%')
    .style('stop-color', '#464646');
}

function DisplayMarking() {
  marking
    .append('circle')
    .attr('cx', orbit_x)
    .attr('cy', orbit_y)
    .attr('r', orbitRadius(""))
    .style('fill', "url(#gradient)");
    //.style('fill', '#eee')

  marking.selectAll('circle').data(statusR.slice(2)).enter()
    .append('circle')
    .attr('cx', orbit_x)
    .attr('cy', orbit_y)
    .attr('r', function(d) { return d * orbit_r; })
    .style('fill-opacity', 0)
    .style('stroke', '#888');
}

function DisplayCountry(countryname) {
  curData = rows.filter(function(d) { return d.countryname == countryname });
  startYear = d3.min(curData, function(d) { return d.year; });
  endYear = d3.max(curData, function(d) { return d.year; });

  var yearList = [];
  groupList = [];

  for (var y = endYear; y >= startYear; y--) {
    //console.debug(y);
    var yearData = curData.filter(function(d) { return d.year == y});
    if (yearData.length == 0)
      continue;
    yearList.push(y);

    yearData.forEach(function(d) {
      if (groupList.indexOf(d.groupname) == -1)
        groupList.push(d.groupname);
    });
  }

  groupPos = {};
  for (var i = 0; i < groupList.length; i++) {
    groupPos[groupList[i]] = i;
  }

  DisplayYear(endYear);
  // CreateYearMenu(yearList);
}

function GetGroupDetails(d) {
  var output = '';
  output += '<p><span>' + d.groupname + ' [' + d3.format('.2%')(d.groupsize) + ']</span></p>';
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

function CircleMouseOver(d ,i) {
  var circle = d3.select(this);

  circle
    .style('opacity', 1.0)

  groupLabel
    //.html(d.groupname + '<br>' + d.statusname.toProperCase());
    .html(GetGroupDetails(d))

  groupLabel
    .style('top', parseInt(circle.attr('cy')) + parseInt(svg.style('top'), 10) - 100 + 'px')
    .style('left', parseInt(circle.attr('cx')) + parseInt(svg.style('left'), 10) + 20 + 'px')
    .style('visibility', 'visible')
}

function CircleMouseClick(d, i) {
  /*if (curCircle)
    curCircle
      .style('fill', function(d) { return d.fill; })
      .style('stroke', function(d) { return d.stroke; });

  curCircle = d3.select(this);

  curCircle
    .style('fill', '#fff568')
    .style('stroke', '#cbc031');

  groupDetails
    .html(GetGroupDetails(d))
    .style('visibility', 'visible')*/
  HighlightCircle(d.groupname);

  messageHub.send("group", d.countryname + "_" + d.groupname)
  messageHub.send("language", d.language)
 // groupDetails
 //    .html(GetGroupDetails(d))
 //    .style('visibility', 'visible')
}

function HighlightCircle(groupname) {
  if (curCircle)
    curCircle
      .style('fill', function(d) { return d.fill; })
      .style('stroke', function(d) { return d.stroke; });

  curCircle = diagram.selectAll('circle')
    .filter(function(d, i) { return d.countryname + "_" + d.groupname == groupname })
    
  curCircle
    .style('fill', '#fff568')
    .style('stroke', '#cbc031');

  

}

function CircleMouseOut(d, i) {
  var circle = d3.select(this);

  circle
    .style('opacity', 0.7)

  groupLabel
    .style('visibility', 'hidden');

  // groupDetails
  //   .style('visibility', 'hidden');
}

var circles;

function DisplayYear(year) {
  var yearData = curData.filter(function(d) { return d.year == year; });

  var layout = {};
  
  var totalcount = groupList.length;

  yearData.forEach(function(d) {
    d.orbit_radius = orbitRadius(d.statusname);
    d.orbit_angle = groupPos[d.groupname] / totalcount * 2 * Math.PI + orbitPhase(d.statusname);
    d.fill = (d.incidence_flag == 1) ? '#f55' : '#58b';
    d.stroke = (d.incidence_flag == 1) ? '#e22' : '#269';
  });

  var circles = diagram.selectAll('circle').data(yearData, function(d) { return d.groupname; });

  circles.enter().append('circle')
    .attr('cx', function(d) { return orbit_x + d.orbit_radius * Math.cos(d.orbit_angle); })
    .attr('cy', function(d) { return orbit_y + d.orbit_radius * Math.sin(d.orbit_angle); })
    .on('mouseover', CircleMouseOver)
    .on('mouseout', CircleMouseOut)
    .on('click', CircleMouseClick)
    .style('cursor', 'pointer');

  circles.transition()
    .ease(d3.ease("cubic-out"))
    .attr('cx', function(d) { return orbit_x + d.orbit_radius * Math.cos(d.orbit_angle); })
    .attr('cy', function(d) { return orbit_y + d.orbit_radius * Math.sin(d.orbit_angle); })
    .attr('r', function(d) { return circleSize(d.groupsize); })
    .style('fill', function(d) { return d.fill; })
    .style('stroke', function(d) { return d.stroke; })
    .style('opacity', 0.7)
    .style('stroke-width', 2.0)

  circles.exit().remove();

  /* Hack to make highlighted circle retain style */
  if(curCircle) {
    curCircle
      .transition()
      .ease(d3.ease("cubic-out"))
      .attr('cx', function(d) { return orbit_x + d.orbit_radius * Math.cos(d.orbit_angle); })
      .attr('cy', function(d) { return orbit_y + d.orbit_radius * Math.sin(d.orbit_angle); })
      .attr('r', function(d) { return circleSize(d.groupsize); })
      .style('opacity', 0.7)
      .style('stroke-width', 2.0)
      .style('fill', '#fff568')
      .style('stroke', '#cbc031');
  }
}

String.prototype.toProperCase = function () {
    return this.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
};

Array.prototype.unique = function(a){
  return function(){return this.filter(a)}}(function(a,b,c){return c.indexOf(a,b+1)<0
});

};