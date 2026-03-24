function waitForElement(selector, callback, maxRetries = 20) {
  const el = document.querySelector(selector);
  if (el) return callback(el);
  if (maxRetries > 0) setTimeout(() => waitForElement(selector, callback, maxRetries - 1), 500);
}

function addQuickInputBackdrop() {
  waitForElement('.monaco-workbench', (workbench) => {
    new MutationObserver((mutations) => {
      for (const { addedNodes } of mutations) {
        for (const node of addedNodes) {
          if (node.nodeType !== 1 || !node.classList?.contains('quick-input-widget')) continue;
          if (node.nextElementSibling?.classList.contains('wrapper-div')) continue;

          const backdrop = document.createElement('div');
          backdrop.className = 'wrapper-div';
          Object.assign(backdrop.style, {
            position: 'absolute', inset: '0',
            backgroundColor: 'rgba(0,0,0,0.1)',
            backdropFilter: 'blur(1px)',
            zIndex: '1000', display: 'none',
          });
          node.style.zIndex = '1001';
          node.parentNode.insertBefore(backdrop, node.nextSibling);

          const sync = () => {
            backdrop.style.display = getComputedStyle(node).display === 'none' ? 'none' : 'block';
          };
          setTimeout(sync, 10);
          new MutationObserver(sync).observe(node, { attributes: true, attributeFilter: ['style'] });
        }
      }
    }).observe(workbench, { childList: true, subtree: true });
  });
}

function moveToolbar() {
  waitForElement(
    '.monaco-workbench .part.titlebar .titlebar-right .action-toolbar-container .monaco-toolbar',
    (toolbar) => {
      const target = document.querySelector(
        '.monaco-workbench .part.sidebar.right > .header-or-footer.header .composite-bar-container'
      );
      if (target) target.appendChild(toolbar);
    }
  );
}

moveToolbar();
addQuickInputBackdrop();
