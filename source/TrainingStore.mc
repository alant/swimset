using Toybox.Application;

// Stores and retrieves saved swim training configurations.
// Storage layout: "TCount" = total count, "T{i}_{Field}" = per-training value.
// On first run, existing global settings are migrated into "Training-1".
module TrainingStore {

    function _fields() {
        return ["PoolSize", "PoolUnit", "LapsPerSet", "SetTimeMinutes",
                "SetTimeSeconds", "NumSets", "Enable30SecAlarm",
                "Enable20SecAlarm", "Enable10SecAlarm"]
            as Toybox.Lang.Array<Toybox.Lang.String>;
    }

    function _defaults() {
        return {
            "PoolSize" => 25, "PoolUnit" => 1, "LapsPerSet" => 2,
            "SetTimeMinutes" => 1, "SetTimeSeconds" => 30, "NumSets" => 8,
            "Enable30SecAlarm" => 1, "Enable20SecAlarm" => 1,
            "Enable10SecAlarm" => 1
        } as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
    }

    function getCount() {
        var v = Application.Storage.getValue("TCount");
        return (v instanceof Toybox.Lang.Number) ? v : 0;
    }

    function _key(i, field) {
        return "T" + i + "_" + field;
    }

    function getTraining(i) {
        var defs = _defaults() as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        var fields = _fields() as Toybox.Lang.Array<Toybox.Lang.String>;
        var d = {} as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        var nameVal = Application.Storage.getValue(_key(i, "Name"));
        d["name"] = (nameVal instanceof Toybox.Lang.String)
            ? nameVal
            : (L(Rez.Strings.TrainingPrefix) + "-" + (i + 1));
        for (var fi = 0; fi < fields.size(); fi++) {
            var f = fields[fi] as Toybox.Lang.String;
            var v = Application.Storage.getValue(_key(i, f));
            d[f] = (v != null) ? v : defs[f];
        }
        return d;
    }

    function _saveTraining(i, dict as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>) {
        Application.Storage.setValue(_key(i, "Name"), dict["name"]);
        var fields = _fields() as Toybox.Lang.Array<Toybox.Lang.String>;
        for (var fi = 0; fi < fields.size(); fi++) {
            var f = fields[fi] as Toybox.Lang.String;
            Application.Storage.setValue(_key(i, f), dict[f]);
        }
    }

    function createTraining(dict as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>) {
        var count = getCount();
        _saveTraining(count, dict);
        Application.Storage.setValue("TCount", count + 1);
        return count;
    }

    function deleteTraining(index) {
        var count = getCount();
        for (var i = index; i < count - 1; i++) {
            _saveTraining(i, getTraining(i + 1) as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>);
        }
        var last = count - 1;
        Application.Storage.deleteValue(_key(last, "Name"));
        var fields = _fields() as Toybox.Lang.Array<Toybox.Lang.String>;
        for (var fi = 0; fi < fields.size(); fi++) {
            Application.Storage.deleteValue(_key(last, fields[fi] as Toybox.Lang.String));
        }
        Application.Storage.setValue("TCount", count - 1);
    }

    function duplicateTraining(index) {
        var d = getTraining(index) as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        d["name"] = (d["name"] as Toybox.Lang.String) + "-1";
        return createTraining(d);
    }

    // Returns the lowest "Training-N" name not already in use.
    function nextAvailableName() as Toybox.Lang.String {
        var prefix = L(Rez.Strings.TrainingPrefix) + "-";
        var count = getCount();
        for (var n = 1; n <= count + 1; n++) {
            var candidate = prefix + n;
            var taken = false;
            for (var i = 0; i < count; i++) {
                var t = getTraining(i) as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
                if ((t["name"] as Toybox.Lang.String).equals(candidate)) {
                    taken = true;
                    break;
                }
            }
            if (!taken) { return candidate; }
        }
        return prefix + (count + 1);
    }

