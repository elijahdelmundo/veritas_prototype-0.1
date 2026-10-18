(() => {
  const articles = [...document.querySelectorAll('.document')];
  const navigation = [...document.querySelectorAll('.file-link')];
  const toc = document.getElementById('toc');
  const currentFile = document.getElementById('current-file');
  const source = document.getElementById('source-link');
  const published = location.hostname === 'elijahdelmundo.github.io';
  const repositorySource = 'https://github.com/elijahdelmundo/veritas_prototype-0.1/blob/main/';
  if (published) {
    for (const link of document.querySelectorAll('a[href^="../"]')) {
      const relative = link.getAttribute('href').slice(3);
      link.href = repositorySource + relative;
    }
  }

  function activate() {
    const hash = decodeURIComponent(location.hash.slice(1));
    const article = articles.find(item => hash === item.id || hash.startsWith(item.id + '-section-')) || articles[0];
    for (const item of articles) item.hidden = item !== article;
    for (const link of navigation) {
      if (link.hash === '#' + article.id) link.setAttribute('aria-current', 'page');
      else link.removeAttribute('aria-current');
    }
    currentFile.textContent = article.dataset.file;
    source.href = published ? repositorySource + article.dataset.file : '../' + article.dataset.file;
    document.title = article.dataset.title + ' · Veritas documentation';
    document.documentElement.style.setProperty('--accent', article.style.getPropertyValue('--accent'));
    document.documentElement.style.setProperty('--soft', article.style.getPropertyValue('--soft'));
    toc.replaceChildren();
    for (const heading of article.querySelectorAll('.doc-section > h2')) {
      const link = document.createElement('a');
      link.href = '#' + heading.id;
      link.textContent = heading.textContent.trim();
      toc.append(link);
    }
    const target = hash && document.getElementById(hash);
    requestAnimationFrame(() => {
      if (target && target !== article) target.scrollIntoView({behavior: 'auto', block: 'start'});
      else window.scrollTo({top: 0, behavior: 'auto'});
    });
  }
  window.addEventListener('hashchange', activate);
  navigation.forEach(link => link.addEventListener('click', () => {
    if (link.hash === location.hash) requestAnimationFrame(activate);
  }));
  document.getElementById('print-document').addEventListener('click', () => window.print());
  activate();
})();
