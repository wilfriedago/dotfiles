const w=(s,c,n=20)=>{let e=document.querySelector(s);e?c(e):n&&setTimeout(()=>w(s,c,n-1),500)}
w('.monaco-workbench .part.titlebar .titlebar-right .action-toolbar-container .monaco-toolbar',t=>{let e=document.querySelector('.monaco-workbench .part.sidebar.right > .header-or-footer.header .composite-bar-container');e&&e.appendChild(t)})
