/**
 * The view class in an MVC design is responsible for updating the display based
 * on the changes made to the model.
 *
 * XXX should consider adding signals where necessary in the model and only
 *     update the view when it fires a signal to improve performance.
 */
public class Dcsg.Application : Dcs.UI.Application {

    /* Application singleton */
    private static Dcsg.Application app;

    /**
     * User interface layout manager.
     */
    private Dcsg.UxManager ux_manager;

    /**
     * Used when the user requests a configuration save.
     */
    public signal void save_requested ();

    /**
     * Used to inform anything when the view has been constructed.
     */
    public signal void view_constructed ();

    /**
     * Returns the singleton for this class creating it first if it hasn't
     * been yet.
     */
    public static new Dcsg.Application get_default () {
        if (app == null) {
            app = new Dcsg.Application ();
        }
        return app;
    }

    /**
     * Default construction.
     */
    internal Application () {
        string[] args1 = {};
        unowned string[] args2 = args1;
        Gtk.init (ref args2);

        debug ("Application construction");

        GLib.Object (application_id: "org.opendcs.dcsg",
                     flags: ApplicationFlags.HANDLES_COMMAND_LINE |
                            ApplicationFlags.HANDLES_OPEN);

        plugins = new Gee.ArrayList<Dcs.LegacyPlugin> ();
    }

    /**
     * Load and launch the application window.
     */
    protected override void activate () {
        base.activate ();

        Gtk.Window.set_default_icon_name ("dcsg");

        WebKit.WebContext.get_default ().set_web_extensions_directory (Dcs.Build.WEB_EXTENSION_DIR);

        debug ("Creating application model using file %s", opt_cfgfile);
        model = new Dcsg.Model (opt_cfgfile);
        assert (model != null);

        (model as Dcs.Container).print_objects (0);
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme =
            (model as Dcsg.Model).dark_theme;

        debug ("Finished constructing the model");

        view = new Dcsg.Window (model);
        assert (view != null);
        (view as Gtk.Window).application = this;

        debug ("Finished constructing the view");

        ux_manager = new Dcsg.UxManager ((Dcsg.Window) view);

        /**
         * FIXME: This hides the window and then shows the message box
         *
         *(view as Gtk.Window).destroy.connect (() => {
         *    activate_action ("quit", null);
         *});
         */

        controller = new Dcsg.Controller ((Dcsg.Model) model,
                                          (Dcsg.Window) view);
        assert (controller != null);
        debug ("Finished constructing the controller");
        (controller as Dcsg.Controller).init ();

        view_constructed ();

        connect_signals ();
        add_actions ();

        debug ("Starting device acquisition and output tasks");
        controller.start_acquisition ();
        controller.start_device_output ();

        debug ("Application activation completed");
    }

    /**
     * Perform the application setup including connecting interface callbacks
     * to the various actions.
     */
    protected override void startup () {
        base.startup ();
        add_app_menu ();
    }

    private void add_app_menu () {
        /*
         *var view_menu = new GLib.Menu ();
         *view_menu.append ("Configuration", "app.configuration");
         *view_menu.append ("Loader", "app.loader");
         *view_menu.append ("Data", "app.data");
         *view_menu.append ("Recent", "app.recent");
         *view_menu.append ("Digital I/O", "app.digio");
         */

        var menu = new GLib.Menu ();

        if (model.admin) {
            debug ("Adding a menu for admin functionality");
            var admin_menu = new GLib.Menu ();
            admin_menu.append ("Defaults", "app.defaults");
            menu.append_submenu ("Admin", admin_menu);
        }

        /*
         *menu.append_section (null, view_menu);
         */

        //menu.append_section (null, settings_menu);
        var preferences_section = new GLib.Menu ();
        preferences_section.append ("Preferences", "app.settings");
        menu.append_section (null, preferences_section);
        var other_section = new GLib.Menu ();
        other_section.append ("Help", "app.help");
        other_section.append ("About Dcs", "app.about");
        other_section.append ("Quit", "app.quit");
        menu.append_section (null, other_section);

        set_app_menu (menu);
    }

    private void connect_signals () {
        controller.notify["admin"].connect (() => {
            model.admin = controller.admin;
        });
    }

