function ready(fn) {
  if (document.readyState != 'loading') {
    fn();
  } else {
    document.addEventListener('DOMContentLoaded', fn);
  }
}

function attachListeners(elems, event, fn) {
  Array.from(elems).forEach((elem) => elem.addEventListener(event, fn));
}
