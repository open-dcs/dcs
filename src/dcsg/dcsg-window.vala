/**
 * The Gtk.Application class expects an ApplicationWindow so a lot is being
 * moved here from outside of the actual view class.
 */
[GtkTemplate (ui = "/org/opendcs/dcs/ui/window.ui")]
public class Dcsg.Window : Dcs.UI.WindowBase {

    private string _xml = """
    """;

    private string _xsd = """
    """;

    /**
     * {@inheritDoc}
     */
    protected override string xml {
        get { return _xml; }
    }

    /**
     * {@inheritDoc}
     */
    protected override string xsd {
        get { return _xsd; }
    }

    /**
     * {@inheritDoc}
     */
    private Gee.Map<string, Dcs.Object> _objects;
    public override Gee.Map<string, Dcs.Object> objects {
        get { return _objects; }
        set { update_objects (value); }
    }

    /**
     * {@inheritDoc}
     */
    public string id { get; set; }

    /* Property backing fields */
    private int _chan_scroll_min_width = 50;

    /**
     * From previous versions, limits the width of an interface element.
     */
    public int chan_scroll_min_width {
        get { return _chan_scroll_min_width; }
        set { _chan_scroll_min_width = value; }
    }

    /**
     * The value is controlled by the existence of certain configuration
     * elements. If it's true a default interface layout will be constructed
     * otherwise a valid layout is expected to be provided.
     */
    public bool using_default { get; private set; default = true; }

    /* Current window state */
    public bool fullscreen { get; set; default = false; }

    /* Model used to update the view */
    public Dcs.Model model { get; construct set; }

    /* Layout - XXX maybe the Window should contain the layout? */
    public Dcsg.Layout layout { get; construct set; }

    [GtkChild]
    private Dcsg.Topbar topbar;

    [GtkChild]
    private Gtk.Stack stack;

    [GtkChild]
    private Gtk.Revealer settings;

    [GtkChild]
    private Dcsg.Loader loader;

    [GtkChild]
    private Dcsg.ConfigurationEditor configuration;

    [GtkChild]
    private Dcsg.CsvExport export;

    [GtkChild]
    private Gtk.Box main_vbox;

    [GtkChild]
    private Gtk.Overlay overlay;

    private uint configure_id;

    public static const uint configure_id_timeout = 100;    // ms

    private string previous_page;

    public Dcs.UI.WindowState state {
        get;
        set;
        default = Dcs.UI.WindowState.WINDOWED;
    }

    /* List of pages default that get added, default layout omitted */
    private string[] pages = {
        "loader",
        "configuration",
        "export",
        "settings"
    };

    /* Common construction */
    construct {
        id = "rootwin0";
    }

    /**
     * Default construction.
     *
     * @param model Data model class that the interface uses to update itself
     * @return A new instance of an Window object
     */
    internal Window (Dcs.Model model) {
        GLib.Object (title: "Data Acquisition and Control",
                     window_position: Gtk.WindowPosition.CENTER);

        this.model = model;
        assert (this.model != null);

        /* FIXME: Load previous window size and fullscreen state using settings. */
        set_default_size (1280, 720);

        topbar.application_toolbar.title = title;
        topbar.application_toolbar.subtitle = model.config_filename;

        settings.set_transition_type (Gtk.RevealerTransitionType.SLIDE_LEFT);

        setup ();
        load_style ();
    }

    /**
     * {@inheritDoc}
     */
    public override void build_from_xml_node (Xml.Node *node) {
        // XXX do something
    }

    private void setup () {
        stack.transition_duration = 400;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.expand = true;

        configuration.filename = model.config_filename;
    }

    /**
     * Load the application styling from CSS.
     */
    private void load_style () {
        /* XXX use resource instead - see gtk3-demo for example */
        /* Apply stylings from CSS resource */
        var provider = Dcsg.load_css ("theme/shared.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (),
                                                  provider,
                                                  600);
    }

    public void add_actions () {
        var fullscreen_action = new SimpleAction ("fullscreen", null);
        fullscreen_action.activate.connect (fullscreen_action_activated_cb);
        this.add_action (fullscreen_action);
    }

