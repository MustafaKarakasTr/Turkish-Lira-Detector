/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'home.dart';

List<CameraDescription> cameras;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tflite real-time detection',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: HomePage(cameras),
    );
  }
}*/
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

//String model_file = "assets/model.tflite";
String model_file = "assets/tflite_model.tflite";
String label_file = "assets/money_labels.txt";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

List<CameraDescription> cameras;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String result = "";
  double confidence = 0.0;
  CameraController cameraController;
  CameraImage cameraImage;
  List recognitionsList;

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      setState(() {
        print("camera image guncellendi");
        cameraController.startImageStream((image) {
          cameraImage = image;
          runModel();
        });
      });
    });
  }

  runModel() async {
    /*recognitionsList = await Tflite.detectObjectOnFrame(
      bytesList: cameraImage.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResultsPerClass: 1,
      threshold: 0.4,
    );*/
    //sleep(Duration(milliseconds: 10));
    cameraController.startImageStream((image) {
      cameraImage = image;
    });
    var recognitions = await Tflite.runModelOnFrame(
      bytesList: cameraImage.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      numResults: 2,
    ) /*.then((recognitions) {
      int endTime = new DateTime.now().millisecondsSinceEpoch;
      //print("Detection took ${endTime - startTime}");

      //widget.setRecognitions(recognitions, img.height, img.width);

      //isDetecting = false;
    })*/
        ;
    print("recognitions: $recognitions");

    result = recognitions[0].toString();
    //confidence = recognitions[0].confidence;

    setState(() {
      //cameraImage = image;
    });
  }

  Future loadModel() async {
    Tflite.close();
    var result = await Tflite.loadModel(model: model_file, labels: label_file);
    print("Result is $result");
  }

  @override
  void dispose() {
    super.dispose();

    cameraController.stopImageStream();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();

    loadModel();
    initCamera();
  }

  /*List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (recognitionsList == null) return [];

    double factorX = screen.width;
    double factorY = screen.height;

    Color colorPick = Colors.pink;

    return recognitionsList.map((result) {
      return Positioned(
        left: result["rect"]["x"] * factorX,
        top: result["rect"]["y"] * factorY,
        width: result["rect"]["w"] * factorX,
        height: result["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['detectedClass']} ${(result['confidenceInClass'] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.black,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }*/

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> list = [];

    list.add(
      Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        height: size.height - 100,
        child: Container(
          height: size.height,
          child: (!cameraController.value.isInitialized)
              ? new Container()
              : Column(children: [
                  AspectRatio(
                    aspectRatio: cameraController.value.aspectRatio,
                    child: CameraPreview(cameraController),
                  ),
                  Text(result)
                ]),
        ),
      ),
    );

    if (cameraImage != null) {
      //list.addAll(displayBoxesAroundRecognizedObjects(size));
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          margin: EdgeInsets.only(top: 50),
          color: Colors.black,
          child: Stack(
            children: list,
          ),
        ),
      ),
    );
  }
}
