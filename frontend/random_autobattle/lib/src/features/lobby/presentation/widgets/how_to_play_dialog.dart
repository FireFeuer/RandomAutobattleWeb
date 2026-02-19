import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class HowToPlayDialog extends StatefulWidget {
  final List<String> imagePaths;
  
  const HowToPlayDialog({
    super.key,
    required this.imagePaths,
  });

  @override
  State<HowToPlayDialog> createState() => _HowToPlayDialogState();
}

class _HowToPlayDialogState extends State<HowToPlayDialog> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.imagePaths.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(30),
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.18),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 900,
          height: 690,
          padding: const EdgeInsets.all(20), 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: widget.imagePaths.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            widget.imagePaths[index],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover, // или BoxFit.fitWidth
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 80, color: Colors.grey[600]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Изображение не найдено',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Navigation controls
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Previous button
                  GestureDetector(
                    onTap: _previousPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.inputBorder,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.inputBorder,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Next button
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.inputBorder,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.inputBorder,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Page indicator
                  Text(
                    '${_currentPage + 1} / ${widget.imagePaths.length}',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inputBorder,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}