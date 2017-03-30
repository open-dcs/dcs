public class Dcs.UI.HeatMap : GLib.Object, Dcs.Object, Dcs.Container,
                                               Dcs.Buildable, Dcs.UI.Drawable {

    private Gee.Map<string, Dcs.Object> _objects;
    private Xml.Node* _config_node;

    /**
     * {@inheritDoc}
     */
    public string id { get; set; default = "heatmap0"; }
    /* compute grid */

    /**
     * {@inheritDoc}
     */
    public Gee.Map<string, Dcs.Object> objects {
        get { return _objects; }
        set { update_objects (value); }
    }

    /**
     * {@inheritDoc}
     */
    protected virtual Xml.Node* config_node {
        get {
            return _config_node;
        }
        set {
            _config_node = value;
        }
    }

    /**
     * {@inheritDoc}
     */
    public unowned Cairo.ImageSurface image_surface { get; set; }

    /* defines the boundary of the map */
    private double xmin;
    private double xmax;
    private double ymin;
    private double ymax;

    /* XXX Make a color map with arbitrary break points instead of max and min */
    /* The minimum value to be mapped to a color */
    private double zmin;

    /* The maximum value to be mapped to a color */
    private double zmax;

    /* The color that min is mapped to */
    protected string min_color_spec { get; set; default = "black"; }

    protected Gdk.RGBA _min_color;

    public Gdk.RGBA min_color  {
        get { return _min_color; }
        set {
            _min_color = value;
            min_color_spec = min_color.to_string ();
        }
    }

    /* The color that max is mapped to */
    protected string max_color_spec { get; set; default = "white"; }

    protected Gdk.RGBA _max_color;

    public Gdk.RGBA max_color  {
        get { return _max_color; }
        set {
            _max_color = value;
            max_color_spec = max_color.to_string ();
        }
    }

    /* Specifies the method used for interpolation */
    protected string interpolation_type { get; set; default = "none"; }

    private Dcs.UI.HeatMap.Data data;

    private Dcs.UI.ChannelMatrix channel_matrix = null;

    /* Represents one square on the heat map */
    private struct Cell {
        public int row;
        public int column;
        public Dcs.TriplePoint point;
        public Gdk.RGBA color;
        public Cairo.Rectangle rect;
        public string chref;
    }

    /* Data representation of the grid of cells */
    private class Data : Gee.LinkedList<Dcs.UI.HeatMap.Cell?> {

        private double _cell_width;
        public double cell_width { get { return _cell_width; } set { _cell_width = value; }}

        private double _cell_height;
        public double cell_height { get { return _cell_height; } set { _cell_height = value; }}

        private int _rows;
        public int rows { get { return _rows; } set { _rows = value; }}

        private int _columns;
        public int columns { get { return _columns; } set { _columns = value; }}

        private Dcs.TriplePoint [,] _points;
        public Dcs.TriplePoint [,] points {
            get {
                _points = new Dcs.TriplePoint[rows, columns];
                foreach (var cell in this) {
                    _points[cell.row, cell.column] = cell.point;
                }

                return _points;
            }
            set {
                if ((value.length[0] == rows) &&(value.length[1] == columns)) {
                    foreach (var cell in this) {
                        cell.point = value[cell.row, cell.column];
                    }
                } else  {
                    error ("Invalid array dimensions");
                }
            }
        }

        private Cairo.Rectangle[,] _rectangles;
        public Cairo.Rectangle[,] rectangles {
            get {
                _rectangles = new Cairo.Rectangle[rows, columns];
                foreach (var cell in this) {
                    _rectangles[cell.row, cell.column] = cell.rect;
                }

                return _rectangles;
            }
            set {
                if ((value.length[0] == rows) &&(value.length[1] == columns)) {
                    foreach (var cell in this) {
                        cell.rect = value[cell.row, cell.column];
                    }
                } else  {
                    error ("Invalid array dimensions");
                }
            }
        }

        private Gdk.RGBA [,] _colors;
        public Gdk.RGBA[,] colors {
            get {
                _colors = new Gdk.RGBA[rows, columns];
                foreach (var cell in this) {
                    _colors[cell.row, cell.column] = cell.color;
                }

                return _colors;
            }
            set {
                if ((value.length[0] == rows) &&(value.length[1] == columns)) {
                    foreach (var cell in this) {
                        cell.color = value[cell.row, cell.column];
                    }
                } else  {
                    error ("Invalid array dimensions");
                }
            }
        }

        /* Fill with initial data */
        public void init () {
            for (int i = 0; i < rows; i++) {
                for (int j = 0; j < columns; j++) {
                    add ({ i, j,
                           Dcs.TriplePoint () { a = 0, b = 0, c = 0 },
                           Gdk.RGBA (),
                           Cairo.Rectangle (),
                           ""});
                }
            }
        }
    }

    construct {
        objects = new Gee.TreeMap<string, Dcs.Object> ();
        data = new Dcs.UI.HeatMap.Data ();
    }

    /**
     * Construction using an XML node.
     */
    public HeatMap.from_xml_node (Xml.Node *node) {
        build_from_xml_node (node);
    }

    /**
     * {@inheritDoc}
     */
    internal void build_from_xml_node (Xml.Node *node) {
        if (node->type == Xml.ElementType.ELEMENT_NODE &&
            node->type != Xml.ElementType.COMMENT_NODE) {
            id = node->get_prop ("id");
            this.config_node = node;

            /* Iterate through node children */
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {
                if (iter->name == "property") {
                    switch (iter->get_prop ("name")) {
                        case "xmin":
                            xmin = double.parse (iter->get_content ());
                            break;
                        case "xmax":
                            xmax = double.parse (iter->get_content ());
                            break;
                        case "ymin":
                            ymin = double.parse (iter->get_content ());
                            break;
                        case "ymax":
                            ymax = double.parse (iter->get_content ());
                            break;
                        case "zmin":
                            zmin = double.parse (iter->get_content ());
                            break;
                        case "zmax":
                            zmax = double.parse (iter->get_content ());
                            break;
                        case "min-color":
                            min_color_spec = iter->get_content ();
                            _min_color.parse (min_color_spec);
                            break;
                        case "max-color":
                            max_color_spec = iter->get_content ();
                            _max_color.parse (max_color_spec);
                            break;
                        case "interpolation-type":
                            interpolation_type = iter->get_content ();
                            break;
                        case "rows":
                            data.rows = int.parse (iter->get_content ());
                            break;
                        case "columns":
                            data.columns = int.parse (iter->get_content ());
                            break;
                        default:
                            break;
                    }
                } else if (iter->name == "object") {
                    var type = iter->get_prop ("type");
                    if (type == "channel-matrix") {
                        channel_matrix = new Dcs.UI.ChannelMatrix.from_xml_node (iter);
                        add_child (channel_matrix);
                    }
                }
            }
        }
        init ();
        connect_notify_signals ();
    }

    /**
     * {@inheritDoc}
     */
    protected void update_node () {
        if (config_node->type == Xml.ElementType.ELEMENT_NODE &&
            config_node->type != Xml.ElementType.COMMENT_NODE) {
            /* iterate through node children */
            for (Xml.Node *iter = config_node->children;
                 iter != null;
                 iter = iter->next) {
                if (iter->name == "property") {
                    switch (iter->get_prop ("name")) {
                        case "xmin":
                            iter->set_content (xmin.to_string ());
                            break;
                        case "xmax":
                            iter->set_content (xmax.to_string ());
                            break;
                        case "ymin":
                            iter->set_content (ymin.to_string ());
                            break;
                        case "ymax":
                            iter->set_content (ymax.to_string ());
                            break;
                        case "zmin":
                            iter->set_content (zmin.to_string ());
                            break;
                        case "zmax":
                            iter->set_content (zmax.to_string ());
                            break;
                        case "min-color":
                            iter->set_content (min_color_spec);
                            break;
                        case "max-color":
                            iter->set_content (max_color_spec);
                            break;
                        default:
                            break;
                    }
                }
            }
        }
    }

    private void init () {
        data.init ();
        data.cell_width = (this.xmax - this.xmin) / (double)data.columns;
        data.cell_height = (this.ymax - this.ymin) / (double)data.rows;
        message ("Heatmap Cell Coordinates");
        for (int i = 0; i < data.size; i++) {
            var cell = data.get (i);
            var a = xmin + (xmax - xmin) * cell.column / (double)data.columns;
            var b = ymin + (ymax - ymin) * cell.row / (double)data.rows;
            cell.point = { a, b, 0 };
            data.set (i, cell);
            message ("  r c a b %d %d %.3f %.3f", cell.row, cell.column, a, b);
        }

        quantize.begin ();
    }

    /* map a data channel source to a cell */
    private async void quantize () {
        while ((channel_matrix != null) &&
                (!(channel_matrix.data.size == channel_matrix.objects.size)) &&
                !(channel_matrix.get_satisfied ())) {
            yield nap (1000);
        }

        for (int i = 0; i < data.size; i++) {
            var cell = data.get (i);
            foreach (var key in channel_matrix.data.keys) {
                var point = channel_matrix.data.get (key);

                if ((point.a < (cell.point.a + data.cell_width / 2)) &&
                       (point.a >= (cell.point.a - data.cell_width / 2)) &&
                       (point.b < (cell.point.b + data.cell_height / 2)) &&
                       (point.b >= (cell.point.b - data.cell_height / 2))) {
                    cell.chref = key;
                    data.set (i, cell);
                }
            }
        }
    }

    private  async void nap (uint interval, int priority = GLib.Priority.DEFAULT) {
        GLib.Timeout.add (interval, () => {
            nap.callback ();
            return false;
        }, priority);
        yield;
    }

    /**
     * Connect all notify signals to update node
     */
    protected void connect_notify_signals () {
        Type type = get_type ();
        ObjectClass ocl = (ObjectClass)type.class_ref ();

        foreach (ParamSpec spec in ocl.list_properties ()) {
            notify[spec.get_name ()].connect ((s, p) => {
            debug ("type: %s spec: %s", type.name (), spec.get_name ());
                update_node ();
            });
        }
    }

    /**
     * {@inheritDoc}
     */
    private void update () {
        for (int i = 0; i < data.size; i++) {
            var cell = data.get (i);
            var point = cell.point;
            /* scale the value */
            var value = point.c;
            if (value > zmax)
                value = zmax;
            if (value < zmin)
                value = zmin;
            value = (value - zmin) / (zmax - zmin);

            cell.color =  lerp (value);
            data.set (i, cell);
        }
    }

    private Gdk.RGBA lerp (double value) requires (value >= 0)
                                         requires (value <=1.0) {
        double h_min;
        double s_min, v_min;
        double h_max, s_max, v_max;
        double h, s, v;
        double r, g, b, a;

        Gtk.rgb_to_hsv (min_color.red, min_color.green, min_color.blue,
                                               out h_min, out s_min, out v_min);
        Gtk.rgb_to_hsv (max_color.red, max_color.green, max_color.blue,
                                               out h_max, out s_max, out v_max);

        h = h_min + value * (h_max - h_min);
        s = s_min + value * (s_max - s_min);
        v = v_min + value * (v_max - v_min);
        a = min_color.alpha + value * (max_color.alpha - min_color.alpha);

        Gtk.HSV.to_rgb (h, s, v, out r, out g, out b);
        Gdk.RGBA color = Gdk.RGBA () { red = r, green = g, blue = b, alpha = a };

        return color;
    }

    /**
     * Update the raw data
     */
    public void refresh () {
        for (int i = 0; i < data.size; i++) {
            var cell = data.get (i);
            var point = cell.point;
            if (channel_matrix.data.has_key (cell.chref)) {
                point.c = channel_matrix.data.get (cell.chref).c;
            }
            /*point.z = 0.5;*/
            cell.point = point;
            data.set (i, cell);
        }
    }

    /* Set a color for cells that have no channel reference (ie. raw data) */
    private void interpolate () {
        /* XXX TBD */
    }

    /**
     * {@inheritDoc}
     */
    private void generate (int w, int h,
                           double x_min, double x_max,
                           double y_min, double y_max) {
        /*calculate the origin positions of the grid elements */
        for (int i = 0; i < data.size; i++) {
            var cell = data.get (i);
            var xslope = w / (x_max - x_min);
            var yslope = h / (y_max - y_min);

            var width = xslope * data.cell_width;
            var height = yslope * data.cell_height;

            var x = xslope * (cell.point.a - x_min);
            var y = h - height - yslope * (cell.point.b - y_min);
            cell.rect = { x, y, width, height };
            data.set (i, cell);
            /*
             *message ("w h x y w h %d %d %-8.3f %-8.3f %-8.3f %-8.3f",
             *                        w, h,
             *                        data.get (i).rect.x, data.get (i).rect.y,
             *                        data.get (i).rect.width, data.get (i).rect.height);
             */
        }

        update();
    }

    /**
     * {@inheritDoc}
     */
    public void draw (Cairo.Context cr) {
        var stencil = new Dcs.UI.HeatMapView (image_surface);
        stencil.draw (data.colors, data.rectangles);
        cr.set_operator (Cairo.Operator.OVER);
        cr.set_source_surface (stencil.get_target (), 0, 0);
        cr.paint ();
    }

    /**
     * {@inheritDoc}
     */
    public void update_objects (Gee.Map<string, Dcs.Object> val) {
        _objects = val;
    }
}
