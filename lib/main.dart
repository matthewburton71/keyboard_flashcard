import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

import 'controller.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  StreamSubscription<String>? _setupSubscription;
  final MidiCommand _midiCommand = MidiCommand();

  bool _virtualDeviceActivated = false;

  @override
  void initState() {
    super.initState();

    _setupSubscription = _midiCommand.onMidiSetupChanged?.listen((data) async {
      if (kDebugMode) {
        print("setup changed $data");
      }
      setState(() {});
    });
    ();
  }

  @override
  void dispose() {
    _setupSubscription?.cancel();
    super.dispose();
  }

  IconData _deviceIconForType(String type) {
    switch (type) {
      case "native":
        return Icons.piano;
      case "own-virtual":
        return Icons.devices;
      case "network":
        return Icons.language;
      case "BLE":
        return Icons.bluetooth;
      default:
        return Icons.device_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Music Note Test'),
          actions: <Widget>[
            Switch(
              value: _virtualDeviceActivated,
              onChanged: (newValue) {
                setState(() {
                  _virtualDeviceActivated = newValue;
                });
                if (newValue) {
                  _midiCommand.addVirtualDevice(name: "Flutter MIDI Command");
                } else {
                  _midiCommand.removeVirtualDevice(
                    name: "Flutter MIDI Command",
                  );
                }
              },
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(24.0),
          child: const Text(
            "Tap to connect device.",
            textAlign: TextAlign.center,
          ),
        ),
        body: Center(
          child: FutureBuilder(
            future: _midiCommand.devices,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                var devices = snapshot.data as List<MidiDevice>;
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          MidiDevice device = devices[index];
                          debugPrint("device: ${device.name}, ${device.type}");

                          return ListTile(
                            title: Text(
                              device.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            subtitle: Text(
                              "ins:${device.inputPorts.length} outs:${device.outputPorts.length}, ${device.id}, ${device.type}",
                            ),
                            leading: Icon(
                              device.connected
                                  ? Icons.radio_button_on
                                  : Icons.radio_button_off,
                            ),
                            trailing: Icon(_deviceIconForType(device.type)),
                            onLongPress: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ControllerPage(),
                                    ),
                                  )
                                  .then((value) {
                                    setState(() {});
                                  });
                            },
                            onTap: () {
                              if (device.connected) {
                                if (kDebugMode) {
                                  print("disconnect");
                                }
                                _midiCommand.disconnectDevice(device);
                              } else {
                                if (kDebugMode) {
                                  print("connect");
                                }
                                _midiCommand
                                    .connectToDevice(device)
                                    .then((_) {
                                      if (kDebugMode) {
                                        print("device connected async");
                                      }
                                    })
                                    .catchError((err) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Error: ${(err as PlatformException?)?.message}",
                                          ),
                                        ),
                                      );
                                    });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute<void>(
                                builder: (_) => ControllerPage(),
                              ),
                            )
                            .then((value) {
                              setState(() {});
                            });
                      },
                      child: Text('Connect'),
                    ),
                  ],
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
    );
  }
}
