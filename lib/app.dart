import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';

const _indigo = Color(0xFF665CF6);
const _teal = Color(0xFF30C8AD);
const _ink = Color(0xFF182039);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF171D31) : Colors.white;
    final surfaceVariant = isDark
        ? const Color(0xFF202840)
        : const Color(0xFFF3F5FA);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _indigo,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFFAAA4FF) : _indigo,
          secondary: isDark ? const Color(0xFF69E0C9) : _teal,
          surface: surface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0D1221)
          : const Color(0xFFF5F6FB),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          height: 1.12,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF303A55) : const Color(0xFFE7EAF2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE05260)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE05260), width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF29324A) : _ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Studio',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: FirebaseDashboardScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class FirebaseDashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const FirebaseDashboardScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<FirebaseDashboardScreen> createState() =>
      _FirebaseDashboardScreenState();
}

class _FirebaseDashboardScreenState extends State<FirebaseDashboardScreen> {
  static const _userDocumentId = 'Fz108SFL28GZxd2e1Klr';

  final _userFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _accountController = TextEditingController();

  bool _isLoadingUser = true;
  bool _isSavingUser = false;
  bool _isChecking = false;
  bool _userLoaded = false;
  String? _userError;
  String _lastCheckedTime = 'Aún no verificado';

  DocumentReference<Map<String, dynamic>> get _userDocument =>
      FirebaseFirestore.instance.collection('usuarios').doc(_userDocumentId);

