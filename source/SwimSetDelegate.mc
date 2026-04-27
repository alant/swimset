using Toybox.WatchUi;
using Toybox.System;

// Swim-mode input handling for Descent G2:
//   while the timer is running -> screen taps must NOT open the menu,
//                                 START/STOP button MUST open the menu.
//   while paused / before start / after discard -> taps and button both work.
//
// Garmin event ordering (touchscreen + physical button):
//   button press : onKey -> (sometimes also) onSelect
//   screen tap   : onTap -> onSelect
// We use timestamps to disambiguate the two onSelect sources.
class SwimSetDelegate extends WatchUi.BehaviorDelegate {
    private var _view;
    private var _lastTapTime = 0;
    private var _lastKeyTime = 0;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Physical button (START/STOP/ENTER). Consume so the OS doesn't pause the
    // ActivityRecording session natively.
    function onKey(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _lastKeyTime = System.getTimer();
            openMenu();
            return true;
        }
        return false;
    }

    function onSelect() {
        var now = System.getTimer();

        // onKey just handled this same button press -> ignore the echo.
        if ((now - _lastKeyTime) < 500) {
            return true;
        }

        if (isTimerRunning()) {
            // Touch path always fires onTap right before onSelect.
            // No recent tap -> this onSelect came from the physical button
            // (on devices where onKey didn't fire) -> open the menu.
            if ((now - _lastTapTime) < 250) {
                return true; // tap during swim mode -> blocked
            }
            openMenu();
            return true;
        }

        // Not running: taps and button both open the menu.
        openMenu();
        return true;
    }

    function onTap(evt) {
        _lastTapTime = System.getTimer();
        // Consume the tap while running so it can't propagate to other handlers.
        return isTimerRunning();
    }

    function onBack() {
        if (_view == null) {
            _view = WatchUi.getCurrentView()[0];
        }
        return _view.hasStarted();
    }

    function onMenu() {
        openMenu();
        return true;
    }

    function onSwipe(evt) {
        return isTimerRunning();
    }

    function onHold(evt) {
        return isTimerRunning();
    }

    private function openMenu() {
        if (_view == null) {
            _view = WatchUi.getCurrentView()[0];
        }
        _view.showMainMenu();
    }

    private function isTimerRunning() {
        if (_view == null) {
            _view = WatchUi.getCurrentView()[0];
        }
        return _view.isRunning();
    }
}
