internal class Dcs.Control.Main : GLib.Object {

    /**
     * Not sure why but having this inside CmdlineConfig blocks startup.
     */
    private struct Options {

        public static  bool version = false;

        public static const GLib.OptionEntry[] entries = {{
            "verbose", 'v', OptionFlags.NO_ARG, OptionArg.CALLBACK, (void *) verbose_cb,
            "Provide verbose debugging output.", null
        },{
            null
        }};
    }

    private bool verbose_cb () {
        Dcs.SysLog.increase_verbosity ();
        return true;
    }

    private static void parse_local_args (ref unowned string[] args) {
        var opt_context = new OptionContext (Dcs.NAME);
        opt_context.set_ignore_unknown_options (true);
        opt_context.set_help_enabled (false);
        opt_context.add_main_entries (Options.entries, null);

        try {
            opt_context.parse (ref args);
        } catch (OptionError e) {
            error (e.message);
        }
    }

    private static int PLUGIN_TIMEOUT = 5;

    private Dcs.SysLog log;
    private Dcs.Control.Server app;

    private int exit_code;

    public bool need_restart;

    private Main () throws GLib.Error {
        this.log = Dcs.SysLog.get_default ();
        log.init (true, null);

        this.exit_code = 0;

        app = new Dcs.Control.Server ();

        Unix.signal_add (Posix.SIGHUP,  () => { this.restart (); return true; });
        Unix.signal_add (Posix.SIGINT,  () => { this.exit (0);   return true; });
        Unix.signal_add (Posix.SIGTERM, () => { this.exit (0);   return true; });
    }

    /**
     * XXX should implement a state dump to capture errors and configuration
     *     when this happens
     */
    public void exit (int exit_code) {
        this.exit_code = exit_code;
        Dcs.SysLog.shutdown ();
        (app as Dcs.Control.Server).shutdown ();
    }

    public void restart () {
        this.need_restart = true;
        this.exit (0);
    }

    private int run (string[] args) {
        message ("Control Server v%s starting...", Dcs.VERSION);
        app.launch (args);

        return this.exit_code;
    }

    internal void dbus_available () {
    }

    private static int main (string[] args) {

        Dcs.Control.Main main = null;
        Dcs.Control.DBusService service = null;

        var original_args = args;

        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (Dcs.GETTEXT_PACKAGE, Dcs.LOCALEDIR);
        Intl.bind_textdomain_codeset (Dcs.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Dcs.GETTEXT_PACKAGE);

        GLib.Environment.set_prgname (_(Dcs.NAME));
        GLib.Environment.set_application_name (_(Dcs.NAME));

        try {
            parse_local_args (ref args);

            main = new Dcs.Control.Main ();
            service = new Dcs.Control.DBusService (main);
            service.publish ();
        } catch (GLib.Error e) {
            error ("%s", e.message);
        }

        /* Launch the application */
        int exit_code = main.run (args);

        if (service != null) {
            service.unpublish ();
        }

        if (main.need_restart) {
            Posix.execvp (original_args[0], original_args);
        }

        return exit_code;
    }
}