    /**
     * Construct the layout using the contents of the configuration file.
     *
     * Lists of objects included:
     * - pages
     * - boxes
     * - trees
     * - charts
     * - control views
     * - module/plugin views
     */
    public void construct_layout () {

        /* Currently only pages can be added to the notebook */
        var pages = model.get_object_map (typeof (Dcs.UI.Page));
        if (pages.size == 0) {
            layout_add_page (new Dcs.UI.Page ());
        } else {
            foreach (var page in pages.values) {
                message ("Constructing layout for page `%s'", page.id);
                layout_add_page (page as Dcs.UI.Page);
            }
        }

        stack.show_all ();

        layout_change_page ((model as Dcsg.Model).startup_page);
        connect_signals ();
    }

    public void add_window (Dcs.UI.Window window) {
        model.add_child (window as Dcs.Object);
        window.add_actions ();
        window.show_all ();
    }

    public void layout_add_page (Dcs.UI.Page page) {
        message ("Adding page `%s' with title `%s'", page.id, page.title);
        stack.add_titled (page, page.id, page.title);
        pages += page.id;

        model.add_child (page);
    }

    public void layout_change_page (string id) {
        debug ("Changing layout page from `%s' to `%s'", stack.visible_child_name, id);
        if (stack.visible_child_name != id) {
            if (id == "loader" && stack.visible_child != loader) {
                previous_page = stack.visible_child_name;
                stack.visible_child = loader;
                topbar.set_visible_child_name (id);
            } else if (id == "configuration" && stack.visible_child != configuration) {
                previous_page = stack.visible_child_name;
                stack.visible_child = configuration;
                topbar.set_visible_child_name (id);
            } else if (id == "export" && stack.visible_child != export) {
                previous_page = stack.visible_child_name;
                stack.visible_child = export;
                topbar.set_visible_child_name (id);
            } else {
                stack.set_visible_child_name (id);
                topbar.set_visible_child_name ("application");
            }
        }
    }

    public void layout_back_page () {
        var id = previous_page;
        layout_change_page (id);
    }

    public void layout_previous_page () {
        int pos = -1;

        for (int i = 0; i < pages.length; i++) {
            if (stack.visible_child_name == pages[i])
                pos = i;
        }

        if (pos != -1 && pages[pos - 1] != "settings") {
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            layout_change_page (pages[pos - 1]);
            stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        }
    }

    public void layout_next_page () {
        int pos = -1;

        for (int i = 0; i < pages.length; i++) {
            if (stack.visible_child_name == pages[i])
                pos = i;
        }

        if (pos != -1 && pages[pos + 1] != "loader") {
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            layout_change_page (pages[pos + 1]);
            stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        }
    }

    public void connect_signals () {
        /* Callbacks with functions */
        var treeviews = model.get_object_map (typeof (Dcs.UI.ChannelTreeView));
        foreach (var treeview in treeviews.values) {
            (treeview as Dcs.UI.ChannelTreeView).channel_selected.connect (treeview_channel_selected_cb);
        }

        var settables = model.get_object_map (typeof (Dcs.UI.Settable));
        foreach (var settable in settables.values) {
            (settable as Dcs.UI.Settable).reveal_menu.connect ((settings_menu) => {
                var style = settings_menu.get_style_context ();
                style.add_class ("background");

                if (settings.get_child () != settings_menu) {
                    settings.remove (settings.get_child ());
                    settings.add (settings_menu);
                    settings.set_reveal_child (true);
                } else {

                    /* Reveal the settings if hidden */
                    settings.set_reveal_child (!settings.get_reveal_child ());
                }
            });
        }
    }

    /**
     * {@inheritDoc}
     */
    public override void update_objects (Gee.Map<string, Dcs.Object> val) {
        _objects = val;
    }

    private void treeview_channel_selected_cb (string id) {
        debug ("Selected channel `%s' to be highlighted on chart", id);
        var channel = model.ctx.get_object (id);

        /**
         * FIXME: the stripchart class doesn't use the chart as its base yet
         */
        var charts = model.get_object_map (typeof (Dcs.UI.StripChart));
        foreach (var chart in charts.values) {
            (chart as Dcs.UI.StripChart).highlight_trace (id);
        }

        charts = model.get_object_map (typeof (Dcs.UI.RTChart));
        foreach (var chart in charts.values) {
            (chart as Dcs.UI.RTChart).highlight_trace (id);
        }
    }

    /**
     * Action callback to set fullscreen window mode.
     */
    private void fullscreen_action_activated_cb (SimpleAction action,
                                                 Variant? parameter) {
        if (state == Dcs.UI.WindowState.WINDOWED) {
            (this as Gtk.Window).fullscreen ();
            state = Dcs.UI.WindowState.FULLSCREEN;
            fullscreen = true;
        } else {
            (this as Gtk.Window).unfullscreen ();
            state = Dcs.UI.WindowState.WINDOWED;
            fullscreen = false;
        }
    }

