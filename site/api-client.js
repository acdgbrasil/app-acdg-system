/**
 * Conecta Raros — API Client
 * Thin wrapper over the Social Care REST API.
 * Depends on: config.js (CR.config)
 */
(function () {
    'use strict';

    CR.api = {};

    var TIMEOUT_MS = 8000;

    // ── private fetch helper ───────────────────────────────────────
    function _request(path, options) {
        var url = CR.config.API_BASE_URL.replace(/\/+$/, '') + path;
        var controller = new AbortController();
        var timer = setTimeout(function () { controller.abort(); }, TIMEOUT_MS);

        var headers = { 'Accept': 'application/json' };
        if (CR.config.API_TOKEN) {
            headers['Authorization'] = 'Bearer ' + CR.config.API_TOKEN;
        }

        var opts = Object.assign({ method: 'GET', headers: headers, signal: controller.signal }, options || {});

        return fetch(url, opts)
            .then(function (res) {
                clearTimeout(timer);
                if (!res.ok) {
                    return res.json().catch(function () { return {}; }).then(function (body) {
                        return { data: null, error: { status: res.status, message: body.error || res.statusText } };
                    });
                }
                if (res.status === 204) return { data: null, error: null };
                return res.json().then(function (json) {
                    return { data: json.data !== undefined ? json.data : json, meta: json.meta || null, error: null };
                });
            })
            .catch(function (err) {
                clearTimeout(timer);
                if (err.name === 'AbortError') {
                    return { data: null, error: { status: 0, message: 'Tempo limite excedido' } };
                }
                return { data: null, error: { status: 0, message: err.message || 'Erro de rede' } };
            });
    }

    // ── build query string ─────────────────────────────────────────
    function _qs(params) {
        var parts = [];
        for (var key in params) {
            if (params[key] !== undefined && params[key] !== null && params[key] !== '') {
                parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(params[key]));
            }
        }
        return parts.length ? '?' + parts.join('&') : '';
    }

    // ── public API ─────────────────────────────────────────────────

    /**
     * GET /health — liveness check (no auth required)
     */
    CR.api.checkHealth = function () {
        return _request('/health');
    };

    /**
     * GET /ready — readiness check (no auth required)
     */
    CR.api.checkReady = function () {
        return _request('/ready');
    };

    /**
     * GET /patients — list patients with cursor-based pagination
     * @param {Object} opts - { search, cursor, limit }
     * @returns {Promise<{data: PatientSummaryResponse[], meta, error}>}
     */
    CR.api.listPatients = function (opts) {
        opts = opts || {};
        var params = {
            search: opts.search,
            cursor: opts.cursor,
            limit: opts.limit || CR.config.PAGE_SIZE
        };
        return _request('/patients' + _qs(params));
    };

    /**
     * GET /patients/:id — full patient record
     * @param {string} patientId
     * @returns {Promise<{data: PatientResponse, meta, error}>}
     */
    CR.api.getPatient = function (patientId) {
        return _request('/patients/' + encodeURIComponent(patientId));
    };

    /**
     * GET /patients/:id/audit-trail — event history
     * @param {string} patientId
     * @param {string} [eventType] — optional filter
     * @returns {Promise<{data: AuditTrailEntryResponse[], meta, error}>}
     */
    CR.api.getAuditTrail = function (patientId, eventType) {
        var params = { eventType: eventType };
        return _request('/patients/' + encodeURIComponent(patientId) + '/audit-trail' + _qs(params));
    };

})();