    // Create a new training from global keys, using the supplied name.
    function createFromGlobalWithName(name as Toybox.Lang.String) {
        var defs = _defaults() as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        var fields = _fields() as Toybox.Lang.Array<Toybox.Lang.String>;
        var d = { "name" => name } as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        for (var fi = 0; fi < fields.size(); fi++) {
            var f = fields[fi] as Toybox.Lang.String;
            var v = Application.Storage.getValue(f);
            d[f] = (v != null) ? v : defs[f];
        }
        return createTraining(d);
    }

    function renameTraining(index, name) {
        Application.Storage.setValue(_key(index, "Name"), name);
    }

    // Write training settings to the global keys that SwimSetView reads.
    function copyToGlobal(index) {
        var d = getTraining(index) as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        var fields = _fields() as Toybox.Lang.Array<Toybox.Lang.String>;
        for (var fi = 0; fi < fields.size(); fi++) {
            var f = fields[fi] as Toybox.Lang.String;
            Application.Storage.setValue(f, d[f]);
        }
    }

    // Read global keys back into a training slot (call after the user edits settings).
    function copyFromGlobal(index) {
        var d = getTraining(index) as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        var fields = _fields() as Toybox.Lang.Array<Toybox.Lang.String>;
        for (var fi = 0; fi < fields.size(); fi++) {
            var f = fields[fi] as Toybox.Lang.String;
            var v = Application.Storage.getValue(f);
            if (v != null) { d[f] = v; }
        }
        _saveTraining(index, d);
    }

    // Create a new training from whatever is currently in the global keys.
    function createFromGlobal() {
        var count = getCount();
        var defs = _defaults() as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        var fields = _fields() as Toybox.Lang.Array<Toybox.Lang.String>;
        var d = { "name" => L(Rez.Strings.TrainingPrefix) + "-" + (count + 1) }
            as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        for (var fi = 0; fi < fields.size(); fi++) {
            var f = fields[fi] as Toybox.Lang.String;
            var v = Application.Storage.getValue(f);
            d[f] = (v != null) ? v : defs[f];
        }
        return createTraining(d);
    }

    // Reset global keys to factory defaults before the user creates a new training.
    function copyDefaultsToGlobal() {
        var defs = _defaults() as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        var fields = _fields() as Toybox.Lang.Array<Toybox.Lang.String>;
        for (var fi = 0; fi < fields.size(); fi++) {
            var f = fields[fi] as Toybox.Lang.String;
            Application.Storage.setValue(f, defs[f]);
        }
    }

    // Compact one-line summary shown as the sublabel in the training list.
    function getSummary(dict as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>) {
        var unit = ((dict["PoolUnit"] as Toybox.Lang.Number) == 0) ? "yd" : "m";
        var sec = dict["SetTimeSeconds"] as Toybox.Lang.Number;
        var timeStr = (dict["SetTimeMinutes"] as Toybox.Lang.Number).toString()
            + ":" + sec.format("%02d");
        return (dict["NumSets"] as Toybox.Lang.Number).toString() + "x " +
               (dict["LapsPerSet"] as Toybox.Lang.Number).toString() + "L " +
               (dict["PoolSize"] as Toybox.Lang.Number).toString() + unit + " " + timeStr;
    }

    // First-run migration: converts existing global settings into Training-1.
    function migrateIfNeeded() {
        if (Application.Storage.getValue("TCount") != null) { return; }
        var defs = _defaults() as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        var fields = _fields() as Toybox.Lang.Array<Toybox.Lang.String>;
        var d = { "name" => L(Rez.Strings.TrainingPrefix) + "-1" }
            as Toybox.Lang.Dictionary<Toybox.Lang.String, Toybox.Lang.Object>;
        for (var fi = 0; fi < fields.size(); fi++) {
            var f = fields[fi] as Toybox.Lang.String;
            var v = Application.Storage.getValue(f);
            if (v == null) {
                try { v = Application.Properties.getValue(f); } catch (ex) {}
            }
            d[f] = (v != null) ? v : defs[f];
        }
        _saveTraining(0, d);
        Application.Storage.setValue("TCount", 1);
    }
}
