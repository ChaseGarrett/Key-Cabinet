# Key-Cabinet
User authentication and key storage for Catawba College's IT department.

This is the code for the final project of my Hardware and Systems Software class, an introduction level Linux class.
This code is responsible for authenticating users and communicating the process of scanning keys in and out to a secondary raspberry pi
on the same network. 

The secondary raspberry pi requires a handful of files to run, the databases and logs; however, the majority of the code is run natively
on one raspberry pi and occasionally running code remotely on another raspberry pi used solely for authentication.

This program makes use of a maglock, a magnetic switch, a dual-channel RFID scanner, a red LED, and a green LED. 
