import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:developer' as devtools;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _indexImage = 0;
  List<String> _images = [
    "assets/rock.png",
    "assets/paper.png",
    "assets/scissors.png"
  ];
  late Timer _timer;

  File? filePath;
  String label = '';
  double confidence = 0.0;

  String? com_decision;
  String match_results = "";
  String image_to_show = "";

  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _tfLteInit();

    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _changeImage();
    });

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _cameraController!.initialize();
  }

  Future<void> _tfLteInit() async {
    await Tflite.loadModel(
      model: "assets/model_rps_2.tflite",
      labels: "assets/labels_rps_2.txt",
    );
  }

  void computer_decision() {
    var intValue = Random().nextInt(3) + 1;
    print(intValue);

    if (intValue == 1) {
      com_decision = "paper";
      image_to_show = "assets/paper.png";
    } else if (intValue == 2) {
      com_decision = "rock";
      image_to_show = "assets/rock.png";
    } else if (intValue == 3) {
      com_decision = "scissors";
      image_to_show = "assets/scissors.png";
    }
    print(com_decision);
  }

  Future<void> pickImageGallery() async {
    com_decision = null;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    var imageMap = File(image.path);

    setState(() {
      filePath = imageMap;
    });

    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 3,
      threshold: 0.5,
      asynch: true,
    );

    if (recognitions == null) {
      devtools.log("recognitions is Null");
      return;
    }
    devtools.log(recognitions.toString());
    setState(() {
      confidence = (recognitions[0]['confidence'] * 100);
      label = recognitions[0]['label'].toString();
    });
    print(recognitions);
    print(label);
    computer_decision();

    _determineMatchResult();
  }

  Future<void> pickImageCamera() async {
    final XFile? image = await _cameraController!.takePicture();

    if (image == null) return;

    var imageMap = File(image.path);

    setState(() {
      filePath = imageMap;
    });

    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.5,
      asynch: true,
    );

    if (recognitions == null) {
      devtools.log("recognitions is Null");
      return;
    }
    devtools.log(recognitions.toString());
    setState(() {
      confidence = (recognitions[0]['confidence'] * 100);
      label = recognitions[0]['label'].toString();
    });

    computer_decision();
    _determineMatchResult();
  }

  void _determineMatchResult() {
    if (label == "paper" && com_decision == "paper") {
      match_results = "Draw";
    } else if (label == "paper" && com_decision == "rock") {
      match_results = "You Win";
    } else if (label == "paper" && com_decision == "scissors") {
      match_results = "Com Win";
    } else if (label == "rock" && com_decision == "paper") {
      match_results = "Com Win";
    } else if (label == "rock" && com_decision == "rock") {
      match_results = "Draw";
    } else if (label == "rock" && com_decision == "scissors") {
      match_results = "You Win";
    } else if (label == "scissors" && com_decision == "paper") {
      match_results = "You Win";
    } else if (label == "scissors" && com_decision == "rock") {
      match_results = "Com Win";
    } else if (label == "scissors" && com_decision == "scissors") {
      match_results = "Draw";
    }
    print(match_results);
  }

  @override
  void dispose() {
    _timer.cancel();
    _cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  void _changeImage() {
    setState(() {
      _indexImage = (_indexImage + 1) % _images.length;
    });
  }

  void _reset() {
    setState(() {
      com_decision = null;
      match_results = "";
      label = "";
      filePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rock-Paper-Scissors"),
      ),
      body: Column(
        children: [
          Container(
            color: Color.fromARGB(255, 255, 234, 0),
            child: Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height *
                    0.35, // Mengatur height menjadi 60% dari height layar
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 0,
                      clipBehavior: Clip.hardEdge,
                      child: Container(
                        height: 200,
                        width: 200,
                        child: com_decision == null
                            ? Image.asset(_images[_indexImage])
                            : Image.asset(image_to_show),
                      ),
                    ),
                    // const SizedBox(height: 12),

                    // const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Card(
                          elevation: 20,
                          child: Container(
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            child: filePath == null
                                ? CameraPreview(_cameraController!)
                                : Image.file(
                                    filePath!,
                                    fit: BoxFit.fill,
                                  ),
                          ),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    height: 80,
                    width: 80,
                    child: Image.asset('assets/Text.png'),
                  ),
                ]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 120.0),
                          child: Text(
                            "$match_results",
                            style: GoogleFonts.silkscreen(
                              fontSize: 60,
                              textStyle: TextStyle(color: Colors.white),
                              // Gunakan font Google
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 0),
                          child: Visibility(
                            visible: match_results != "",
                            child: ElevatedButton(
                              onPressed: _reset,
                              child: Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 86, 62,
                                    224), // Ganti dengan warna yang diinginkan
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 150.0),
                          child: Text(
                            "$label",
                            style: GoogleFonts.silkscreen(
                              fontSize: 40,
                              textStyle: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 0),
                            child: ElevatedButton(
                              onPressed: pickImageCamera,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 86, 62,
                                    224),
                                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20) // Ganti dengan warna yang diinginkan
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 0),
                            child: ElevatedButton(
                              onPressed: pickImageGallery,
                              child: Icon(
                                Icons.photo,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 86, 62,
                                    224),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20) // Ganti dengan warna yang diinginkan
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
