var Thoth = function () {
  // Shorthand.
  var d   = document,
      Y   = YAHOO,
      yut = Y.util,
      yud = yut.Dom,
      yue = yut.Event;

  // -- Constants --------------------------------------------------------------

  /**
   * URLs for lazy-loaded JavaScript dependencies.
   *
   * @const js
   * @type Object
   * @private
   */
  var js = {
    thoth: {
      comments   : '/js/admin/comments.js',
      name       : '/js/admin/name.js',
      tagcomplete: '/js/admin/tagcomplete.js'
    },
    yui: {
      anim     : 'http://yui.yahooapis.com/2.8.0/build/animation/animation-min.js',
      conn_json: 'http://yui.yahooapis.com/combo?2.8.0/build/connection/connection-min.js&2.8.0/build/json/json-min.js'
    }
  };

  // -- Private Variables ------------------------------------------------------
  var hotKeys = {},
      next, prev, token;

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

    hotKeys.ctrl_alt_a = new yut.KeyListener(d,
        { ctrl: true, alt: true, keys: 65 }, Thoth.toggleAdminToolbar);

    hotKeys.n = new yut.KeyListener(d, { keys: 78 }, handleKeyNext);
    hotKeys.p = new yut.KeyListener(d, { keys: 80 }, handleKeyPrev);

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
      if (hotKeys.hasOwnProperty(key) && key !== 'ctrl_alt_a') {
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
    // -- Constants ------------------------------------------------------------

    /**
     * URLs for lazy-loaded JavaScript dependencies.
     *
     * @const js
     * @type Object
     */
    js: js,

    // -- Public Methods -------------------------------------------------------

    /**
     * Initializes the Thoth module.
     *
     * @method init
     * @param {Boolean} admin (optional) whether or not we're in admin mode
     * @param {String} formToken (optional) admin form token for this request
     */
    init: function (admin, formToken) {
      attachKeys();

      if (admin) {
        token = formToken;

        // Load the Name module if this page contains one or more name input
        // elements.
        if (yud.get('page-form') || yud.get('post-form')) {
          LazyLoad.js([js.yui.conn_json, js.thoth.name]);
        }

        // Load the TagComplete module if this page contains one or more tag
        // input elements.
        if (yud.get('post-form')) {
          LazyLoad.js([js.yui.conn_json, js.thoth.tagcomplete]);
        }

        // Load the Comments module if this page contains comments.
        if (yud.get('comments')) {
          LazyLoad.js([js.yui.conn_json, js.thoth.comments]);
        }
      }
    },

    /**
     * Gets the administrator form token for this request, if any.
     *
     * @method getToken
     * @return {String|null} form token, or <i>null</i> if user is not an admin
     */
    getToken: function () {
      return token;
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
