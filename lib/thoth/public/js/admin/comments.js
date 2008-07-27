Thoth.Admin = Thoth.Admin || {};

Thoth.Admin.Comments = function () {
  // Shorthand.
  var Y   = YAHOO,
      yut = Y.util,
      yuc = yut.Connect,
      yud = yut.Dom,
      yue = yut.Event;

  // -- Private Methods --------------------------------------------------------

  /**
   * Deletes the comment with the specified <i>id</i>.
   *
   * @method deleteComment
   * @param {Number} id comment id
   * @param {Boolean} silent if <i>true</i>, no confirmation dialog will be
   *   displayed
   * @private
   */
  function deleteComment(id, silent) {
    var postData = 'id=' + encodeURIComponent(id) + '&token=' +
          encodeURIComponent(Thoth.getToken());

    if (!silent && !confirm(
        'Are you sure you want to permanently delete this comment?')) {
      return;
    }

    yuc.asyncRequest('POST', '/api/comment/delete', {
      scope: this,
      timeout: 8000,
      failure: function (r) {
        try {
          alert(Y.lang.JSON.parse(r.responseText).error);
        } catch (e) {
          alert('Unable to delete comment.');
        }
      },
      success: function () {
        yud.addClass('comment-' + id, 'hidden');
      }
    }, postData);
  }

  // -- Private Event Handlers -------------------------------------------------

  /**
   * Handles clicks within the comments div. Uses delegation to determine what
   * action to take, if any.
   *
   * @method handleCommentClick
   * @param {Event} e event object
   * @private
   */
  function handleCommentClick(e) {
    var el = yue.getTarget(e),
        commentEl;

    if (yud.hasClass(el, 'comment-delete') &&
        (commentEl = yud.getAncestorByClassName(el, 'comment'))) {

      yue.preventDefault(e);
      deleteComment(commentEl.id.split('-')[1], e.shiftKey || e.metaKey);
    }
  }

  return {
    // -- Public Methods -------------------------------------------------------

    /**
     * Initializes the Comments module.
     *
     * @method init
     */
    init: function () {
      yue.on('comments', 'click', handleCommentClick, this, true);
    }
  };
}();

YAHOO.util.Event.onDOMReady(Thoth.Admin.Comments.init, Thoth.Admin.Comments,
    true);
