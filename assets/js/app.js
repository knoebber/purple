// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import './user_socket.js'

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import '../vendor/some-package.js'
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import 'some-package'
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html';
import './events';
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from '../vendor/topbar';

import AutoFocus from './hooks/autofocus';
import BoardSortable from './hooks/board_sortable';
import CopyMarkdownImage from './hooks/copy_markdown_image';
import EntrySortable from './hooks/entry_sortable';
import MarkdownTextarea from './hooks/markdown_textarea';
import PDF from './hooks/pdf';
import SideNav from './hooks/side_nav';

const params = {
  _csrf_token: document.querySelector("meta[name='csrf-token']").getAttribute('content'),
};

const liveSocket = new LiveSocket(
  '/live',
  Socket,
  {
    hooks: {
      AutoFocus,
      BoardSortable,
      CopyMarkdownImage,
      EntrySortable,
      MarkdownTextarea,
      PDF,
      SideNav,
    },
    params,
  }
);

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: 'purple'}, shadowColor: 'rgba(0, 0, 0, .3)'});
window.addEventListener('phx:page-loading-start', info => topbar.show());
window.addEventListener('phx:page-loading-stop', info => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
