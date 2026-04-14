/**
 * Conecta Raros — Dashboard Data Layer
 * Maps API responses to DOM updates. Handles loading, error, and empty states.
 * Depends on: config.js, api-client.js
 */
(function () {
    'use strict';

    CR.data = {};

    var loadedPages = {};

    // ── DOM helpers ────────────────────────────────────────────────

    function $(id) { return document.getElementById(id); }

    function updateMetric(id, value) {
        var el = $(id);
        if (!el) return;
        el.textContent = value;
    }

    function updateMetricWithSub(id, value, sub) {
        var el = $(id);
        if (!el) return;
        el.innerHTML = '';
        el.appendChild(document.createTextNode(value));
        if (sub) {
            var span = document.createElement('span');
            span.className = 'sub';
            span.textContent = sub;
            el.appendChild(span);
        }
    }

    function setProgressBar(id, percent) {
        var el = $(id);
        if (!el) return;
        el.style.width = Math.min(100, Math.max(0, percent)) + '%';
    }

    function showLoading(pageId) {
        var overlay = $('loading-' + pageId);
        if (overlay) overlay.style.display = 'flex';
        var error = $('error-' + pageId);
        if (error) error.style.display = 'none';
    }

    function hideLoading(pageId) {
        var overlay = $('loading-' + pageId);
        if (overlay) overlay.style.display = 'none';
    }

    function showError(pageId, message, retryFn) {
        hideLoading(pageId);
        var container = $('error-' + pageId);
        if (!container) return;
        var msg = container.querySelector('.error-message');
        if (msg) msg.textContent = message || 'Não foi possível carregar os dados.';
        var btn = container.querySelector('.btn-retry');
        if (btn && retryFn) {
            btn.onclick = function () {
                container.style.display = 'none';
                retryFn();
            };
        }
        container.style.display = 'flex';
    }

    function showEmpty(containerId, message) {
        var el = $(containerId);
        if (!el) return;
        el.innerHTML =
            '<div class="empty-state">' +
                '<i class="ph ph-users" style="font-size:32px; opacity:0.3;"></i>' +
                '<p>' + (message || 'Nenhum paciente encontrado.') + '</p>' +
            '</div>';
    }

    function formatPatientId(id) {
        if (!id) return '—';
        return '#' + id.substring(0, 8).toUpperCase();
    }

    function formatName(patient) {
        if (patient.fullName) return patient.fullName;
        var parts = [];
        if (patient.firstName) parts.push(patient.firstName);
        if (patient.lastName) parts.push(patient.lastName);
        return parts.join(' ') || '—';
    }

    function formatDiagnosis(diag) {
        if (!diag) return null;
        return diag;
    }

    // ── render patient table ──────────────────────────────────────

    function renderPatientTable(containerId, patients, columns) {
        var container = $(containerId);
        if (!container) return;

        // Clear existing rows (keep head row)
        var rows = container.querySelectorAll('.table-row:not(.head)');
        rows.forEach(function (r) { r.remove(); });

        // Remove any empty-state
        var empty = container.querySelector('.empty-state');
        if (empty) empty.remove();

        if (!patients || patients.length === 0) {
            showEmpty(containerId, 'Nenhum paciente encontrado.');
            return;
        }

        patients.forEach(function (p) {
            var row = document.createElement('div');
            row.className = 'table-row';

            if (columns === 'visao') {
                // ID, Name, Diagnosis, Status
                row.innerHTML =
                    '<span>' + formatPatientId(p.patientId) + '</span>' +
                    '<span>' + formatName(p) + '</span>' +
                    '<span>' + (formatDiagnosis(p.primaryDiagnosis) || '—') + '</span>' +
                    '<span class="status-badge ' + (p.primaryDiagnosis ? 'success' : 'pending') + '">' +
                        (p.primaryDiagnosis ? 'Diagnosticado' : 'Em Análise') +
                    '</span>';
            } else {
                // Pacientes page: Name, Members, ID, Status
                row.innerHTML =
                    '<span>' + formatName(p) + '</span>' +
                    '<span>' + (p.memberCount || 0) + ' membro(s)</span>' +
                    '<span>' + formatPatientId(p.patientId) + '</span>' +
                    '<span class="status-badge ' + (p.primaryDiagnosis ? 'success' : 'pending') + '">' +
                        (p.primaryDiagnosis ? 'Ativo' : 'Aguardando IA') +
                    '</span>';
            }

            container.appendChild(row);
        });
    }

    // ── page loaders ──────────────────────────────────────────────

    /**
     * Load Visão Geral (Overview) page data
     */
    CR.data.loadVisaoGeral = function () {
        var pageId = 'page-visao';
        showLoading(pageId);

        // First check API connectivity via public /health endpoint
        CR.api.checkHealth().then(function (healthResult) {
            // Now try to load patients (may require auth)
            return CR.api.listPatients({ limit: 50 });
        }).then(function (result) {
            hideLoading(pageId);

            if (result.error) {
                if (result.error.status === 401 || result.error.status === 403) {
                    showError(pageId, 'Autenticação necessária. Configure o token JWT para acessar os dados de pacientes.', CR.data.loadVisaoGeral);
                } else {
                    showError(pageId, result.error.message, CR.data.loadVisaoGeral);
                }
                return;
            }

            var patients = result.data || [];
            var total = patients.length;
            var diagnosed = patients.filter(function (p) { return p.primaryDiagnosis; }).length;
            var pending = total - diagnosed;

            // Update metrics
            updateMetric('metric-total-registros', total.toLocaleString('pt-BR'));
            updateMetricWithSub('metric-sindromes', diagnosed, ' diagnosticados');
            updateMetric('metric-aguardando-visao', pending);

            // Update progress bar (diagnosed / total)
            var pct = total > 0 ? Math.round((diagnosed / total) * 100) : 0;
            setProgressBar('progress-sindromes', pct);
            var pctLabel = $('progress-sindromes-label');
            if (pctLabel) pctLabel.textContent = pct + '% DIAGNOSTICADOS';

            // Render recent patients table (first 5)
            renderPatientTable('table-novos-pacientes', patients.slice(0, 5), 'visao');

            loadedPages[pageId] = true;
        });
    };

    /**
     * Load Pacientes page data
     */
    CR.data.loadPacientes = function () {
        var pageId = 'page-pacientes';
        if (loadedPages[pageId]) return;
        showLoading(pageId);

        CR.api.listPatients({ limit: CR.config.PAGE_SIZE }).then(function (result) {
            hideLoading(pageId);

            if (result.error) {
                showError(pageId, result.error.message, function () {
                    loadedPages[pageId] = false;
                    CR.data.loadPacientes();
                });
                return;
            }

            var patients = result.data || [];
            var total = patients.length;
            var diagnosed = patients.filter(function (p) { return p.primaryDiagnosis; }).length;
            var pending = total - diagnosed;

            var totalMembers = patients.reduce(function (sum, p) { return sum + (p.memberCount || 0); }, 0);

            updateMetric('metric-total-pacientes', total.toLocaleString('pt-BR'));
            updateMetric('metric-diagnosticos', diagnosed.toLocaleString('pt-BR'));
            updateMetric('metric-aguardando', pending.toLocaleString('pt-BR'));
            updateMetric('metric-membros', totalMembers.toLocaleString('pt-BR'));

            renderPatientTable('table-todos-pacientes', patients, 'pacientes');

            loadedPages[pageId] = true;
        });
    };

    /**
     * Search patients (called from debounced input)
     */
    CR.data.searchPatients = function (query) {
        var activePage = document.querySelector('.dashboard-page.active');
        if (!activePage) return;

        var tableId = activePage.id === 'page-visao' ? 'table-novos-pacientes' : 'table-todos-pacientes';
        var columns = activePage.id === 'page-visao' ? 'visao' : 'pacientes';

        CR.api.listPatients({ search: query, limit: CR.config.PAGE_SIZE }).then(function (result) {
            if (result.error) return;
            renderPatientTable(tableId, result.data || [], columns);
        });
    };

    /**
     * Check if a page needs loading
     */
    CR.data.isLoaded = function (pageId) {
        return !!loadedPages[pageId];
    };

})();