    [GtkCallback]
    public bool key_pressed_cb (Gdk.EventKey event) {
        var app = Dcsg.Application.get_default ();
        var modifiers = Gtk.accelerator_get_default_mod_mask ();

        if (event.keyval == Gdk.Key.Home) {             // Home -> go to default
            layout_change_page ((model as Dcsg.Model).startup_page);
        } else if (event.keyval == Gdk.Key.F11) {       // F11 -> fullscreen
            if (state == Dcs.UI.WindowState.WINDOWED) {
                (this as Gtk.Window).fullscreen ();
                state = Dcs.UI.WindowState.FULLSCREEN;
                fullscreen = true;
            } else {
                (this as Gtk.Window).unfullscreen ();
                state = Dcs.UI.WindowState.WINDOWED;
                fullscreen = false;
            }
            return true;
        } else if (event.keyval == Gdk.Key.F1) {        // F1 -> open help
            app.activate_action ("help", null);
            return true;
        } else if (event.keyval == Gdk.Key.q &&         // CTRL + q -> quit
                   (event.state & modifiers) == Gdk.ModifierType.CONTROL_MASK) {
            app.activate_action ("quit", null);
            return true;
        } else if (event.keyval == Gdk.Key.o &&         // CTRL + o -> loader
                   (event.state & modifiers) == Gdk.ModifierType.CONTROL_MASK) {
            layout_change_page ("loader");
            return true;
        } else if (event.keyval == Gdk.Key.x &&         // CTRL + x -> export
                   (event.state & modifiers) == Gdk.ModifierType.CONTROL_MASK) {
            layout_change_page ("export");
            return true;
        } else if (event.keyval == Gdk.Key.Left &&      // ALT + Left -> back
                   (event.state & modifiers) == Gdk.ModifierType.MOD1_MASK) {
            layout_previous_page ();
            return true;
        } else if (event.keyval == Gdk.Key.Right &&     // ALT + Right -> fwd
                   (event.state & modifiers) == Gdk.ModifierType.MOD1_MASK) {
            layout_next_page ();
            return true;
        } else if (event.keyval == Gdk.Key.Escape) {    // ESC -> cancel
            /* Hide the revealed widget settings */
            settings.set_reveal_child (false);
        }

        return false;
    }

    [GtkCallback]
    private bool configure_event_cb () {
        if (state == Dcs.UI.WindowState.FULLSCREEN)
            return false;

        if (configure_id != 0)
            GLib.Source.remove (configure_id);

        configure_id = Timeout.add (configure_id_timeout, () => {
            configure_id = 0;
            //save_window_geometry ();
            return false;
        });

        return false;
    }

    [GtkCallback]
    private bool window_state_event_cb (Gdk.EventWindowState event) {
        if (Dcs.UI.WindowState.FULLSCREEN in event.changed_mask)
            this.notify_property ("fullscreen");

        if (state == Dcs.UI.WindowState.FULLSCREEN)
            return false;

        //settings.set_boolean ("window-maximized", maximized);

        return false;
    }

    [GtkCallback]
    private bool delete_event_cb () {
        /**
         * FIXME: this doesn't work, it still closes the window, not really a
         *        big surprise though
         * FIXME: should be checking if the window was closed during an
         *        important operation, or while in a state that could cause
         *        issues
         * FIXME: this should just chain up to the application quit but is
         *        doesn't seem to want to fire the dialog when it does
         */

/*
 *        var dialog = new Gtk.MessageDialog (null,
 *                                            Gtk.DialogFlags.MODAL,
 *                                            Gtk.MessageType.QUESTION,
 *                                            Gtk.ButtonsType.YES_NO,
 *                                            "Are you sure you want to quit?");
 *
 *        (dialog as Gtk.Dialog).response.connect ((response_id) => {
 *            switch (response_id) {
 *                case Gtk.ResponseType.NO:
 *                    (dialog as Gtk.Dialog).destroy ();
 *                    break;
 *                case Gtk.ResponseType.YES:
 *                    var app = Dcsg.Application.get_default ();
 *                    app.remove_window (this);
 *                    (dialog as Gtk.Dialog).destroy ();
 *                    app.quit ();
 *                    break;
 *            }
 *        });
 *
 *        (dialog as Gtk.Dialog).run ();
 */

        var app = Dcsg.Application.get_default ();
        app.remove_window (this);
        app.quit ();

        return false;
    }
}
