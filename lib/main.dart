import 'package:exposure_documentation/exposure_mode.dart';
import 'package:exposure_documentation/exposure_questions.dart';
import 'package:exposure_documentation/input_block.dart';
import 'package:flutter/material.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
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
  List<InputBlock> preparation = preparationQuestions
      .map((question) => InputBlock(question: question, answer: ''))
      .toList();
  int currentPreparationIndex = 0;

  List<InputBlock> postProcessing = postProcessingQuestions
      .map((question) => InputBlock(question: question, answer: ''))
      .toList();
  int currentPostProcessingIndex = 0;

  List<ExposureMode> modeOrder = [
    ExposureMode.preparation,
    ExposureMode.intensityDiagramm,
    ExposureMode.postProcessing,
    ExposureMode.save,
  ];
  int currentModeIndex = 0;

  final TextEditingController _controller = TextEditingController();

  void next() {
    _controller.clear();
    switch (modeOrder[currentModeIndex]) {
      case ExposureMode.preparation:
        if (currentPreparationIndex + 1 < preparation.length) {
          increasePreparationIndex();
        } else {
          increaseCurrentModeIndex();
        }
      case ExposureMode.intensityDiagramm:
        increaseCurrentModeIndex();
      case ExposureMode.postProcessing:
        if (currentPostProcessingIndex + 1 < postProcessing.length) {
          increasePostProcessionIndex();
        } else {
          increaseCurrentModeIndex();
        }
      case ExposureMode.save:
    }
  }

  void increasePreparationIndex() {
    setState(() {
      currentPreparationIndex++;
    });
  }

  void setCurrentPreparationAnswer({required final String answer}) {
    setState(() {
      preparation[currentPreparationIndex].answer = answer;
    });
  }

  void increasePostProcessionIndex() {
    setState(() {
      currentPostProcessingIndex++;
    });
  }

  void setCurrentPostProcessionAnswer({required final String answer}) {
    setState(() {
      postProcessing[currentPostProcessingIndex].answer = answer;
    });
  }

  void increaseCurrentModeIndex() {
    setState(() {
      currentModeIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('preparation'),
      ),
      body: Center(
          child: Column(
        children: switch (modeOrder[currentModeIndex]) {
          ExposureMode.preparation => buildInputBlock(
              onChanged: (answer) =>
                  setCurrentPreparationAnswer(answer: answer),
              question: preparationQuestions[currentPreparationIndex],
            ),
          ExposureMode.intensityDiagramm => [buildNextButton()],
          ExposureMode.postProcessing => buildInputBlock(
              onChanged: (answer) =>
                  setCurrentPreparationAnswer(answer: answer),
              question: postProcessingQuestions[currentPostProcessingIndex],
            ),
          ExposureMode.save => [const Text('finished!')],
        },
      )),
    );
  }

  List<Widget> buildInputBlock({
    required final String question,
    required final void Function(String)? onChanged,
  }) =>
      [
        Text(question),
        const SizedBox(height: 12),
        TextField(
          onChanged: onChanged,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          controller: _controller,
        ),
        const SizedBox(height: 12),
        buildNextButton(),
      ];

  Widget buildNextButton() => ElevatedButton(
        onPressed: () {
          next();
        },
        child: const Text('Weiter'),
      );
}
