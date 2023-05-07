export default {
  mounted() {
    window.addEventListener('phx:page-loading-stop', (info) => {
      this.pushEventTo(
	'#js-side-nav',
	'global_navigate',
	{ to: info.detail.to }
      );
    }, { once: true });
  }
}
