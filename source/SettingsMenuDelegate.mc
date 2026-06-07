using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;

// ── Training settings menu ───────────────────────────────────────────────────
// saveAction controls Back behaviour:
//   null          → in-workout (Back just dismisses)
//   String        → Create flow: createFromGlobalWithName(name) on Back
//   Number        → Edit flow: copyFromGlobal(index) on Back
class SwimSetSettingsDelegate extends WatchUi.Menu2InputDelegate {
    private var _mainView;
    private var _saveAction; // null | String (new name) | Number (training index)

    function initialize(mainView, saveAction) {
        Menu2InputDelegate.initialize();
        _mainView = mainView;
        _saveAction = saveAction;
    }

    function onSelect(item) {
        var idx = item.getId();
        if (idx == :finish) {
            _save();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return;
        } else if (idx == :poolSize) {
            pushOptions(L(Rez.Strings.PoolSize), "PoolSize", [10, 15, 20, 25, 50], null, item);
        } else if (idx == :poolUnit) {
            pushOptions(L(Rez.Strings.PoolUnit), "PoolUnit", [0, 1],
                [L(Rez.Strings.Yards), L(Rez.Strings.Meters)], item);
        } else if (idx == :lapsPerSet) {
            pushOptions(L(Rez.Strings.LapsPerSet), "LapsPerSet", [1, 2, 3, 4, 5], null, item);
        } else if (idx == :perSetTime) {
            var view = new SetTimeView();
            var delegate = new SetTimeDelegate(view, _mainView, item);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
        } else if (idx == :numSets) {
            var vals = new [20];
            for (var i = 0; i < 20; i++) { vals[i] = i + 1; }
            pushOptions(L(Rez.Strings.NumSets), "NumSets", vals, null, item);
        } else if (idx == :alarm30) {
            pushOptions(L(Rez.Strings.Alarm30), "Enable30SecAlarm", [0, 1],
                [L(Rez.Strings.Off), L(Rez.Strings.On)], item);
        } else if (idx == :alarm20) {
            pushOptions(L(Rez.Strings.Alarm20), "Enable20SecAlarm", [0, 1],
                [L(Rez.Strings.Off), L(Rez.Strings.On)], item);
        } else if (idx == :alarm10) {
            pushOptions(L(Rez.Strings.Alarm10), "Enable10SecAlarm", [0, 1],
                [L(Rez.Strings.Off), L(Rez.Strings.On)], item);
        }
    }

    function onBack() as Lang.Boolean {
        _save();
        return false;
    }

    private function _save() {
        if (_saveAction instanceof Toybox.Lang.String) {
            TrainingStore.createFromGlobalWithName(_saveAction as Toybox.Lang.String);
        } else if (_saveAction instanceof Toybox.Lang.Number) {
            TrainingStore.copyFromGlobal(_saveAction as Toybox.Lang.Number);
        }
    }

    private function pushOptions(title, key, values, labels, parentItem) {
        var menu = new WatchUi.Menu2({ :title => title });
        var cur = Application.Storage.getValue(key);
        if (cur == null) {
            try { cur = Application.Properties.getValue(key); } catch (ex) {}
        }
        if (cur == true)  { cur = 1; }
        if (cur == false) { cur = 0; }
        var vals = values as Toybox.Lang.Array;
        var labs = labels as Toybox.Lang.Array;
        for (var i = 0; i < vals.size(); i++) {
            var val = vals[i];
            var labelStr = (labs != null) ? (labs[i] as Toybox.Lang.String) : val.toString();
            var subLabelStr = (val == cur) ? L(Rez.Strings.Selected) : null;
            menu.addItem(new WatchUi.MenuItem(labelStr, subLabelStr, val, {}));
        }
        WatchUi.pushView(menu, new SettingOptionsDelegate(key, _mainView, parentItem), WatchUi.SLIDE_LEFT);
    }
}

// ── App-level settings (Language + Version only) ─────────────────────────────
class AppSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        if (item.getId() == :appLang) {
            var menu = new WatchUi.Menu2({ :title => L(Rez.Strings.AppLang) });
            var cur = Application.Storage.getValue("AppLanguage");
            if (cur == null) {
                try { cur = Application.Properties.getValue("AppLanguage"); } catch (ex) {}
            }
            var vals = [-1, 0, 1, 2];
            var labs = [L(Rez.Strings.LangAuto), L(Rez.Strings.LangEN),
                        L(Rez.Strings.LangZH),   L(Rez.Strings.LangJA)];
            for (var i = 0; i < vals.size(); i++) {
                var subLbl = (vals[i] == cur) ? L(Rez.Strings.Selected) : null;
                menu.addItem(new WatchUi.MenuItem(labs[i], subLbl, vals[i], {}));
            }
            WatchUi.pushView(menu,
                new SettingOptionsDelegate("AppLanguage", null, item),
                WatchUi.SLIDE_LEFT);
        }
        // :appVersion is read-only — no action
    }

}

