function copyMarkdownToClipboard(name, path) {
  navigator
    .clipboard
    .writeText(`![${name}](${path})`)
    .then(() => {
      alert('Copied to clipboard - paste content into an entry');
    });
}

const CopyMarkdownImage = {
  mounted() {
    this.el.addEventListener('click', () => {
      copyMarkdownToClipboard(
        this.el.getAttribute('name'),
        this.el.getAttribute('value'),
      );
    });
  },
};

export default CopyMarkdownImage;
