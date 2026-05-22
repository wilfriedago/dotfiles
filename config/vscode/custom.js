function waitForElement(selector, callback, maxRetries = 20) {
  const el = document.querySelector(selector);
  if (el) return callback(el);
  if (maxRetries > 0) setTimeout(() => waitForElement(selector, callback, maxRetries - 1), 500);
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
