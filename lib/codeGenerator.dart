import 'dart:math';

class TeamCodeGenerator {
  // Function to generate a random alphanumeric code
  static String generateCode() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => characters[random.nextInt(characters.length)]).join();
  }
}
