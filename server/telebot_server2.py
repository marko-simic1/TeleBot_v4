#!/usr/bin/python3
import dbus
import rospy
from geometry_msgs.msg import Twist

from advertisement import Advertisement
from server import telebotMain, Service, Characteristic, Descriptor

GATT_CHRC_IFACE = "org.bluez.GattCharacteristic1"
NOTIFY_TIMEOUT = 1000

class telebotAdvertisement(Advertisement):
    def __init__(self, index):
        Advertisement.__init__(self, index, "peripheral")
        self.add_local_name("FER WP1")
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
        self.joystick_publisher = rospy.Publisher('/turtle1/cmd_vel', Twist, queue_size=10)
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
        rospy.loginfo(f"Received data: {received_data}")
        self.publish_telejoy(received_data)

    def publish_telejoy(self, data):
        # Assuming data is in a format suitable for Twist messages (e.g., x,y,z linear and angular velocities)
        parts = data.split(',')
        if len(parts) == 2:
            twist_msg = Twist()
            twist_msg.linear.x = float(parts[0])
            twist_msg.angular.z = float(parts[1])
            self.joystick_publisher.publish(twist_msg)

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
    rospy.init_node('teleop_turtlesim')
    
    telebotMonitor = telebotMain()
    telebotMonitor.add_service(telebotService(0))
    telebotMonitor.register()

    telebotAdvertisement = telebotAdvertisement(0)
    telebotAdvertisement.register()

    try:
        telebotMonitor.run()
    except rospy.ROSInterruptException:
        pass
    finally:
        telebotMonitor.quit()

