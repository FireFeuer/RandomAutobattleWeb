import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';

class MusicToggleButton extends StatefulWidget {
  const MusicToggleButton({super.key});

  @override
  State<MusicToggleButton> createState() => _MusicToggleButtonState();
}

class _MusicToggleButtonState extends State<MusicToggleButton> {
  final _audio = AudioService();
  double _currentVolume = 0.18; // 40% по умолчанию

  @override
  void initState() {
    super.initState();
    _audio.init();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _audio.playingStream,
      initialData: _audio.isPlaying,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Круглая кнопка включения/выключения музыки
            GestureDetector(
              onTap: _audio.toggle,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.music_note,
                      size: 34,
                      color: Colors.white,
                    ),
                    if (!isPlaying)
                      const Icon(
                        Icons.close,
                        size: 46,
                        color: Colors.redAccent,
                      ),
                  ],
                ),
              ),
            ),
            
            // Ползунок громкости (только если музыка включена)
            if (isPlaying) ...[
              const SizedBox(width: 0), // ближе к кнопке
              SizedBox(
                width: 160, // чуть уже, чтобы избежать переполнения
                child: Column(
                  mainAxisSize: MainAxisSize.min, // важно: не растягиваемся по высоте
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ползунок
                    SizedBox(
                      height: 36, // фиксированная высота для слайдера
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 12,
                          activeTrackColor: AppColors.accentBlue,
                          inactiveTrackColor: AppColors.inputBorder,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12,
                          ),
                          thumbColor: AppColors.accentBlue,
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 24,
                          ),
                          overlayColor: AppColors.accentBlue.withOpacity(0.2),
                          showValueIndicator: ShowValueIndicator.never,
                        ),
                        child: Slider(
                          value: _currentVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: (value) {
                            setState(() {
                              _currentVolume = value;
                            });
                            _audio.setVolume(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}