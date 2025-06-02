import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';
import 'package:flutter_virtual_piano/flutter_virtual_piano.dart';
import 'package:midi_test/notes.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ControllerPage extends StatelessWidget {
  const ControllerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Music Note Test')),
      body: MidiControls(),
    );
  }
}

class MidiControls extends StatefulWidget {
  const MidiControls({super.key});

  @override
  MidiControlsState createState() {
    return MidiControlsState();
  }
}

class MidiControlsState extends State<MidiControls> {
  var _channel = 0;
  Set<int> pressedKeysNum = {};
  Set<String> pressedKeysNotes = {};

  String nextNote = 'C';
  Color? nextNoteColor;

  StreamSubscription<MidiPacket>? _rxSubscription;
  final MidiCommand _midiCommand = MidiCommand();

  @override
  void initState() {
    // prevent screen from timing out
    WakelockPlus.enable();

    if (kDebugMode) {
      print('init controller');
    }
    _rxSubscription = _midiCommand.onMidiDataReceived?.listen((packet) {
      var data = packet.data;
      var device = packet.device;
      if (kDebugMode) {
        debugPrint("data $data from device ${device.name}:${device.id}");
      }
      var status = data[0];
      if (status == 0xF8) {
        // Beat
        return;
      }
      if (status == 0xFE) {
        // Active sense;
        return;
      }
      if (data.length >= 2) {
        var rawStatus = status & 0xF0; // without channel
        var channel = (status & 0x0F);
        // if (channel == _channel) {
        if (true) {
          var d1 = data[1];
          switch (rawStatus) {
            case 0x80: // Note Off
              _noteOff(d1);
              break;
            case 0x90: // Note On
              _noteOn(d1, data[2]);
              break;
          }
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    // re enable screen timing out
    WakelockPlus.disable();
    _rxSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        // const Divider(),
        // Text("Channel", style: Theme.of(context).textTheme.titleLarge),
        // SteppedSelector('Channel', _channel + 1, 1, 16, _onChannelChanged),
        const Divider(),
        SizedBox(
          height: 160,
          child: VirtualPiano(
            noteRange: const RangeValues(48, 72),
            highlightedNoteSets: [
              HighlightedNoteSet(pressedKeysNum, Colors.green),
            ],
            onNotePressed: (note, vel) {
              _noteOn(note, 100);
            },
            onNoteReleased: (note) {
              _noteOff(note);
            },
            showKeyLabels: true,
          ),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(color: nextNoteColor),
              child: Text(
                'Press Note: $nextNote',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Pressed: $pressedKeysNotes')],
        ),
      ],
    );
  }

  _noteOn(int note, int velocity) {
    debugPrint('Note: ${Notes.getNoteLetter(note)}${Notes.getOctave(note)}');
    if (nextNote == Notes.getNoteLetter(note)) {
      nextNote = Notes.getRandomNaturalNote();
      nextNoteColor = Colors.green;
    } else {
      nextNoteColor = Colors.red;
    }
    setState(() {
      pressedKeysNum.add(note);
      pressedKeysNotes.add(Notes.getNoteLetter(note));
    });
    NoteOnMessage(channel: _channel, note: note, velocity: velocity).send();
  }

  _noteOff(int note) {
    setState(() {
      pressedKeysNum.remove(note);
      pressedKeysNotes.remove(Notes.getNoteLetter(note));
      nextNoteColor = null;
    });
    NoteOffMessage(channel: _channel, note: note).send();
  }

  _onChannelChanged(int newValue) {
    setState(() {
      _channel = newValue - 1;
    });
  }
}

class SteppedSelector extends StatelessWidget {
  final String label;
  final int minValue;
  final int maxValue;
  final int value;
  final Function(int) callback;

  const SteppedSelector(
    this.label,
    this.value,
    this.minValue,
    this.maxValue,
    this.callback, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(label),
        IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: (value > minValue)
              ? () {
                  callback(value - 1);
                }
              : null,
        ),
        Text(value.toString()),
        IconButton(
          icon: const Icon(Icons.add_circle),
          onPressed: (value < maxValue)
              ? () {
                  callback(value + 1);
                }
              : null,
        ),
      ],
    );
  }
}
