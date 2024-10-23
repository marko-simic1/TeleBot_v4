# TeleBot App v4 🚀

[![License](https://img.shields.io/badge/license-University%20of%20Zagreb-blue.svg)](#)

**TeleBot** is a cross-platform mobile application that allows users to connect to their robots via Bluetooth Low Energy (BLE) and control them using dual joysticks.

---

## 📲 Installation

### On Your Mobile Device 📱

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/TeleBot.git
   ```
2. **Install Flutter**: Download and install the [Flutter SDK](https://flutter.dev/docs/get-started/install).
3. **Connect Your Phone**: Plug your mobile device into your PC via USB cable.
4. **Navigate to the App Directory**:
   ```bash
   cd TeleBot/app
   ```
5. **Run the App**:
   ```bash
   flutter run
   ```
   The app will build and launch on your connected mobile device.

### On Your Robot's PC 🤖

1. **Ensure Ubuntu is Installed**: Your robot's PC must be running Ubuntu.
2. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/TeleBot.git
   ```
3. **Navigate to the Server Directory**:
   ```bash
   cd TeleBot/server
   ```
4. **Install Required Packages**:
   ```bash
   sudo apt-get update
   sudo apt-get install bluetooth bluez python3-pip
   pip3 install -r requirements.txt
   ```
5. **Run the Server**:
   ```bash
   sudo python3 telebot_server.py
   ```
   *Note: Running with `sudo` may be necessary to access BLE functionalities.*

6. **Connect via the App**: On your TeleBot app, scan for devices and connect to `TELEBOT_SERVER`.

---

## ⚙️ Configuration

Customize `telebot_server.py` to suit your specific robot:

- **Data Scaling**: Adjust how the received joystick data is scaled.
- **Data Transmission**: Define how data is sent to your robot's control systems.

**Example**: In `telebot_server_turtlesim.py`:

- Processes joystick input.
- Scales data for [Turtlesim](http://wiki.ros.org/turtlesim).
- Publishes commands to control the Turtlesim simulation.

```python
# telebot_server_turtlesim.py snippet

def handle_joystick_data(data):
    scaled_data = scale_data_for_turtlesim(data)
    publish_to_turtlesim(scaled_data)
```

---

## ✨ Features

- **Dual Joystick Control**: Intuitive control over robot movements.
- **BLE Connectivity**: Seamless Bluetooth Low Energy connection.
- **Customizable Server Scripts**: Adaptable to different robot types and simulations.

---

## 📚 Resources

- **Flutter Documentation**: [flutter.dev/docs](https://flutter.dev/docs)
- **BLE Overview**: [bluetooth.com](https://www.bluetooth.com/bluetooth-technology/radio-versions/)
- **Turtlesim Tutorial**: [ROS Wiki](http://wiki.ros.org/turtlesim)

---

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

---

## 📬 Contact Information

For any questions or support, feel free to reach out:

- **Email**: [marko.simic2@fer.hr](mailto:marko.simic2@fer.hr)

---

## 📄 License

This project is licensed under the **University of Zagreb Faculty of Electrical Engineering and Computing**, Laboratory for Robotics and Intelligent Control Systems.

---

*Happy Robotics! 🤖*
