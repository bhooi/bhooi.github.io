var Tooltip = function() {
	this.elem = $("<div>")
		.addClass("tooltip")
		.css({ "position": "absolute", "z-index": 9999 })
		.hide()
		.appendTo("body")
}

Tooltip.prototype.show = function(contents, x, y) {
	this.elem
		.empty()
		.html(contents)
		.css({ "left": x, "top": y })
		.show();
}

Tooltip.prototype.hide = function() {
	this.elem.hide();
}
