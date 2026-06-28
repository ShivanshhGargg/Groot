import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_token_store.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(tokenStoreProvider))..restore();
});

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
  });

  const AuthState.signedOut()
      : isAuthenticated = false,
        isLoading = false,
        error = null;

  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._tokenStore) : super(const AuthState.signedOut());

  final SecureTokenStore _tokenStore;

  Future<void> restore() async {
    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!email.contains('@') || password.length < 4) {
      state = state.copyWith(
        isLoading: false,
        error: 'Use a valid email and password.',
      );
      return;
    }

    await _tokenStore.saveTokens(
      accessToken: 'demo-access-token',
      refreshToken: 'demo-refresh-token',
    );
    state = const AuthState(isAuthenticated: true, isLoading: false);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (fullName.trim().isEmpty || !email.contains('@') || password.length < 6) {
      state = state.copyWith(
        isLoading: false,
        error: 'Add your name, a valid email, and a stronger password.',
      );
      return;
    }

    await _tokenStore.saveTokens(
      accessToken: 'demo-access-token',
      refreshToken: 'demo-refresh-token',
    );
    state = const AuthState(isAuthenticated: true, isLoading: false);
  }

  Future<void> signOut() async {
    await _tokenStore.clear();
    state = const AuthState.signedOut();
  }
}