    /**
     * XXX should load these as an ActionGroup using a UI resource file - or,
     *     if possible make the application a composite
     */
    private void add_actions () {
        if (controller.admin) {
            var admin_action = new SimpleAction ("admin", null);
            add_action (admin_action);
        }

        /* file menu actions */
        var save_action = new SimpleAction ("save", null);
        save_action.activate.connect (save_activated_cb);
        this.add_action (save_action);

        /* view menu actions */
        var view_data_action = new SimpleAction ("data", null);
        view_data_action.activate.connect (view_data_activated_cb);
        this.add_action (view_data_action);

        var configuration_action = new SimpleAction ("configuration", null);
        configuration_action.activate.connect (configuration_activated_cb);
        this.add_action (configuration_action);

        var configuration_back_action = new SimpleAction ("configuration-back", null);
        configuration_back_action.activate.connect (configuration_back_activated_cb);
        this.add_action (configuration_back_action);

        var export_action = new SimpleAction ("export", null);
        export_action.activate.connect (export_activated_cb);
        this.add_action (export_action);

        var export_back_action = new SimpleAction ("export-back", null);
        export_back_action.activate.connect (export_back_activated_cb);
        this.add_action (export_back_action);

        var loader_action = new SimpleAction ("loader", null);
        loader_action.activate.connect (loader_activated_cb);
        this.add_action (loader_action);

        var loader_back_action = new SimpleAction ("loader-back", null);
        loader_back_action.activate.connect (loader_back_activated_cb);
        this.add_action (loader_back_action);

        /* admin menu actions */
        var defaults_action = new SimpleAction.stateful ("defaults", null, new Variant.boolean (false));
        defaults_action.activate.connect (defaults_activated_cb);
        this.add_action (defaults_action);

        /* top-level menu actions */
        var help_action = new SimpleAction ("help", null);
        help_action.activate.connect (help_activated_cb);
        this.add_action (help_action);

        var about_action = new SimpleAction ("about", null);
        about_action.activate.connect (about_activated_cb);
        this.add_action (about_action);

        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (quit_activated_cb);
        this.add_action (quit_action);

        var previous_page_action = new SimpleAction ("previous-page", null);
        previous_page_action.activate.connect (previous_page_activated_cb);
        this.add_action (previous_page_action);

        var next_page_action = new SimpleAction ("next-page", null);
        next_page_action.activate.connect (next_page_activated_cb);
        this.add_action (next_page_action);

        var settings_action = new SimpleAction ("settings", null);
        settings_action.activate.connect (settings_activated_cb);
        this.add_action (settings_action);

        var settings_ok_action = new SimpleAction ("settings-ok", null);
        settings_ok_action.activate.connect (settings_ok_activated_cb);
        this.add_action (settings_ok_action);

        /* Handling some of the actions at the view level to reduce the need to
         * make public a lot of widget content. */
        (view as Dcsg.Window).add_actions ();
    }

    /**
     * {@inheritDoc}
     */
    public override void shutdown () {
        base.shutdown ();

        debug ("Stopping device acquisition and output tasks");
        controller.stop_acquisition ();
        controller.stop_device_output ();

        /* Let someone else deal with shutting down. */
        closed ();
    }

    static bool opt_admin;
    static bool opt_help;
    static string opt_cfgfile;
    static const OptionEntry[] options = {{
        "admin", 'a', 0, OptionArg.NONE, ref opt_admin,
        "Allow administrative functionality.", null
    },{
        "cli", 'c', 0, OptionArg.NONE, null,
        "Start the application with a command line interface", null
    },{
        "config", 'f', 0, OptionArg.STRING, ref opt_cfgfile,
        "Use the given configuration file.", null
    },{
        "help", 'h', 0, OptionArg.NONE, ref opt_help,
        null, null
    },{
        "verbose", 'v', 0, OptionArg.NONE, null,
        "Provide verbose debugging output.", null
    },{
        "version", 'V', 0, OptionArg.NONE, null,
        "Display version number.", null
    },{
        null
    }};

