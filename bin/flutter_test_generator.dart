import 'dart:convert';
import 'dart:io';
import 'package:interact/interact.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

void main() async {
  print("🔍 Welcome to the Dart CLI File Picker!");

  // Lấy thư mục hiện tại
  final currentDir = Directory.current;
  final selectedPaths = await navigateAndSelectFiles(currentDir);
  await generateTest(selectedPaths);
}

Future<List<String>> navigateAndSelectFiles(Directory directory) async {
  final selectedPaths = <String>[];
  var currentIndex = 0; // Track the current index of the cursor

  while (true) {
    // Lấy danh sách các mục trong thư mục hiện tại
    final entities = directory.listSync();
    entities.sort((a, b) => a.path.compareTo(b.path));

    final options = entities.map((e) {
      final filePath = e.path;
      final name = path.basename(filePath);
      final checkMark = selectedPaths.contains(filePath) ? "✔️ " : "   ";
      if (e is Directory) {
        return "$checkMark📁 $name/";
      } else if (e is File) {
        return "$checkMark📄 $name";
      } else {
        return name;
      }
    }).toList();

    // Thêm tùy chọn để quay lại thư mục cha nếu không phải là thư mục gốc
    if (directory.parent.path != directory.path) {
      options
        ..insert(0, "⬆️  .. (Go Up)")
        ..insert(0, "Generate Test");
    }

    // Hiển thị menu lựa chọn và giữ nguyên vị trí con trỏ
    currentIndex = Select(
      prompt: 'Current Directory: ${directory.path}',
      options: options,
      initialIndex: currentIndex,
    ).interact();

    // Xử lý lựa chọn
    final selectedOption = options[currentIndex];

    if (selectedOption.startsWith('Generate Test')) {
      return selectedPaths;
    } else if (selectedOption.startsWith("⬆️")) {
      // Đi lên thư mục cha
      directory = directory.parent;
    } else {
      final selectedEntity = entities[directory.parent.path != directory.path
          ? currentIndex - 2
          : currentIndex];

      if (selectedEntity is Directory) {
        // Đi vào thư mục con
        directory = Directory(selectedEntity.path);
        currentIndex = 1; // Reset cursor when entering a new directory
      } else if (selectedEntity is File) {
        // Kiểm tra xem file đã được chọn chưa
        if (selectedPaths.contains(selectedEntity.path)) {
          // Nếu đã chọn, bỏ chọn
          selectedPaths.remove(selectedEntity.path);
          print("❎ Unselected: ${selectedEntity.path}");
        } else {
          // Nếu chưa chọn, chọn file
          selectedPaths.add(selectedEntity.path);
          print("✅ Selected: ${selectedEntity.path}");
        }
      }
    }

    // Hiển thị các file đã chọn
    if (selectedPaths.isNotEmpty) {
      print("\n🗂️  Currently Selected Files:");
      for (var path in selectedPaths) {
        print("- $path");
      }
      print("");
    }
  }
}

Future<void> generateTest(List<String> paths) async {
  final apiKey = 'eGT93tquk0pEt1F73J9JfiF8Plkh29eEet1QUoC38c320e86';
  if (apiKey.isEmpty) {
    print("❗️ OpenAI API key not found.");
    return;
  }

  final gift = Spinner(
    icon: '🏆',
    rightPrompt: (done) => done ? 'Done!' : 'Generating test files...',
  ).interact();

  try {
    for (var filePath in paths) {
      final fileContent = await File(filePath).readAsString();
      final testContent = await generateTestFile(apiKey, fileContent);

      final testFilePath = path.setExtension(filePath, '.test.dart');
      await File(testFilePath).writeAsString(testContent);
      print("✅ Test file generated: $testFilePath");
    }
  } catch (e) {
    print("❗️ Error generating test files: $e");
  } finally {
    gift.done();
  }
}

Future<String> generateTestFile(String apiKey, String fileContent) async {
  final response = await http.post(
    Uri.parse('https://ai.runsystem.work/api/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode({
      'model': 'text-davinci-003',
      'prompt':
          'Generate a Dart test file for the following Dart code:\n\n$fileContent',
      'max_tokens': 1500,
    }),
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return responseData['choices'][0]['text'].trim();
  } else {
    throw Exception('Failed to generate test file. Error: ${response.body}');
  }
}

// class Message {
//   final String role;
//   final String content;
//   final DateTime timestamp;

//   Message(this.text, this.sender, this.timestamp);

//   @override
//   String toString() {
//     return 'Message{sender: $sender, text: $text, timestamp: $timestamp}';
//   }
// }
