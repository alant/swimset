using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.ActivityRecording;
using Toybox.Activity;

class StatsView extends WatchUi.View {
    private var _totalTime;
    private var _totalDistance;
    private var _avgPace;
    private var _avgHeartRate;
    private var _poolUnit;
    private var _isEstimatedDistance;

    function initialize(totalTime, totalDistance, avgHeartRate, poolUnit, isEstimatedDistance, completedLengths, completedSets) {
        View.initialize();
        _totalTime = totalTime;
        _totalDistance = totalDistance;
        _avgHeartRate = avgHeartRate;
        _poolUnit = poolUnit;
        _isEstimatedDistance = isEstimatedDistance;

        if (totalDistance > 0 && totalTime > 0) {
            _avgPace = (totalTime.toFloat() / totalDistance.toFloat()) * 100;
        } else {
            _avgPace = 0;
        }
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

        dc.drawText(centerX, height * 0.05, Graphics.FONT_MEDIUM, L(Rez.Strings.WorkoutSaved), Graphics.TEXT_JUSTIFY_CENTER);

        var minutes = _totalTime / 60;
        var seconds = _totalTime % 60;
        var timeStr = minutes.format("%d") + ":" + seconds.format("%02d");

        dc.drawText(centerX, height * 0.18, Graphics.FONT_SMALL, L(Rez.Strings.TotalTime), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height * 0.26, Graphics.FONT_MEDIUM, timeStr, Graphics.TEXT_JUSTIFY_CENTER);

        var unitStr = _poolUnit == 0 ? L(Rez.Strings.Yds) : L(Rez.Strings.M);
        var distancePrefix = _isEstimatedDistance ? "~" : "";
        dc.drawText(centerX, height * 0.40, Graphics.FONT_SMALL, L(Rez.Strings.TotalDistance), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height * 0.48, Graphics.FONT_MEDIUM, distancePrefix + _totalDistance + " " + unitStr, Graphics.TEXT_JUSTIFY_CENTER);



        if (_avgPace > 0) {
            var paceSeconds = _avgPace.toNumber();
            var paceMin = paceSeconds / 60;
            var paceSec = paceSeconds % 60;
            var paceStr = paceMin.format("%d") + ":" + paceSec.format("%02d") + " /" + (_poolUnit == 0 ? "100yd" : "100m");
            dc.drawText(centerX, height * 0.62, Graphics.FONT_SMALL, L(Rez.Strings.AvgPace), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, height * 0.70, Graphics.FONT_SMALL, paceStr, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var hrStr = (_avgHeartRate != null && _avgHeartRate > 0) ? _avgHeartRate.format("%d") + " bpm" : "--";
        dc.drawText(centerX, height * 0.84, Graphics.FONT_SMALL, L(Rez.Strings.AvgHR) + ": " + hrStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onHide() {
    }
}

class StatsDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onSelect() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
