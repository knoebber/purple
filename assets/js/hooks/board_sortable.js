import Sortable from 'sortablejs/modular/sortable.core.esm.js';

function getIds(sortableEl) {
  return sortableEl
    ? Array
      .from(sortableEl.querySelectorAll('.js-sortable-item'))
      .map((e) => e.id)
    : null;
}

function getStatus(sortableEl, itemEl) {
  return {
    status: Array
      .from(sortableEl.classList)
      .find((className) => className.startsWith('js-status'))
      .split('-')[2],
    id: itemEl.id,
  }
}


export default {
  mounted() {
    Sortable.create(this.el, {
      animation: 150,
      handle: '.cursor-move',
      ghostClass: 'opacity-25',
      group: this.el.dataset.sortableGroup,
      dragClass: 'filter-none',
      onSort: (sortableEvent) => {
	const { item, originalTarget } = sortableEvent;
	const shouldChangeStatus = item.parentElement.id !== originalTarget.id;
	this.pushEvent('save_item_order', {
	  new_status: shouldChangeStatus ? getStatus(item.parentElement, item) : null,
	  sort_order: {
	    doneIds: getIds(document.getElementById('js-sortable-done')),
	    infoIds: getIds(document.getElementById('js-sortable-info')),
	    todoIds: getIds(document.getElementById('js-sortable-todo')),
	  }
	});
      }
    });
  },
};
