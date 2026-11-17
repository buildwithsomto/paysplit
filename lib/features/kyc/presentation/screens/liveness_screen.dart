import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

enum _CameraStatus { starting, ready, denied, unavailable }

/// Step 3: a live front-camera frame, one shot, checked for liveness and
/// matched to the ID record.
class LivenessScreen extends ConsumerStatefulWidget {
  const LivenessScreen({super.key});
  @override
  ConsumerState<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends ConsumerState<LivenessScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  _CameraStatus _status = _CameraStatus.starting;

  /// The frame being checked, shown frozen in place of the live preview.
  Uint8List? _shot;
  bool _capturing = false;
  int _startToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _startToken++;
    unawaited(_camera?.dispose());
    super.dispose();
  }

  /// The camera is released whenever the app leaves the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_camera == null) unawaited(_startCamera());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _startToken++;
      final camera = _camera;
      _camera = null;
      unawaited(camera?.dispose());
      if (mounted && _status == _CameraStatus.ready) {
        setState(() => _status = _CameraStatus.starting);
      }
    }
  }

  Future<void> _startCamera() async {
    final token = ++_startToken;
    if (mounted) setState(() => _status = _CameraStatus.starting);
    CameraController? controller;
    var status = _CameraStatus.unavailable;
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final front = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        controller = CameraController(
          front,
          // 720p keeps a sharp face well under the API's 2 MB limit.
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await controller.initialize();
        status = _CameraStatus.ready;
      }
    } on CameraException catch (error) {
      status = error.code.startsWith('CameraAccess')
          ? _CameraStatus.denied
          : _CameraStatus.unavailable;
    } on Object {
      status = _CameraStatus.unavailable;
    }
    if (!mounted || token != _startToken) {
      unawaited(controller?.dispose());
      return;
    }
    if (status != _CameraStatus.ready) {
      unawaited(controller?.dispose());
      controller = null;
    }
    setState(() {
      _camera = controller;
      _status = status;
    });
  }

  Future<void> _takeShot() async {
    final camera = _camera;
    if (camera == null || _capturing || ref.read(kycControllerProvider).busy) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final photo = await camera.takePicture();
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      await _submit(bytes, png: false);
    } on CameraException {
      if (mounted) {
        showAppNotice(
          context,
          'The photo couldn’t be taken. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// For devices without a usable camera, such as simulators.
  Future<void> _choosePhoto() async {
    if (_capturing || ref.read(kycControllerProvider).busy) return;
    setState(() => _capturing = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      await _submit(bytes, png: photo.name.toLowerCase().endsWith('.png'));
    } on PlatformException {
      if (mounted) {
        showAppNotice(
          context,
          'Your photos couldn’t be opened. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _submit(Uint8List bytes, {required bool png}) async {
    setState(() => _shot = bytes);
    final approved = await ref
        .read(kycControllerProvider.notifier)
        .submitSelfie(
          bytes,
          filename: png ? 'selfie.png' : 'selfie.jpg',
          contentType: png ? 'image/png' : 'image/jpeg',
        );
    if (!mounted) return;
    if (approved) {
      context.go('/kyc/result');
    } else {
      // Back to the live frame for another try.
      setState(() => _shot = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final checking = state.busy;
    final busy = checking || _capturing;
    ref.listen(kycControllerProvider.select((s) => s.errors['form']), (
      previous,
      next,
    ) {
      if (next != null) showAppNotice(context, next);
    });
    final error = state.errors['selfie'];
    final ready = _status == _CameraStatus.ready && _camera != null;
    final noCamera =
        _status == _CameraStatus.denied || _status == _CameraStatus.unavailable;
    final hint = switch (_status) {
      _ when error != null => error,
      _ when checking => 'Hold on while we confirm it’s really you.',
      _CameraStatus.denied =>
        'PaySplit needs camera access for this step. Allow it in Settings, or choose a photo.',
      _CameraStatus.unavailable =>
        'This device has no camera available. Choose a clear photo of your face instead.',
      _ => 'Keep your face within the frame and follow the instructions.',
    };
    return AppPageLayout(
      title: '',
      onBack: () => context.go('/kyc/identity'),
      bodyGap: 20,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: noCamera ? 'Choose Photo' : 'Take Shot',
            busy: busy || _status == _CameraStatus.starting,
            onPressed: noCamera ? _choosePhoto : _takeShot,
          ),
          if (!noCamera)
            AppTextLink(
              label: 'Choose a photo instead',
              onPressed: busy ? null : _choosePhoto,
            ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 272),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 272 / 433,
                child: _FaceFrame(
                  camera: ready ? _camera : null,
                  shot: _shot,
                  checking: checking,
                  placeholder: switch (_status) {
                    _CameraStatus.denied => Icons.no_photography_outlined,
                    _CameraStatus.unavailable => Icons.person_outline_rounded,
                    _ => null,
                  },
                  alert: error != null,
                ),
              ),
              const SizedBox(height: 34),
              Text(
                'Checking your Face',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  height: 1.2,
                  color: Color(0xFF323232),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                liveRegion: error != null || checking,
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.6,
                    color: error == null
                        ? const Color(0xFF7C7C7C)
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dashed oval from the design, filled with the live camera.
class _FaceFrame extends StatelessWidget {
  const _FaceFrame({
    required this.camera,
    required this.shot,
    required this.checking,
    required this.placeholder,
    required this.alert,
  });
  final CameraController? camera;
  final Uint8List? shot;
  final bool checking;
  final IconData? placeholder;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final camera = this.camera;
    final preview = camera?.value.previewSize;
    return Semantics(
      image: true,
      label: shot != null
          ? 'Your photo'
          : camera != null
          ? 'Live camera preview'
          : 'Camera preview unavailable',
      child: CustomPaint(
        foregroundPainter: _DashedOvalPainter(
          color: alert ? AppColors.error : AppColors.primary,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: ColoredBox(
              color: AppColors.primaryLight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (shot case final shot?)
                    Image.memory(shot, fit: BoxFit.cover, gaplessPlayback: true)
                  else if (camera != null && preview != null)
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        // The sensor reports landscape; the screen is portrait.
                        width: preview.height,
                        height: preview.width,
                        child: CameraPreview(camera),
                      ),
                    )
                  else if (placeholder != null)
                    Icon(placeholder, size: 96, color: AppColors.primary)
                  else
                    const Center(
                      child: SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Starting camera',
                        ),
                      ),
                    ),
                  if (checking)
                    const ColoredBox(
                      color: Color(0x660F324A),
                      child: Center(
                        child: SizedBox.square(
                          dimension: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                            semanticsLabel: 'Checking your face',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedOvalPainter extends CustomPainter {
  const _DashedOvalPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()..addOval((Offset.zero & size).deflate(.75));
    const dash = 5.0, gap = 4.0;
    for (final metric in outline.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += dash + gap) {
        canvas.drawPath(metric.extractPath(at, at + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOvalPainter oldDelegate) =>
      oldDelegate.color != color;
}
