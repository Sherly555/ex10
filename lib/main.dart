import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // optional for debug prints

final usersColl = FirebaseFirestore.instance.collection('users');

/// Register a new user
Future<String?> registerUser({
  required String username,
  required String password,
  int saltLength = 16,
  int iterations = 10000,
}) async {
  final docRef = usersColl.doc(username);

  // 1. Check if user exists
  final snapshot = await docRef.get();
  if (snapshot.exists) {
    return 'Username already exists';
  }

  // 2. Generate salt and compute hash
  final salt = generateSalt(saltLength);
  final hash = computeHash(password, salt, iterations: iterations);

  // 3. Prepare data
  final data = {
    'username': username,
    'salt': salt,
    'passwordHash': hash,
    'createdAt': FieldValue.serverTimestamp(),
  };

  try {
    await docRef.set(data);
    return null; // success -> return null error
  } on FirebaseException catch (e) {
    debugPrint('Firestore write failed: ${e.message}');
    return 'Registration failed: ${e.message}';
  }
}

/// Login existing user
Future<String?> loginUser({
  required String username,
  required String password,
  int iterations = 10000,
}) async {
  final docRef = usersColl.doc(username);
  final snapshot = await docRef.get();

  if (!snapshot.exists) return 'User not found';

  final data = snapshot.data()!;
  final salt = data['salt'] as String?;
  final storedHash = data['passwordHash'] as String?;
  if (salt == null || storedHash == null) return 'Invalid user record';

  final computed = computeHash(password, salt, iterations: iterations);
  if (computed == storedHash) {
    // Auth success. You can now set local app state (e.g., secure local token)
    return null; // success
  } else {
    return 'Invalid credentials';
  }
}
