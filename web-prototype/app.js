(() => {
  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const app = $('#app');
  const appScroll = $('#appScroll');
  const player = $('#player');
  const playerVideo = $('#playerVideo');
  const playerControls = $('#playerControls');
  const seekRipple = $('#seekRipple');
  const lockBadge = $('#lockBadge');
  const psheet = $('#psheet');
  const psheetBackdrop = $('#psheetBackdrop');
  const psheetTitle = $('#psheetTitle');
  const psheetBody = $('#psheetBody');
  const toastEl = $('#toast');
  const homeFeed = $('#homeFeed');
  const searchInput = $('#searchInput');
  const searchResultsLabel = $('#searchResultsLabel');
  const topQuality = $('#topQuality');
  const pcQuality = $('#pcQuality');
  const pcSpeed = $('#pcSpeed');
  const pcInterp = $('#pcInterp');
  const pcEnhance = $('#pcEnhance');
  const specPage = $('#specPage');
  const specPlatform = $('#specPlatform');

  const pageNames = {
    home: '首页',
    search: '搜索',
    detail: '详情',
    dynamic: '动态',
    messages: '消息',
    my: '我的'
  };

  let activePage = 'home';
  let playerOpen = false;
  let locked = false;
  let hideTimer = null;
  let clickTimer = null;
  let toastTimer = null;

  function showToast(message) {
    toastEl.textContent = message;
    toastEl.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastEl.classList.remove('show'), 1800);
  }

  function showPage(page) {
    activePage = page;
    $$('.page').forEach((section) => {
      section.classList.toggle('active', section.dataset.page === page);
    });
    app.dataset.page = page;
    appScroll.scrollTop = 0;

    const rootIndex = ['home', 'dynamic', 'messages', 'my'].indexOf(page);
    if (rootIndex >= 0) {
      app.style.setProperty('--tab', String(rootIndex));
    }
    $$('.tabbar .tab').forEach((tab) => {
      tab.classList.toggle('on', tab.dataset.page === page);
    });
    specPage.textContent = pageNames[page] || page;

    if (page === 'search') {
      setTimeout(() => searchInput.focus(), 140);
    }
  }

  function showControls() {
    playerControls.classList.remove('hidden');
    scheduleHide();
  }

  function scheduleHide() {
    clearTimeout(hideTimer);
    if (locked) return;
    hideTimer = setTimeout(() => {
      if (playerOpen && !locked) playerControls.classList.add('hidden');
    }, 3000);
  }

  function openPlayer() {
    player.classList.add('open');
    player.setAttribute('aria-hidden', 'false');
    playerOpen = true;
    locked = false;
    lockBadge.classList.remove('show');
    showControls();
    closeSheet();
    if (screen.orientation && screen.orientation.lock) {
      screen.orientation.lock('landscape').catch(() => {});
    }
  }

  function closePlayer() {
    player.classList.remove('open');
    player.setAttribute('aria-hidden', 'true');
    playerOpen = false;
    locked = false;
    lockBadge.classList.remove('show');
    clearTimeout(hideTimer);
    closeSheet();
    if (screen.orientation && screen.orientation.unlock) {
      try { screen.orientation.unlock(); } catch (_) {}
    }
  }

  function showRipple(text, leftPercent) {
    seekRipple.textContent = text;
    seekRipple.style.left = leftPercent + '%';
    seekRipple.classList.remove('go');
    void seekRipple.offsetWidth;
    seekRipple.classList.add('go');
  }

  const sheetData = {
    quality: {
      title: '画质',
      sub: '占位选项，不加载任何媒体',
      options: [
        { label: '4K 占位', meta: '大会员档（占位）' },
        { label: '1080P60 占位', meta: '当前' },
        { label: '1080P 占位', meta: '' },
        { label: '720P 占位', meta: '' },
        { label: '仅音频占位', meta: '' }
      ],
      apply(label) {
        topQuality.textContent = label.replace(' 占位', '');
        pcQuality.textContent = label.replace(' 占位', '');
      }
    },
    speed: {
      title: '倍速',
      sub: '占位选项，不改变实际播放',
      options: [
        { label: '0.5×', meta: '' },
        { label: '1.0×', meta: '当前' },
        { label: '1.25×', meta: '' },
        { label: '1.5×', meta: '' },
        { label: '2.0×', meta: '' }
      ],
      apply(label) { pcSpeed.textContent = label; }
    },
    interp: {
      title: '插帧',
      sub: '目标帧率占位；实际能力由屏幕/设备决定',
      options: [
        { label: '关', meta: '' },
        { label: '60', meta: '' },
        { label: '90', meta: '' },
        { label: '120', meta: '当前' },
        { label: '自动', meta: '跟随屏幕' }
      ],
      apply(label) { pcInterp.textContent = '插帧 ' + label; }
    },
    enhance: {
      title: '增强',
      sub: '占位选项，不加载实际 shader',
      options: [
        { label: '关', meta: '' },
        { label: 'CAS', meta: '当前' },
        { label: 'Anime4K', meta: '高负载（占位）' }
      ],
      apply(label) { pcEnhance.textContent = label; }
    }
  };

  function openSheet(kind) {
    const data = sheetData[kind];
    if (!data) return;
    psheetTitle.textContent = data.title;
    psheetBody.innerHTML = '';
    const sub = document.createElement('div');
    sub.className = 'psheet-sub';
    sub.textContent = data.sub;
    psheetBody.appendChild(sub);

    data.options.forEach((option) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'opt';
      if (option.meta === '当前') button.classList.add('on');
      button.innerHTML = `<span>${option.label}</span><span class="meta">${option.meta || ''}</span>`;
      button.addEventListener('click', () => {
        data.apply(option.label);
        closeSheet();
        showToast(`${data.title}：${option.label}（占位）`);
      });
      psheetBody.appendChild(button);
    });

    psheet.classList.add('open');
    psheetBackdrop.classList.add('show');
  }

  function closeSheet() {
    psheet.classList.remove('open');
    psheetBackdrop.classList.remove('show');
  }

  /* page navigation */
  $$('.tabbar .tab').forEach((tab) => {
    tab.addEventListener('click', () => showPage(tab.dataset.page));
  });
  $$('[data-goto]').forEach((button) => {
    button.addEventListener('click', () => showPage(button.dataset.goto));
  });
  $$('[data-back-home]').forEach((button) => {
    button.addEventListener('click', () => showPage('home'));
  });
  $$('[data-open-detail]').forEach((button) => {
    button.addEventListener('click', () => showPage('detail'));
  });
  $$('[data-open-player]').forEach((button) => {
    button.addEventListener('click', openPlayer);
  });

  const searchBtn = $('#searchBtn');
  if (searchBtn) searchBtn.addEventListener('click', () => showPage('search'));
  const searchCancel = $('#searchCancel');
  if (searchCancel) searchCancel.addEventListener('click', () => showPage('home'));

  /* mini player */
  const mini = $('#mini');
  if (mini) {
    mini.addEventListener('click', openPlayer);
    const close = $('.mini-close', mini);
    if (close) {
      close.addEventListener('click', (event) => {
        event.stopPropagation();
        mini.classList.add('dismissed');
        showToast('已关闭占位播放器');
      });
    }
  }

  /* chips */
  $$('.chips').forEach((group) => {
    $$('.chip', group).forEach((chip) => {
      chip.addEventListener('click', () => {
        $$('.chip', group).forEach((item) => item.classList.remove('on'));
        chip.classList.add('on');
      });
    });
  });

  /* detail tabs */
  $$('.detail-tabs').forEach((group) => {
    $$('button', group).forEach((button) => {
      button.addEventListener('click', () => {
        $$('button', group).forEach((item) => item.classList.remove('on'));
        button.classList.add('on');
      });
    });
  });

  /* refresh placeholder */
  const refreshBtn = $('#refreshBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      homeFeed.classList.add('refreshing');
      showToast('刷新占位');
      setTimeout(() => homeFeed.classList.remove('refreshing'), 720);
    });
  }

  /* search placeholder */
  if (searchInput) {
    searchInput.addEventListener('input', () => {
      const value = searchInput.value.trim();
      searchResultsLabel.textContent = value ? `搜索结果（占位 · ${value}）` : '搜索结果（占位）';
    });
    searchInput.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault();
        showToast('搜索占位：不请求真实接口');
        searchInput.blur();
      }
    });
  }

  /* generic placeholder toast */
  $$('[data-toast]').forEach((button) => {
    button.addEventListener('click', () => showToast(button.dataset.toast));
  });

  /* platform materials */
  $$('#platformSwitch button').forEach((button) => {
    button.addEventListener('click', () => {
      const platform = button.dataset.platform;
      document.body.dataset.platform = platform;
      $$('#platformSwitch button').forEach((item) => item.classList.toggle('on', item === button));
      specPlatform.textContent = platform === 'ios' ? 'iOS 26+ Liquid Glass' : 'Android 12+ 自写磨砂';
      showToast(platform === 'ios' ? 'iOS：原生玻璃材质' : 'Android：自写磨砂材质');
    });
  });

  const labelsBtn = $('#labelsBtn');
  if (labelsBtn) {
    labelsBtn.addEventListener('click', () => {
      document.body.classList.toggle('no-labels');
      labelsBtn.classList.toggle('on');
    });
  }

  const gridBtn = $('#gridBtn');
  if (gridBtn) {
    gridBtn.addEventListener('click', () => {
      document.body.classList.toggle('grid');
      gridBtn.classList.toggle('on');
    });
  }

  const motionBtn = $('#motionBtn');
  if (motionBtn) {
    motionBtn.addEventListener('click', () => {
      document.body.classList.toggle('reduce-motion');
      motionBtn.classList.toggle('on');
      showToast(document.body.classList.contains('reduce-motion') ? '动效：减少' : '动效：恢复');
    });
  }

  const landscapeBtn = $('#landscapeBtn');
  if (landscapeBtn) landscapeBtn.addEventListener('click', openPlayer);

  /* player */
  const playerBack = $('#playerBack');
  if (playerBack) playerBack.addEventListener('click', closePlayer);
  const pcExit = $('#pcExit');
  if (pcExit) pcExit.addEventListener('click', closePlayer);

  const pcPlay = $('#pcPlay');
  if (pcPlay) {
    pcPlay.addEventListener('click', () => {
      pcPlay.textContent = pcPlay.textContent === '▶' ? 'Ⅱ' : '▶';
      showToast('无播放源 · 仅交互占位');
      showControls();
    });
  }

  const pcDanmaku = $('#pcDanmaku');
  if (pcDanmaku) {
    pcDanmaku.addEventListener('click', () => {
      pcDanmaku.classList.toggle('on');
      showToast(pcDanmaku.classList.contains('on') ? '弹幕：开（占位）' : '弹幕：关（占位）');
      showControls();
    });
  }

  const pcLock = $('#pcLock');
  if (pcLock) {
    pcLock.addEventListener('click', () => {
      locked = true;
      clearTimeout(hideTimer);
      playerControls.classList.add('hidden');
      lockBadge.classList.add('show');
    });
  }

  if (lockBadge) {
    lockBadge.addEventListener('click', () => {
      locked = false;
      lockBadge.classList.remove('show');
      showControls();
    });
  }

  $$('[data-sheet]').forEach((button) => {
    button.addEventListener('click', () => openSheet(button.dataset.sheet));
  });
  if (psheetBackdrop) psheetBackdrop.addEventListener('click', closeSheet);
  const psheetClose = $('#psheetClose');
  if (psheetClose) psheetClose.addEventListener('click', closeSheet);

  if (playerVideo) {
    playerVideo.addEventListener('click', (event) => {
      if (locked || event.target.closest('.player-controls')) return;
      if (clickTimer) return;
      clickTimer = setTimeout(() => {
        clickTimer = null;
        if (playerControls.classList.contains('hidden')) showControls();
        else {
          playerControls.classList.add('hidden');
          clearTimeout(hideTimer);
        }
      }, 220);
    });

    playerVideo.addEventListener('dblclick', (event) => {
      if (locked || event.target.closest('.player-controls')) return;
      clearTimeout(clickTimer);
      clickTimer = null;
      const rect = playerVideo.getBoundingClientRect();
      const right = event.clientX > rect.left + rect.width / 2;
      showRipple(right ? '+10s' : '-10s', right ? 72 : 28);
      showControls();
    });
  }

  const playerStage = $('#playerStage');
  if (playerStage) {
    playerStage.addEventListener('pointermove', () => {
      if (playerOpen && !locked) showControls();
    });
  }
  if (playerControls) {
    playerControls.addEventListener('pointerenter', () => clearTimeout(hideTimer));
    playerControls.addEventListener('pointerleave', () => scheduleHide());
  }

  /* rail placeholders */
  const railContent = {
    info: '信息占位',
    episodes: '选集占位',
    comments: '评论占位',
    settings: '设置占位'
  };
  $$('.rail-tabs button').forEach((button) => {
    button.addEventListener('click', () => {
      $$('.rail-tabs button').forEach((item) => item.classList.remove('on'));
      button.classList.add('on');
      const railBody = $('#railBody');
      railBody.innerHTML = `
        <div class="rail-placeholder">
          <span class="ph-label">${railContent[button.dataset.rail]}</span>
          <div class="ph-title">
            <span class="ph-line w85"></span>
            <span class="ph-line w60"></span>
            <span class="ph-line w40"></span>
          </div>
          <div class="ph-title" style="margin-top:16px">
            <span class="ph-line w70"></span>
            <span class="ph-line w50"></span>
          </div>
        </div>`;
    });
  });

  /* keyboard */
  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') return;
    if (psheet.classList.contains('open')) {
      closeSheet();
      return;
    }
    if (playerOpen) {
      closePlayer();
      return;
    }
    if (activePage === 'search' || activePage === 'detail') {
      showPage('home');
    }
  });

  showPage('home');
})();
