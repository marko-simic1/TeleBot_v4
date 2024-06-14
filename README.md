# TeleBot app_v4

TeleBot is an crossplatform mobile app that let users to connect to their robot via bluetooth low energy(BLE) and controls them with two joysticks.

##Installation

To install this app on your phone you need to follow next steps:
1. Download App repository to your PC
2. Install Flutter open source framework
3. Connect your phone to PC via cable
4. Open command prompt and place yourself in App folder
5. Run 'flutter run' and App will run on your mobile phone

To use this App on your robot you need to follow next steps:
1. Robot PC must be ran by Ubuntu
2. Download App repository to your robot PC
3. Open terminal and place yourself inside of server folder
4. Install all needed packages for server to run
5. run 'python3 telebot_server.py' to register GATT profile that will phone connect to

Next you will need to connect to 'TELEBOT_SERVER' when you discover it on your TeleBot App and that's it

##Configuration

For a specific type of robot, you will need to configure telebot_server.py to handle the scaling of the received data and define how it will be sent. The script telebot_server_turtlesim.py processes data received from the joystick, scales it for Turtlesim, and publishes it to the Turtlesim node to control the Turtlesim simulation.

##Contact Information

For any questions you can contact me at marko.simic2@fer.hr

License This project is licensed under the University of Zagreb Faculty of Electrical Engineering and Computing, Laboratory for Robotics and Intelligent Control Systems
