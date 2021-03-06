/**
 * OpenDCS GUI namespace for the GNOME desktop application.
 */
namespace Dcsg {

    public Type type_from_name (string name) {
        Type? type;

        string simplified = name.down ()
                                .replace ("-", "")
                                .replace ("_", "")
                                .replace ("dcs", "");

        debug ("Get type: %s", simplified);

        // Check if the type requested is in the UI namespace
        type = Dcs.UI.type_from_name (simplified);
        if (type != null) {
            debug ("Got UI type: %s", type.name ());
            return type;
        }

        switch (simplified) {
            default:
                type = typeof (Dcs.Object);
                break;
        }

        return type;
    }

    public Gtk.CssProvider load_css (string css) {
        var provider = new Gtk.CssProvider ();
        try {
            var file = File.new_for_uri ("resource:///org/opendcs/dcs/" + css);
            provider.load_from_file (file);
        } catch (GLib.Error e) {
            GLib.warning ("Error loading css file `%s': %s", css, e.message);
        }
        return provider;
    }

    public Gdk.Pixbuf load_asset (string asset) throws GLib.Error {
        return new Gdk.Pixbuf.from_resource ("/org/opendcs/dcs/icons/" + asset);
    }

    public Gtk.Builder load_ui (string ui) {
        var builder = new Gtk.Builder ();
        try {
            builder.add_from_resource ("/org/opendcs/dcs/ui/".concat (ui, null));
        } catch (GLib.Error e) {
            GLib.error ("Failed to load UI file `%s': %s", ui, e.message);
        }
        return builder;
    }

    public Rsvg.Handle load_svg (string svg) {
        Rsvg.Handle rsvg;
        try {
            rsvg = new Rsvg.Handle.from_file (svg);
        } catch (GLib.Error e) {
            GLib.error ("Failed to load SVG file `%s': %s", svg, e.message);
        }
        return rsvg;
    }

    public Gdk.RGBA get_dcsg_bg_color () {
        var style = new Gtk.StyleContext ();
        var path = new Gtk.WidgetPath ();
        path.append_type (typeof (Gtk.Window));
        style.set_path (path);
        style.add_class ("dcsg-bg");
        return style.get_background_color (0);
    }
}
