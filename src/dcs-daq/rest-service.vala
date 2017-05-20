public class Dcs.DAQ.RestService : Dcs.Net.RestService {

    /*
     *private const Dcs.Net.RouteEntry[] routes = {
     *    { "/",                 Dcs.Net.RouteArg.CALLBACK, (void*) route_default,  null },
     *    { "/channel/<int:id>", Dcs.Net.RouteArg.CALLBACK, (void*) route_channel,  null },
     *    { "/channels",         Dcs.Net.RouteArg.CALLBACK, (void*) route_channels, null },
     *    { null }
     *};
     */

    private const string bad_request = "jsonp('XXX': {'status': 400})";

    public RestService (Dcs.Net.Service service) {
        this.service = service;
        init ();
    }

    public RestService.with_port (Dcs.Net.Service service, int port) {
        this.service = service;
        GLib.Object (port: port);
        init ();
    }

    private void init () {
        base.init ();
        debug (_("Initializing the DAQ REST service"));

        add_handler (null,        route_default);
        add_handler ("/channel",  route_channel);
        add_handler ("/channels", route_channels);
        add_handler ("/device",   route_device);
        add_handler ("/devices",  route_devices);
        add_handler ("/task",     route_task);
        add_handler ("/tasks",    route_tasks);

        // XXX idea discussed for having plugins that provide their own
        // configuration pages as a route
        /*
         *foreach (var plugin in plugins) {
         *    add_handler ("/config/device/" + plugin.id, plugin.route_config);
         *    http://10.0.0.10/config/device/dev0
         *}
         */

        /*
         *add_routes (routes);
         */
    }

    /* API routes */

    /**
     * Default route serves static index page.
     */
    private void route_default (Soup.Server server,
                                Soup.Message msg,
                                string path,
                                GLib.HashTable? query,
                                Soup.ClientContext client) {

        unowned Dcs.DAQ.RestService self = server as Dcs.DAQ.RestService;

        // XXX async example that simulates load, should change
        Timeout.add_seconds (0, () => {
			string html_head = "<head><title>Index</title></head>";
			string html_body = "<body><h1>Index:</h1></body>";
			msg.set_response ("text/html", Soup.MemoryUse.COPY,
							  "<html>%s%s</html>".printf (html_head,
                                                          html_body).data);

			// Resumes HTTP I/O on msg:
			self.unpause_message (msg);
			debug ("REST default handler end");
			return false;
        }, Priority.DEFAULT);

        self.pause_message (msg);
    }

    /**
     * Channel routes to display all or work with CRUD.
     */
    private void route_channel (Soup.Server server,
                                Soup.Message msg,
                                string path,
                                GLib.HashTable? query,
                                Soup.ClientContext client) {

        // Leaving in leading / results in empty 0th token
        string[] tokens = path.substring (1).split ("/");

        /*
         *var bad_request = "jsonp('channel': {'status': %d})".printf (
         *                        Soup.Status.BAD_REQUEST);
         */

        // CRUD for channel requests
        switch (msg.method.up ()) {
            case "PUT":
                debug (_("PUT channel: not implemented"));
                break;
            case "GET":
                if (tokens.length >= 2) {
                    debug (_("GET channel: (id %s)"), tokens[1]);
                } else {
                    msg.status_code = Soup.Status.BAD_REQUEST;
                    msg.response_headers.append ("Access-Control-Allow-Origin", "*");
                    msg.set_response ("application/json",
                                      Soup.MemoryUse.COPY,
                                      bad_request.data);
                }
                break;
            case "POST":
                debug (_("POST channel: not implemented"));
                break;
            case "DELETE":
                debug (_("DELETE channel: not implemented"));
                break;
            default:
                msg.status_code = Soup.Status.BAD_REQUEST;
                msg.response_headers.append ("Access-Control-Allow-Origin", "*");
                msg.set_response ("application/json",
                                  Soup.MemoryUse.COPY,
                                  bad_request.replace ("XXX", "channel").data);
                break;
        }
    }

    private void route_channels (Soup.Server server,
                                 Soup.Message msg,
                                 string path,
                                 GLib.HashTable? query,
                                 Soup.ClientContext client) {

        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("data");
        builder.add_double_value (1.0);
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());

        var response = "jsonp(%s)".printf (generator.to_data (null));
        debug ("GET channels: %s", response);

        msg.status_code = Soup.Status.OK;
        msg.response_headers.append ("Access-Control-Allow-Origin", "*");
        msg.set_response ("application/json",
                          Soup.MemoryUse.COPY,
                          response.data);
    }

    /**
     * Device routes to display all or work with CRUD.
     */
    private void route_device (Soup.Server server,
                               Soup.Message msg,
                               string path,
                               GLib.HashTable? query,
                               Soup.ClientContext client) {

        // Leaving in leading / results in empty 0th token
        string[] tokens = path.substring (1).split ("/");

        // CRUD for task requests
        switch (msg.method.up ()) {
            case "PUT":
                debug (_("PUT device: not implemented"));
                break;
            case "GET":
                debug (_("GET device: not implemented"));
                break;
            case "POST":
                debug (_("POST device: not implemented"));
                break;
            case "DELETE":
                debug (_("DELETE device: not implemented"));
                break;
            default:
                msg.status_code = Soup.Status.BAD_REQUEST;
                msg.response_headers.append ("Access-Control-Allow-Origin", "*");
                msg.set_response ("application/json",
                                  Soup.MemoryUse.COPY,
                                  bad_request.replace ("XXX", "device").data);
                break;
        }
    }

    private void route_devices (Soup.Server server,
                                Soup.Message msg,
                                string path,
                                GLib.HashTable? query,
                                Soup.ClientContext client) {

        var response = "jsonp('devices': { 'response': 'test' })";
        debug ("GET devices: %s", response);

        msg.status_code = Soup.Status.OK;
        msg.response_headers.append ("Access-Control-Allow-Origin", "*");
        msg.set_response ("application/json",
                          Soup.MemoryUse.COPY,
                          response.data);
    }

    /**
     * Task routes to display all or work with CRUD.
     */
    private void route_task (Soup.Server server,
                             Soup.Message msg,
                             string path,
                             GLib.HashTable? query,
                             Soup.ClientContext client) {

        // Leaving in leading / results in empty 0th token
        string[] tokens = path.substring (1).split ("/");

        // CRUD for task requests
        switch (msg.method.up ()) {
            case "PUT":
                debug (_("PUT task: not implemented"));
                break;
            case "GET":
                debug (_("GET task: not implemented"));
                break;
            case "POST":
                debug (_("POST task: not implemented"));
                break;
            case "DELETE":
                debug (_("DELETE task: not implemented"));
                break;
            default:
                msg.status_code = Soup.Status.BAD_REQUEST;
                msg.response_headers.append ("Access-Control-Allow-Origin", "*");
                msg.set_response ("application/json",
                                  Soup.MemoryUse.COPY,
                                  bad_request.replace ("XXX", "task").data);
                break;
        }
    }

    private void route_tasks (Soup.Server server,
                              Soup.Message msg,
                              string path,
                              GLib.HashTable? query,
                              Soup.ClientContext client) {

        var response = "jsonp('tasks': { 'response': 'test' })";
        debug ("GET tasks: %s", response);

        msg.status_code = Soup.Status.OK;
        msg.response_headers.append ("Access-Control-Allow-Origin", "*");
        msg.set_response ("application/json",
                          Soup.MemoryUse.COPY,
                          response.data);
    }
}