  @override
  void initState() {
    super.initState();
    _loadUserDocument();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  String get _projectId {
    if (Firebase.apps.isNotEmpty) {
      return Firebase.app().options.projectId;
    }
    try {
      return DefaultFirebaseOptions.currentPlatform.projectId;
    } on UnsupportedError {
      return 'No configurado';
    }
  }

  String get _platformName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  Future<bool> _loadUserDocument() async {
    if (Firebase.apps.isEmpty) {
      setState(() {
        _isLoadingUser = false;
        _userLoaded = false;
        _userError = 'Firebase no está inicializado. Revisa la configuración.';
      });
      return false;
    }

    setState(() {
      _isLoadingUser = true;
      _userError = null;
    });

    try {
      final snapshot = await _userDocument.get();
      if (!mounted) return false;
      if (!snapshot.exists) {
        setState(() {
          _userLoaded = false;
          _userError = 'No se encontró el documento de usuario en Firestore.';
        });
        return false;
      }

      final data = snapshot.data();
      if (data == null) {
        setState(() {
          _userLoaded = false;
          _userError = 'El documento de usuario no contiene datos.';
        });
        return false;
      }

      String readStringField(String field) {
        final value = data[field];
        if (value == null) return '';
        if (value is String) return value;
        throw FormatException('El campo "$field" debe ser texto.');
      }

      setState(() {
        _nameController.text = readStringField('nombre');
        _emailController.text = readStringField('email');
        _accountController.text = readStringField('nocuenta');
        _userLoaded = true;
        _lastCheckedTime = _formatTime(DateTime.now());
      });
      return true;
    } on FirebaseException catch (error) {
      if (!mounted) return false;
      setState(() {
        _userLoaded = false;
        _userError = _firestoreErrorMessage(error, 'leer');
      });
      return false;
    } on FormatException catch (error) {
      if (!mounted) return false;
      setState(() {
        _userLoaded = false;
        _userError = error.message;
      });
      return false;
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<void> _saveUserDocument() async {
    if (_isSavingUser ||
        !_userLoaded ||
        !(_userFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSavingUser = true;
      _userError = null;
    });

    try {
      await _userDocument.update({
        'nombre': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'nocuenta': _accountController.text.trim(),
      });
      if (!mounted) return;

      setState(() {
        _lastCheckedTime = _formatTime(DateTime.now());
      });
      _showMessage('Cambios guardados en Firestore.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _userError = _firestoreErrorMessage(error, 'guardar');
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingUser = false);
      }
    }
  }

  Future<void> _verifyConnection() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    final connected = await _loadUserDocument();
    if (!mounted) return;
    setState(() => _isChecking = false);
    if (connected) {
      _showMessage('Conexión con Firestore verificada.');
    }
  }

  Future<void> _copyProjectId() async {
    await Clipboard.setData(ClipboardData(text: _projectId));
    if (mounted) _showMessage('ID del proyecto copiado.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _firestoreErrorMessage(FirebaseException error, String action) {
    if (error.code == 'permission-denied') {
      return 'Firestore denegó el acceso. Revisa las reglas de seguridad para '
          'permitir $action con esta app.';
    }
    return 'No se pudo $action el documento (${error.code}): '
        '${error.message ?? 'Error de Firestore.'}';
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';

  String? _requiredFieldValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $label es obligatorio.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'El correo es obligatorio.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Escribe un correo válido.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth < 600 ? 20 : 36,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 44),
                      _buildIntro(theme),
                      const SizedBox(height: 30),
                      LayoutBuilder(
                        builder: (context, layout) {
                          if (layout.maxWidth >= 820) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: _buildUserCard(theme)),
                                const SizedBox(width: 22),
                                Expanded(
                                  flex: 4,
                                  child: _buildConnectionCard(theme),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _buildConnectionCard(theme),
                              const SizedBox(height: 18),
                              _buildUserCard(theme),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      _buildFooter(theme),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.storage_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIREBASE STUDIO',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 12,
                letterSpacing: 1.25,
                color: colors.onSurface,
              ),
            ),
            Text(
              'Panel de control',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton.filledTonal(
          tooltip: widget.isDarkMode ? 'Usar modo claro' : 'Usar modo oscuro',
          onPressed: widget.onToggleTheme,
          icon: Icon(
            widget.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildIntro(ThemeData theme) {
    final colors = theme.colorScheme;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: 18,
      spacing: 20,
      children: [
        SizedBox(
          width: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PANEL DE CONEXIÓN',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Firebase, bajo control.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Consulta y actualiza la información de tu perfil conectada '
                'a Cloud Firestore.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildProjectChip(theme),
      ],
    );
  }

  Widget _buildProjectChip(ThemeData theme) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_copy_outlined, size: 17, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            _projectId,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurface,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Copiar ID del proyecto',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: _copyProjectId,
            icon: Icon(Icons.copy_rounded, size: 15, color: colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(ThemeData theme) {
    final connected = _userLoaded;
    final status = _isLoadingUser
        ? 'Sincronizando'
        : connected
        ? 'Conectado'
        : Firebase.apps.isEmpty
        ? 'Configuración pendiente'
        : 'Revisa el acceso';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF252C50), Color(0xFF171D36)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  color: Color(0xFF9E98FF),
                  size: 23,
                ),
              ),
              const Spacer(),
              _statusPill(status, connected),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Conexión a Firestore',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Base de datos predeterminada',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 22),
          _connectionDetail(
            theme,
            icon: Icons.devices_rounded,
            label: 'PLATAFORMA',
            value: _platformName,
          ),
          const SizedBox(height: 16),
          _connectionDetail(
            theme,
            icon: Icons.schedule_rounded,
            label: 'ÚLTIMA VERIFICACIÓN',
            value: _lastCheckedTime,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isChecking ? null : _verifyConnection,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isChecking
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _indigo,
                      ),
                    )
                  : const Icon(Icons.sync_rounded, size: 19),
              label: Text(
                _isChecking ? 'Comprobando...' : 'Comprobar conexión',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status, bool connected) {
    final color = connected ? _teal : const Color(0xFFFFC46B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectionDetail(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white.withValues(alpha: 0.56)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.53),
                  fontSize: 9,
                  letterSpacing: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(ThemeData theme) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: widget.isDarkMode ? 0.12 : 0.035,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERFIL',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Datos de usuario',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Volver a cargar el perfil',
                onPressed: _isLoadingUser || _isSavingUser
                    ? null
                    : _loadUserDocument,
                icon: Icon(Icons.refresh_rounded, color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'usuarios/$_userDocumentId',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (_isLoadingUser) ...[
            const SizedBox(height: 22),
            const LinearProgressIndicator(),
          ],
          if (_userError != null) ...[
            const SizedBox(height: 18),
            _errorBanner(theme, _userError!),
          ],
          if (_userLoaded) ...[
            const SizedBox(height: 22),
            Form(
              key: _userFormKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fields = [
                    _profileField(
                      theme,
                      controller: _nameController,
                      label: 'Nombre',
                      icon: Icons.person_outline_rounded,
                      validator: (value) =>
                          _requiredFieldValidator(value, 'nombre'),
                      capitalization: TextCapitalization.words,
                    ),
                    _profileField(
                      theme,
                      controller: _accountController,
                      label: 'Número de cuenta',
                      icon: Icons.badge_outlined,
                      validator: (value) =>
                          _requiredFieldValidator(value, 'número de cuenta'),
                    ),
                  ];
                  return Column(
                    children: [
                      if (constraints.maxWidth >= 520)
                        Row(
                          children: [
                            Expanded(child: fields[0]),
                            const SizedBox(width: 14),
                            Expanded(child: fields[1]),
                          ],
                        )
                      else ...[
                        fields[0],
                        const SizedBox(height: 14),
                        fields[1],
                      ],
                      const SizedBox(height: 14),
                      _profileField(
                        theme,
                        controller: _emailController,
                        label: 'Correo electrónico',
                        icon: Icons.alternate_email_rounded,
                        validator: _emailValidator,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isSavingUser ? null : _saveUserDocument,
                          icon: _isSavingUser
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            _isSavingUser ? 'Guardando...' : 'Guardar cambios',
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          if (!_isLoadingUser && !_userLoaded && _userError == null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                'No hay información de perfil disponible.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _profileField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      autocorrect: false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _errorBanner(ThemeData theme, String message) {
    final color = theme.colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final colors = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Tus cambios se guardan en Cloud Firestore.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
