// NP5.HOUSE — shared scripts

function initCursor() {
  const cur = document.getElementById('cur');
  const ring = document.getElementById('ring');
  if (!cur || !ring) return;
  let mx = 0, my = 0, rx = 0, ry = 0;
  document.addEventListener('mousemove', e => {
    mx = e.clientX; my = e.clientY;
    cur.style.left = mx + 'px'; cur.style.top = my + 'px';
  });
  (function tick() {
    rx += (mx - rx) * 0.12; ry += (my - ry) * 0.12;
    ring.style.left = rx + 'px'; ring.style.top = ry + 'px';
    requestAnimationFrame(tick);
  })();
  document.querySelectorAll('a,button').forEach(el => {
    el.addEventListener('mouseenter', () => { cur.classList.add('h'); ring.classList.add('h'); });
    el.addEventListener('mouseleave', () => { cur.classList.remove('h'); ring.classList.remove('h'); });
  });
}

function initNav(threshold = 80) {
  const nav = document.getElementById('nav');
  if (!nav) return;
  const update = () => nav.classList.toggle('solid', window.scrollY > threshold);
  window.addEventListener('scroll', update, { passive: true });
  update();
}

function initMobileNav() {
  const toggle = document.getElementById('navToggle');
  const drawer = document.getElementById('navDrawer');
  if (!toggle || !drawer) return;
  toggle.addEventListener('click', () => {
    const open = toggle.classList.toggle('open');
    drawer.classList.toggle('open', open);
    document.body.style.overflow = open ? 'hidden' : '';
  });
  drawer.querySelectorAll('a').forEach(a => a.addEventListener('click', () => {
    toggle.classList.remove('open');
    drawer.classList.remove('open');
    document.body.style.overflow = '';
  }));
}

function initScrollReveal(threshold = 0.08) {
  const obs = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('on');
        obs.unobserve(entry.target);
      }
    });
  }, { threshold });
  document.querySelectorAll('.r').forEach(el => obs.observe(el));
}

function initImageSlider() {
  const imgs = document.querySelectorAll('.js-img');
  const thumbs = document.querySelectorAll('.js-thumb');
  const counter = document.getElementById('jsCurrent');
  if (!imgs.length) return;
  let current = 0;

  function goTo(n) {
    imgs[current].classList.remove('active');
    thumbs[current]?.classList.remove('active');
    current = (n + imgs.length) % imgs.length;
    imgs[current].classList.add('active');
    thumbs[current]?.classList.add('active');
    if (counter) counter.textContent = current + 1;
  }

  document.querySelector('.js-prev')?.addEventListener('click', () => goTo(current - 1));
  document.querySelector('.js-next')?.addEventListener('click', () => goTo(current + 1));
  thumbs.forEach((t, i) => t.addEventListener('click', () => goTo(i)));
  document.addEventListener('keydown', e => {
    if (e.key === 'ArrowLeft') goTo(current - 1);
    if (e.key === 'ArrowRight') goTo(current + 1);
  });

  // Touch / swipe
  let touchStartX = 0;
  const slider = document.querySelector('.jslider-main');
  if (slider) {
    slider.addEventListener('touchstart', e => { touchStartX = e.touches[0].clientX; }, { passive: true });
    slider.addEventListener('touchend', e => {
      const dx = touchStartX - e.changedTouches[0].clientX;
      if (Math.abs(dx) > 40) goTo(current + (dx > 0 ? 1 : -1));
    });
  }

  // Auto-advance
  setInterval(() => goTo(current + 1), 5500);
}

document.addEventListener('DOMContentLoaded', () => {
  initCursor();
  initNav();
  initMobileNav();
  initScrollReveal();
  initImageSlider();
});
