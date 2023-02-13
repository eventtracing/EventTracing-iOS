function simulate_click(eid) {
  var options = {
    pointerX: 0,
    pointerY: 0,
    button: 0,
    ctrlKey: false,
    altKey: false,
    shiftKey: false,
    metaKey: false,
    bubbles: true,
    cancelable: true,
  };

  function extend(destination, source) {
    for (var property in source) destination[property] = source[property];
    return destination;
  }

  var oEvent;
  var eventType = "MouseEvents";
  var element = document.querySelector("#" + eid);
  if (!element) {
    return;
  }

  oEvent = document.createEvent(eventType);
  oEvent.initMouseEvent(
    "click",
    options.bubbles,
    options.cancelable,
    document.defaultView,
    options.button,
    options.pointerX,
    options.pointerY,
    options.pointerX,
    options.pointerY,
    options.ctrlKey,
    options.altKey,
    options.shiftKey,
    options.metaKey,
    options.button,
    element
  );
  element.dispatchEvent(oEvent);
}
