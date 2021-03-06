public class Dcs.DAQ.Arduino.Device : Peas.ExtensionBase, Peas.Activatable {

    private Dcs.DAQ.Device device;

    public GLib.Object object { construct; owned get; }

    public Device (Dcs.Net.ZmqService zmq_service) {
        debug ("Arduino device constructor");
    }

    public void activate () {
        debug ("Arduino device activated");
        device = (Dcs.DAQ.Device) object;
        debug (device.zmq_service.to_string ());
        device.zmq_service.data_published.connect ((data) => {
            debug ((string) data);
        });
    }

    public void deactivate () { }

    public void update_state () { }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                       typeof (Dcs.DAQ.Arduino.Device));
}
