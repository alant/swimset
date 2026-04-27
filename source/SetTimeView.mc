using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.System;

class SetTimeView extends WatchUi.View {
    private var _minutes;
    private var _seconds;
    private var _focusMinutes = true;

    function initialize() {
        View.initialize();
        var rd = new SettingsReader();
        _minutes = rd.get("SetTimeMinutes", 1);
        _seconds = rd.get("SetTimeSeconds", 50);
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var leftCenterX = width * 0.34;
        var rightCenterX = width * 0.66;

        var titleY = height * 0.11;
        var topValueY = height * 0.32;
        var currentValueY = height * 0.52;
        var bottomValueY = height * 0.72;
        var selectionBandTop = 0;
        var selectionBandHeight = height * 0.22;
        var underlineY = height * 0.62;
        var labelY = height * 0.90;

        var align = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.fillRectangle(0, selectionBandTop, width, selectionBandHeight);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, Graphics.FONT_TINY, L(Rez.Strings.PerSetTime), align);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCenterX, topValueY, Graphics.FONT_SMALL, formatMinutes(previousMinutes()), align);
        dc.drawText(rightCenterX, topValueY, Graphics.FONT_SMALL, formatSeconds(previousSeconds()), align);

        if (_focusMinutes) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftCenterX, currentValueY, Graphics.FONT_NUMBER_HOT, formatMinutes(_minutes), align);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightCenterX, currentValueY, Graphics.FONT_NUMBER_MEDIUM, formatSeconds(_seconds), align);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftCenterX, currentValueY, Graphics.FONT_NUMBER_MEDIUM, formatMinutes(_minutes), align);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightCenterX, currentValueY, Graphics.FONT_NUMBER_HOT, formatSeconds(_seconds), align);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, currentValueY, Graphics.FONT_NUMBER_MEDIUM, ":", align);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCenterX, bottomValueY, Graphics.FONT_SMALL, formatMinutes(nextMinutes()), align);
        dc.drawText(rightCenterX, bottomValueY, Graphics.FONT_SMALL, formatSeconds(nextSeconds()), align);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_focusMinutes) {
            dc.fillRectangle(leftCenterX - 30, underlineY, 60, 4);
        } else {
            dc.fillRectangle(rightCenterX - 38, underlineY, 76, 4);
        }

        if (_focusMinutes) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftCenterX, labelY, Graphics.FONT_XTINY, L(Rez.Strings.Minutes), align);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightCenterX, labelY, Graphics.FONT_XTINY, L(Rez.Strings.Seconds), align);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightCenterX, labelY, Graphics.FONT_XTINY, L(Rez.Strings.Seconds), align);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftCenterX, labelY, Graphics.FONT_XTINY, L(Rez.Strings.Minutes), align);
        }
    }

    function adjustMinutes(delta) {
        _minutes += delta;
        if (_minutes < 0) { _minutes = 0; }
        if (_minutes > 5) { _minutes = 5; }
        WatchUi.requestUpdate();
    }

    function adjustSeconds(delta) {
        _seconds += delta;
        if (_seconds < 0) { _seconds = 0; }
        if (_seconds > 55) { _seconds = 55; }
        WatchUi.requestUpdate();
    }

    function toggleFocus() {
        _focusMinutes = !_focusMinutes;
        WatchUi.requestUpdate();
    }

    function focusMinutes() {
        _focusMinutes = true;
        WatchUi.requestUpdate();
    }

    function focusSeconds() {
        _focusMinutes = false;
        WatchUi.requestUpdate();
    }

    private function previousMinutes() {
        return _minutes > 0 ? _minutes - 1 : 0;
    }

    private function nextMinutes() {
        return _minutes < 5 ? _minutes + 1 : 5;
    }

    private function previousSeconds() {
        return _seconds > 0 ? _seconds - 5 : 0;
    }

    private function nextSeconds() {
        return _seconds < 55 ? _seconds + 5 : 55;
    }

    private function formatMinutes(value) {
        return value.format("%d");
    }

    private function formatSeconds(value) {
        return value.format("%02d");
    }



    function save() {
        Application.Storage.setValue("SetTimeMinutes", _minutes);
        Application.Storage.setValue("SetTimeSeconds", _seconds);
    }

    function getMinutes() { return _minutes; }
    function getSeconds() { return _seconds; }
    function isFocusMinutes() { return _focusMinutes; }
}

class SetTimeDelegate extends WatchUi.BehaviorDelegate {
    private var _view;
    private var _mainView;
    private var _parentItem;

    function initialize(view, mainView, parentItem) {
        BehaviorDelegate.initialize();
        _view = view;
        _mainView = mainView;
        _parentItem = parentItem;
    }

    function onNextPage() {
        if (_view.isFocusMinutes()) {
            _view.adjustMinutes(1);
        } else {
            _view.adjustSeconds(5);
        }
        return true;
    }

    function onPreviousPage() {
        if (_view.isFocusMinutes()) {
            _view.adjustMinutes(-1);
        } else {
            _view.adjustSeconds(-5);
        }
        return true;
    }

    function onTap(evt) {
        var coords = evt.getCoordinates();
        if (coords != null) {
            var splitX = System.getDeviceSettings().screenWidth / 2;
            if (coords[0] < splitX) {
                _view.focusMinutes();
            } else {
                _view.focusSeconds();
            }
            return true;
        }
        return false;
    }

    function onSelect() {
        _view.toggleFocus();
        return true;
    }

    function onBack() {
        _view.save();
        _mainView.loadSettings();

        var min = _view.getMinutes();
        var sec = _view.getSeconds();
        var subLabel = min.format("%d") + ":" + sec.format("%02d");
        _parentItem.setSubLabel(subLabel);

        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