    public override int command_line (GLib.ApplicationCommandLine cmdline) {
        opt_admin = false;
        opt_help = false;
        opt_cfgfile = null;

        var opt_context = new OptionContext (Dcs.Build.PACKAGE_NAME);
        opt_context.add_main_entries (options, null);
        opt_context.set_help_enabled (false);

        try {
            string[] args1 = cmdline.get_arguments ();
            unowned string[] args2 = args1;
            opt_context.parse (ref args2);
        } catch (OptionError e) {
           cmdline.printerr ("error: %s\n", e.message);
           cmdline.printerr (opt_context.get_help (true, null));
           return 1;
        }

        if (opt_help) {
            cmdline.printerr (opt_context.get_help (true, null));
            return 1;
        }

        if (opt_cfgfile == null) {
            opt_cfgfile = Path.build_filename (Dcs.Build.DATADIR, "dcs.xml");
            GLib.message ("Configuration file not provided, using %s", opt_cfgfile);
        }

        controller.admin = opt_admin;

        /* XXX not sure if this is the correct way to use this yet */
        activate ();

        return 0;
    }

    public override void open (GLib.File[] files, string hint) {
		try {
            var tmp = File.new_for_path ("/tmp/dcs.out");
            var ios = tmp.create_readwrite (FileCreateFlags.PRIVATE);
            var os = ios.output_stream;
            var dos = new DataOutputStream (os);
            dos.put_string ("Test output:\n\n");

            foreach (var file in files) {
                stderr.printf ("Reading from file: %s\n", file.get_uri ());
                dos.put_string ("Reading from file: %s\n".printf (file.get_uri ()));

                try {
                    //var arrangement = Tabler.load_from_file (file.get_uri ());
                    //create_window (arrangement);
                } catch (GLib.Error e) {
                    stderr.printf (_("An error occured while reading file %s: %s\n"),
                                file.get_uri (), e.message);
                    dos.put_string (_("An error occured while reading file %s: %s\n".printf (
                                    file.get_uri (), e.message)));
                    //create_window (new Arrangement ());
                    //show_error (_("Invalid file"), _("Error loading %s."),
                                //file.get_basename ());
                    continue;
                } catch (FileError e) {
                    //create_window (new Arrangement ());
                    //show_error (_("File not found or could not be read."),
                                //_("%s not found or could not be read."), file.get_path ());
                    continue;
                }
            }
		} catch (Error e) {
            error ("Received error %s", e.message);
		} catch (IOError e) {
            error ("Received I/O error %s", e.message);
		}
    }

