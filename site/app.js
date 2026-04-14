document.addEventListener("DOMContentLoaded", () => {

    // ============================================
    // HEADER SCROLL STATE
    // ============================================
    const siteHeader = document.getElementById('site-header');
    if (siteHeader) {
        const onHeaderScroll = () => {
            if (window.scrollY > 40) {
                siteHeader.classList.add('scrolled');
            } else {
                siteHeader.classList.remove('scrolled');
            }
        };
        window.addEventListener('scroll', onHeaderScroll, { passive: true });
        onHeaderScroll(); // run once on load
    }

    // ============================================
    // MOBILE MENU TOGGLE
    // ============================================
    const menuToggle = document.getElementById('menu-toggle');
    const mobileMenu = document.getElementById('mobile-menu');

    if (menuToggle && mobileMenu) {
        const closeMenu = () => {
            mobileMenu.classList.remove('open');
            menuToggle.classList.remove('open');
            menuToggle.setAttribute('aria-expanded', 'false');
            mobileMenu.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = '';
        };

        menuToggle.addEventListener('click', () => {
            const isOpen = mobileMenu.classList.toggle('open');
            menuToggle.classList.toggle('open');
            menuToggle.setAttribute('aria-expanded', String(isOpen));
            mobileMenu.setAttribute('aria-hidden', String(!isOpen));
            document.body.style.overflow = isOpen ? 'hidden' : '';
        });

        // Close on link click
        mobileMenu.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', closeMenu);
        });

        // Close on Escape
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && mobileMenu.classList.contains('open')) {
                closeMenu();
            }
        });
    }

    // ============================================
    // WHATSAPP FLOAT BUTTON
    // ============================================
    const whatsappBtn = document.querySelector('.whatsapp-float');
    if (whatsappBtn) {
        window.addEventListener('scroll', () => {
            if (window.scrollY > 100) {
                whatsappBtn.classList.remove('hidden');
            } else {
                whatsappBtn.classList.add('hidden');
            }
        }, { passive: true });
    }

    // ============================================
    // PHYSICS-WEIGHT SCROLL REVEALS
    // Elements tagged with data-weight="heavy" use longer durations.
    // H1/display text auto-gets heavy; small labels get light.
    // ============================================
    const HEAVY_SELECTORS = ['h1', 'h2', '.hero-title', '.section-title', '.huge-metric'];
    const LIGHT_SELECTORS = ['.eyebrow', '.section-label', '.badge', '.faq-number'];

    const revealElements = document.querySelectorAll('.reveal-up');

    revealElements.forEach(el => {
        // Auto-assign weight class if not already set
        if (!el.classList.contains('heavy') && !el.classList.contains('light')) {
            const isHeavy = HEAVY_SELECTORS.some(sel => el.matches(sel) || el.querySelector(sel));
            const isLight = LIGHT_SELECTORS.some(sel => el.matches(sel));
            if (isHeavy) el.classList.add('heavy');
            else if (isLight) el.classList.add('light');
        }
    });

    const observerOptions = {
        root: null,
        rootMargin: '0px 0px -48px 0px',
        threshold: 0.08
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    revealElements.forEach(el => observer.observe(el));

    // ============================================
    // FAQ SMOOTH ACCORDION
    // Uses grid-template-rows: 0fr ↔ 1fr for CSS-only height animation.
    // ============================================
    document.querySelectorAll('details.faq-item').forEach(detail => {
        const summary = detail.querySelector('summary');
        const content = detail.querySelector('.faq-content');
        if (!summary || !content) return;

        summary.addEventListener('click', (e) => {
            e.preventDefault();

            if (detail.hasAttribute('open')) {
                // CLOSING: CSS .closing rule triggers 0fr transition, then remove [open]
                detail.classList.add('closing');
                setTimeout(() => {
                    detail.removeAttribute('open');
                    detail.classList.remove('closing');
                }, 460);
            } else {
                // OPENING: start collapsed, then release to CSS transition
                content.style.transition = 'none';
                content.style.gridTemplateRows = '0fr';
                content.style.opacity = '0';

                detail.setAttribute('open', '');

                requestAnimationFrame(() => {
                    requestAnimationFrame(() => {
                        content.style.transition = '';
                        content.style.gridTemplateRows = '';
                        content.style.opacity = '';
                    });
                });
            }
        });
    });

    // ============================================
    // SCROLL PARALLAX — data-parallax="0.2"
    // Elements move at (scrollY * factor) on the Y axis.
    // Runs in a single rAF loop for performance.
    // ============================================
    function initParallaxScroll() {
        const parallaxEls = document.querySelectorAll('[data-parallax]');
        if (!parallaxEls.length) return;

        const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (prefersReducedMotion) return;

        let ticking = false;

        const applyParallax = () => {
            const scrollY = window.scrollY;
            parallaxEls.forEach(el => {
                const factor = parseFloat(el.dataset.parallax) || 0.1;
                const rect = el.getBoundingClientRect();
                const elCenterY = rect.top + rect.height / 2 + scrollY;
                const offset = (scrollY - elCenterY + window.innerHeight * 0.5) * factor;
                el.style.transform = `translateY(${offset.toFixed(2)}px)`;
            });
            ticking = false;
        };

        window.addEventListener('scroll', () => {
            if (!ticking) {
                requestAnimationFrame(applyParallax);
                ticking = true;
            }
        }, { passive: true });

        applyParallax(); // Initial position
    }

    initParallaxScroll();

    // ============================================
    // CURSOR GLOW — desktop only
    // A warm subtle radial glow that follows the cursor.
    // ============================================
    function initCursorGlow() {
        const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
        const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (isTouchDevice || prefersReducedMotion) return;

        const glow = document.createElement('div');
        glow.id = 'cursor-glow';
        glow.setAttribute('aria-hidden', 'true');
        Object.assign(glow.style, {
            position: 'fixed',
            top: '0',
            left: '0',
            width: '480px',
            height: '480px',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(230,92,59,0.06) 0%, transparent 70%)',
            pointerEvents: 'none',
            zIndex: '9999',
            transform: 'translate(-50%, -50%)',
            transition: 'opacity 0.4s ease',
            opacity: '0',
            willChange: 'transform',
        });
        document.body.appendChild(glow);

        let curX = 0, curY = 0;
        let glowX = 0, glowY = 0;
        let visible = false;
        let rafId = null;

        const lerp = (a, b, t) => a + (b - a) * t;

        const animateGlow = () => {
            glowX = lerp(glowX, curX, 0.08);
            glowY = lerp(glowY, curY, 0.08);
            glow.style.transform = `translate(calc(${glowX}px - 50%), calc(${glowY}px - 50%))`;
            rafId = requestAnimationFrame(animateGlow);
        };

        document.addEventListener('mousemove', (e) => {
            curX = e.clientX;
            curY = e.clientY;
            if (!visible) {
                glow.style.opacity = '1';
                visible = true;
                if (!rafId) animateGlow();
            }
        });

        document.addEventListener('mouseleave', () => {
            glow.style.opacity = '0';
            visible = false;
        });
    }

    initCursorGlow();

    // ============================================
    // HULY-STYLE HERO PARALLAX & 3D TILT
    // ============================================
    const heroSection = document.getElementById('hero-section');
    if (heroSection) {
        const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
        const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        if (!isTouchDevice && !prefersReducedMotion) {
            const heroArc = heroSection.querySelector('.hero-arc');
            const parallaxLayers = heroSection.querySelectorAll('.hero-parallax-layer');

            let rafId = null;
            let isHovering = false;

            heroSection.addEventListener('mousemove', (e) => {
                if (rafId) return;
                isHovering = true;

                rafId = requestAnimationFrame(() => {
                    const rect = heroSection.getBoundingClientRect();
                    const centerX = rect.left + rect.width / 2;
                    const centerY = rect.top + rect.height / 2;

                    let mx = (e.clientX - centerX) / (rect.width / 2);
                    let my = (e.clientY - centerY) / (rect.height / 2);
                    mx = Math.max(-1, Math.min(1, mx));
                    my = Math.max(-1, Math.min(1, my));

                    if (heroArc) {
                        const tx = mx * 6;
                        const ty = my * 4;
                        const tiltY = mx * 5;
                        const tiltX = -my * 3;
                        heroArc.style.transform =
                            `translateY(-50%) rotate(45deg) scale(1) translate(${tx}px,${ty}px) rotateY(${tiltY}deg) rotateX(${tiltX}deg)`;
                        heroArc.style.boxShadow =
                            `${-mx * 10}px ${-my * 6 + 22}px 90px rgba(230,92,59,0.10)`;
                    }

                    parallaxLayers.forEach(layer => {
                        const depth = parseFloat(layer.dataset.depth) || 0.002;
                        const px = mx * depth * 400;
                        const py = my * depth * 300;
                        layer.style.transform = `translate(${px}px, ${py}px)`;
                    });

                    rafId = null;
                });
            });

            heroSection.addEventListener('mouseleave', () => {
                isHovering = false;
                if (rafId) { cancelAnimationFrame(rafId); rafId = null; }

                const resetTransition = 'transform 0.6s cubic-bezier(0.16,1,0.3,1), box-shadow 0.6s ease-out';
                if (heroArc) {
                    heroArc.style.transition = resetTransition;
                    heroArc.style.transform = 'translateY(-50%) rotate(45deg) scale(1)';
                    heroArc.style.boxShadow = '0 20px 60px rgba(230,92,59,0.08)';
                }
                parallaxLayers.forEach(layer => {
                    layer.style.transition = resetTransition;
                    layer.style.transform = 'translate(0,0)';
                });

                setTimeout(() => {
                    if (!isHovering) {
                        const fastTransition = 'transform 0.15s ease-out, box-shadow 0.15s ease-out';
                        if (heroArc) heroArc.style.transition = fastTransition;
                        parallaxLayers.forEach(layer => { layer.style.transition = fastTransition; });
                    }
                }, 620);
            });
        }
    }

});
