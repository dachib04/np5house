// NP5.HOUSE — EN / LT language switcher
(function () {
  function t(key, lang) {
    const entry = window.I18N && window.I18N[key];
    if (!entry) return null;
    return entry[lang] != null ? entry[lang] : entry.en;
  }

  function applyLang(lang) {
    document.documentElement.setAttribute('lang', lang);

    document.querySelectorAll('[data-i18n]').forEach(el => {
      const val = t(el.getAttribute('data-i18n'), lang);
      if (val != null) el.textContent = val;
    });
    document.querySelectorAll('[data-i18n-html]').forEach(el => {
      const val = t(el.getAttribute('data-i18n-html'), lang);
      if (val != null) el.innerHTML = val;
    });
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
      const val = t(el.getAttribute('data-i18n-placeholder'), lang);
      if (val != null) el.setAttribute('placeholder', val);
    });
    document.querySelectorAll('[data-i18n-alt]').forEach(el => {
      const val = t(el.getAttribute('data-i18n-alt'), lang);
      if (val != null) el.setAttribute('alt', val);
    });
    document.querySelectorAll('[data-i18n-title]').forEach(el => {
      const val = t(el.getAttribute('data-i18n-title'), lang);
      if (val != null) el.setAttribute('title', val);
    });

    document.querySelectorAll('.nav-lang').forEach(btn => {
      btn.textContent = lang === 'lt' ? '🇱🇹' : '🇬🇧';
      btn.setAttribute('aria-label', 'Language');
    });
    document.querySelectorAll('.nav-lang-opt').forEach(opt => {
      opt.classList.toggle('active', opt.getAttribute('data-lang') === lang);
    });

    try { localStorage.setItem('np5-lang', lang); } catch (e) {}
    document.dispatchEvent(new CustomEvent('np5langchange', { detail: { lang } }));
  }

  function currentLang() {
    return document.documentElement.getAttribute('lang') === 'lt' ? 'lt' : 'en';
  }

  function closeAllMenus() {
    document.querySelectorAll('.nav-lang-wrap.open').forEach(w => w.classList.remove('open'));
  }

  function initI18n() {
    let saved = 'en';
    try { saved = localStorage.getItem('np5-lang') || 'en'; } catch (e) {}
    applyLang(saved);

    document.querySelectorAll('.nav-lang-wrap').forEach(wrap => {
      const btn = wrap.querySelector('.nav-lang');
      if (btn) {
        btn.addEventListener('click', e => {
          e.stopPropagation();
          const willOpen = !wrap.classList.contains('open');
          closeAllMenus();
          if (willOpen) wrap.classList.add('open');
        });
      }
      wrap.querySelectorAll('.nav-lang-opt').forEach(opt => {
        opt.addEventListener('click', e => {
          e.stopPropagation();
          applyLang(opt.getAttribute('data-lang'));
          closeAllMenus();
        });
      });
    });

    document.addEventListener('click', closeAllMenus);
    document.addEventListener('keydown', e => { if (e.key === 'Escape') closeAllMenus(); });
  }

  window.NP5_I18N = { applyLang, currentLang };
  document.addEventListener('DOMContentLoaded', initI18n);
})();