    /**
     * Action callback for quit.
     */
    private void quit_activated_cb (SimpleAction action, Variant? parameter) {
        var dialog = new Gtk.MessageDialog (null,
                                            Gtk.DialogFlags.MODAL,
                                            Gtk.MessageType.QUESTION,
                                            Gtk.ButtonsType.YES_NO,
                                            "Are you sure you want to quit?");

        (dialog as Gtk.Dialog).response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.NO:
                    (dialog as Gtk.Dialog).destroy ();
                    break;
                case Gtk.ResponseType.YES:
                    (dialog as Gtk.Dialog).destroy ();
                    this.quit ();
                    break;
            }
        });

        (dialog as Gtk.Dialog).run ();
    }

    /**
     * Action callback for admin - not sure why yet.
     */
    private void admin_activated_cb (SimpleAction action, Variant? parameter) {
        debug ("Nothing yet.");
    }

    /**
     * Action callback for settings.
     */
    private void settings_activated_cb (SimpleAction action, Variant? parameter) {
        GLib.debug ("Settings: Dialog activated.");
        int x, y, wp, hp, ws, hs;
        //(view as Dcsg.Window).layout_change_page ("settings");
        (view as Gtk.Window).get_position (out x, out y);
        (view as Gtk.Window).get_size (out wp, out hp);
        var settings = new Dcsg.SettingsDialog ();
        settings.delete_event.connect ((settings as Gtk.Widget).hide_on_delete);
        settings.get_size (out ws, out hs);

        settings.title = "Settings";
        settings.set_default_size (320, 240);
        settings.modal = true;
        settings.transient_for = view as Gtk.Window;
        settings.move (x + wp / 2 - ws / 2, y + hp / 2 - hs / 2);

        settings.show_all ();
    }

    /**
     * Action callback to apply application settings.
     */
    private void settings_ok_activated_cb (SimpleAction action, Variant? parameter) {
        debug ("The OK button was pressed in the Settings Dialog.");
    }

    /**
     * Action callback for configuration.
     */
    private void configuration_activated_cb (SimpleAction action, Variant? parameter) {
        (view as Dcsg.Window).layout_change_page ("configuration");

    }

    /**
     * Action callback for going back to previous page from configuration.
     */
    private void configuration_back_activated_cb (SimpleAction action, Variant? parameter) {
        (view as Dcsg.Window).layout_back_page ();
    }

    /**
     * Action callback for CSV export.
     */
    private void export_activated_cb (SimpleAction action, Variant? parameter) {
        (view as Dcsg.Window).layout_change_page ("export");
    }

    /**
     * Action callback for going back to previous page from the CSV export.
     */
    private void export_back_activated_cb (SimpleAction action, Variant? parameter) {
        (view as Dcsg.Window).layout_back_page ();
    }

    /**
     * Action callback for configuration loader.
     */
    private void loader_activated_cb (SimpleAction action, Variant? parameter) {
        (view as Dcsg.Window).layout_change_page ("loader");
    }

    /**
     * Action callback for going back to previous page from the configuration loader.
     */
    private void loader_back_activated_cb (SimpleAction action, Variant? parameter) {
        (view as Dcsg.Window).layout_back_page ();
    }

    /**
     * Action callback for going to the previous available non-settings page.
     */
    private void previous_page_activated_cb (SimpleAction action, Variant? parameter) {
        (view as Dcsg.Window).layout_previous_page ();
    }

    /**
     * Action callback for going to the next available non-settings page.
     */
    private void next_page_activated_cb (SimpleAction action, Variant? parameter) {
        (view as Dcsg.Window).layout_next_page ();
    }

    /**
     * Action callback for saving the configuration file.
     */
    private void save_activated_cb (SimpleAction action, Variant? parameter) {
        /* Warn the user if <defaults> are currently enabled */
        if (model.def_enabled) {
            var msg = "Calibrations are set to defaults.\nDo you still want to save?";
            var dialog = new Gtk.MessageDialog (null,
                                                Gtk.DialogFlags.MODAL,
                                                Gtk.MessageType.QUESTION,
                                                Gtk.ButtonsType.YES_NO,
                                                msg);

            (dialog as Gtk.Dialog).response.connect ((response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.YES:
                        (dialog as Gtk.Dialog).destroy ();
                        break;
                    case Gtk.ResponseType.NO:
                        (dialog as Gtk.Dialog).destroy ();
                        return;
                    default:
                        break;
                }
            });

            (dialog as Gtk.Dialog).run ();
        }

        /* Second check to confirm overwrite this time */
        var dialog = new Gtk.MessageDialog (null,
                                            Gtk.DialogFlags.MODAL,
                                            Gtk.MessageType.QUESTION,
                                            Gtk.ButtonsType.YES_NO,
                                            "Overwrite %s with application preferences?",
                                            model.config.file_name);

        (dialog as Gtk.Dialog).response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.YES:
                    /* Signal the controller if the user selected yes */
                    (dialog as Gtk.Dialog).destroy ();
                    save_requested ();
                    break;
                case Gtk.ResponseType.NO:
                    (dialog as Gtk.Dialog).destroy ();
                    return;
                default:
                    break;
            }
        });

        (dialog as Gtk.Dialog).run ();
    }

    /**
     * Action callback for acquire.
     */
    private void acquire_activated_cb (SimpleAction action, Variant? parameter) {
        this.hold ();
        Variant state = action.get_state ();
        bool active = state.get_boolean ();
        action.set_state (new Variant.boolean (!active));
        /* XXX locking the model may not be necessary, from older version */
        if (!active) {
            controller.start_acquisition ();
            controller.start_device_output ();
        } else {
            controller.stop_acquisition ();
            controller.stop_device_output ();
        }
        this.release ();
    }

    /**
     * Action callback for defaults.
     */
    private void defaults_activated_cb (SimpleAction action, Variant? parameter) {
        this.hold ();
        Variant state = action.get_state ();
        bool active = state.get_boolean ();
        action.set_state (new Variant.boolean (!active));

        var channels = model.ctx.get_object_map (typeof (Cld.Channel));

        if (!active) {
            model.def_enabled = true;
            foreach (var channel in channels.values) {
                /* Don't scale output channels */
                if (!(channel is Cld.AOChannel)) {
                    stdout.printf ("Found channel: %s reading %f\n",
                        channel.id, (channel as Cld.ScalableChannel).scaled_value);
                    var cal = (channel as Cld.ScalableChannel).calibration;
                    stdout.printf ("Found calibration: %s units %s\n",
                        cal.id, cal.units);
                    cal.units = "Volts";
                    foreach (var coefficient in cal.coefficients.values) {
                        stdout.printf ("Found coefficient: %s\n", coefficient.id);
                        if ((coefficient as Cld.Coefficient).n == 1)
                            (coefficient as Cld.Coefficient).value = 1.0;
                        else
                            (coefficient as Cld.Coefficient).value = 0.0;
                    }
                }
            }
        } else {
            /* FIXME: the application shouldn't have to use XPath for edits */
            model.def_enabled = false;
            foreach (var channel in channels.values) {
                /* Don't scale output channels */
                if (!(channel is Cld.AOChannel)) {
                    stdout.printf ("Found channel: %s reading %f\n",
                        channel.id, (channel as Cld.ScalableChannel).scaled_value);
                    var cal = (channel as Cld.ScalableChannel).calibration;
                    stdout.printf ("Found calibration: %s units %s\n",
                        cal.id, cal.units);

                    var xpath = "//cld/cld:objects/cld:object[@id=\"%s\"]/cld:property[@name=\"units\"]".printf (cal.id);
                    string value;

                    try {
                        value = model.xml.value_at_xpath (xpath);
                        cal.units = value;
                    } catch (Cld.XmlError error) {
                        warning (error.message);
                    }

                    foreach (var coefficient in cal.coefficients.values) {
                        stdout.printf ("Found coefficient: %s\n", coefficient.id);
                        xpath = "//cld/cld:objects/cld:object[@id=\"%s\"]/cld:object[@id=\"%s\"]/cld:property[@name=\"value\"]".printf (cal.id, coefficient.id);
                        try {
                            value = model.xml.value_at_xpath (xpath);
                            stdout.printf ("Printing @ %s: value: %s\n", xpath, value);
                            (coefficient as Cld.Coefficient).value = double.parse (value);
                        } catch (Cld.XmlError error) {
                            warning (error.message);
                        }
                    }
                }
            }
        }
        this.release ();
    }

    /**
     * Action callback for about.
     */
    private void about_activated_cb (SimpleAction action, Variant? parameter) {
        var window = get_active_window ();

        string[] authors = {
            "Geoff Johnson <geoff.jay@gmail.com>",
            "Stephen Roy <stephen.roy@coanda.ca>"
        };

        string[] documenters = {
            "Geoff Johnson <geoff.jay@gmail.com>",
            "Stephen Roy <stephen.roy@coanda.ca>"
        };

        string comments = "OpenDCS - dcsg is an application for data acquisition and control for the GNOME Desktop";

        Gdk.Pixbuf? logo = null;
        try {
            logo = Dcsg.load_asset ("dcs.svg");
        } catch (GLib.Error error) {
            warning (error.message);
        }

         Gtk.AboutDialog dialog = new Gtk.AboutDialog ();
         dialog.set_destroy_with_parent (true);
         dialog.set_transient_for (window);
         dialog.set_modal (true);
         dialog.authors = authors;
         dialog.comments = comments;
         dialog.copyright = "Copyright © 2016 Geoff Johnson";
         dialog.set_license_type (Gtk.License.MIT_X11);
         dialog.documenters = documenters;
         dialog.logo = logo;
         dialog.version = Dcs.Build.PACKAGE_VERSION;
         dialog.website = "http://open-dcs.github.io";
         dialog.website_label = "OpenDCS";

         dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
                dialog.hide_on_delete ();
            }
         });

        dialog.present ();
    }

    /**
     * Action callback for help.
     */
    private void help_activated_cb (SimpleAction action, Variant? parameter) {
        GLib.debug ("Help: Documentation viewer activated.");
    }

    /**
     * View menu actions.
     */
    private void view_data_activated_cb (SimpleAction action, Variant? parameter) {
        GLib.debug ("View: Data viewer action activated");
    }
}
