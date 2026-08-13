import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserProfile?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<UserProfile?> {
  late final AuthRepository _repository;

  @override
  FutureOr<UserProfile?> build() async {
    _repository = ref.watch(authRepositoryProvider);
    return await _repository.getUserProfile();
  }

  Future<void> registerUser({
    required String fullName,
    required String rollNo,
    required String academicYear,
    required String graduationYear,
    required String division,
    required String batch,
    required String branch,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Launch Native Google Auth
      await _repository.signInWithGoogle();
      
      // 2. Check if profile already exists
      final profile = await _repository.getUserProfile();
      if (profile != null) {
        final email = _repository.currentUserEmail;
        await _repository.signOut();
        throw Exception('REDIRECT_TO_LOGIN:${email ?? "your"}');
      }

      // 3. Create the profile for the new user
      await _repository.createProfile(
        fullName: fullName,
        rollNo: rollNo,
        academicYear: academicYear,
        graduationYear: graduationYear,
        division: division,
        batch: batch,
        branch: branch,
      );

      final newProfile = await _repository.getUserProfile();
      state = AsyncValue.data(newProfile);
    } catch (e, st) {
      // Sign out on failure so they can try again cleanly
      await _repository.signOut();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginExistingUser() async {
    state = const AsyncValue.loading();
    try {
      // 1. Launch Native Google Auth
      await _repository.signInWithGoogle();

      // 2. Enforce strict flow: Profile must exist
      final profile = await _repository.getUserProfile();
      if (profile == null) {
        await _repository.signOut();
        throw Exception('REDIRECT_TO_SIGNUP');
      }

      state = AsyncValue.data(profile);
    } catch (e, st) {
      await _repository.signOut();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? academicYear,
    String? graduationYear,
    String? division,
    String? batch,
    String? branch,
    String? rollNo,
    String? profileImageUrl,
  }) async {
    try {
      await _repository.updateProfile(
        fullName: fullName,
        academicYear: academicYear,
        graduationYear: graduationYear,
        division: division,
        batch: batch,
        branch: branch,
        rollNo: rollNo,
        profileImageUrl: profileImageUrl,
      );
      final updatedProfile = await _repository.getUserProfile();
      if (updatedProfile != null) {
        state = AsyncValue.data(updatedProfile);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    return await _repository.uploadProfileImage(imageFile);
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
