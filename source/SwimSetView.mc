using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.Application;

class SwimSetView extends WatchUi.View {
    private var _timer;
    private var _running = false;
    private var _paused = false;
    private var _currentSet = 1;
    private var _elapsedSeconds = 0;
    private var _totalSets;
    private var _setTimeSeconds;
    private var _poolSize;
    private var _poolUnit;
    private var _enable30SecAlarm;
    private var _enable20SecAlarm;
    private var _enable10SecAlarm;
    private var _30secTriggered = false;
    private var _20secTriggered = false;
    private var _10secTriggered = false;
    private var _session;
    private var _hasStarted = false;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
        _session = null;
        _hasStarted = false;
        _paused = false;
        loadSettings();
    }

    // Storage (on-watch) takes priority; Properties (properties.xml) provides defaults.
    function loadSettings() {
        _poolSize    = storedOr("PoolSize",             Application.Properties.getValue("PoolSize"),             25);
        _poolUnit    = storedOr("PoolUnit",             Application.Properties.getValue("PoolUnit"),             0);
        var mins     = storedOr("SetTimeMinutes",       Application.Properties.getValue("SetTimeMinutes"),       1);
        var secs     = storedOr("SetTimeSeconds",       Application.Properties.getValue("SetTimeSeconds"),       50);
        _setTimeSeconds = (mins * 60) + secs;
        _totalSets   = storedOr("NumSets",              Application.Properties.getValue("NumSets"),              8);
        _enable30SecAlarm = storedOr("Enable30SecAlarm", Application.Properties.getValue("Enable30SecAlarm"), 1) != 0;
        _enable20SecAlarm = storedOr("Enable20SecAlarm", Application.Properties.getValue("Enable20SecAlarm"), 1) != 0;
        _enable10SecAlarm = storedOr("Enable10SecAlarm", Application.Properties.getValue("Enable10SecAlarm"), 1) != 0;
    }

    private function storedOr(key, propDefault, hardDefault) {
        var v = Application.Storage.getValue(key);
        if (v != null) { return v; }
        return propDefault != null ? propDefault : hardDefault;
    }

    function onLayout(dc) {
    }

    function onShow() {
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        var remaining = _setTimeSeconds - _elapsedSeconds;
        var minutes = remaining / 60;
        var seconds = remaining % 60;
        var timeStr = minutes.format("%02d") + ":" + seconds.format("%02d");

        var unitStr = _poolUnit == 0 ? "yds" : "m";
        var totalDist = _currentSet * (_poolSize * 2);

        dc.drawText(centerX, height * 0.10, Graphics.FONT_SMALL, "Set " + _currentSet + " / " + _totalSets, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height * 0.22, Graphics.FONT_SMALL, totalDist + " " + unitStr, Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(centerX, height * 0.38, Graphics.FONT_NUMBER_HOT, timeStr, Graphics.TEXT_JUSTIFY_CENTER);

        if (Activity has :getActivityInfo) {
            var info = Activity.getActivityInfo();
            if (info != null && info has :currentHeartRate && info.currentHeartRate != null) {
                var hrStr = info.currentHeartRate.format("%d") + " bpm";
                dc.drawText(centerX, height * 0.7, Graphics.FONT_SMALL, hrStr, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        var statusStr = "";
        if (_paused) {
            statusStr = L(Rez.Strings.Paused);
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(4);
            dc.drawCircle(centerX, height / 2, (width / 2) - 2);
            dc.setPenWidth(1);
        } else if (_running) {
            statusStr = L(Rez.Strings.Swimming);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            statusStr = L(Rez.Strings.Stopped);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(centerX, height * 0.85, Graphics.FONT_SMALL, statusStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onHide() {
    }

    function startTimer() {
        if (!_running && !_paused) {
            _running = true;
            _hasStarted = true;

            if (_session == null) {
                try {
                    // poolLength (metres) is required for SPORT_SWIMMING + SUB_SPORT_LAP_SWIMMING
                    var poolLenM = _poolUnit == 0
                        ? (_poolSize * 0.9144).toFloat()   // yards → metres
                        : _poolSize.toFloat();              // already metres
                    _session = ActivityRecording.createSession({
                        :name => "Swim Set",
                        :sport => Activity.SPORT_SWIMMING,
                        :subSport => Activity.SUB_SPORT_LAP_SWIMMING,
                        :poolLength => poolLenM
                    });
                    _session.start();
                } catch (ex) {
                    System.println("Session create failed");
                    _session = null;
                }
            }

            triggerVibration([new Attention.VibeProfile(100, 1000)]);

            _timer.start(method(:onTimerTick), 1000, true);
            WatchUi.requestUpdate();
        }
    }

    function pauseTimer() {
        if (_running) {
            _running = false;
            _paused = true;
            _timer.stop();
            if (_session != null) {
                try {
                    if (_session.isRecording()) {
                        _session.stop();
                    }
                } catch (ex) {
                    System.println("Pause session failed");
                }
            }
            WatchUi.requestUpdate();
        }
    }

    function resumeTimer() {
        if (_paused) {
            _paused = false;
            _running = true;
            if (_session != null) {
                try {
                    _session.start();
                } catch (ex) {
                    System.println("Resume session failed");
                }
            }
            _timer.start(method(:onTimerTick), 1000, true);
            WatchUi.requestUpdate();
        }
    }

    function showMainMenu() {
        var menu = new WatchUi.Menu2({:title => L(Rez.Strings.Options)});

        if (!_hasStarted) {
            menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Start), null, :start, {}));
            menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Settings),    null, :settings, {}));
        } else {
            if (_paused) {
                menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Resume), null, :resume, {}));
            } else {
                menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Pause), null, :pause, {}));
            }
            menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Save),    null, :save, {}));
            menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Discard), null, :discard, {}));
        }

        WatchUi.pushView(menu, new MainMenuDelegate(self), WatchUi.SLIDE_LEFT);
    }

    function showSettingsMenu() {
        buildSettingsMenu(self);
    }

    function handleMenuAction(action) {
        if (action == :start) {
            startTimer();
        } else if (action == :pause) {
            pauseTimer();
        } else if (action == :resume) {
            resumeTimer();
        } else if (action == :save) {
            saveWorkout();
        } else if (action == :discard) {
            discardWorkout();
        } else if (action == :settings) {
            showSettingsMenu();
        }
    }

    function saveWorkout() {
        _timer.stop();
        _running = false;
        _paused = false;
        if (_session != null) {
            try {
                if (_session.isRecording()) {
                    _session.stop();
                }
                _session.save();
            } catch (ex) {
                System.println("Save workout failed");
            }
            _session = null;
        }
    }

    function discardWorkout() {
        if (_running || _paused) {
            _timer.stop();
        }
        _running = false;
        _paused = false;
        if (_session != null) {
            try {
                _session.discard();
                System.println("Workout discarded");
            } catch (ex) {
                System.println("Discard workout failed");
            }
            _session = null;
        }
        _currentSet = 1;
        _elapsedSeconds = 0;
        _30secTriggered = false;
        _20secTriggered = false;
        _10secTriggered = false;
        _hasStarted = false;
        WatchUi.requestUpdate();
    }

    function resetTimer() {
        if (_session != null) {
            if (_session.isRecording()) {
                _session.stop();
            }
            _session.discard();
            _session = null;
        }

        if (_running) {
            _running = false;
            _timer.stop();
        }

        _currentSet = 1;
        _elapsedSeconds = 0;
        _30secTriggered = false;
        _20secTriggered = false;
        _10secTriggered = false;
        _hasStarted = false;
        _paused = false;
        WatchUi.requestUpdate();
    }

    function onTimerTick() {
        _elapsedSeconds++;

        var remaining = _setTimeSeconds - _elapsedSeconds;

        if (_enable30SecAlarm && !_30secTriggered && remaining == 30) {
            _30secTriggered = true;
            triggerVibration([
                new Attention.VibeProfile(80, 250),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(80, 250),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(80, 250)
            ]);
        }

        if (_enable20SecAlarm && !_20secTriggered && remaining == 20) {
            _20secTriggered = true;
            // 2 distinct bursts
            triggerVibration([
                new Attention.VibeProfile(80, 250),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(80, 250)
            ]);
        }

        if (_enable10SecAlarm && !_10secTriggered && remaining == 10) {
            _10secTriggered = true;
            triggerVibration([new Attention.VibeProfile(80, 200)]);
        }

        if (_elapsedSeconds >= _setTimeSeconds) {
            triggerVibration([new Attention.VibeProfile(100, 1000)]);

            if (_session != null) {
                try {
                    if (_session.isRecording()) {
                        _session.addLap();
                        System.println("Lap added");
                    }
                } catch (ex) {
                    System.println("Add lap failed");
                }
            }

            _currentSet++;
            _elapsedSeconds = 0;
            _30secTriggered = false;
            _20secTriggered = false;
            _10secTriggered = false;
            if (_currentSet > _totalSets) {
                pauseTimer();
                _currentSet = _totalSets;
            }
        }

        WatchUi.requestUpdate();
    }

    function triggerVibration(pattern) {
        if (Attention has :vibrate) {
            Attention.vibrate(pattern);
        }
    }

    function hasStarted() {
        return _hasStarted;
    }

    function isRunning() {
        return _running;
    }
}
