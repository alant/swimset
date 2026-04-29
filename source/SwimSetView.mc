using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.Application;
using Toybox.Time;
using Toybox.FitContributor;

class SwimSetView extends WatchUi.View {
    private var _timer;
    private var _navTimer;
    private var _running = false;
    private var _paused = false;
    private var _currentSet = 1;
    private var _elapsedSeconds = 0;
    private var _setStartTimeValue = 0;
    private var _pauseStartTimeValue = 0;
    private var _totalSets;
    private var _setTimeSeconds;
    private var _poolSize;
    private var _poolUnit;
    private var _lapsPerSet;
    private var _enable30SecAlarm;
    private var _enable20SecAlarm;
    private var _enable10SecAlarm;
    private var _30secTriggered = false;
    private var _20secTriggered = false;
    private var _10secTriggered = false;
    private var _session;
    private var _hasStarted = false;
    private var _hasSaved = false;
    private var _mainMenu;
    private var _workoutStartTime = 0;
    private var _totalPausedTime = 0;
    private var _completedSets = 0;
    private var _completedLengths = 0;
    private var _lastKnownAvgHeartRate = null;
    private var _lastKnownCurrentHeartRate = null;

    private var _sessionDistanceField;
    private var _sessionLengthsField;
    private var _sessionSetsField;
    private var _sessionPaceField;
    private var _sessionHrField;
    private var _lapDistanceField;
    private var _lapLengthsField;
    private var _lapElapsedField;
    private var _lapPaceField;
    private var _recordDistanceField;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
        _navTimer = new Timer.Timer();
        _session = null;
        _hasStarted = false;
        _hasSaved = false;
        _paused = false;
        _workoutStartTime = 0;
        _totalPausedTime = 0;
        _completedSets = 0;
        _completedLengths = 0;
        _lastKnownAvgHeartRate = null;
        _lastKnownCurrentHeartRate = null;
        clearFitFields();
        loadSettings();
    }

    function loadSettings() {
        _poolSize    = storedOr("PoolSize",             Application.Properties.getValue("PoolSize"),             25);
        _poolUnit    = storedOr("PoolUnit",             Application.Properties.getValue("PoolUnit"),             0);
        _lapsPerSet  = storedOr("LapsPerSet",           Application.Properties.getValue("LapsPerSet"),           2);
        var mins     = storedOr("SetTimeMinutes",       Application.Properties.getValue("SetTimeMinutes"),       1);
        var secs     = storedOr("SetTimeSeconds",       Application.Properties.getValue("SetTimeSeconds"),       30);
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
        if (remaining < 0) { remaining = 0; }
        var minutes = remaining / 60;
        var seconds = remaining % 60;
        var timeStr = minutes.format("%02d") + ":" + seconds.format("%02d");

        var unitStr = _poolUnit == 0 ? L(Rez.Strings.Yds) : L(Rez.Strings.M);
        var totalDist = (_completedLengths + currentSetDisplayLengths()) * _poolSize;

        dc.drawText(centerX, height * 0.10, Graphics.FONT_SMALL, L(Rez.Strings.Set) + " " + _currentSet + " / " + _totalSets, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height * 0.22, Graphics.FONT_SMALL, totalDist + " " + unitStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height * 0.38, Graphics.FONT_NUMBER_HOT, timeStr, Graphics.TEXT_JUSTIFY_CENTER);

        refreshActivitySnapshots();
        if (_lastKnownCurrentHeartRate != null) {
            var hrStr = _lastKnownCurrentHeartRate.format("%d") + " bpm";
            dc.drawText(centerX, height * 0.7, Graphics.FONT_SMALL, hrStr, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var statusStr = "";
        if (_paused) {
            statusStr = L(Rez.Strings.Paused);
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(4);
            dc.drawCircle(centerX, height / 2, (width / 2) - 2);
            dc.setPenWidth(1);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else if (_running) {
            statusStr = L(Rez.Strings.Swimming);
        } else {
            statusStr = L(Rez.Strings.Stopped);
        }
        dc.drawText(centerX, height * 0.82, Graphics.FONT_SMALL, statusStr, Graphics.TEXT_JUSTIFY_CENTER);

        if (_running) {
            dc.drawText(centerX, height * 0.90, Graphics.FONT_XTINY, L(Rez.Strings.TouchLocked), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function onHide() {
    }

    function startTimer() {
        if (!_running && !_paused) {
            _running = true;
            _hasStarted = true;

            if (_session == null) {
                try {
                    _session = ActivityRecording.createSession({
                        :name => "Swim Set",
                        :sport => Activity.SPORT_SWIMMING,
                        :subSport => Activity.SUB_SPORT_LAP_SWIMMING,
                        :poolLength => getPoolLengthMeters()
                    });
                    setupFitFields();
                    updateSessionFitFields(0);
                    updateRecordFitFields();
                    _session.start();
                } catch (ex) {
                    System.println("Session create failed");
                    _session = null;
                    clearFitFields();
                }
                _workoutStartTime = Time.now().value();
            }

            triggerVibration([new Attention.VibeProfile(100, 1000)]);

            _setStartTimeValue = Time.now().value();
            _timer.start(method(:onTimerTick), 1000, true);
            WatchUi.requestUpdate();
        }
    }

    function pauseTimer() {
        if (_running) {
            _running = false;
            _paused = true;
            _pauseStartTimeValue = Time.now().value();
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

            var pauseDuration = Time.now().value() - _pauseStartTimeValue;
            _setStartTimeValue += pauseDuration;
            _totalPausedTime += pauseDuration;

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
        _navTimer.stop();
        _mainMenu = new WatchUi.Menu2({:title => L(Rez.Strings.Options)});

        if (!_hasStarted) {
            _mainMenu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Start), null, :start, {}));
            _mainMenu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Settings), null, :settings, {}));
        } else {
            if (_paused) {
                _mainMenu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Resume), null, :resume, {}));
            } else {
                _mainMenu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Pause), null, :pause, {}));
            }
            if (!_hasSaved) {
                _mainMenu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Save), null, :save, {}));
            }
            _mainMenu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Discard), null, :discard, {}));
        }

        WatchUi.pushView(_mainMenu, new MainMenuDelegate(self), WatchUi.SLIDE_LEFT);
    }

    function showMainMenuDelayed() {
        _navTimer.start(method(:showMainMenu), 200, false);
    }

    function focusSettingsInMainMenu() {
        if (_mainMenu != null && !_hasStarted) {
            _mainMenu.setFocus(1);
        }
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
            var confirmDialog = new WatchUi.Confirmation(L(Rez.Strings.DiscardConfirm));
            var confirmDelegate = new DiscardConfirmDelegate(self, 1);
            WatchUi.pushView(confirmDialog, confirmDelegate, WatchUi.SLIDE_IMMEDIATE);
        } else if (action == :settings) {
            showSettingsMenu();
        }
    }

    function saveWorkout() {
        _timer.stop();
        _running = false;
        _hasSaved = true;

        var totalTime = getTotalElapsedSeconds();
        if (_paused && _pauseStartTimeValue > 0) {
            var currentPauseDuration = Time.now().value() - _pauseStartTimeValue;
            if (currentPauseDuration > 0) { totalTime -= currentPauseDuration; }
            if (totalTime < 0) { totalTime = 0; }
        }
        _paused = false;
        var nativeDistanceM = 0.0;
        refreshActivitySnapshots();

        if (_session != null) {
            try {
                if (Activity has :getActivityInfo) {
                    var info = Activity.getActivityInfo();
                    if (info != null && info has :totalDistance && info.totalDistance != null) {
                        nativeDistanceM = info.totalDistance.toFloat();
                    }
                }

                updateSessionFitFields(totalTime);
                updateRecordFitFields();

                if (_session.isRecording()) {
                    _session.stop();
                }
                _session.save();
            } catch (ex) {
                System.println("Save workout failed");
            }
            _session = null;
            clearFitFields();
        }

        var estimatedDistanceM = getEstimatedDistanceMeters();
        var totalDistanceM = nativeDistanceM;
        var isEstimatedDistance = false;
        if (totalDistanceM <= 0 || estimatedDistanceM > totalDistanceM) {
            totalDistanceM = estimatedDistanceM;
            isEstimatedDistance = estimatedDistanceM > 0;
        }

        var totalDistanceDisplay = metersToDisplayDistance(totalDistanceM);
        var statsView = new StatsView(totalTime, totalDistanceDisplay, _lastKnownAvgHeartRate, _poolUnit, isEstimatedDistance, _completedLengths, _completedSets);
        var statsDelegate = new StatsDelegate();
        WatchUi.pushView(statsView, statsDelegate, WatchUi.SLIDE_LEFT);

        resetTimer();
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
        clearFitFields();
        _currentSet = 1;
        _elapsedSeconds = 0;
        _setStartTimeValue = 0;
        _pauseStartTimeValue = 0;
        _30secTriggered = false;
        _20secTriggered = false;
        _10secTriggered = false;
        _hasStarted = false;
        _hasSaved = false;
        _workoutStartTime = 0;
        _totalPausedTime = 0;
        _completedSets = 0;
        _completedLengths = 0;
        _lastKnownAvgHeartRate = null;
        _lastKnownCurrentHeartRate = null;
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
        clearFitFields();

        if (_running) {
            _running = false;
            _timer.stop();
        }

        _currentSet = 1;
        _elapsedSeconds = 0;
        _setStartTimeValue = 0;
        _pauseStartTimeValue = 0;
        _30secTriggered = false;
        _20secTriggered = false;
        _10secTriggered = false;
        _hasStarted = false;
        _hasSaved = false;
        _paused = false;
        _workoutStartTime = 0;
        _totalPausedTime = 0;
        _completedSets = 0;
        _completedLengths = 0;
        _lastKnownAvgHeartRate = null;
        _lastKnownCurrentHeartRate = null;
        WatchUi.requestUpdate();
    }

    function onTimerTick() {
        if (_running) {
            _elapsedSeconds = Time.now().value() - _setStartTimeValue;
        }

        refreshActivitySnapshots();
        updateRecordFitFields();

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

            _completedSets += 1;
            _completedLengths += _lapsPerSet;
            updateLapFitFields(_elapsedSeconds);
            updateSessionFitFields(getTotalElapsedSeconds());
            updateRecordFitFields();

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
            _setStartTimeValue = Time.now().value();
            _elapsedSeconds = 0;
            _30secTriggered = false;
            _20secTriggered = false;
            _10secTriggered = false;
            if (_currentSet > _totalSets) {
                pauseTimer();
                _currentSet = _totalSets;
                showCompletionDialog();
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

    function onDiscardConfirmDismissed() {
    }

    function showCompletionDialog() {
        if (WatchUi.getCurrentView()[0] != self) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            _navTimer.start(method(:showCompletionDialog), 50, false);
            return;
        }
        var dialog = new CompletionDialog();
        var delegate = new CompletionDialogDelegate(self);
        WatchUi.pushView(dialog, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    private function currentSetDisplayLengths() {
        if (_hasStarted) {
            return _lapsPerSet;
        }
        return 0;
    }

    private function getPoolLengthMeters() {
        if (_poolUnit == 0) {
            return (_poolSize * 0.9144).toFloat();
        }
        return _poolSize.toFloat();
    }

    private function getEstimatedDistanceMeters() {
        return _completedLengths.toFloat() * getPoolLengthMeters();
    }

    private function metersToDisplayDistance(distanceM) {
        if (_poolUnit == 0) {
            return (distanceM / 0.9144 + 0.5).toNumber();
        }
        return (distanceM + 0.5).toNumber();
    }

    private function getTotalElapsedSeconds() {
        if (_workoutStartTime <= 0) {
            return 0;
        }
        var totalTime = Time.now().value() - _workoutStartTime - _totalPausedTime;
        if (totalTime < 0) {
            return 0;
        }
        return totalTime;
    }

    private function computePacePer100M(totalTimeSec, distanceM) {
        if (totalTimeSec > 0 && distanceM > 0) {
            return (totalTimeSec.toFloat() / distanceM.toFloat()) * 100.0;
        }
        return 0.0;
    }

    private function refreshActivitySnapshots() {
        if (Activity has :getActivityInfo) {
            var info = Activity.getActivityInfo();
            if (info != null) {
                if (info has :averageHeartRate && info.averageHeartRate != null) {
                    _lastKnownAvgHeartRate = info.averageHeartRate;
                }
                if (info has :currentHeartRate && info.currentHeartRate != null) {
                    _lastKnownCurrentHeartRate = info.currentHeartRate;
                }
            }
        }
    }

    private function clearFitFields() {
        _sessionDistanceField = null;
        _sessionLengthsField = null;
        _sessionSetsField = null;
        _sessionPaceField = null;
        _sessionHrField = null;
        _lapDistanceField = null;
        _lapLengthsField = null;
        _lapElapsedField = null;
        _lapPaceField = null;
        _recordDistanceField = null;
    }

    private function setupFitFields() {
        clearFitFields();
        if (_session == null) {
            return;
        }

        try {
            _sessionDistanceField = _session.createField("TotalDistanceM", 0, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "m"});
            _sessionLengthsField = _session.createField("TotalLengths", 1, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "count"});
            _sessionSetsField = _session.createField("TotalSets", 2, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "count"});
            _sessionPaceField = _session.createField("AvgPace100M", 3, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "sec/100m"});
            _sessionHrField = _session.createField("AvgHeartRate", 4, FitContributor.DATA_TYPE_UINT8, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "bpm"});

            _lapDistanceField = _session.createField("LapDistanceM", 10, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "m"});
            _lapLengthsField = _session.createField("LapLengths", 11, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "count"});
            _lapElapsedField = _session.createField("LapElapsedSec", 12, FitContributor.DATA_TYPE_UINT32, {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "s"});
            _lapPaceField = _session.createField("LapPace100M", 13, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "sec/100m"});

            _recordDistanceField = _session.createField("EstimatedDistanceM", 20, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "m"});
        } catch (ex) {
            System.println("Create FIT fields failed");
            clearFitFields();
        }
    }

    private function updateSessionFitFields(totalTime) {
        var totalDistanceM = getEstimatedDistanceMeters();
        var avgPace = computePacePer100M(totalTime, totalDistanceM);

        if (_sessionDistanceField != null) { _sessionDistanceField.setData(totalDistanceM); }
        if (_sessionLengthsField != null) { _sessionLengthsField.setData(_completedLengths); }
        if (_sessionSetsField != null) { _sessionSetsField.setData(_completedSets); }
        if (_sessionPaceField != null) { _sessionPaceField.setData(avgPace); }
        if (_sessionHrField != null && _lastKnownAvgHeartRate != null) { _sessionHrField.setData(_lastKnownAvgHeartRate); }
    }

    private function updateLapFitFields(lapElapsedSeconds) {
        var lapDistanceM = _lapsPerSet.toFloat() * getPoolLengthMeters();
        var lapPace = computePacePer100M(lapElapsedSeconds, lapDistanceM);

        if (_lapDistanceField != null) { _lapDistanceField.setData(lapDistanceM); }
        if (_lapLengthsField != null) { _lapLengthsField.setData(_lapsPerSet); }
        if (_lapElapsedField != null) { _lapElapsedField.setData(lapElapsedSeconds); }
        if (_lapPaceField != null) { _lapPaceField.setData(lapPace); }
    }

    private function updateRecordFitFields() {
        if (_recordDistanceField != null) {
            _recordDistanceField.setData(getEstimatedDistanceMeters());
        }
    }
}
