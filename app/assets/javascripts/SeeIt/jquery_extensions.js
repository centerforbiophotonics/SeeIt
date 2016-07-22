jQuery.fn.extend({
  singleton_on: function(event, handler) {
    this.off(event);
    this.on(event, handler);
    return this;
  }
});