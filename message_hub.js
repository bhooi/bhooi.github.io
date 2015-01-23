var MessageHub = function() {
	this.subscribers = {}
}

MessageHub.prototype.send = function(type, args) {
	var numSubscribers = 0;
	if (this.subscribers.hasOwnProperty(type)) {
		var numSubscribers = this.subscribers[type].length
		for (var i = 0; i < numSubscribers; i++) {
			this.subscribers[type][i](args);
		} 
	}
	return numSubscribers
}

MessageHub.prototype.subscribe = function(type, handler) {
	if (typeof handler !== "function") {
		console.error("MessageHub.subscribed called with non-function as handler.");
		return;
	}
	if (!this.subscribers.hasOwnProperty(type)) {
		this.subscribers[type] = [];
	}
	this.subscribers[type].push(handler);
}
