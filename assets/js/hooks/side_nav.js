export default {
  mounted() {
    console.log('side nav hook mounted');
    this.pushEventTo(
      '#js-side-nav',
      'global_navigate',
      { to: window.location.toString() }
    );
  }
}
