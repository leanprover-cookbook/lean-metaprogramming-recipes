window.addEventListener('load', () => {
  // 1. Add 'Try it!' and 'Copy' buttons to code blocks
  const blocks = document.querySelectorAll('code.hl.lean.block');
  blocks.forEach(block => {
    const code = block.innerText;
    
    // Create actions container
    const actions = document.createElement('div');
    actions.className = 'code-block-actions';
    
    // Copy button
    const copyButton = document.createElement('button');
    copyButton.className = 'copy-button';
    copyButton.title = 'Copy to clipboard';
    const copyIcon = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>';
    const checkIcon = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>';
    copyButton.innerHTML = copyIcon;
    
    copyButton.addEventListener('click', () => {
      navigator.clipboard.writeText(code).then(() => {
        copyButton.innerHTML = checkIcon;
        setTimeout(() => {
          copyButton.innerHTML = copyIcon;
        }, 2000);
      });
    });
    
    // Try it button
    const header = "import Lean\nopen Lean Meta Elab Tactic Term Command\n-- If any imports are missing from the default header, please manually add them.\n\n";
    const url = 'https://live.lean-lang.org/#code=' + encodeURIComponent(header + code);
    const tryItButton = document.createElement('a');
    tryItButton.href = url;
    tryItButton.target = '_blank';
    tryItButton.className = 'try-it-button';
    tryItButton.title = 'Open in Lean 4 Web Editor';
    tryItButton.innerHTML = `
      <svg width="12" height="12" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"></path></svg>
      <span>Try it!</span>
    `;
    
    actions.appendChild(copyButton);
    actions.appendChild(tryItButton);
    block.appendChild(actions);
  });
});
