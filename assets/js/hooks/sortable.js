import Sortable from 'sortablejs/modular/sortable.core.esm.js';

function onSort(hook) {
  const list = Array
    .from(hook.el.querySelectorAll('.js-sortable-item'))
    .map((e) => e.id);

  hook.pushEvent('save_sort_order', { list });
}

const SortableHook = {
  mounted(e) {
    Sortable.create(this.el, {
      animation: 150,
      handle: '.cursor-move',
      ghostClass: 'opacity-25',
      dragClass: 'filter-none',
      onSort: () => onSort(this),
    });
  },
};

export default SortableHook;
