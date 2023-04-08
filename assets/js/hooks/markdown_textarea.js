/**
 * Automatically creates markdown link when pasting a url into a textarea over selected text
 */
function onPaste(e) {
  const { target, clipboardData } = e;
  const { value, selectionStart, selectionEnd } = target;
  const selection = value.substring(selectionStart, selectionEnd)
  if (selection) {
    try {
      const uri = new URL(clipboardData.getData('text/plain'));
      e.preventDefault();
      target.value = `${value.substring(0, selectionStart)}[${selection}](${uri})${value.substring(selectionEnd)}`;
    } catch(e) {
      if (!(e instanceof TypeError)) {
	// Type error is raised when url is invalid, which is expected.
	console.error(e);
      }
    }
  }
}

export default {
  mounted() {
    this.el.focus();
    this.el.addEventListener('paste', onPaste);
  }
}
