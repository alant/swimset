using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;

class SwimSetApp extends Application.AppBase {
    private var _view;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        _view = new SwimSetView();
        return [_view, new SwimSetDelegate()];
    }

    function onSettingsChanged() {
        _lCache = {}; // Clear cache on settings change
        if (_view != null) {
            _view.loadSettings();
            WatchUi.requestUpdate();
        }
    }
}

// ── Localization Helper with Caching ─────────────────────────────────────────

var _lCache = {};
var _lCachedLang = null;

function L(id) {
    var lang = Application.Storage.getValue("AppLanguage");
    
    // -1 or null means System Default
    if (lang == null || lang == -1) {
        var sys = System.getDeviceSettings().systemLanguage;
        if (sys == 23 || sys == 24) { lang = 1; } // 23=CHS, 24=CHT
        else if (sys == 13) { lang = 2; } // 13=JPN
        else { lang = 0; }
    }

    // Reset cache if language changed manually
    if (lang != _lCachedLang) {
        _lCache = {};
        _lCachedLang = lang;
    }

    if (_lCache.hasKey(id)) {
        return _lCache[id];
    }

    var s = WatchUi.loadResource(id) as Toybox.Lang.String;
    var original = s;

    for (var i = 0; i < lang; i++) {
        var found = s.find("|");
        if (found != null) {
            s = s.substring(found + 1, s.length());
        } else {
            // Fallback to first part (English)
            var fallback = original.find("|");
            var res = (fallback != null) ? original.substring(0, fallback) : original;
            _lCache[id] = res;
            return res;
        }
    }
    
    var end = s.find("|");
    var finalRes = (end != null) ? s.substring(0, end) : s;
    _lCache[id] = finalRes;
    return finalRes;
}
