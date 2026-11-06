// Loaded by the "Custom UI Style" extension (see "custom-ui-style.external.imports" in settings.json).
//
// Purpose: move the title bar's right-hand action toolbar (layout toggles, account/settings
// buttons, etc.) into the header of the primary sidebar when it is docked on the right.
// This frees the title bar and keeps those controls next to the sidebar they affect.

const TITLEBAR_TOOLBAR_SELECTOR =
  '.monaco-workbench .part.titlebar .titlebar-right .action-toolbar-container .monaco-toolbar';

const RIGHT_SIDEBAR_HEADER_SELECTOR =
  '.monaco-workbench .part.sidebar.right > .header-or-footer.header .composite-bar-container';

const RETRY_INTERVAL_MS = 500;
const MAX_RETRIES = 20; // 20 x 500 ms = give up after ~10 seconds

/**
 * Poll the DOM until an element matching `selector` exists, then call `onFound` with it.
 * VS Code builds its workbench asynchronously, so the element may not exist yet when this
 * script first runs. Gives up silently after `retriesLeft` attempts.
 */
function waitForElement(selector, onFound, retriesLeft = MAX_RETRIES) {
  const element = document.querySelector(selector);

  if (element) {
    onFound(element);
    return;
  }

  if (retriesLeft > 0) {
    setTimeout(() => waitForElement(selector, onFound, retriesLeft - 1), RETRY_INTERVAL_MS);
  }
}

/**
 * Re-parent the title bar toolbar into the right sidebar header.
 * `appendChild` moves the existing node rather than copying it, so the toolbar keeps
 * all of its event listeners and continues to work after the move.
 */
function moveTitlebarToolbarIntoRightSidebar() {
  waitForElement(TITLEBAR_TOOLBAR_SELECTOR, (titlebarToolbar) => {
    const rightSidebarHeader = document.querySelector(RIGHT_SIDEBAR_HEADER_SELECTOR);

    if (rightSidebarHeader) {
      rightSidebarHeader.appendChild(titlebarToolbar);
    }
  });
}

moveTitlebarToolbarIntoRightSidebar();
