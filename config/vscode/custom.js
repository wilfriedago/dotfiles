function observeParentContainer() {
  const parentContainer = document.querySelector(".monaco-workbench") // Adjust to your actual container

  if (!parentContainer) {
    setTimeout(observeParentContainer, 500) // Retry after 500ms
    return
  }

  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach((node) => {
        if (node.nodeType === 1 && node.matches(".quick-input-widget")) {

          // Ensure a wrapper does not already exist
          if (!node.nextElementSibling || !node.nextElementSibling.classList.contains("wrapper-div")) {
            const wrapperDiv = document.createElement("div")
            wrapperDiv.classList.add("wrapper-div")

            // Apply styles to the wrapper div (backdrop)
            wrapperDiv.style.position = "absolute"
            wrapperDiv.style.top = "0"
            wrapperDiv.style.left = "0"
            wrapperDiv.style.width = "100%"
            wrapperDiv.style.height = "100%"
            wrapperDiv.style.backgroundColor = "rgba(0, 0, 0, 0.5)" // Darker effect
            wrapperDiv.style.backdropFilter = "blur(4px)" // Blur effect
            wrapperDiv.style.zIndex = "1000" // Backdrop should be behind the node
            wrapperDiv.style.display = "none" // Hide backdrop by default

            // Ensure the quick input widget is always on top
            node.style.zIndex = "1001"

            // Insert the wrapper as a sibling, not as a parent
            node.parentNode.insertBefore(wrapperDiv, node.nextSibling)

            // 🔥 **Immediate check to show backdrop if node is visible**
            setTimeout(() => {
              if (window.getComputedStyle(node).display !== "none") {
                wrapperDiv.style.display = "block" // Show backdrop if node is visible
              }
            }, 10) // Small delay to ensure styles are applied

            // Observe the node's style changes
            const styleObserver = new MutationObserver(() => {
              const currentDisplay = window.getComputedStyle(node).display

              if (currentDisplay === "none") {
                wrapperDiv.style.display = "none" // Hide backdrop when node is hidden
              } else {
                wrapperDiv.style.display = "block" // Show backdrop when node is visible
              }
            })

            // Start observing the quick input widget for style changes
            styleObserver.observe(node, { attributes: true, attributeFilter: ["style"] })
          }
        }
      })
    })
  })

  // Start observing the parent container for new child elements
  observer.observe(parentContainer, { childList: true, subtree: true })
}

function moveToolbar() {
  const toolbar = document.querySelector(".monaco-workbench .part.titlebar > .titlebar-container > .titlebar-right > .action-toolbar-container .monaco-toolbar")
  const sidebarRightContainer = document.querySelector(".monaco-workbench .part.sidebar.right > .header-or-footer.header .composite-bar-container")
  const sidebarLeftContainer = document.querySelector(".monaco-workbench .part.auxiliarybar.left > .header-or-footer.header .composite-bar-container")

  if (!toolbar || !sidebarRightContainer || !sidebarLeftContainer) {
    setTimeout(moveToolbar, 500) // Retry after 500ms
    return
  }

  // Move toolbar into the target container
  sidebarRightContainer.appendChild(toolbar)
}

// Run the function
moveToolbar()

// Run the function
observeParentContainer()
