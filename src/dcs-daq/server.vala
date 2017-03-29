public class Dcs.DAQ.Server : Dcs.CLI.Application {

    private GLib.MainLoop loop;

    public Dcs.DAQ.RestService rest_service;

    public Dcs.DAQ.ZmqService zmq_service;

    internal Server () {
        GLib.Object (application_id: "org.opendcs.dcs.daq");

        loop = new GLib.MainLoop ();

        rest_service = new Dcs.DAQ.RestService ();
        zmq_service = new Dcs.DAQ.ZmqService.with_conn_info (
            Dcs.Net.ZmqTransport.TCP, "*", 5588);
    }

    protected override void activate () {
        base.activate ();

        debug (_("Activating DAQ Server"));
        loop.run ();
    }

    protected override void startup () {
        debug (_("Starting DAQ server > Main"));
        base.startup ();

        debug (_("Starting DAQ server > ZMQ Service"));
        zmq_service.run ();
    }

    protected override void shutdown () {
        debug (_("Shuting down DAQ Server"));
        loop.quit ();

        base.shutdown ();
    }

    static bool opt_help;
    static const OptionEntry[] options = {{
        "help", 'h', 0, OptionArg.NONE, ref opt_help, null, null
    },{
        null
    }};

    public override int command_line (GLib.ApplicationCommandLine cmdline) {
        opt_help = false;

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
        }

        return 0;
    }
}
