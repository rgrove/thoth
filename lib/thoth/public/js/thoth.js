var Thoth = function () {
  // Shorthand.
  var d   = document,
      Y   = YAHOO,
      yut = Y.util,
      yud = yut.Dom,
      yue = yut.Event;

  // -- Private Variables ------------------------------------------------------
  var hotKeys = {},
      next,
      prev;

  // -- Private Methods --------------------------------------------------------
  function attachKeys() {
    next = yud.get('next_url');
    prev = yud.get('prev_url');

    hotKeys['ctrl_alt_a'] = new yut.KeyListener(d,
        { ctrl: true, alt: true, keys: 65 }, toggleAdminToolbar);

    hotKeys['n'] = new yut.KeyListener(d, { keys: 78 }, handleKeyNext);
    hotKeys['p'] = new yut.KeyListener(d, { keys: 80 }, handleKeyPrev);

    // Stop listening for hotkeys when a form element gets focus.
    var inputs    = d.body.getElementsByTagName('input'),
        selects   = d.body.getElementsByTagName('select'),
        textareas = d.body.getElementsByTagName('textarea');

    yue.on(inputs, 'blur', enableKeys, this, true);
    yue.on(inputs, 'focus', disableKeys, this, true);
    yue.on(selects, 'blur', enableKeys, this, true);
    yue.on(selects, 'focus', disableKeys, this, true);
    yue.on(textareas, 'blur', enableKeys, this, true);
    yue.on(textareas, 'focus', disableKeys, this, true);

    enableKeys();
  }

  function disableKeys() {
    for (var key in hotKeys) {
      if (hotKeys.hasOwnProperty(key) && key != 'ctrl_alt_a') {
        hotKeys[key].disable();
      }
    }
  }

  function enableKeys() {
    for (var key in hotKeys) {
      if (hotKeys.hasOwnProperty(key)) {
        hotKeys[key].enable();
      }
    }
  }

  function handleKeyNext() {
    if (next) {
      window.location = next.href;
    }
  }

  function handleKeyPrev() {
    if (prev) {
      window.location = prev.href;
    }
  }

  function toggleAdminToolbar() {
    var toolbar  = yud.get('adminToolbar'),
        username = yud.get('username');

    if (yud.addClass(toolbar, 'hidden')) {
      if (username) { username.blur(); }
    } else if (yud.removeClass(toolbar, 'hidden')) {
      if (username) { username.focus(); }
    }
  }

  yue.onContentReady('doc', attachKeys, this, true);

  return {};
}();
