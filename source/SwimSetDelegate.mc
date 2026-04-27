using Toybox.WatchUi;

// Swim-mode input handling:
//   while the timer is running -> screen taps/swipes/holds must NOT open menu,
//                                 START/STOP button MUST open the menu.
//   while paused / before start / after discard -> taps and button both open menu.
//
// Avoid onSelect() entirely because Garmin maps it from both physical select
// buttons and touch taps on many hybrid devices, which makes it unreliable for
// distinguishing the input source across models.
class SwimSetDelegate extends WatchUi.BehaviorDelegate {
    private var _view;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Physical START/STOP/ENTER button should always be able to open options.
    // Consume so the OS/native behavior does not interfere with the app flow.
    function onKey(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            openMenu();
            return true;
        }
        return false;
    }

    // Touch should be blocked during swim mode, and enabled otherwise.
    function onTap(evt) {
        if (isTimerRunning()) {
            return true;
        }
        openMenu();
        return true;
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
