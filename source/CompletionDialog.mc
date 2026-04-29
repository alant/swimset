using Toybox.WatchUi;
using Toybox.Graphics;

class CompletionDialog extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        dc.drawText(centerX, height * 0.25, Graphics.FONT_LARGE, L(Rez.Strings.WorkoutComplete), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height * 0.50, Graphics.FONT_MEDIUM, L(Rez.Strings.PressToSave), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height * 0.70, Graphics.FONT_SMALL, L(Rez.Strings.BackToDiscard), Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class CompletionDialogDelegate extends WatchUi.BehaviorDelegate {
    private var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            _view.saveWorkout();
            return true;
        }
        return false;
    }

    function onSelect() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        _view.saveWorkout();
        return true;
    }

    function onBack() {
        var confirmDialog = new WatchUi.Confirmation(L(Rez.Strings.DiscardConfirm));
        var confirmDelegate = new DiscardConfirmDelegate(_view, 0);
        WatchUi.pushView(confirmDialog, confirmDelegate, WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onTap(evt) {
        return true;
    }

    function onSwipe(evt) {
        return true;
    }

    function onHold(evt) {
        return true;
    }
}

class DiscardConfirmDelegate extends WatchUi.ConfirmationDelegate {
    private var _view;
    private var _extraPops;

    function initialize(view, extraPops) {
        ConfirmationDelegate.initialize();
        _view = view;
        _extraPops = extraPops;
    }

    function onResponse(response) {
        _view.onDiscardConfirmDismissed();
        if (response == WatchUi.CONFIRM_YES) {
            _view.discardWorkout();
            if (_extraPops == 0) {
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            }
        } else {
            if (_extraPops == 1) {
                _view.showMainMenuDelayed();
            }
        }
        return true;
    }
}
