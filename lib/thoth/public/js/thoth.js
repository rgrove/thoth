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

  /**
   * Attaches keyboard shortcut event listeners.
   *
   * @method attachKeys
   * @private
   */
  function attachKeys() {
    var inputs    = d.body.getElementsByTagName('input'),
        selects   = d.body.getElementsByTagName('select'),
        textareas = d.body.getElementsByTagName('textarea');

    next = yud.get('next_url');
    prev = yud.get('prev_url');

    hotKeys['ctrl_alt_a'] = new yut.KeyListener(d,
        { ctrl: true, alt: true, keys: 65 }, Thoth.toggleAdminToolbar);

    hotKeys['n'] = new yut.KeyListener(d, { keys: 78 }, handleKeyNext);
    hotKeys['p'] = new yut.KeyListener(d, { keys: 80 }, handleKeyPrev);

    // Stop listening for hotkeys when a form element gets focus.
    yue.on(inputs, 'blur', enableKeys, Thoth, true);
    yue.on(inputs, 'focus', disableKeys, Thoth, true);
    yue.on(selects, 'blur', enableKeys, Thoth, true);
    yue.on(selects, 'focus', disableKeys, Thoth, true);
    yue.on(textareas, 'blur', enableKeys, Thoth, true);
    yue.on(textareas, 'focus', disableKeys, Thoth, true);

    enableKeys();
  }

  /**
   * Disables all key listeners.
   *
   * @method disableKeys
   * @private
   */
  function disableKeys() {
    var key;

    for (key in hotKeys) {
      if (hotKeys.hasOwnProperty(key) && key != 'ctrl_alt_a') {
        hotKeys[key].disable();
      }
    }
  }

  /**
   * Enables all key listeners.
   *
   * @method enableKeys
   * @private
   */
  function enableKeys() {
    var key;

    for (key in hotKeys) {
      if (hotKeys.hasOwnProperty(key)) {
        hotKeys[key].enable();
      }
    }
  }

  // -- Private Event Handlers -------------------------------------------------

  /**
   * Handles the "next page" keyboard shortcut.
   *
   * @method handleKeyNext
   * @private
   */
  function handleKeyNext() {
    if (next) {
      window.location = next.href;
    }
  }

  /**
   * Handles the "previous page" keyboard shortcut.
   *
   * @method handleKeyPrev
   * @private
   */
  function handleKeyPrev() {
    if (prev) {
      window.location = prev.href;
    }
  }

  return {
    // -- Public Methods -------------------------------------------------------

    /**
     * Initializes the Thoth module.
     *
     * @method init
     * @param {Boolean} admin whether or not we're in admin mode
     */
    init: function (admin) {
      attachKeys();

      // Load the TagComplete module if this page contains one or more tag input
      // elements.
      if (admin && yud.getElementsByClassName('tags-input', 'input').length) {
        LazyLoad.loadOnce([
          'http://yui.yahooapis.com/combo?2.5.2/build/connection/connection-min.js&2.5.2/build/json/json-min.js',
          '/js/admin/tagcomplete.js'
        ]);
      }
    },

    /**
     * Toggles the visibility of the admin toolbar.
     *
     * @method toggleAdminToolbar
     */
    toggleAdminToolbar: function () {
      var toolbar  = yud.get('adminToolbar'),
          username = yud.get('username');

      if (yud.addClass(toolbar, 'hidden')) {
        if (username) { username.blur(); }
      } else if (yud.removeClass(toolbar, 'hidden')) {
        if (username) { username.focus(); }
      }
    }
  };
}();