// ── Individual option selector ───────────────────────────────────────────────
class SettingOptionsDelegate extends WatchUi.Menu2InputDelegate {
    private var _key;
    private var _mainView;
    private var _parentItem;

    function initialize(key, mainView, parentItem) {
        Menu2InputDelegate.initialize();
        _key = key;
        _mainView = mainView;
        _parentItem = parentItem;
    }

    function onSelect(item) {
        var val = item.getId();
        Application.Storage.setValue(_key, val);
        if (_mainView != null) { _mainView.loadSettings(); }

        var rd = new SettingsReader();
        var subLabel = "";
        if      (_key.equals("PoolSize"))          { subLabel = rd.get("PoolSize", 25).toString(); }
        else if (_key.equals("PoolUnit"))           { subLabel = rd.unitLabel(); }
        else if (_key.equals("LapsPerSet"))         { subLabel = rd.get("LapsPerSet", 2).toString(); }
        else if (_key.equals("NumSets"))            { subLabel = rd.get("NumSets", 8).toString(); }
        else if (_key.equals("Enable30SecAlarm"))   { subLabel = rd.alarmLabel("Enable30SecAlarm"); }
        else if (_key.equals("Enable20SecAlarm"))   { subLabel = rd.alarmLabel("Enable20SecAlarm"); }
        else if (_key.equals("Enable10SecAlarm"))   { subLabel = rd.alarmLabel("Enable10SecAlarm"); }
        else if (_key.equals("AppLanguage"))        { subLabel = rd.langLabel(); }

        _parentItem.setSubLabel(subLabel);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// ── Menu builders ────────────────────────────────────────────────────────────

// Training settings (Pool Size → 10s Alarm).
// title    = menu header (training name for Create/Edit, "Settings" in-workout)
// saveAction = null (in-workout), String (new training name), Number (training index)
// Back saves the training when saveAction is not null.
function buildTrainingSettingsMenu(mainView, saveAction, title, useSwitchTo) {
    var rd = new SettingsReader();
    var menu = new WatchUi.Menu2({ :title => title });
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.PoolSize),   rd.get("PoolSize", 25).toString(),  :poolSize,   {}));
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.PoolUnit),   rd.unitLabel(),                     :poolUnit,   {}));
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.LapsPerSet), rd.get("LapsPerSet", 2).toString(), :lapsPerSet, {}));
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.PerSetTime), rd.timeLabel(),                     :perSetTime, {}));
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.NumSets),    rd.get("NumSets", 8).toString(),    :numSets,    {}));
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Alarm30),    rd.alarmLabel("Enable30SecAlarm"),  :alarm30,    {}));
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Alarm20),    rd.alarmLabel("Enable20SecAlarm"),  :alarm20,    {}));
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Alarm10),    rd.alarmLabel("Enable10SecAlarm"),  :alarm10,    {}));
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Finish),     null,                               :finish,     {}));
    var delegate = new SwimSetSettingsDelegate(mainView, saveAction);
    if (useSwitchTo) {
        WatchUi.switchToView(menu, delegate, WatchUi.SLIDE_LEFT);
    } else {
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_LEFT);
    }
}

// App-level settings (Language + Version). Accessible from training list only.
function buildAppSettingsMenu() {
    var rd = new SettingsReader();
    var menu = new WatchUi.Menu2({ :title => L(Rez.Strings.AppSettings) });
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.AppLang), rd.langLabel(),            :appLang,    {}));
    menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Version), L(Rez.Strings.AppVersion), :appVersion, {}));
    WatchUi.pushView(menu, new AppSettingsDelegate(), WatchUi.SLIDE_LEFT);
}

// In-workout shortcut: edits settings in-place without saving to a training slot.
function buildSettingsMenu(mainView) {
    buildTrainingSettingsMenu(mainView, null, L(Rez.Strings.Settings), false);
}

// ── Tiny helper to read stored/property values ───────────────────────────────

class SettingsReader {
    function get(key, fallback) {
        var v = Application.Storage.getValue(key);
        if (v != null) { return v; }
        try {
            v = Application.Properties.getValue(key);
        } catch (ex) {
            return fallback;
        }
        return v != null ? v : fallback;
    }

    function unitLabel() {
        return get("PoolUnit", 0) == 0 ? L(Rez.Strings.Yards) : L(Rez.Strings.Meters);
    }

    function alarmLabel(key) {
        var v = get(key, 1);
        return (v == 0 || v == false) ? L(Rez.Strings.Off) : L(Rez.Strings.On);
    }

    function langLabel() {
        var v = get("AppLanguage", -1);
        if (v == 0) { return L(Rez.Strings.LangEN); }
        if (v == 1) { return L(Rez.Strings.LangZH); }
        if (v == 2) { return L(Rez.Strings.LangJA); }
        return L(Rez.Strings.LangAuto);
    }

    function timeLabel() {
        var min = get("SetTimeMinutes", 1);
        var sec = get("SetTimeSeconds", 50);
        return min.format("%d") + ":" + sec.format("%02d");
    }
}
