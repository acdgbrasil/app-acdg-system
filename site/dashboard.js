document.addEventListener("DOMContentLoaded", function () {
    var navItems = document.querySelectorAll(".sidebar-nav .nav-item[data-target]");
    var pages = document.querySelectorAll(".dashboard-page");

    // ── Navigation ─────────────────────────────────────────────
    navItems.forEach(function (item) {
        item.addEventListener("click", function (e) {
            e.preventDefault();
            var targetId = item.getAttribute("data-target");
            if (!targetId) return;
            if (item.classList.contains("active")) return;

            navItems.forEach(function (nav) { nav.classList.remove("active"); });
            item.classList.add("active");

            pages.forEach(function (page) {
                if (page.id === targetId) {
                    page.classList.add("active");
                } else {
                    page.classList.remove("active");
                }
            });

            // Trigger data load for the new page
            loadPageData(targetId);
        });
    });

    // ── Data Loading ───────────────────────────────────────────
    function loadPageData(pageId) {
        if (!CR || !CR.data) return;
        if (pageId === 'page-visao' && !CR.data.isLoaded('page-visao')) {
            CR.data.loadVisaoGeral();
        } else if (pageId === 'page-pacientes' && !CR.data.isLoaded('page-pacientes')) {
            CR.data.loadPacientes();
        }
    }

    // ── Search (debounced) ─────────────────────────────────────
    var searchInput = document.getElementById('search-input');
    var searchTimeout = null;
    if (searchInput) {
        searchInput.addEventListener('input', function () {
            clearTimeout(searchTimeout);
            var query = searchInput.value.trim();
            searchTimeout = setTimeout(function () {
                if (CR && CR.data) {
                    CR.data.searchPatients(query);
                }
            }, 300);
        });
    }

    // ── Init: load default page ────────────────────────────────
    var initialActive = document.querySelector(".dashboard-page.active") || document.getElementById("page-visao");
    if (initialActive) {
        initialActive.classList.add("active");
        loadPageData(initialActive.id);
    }
});
