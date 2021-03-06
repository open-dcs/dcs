public class Dcs.MetaConfig : Dcs.Config {

    private Gee.ArrayList<Dcs.Config> config_list;

    public MetaConfig () {
        config_list = new Gee.ArrayList<Dcs.Config> ();
    }

    /**
     * {@inheritDoc}
     */
    public override string get_string (string ns,
                                       string key)
                                       throws GLib.Error {
		string value = null;

        foreach (var config in config_list) {
            try {
                value = config.get_string (ns, key);
            } catch (Dcs.ConfigError e) {
                if (!(e is Dcs.ConfigError.NO_VALUE_SET)) {
                    throw e;
                }
            }
        }

        if (value != null) {
            return value;
        } else {
            throw new Dcs.ConfigError.NO_VALUE_SET (_("No value available"));
		}
    }

    /**
     * {@inheritDoc}
     */
    public override Gee.ArrayList<string> get_string_list (string ns,
                                                           string key)
                                                           throws GLib.Error {
        Gee.ArrayList<string> value = null;

        foreach (var config in config_list) {
            try {
                value = config.get_string_list (ns, key);
            } catch (Dcs.ConfigError e) {
                if (!(e is Dcs.ConfigError.NO_VALUE_SET)) {
                    throw e;
                }
            }
        }

        if (value != null) {
            return value;
        } else {
            throw new Dcs.ConfigError.NO_VALUE_SET (_("No value available"));
		}
    }

    /**
     * {@inheritDoc}
     */
    public override int get_int (string ns,
                                 string key)
                                 throws GLib.Error {
		int value = 0;
		bool value_set = false;

        foreach (var config in config_list) {
            try {
                value = config.get_int (ns, key);
                value_set = true;
            } catch (Dcs.ConfigError e) {
                if (!(e is Dcs.ConfigError.NO_VALUE_SET)) {
                    throw e;
                }
            }
        }

        if (value_set) {
            return value;
        } else {
            throw new Dcs.ConfigError.NO_VALUE_SET (_("No value available"));
		}
    }

    /**
     * {@inheritDoc}
     */
    public override Gee.ArrayList<int> get_int_list (string ns,
                                                     string key)
                                                     throws GLib.Error {
        Gee.ArrayList<int> value = null;

        foreach (var config in config_list) {
            try {
                value = config.get_int_list (ns, key);
            } catch (Dcs.ConfigError e) {
                if (!(e is Dcs.ConfigError.NO_VALUE_SET)) {
                    throw e;
                }
            }
        }

        if (value != null) {
            return value;
        } else {
            throw new Dcs.ConfigError.NO_VALUE_SET (_("No value available"));
		}
    }

    /**
     * {@inheritDoc}
     */
    public override bool get_bool (string ns,
                                   string key)
                                   throws GLib.Error {
		bool value = false;
		bool value_set = false;

        foreach (var config in config_list) {
            try {
                value = config.get_bool (ns, key);
                value_set = true;
            } catch (Dcs.ConfigError e) {
                if (!(e is Dcs.ConfigError.NO_VALUE_SET)) {
                    throw e;
                }
            }
        }

        if (value_set) {
            return value;
        } else {
            throw new Dcs.ConfigError.NO_VALUE_SET (_("No value available"));
		}
    }
}
