import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './discovery_page.dart';


class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "";
  String _name = "";
  String _addressArduino ="";
  String _dispositivoSelecionado = "Selecione um disposito para parear";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

//  BackgroundCollectingTask? _collectingTask;
  late BluetoothConnection _connection;

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    //_collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  void _acionar(address) async {
   //BluetoothConnection connection = await BluetoothConnection.toAddress(address);
    //print('Connected to the device ');

    _connection.output.add(ascii.encode("0,255,255*"));
    await _connection.output.allSent;

  }

  _connectarArduino (address) async {
    BluetoothConnection connection = await BluetoothConnection.toAddress(address);
    setState(() {
      _connection = connection;
      print("arduino conectado");
    });
  }

  _desconectarArduino() async {
    if (_connection.isConnected){
      _connection.finish();

      setState(() {
        _addressArduino ="";
        _dispositivoSelecionado = "Selecione um disposito para parear";
      });
    }
  }

  _mudarCor(address, cor) async{
   // BluetoothConnection connection = await BluetoothConnection.toAddress(address);

    _connection.output.add(ascii.encode(cor+"*"));
    await _connection.output.allSent;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Bluetooth Serial'),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            Divider(),
            SwitchListTile(
              title: Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            Divider(),
            ListTile(title: Text(_dispositivoSelecionado)),
            ListTile(
              title: ElevatedButton(
                  child: Text('Explore discovered devices'),
                  onPressed: () async {
                    final BluetoothDevice? selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return DiscoveryPage();
                        },
                      ),
                    );

                    if (selectedDevice != null) {
                      print('Discovery -> selected ' + selectedDevice.address +" "+ selectedDevice.name!);
                      _dispositivoSelecionado = selectedDevice.name!;

                      setState(() {
                        _addressArduino = selectedDevice.address;
                        _connectarArduino(selectedDevice.address);
                      });
                    } else {
                      print('Discovery -> no device selected');
                      print("adress atual: " +_addressArduino);
                    }
                  }),
            ),
            Divider(),
            _addressArduino  != ""
                ? Column(
              children: [
                ElevatedButton(
                  child:  Text('Ligar a cor'),
                  onPressed: (){
                    _acionar(_addressArduino);
                  },
                ),
                Divider(),
                ElevatedButton(
                  child:  Text('Mudar a cor'),
                  onPressed: (){
                    _mudarCor(_addressArduino, "255,0,0");
                  },
                ),
                Divider(),
                ElevatedButton(
                  child:  Text('Desconectar'),
                  onPressed: (){
                    _desconectarArduino();
                  },
                ),
              ],
            )
                : Container()
          ],
        ),
      ),
    );
  }

}
