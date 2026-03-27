// Comment functionality for threaded comments

window.toggleReplyForm = function(commentId) {
  const form = document.getElementById(`reply-form-${commentId}`);
  if (form) {
    form.classList.toggle('hidden');
  }
};

window.toggleEditForm = function(commentId) {
  const body = document.getElementById(`comment-body-${commentId}`);
  const form = document.getElementById(`edit-form-${commentId}`);
  if (body && form) {
    body.classList.toggle('hidden');
    form.classList.toggle('hidden');
  }
};

window.confirmDelete = function(commentId, excerpt) {
  const confirmation = prompt(`To delete this comment, type the following text:\n\n"${excerpt}"`);

  if (confirmation !== null) {
    const confirmationField = document.getElementById(`confirmation-${commentId}`);
    const deleteForm = document.getElementById(`delete-form-${commentId}`);

    if (confirmationField && deleteForm) {
      confirmationField.value = confirmation;
      deleteForm.submit();
    }
  }
};
