import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as dart_ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

// final GlobalKey<_HomePageState> qrKey2 = GlobalKey();

class _HomePageState extends State<HomePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  // final GlobalKey<_HomePageState> _renderObjectKey = GlobalKey();

  QRViewController? controller;
  Barcode? result;

  Uint8List? bytes;

  // @override
  // void reassemble() {
  //   super.reassemble();
  //   if (Platform.isAndroid) {
  //     controller!.pauseCamera();
  //   } else if (Platform.isIOS) {
  //     controller!.resumeCamera();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 30,
              ),
              Container(
                width: 200,
                height: 200,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              (result != null)
                  ? Text("${result!.code}")
                  : const Text("Scan a QR code"),
              const SizedBox(
                height: 30,
              ),
              const Text("New QR code Based on present data"),
              qrImageWidget(),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: _createPdf,
                child: const Text("Create Pdf"),
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size(180,40)),
                  backgroundColor: MaterialStateProperty.all(
                    const Color.fromARGB(255, 60, 177, 144),
                  ),
                  elevation: MaterialStateProperty.all(1),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _createPdf() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          alignment: Alignment.center,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Stack(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          ),
        );
      },
    );
    print("i started here1");
    final screenshotController = ScreenshotController();
    final appStorage = await getApplicationDocumentsDirectory();
    final bytes = await screenshotController.captureFromWidget(
      Material(
        child: qrImageWidget(),
      ),
    );
    print("i started here2");
    setState(() {
      this.bytes = bytes;
    });
    await saveImage(bytes, appStorage);
    print("i started here3");

    final PdfDocument document = PdfDocument();
    //Read image data.
    print("i started here4");
    // final Uint8List imageData =
    //     File('${appStorage.path}/image.png').readAsBytesSync();
    //Load the image using PdfBitmap.
    print("i started here5");
    final PdfBitmap image = PdfBitmap(bytes);
    print("i started here6");
    document.pages
        .add()
        .graphics
        .drawImage(image, const Rect.fromLTWH(0, 0, 500, 500));

    List<int> bytesPdf = document.save();
    document.dispose();
    print("i started here7");

    Future.delayed(const Duration(milliseconds: 1000), () {
      Navigator.of(context).pop(true);
      saveAndLaunchFile(bytesPdf, 'output.pdf');
    });
  }

  Future<void> saveAndLaunchFile(List<int> bytes, String filename) async {
    final path = (await getExternalStorageDirectory())!.path;
    final file = File('$path/$filename');
    await file.writeAsBytes(bytes, flush: true);
    OpenFile.open('$path/$filename');
  }

  Future saveImage(Uint8List bytes, Directory appStorage) async {
    final file = File('${appStorage.path}/image.png');
    file.writeAsBytes(bytes);
  }

  Widget qrImageWidget() {
    return QrImage(
      data: (result != null) ? result!.code! : '',
      size: 200,
    );
  }
}
