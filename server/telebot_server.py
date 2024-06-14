#!/usr/bin/python3
import dbus

from advertisement import Advertisement
from server import telebotMain, Service, Characteristic, Descriptor

GATT_CHRC_IFACE = "org.bluez.GattCharacteristic1"
NOTIFY_TIMEOUT = 1000

class telebotAdvertisement(Advertisement):
    def __init__(self, index):
        Advertisement.__init__(self, index, "peripheral")
        self.add_local_name("TELEBOT_SERVER")
        self.include_tx_power = False
        self.add_service_uuid("5701")

class telebotService(Service):
    UUID = "8b0be1f6-ddd3-11ec-9d64-0242ac120002"

    def __init__(self, index):
        Service.__init__(self, index, self.UUID, True)
        self.add_characteristic(DataCharacteristic(self))

class DataCharacteristic(Characteristic):
    UUID = "ebcb181a-e01f-11ec-9d64-0242ac120002"

    def __init__(self, service):
        self.notifying = False
        Characteristic.__init__(self, self.UUID, ["notify", "write", "read"], service)
        self.add_descriptor(DataDescriptor(self))

    def get_data(self):
        value = []
        data = self.getDataString()
        for c in data:
            value.append(dbus.Byte(c.encode()))
        return value

    def set_data_callback(self):
        if self.notifying:
            value = self.get_data()
            self.PropertiesChanged(GATT_CHRC_IFACE, {"Value": value}, [])
        return self.notifying

    def StartNotify(self):
        if self.notifying:
            return

        self.notifying = True
        value = self.get_data()
        self.PropertiesChanged(GATT_CHRC_IFACE, {"Value": value}, [])
        self.add_timeout(NOTIFY_TIMEOUT, self.set_data_callback)

    def StopNotify(self):
        self.notifying = False

    def ReadValue(self, options):
        value = self.get_data()
        return value

    def WriteValue(self, value, options):
        # Decode the received value
        received_data = ''.join([chr(byte) for byte in value])
        print(f"Received data: {received_data}")

    def getDataString(self):
        # Modify this function to return the joystick data
        return "Joystick data"

class DataDescriptor(Descriptor):
    DATA_DESCRIPTOR_UUID = "2901"
    DATA_DESCRIPTOR_VALUE = "Joystick movement data"

    def __init__(self, characteristic):
        Descriptor.__init__(self, self.DATA_DESCRIPTOR_UUID, ["read"], characteristic)

    def ReadValue(self, options):
        value = []
        desc = self.DATA_DESCRIPTOR_VALUE
        for c in desc:
            value.append(dbus.Byte(c.encode()))
        return value

if __name__ == '__main__':
    telebotMonitor = telebotMain()
    telebotMonitor.add_service(telebotService(0))
    telebotMonitor.register()

    telebotAdvertisment = telebotAdvertisement(0)
    telebotAdvertisment.register()

    try:
        telebotMonitor.run()
    except:
        telebotMonitor.quit()
