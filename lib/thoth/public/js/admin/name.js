Thoth.Admin = Thoth.Admin || {};

Thoth.Admin.Name = function () {
  // Shorthand.
  var d   = document,
      Y   = YAHOO,
      yut = Y.util,
      yuc = yut.Connect,
      yud = yut.Dom,
      yue = yut.Event;

  // -- Private Variables ------------------------------------------------------
  var conn,
      data,
      delay,
      regexp = /^[0-9a-z_-]+$/i,
      self;

  // -- Private Methods --------------------------------------------------------

  /**
   * Submits an Ajax request to determine if the current name is valid and not
   * already taken.
   *
   * @method checkName
   * @param {HTMLElement} el name input element
   * @param {String} name name to check
   * @private
   */
  function checkName(el, name) {
    if (conn && yuc.isCallInProgress(conn)) {
      yuc.abort(conn);
    }

    var url = '/api/' + (yud.hasClass(el, 'name-post') ? 'post' : 'page') +
        '/check_name?name=' + encodeURIComponent(name);

    conn = yuc.asyncRequest('GET', url, {
      argument: el,
      success : handleCheckResponse,
      timeout : 1000
    });
  }

  /**
   * Hides the error message associated with the specified name input element.
   *
   * @method hideError
   * @param {HTMLElement} el name input element
   * @private
   */
  function hideError(el) {
    var errorEl = yud.get(el.id + '-error');

    if (errorEl) {
      errorEl.parentNode.removeChild(errorEl);
    }
  }

  /**
   * Shows an error message associated with the specified name input element.
   *
   * @method showError
   * @param {HTMLElement} el name input element
   * @param {String} message error message
   * @private
   */
  function showError(el, message) {
    var errorEl = yud.get(el.id + '-error');

    if (!errorEl) {
      errorEl = d.createElement('p');

      errorEl.id        = el.id + '-error';
      errorEl.className = 'flash error';

      yud.insertAfter(errorEl, el);
    }

    errorEl.innerHTML = '';
    errorEl.appendChild(d.createTextNode(message));
  }

  /**
   * Submits an Ajax request for a name suggestion based on the contents of the
   * specified title input element.
   *
   * @method suggestName
   * @param {HTMLElement} el title input element
   * @param {String} title title string
   * @private
   */
  function suggestName(el, title) {
    if (conn && yuc.isCallInProgress(conn)) {
      yuc.abort(conn);
    }

    var url = '/api/' + (yud.hasClass(el, 'title-post') ? 'post' : 'page') +
        '/suggest_name?title=' + encodeURIComponent(title);

    conn = yuc.asyncRequest('GET', url, {
      argument: el,
      success : handleSuggestResponse,
      timeout : 1000
    });
  }

  // -- Private Event Handlers -------------------------------------------------

  /**
   * Handles Ajax check_name responses.
   *
   * @method handleCheckResponse
   * @param {Object} response response object
   * @private
   */
  function handleCheckResponse(response) {
    var data

    try {
      data = Y.lang.JSON.parse(response.responseText);
    } catch (e) {
      return;
    }

    if (!data.valid) {
      showError(response.argument, 'Names may only contain letters, numbers, ' +
          'underscores, and dashes, and may not be entirely numeric.');
    } else if (!data.unique) {
      showError(response.argument, 'This name is already taken.');
    } else {
      hideError(response.argument);
    }
  }

  /**
   * Handles keypress events on name input fields.
   *
   * @method handleKeyPress
   * @param {Event} e event object
   * @private
   */
  function handleKeyPress(e) {
    var c  = String.fromCharCode(yue.getCharCode(e)),
        el = yue.getTarget(e);

    if (e.isChar) {
      if (regexp.test(c)) {
        if (/[A-Z]/.test(c)) {
          yue.stopEvent(e);
          el.value += c.toLowerCase();
        }
      } else {
        yue.stopEvent(e);

        if (c === ' ') {
          el.value += '-';
        }
      }
    }
  }

  /**
   * Handles keyup events on name input fields.
   *
   * @method handleKeyUp
   * @param {Event} e event object
   * @private
   */
  function handleKeyUp(e) {
    var el = yue.getTarget(e);

    clearTimeout(delay);

    if (el.value) {
      yue.removeListener('title', 'change', handleTitleChange);

      delay = setTimeout(function () {
        checkName(el, el.value);
      }, 200);
    } else {
      hideError(el);
      yue.on('title', 'change', handleTitleChange, self, true);
    }
  }

  /**
   * Handles Ajax suggest_name responses.
   *
   * @method handleSuggestResponse
   * @param {Object} response response object
   * @private
   */
  function handleSuggestResponse(response) {
    try {
      yud.get('name').value = Y.lang.JSON.parse(response.responseText).name;
    } catch (e) {}
  }

  /**
   * Handles change events on title input fields.
   *
   * @method handleTitleChange
   * @param {Event} e event object
   * @private
   */
  function handleTitleChange(e) {
    var el = yue.getTarget(e);

    if (el.value) {
      suggestName(el, el.value);
    }
  }

  return {
    // -- Public Methods -------------------------------------------------------

    /**
     * Initializes the Name module on this page.
     *
     * @method init
     */
    init: function () {
      var name = yud.get('name');

      self = this;

      // Listen for keys on name input fields.
      yue.on(name, 'keypress', handleKeyPress, self, true);
      yue.on(name, 'keyup', handleKeyUp, self, true);

      if (!name.value.length) {
        // Listen for changes to title input fields.
        yue.on('title', 'change', handleTitleChange, self, true);
      }
    },
  };
}();

YAHOO.util.Event.onDOMReady(Thoth.Admin.Name.init, Thoth.Admin.Name, true);
