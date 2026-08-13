import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  Future<void> signInWithGoogle() async {
    const webClientId = '294252866971-2oh4ka0aaqn7ilupqe5p81tlck6vqb0l.apps.googleusercontent.com';

    // 1. Initialize GoogleSignIn instance
    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId,
    );

    // 2. Start the interactive sign-in process
    final googleUser = await GoogleSignIn.instance.authenticate();

    if (googleUser == null) {
      throw Exception('SIGN_IN_CANCELLED');
    }

    final String email = googleUser.email.trim().toLowerCase();
    if (!email.endsWith('@nirmauni.ac.in') && email != 'nirmahubtest@gmail.com' && email != 'testnirmahub@gmail.com') {
      await GoogleSignIn.instance.signOut();
      throw Exception('Please use your Nirma ID (@nirmauni.ac.in) only.');
    }

    // 3. Obtain the auth details from the request
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('No ID Token found.');
    }

    // 4. Optionally obtain access token (Supabase might require it depending on the provider, 
    // but for Google, idToken is the most important. We can pass it if we have it.)
    // In google_sign_in 7.2.0, accessToken is retrieved via the authorization client:
    final clientAuth = await googleUser.authorizationClient.authorizationForScopes([
      'email',
      'profile',
    ]);
    final accessToken = clientAuth?.accessToken;

    // 5. Authenticate with Supabase
    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Signs the user out from Supabase and Google
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _supabase.auth.signOut();
  }
  Future<void> createProfile({
    required String fullName,
    required String rollNo,
    required String academicYear,
    required String graduationYear,
    required String division,
    required String batch,
    required String branch,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated. Please sign in first.');
    }

    await _supabase.from('profiles').insert({
      'id': user.id,
      'full_name': fullName,
      'roll_no': rollNo,
      'academic_year': academicYear,
      'graduation_year': graduationYear,
      'division': division,
      'batch': batch,
      'branch': branch,
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('academic_year', academicYear);
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
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (academicYear != null) updates['academic_year'] = academicYear;
    if (graduationYear != null) updates['graduation_year'] = graduationYear;
    if (division != null) updates['division'] = division;
    if (batch != null) updates['batch'] = batch;
    if (branch != null) updates['branch'] = branch;
    if (rollNo != null) updates['roll_no'] = rollNo;
    if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', user.id);
      
      if (academicYear != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('academic_year', academicYear);
      }
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User is not authenticated.');

    final fileExt = imageFile.path.split('.').last;
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'avatars/$fileName';

    await _supabase.storage.from('profile_images').upload(
      filePath,
      imageFile,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );

    return _supabase.storage.from('profile_images').getPublicUrl(filePath);
  }

  /// Checks if the current authenticated user already has a profile.
  Future<bool> profileExists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final response = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    return response != null;
  }

  /// Fetches the user's profile details.
  Future<UserProfile?> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    
    final profile = UserProfile.fromJson(response);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('academic_year', profile.academicYear);
    
    return profile;
  }
}
