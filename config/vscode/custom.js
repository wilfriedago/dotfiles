const w=(s,c,n=20)=>{let e=document.querySelector(s);e?c(e):n&&setTimeout(()=>w(s,c,n-1),500)}
w('.monaco-workbench .part.titlebar .titlebar-right .action-toolbar-container .monaco-toolbar',t=>{let e=document.querySelector('.monaco-workbench .part.sidebar.right > .header-or-footer.header .composite-bar-container');e&&e.appendChild(t)})

;(() => {
  const GAP = 8

  const desc =
    Object.getOwnPropertyDescriptor(window, 'innerHeight') ??
    Object.getOwnPropertyDescriptor(Window.prototype, 'innerHeight')
  if (!desc?.get || !desc.configurable) return

  const real = desc.get
  Object.defineProperty(window, 'innerHeight', {
    configurable: true,
    enumerable: desc.enumerable,
    get: () => Math.max(0, real.call(window) - GAP),
  })

  const style = document.createElement('style')
  style.textContent = `.monaco-workbench { margin-top: ${GAP}px; }`
  ;(document.head ?? document.documentElement).appendChild(style)

  // the workbench may already have measured the real height — make it re-layout
  const relayout = () => dispatchEvent(new Event('resize'))
  relayout()
  addEventListener('load', relayout, { once: true })
})()
