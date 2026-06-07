using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Timer;

// Root training list.  Subclasses Menu2 so we can override onShow() and rebuild
// items whenever the view returns to the top (after edit / create / delete / rename).
class TrainingListMenu extends WatchUi.Menu2 {
    private var _itemCount = 0;
    private var _pendingCreateName = null;

    function initialize() {
        WatchUi.Menu2.initialize({ :title => L(Rez.Strings.Trainings) });
        _rebuild();
    }

    function setPendingCreate(name) {
        _pendingCreateName = name;
    }

    function onShow() {
        if (_pendingCreateName != null) {
            var name = _pendingCreateName;
            _pendingCreateName = null;
            buildTrainingSettingsMenu(null, name, name);
            return;
        }
        _rebuild();
        WatchUi.requestUpdate();
    }

    private function _rebuild() {
        while (_itemCount > 0) {
            deleteItem(0);
            _itemCount--;
        }
        var count = TrainingStore.getCount();
        for (var i = 0; i < count; i++) {
            var t = TrainingStore.getTraining(i) as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
            addItem(new WatchUi.MenuItem(
                t["name"] as Toybox.Lang.String,
                TrainingStore.getSummary(t),
                i, null));
            _itemCount++;
        }
        addItem(new WatchUi.MenuItem(L(Rez.Strings.CreateTraining), null, :create,      null));
        _itemCount++;
        addItem(new WatchUi.MenuItem(L(Rez.Strings.AppSettings),    null, :appSettings, null));
        _itemCount++;
    }
}

class TrainingListDelegate extends WatchUi.Menu2InputDelegate {
    private var _menu;

    function initialize(menu) {
        WatchUi.Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :create) {
            // Name the training first, then configure settings.
            TrainingStore.copyDefaultsToGlobal();
            var defaultName = TrainingStore.nextAvailableName();
            WatchUi.pushView(
                new WatchUi.TextPicker(defaultName),
                new TrainingCreateNameDelegate(_menu),
                WatchUi.SLIDE_LEFT);
        } else if (id == :appSettings) {
            buildAppSettingsMenu();
        } else {
            var idx = id as Toybox.Lang.Number;
            var t = TrainingStore.getTraining(idx) as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
            var menu = new WatchUi.Menu2({ :title => t["name"] as Toybox.Lang.String });
            menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Start),     null, :start,     null));
            menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Edit),      null, :edit,      null));
            menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Duplicate), null, :duplicate, null));
            menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Rename),    null, :rename,    null));
            menu.addItem(new WatchUi.MenuItem(L(Rez.Strings.Delete),    null, :delete,    null));
            WatchUi.pushView(menu, new TrainingActionDelegate(idx), WatchUi.SLIDE_LEFT);
        }
    }
}

class TrainingCreateNameDelegate extends WatchUi.TextPickerDelegate {
    private var _menu;

    function initialize(menu) {
        WatchUi.TextPickerDelegate.initialize();
        _menu = menu;
    }

    function onTextEntered(text, changed) {
        var name = (changed && text != null && text.length() > 0)
            ? text
            : TrainingStore.nextAvailableName();

        _menu.setPendingCreate(name);
        return true;
    }

    function onCancel() {
        return true;
    }
}

class TrainingActionDelegate extends WatchUi.Menu2InputDelegate {
    private var _index;

    function initialize(index) {
        WatchUi.Menu2InputDelegate.initialize();
        _index = index;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :start) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            TrainingStore.copyToGlobal(_index);
            var view = new SwimSetView();
            WatchUi.pushView(view, new SwimSetDelegate(), WatchUi.SLIDE_LEFT);
            view.startTimer();
        } else if (id == :edit) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            TrainingStore.copyToGlobal(_index);
            var t = TrainingStore.getTraining(_index) as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
            var name = t["name"] as Toybox.Lang.String;
            buildTrainingSettingsMenu(null, _index, name);
        } else if (id == :duplicate) {
            TrainingStore.duplicateTraining(_index);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (id == :rename) {
            var t = TrainingStore.getTraining(_index) as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
            WatchUi.pushView(
                new WatchUi.TextPicker(t["name"] as Toybox.Lang.String),
                new TrainingRenameDelegate(_index),
                WatchUi.SLIDE_LEFT);
        } else if (id == :delete) {
            WatchUi.pushView(
                new WatchUi.Confirmation(L(Rez.Strings.DeleteConfirm)),
                new TrainingDeleteDelegate(_index),
                WatchUi.SLIDE_LEFT);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class TrainingRenameDelegate extends WatchUi.TextPickerDelegate {
    private var _index;

    function initialize(index) {
        WatchUi.TextPickerDelegate.initialize();
        _index = index;
    }

    function onTextEntered(text, changed) {
        if (changed && text != null && text.length() > 0) {
            TrainingStore.renameTraining(_index, text);
        }
        return true;
    }
}

class TrainingDeleteDelegate extends WatchUi.ConfirmationDelegate {
    private var _index;

    function initialize(index) {
        WatchUi.ConfirmationDelegate.initialize();
        _index = index;
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            TrainingStore.deleteTraining(_index);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }
}
