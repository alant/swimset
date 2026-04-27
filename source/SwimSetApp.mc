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
        _lCache = {} as Toybox.Lang.Dictionary<Toybox.Lang.Symbol, Toybox.Lang.String>; // Clear cache on settings change
        if (_view != null) {
            _view.loadSettings();
            WatchUi.requestUpdate();
        }
    }
}

// ── Localization Helper with Caching ─────────────────────────────────────────

var _lCache as Toybox.Lang.Dictionary<Toybox.Lang.Symbol, Toybox.Lang.String> = {} as Toybox.Lang.Dictionary<Toybox.Lang.Symbol, Toybox.Lang.String>;
var _lCachedLang as Toybox.Lang.Number or Null = null;

function L(id as Toybox.Lang.Symbol) as Toybox.Lang.String {
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
        _lCache = {} as Toybox.Lang.Dictionary<Toybox.Lang.Symbol, Toybox.Lang.String>;
        _lCachedLang = lang;
    }

    if (_lCache.hasKey(id)) {
        return _lCache.get(id) as Toybox.Lang.String;
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
            _lCache.put(id, res);
            return res;
        }
    }
    
    var end = s.find("|");
    var finalRes = (end != null) ? s.substring(0, end) : s;
    _lCache.put(id, finalRes);
    return finalRes;
}
