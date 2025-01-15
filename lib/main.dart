import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Database? _database;
  Future<List<Map<String, dynamic>>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _initDatabase().then((_) {
      _refreshData();
    });
  }

  Future<void> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'devices.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE devices(id INTEGER PRIMARY KEY, serial TEXT, name TEXT, dateTime TEXT, co REAL, so REAL, pm25 REAL)',
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    final data = await _database?.query('devices') ?? [];
    print('Data yang diambil: $data');
    return data;
  }

  Future<void> _pickCSVFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(CsvToListConverter())
          .toList();

      print('Parsed CSV fields: $fields');

      if (_isValidCSV(fields)) {
        await _saveCSVData(fields, context);
      } else {
        _showSnackBar(context, 'Format CSV tidak valid.');
      }
    }
  }

  Future<void> _saveCSVData(
      List<List<dynamic>> fields, BuildContext context) async {
    for (var row in fields.skip(1)) {
      String serial = row[0];
      String name = row[1];
      String dateTime = row[2];

      final existingData = await _database?.query(
        'devices',
        where: 'serial = ? AND name = ? AND dateTime = ?',
        whereArgs: [serial, name, dateTime],
      );

      if (existingData != null && existingData.isNotEmpty) {
        _showSnackBar(context,
            'Data dengan Serial: $serial, Name: $name, Date: $dateTime sudah ada.');
      } else {
        await _database?.insert('devices', {
          'serial': serial,
          'name': name,
          'dateTime': dateTime,
          'co': row[3],
          'so': row[4],
          'pm25': row[5],
        });
        print('Data berhasil disimpan: $serial, $name, $dateTime');
      }
    }
    _showSnackBar(context, 'File CSV berhasil diunggah dan diparsing.');

    _refreshData();
  }

  bool _isValidCSV(List<List<dynamic>> fields) {
    if (fields.isEmpty || fields[0].length != 6) {
      return false;
    }
    return true;
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 3),
      backgroundColor: Colors.blueAccent,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _refreshData() {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Image.asset(
                    'assets/artium.jpeg',
                    height: 100,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Device List:',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                Map<String, List<Map<String, dynamic>>> groupedData = {};
                for (var item in data) {
                  if (!groupedData.containsKey(item['name'])) {
                    groupedData[item['name']] = [];
                  }
                  groupedData[item['name']]!.add(item);
                }

                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: groupedData.keys.length,
                      itemBuilder: (context, index) {
                        final deviceName = groupedData.keys.elementAt(index);
                        final items = groupedData[deviceName]!;

                        return Card(
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(
                              'Device: $deviceName',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text('Jumlah Detail: ${items.length}'),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                await _showDeviceDetails(context, items);
                              },
                              child: Text('Details'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (groupedData.isNotEmpty) ...[
                              Text(
                                'Total Devices: ${groupedData.keys.length}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                height: 150,
                                child: PieChart(
                                  PieChartData(
                                    sections:
                                        groupedData.keys.map((deviceName) {
                                      final count =
                                          groupedData[deviceName]!.length;
                                      return PieChartSectionData(
                                        value: count.toDouble(),
                                        color: Colors.primaries[groupedData.keys
                                                .toList()
                                                .indexOf(deviceName) %
                                            Colors.primaries.length],
                                        title: '$deviceName ($count)',
                                        radius: 45,
                                        titleStyle: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }).toList(),
                                    centerSpaceRadius: 40,
                                    startDegreeOffset: 180,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Silakan upload file CSV untuk memuat data device',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickCSVFile(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 20),
            SizedBox(height: 4),
            Text('Upload CSV',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
          ],
        ),
        backgroundColor: Colors.blue,
        elevation: 6,
      ),
    );
  }

  Future<void> _showDeviceDetails(
      BuildContext context, List<Map<String, dynamic>> items) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detail Perangkat', style: TextStyle(fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((device) {
                return Card(
                  margin: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 12.0),
                        child: Text('Serial: ${device['serial']}',
                            style: TextStyle(fontSize: 16)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 12.0),
                        child: Text('Jam: ${device['dateTime']}',
                            style: TextStyle(fontSize: 16)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 12.0),
                        child: Text('CO: ${device['co']}',
                            style: TextStyle(fontSize: 16)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 12.0),
                        child: Text('SO: ${device['so']}',
                            style: TextStyle(fontSize: 16)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 12.0),
                        child: Text('PM2.5: ${device['pm25']}',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tutup', style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () async {
                await _deleteDevice(context, items[0]['serial']);
                Navigator.of(context).pop();
              },
              child: Text('Hapus', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDevice(BuildContext context, String serial) async {
    await _database
        ?.delete('devices', where: 'serial = ?', whereArgs: [serial]);
    _showSnackBar(context, 'Data dengan serial $serial berhasil dihapus.');
    _refreshData();
  }
}
