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
        if (_view != null) {
            _view.loadSettings();
            WatchUi.requestUpdate();
        }
    }
}

// ── Localization Helper ──────────────────────────────────────────────────────

function L(id) {
    var s = WatchUi.loadResource(id) as Toybox.Lang.String;
    var lang = Application.Storage.getValue("AppLanguage");
    
    // -1 or null means System Default
    if (lang == null || lang == -1) {
        var sys = System.getDeviceSettings().systemLanguage;
        if (sys == 23 || sys == 24) { lang = 1; } // 23=CHS, 24=CHT
        else if (sys == 13) { lang = 2; } // 13=JPN
        else { lang = 0; }
    }

    var start = 0;
    for (var i = 0; i < lang; i++) {
        var found = s.find("|");
        if (found != null) {
            start += found + 1;
            s = s.substring(found + 1, s.length());
        } else {
            // If we're looking for index 1 or 2 but there's no |, return the whole thing (English)
            s = WatchUi.loadResource(id) as Toybox.Lang.String;
            var fallback = s.find("|");
            return (fallback != null) ? s.substring(0, fallback) : s;
        }
    }
    
    var end = s.find("|");
    return (end != null) ? s.substring(0, end) : s;
}
