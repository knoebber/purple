import pdfJS from 'pdfjs-dist';
import pdfjsWorker from 'pdfjs-dist/build/pdf.worker.entry';

let isRendering = false;
let pageNum = 1;

function renderPDF(canvas) {
  pdfJS.GlobalWorkerOptions.workerSrc = pdfjsWorker;
  //
  // Asynchronous download PDF
  //
  const loadingTask = pdfJS.getDocument(canvas.dataset.path);
  (async () => {
    const pdf = await loadingTask.promise;
    //
    // Fetch the first page
    //
    let page = await pdf.getPage(1);
    const viewport = page.getViewport({ scale: 1.5 });
    // Support HiDPI-screens.
    const outputScale = window.devicePixelRatio || 1;

    //
    // Prepare canvas using PDF page dimensions
    //
    const context = canvas.getContext('2d');

    canvas.width = Math.floor(viewport.width * outputScale);
    canvas.height = Math.floor(viewport.height * outputScale);
    canvas.style.width = Math.floor(viewport.width) + 'px';
    canvas.style.height = Math.floor(viewport.height) + 'px';
    canvas.classList.add('border', 'border-purple-500', 'rounded');

    const transform = outputScale !== 1 
    ? [outputScale, 0, 0, outputScale, 0, 0] 
    : null;

    //
    // Render PDF page into canvas context
    //
    let renderContext = {
      canvasContext: context,
      transform,
      viewport,
    };
    page.render(renderContext);

    async function onPrevPage() {
      if (pageNum <= 1) {
        return;
      }
      pageNum -= 1;
      page = await pdf.getPage(pageNum);
      page.render(renderContext);
    }

    async function onNextPage() {
      if (pageNum >= pdf.numPages) {
        return;
      }
      pageNum += 1;
      page = await pdf.getPage(pageNum);
      page.render(renderContext);
    } 

    async function onZoom(e) {
      console.log('zooming to', parseFloat(e.target.value));
      console.log(page.getViewport({ scale: parseFloat(e.target.value) }));
      const newViewport = page.getViewport({ scale: parseFloat(e.target.value) });
      canvas.width = Math.floor(newViewport.width * outputScale);
      canvas.height = Math.floor(newViewport.height * outputScale);
      canvas.style.width = Math.floor(newViewport.width) + 'px';
      canvas.style.height = Math.floor(newViewport.height) + 'px';
      renderContext.viewport = newViewport;
      page = await pdf.getPage(pageNum);
      page.render(renderContext);     
    } 

    document.querySelector('.js-next').addEventListener('click', onNextPage);
    document.querySelector('.js-prev').addEventListener('click', onPrevPage)
    document.querySelector('.js-zoom').addEventListener('click', onZoom)
  })();
}


export default {
  mounted() {
  	renderPDF(this.el);
  },
  updated() {
    renderPDF(this.el);
  },
};
